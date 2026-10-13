import { WebSocket } from 'ws';

console.log('Testing connection to WhatsUp Gemini Live Relay (ws://localhost:8080/ws/live-call)...');

const ws = new WebSocket('ws://localhost:8080/ws/live-call');

ws.on('open', () => {
  console.log('✅ Connected to Relay WebSocket successfully!');
  
  // Send test setup handshake
  const setupPayload = {
    type: 'setup',
    langA: { code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা' },
    langB: { code: 'en', englishName: 'English', nativeName: 'English' },
    voice: 'Aoede',
    model: 'models/gemini-2.0-flash-live-001',
    autoDetect: true,
  };

  console.log('Sending test setup handshake...');
  ws.send(JSON.stringify(setupPayload));
});

ws.on('message', (data) => {
  console.log('📩 Received message from Relay:', data.toString());
  setTimeout(() => {
    console.log('Closing test connection cleanly...');
    ws.close();
    process.exit(0);
  }, 500);
});

ws.on('error', (err) => {
  console.error('❌ WebSocket Error:', err.message);
  process.exit(1);
});
