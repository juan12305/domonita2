import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/sensor_data.dart';
import '../../services/prompt_repository.dart';

class VoiceCommandService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GenerativeModel _model;
  final PromptRepository prompts;
  bool _isInitialized = false;

  VoiceCommandService(String apiKey, this.prompts)
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash-lite',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.3,
            maxOutputTokens: 256,
          ),
        );

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      return false;
    }
  }

  bool get isAvailable => _isInitialized && _speech.isAvailable;

  Future<void> startListening({
    required Function(String) onResult,
    required Function() onListening,
    required Function() onDone,
  }) async {
    if (!_isInitialized) {
      debugPrint('Speech not initialized');
      return;
    }

    try {
      onListening();
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            onDone();
          }
        },
        localeId: 'es_ES', // Español
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: false,
        ),
      );
    } catch (e) {
      debugPrint('Error starting listening: $e');
      onDone();
    }
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<Map<String, dynamic>> processVoiceCommand(
    String command,
    SensorData? currentSensorData,
  ) async {
    try {
      debugPrint('Processing voice command: $command');

      // Usar prompt desde Supabase
      final prompt = prompts.render('voice_command', {
        'command': command,
        'temperature': currentSensorData?.temperature.toString() ?? 'N/A',
        'humidity': currentSensorData?.humidity.toString() ?? 'N/A',
        'light': currentSensorData?.light == 0 ? 'Mucha luz' : 'Poca luz',
      });

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      String? text = response.text?.trim();
      debugPrint('Voice command AI response: "$text"');

      if (text == null || text.isEmpty) {
        return {
          'light_action': 'NO_CHANGE',
          'fan_action': 'NO_CHANGE',
          'reason': 'No pude entender el comando',
          'success': false,
        };
      }

      // Limpiar y extraer JSON
      text = text.replaceAll(RegExp(r'```json|```|\n'), '').trim();
      final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (match != null) {
        text = match.group(0)!;
      }

      final Map<String, dynamic> parsed = jsonDecode(text);
      return {
        'light_action': parsed['light_action'] ?? 'NO_CHANGE',
        'fan_action': parsed['fan_action'] ?? 'NO_CHANGE',
        'reason': parsed['reason'] ?? 'Comando procesado',
        'success': true,
      };
    } catch (e) {
      debugPrint('Error processing voice command: $e');
      return {
        'light_action': 'NO_CHANGE',
        'fan_action': 'NO_CHANGE',
        'reason': 'Error al procesar el comando: $e',
        'success': false,
      };
    }
  }

  void dispose() {
    _speech.stop();
  }
}
