# Proyecto de Domótica Completo

Este proyecto implementa un sistema de domótica completo con ESP32, servidor WebSocket en Node.js y aplicación Flutter con Clean Architecture y Hive.

## Estructura del Proyecto

```
domotica_project/
├── esp32/               # Código Arduino para ESP32
├── websocket_server/    # Servidor WebSocket Node.js
├── flutter_app/         # Aplicación Flutter
└── TODO.md              # Lista de tareas pendientes
```

## Componentes

### ESP32
- **Pines utilizados:**
  - LED: GPIO 2 (no cambiar)
  - DHT11: GPIO 4
  - LDR: GPIO 34
- Envía datos de sensores cada 3 segundos
- Recibe comandos para controlar LED

### Servidor WebSocket
- Puerto: 8080
- Relaya datos entre ESP32 y Flutter
- Maneja conexiones múltiples

### Aplicación Flutter
- Arquitectura limpia con Clean Architecture
- Hive para almacenamiento local
- Material 3 con diseño moderno
- Control en tiempo real del LED

## Configuración Inicial

### 1. ESP32
1. Instala Arduino IDE
2. Agrega soporte para ESP32
3. Instala librerías: WiFi, WebSocketsClient, DHT
4. Actualiza credenciales WiFi en `esp32/esp32.ino`
5. Actualiza IP del servidor WebSocket
6. Sube el código al ESP32

### 2. Servidor WebSocket
```bash
cd websocket_server
npm install
npm start
```

### 3. Aplicación Flutter
```bash
cd flutter_app
flutter pub get
flutter pub run build_runner build
flutter run
```

## Funcionalidad

- **ESP32 → Servidor → Flutter:** Datos de temperatura, humedad y luz
- **Flutter → Servidor → ESP32:** Comandos LED_ON / LED_OFF
- **Offline:** Flutter muestra últimos datos guardados en Hive

## Notas Importantes

- Asegúrate de que todos los dispositivos estén en la misma red
- El LED está físicamente conectado al GPIO 2 del ESP32
- El servidor WebSocket debe estar accesible desde ESP32 y Flutter
- Actualiza las direcciones IP según tu configuración de red

## Solución de Problemas

- Verifica conexiones de red
- Revisa logs del servidor WebSocket
- Asegúrate de que las librerías estén instaladas correctamente
- Confirma que los pines del ESP32 coincidan con el hardware
