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
      ..key = fields[0] == null ? 0 : fields[0] as int
      ..value = fields[1] == null ? 0 : fields[1] as int
      ..version = fields[2] == null ? 0 : fields[2] as int
      ..isDeleted = fields[3] == null ? false : fields[3] as bool
      ..isDefered = fields[4] == null ? false : fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, BoxInt obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.isDeleted)
      ..writeByte(4)
      ..write(obj.isDefered);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BoxIntAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
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
      ..key = fields[0] == null ? 0 : fields[0] as int
      ..value = fields[1] == null ? '' : fields[1] as String
      ..version = fields[2] == null ? 0 : fields[2] as int
      ..isDeleted = fields[3] == null ? false : fields[3] as bool
      ..isDefered = fields[4] == null ? false : fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, BoxString obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.isDeleted)
      ..writeByte(4)
      ..write(obj.isDefered);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BoxStringAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
