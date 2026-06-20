// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FavoriteItemAdapter extends TypeAdapter<FavoriteItem> {
  @override
  final int typeId = 2;

  @override
  FavoriteItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteItem(
      id: fields[0] as String,
      url: fields[1] as String,
      title: fields[2] as String,
      category: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      thumbnail: fields[5] as String?,
      description: fields[6] as String?,
      isTranslated: fields[7] as bool,
      lastTranslatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.thumbnail)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.isTranslated)
      ..writeByte(8)
      ..write(obj.lastTranslatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}