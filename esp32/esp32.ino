#include <WiFi.h>
#include <WebSocketsClient.h>
#include <DHT.h>

// Configuración de pines
#define LED_PIN 2
#define DHT_PIN 4
#define LDR_PIN 34

// Configuración de WiFi
const char* ssid = "MACRO_OLIVER"; // Tu SSID
const char* password = "1085323594@"; // Tu contraseña

// Configuración del servidor WebSocket
const char* websocket_server = "192.168.110.155"; // IP del servidor Node.js
const int websocket_port = 3000;

// Objetos
DHT dht(DHT_PIN, DHT11);
WebSocketsClient webSocket;

// Variables
unsigned long lastSendTime = 0;
const unsigned long sendInterval = 3000; // 3 segundos

// Prototipos de funciones
void webSocketEvent(WStype_t type, uint8_t * payload, size_t length);
void sendSensorData();

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  dht.begin();

  // Conectar a WiFi
  WiFi.begin(ssid, password);
  Serial.print("Conectando a WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConectado a WiFi");

  // Conectar al servidor WebSocket
  webSocket.begin(websocket_server, websocket_port, "/");
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);
  Serial.println("Conectando al servidor WebSocket...");
}

void loop() {
  webSocket.loop();

  // Enviar datos cada 3 segundos
  if (millis() - lastSendTime >= sendInterval) {
    sendSensorData();
    lastSendTime = millis();
  }
}

void sendSensorData() {
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  int light = analogRead(LDR_PIN);

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Error al leer del sensor DHT");
    return;
  }

  // Crear JSON
  String jsonData = "{";
  jsonData += "\"temperature\":" + String(temperature, 1) + ",";
  jsonData += "\"humidity\":" + String(humidity, 1) + ",";
  jsonData += "\"light\":" + String(light);
  jsonData += "}";

  // Enviar por WebSocket
  webSocket.sendTXT(jsonData);
  Serial.println("Datos enviados: " + jsonData);
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("Desconectado del servidor WebSocket");
      break;
    case WStype_CONNECTED:
      Serial.println("Conectado al servidor WebSocket");
      webSocket.sendTXT("ESP32_CONNECTED");
      break;
    case WStype_TEXT:
      String message = String((char*)payload);
      Serial.println("Mensaje recibido: " + message);
      if (message == "LED_ON") {
        digitalWrite(LED_PIN, HIGH);
        Serial.println("LED encendido");
      } else if (message == "LED_OFF") {
        digitalWrite(LED_PIN, LOW);
        Serial.println("LED apagado");
      }
      break;
  }
}
