// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BoxIntAdapter extends TypeAdapter<BoxInt> {
  @override
  final int typeId = 1;

  @override
  BoxInt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoxInt()
      ..value = fields[0] == null ? 0 : fields[0] as int
      ..version = fields[1] == null ? 0 : fields[1] as int
      ..isDeleted = fields[2] == null ? false : fields[2] as bool;
  }

  @override
  void write(BinaryWriter writer, BoxInt obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.value)
      ..writeByte(1)
      ..write(obj.version)
      ..writeByte(2)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoxIntAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BoxStringAdapter extends TypeAdapter<BoxString> {
  @override
  final int typeId = 2;

  @override
  BoxString read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoxString()
      ..value = fields[0] == null ? '' : fields[0] as String
      ..version = fields[1] == null ? 0 : fields[1] as int
      ..isDeleted = fields[2] == null ? false : fields[2] as bool;
  }

  @override
  void write(BinaryWriter writer, BoxString obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.value)
      ..writeByte(1)
      ..write(obj.version)
      ..writeByte(2)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoxStringAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
