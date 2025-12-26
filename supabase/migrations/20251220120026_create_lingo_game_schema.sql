/*
  # Lingo Competition Game Schema

  ## Overview
  This migration creates the complete database schema for a real-time Lingo word-guessing competition game.

  ## New Tables
  
  ### `words`
  - `id` (uuid, primary key) - Unique word identifier
  - `word` (text, unique, not null) - The actual word (uppercase)
  - `length` (int, not null) - Word length (4-6 letters)
  - `starting_letter` (text, not null) - First letter for filtering
  - `created_at` (timestamptz) - When word was added
  
  ### `game_sessions`
  - `id` (uuid, primary key) - Unique session identifier
  - `current_round` (int) - Current round number (1-3)
  - `current_group_id` (uuid) - Which group is currently playing
  - `created_at` (timestamptz) - When session was created
  - `updated_at` (timestamptz) - Last update timestamp
  
  ### `groups`
  - `id` (uuid, primary key) - Unique group identifier
  - `session_id` (uuid, foreign key) - Parent game session
  - `name` (text, not null) - Team/group name
  - `score` (int, default 0) - Total accumulated score
  - `turn_order` (int, not null) - Order of play
  - `created_at` (timestamptz) - When group was created
  
  ### `game_state`
  - `id` (uuid, primary key) - Unique state identifier
  - `session_id` (uuid, foreign key) - Parent game session
  - `group_id` (uuid, foreign key) - Which group this state belongs to
  - `current_word` (text) - The word being guessed
  - `current_word_id` (uuid) - Reference to words table
  - `timer_active` (boolean, default false) - Is countdown running
  - `timer_started_at` (timestamptz) - When timer started
  - `attempts_used` (int, default 0) - Number of attempts so far
  - `guesses` (jsonb, default []) - Array of guess objects with results
  - `round_config` (jsonb) - Scoring configuration
  - `updated_at` (timestamptz) - Last update timestamp
  - Unique constraint on (session_id, group_id)

  ## Security
  - RLS enabled on all tables
  - Public read access for game data (allows unauthenticated players)
  - Public write access for game operations (no login required)
  
  ## Indexes
  - `words`: indexed on length and starting_letter for fast filtering
  - `groups`: indexed on session_id for quick lookups
  - `game_state`: indexed on session_id and group_id for real-time queries
*/

-- Create words table
CREATE TABLE IF NOT EXISTS words (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  word text UNIQUE NOT NULL,
  length int NOT NULL,
  starting_letter text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_words_length ON words(length);
CREATE INDEX IF NOT EXISTS idx_words_starting ON words(starting_letter);

-- Create game_sessions table
CREATE TABLE IF NOT EXISTS game_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  current_round int DEFAULT 1,
  current_group_id uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create groups table
CREATE TABLE IF NOT EXISTS groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
  name text NOT NULL,
  score int DEFAULT 0,
  turn_order int NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_groups_session ON groups(session_id);

-- Create game_state table
CREATE TABLE IF NOT EXISTS game_state (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  current_word text,
  current_word_id uuid REFERENCES words(id),
  timer_active boolean DEFAULT false,
  timer_started_at timestamptz,
  attempts_used int DEFAULT 0,
  guesses jsonb DEFAULT '[]'::jsonb,
  round_config jsonb DEFAULT '{"starting_points":120,"penalty":20,"rounds":[{"number":1,"word_length":4},{"number":2,"word_length":5},{"number":3,"word_length":6}]}'::jsonb,
  updated_at timestamptz DEFAULT now(),
  UNIQUE(session_id, group_id)
);

CREATE INDEX IF NOT EXISTS idx_game_state_session ON game_state(session_id);
CREATE INDEX IF NOT EXISTS idx_game_state_group ON game_state(group_id);

-- Enable RLS
ALTER TABLE words ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_state ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (no authentication required)
CREATE POLICY "Public read access for words"
  ON words FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Public write access for words"
  ON words FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Public read access for game_sessions"
  ON game_sessions FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Public write access for game_sessions"
  ON game_sessions FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Public read access for groups"
  ON groups FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Public write access for groups"
  ON groups FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Public read access for game_state"
  ON game_state FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Public write access for game_state"
  ON game_state FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- Insert starter words
INSERT INTO words (word, length, starting_letter) VALUES
  ('GAME', 4, 'G'),
  ('PLAY', 4, 'P'),
  ('WORD', 4, 'W'),
  ('TIME', 4, 'T'),
  ('GOAL', 4, 'G'),
  ('TEAM', 4, 'T'),
  ('FIRE', 4, 'F'),
  ('STAR', 4, 'S'),
  ('BALL', 4, 'B'),
  ('RING', 4, 'R'),
  ('SOUND', 5, 'S'),
  ('TIMER', 5, 'T'),
  ('LINGO', 5, 'L'),
  ('SCORE', 5, 'S'),
  ('GUESS', 5, 'G'),
  ('ROUND', 5, 'R'),
  ('BOARD', 5, 'B'),
  ('CLOCK', 5, 'C'),
  ('FLASH', 5, 'F'),
  ('MAGIC', 5, 'M'),
  ('WINNER', 6, 'W'),
  ('POINTS', 6, 'P'),
  ('LEADER', 6, 'L'),
  ('BUZZER', 6, 'B'),
  ('ANSWER', 6, 'A'),
  ('PLAYER', 6, 'P'),
  ('COMBAT', 6, 'C'),
  ('TROPHY', 6, 'T'),
  ('PUZZLE', 6, 'P'),
  ('TURBO', 5, 'T')
ON CONFLICT (word) DO NOTHING;