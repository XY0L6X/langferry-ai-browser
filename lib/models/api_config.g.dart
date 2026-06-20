// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApiConfigAdapter extends TypeAdapter<ApiConfig> {
  @override
  final int typeId = 0;

  @override
  ApiConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiConfig(
      name: fields[0] as String,
      endpoint: fields[1] as String,
      apiKey: fields[2] as String,
      model: fields[3] as String,
      systemPrompt: fields[4] as String?,
      isActive: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      lastUsedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ApiConfig obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.endpoint)
      ..writeByte(2)
      ..write(obj.apiKey)
      ..writeByte(3)
      ..write(obj.model)
      ..writeByte(4)
      ..write(obj.systemPrompt)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastUsedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}