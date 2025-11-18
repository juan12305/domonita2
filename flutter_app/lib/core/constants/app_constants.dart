/// Constantes de la aplicación
class AppConstants {
  AppConstants._();

  // WebSocket Commands
  static const String wsFlutterConnected = 'FLUTTER_CONNECTED';
  static const String wsLightOn = 'LIGHT_ON';
  static const String wsLightOff = 'LIGHT_OFF';
  static const String wsFanOn = 'FAN_ON';
  static const String wsFanOff = 'FAN_OFF';
  static const String wsAutoOn = 'AUTO_ON';
  static const String wsAutoOff = 'AUTO_OFF';

  // Actuator Types
  static const String actuatorTypeFan = 'ventilador';
  static const String actuatorTypeLight = 'bombillo';

  // Sensor Keys
  static const String sensorKeyTemperature = 'temperature';
  static const String sensorKeyHumidity = 'humidity';
  static const String sensorKeyLight = 'light';
  static const String sensorKeyTimestamp = 'timestamp';

  // Temperature Thresholds
  static const double temperatureThresholdFan = 22.0;

  // Storage Limits
  static const int maxSensorRecords = 200;
  static const int saveIntervalMinutes = 1;

  // Gemini AI
  static const String geminiModel = 'gemini-2.0-flash-lite';
  static const double geminiTemperature = 0.3;
  static const int geminiMaxTokens = 256;

  // Action Keys
  static const String actionLightOn = 'LIGHT_ON';
  static const String actionLightOff = 'LIGHT_OFF';
  static const String actionFanOn = 'FAN_ON';
  static const String actionFanOff = 'FAN_OFF';
  static const String actionNoChange = 'NO_CHANGE';

  // Response Keys
  static const String responseKeyLightAction = 'light_action';
  static const String responseKeyFanAction = 'fan_action';
  static const String responseKeyReason = 'reason';
  static const String responseKeyResponse = 'response';
  static const String responseKeyActions = 'actions';
  static const String responseKeySuccess = 'success';

  // Default Values
  static const String defaultOffAction = 'OFF';
  static const String defaultReason = 'No se especificó razón';
}

/// Mapa de acciones de comandos de voz
class VoiceCommandActions {
  VoiceCommandActions._();

  static const Map<String, String> lightOnCommands = {
    'TURN_LED_ON': 'LIGHT_ON',
    'TURN_LIGHT_ON': 'LIGHT_ON',
    'LED_ON': 'LIGHT_ON',
    'LIGHT_ON': 'LIGHT_ON',
  };

  static const Map<String, String> lightOffCommands = {
    'TURN_LED_OFF': 'LIGHT_OFF',
    'TURN_LIGHT_OFF': 'LIGHT_OFF',
    'LED_OFF': 'LIGHT_OFF',
    'LIGHT_OFF': 'LIGHT_OFF',
    'TURN OFF LIGHT': 'LIGHT_OFF',
    'APAGAR LUZ': 'LIGHT_OFF',
    'APAGAR BOMBILLO': 'LIGHT_OFF',
    'TURN OFF THE LIGHT': 'LIGHT_OFF',
  };

  static const Map<String, String> fanOnCommands = {
    'TURN_FAN_ON': 'FAN_ON',
    'FAN_ON': 'FAN_ON',
    'TURN_ON_FAN': 'FAN_ON',
  };

  static const Map<String, String> fanOffCommands = {
    'TURN_FAN_OFF': 'FAN_OFF',
    'FAN_OFF': 'FAN_OFF',
    'TURN_OFF_FAN': 'FAN_OFF',
    'TURN OFF FAN': 'FAN_OFF',
    'TURN_OFF_THE_FAN': 'FAN_OFF',
    'APAGAR VENTILADOR': 'FAN_OFF',
  };

  static const List<String> autoOnKeywords = [
    'ON',
    'ENABLE',
    'ACTIVA',
    'START',
  ];

  static const List<String> autoOffKeywords = [
    'OFF',
    'DISABLE',
    'DESACT',
    'STOP',
  ];
}

/// Palabras clave para detección de intención
class IntentKeywords {
  IntentKeywords._();

  static const List<String> turnOnKeywords = [
    'enciende',
    'prende',
    'turn on',
    'encender',
    'activa',
    'activar',
    'habilita',
    'habilitar',
    'enable',
  ];

  static const List<String> turnOffKeywords = [
    'apaga',
    'apague',
    'turn off',
    'apag',
    'desactiva',
    'desactivar',
    'deshabilita',
    'deshabilitar',
    'disable',
    'quita',
  ];

  static const List<String> lightKeywords = [
    'bombillo',
    'luz',
    'light',
  ];

  static const List<String> fanKeywords = [
    'ventilador',
    'fan',
  ];

  static const List<String> autoOffPhrases = [
    'apaga el modo auto',
    'apaga modo auto',
    'apaga el modo automatico',
    'apaga modo automatico',
    'apaga modo inteligente',
    'apaga control automatico',
    'desactiva el modo auto',
    'desactiva modo auto',
    'desactiva el modo automatico',
    'desactiva modo automatico',
    'deshabilita el modo auto',
    'deshabilita modo automatico',
    'quita el modo auto',
    'quita modo automatico',
    'stop auto mode',
    'turn off auto mode',
    'disable auto mode',
    'auto mode off',
    'modo auto off',
    'modo automatico off',
  ];

  static const List<String> autoOnPhrases = [
    'enciende el modo auto',
    'enciende modo auto',
    'enciende el modo automatico',
    'enciende modo automatico',
    'activa el modo auto',
    'activa modo auto',
    'activa el modo automatico',
    'activa modo automatico',
    'activa modo inteligente',
    'habilita el modo auto',
    'habilita modo automatico',
    'usa el modo auto',
    'enable auto mode',
    'turn on auto mode',
    'start auto mode',
    'auto mode on',
    'modo auto on',
    'modo automatico on',
  ];

  static const List<String> autoModeKeywords = [
    'modo auto',
    'modo automatico',
    'auto mode',
    'automatic mode',
    'control automatico',
    'modo inteligente',
  ];

  static const List<String> summaryKeywords = [
    'resumen',
    'temperatura',
    'humedad',
    'luz',
  ];
}
