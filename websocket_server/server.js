// server.js
const express = require('express');
const http = require('http');
const WebSocket = require('ws');

const PORT = process.env.PORT || 3000;
const app = express();

// Endpoint para Render
app.get('/', (req, res) => {
  res.send('Servidor WebSocket activo 🚀');
});

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Variables globales
let esp32Client = null;
let flutterClients = [];

// ======= MANEJO DE CONEXIONES =======
wss.on('connection', (ws) => {
  console.log('🔌 Nueva conexión establecida');

  ws.on('message', (message) => {
    const msg = message.toString();
    console.log('📩 Mensaje recibido:', msg);

    // ======= IDENTIFICACIÓN DE CLIENTE =======
    if (msg === 'ESP32_CONNECTED') {
      esp32Client = ws;
      ws.send('connection_successful');
      console.log('✅ ESP32 conectado');
      return;
    }

    if (msg === 'FLUTTER_CONNECTED') {
      flutterClients.push(ws);
      ws.send('connection_successful');
      console.log('✅ Flutter conectado');
      return;
    }

    // ======= COMANDOS DESDE FLUTTER =======
    const validCommands = [
      'LIGHT_ON', 'LIGHT_OFF',
      'FAN_ON', 'FAN_OFF',
      'AUTO_ON', 'AUTO_OFF'
    ];

    if (validCommands.includes(msg)) {
      if (esp32Client && esp32Client.readyState === WebSocket.OPEN) {
        esp32Client.send(msg);
        console.log('📤 Comando enviado al ESP32:', msg);
      } else {
        console.log('⚠️ ESP32 no conectado, no se pudo enviar:', msg);
      }
      return;
    }

    // ======= DATOS DESDE ESP32 =======
    try {
      const data = JSON.parse(msg);

      // Si el ESP32 envía un JSON válido con datos de sensores
      if (
        typeof data.temperature !== 'undefined' &&
        typeof data.humidity !== 'undefined' &&
        typeof data.light !== 'undefined'
      ) {
        // Reenviar los datos a todos los Flutter conectados
        flutterClients.forEach((client) => {
          if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({
              source: 'esp32',
              ...data
            }));
          }
        });

        console.log(`📊 Datos reenviados a Flutter: ${msg}`);
      } else {
        console.log('⚠️ JSON recibido no tiene estructura esperada');
      }
    } catch (err) {
      console.log('⚠️ Mensaje no reconocido o no JSON:', msg);
    }
  });

  // ======= MANEJO DE DESCONECTADOS =======
  ws.on('close', () => {
    console.log('❌ Conexión cerrada');

    if (ws === esp32Client) {
      esp32Client = null;
      console.log('💀 ESP32 desconectado');
    } else {
      flutterClients = flutterClients.filter((c) => c !== ws);
      console.log('📴 Flutter desconectado');
    }
  });
});

// ======= INICIAR SERVIDOR =======
server.listen(PORT, () => {
  console.log(`🚀 Servidor WebSocket y HTTP activo en puerto ${PORT}`);
});
