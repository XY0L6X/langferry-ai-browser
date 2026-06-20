// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UsageRecordAdapter extends TypeAdapter<UsageRecord> {
  @override
  final int typeId = 2;

  @override
  UsageRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UsageRecord(
      id: fields[0] as String,
      time: fields[1] as DateTime,
      model: fields[2] as String,
      promptTokens: fields[3] as int,
      completionTokens: fields[4] as int,
      cost: fields[5] as double,
      pageUrl: fields[6] as String?,
      pageTitle: fields[7] as String?,
      translatedItems: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UsageRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.time)
      ..writeByte(2)
      ..write(obj.model)
      ..writeByte(3)
      ..write(obj.promptTokens)
      ..writeByte(4)
      ..write(obj.completionTokens)
      ..writeByte(5)
      ..write(obj.cost)
      ..writeByte(6)
      ..write(obj.pageUrl)
      ..writeByte(7)
      ..write(obj.pageTitle)
      ..writeByte(8)
      ..write(obj.translatedItems);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
