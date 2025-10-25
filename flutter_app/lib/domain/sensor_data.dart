import 'package:hive/hive.dart';

part 'sensor_data.g.dart';

@HiveType(typeId: 0)
class SensorData extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  double temperature;
  @HiveField(2)
  double humidity;
  @HiveField(3)
  int light;
  @HiveField(4)
  String timestamp;

  SensorData({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) => SensorData(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        temperature: (json['temperature'] as num).toDouble(),
        humidity: (json['humidity'] as num).toDouble(),
        light: json['light'] is int ? json['light'] : int.tryParse(json['light'].toString()) ?? 0,
        timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'temperature': temperature,
      'humidity': humidity,
      'light': light,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'SensorData(id: $id, temperature: $temperature, humidity: $humidity, light: $light, timestamp: $timestamp)';
  }
}
