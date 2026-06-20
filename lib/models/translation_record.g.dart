// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranslationRecordAdapter extends TypeAdapter<TranslationRecord> {
  @override
  final int typeId = 1;

  @override
  TranslationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranslationRecord(
      id: fields[0] as String,
      url: fields[1] as String,
      title: fields[2] as String,
      originalText: fields[3] as String,
      translatedText: fields[4] as String,
      sourceLanguage: fields[5] as String,
      targetLanguage: fields[6] as String,
      createdAt: fields[7] as DateTime,
      isFavorite: fields[8] as bool,
      favoriteCategory: fields[9] as String?,
      apiName: fields[10] as String?,
      modelName: fields[11] as String?,
      cacheKey: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TranslationRecord obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.originalText)
      ..writeByte(4)
      ..write(obj.translatedText)
      ..writeByte(5)
      ..write(obj.sourceLanguage)
      ..writeByte(6)
      ..write(obj.targetLanguage)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.isFavorite)
      ..writeByte(9)
      ..write(obj.favoriteCategory)
      ..writeByte(10)
      ..write(obj.apiName)
      ..writeByte(11)
      ..write(obj.modelName)
      ..writeByte(12)
      ..write(obj.cacheKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}