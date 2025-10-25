#include <WiFi.h>
#include <WebSocketsClient.h>
#include <DHT.h>
#include <time.h>  // ✅ Para obtener la hora NTP

// ======= CONFIGURACIÓN DE PINES =======
#define DHT_PIN 25
#define LDR_PIN 26
#define RELAY_LIGHT 27   // 💡 Relé para el bombillo
#define RELAY_FAN 14     // 🌬️ Relé para el ventilador

// ======= CONFIGURACIÓN DE WIFI =======
const char* ssid = "MACRO_OLIVER";
const char* password = "1085323594@";

// ======= CONFIGURACIÓN DEL SERVIDOR WEBSOCKET =======
const char* websocket_server = "flutteresp.onrender.com"; // SIN https://
const int websocket_port = 443;
const char* websocket_path = "/";

// ======= OBJETOS =======
DHT dht(DHT_PIN, DHT11);
WebSocketsClient webSocket;

// ======= VARIABLES =======
unsigned long lastSendTime = 0;
const unsigned long sendInterval = 3000; // Enviar cada 3 segundos
bool autoMode = false; // 🔁 Modo automático controlado desde Flutter

// ======= PROTOTIPOS =======
void webSocketEvent(WStype_t type, uint8_t * payload, size_t length);
void sendSensorData();
String getCurrentTime();  

// ======= SETUP =======
void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(RELAY_LIGHT, OUTPUT);
  pinMode(RELAY_FAN, OUTPUT);
  pinMode(LDR_PIN, INPUT);

  // Inicialmente todo apagado
  digitalWrite(RELAY_LIGHT, LOW);
  digitalWrite(RELAY_FAN, LOW);

  dht.begin();

  // ======= CONECTAR WIFI =======
  Serial.println("Conectando a WiFi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ Conectado a WiFi");
  Serial.print("IP local: ");
  Serial.println(WiFi.localIP());

  // ======= CONFIGURAR HORA NTP =======
  configTime(-5 * 3600, 0, "pool.ntp.org", "time.nist.gov"); // UTC-5 (Colombia)
  Serial.println("⌚ Esperando sincronización NTP...");
  delay(2000);

  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    Serial.println("⚠ No se pudo obtener la hora NTP");
  } else {
    Serial.println("✅ Hora NTP sincronizada correctamente");
  }

  // ======= CONEXIÓN SEGURA CON RENDER =======
  webSocket.beginSSL(websocket_server, websocket_port, websocket_path);
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);
  webSocket.enableHeartbeat(15000, 3000, 2);

  Serial.println("Conectando al servidor WebSocket (Render)...");
}

// ======= LOOP PRINCIPAL =======
void loop() {
  webSocket.loop();

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠ WiFi desconectado, intentando reconectar...");
    WiFi.begin(ssid, password);
    delay(1000);
  }

  if (millis() - lastSendTime >= sendInterval) {
    sendSensorData();
    lastSendTime = millis();
  }
}

// ======= OBTENER HORA ACTUAL =======
String getCurrentTime() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    return "unknown";
  }

  char buffer[25];
  strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", &timeinfo);
  return String(buffer);
}

// ======= ENVÍO DE DATOS =======
void sendSensorData() {
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  int lightRaw = digitalRead(LDR_PIN);
  bool isDark = (lightRaw == HIGH);

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("⚠ Error al leer DHT11");
    return;
  }

  // ✅ Crear JSON con hora
  String jsonData = "{";
  jsonData += "\"temperature\":" + String(temperature, 1) + ",";
  jsonData += "\"humidity\":" + String(humidity, 1) + ",";
  jsonData += "\"light\":" + String(isDark ? 1 : 0) + ",";
  jsonData += "\"timestamp\":\"" + getCurrentTime() + "\"";
  jsonData += "}";

  webSocket.sendTXT(jsonData);

  Serial.println("📤 Datos enviados: " + jsonData);
  Serial.printf("🌡 %.1f°C | 💧 %.1f%% | 💡 %d | 🕒 %s | Bombillo: %s | Ventilador: %s\n",
                temperature, humidity,
                isDark ? 1 : 0,
                getCurrentTime().c_str(),
                digitalRead(RELAY_LIGHT) ? "ON" : "OFF",
                digitalWrite(RELAY_FAN, HIGH) ? "ON" : "OFF");
}

// ======= EVENTOS WEBSOCKET =======
void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("❌ Desconectado del servidor WebSocket");
      break;

    case WStype_CONNECTED:
      Serial.println("✅ Conectado al servidor WebSocket (Render)");
      webSocket.sendTXT("ESP32_CONNECTED");
      break;

    case WStype_TEXT: {
      String message = String((char*)payload);
      Serial.println("📩 Mensaje recibido: " + message);

      // ======= MODO AUTOMÁTICO / MANUAL =======
      if (message == "AUTO_ON") {
        autoMode = true;
        Serial.println("🤖 Modo automático activado");
      } 
      else if (message == "AUTO_OFF") {
        autoMode = false;
        Serial.println("🧍 Modo manual activado");
      }

      // ======= COMANDOS DE CONTROL =======
      else if (message == "LIGHT_ON") {
        digitalWrite(RELAY_LIGHT, HIGH);
        Serial.println("💡 Bombillo encendido");
      } 
      else if (message == "LIGHT_OFF") {
        digitalWrite(RELAY_LIGHT, LOW);
        Serial.println("💡 Bombillo apagado");
      }
      else if (message == "FAN_ON") {
        digitalWrite(RELAY_FAN, HIGH);
        Serial.println("🌬️ Ventilador encendido");
      } 
      else if (message == "FAN_OFF") {
        digitalWrite(RELAY_FAN, LOW);
        Serial.println("🌬️ Ventilador apagado");
      }

      break;
    }

    case WStype_ERROR:
      Serial.println("⚠ Error en la conexión WebSocket");
      break;
  }
}
