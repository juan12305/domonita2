import 'package:hive/hive.dart';
part 'actuator.g.dart';

@HiveType(typeId: 1)
class Actuator extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String type; // 'bombillo' o 'ventilador'
  @HiveField(2)
  bool state; // true = ON, false = OFF
  @HiveField(3)
  String timestamp;

  Actuator({
    required this.id,
    required this.type,
    required this.state,
    required this.timestamp,
  });
}
