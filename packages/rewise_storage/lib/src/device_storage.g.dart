// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_storage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BoxAuthProfileAdapter extends TypeAdapter<BoxAuthProfile> {
  @override
  final int typeId = 21;

  @override
  BoxAuthProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoxAuthProfile()
      ..value = fields[1] as Uint8List?
      ..key = fields[0] == null ? 0 : fields[0] as int
      ..version = fields[2] == null ? 0 : fields[2] as int
      ..isDeleted = fields[3] == null ? false : fields[3] as bool
      ..isDefered = fields[4] == null ? false : fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, BoxAuthProfile obj) {
    writer
      ..writeByte(5)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(0)
      ..write(obj.key)
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
  bool operator ==(Object other) =>
      identical(this, other) || other is BoxAuthProfileAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
