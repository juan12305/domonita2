// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:domotica_app/data/repositories/sensor_repository.dart';
import 'package:domotica_app/data/services/gemini_service.dart';
import 'package:domotica_app/data/services/voice_command_service.dart';
import 'package:domotica_app/domain/sensor_data.dart';
import 'package:domotica_app/main.dart';
import 'package:domotica_app/services/prompt_repository.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final repository = _FakeSensorRepository();
    SharedPreferences.setMockInitialValues({});
    final geminiService = _StubGeminiService();
    final voiceService = VoiceCommandService('test-api-key');

    await tester.pumpWidget(
      MyApp(
        repository: repository,
        geminiService: geminiService,
        voiceService: voiceService,
      ),
    );

    await tester.pump();

    // Verify the app renders the login route.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Inicia sesión'), findsOneWidget);
  });
}

class _FakeSensorRepository extends SensorRepository {
  _FakeSensorRepository() : super(websocketUrl: 'ws://fake');

  @override
  List<SensorData> get allSensorData => const [];

  @override
  Future<void> init() async {}

  @override
  void sendLedOn() {}

  @override
  void sendLedOff() {}

  @override
  void sendFanOn() {}

  @override
  void sendFanOff() {}
}

class _StubPromptRepository extends PromptRepository {
  @override
  Future<void> init() async {}

  @override
  String render(String key, Map<String, String> vars) => '';
}

class _StubGeminiService extends GeminiService {
  _StubGeminiService() : super('test-api-key', _StubPromptRepository());

  @override
  Future<Map<String, String>> getAutoDecision(SensorData data) async => {
    'light_action': 'OFF',
    'fan_action': 'OFF',
    'reason': 'stub',
  };

  @override
  Future<String> generateAnalysis(List<SensorData> data) async =>
      'stub analysis';

  @override
  Future<Map<String, dynamic>?> chatResponse(
    String userMessage,
    List<String> history, {
    List<SensorData>? sensorData,
  }) async {
    return {'response': 'stub response', 'actions': const <String>[]};
  }
}
