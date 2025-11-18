import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../domain/sensor_data.dart';
import '../../services/prompt_repository.dart';

class GeminiService {
  final PromptRepository prompts;
  late GenerativeModel _model;

  GeminiService(String apiKey, this.prompts) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 256,
      ),
    );
  }

  Future<Map<String, String>> getAutoDecision(SensorData data) async {
    debugPrint(
      'GeminiService: getAutoDecision called with data: ${data.toJson()}',
    );

    final prompt = prompts.render('auto_decision', {
      'sensor_json': jsonEncode(data.toJson()),
    });

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
      if (match != null) {
        text = match.group(0)!;
      }

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

  Future<String> generateAnalysis(List<SensorData> data) async {
    if (data.isEmpty) {
      return 'No hay datos disponibles para analizar.';
    }

    final recentData = data.length > 20 ? data.sublist(data.length - 20) : data;

    final prompt = prompts.render('analysis', {
      'recent_sensor_json': jsonEncode(
        recentData.map((d) => d.toJson()).toList(),
      ),
    });

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

  Future<Map<String, dynamic>?> chatResponse(
    String userMessage,
    List<String> history, {
    List<SensorData>? sensorData,
  }) async {
    debugPrint(
      'GeminiService: chatResponse called with message: "$userMessage"',
    );

    final limitedHistory = history.length > 5
        ? history.sublist(history.length - 5)
        : history;

    final historyBlock = limitedHistory.isNotEmpty
        ? 'Historial reciente:\n${limitedHistory.join('\n')}\n\n'
        : '';

    String sensorContext = '';
    if (sensorData != null && sensorData.isNotEmpty) {
      final latest = sensorData.first;
      sensorContext =
          'Los sensores reportan: temperatura actual ${latest.temperature}°C, luz ${latest.light} lux, humedad ${latest.humidity}%. ';
    }

    final lowerMessage = userMessage.toLowerCase();
    final isSummaryRequest =
        lowerMessage.contains('resumen') ||
        lowerMessage.contains('temperatura') ||
        lowerMessage.contains('humedad') ||
        lowerMessage.contains('luz');

    if (isSummaryRequest && sensorData != null && sensorData.isNotEmpty) {
      debugPrint(
        'GeminiService: Detected summary request, generating analysis...',
      );
      final analysis = await generateAnalysis(sensorData);
      return {'response': analysis, 'actions': []};
    }

    final prompt = prompts.render('chat', {
      'sensor_context': sensorContext,
      'history': historyBlock,
      'user_message': userMessage,
    });

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      String? text = response.text?.trim();
      debugPrint('GeminiService: Raw chat response: "$text"');

      if (text == null || text.isEmpty) {
        return {'response': 'No entendí tu mensaje.', 'actions': []};
      }

      text = text.replaceAll(RegExp(r'```json|```|\n'), '').trim();
      final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (match != null) {
        text = match.group(0)!;
      }

      final result = jsonDecode(text);
      if (result is Map<String, dynamic>) {
        return {
          'response': result['response'] ?? '',
          'actions': List<String>.from(result['actions'] ?? []),
        };
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
