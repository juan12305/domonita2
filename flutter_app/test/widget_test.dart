// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domotica_app/data/repositories/sensor_repository.dart';
import 'package:domotica_app/domain/sensor_data.dart';
import 'package:domotica_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final repository = _FakeSensorRepository();

    await tester.pumpWidget(
      MyApp(
        repository: repository,
        geminiApiKey: 'test-api-key',
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
