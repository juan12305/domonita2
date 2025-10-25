// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SensorDataAdapter extends TypeAdapter<SensorData> {
  @override
  final int typeId = 0;

  @override
  SensorData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorData(
      id: fields[0] as String,
      temperature: fields[1] as double,
      humidity: fields[2] as double,
      light: fields[3] as int,
      timestamp: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SensorData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.temperature)
      ..writeByte(2)
      ..write(obj.humidity)
      ..writeByte(3)
      ..write(obj.light)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
