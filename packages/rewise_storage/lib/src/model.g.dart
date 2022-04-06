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
    return BoxInt()..value = fields[0] == null ? 0 : fields[0] as int;
  }

  @override
  void write(BinaryWriter writer, BoxInt obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.value);
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

class BoxFactAdapter extends TypeAdapter<BoxFact> {
  @override
  final int typeId = 5;

  @override
  BoxFact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoxFact()
      ..value = fields[0] as Uint8List?
      ..version = fields[1] == null ? 0 : fields[1] as int;
  }

  @override
  void write(BinaryWriter writer, BoxFact obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.value)
      ..writeByte(1)
      ..write(obj.version);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoxFactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
