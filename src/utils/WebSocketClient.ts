let ws: WebSocket | null = null;
let messageCallback: ((data: any) => void) | null = null;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 10;
const RECONNECT_DELAY = 2000;

const connect = () => {
  if (ws && ws.readyState === WebSocket.OPEN) return;

  try {
    ws = new WebSocket('ws://localhost:8083');

    ws.onopen = () => {
      console.log('WebSocket connected');
      reconnectAttempts = 0;
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (messageCallback) {
          messageCallback(data);
        }
      } catch (e) {
        console.error('Failed to parse WS message:', e);
      }
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    ws.onclose = () => {
      console.log('WebSocket closed, attempting reconnect...');
      ws = null;

      if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
        reconnectAttempts++;
        setTimeout(connect, RECONNECT_DELAY);
      } else {
        console.warn('Max reconnect attempts reached. Please restart backend.');
      }
    };
  } catch (e) {
    console.error('Failed to create WebSocket:', e);
  }
};

export const initWebSocket = (onMessage: (data: any) => void) => {
  messageCallback = onMessage;
  connect();

  return () => {
    messageCallback = null;
    if (ws) {
      ws.close();
      ws = null;
    }
  };
};

export const sendUpdate = (data: any) => {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type: 'update', ...data }));
  } else {
    console.warn('WebSocket not open, message not sent');
  }
};