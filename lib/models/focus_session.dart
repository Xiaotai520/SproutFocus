import 'package:hive/hive.dart';

/// A single completed (or abandoned) focus session — one plant in the garden.
class FocusSession {
  final String id;
  final String tag;
  final String? note;

  /// Which plant this session grew, derived from the tag at planting time.
  final String plantType;

  /// Minutes the user requested.
  final int plannedMinutes;

  /// Actual seconds the phone stayed locked.
  final int grownSeconds;

  /// Whether the plant reached full bloom (session ran to completion).
  final bool bloomed;

  /// When the seed was planted (session started).
  final DateTime plantedAt;

  FocusSession({
    required this.id,
    required this.tag,
    this.note,
    required this.plantType,
    required this.plannedMinutes,
    required this.grownSeconds,
    required this.bloomed,
    required this.plantedAt,
  });

  int get grownMinutes => grownSeconds ~/ 60;

  /// Maps a focus tag to the species of plant grown for that session.
  static String plantForTag(String tag) {
    switch (tag) {
      case 'studying':
        return 'fern';
      case 'work':
        return 'sunflower';
      case 'reading':
        return 'lavender';
      case 'exercise':
        return 'cactus';
      case 'meditation':
        return 'lotus';
      default:
        return 'sprout';
    }
  }
}

/// Hand-written Hive adapter. Uses typeId 11 and a field layout distinct from
/// any earlier schema so stored data never collides with a previous app.
class FocusSessionAdapter extends TypeAdapter<FocusSession> {
  @override
  final int typeId = 11;

  @override
  FocusSession read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return FocusSession(
      id: fields[0] as String,
      tag: fields[1] as String,
      note: fields[2] as String?,
      plantType: fields[3] as String,
      plannedMinutes: fields[4] as int,
      grownSeconds: fields[5] as int,
      bloomed: fields[6] as bool,
      plantedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FocusSession obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tag)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.plantType)
      ..writeByte(4)
      ..write(obj.plannedMinutes)
      ..writeByte(5)
      ..write(obj.grownSeconds)
      ..writeByte(6)
      ..write(obj.bloomed)
      ..writeByte(7)
      ..write(obj.plantedAt);
  }
}
