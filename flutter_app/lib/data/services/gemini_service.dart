import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/sensor_data.dart';

class GeminiService {
  late GenerativeModel _model;

  GeminiService(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 256,
      ),
    );
  }

  // ========================================================
  // 🔹 DECISIONES AUTOMÁTICAS DE CONTROL
  // ========================================================
  Future<Map<String, String>> getAutoDecision(SensorData data) async {
    debugPrint('GeminiService: getAutoDecision called with data: ${data.toJson()}');

    final prompt = '''
Eres un sistema de control automático IoT. Toma decisiones basadas en los sensores.

**Sensores:**
- light: 0 = mucha luz, 1 = poca luz
- temperature: en grados Celsius

**Reglas:**
- Si light = 1 → light_action = "ON" (encender bombillo)
- Si light = 0 → light_action = "OFF"
- Si temperature >= 22 → fan_action = "ON" (encender ventilador)
- Si temperature < 22 → fan_action = "OFF"

Responde estrictamente en formato JSON:
{"light_action": "ON/OFF", "fan_action": "ON/OFF", "reason": "explicación corta"}

Datos actuales: ${jsonEncode(data.toJson())}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      String? text = response.text?.trim();
      debugPrint('GeminiService: Raw AI response: "$text"');

      if (text == null || text.isEmpty) {
        return {
          'light_action': 'OFF',
          'fan_action': 'OFF',
          'reason': 'Sin respuesta del modelo',
        };
      }

      text = text.replaceAll(RegExp(r'```json|```|\n'), '').trim();
      final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (match != null) text = match.group(0)!;

      final result = jsonDecode(text) as Map<String, dynamic>;

      return {
        'light_action': result['light_action'] ?? 'OFF',
        'fan_action': result['fan_action'] ?? 'OFF',
        'reason': result['reason'] ?? 'No se especificó razón',
      };
    } catch (e) {
      debugPrint('GeminiService: Error generating auto decision: $e');
      return {
        'light_action': 'OFF',
        'fan_action': 'OFF',
        'reason': 'Error procesando la decisión automática',
      };
    }
  }

  // ========================================================
  // 🔹 ANÁLISIS DE DATOS HISTÓRICOS
  // ========================================================
  Future<String> generateAnalysis(List<SensorData> data) async {
    if (data.isEmpty) return 'No hay datos disponibles para analizar.';

    final recentData = data.length > 20 ? data.sublist(data.length - 20) : data;

    final prompt = '''
Analiza estos datos de sensores IoT y genera un resumen corto (menos de 100 palabras).
Menciona:
- Promedio, mínima y máxima de temperatura
- Estado de humedad
- Frecuencia de poca luz
- Recomendación simple

Datos JSON: ${jsonEncode(recentData.map((d) => d.toJson()).toList())}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? 'No se pudo generar el análisis.';
      debugPrint('GeminiService: Analysis response: "$text"');
      return text;
    } catch (e) {
      debugPrint('GeminiService: Error generating analysis: $e');
      return 'Error al generar el análisis.';
    }
  }

  // ========================================================
  // 🔹 CHAT GENERAL DEL ASISTENTE DOMÓTICO (MEJORADO)
  // ========================================================
  Future<Map<String, dynamic>?> chatResponse(
    String userMessage,
    List<String> history, {
    List<SensorData>? sensorData, // 👈 nuevo parámetro opcional
  }) async {
    debugPrint('GeminiService: chatResponse called with message: "$userMessage"');

    final limitedHistory = history.length > 5 ? history.sublist(history.length - 5) : history;

    final context = limitedHistory.isNotEmpty
        ? 'Historial reciente:\n${limitedHistory.join('\n')}\n\n'
        : '';

    // ⚙️ Agregar contexto de sensores actuales
    String sensorContext = '';
    if (sensorData != null && sensorData.isNotEmpty) {
      final latest = sensorData.first;
      sensorContext =
          'Los sensores reportan: temperatura actual ${latest.temperature}°C, luz ${latest.light} lux, humedad ${latest.humidity}%. ';
    }

    // 🔍 Detecta si el usuario pide un resumen o datos de sensores
    final isSummaryRequest = userMessage.toLowerCase().contains('resumen') ||
        userMessage.toLowerCase().contains('temperatura') ||
        userMessage.toLowerCase().contains('humedad') ||
        userMessage.toLowerCase().contains('luz');

    // ✅ Si el usuario pide resumen → usa generateAnalysis
    if (isSummaryRequest && sensorData != null && sensorData.isNotEmpty) {
      debugPrint('GeminiService: Detected summary request, generating analysis...');
      final analysis = await generateAnalysis(sensorData);
      return {'response': analysis, 'actions': []};
    }

    // 💬 Si no, responde normalmente como chatbot
    final prompt = '''
$sensorContext
Eres un asistente IoT de hogar inteligente. Tu función es responder preguntas sobre sensores, bombillos y ventiladores.

**Instrucciones:**
- Responde siempre en español.
- Sé breve (máx. 80 palabras).
- Si el usuario pide una acción, responde solo con un JSON:
  {"response": "mensaje breve", "actions": ["turn_led_on", "turn_fan_off"]}
- Si es solo conversación o resumen, responde texto plano, sin formato JSON.

$context
Usuario: "$userMessage"
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      String? text = response.text?.trim();
      debugPrint('GeminiService: Raw chat response: "$text"');

      if (text == null || text.isEmpty) {
        return {'response': 'No entendí tu mensaje.', 'actions': []};
      }

      text = text.replaceAll(RegExp(r'```json|```|\n'), '').trim();
      final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (match != null) text = match.group(0)!;

      try {
        final result = jsonDecode(text);
        if (result is Map<String, dynamic>) {
          return {
            'response': result['response'] ?? '',
            'actions': List<String>.from(result['actions'] ?? []),
          };
        }
      } catch (_) {
        // No era JSON → texto plano
      }

      return {'response': text, 'actions': []};
    } catch (e) {
      debugPrint('GeminiService: Error generating chat response: $e');
      return {
        'response': 'Hubo un error al procesar tu mensaje.',
        'actions': [],
      };
    }
  }
}
