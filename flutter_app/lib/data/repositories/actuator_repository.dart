import 'package:hive/hive.dart';
import '../../domain/actuator.dart';

class ActuatorRepository {
  late Box<Actuator> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Actuator>('actuatorBox');
  }

  Future<void> saveActuatorState({
    required String type, // 'bombillo' o 'ventilador'
    required bool state,
    required String timestamp,
  }) async {
    final actuator = Actuator(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      state: state,
      timestamp: timestamp,
    );
    await _box.add(actuator);
  }

  List<Actuator> getAllStates() {
    return _box.values.toList();
  }
}
