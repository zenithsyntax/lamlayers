// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_favorites.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FontFavoritesAdapter extends TypeAdapter<FontFavorites> {
  @override
  final int typeId = 18;

  @override
  FontFavorites read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FontFavorites().._likedFamilies = (fields[0] as List).cast<String>();
  }

  @override
  void write(BinaryWriter writer, FontFavorites obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj._likedFamilies);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontFavoritesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
