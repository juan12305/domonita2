import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/sensor_data.dart';
import '../../data/repositories/sensor_repository.dart';
import '../../data/services/gemini_service.dart';

enum AiConsumptionLevel { high, medium, low }

class SensorController extends ChangeNotifier {
  final SensorRepository repository;
  final GeminiService geminiService;
  bool _isAutoMode = false;
  Map<String, String>? _cachedDecision;
  DateTime? _lastDecisionTime;
  bool _isEvaluatingAutoDecision = false;

  static const _prefsKeyConsumptionLevel = 'ai_consumption_level';

  AiConsumptionLevel _level = AiConsumptionLevel.medium;
  Duration _decisionCacheDuration = const Duration(seconds: 15);

  SensorController({required this.repository, required this.geminiService}) {
    repository.addListener(_onRepositoryChanged);
    unawaited(loadLevel());
  }

  SensorData? get sensorData => repository.lastSensorData;
  bool get connected => repository.connected;
  bool get isAutoMode => _isAutoMode;
  AiConsumptionLevel get level => _level;
  Duration get decisionCacheDuration => _decisionCacheDuration;

  Future<void> loadLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKeyConsumptionLevel);
      if (saved == null) return;

      final restored = AiConsumptionLevel.values.firstWhere(
        (level) => level.name == saved,
        orElse: () => _level,
      );
      if (restored == _level) return;

      _level = restored;
      _applyLevelDuration();
      _clearDecisionCache();
      debugPrint(
        'AI consumption restored to $_level ($_decisionCacheDuration)',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load AI consumption level: $e');
    }
  }

  void setConsumptionLevel(AiConsumptionLevel newLevel) {
    if (newLevel == _level) return;

    _level = newLevel;
    _applyLevelDuration();
    _clearDecisionCache();
    debugPrint('AI consumption set to $_level ($_decisionCacheDuration)');
    notifyListeners();
    unawaited(_persistLevel());
  }

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
    setAutoMode(!_isAutoMode);
  }

  void setAutoMode(bool enabled) {
    if (_isAutoMode == enabled) return;

    _isAutoMode = enabled;
    if (!enabled) {
      _clearDecisionCache();
      debugPrint('Cleared AI decision cache when disabling auto mode');
    } else {
      debugPrint('Auto mode enabled');
    }

    repository.setAutoMode(enabled);
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

  void _applyLevelDuration() {
    switch (_level) {
      case AiConsumptionLevel.high:
        _decisionCacheDuration = const Duration(seconds: 10);
        break;
      case AiConsumptionLevel.medium:
        _decisionCacheDuration = const Duration(seconds: 15);
        break;
      case AiConsumptionLevel.low:
        _decisionCacheDuration = const Duration(seconds: 25);
        break;
    }
  }

  void _clearDecisionCache() {
    _cachedDecision = null;
    _lastDecisionTime = null;
  }

  Future<void> _persistLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyConsumptionLevel, _level.name);
    } catch (e) {
      debugPrint('Failed to persist AI consumption level: $e');
    }
  }
}
