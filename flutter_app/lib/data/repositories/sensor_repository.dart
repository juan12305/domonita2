import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../domain/sensor_data.dart';
import 'actuator_repository.dart';

class SensorRepository extends ChangeNotifier {
  final String websocketUrl;
  late WebSocketChannel _channel;
  late Box<SensorData> _box;
  late ActuatorRepository _actuatorRepository;

  SensorData? _lastSensorData;
  bool _connected = false;
  DateTime _lastSaved = DateTime.now();

  // Control de escritura asíncrona en Hive
  final List<SensorData> _pendingWrites = [];
  bool _isWriting = false;

  SensorRepository({required this.websocketUrl});

  SensorData? get lastSensorData => _lastSensorData;
  bool get connected => _connected;
  List<SensorData> get allSensorData => _box.values.toList();

  Future<void> init() async {
    _box = await Hive.openBox<SensorData>('sensorDataBox');
    _actuatorRepository = ActuatorRepository();
    await _actuatorRepository.init();

    // Cargar último dato guardado (si existe)
    if (_box.isNotEmpty) {
      _lastSensorData = _box.getAt(_box.length - 1);
    }

    _connect();
  }

  // =======================
  //  CONEXIÓN WEBSOCKET
  // =======================
  void _connect() {
    debugPrint('🔌 Conectando a WebSocket...');
    _channel = WebSocketChannel.connect(Uri.parse(websocketUrl));

    _channel.stream.listen((message) async {
      try {
        final data = jsonDecode(message);
        if (data is Map<String, dynamic> &&
            data.containsKey('temperature') &&
            data.containsKey('humidity') &&
            data.containsKey('light')) {
          final sensorData = SensorData.fromJson(data);

          // Actualiza los datos en memoria
          _lastSensorData = sensorData;

          // Guarda en Hive sin bloquear la UI
          _saveToHive(sensorData);

          // Guarda el estado del ventilador de forma asíncrona
          if (data.containsKey('temperature')) {
            final temp = (data['temperature'] as num).toDouble();
            unawaited(_actuatorRepository.saveActuatorState(
              type: 'ventilador',
              state: temp > 22.0,
              timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
            ));
          }

          // Notifica a la UI en el siguiente frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        }
      } catch (e) {
        debugPrint("⚠️ Error al procesar mensaje WebSocket: $e");
      }
    }, onDone: () {
      _connected = false;
      notifyListeners();
      debugPrint("⚠️ WebSocket cerrado. Reintentando...");
      _reconnect();
    }, onError: (error) {
      _connected = false;
      notifyListeners();
      debugPrint("❌ Error WebSocket: $error. Reintentando...");
      _reconnect();
    });

    _channel.ready.then((_) {
      _connected = true;
      notifyListeners();
      debugPrint("✅ WebSocket conectado correctamente");
      _channel.sink.add('FLUTTER_CONNECTED');
    });
  }

  // =======================
  //  RECONEXIÓN AUTOMÁTICA
  // =======================
  void _reconnect() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!_connected) {
      _connect();
    }
  }

  // =======================
  //  GUARDADO EN HIVE
  // =======================
  void _saveToHive(SensorData data) async {
    // Solo guardar si ha pasado al menos 1 minuto desde el último guardado
    if (DateTime.now().difference(_lastSaved).inMinutes < 1) return;

    _pendingWrites.add(data);
    if (_isWriting) return;

    _isWriting = true;
    while (_pendingWrites.isNotEmpty) {
      final next = _pendingWrites.removeAt(0);
      try {
        await _box.add(next);
        _lastSaved = DateTime.now();

        // Mantener solo los últimos 200 registros
        if (_box.length > 200) {
          await _box.deleteAt(0);
        }
      } catch (e) {
        debugPrint("⚠️ Error al guardar en Hive: $e");
      }
    }
    _isWriting = false;
  }

  // =======================
  //  ACCIONES MANUALES LED Y FAN
  // =======================
  void sendLedOn() async {
    debugPrint('sendLedOn called, connected: $_connected');
    if (_connected) {
      debugPrint('Sending LIGHT_ON');
      _channel.sink.add('LIGHT_ON');
      unawaited(_actuatorRepository.saveActuatorState(
        type: 'bombillo',
        state: true,
        timestamp: DateTime.now().toIso8601String(),
      ));
    } else {
      debugPrint('Not connected, cannot send LIGHT_ON');
    }
  }

  void sendLedOff() async {
    debugPrint('sendLedOff called, connected: $_connected');
    if (_connected) {
      debugPrint('Sending LIGHT_OFF');
      _channel.sink.add('LIGHT_OFF');
      unawaited(_actuatorRepository.saveActuatorState(
        type: 'bombillo',
        state: false,
        timestamp: DateTime.now().toIso8601String(),
      ));
    } else {
      debugPrint('Not connected, cannot send LIGHT_OFF');
    }
  }

  void sendFanOn() async {
    debugPrint('sendFanOn called, connected: $_connected');
    if (_connected) {
      debugPrint('Sending FAN_ON');
      _channel.sink.add('FAN_ON');
      unawaited(_actuatorRepository.saveActuatorState(
        type: 'ventilador',
        state: true,
        timestamp: DateTime.now().toIso8601String(),
      ));
    } else {
      debugPrint('Not connected, cannot send FAN_ON');
    }
  }

  void sendFanOff() async {
    debugPrint('sendFanOff called, connected: $_connected');
    if (_connected) {
      debugPrint('Sending FAN_OFF');
      _channel.sink.add('FAN_OFF');
      unawaited(_actuatorRepository.saveActuatorState(
        type: 'ventilador',
        state: false,
        timestamp: DateTime.now().toIso8601String(),
      ));
    } else {
      debugPrint('Not connected, cannot send FAN_OFF');
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
