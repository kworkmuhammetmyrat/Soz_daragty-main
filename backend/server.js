const express = require('express');
const WebSocket = require('ws');
const Redis = require('ioredis');

const app = express();
const PORT = 3001;
const WS_PORT = 8083;

const wss = new WebSocket.Server({ port: WS_PORT });

const subscriber = new Redis();
const publisher = new Redis();

const clients = new Set();

wss.on('connection', (ws) => {
  console.log(`New WebSocket client connected. Total clients: ${clients.size + 1}`);
  clients.add(ws);

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      if (data.type === 'update') {
        publisher.publish('game-updates', JSON.stringify(data));
      }
    } catch (error) {
      console.error('Error parsing message:', error);
    }
  });

  ws.on('close', () => {
    clients.delete(ws);
    console.log(`Client disconnected. Total clients: ${clients.size}`);
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
    clients.delete(ws);
  });

  ws.send(JSON.stringify({ type: 'connected', message: 'Connected to Söz Daragty realtime server' }));
});

subscriber.subscribe('game-updates', (err, count) => {
  if (err) {
    console.error('Failed to subscribe to Redis channel:', err);
  } else {
    console.log(`Subscribed to ${count} channel(s)`);
  }
});

subscriber.on('message', (channel, message) => {
  if (channel === 'game-updates') {
    clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    });
  }
});

subscriber.on('error', (err) => {
  console.error('Redis error:', err);
});

subscriber.on('connect', () => {
  console.log('Connected to Redis');
});

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    websocket_clients: clients.size,
    redis_status: subscriber.status
  });
});

app.listen(PORT, () => {
  console.log(`HTTP server running on http://localhost:${PORT}`);
  console.log(`WebSocket server running on ws://localhost:${WS_PORT}`);
  console.log('Waiting for Redis connection...');
});

process.on('SIGINT', () => {
  console.log('\\nShutting down gracefully...');
  subscriber.quit();
  publisher.quit();
  wss.close();
  process.exit(0);
});