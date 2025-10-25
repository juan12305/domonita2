import 'package:flutter/material.dart';

import '../../domain/sensor_data.dart';
import '../../data/repositories/sensor_repository.dart';
import '../../data/services/gemini_service.dart';

class SensorController extends ChangeNotifier {
  final SensorRepository repository;
  final GeminiService geminiService;
  bool _isAutoMode = false;
  Map<String, String>? _cachedDecision;
  DateTime? _lastDecisionTime;
  bool _isEvaluatingAutoDecision = false;

  // Cache decisions briefly to avoid llamadas consecutivas al modelo
  static const Duration _decisionCacheDuration = Duration(seconds: 15);

  SensorController({required this.repository, required String geminiApiKey})
      : geminiService = GeminiService(geminiApiKey) {
    repository.addListener(_onRepositoryChanged);
  }

  SensorData? get sensorData => repository.lastSensorData;
  bool get connected => repository.connected;
  bool get isAutoMode => _isAutoMode;

  void _onRepositoryChanged() {
    notifyListeners();

    if (!_isAutoMode) return;
    final snapshot = repository.lastSensorData;
    if (snapshot == null) return;

    _evaluateAutoMode(snapshot);
  }

  void turnLedOn() {
    repository.sendLedOn();
  }

  void turnLedOff() {
    repository.sendLedOff();
  }

  void turnFanOn() {
    repository.sendFanOn();
  }

  void turnFanOff() {
    repository.sendFanOff();
  }

  void toggleAutoMode() {
    _isAutoMode = !_isAutoMode;
    // Clear cache when toggling auto mode
    if (!_isAutoMode) {
      _cachedDecision = null;
      _lastDecisionTime = null;
      debugPrint('Cleared AI decision cache when disabling auto mode');
    }
    notifyListeners();
  }

  Future<Map<String, String>> getAutoDecision(SensorData snapshot) async {
    if (_cachedDecision != null && _lastDecisionTime != null) {
      final now = DateTime.now();
      final timeSinceLastDecision = now.difference(_lastDecisionTime!);
      if (timeSinceLastDecision < _decisionCacheDuration) {
        debugPrint(
          'Using cached AI decision (age: ${timeSinceLastDecision.inSeconds}s)',
        );
        return _cachedDecision!;
      }
    }

    _cachedDecision = await geminiService.getAutoDecision(snapshot);
    _lastDecisionTime = DateTime.now();
    debugPrint('Cached new AI decision for $_decisionCacheDuration');

    return _cachedDecision!;
  }

  Future<void> _evaluateAutoMode(SensorData snapshot) async {
    if (_isEvaluatingAutoDecision) return;
    _isEvaluatingAutoDecision = true;
    try {
      debugPrint('Auto mode active, sensor data: ${snapshot.toJson()}');
      final decision = await getAutoDecision(snapshot);
      debugPrint('AI decision: $decision');

      if (decision['light_action'] == 'ON') {
        debugPrint('AI decided to turn LIGHT ON');
        turnLedOn();
      } else if (decision['light_action'] == 'OFF') {
        debugPrint('AI decided to turn LIGHT OFF');
        turnLedOff();
      }

      if (decision['fan_action'] == 'ON') {
        debugPrint('AI decided to turn FAN ON');
        turnFanOn();
      } else if (decision['fan_action'] == 'OFF') {
        debugPrint('AI decided to turn FAN OFF');
        turnFanOff();
      }
    } finally {
      _isEvaluatingAutoDecision = false;
    }
  }

  @override
  void dispose() {
    repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
