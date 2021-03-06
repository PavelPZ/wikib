// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rewise_storage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BoxFactAdapter extends TypeAdapter<BoxFact> {
  @override
  final int typeId = 10;

  @override
  BoxFact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoxFact()
      ..value = fields[1] as Uint8List?
      ..key = fields[0] == null ? 0 : fields[0] as int
      ..version = fields[2] == null ? 0 : fields[2] as int
      ..isDeleted = fields[3] == null ? false : fields[3] as bool
      ..isDefered = fields[4] == null ? false : fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, BoxFact obj) {
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
  bool operator ==(Object other) => identical(this, other) || other is BoxFactAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class BoxDailyAdapter extends TypeAdapter<BoxDaily> {
  @override
  final int typeId = 11;

  @override
  BoxDaily read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoxDaily()
      ..value = fields[1] as Uint8List?
      ..key = fields[0] == null ? 0 : fields[0] as int
      ..version = fields[2] == null ? 0 : fields[2] as int
      ..isDeleted = fields[3] == null ? false : fields[3] as bool
      ..isDefered = fields[4] == null ? false : fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, BoxDaily obj) {
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
  bool operator ==(Object other) => identical(this, other) || other is BoxDailyAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class BoxBookAdapter extends TypeAdapter<BoxBook> {
  @override
  final int typeId = 12;

  @override
  BoxBook read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoxBook()
      ..value = fields[1] as Uint8List?
      ..key = fields[0] == null ? 0 : fields[0] as int
      ..version = fields[2] == null ? 0 : fields[2] as int
      ..isDeleted = fields[3] == null ? false : fields[3] as bool
      ..isDefered = fields[4] == null ? false : fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, BoxBook obj) {
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
  bool operator ==(Object other) => identical(this, other) || other is BoxBookAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class BoxConfigAdapter extends TypeAdapter<BoxConfig> {
  @override
  final int typeId = 13;

  @override
  BoxConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoxConfig()
      ..value = fields[1] as Uint8List?
      ..key = fields[0] == null ? 0 : fields[0] as int
      ..version = fields[2] == null ? 0 : fields[2] as int
      ..isDeleted = fields[3] == null ? false : fields[3] as bool
      ..isDefered = fields[4] == null ? false : fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, BoxConfig obj) {
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
  bool operator ==(Object other) => identical(this, other) || other is BoxConfigAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
