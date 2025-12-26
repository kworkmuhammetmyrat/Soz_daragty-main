import { useEffect, useState, useCallback } from 'react';
import { query, single } from '../lib/localDb';
import { initWebSocket } from '../utils/WebSocketClient';

export const useGameState = (sessionId: string | null) => {
  const [gameState, setGameState] = useState<any>(null);
  const [gameSession, setGameSession] = useState<any>(null);
  const [groups, setGroups] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    if (!sessionId) {
      setLoading(false);
      return;
    }

    try {
      const session = await single('SELECT * FROM game_sessions WHERE id = ?', [sessionId]);
      if (!session) {
        setLoading(false);
        return;
      }
      setGameSession(session);

      const groupList = await query(
        'SELECT * FROM groups WHERE session_id = ? ORDER BY turn_order',
        [sessionId]
      );
      setGroups(groupList || []);

      if (session.current_group_id) {
        const state = await single(
          'SELECT * FROM game_state WHERE session_id = ? AND group_id = ?',
          [sessionId, session.current_group_id]
        );

        if (state) {
          setGameState({
            ...state,
            guesses: state.guesses ? JSON.parse(state.guesses) : [],
            round_config: state.round_config ? JSON.parse(state.round_config) : { starting_points: 120, penalty: 20 },
            timer_active: state.timer_active === 1,
            timer_started_at: state.timer_started_at
          });
        } else {
          setGameState(null);
        }
      } else {
        setGameState(null);
      }

      setLoading(false);
    } catch (err) {
      console.error('Load error:', err);
      setLoading(false);
    }
  }, [sessionId]);

  useEffect(() => {
    load();

    if (!sessionId) return;

    const cleanup = initWebSocket((data) => {
      if (data.change === 'db_updated') {
        load();
      }
    });

    return cleanup;
  }, [sessionId, load]);

  return { gameState, gameSession, groups, loading };
};