import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// How a species arranges its foliage. Drives the leaf-drawing branch in
/// [SproutPainter] so each plant reads as a distinct silhouette.
enum LeafForm {
  /// Two broad opposed leaves — the original generic sprout.
  pair,

  /// Many small opposed fronds climbing the stem (fern).
  frond,

  /// A few large upward leaves on a tall stalk (sunflower).
  broad,

  /// Slim paired blades hugging a narrow stem (lavender).
  blade,

  /// No leaves at all; a thick ribbed column instead (cactus).
  none,

  /// Low, wide floating pads (lotus).
  pad,
}

/// How a species blooms once nearly grown.
enum BloomForm {
  /// No flower — stays foliage only.
  never,

  /// A ring of rounded petals around a pale centre (sprout, sunflower).
  ring,

  /// A vertical stack of small florets up the stem (lavender).
  spike,

  /// A single small flower perched on top (cactus).
  crown,

  /// Wide, layered pointed petals opening outward (lotus).
  layered,
}

/// Visual identity for one plant species.
///
/// Keyed by the species strings already produced by
/// `FocusSession.plantForTag`, so stored Hive records stay valid — this adds a
/// presentation layer over existing data and changes no persisted schema.
@immutable
class PlantSpecies {
  /// The persisted key (`'fern'`, `'sunflower'`, …).
  final String id;

  /// Capitalised name shown to the user.
  final String name;

  /// One short line describing what earns this plant.
  final String unlockHint;

  final Color stem;
  final Color leaf;
  final Color flower;

  final LeafForm leafForm;
  final BloomForm bloomForm;

  /// Petal count for the ring / layered bloom forms.
  final int petals;

  /// Stem height as a fraction of the canvas, at full growth.
  final double stemHeight;

  /// Stem thickness multiplier (cactus is fat, lavender is thin).
  final double stemWidth;

  const PlantSpecies({
    required this.id,
    required this.name,
    required this.unlockHint,
    required this.stem,
    required this.leaf,
    required this.flower,
    required this.leafForm,
    required this.bloomForm,
    this.petals = 6,
    this.stemHeight = 0.42,
    this.stemWidth = 1.0,
  });

  bool get blooms => bloomForm != BloomForm.never;

  // --- The species table ---

  static const PlantSpecies sprout = PlantSpecies(
    id: 'sprout',
    name: 'Sprout',
    unlockHint: 'Finish any session',
    stem: AppColors.primary,
    leaf: AppColors.secondary,
    flower: AppColors.bloom,
    leafForm: LeafForm.pair,
    bloomForm: BloomForm.ring,
  );

  static const PlantSpecies fern = PlantSpecies(
    id: 'fern',
    name: 'Fern',
    unlockHint: 'Finish a studying session',
    stem: Color(0xFF3D8B5A),
    leaf: Color(0xFF6FBF73),
    flower: Color(0xFF6FBF73),
    leafForm: LeafForm.frond,
    bloomForm: BloomForm.never,
    stemHeight: 0.40,
    stemWidth: 0.85,
  );

  static const PlantSpecies sunflower = PlantSpecies(
    id: 'sunflower',
    name: 'Sunflower',
    unlockHint: 'Finish a work session',
    stem: Color(0xFF4A8C3F),
    leaf: Color(0xFF7CB342),
    flower: Color(0xFFF9C13C),
    leafForm: LeafForm.broad,
    bloomForm: BloomForm.ring,
    petals: 12,
    stemHeight: 0.50,
    stemWidth: 1.15,
  );

  static const PlantSpecies lavender = PlantSpecies(
    id: 'lavender',
    name: 'Lavender',
    unlockHint: 'Finish a reading session',
    stem: Color(0xFF7D9A6B),
    leaf: Color(0xFF9CBE85),
    flower: Color(0xFF9B7EDE),
    leafForm: LeafForm.blade,
    bloomForm: BloomForm.spike,
    stemHeight: 0.46,
    stemWidth: 0.7,
  );

  static const PlantSpecies cactus = PlantSpecies(
    id: 'cactus',
    name: 'Cactus',
    unlockHint: 'Finish an exercise session',
    stem: Color(0xFF4E9A6B),
    leaf: Color(0xFF4E9A6B),
    flower: Color(0xFFE8617D),
    leafForm: LeafForm.none,
    bloomForm: BloomForm.crown,
    stemHeight: 0.34,
    stemWidth: 4.2,
  );

  static const PlantSpecies lotus = PlantSpecies(
    id: 'lotus',
    name: 'Lotus',
    unlockHint: 'Finish a meditation session',
    stem: Color(0xFF5E9E7A),
    leaf: Color(0xFF86C2A0),
    flower: Color(0xFFF292B6),
    leafForm: LeafForm.pad,
    bloomForm: BloomForm.layered,
    petals: 8,
    stemHeight: 0.36,
    stemWidth: 0.9,
  );

  /// Every species, in the order the collection grid shows them.
  static const List<PlantSpecies> all = [
    sprout,
    fern,
    sunflower,
    lavender,
    cactus,
    lotus,
  ];

  /// Look up a species by its persisted key, falling back to [sprout] so an
  /// unknown or legacy value still renders something sensible.
  static PlantSpecies byId(String? id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return sprout;
  }
}
