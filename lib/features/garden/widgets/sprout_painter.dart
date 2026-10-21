import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'plant_species.dart';

/// Draws a potted plant whose growth tracks [progress] (0 = bare soil,
/// 1 = full bloom) and whose silhouette, colours and flower come from
/// [species]. Used both as the app's logo mark (at progress ~0.55) and as the
/// live growth meter on the growing screen.
class SproutPainter extends CustomPainter {
  /// 0.0 → just-planted seed, 1.0 → fully bloomed flower.
  final double progress;

  /// Which plant to draw. Defaults to the generic sprout so the logo mark and
  /// any species-agnostic call site keep their original look.
  final PlantSpecies species;

  /// When true, a flower head is drawn once nearly grown. Species that never
  /// flower (e.g. fern) suppress it regardless of this flag.
  final bool allowBloom;

  /// Draws everything in a flat muted tone — used for locked entries in the
  /// collection grid.
  final bool silhouette;

  SproutPainter({
    required this.progress,
    this.species = PlantSpecies.sprout,
    this.allowBloom = true,
    this.silhouette = false,
  });

  Color _tint(Color c) => silhouette ? AppColors.hairline : c;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = progress.clamp(0.0, 1.0);

    // --- Terracotta pot ---
    final potTop = h * 0.66;
    final potBottom = h * 0.92;
    final potTopHalf = w * 0.26;
    final potBottomHalf = w * 0.20;
    final cx = w / 2;

    final potPaint = Paint()..color = _tint(AppColors.bloom);
    final potPath = Path()
      ..moveTo(cx - potTopHalf, potTop)
      ..lineTo(cx + potTopHalf, potTop)
      ..lineTo(cx + potBottomHalf, potBottom)
      ..lineTo(cx - potBottomHalf, potBottom)
      ..close();
    canvas.drawPath(potPath, potPaint);

    // Pot rim
    final rim = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        cx - potTopHalf - 3,
        potTop - h * 0.05,
        (potTopHalf + 3) * 2,
        h * 0.06,
      ),
      Radius.circular(h * 0.03),
    );
    canvas.drawRRect(rim, Paint()..color = _tint(AppColors.soilLight));

    // Soil
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, potTop - h * 0.02),
        width: potTopHalf * 1.9,
        height: h * 0.05,
      ),
      Paint()..color = _tint(AppColors.soil),
    );

    if (p <= 0.02) return;

    // --- Stem ---
    final soilY = potTop - h * 0.03;
    final stemHeight = h * species.stemHeight * p;
    final stemTop = soilY - stemHeight;
    final stemThickness = math.max(3.0, w * 0.03 * species.stemWidth);

    if (species.leafForm == LeafForm.none) {
      // Cactus: a rounded ribbed column rather than a line.
      _column(canvas, cx, soilY, stemTop, stemThickness, w);
    } else {
      final stemPaint = Paint()
        ..color = _tint(species.stem)
        ..strokeWidth = stemThickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx, soilY), Offset(cx, stemTop), stemPaint);
    }

    // --- Foliage ---
    _foliage(canvas, cx, soilY, stemHeight, w, p);

    // --- Flower head ---
    if (allowBloom && species.blooms && p > 0.85) {
      final t = ((p - 0.85) / 0.15).clamp(0.0, 1.0);
      _bloom(canvas, cx, stemTop, soilY, stemHeight, w, t);
    }
  }

  /// Cactus body: a fat rounded column with two pale vertical ribs and spines.
  void _column(
    Canvas canvas,
    double cx,
    double soilY,
    double stemTop,
    double thickness,
    double w,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - thickness / 2, stemTop, cx + thickness / 2, soilY),
      Radius.circular(thickness / 2),
    );
    canvas.drawRRect(body, Paint()..color = _tint(species.stem));

    final rib = Paint()
      ..color = _tint(Colors.white).withValues(alpha: silhouette ? 0.0 : 0.18)
      ..strokeWidth = math.max(1.0, w * 0.008)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final dx in [-thickness * 0.22, thickness * 0.22]) {
      canvas.drawLine(
        Offset(cx + dx, stemTop + thickness * 0.35),
        Offset(cx + dx, soilY - thickness * 0.15),
        rib,
      );
    }

    // Small arms once it has grown enough to have room for them.
    final span = soilY - stemTop;
    if (span > thickness * 1.3) {
      final armY = stemTop + span * 0.45;
      final armLen = thickness * 0.5;
      final arm = Paint()
        ..color = _tint(species.stem)
        ..strokeWidth = thickness * 0.38
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(cx - thickness * 0.4, armY),
        Offset(cx - thickness * 0.4 - armLen, armY - armLen * 0.5),
        arm,
      );
      canvas.drawLine(
        Offset(cx + thickness * 0.4, armY + span * 0.12),
        Offset(
          cx + thickness * 0.4 + armLen,
          armY + span * 0.12 - armLen * 0.5,
        ),
        arm,
      );
    }
  }

  void _foliage(
    Canvas canvas,
    double cx,
    double soilY,
    double stemHeight,
    double w,
    double p,
  ) {
    final paint = Paint()..color = _tint(species.leaf);

    switch (species.leafForm) {
      case LeafForm.none:
        return;

      case LeafForm.pair:
        if (p > 0.25) {
          final size = w * 0.16 * ((p - 0.25) / 0.75).clamp(0.0, 1.0);
          _leaf(
            canvas,
            paint,
            Offset(cx, soilY - stemHeight * 0.55),
            size,
            left: true,
          );
        }
        if (p > 0.45) {
          final size = w * 0.15 * ((p - 0.45) / 0.55).clamp(0.0, 1.0);
          _leaf(
            canvas,
            paint,
            Offset(cx, soilY - stemHeight * 0.8),
            size,
            left: false,
          );
        }
        return;

      case LeafForm.frond:
        // Many small opposed fronds, each appearing in turn as it grows.
        const count = 5;
        for (var i = 0; i < count; i++) {
          final threshold = 0.12 + i * 0.14;
          if (p <= threshold) break;
          final t = ((p - threshold) / 0.14).clamp(0.0, 1.0);
          final frac = 0.22 + i * 0.17;
          final y = soilY - stemHeight * frac;
          final size = w * 0.115 * t * (1 - i * 0.1);
          _leaf(canvas, paint, Offset(cx, y), size, left: true, droop: 0.55);
          _leaf(canvas, paint, Offset(cx, y), size, left: false, droop: 0.55);
        }
        return;

      case LeafForm.broad:
        // Two large leaves low on a tall stalk.
        if (p > 0.22) {
          final t = ((p - 0.22) / 0.4).clamp(0.0, 1.0);
          _leaf(
            canvas,
            paint,
            Offset(cx, soilY - stemHeight * 0.38),
            w * 0.21 * t,
            left: true,
            droop: -0.25,
          );
        }
        if (p > 0.42) {
          final t = ((p - 0.42) / 0.4).clamp(0.0, 1.0);
          _leaf(
            canvas,
            paint,
            Offset(cx, soilY - stemHeight * 0.62),
            w * 0.19 * t,
            left: false,
            droop: -0.25,
          );
        }
        return;

      case LeafForm.blade:
        // Slim blades hugging the stem.
        const count = 3;
        for (var i = 0; i < count; i++) {
          final threshold = 0.18 + i * 0.16;
          if (p <= threshold) break;
          final t = ((p - threshold) / 0.16).clamp(0.0, 1.0);
          final y = soilY - stemHeight * (0.2 + i * 0.2);
          final size = w * 0.1 * t;
          _leaf(
            canvas,
            paint,
            Offset(cx, y),
            size,
            left: i.isEven,
            droop: -0.6,
          );
        }
        return;

      case LeafForm.pad:
        // Low floating pads either side of a short stem.
        if (p > 0.2) {
          final t = ((p - 0.2) / 0.5).clamp(0.0, 1.0);
          final y = soilY - stemHeight * 0.45;
          final rx = w * 0.17 * t;
          for (final dir in [-1, 1]) {
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(cx + dir * rx * 0.95, y),
                width: rx * 1.5,
                height: rx * 0.52,
              ),
              paint,
            );
          }
        }
        return;
    }
  }

  void _bloom(
    Canvas canvas,
    double cx,
    double stemTop,
    double soilY,
    double stemHeight,
    double w,
    double t,
  ) {
    final petalPaint = Paint()..color = _tint(species.flower);

    switch (species.bloomForm) {
      case BloomForm.never:
        return;

      case BloomForm.ring:
        final r = w * 0.11 * t * (species.petals > 8 ? 1.25 : 1.0);
        final petalR = species.petals > 8 ? r * 0.42 : r * 0.7;
        for (var i = 0; i < species.petals; i++) {
          final a = (2 * math.pi / species.petals) * i;
          canvas.drawCircle(
            Offset(cx + math.cos(a) * r, stemTop + math.sin(a) * r),
            petalR,
            petalPaint,
          );
        }
        canvas.drawCircle(
          Offset(cx, stemTop),
          r * (species.petals > 8 ? 0.55 : 0.7),
          Paint()
            ..color = _tint(
              species.petals > 8 ? const Color(0xFF6B4A2F) : AppColors.surface,
            ),
        );
        return;

      case BloomForm.spike:
        // A vertical stack of small florets up the top of the stem.
        const count = 6;
        final span = stemHeight * 0.42;
        for (var i = 0; i < count; i++) {
          final f = i / (count - 1);
          final y = stemTop + span * f;
          final r = w * 0.035 * t * (1 - f * 0.35);
          final dx = (i.isEven ? -1 : 1) * w * 0.022;
          canvas.drawCircle(Offset(cx + dx, y), r, petalPaint);
        }
        return;

      case BloomForm.crown:
        final r = w * 0.07 * t;
        for (var i = 0; i < 5; i++) {
          final a = (2 * math.pi / 5) * i - math.pi / 2;
          canvas.drawCircle(
            Offset(
              cx + math.cos(a) * r * 0.75,
              stemTop + math.sin(a) * r * 0.75,
            ),
            r * 0.55,
            petalPaint,
          );
        }
        canvas.drawCircle(
          Offset(cx, stemTop),
          r * 0.4,
          Paint()..color = _tint(const Color(0xFFFFE08A)),
        );
        return;

      case BloomForm.layered:
        // Wide pointed petals in two offset rings, opening outward.
        final r = w * 0.13 * t;
        for (final ring in [1.0, 0.62]) {
          final offset = ring == 1.0 ? 0.0 : math.pi / species.petals;
          final paint = Paint()
            ..color = _tint(
              species.flower,
            ).withValues(alpha: silhouette ? 1.0 : (ring == 1.0 ? 0.85 : 1.0));
          for (var i = 0; i < species.petals; i++) {
            final a = (2 * math.pi / species.petals) * i + offset;
            final tip = Offset(
              cx + math.cos(a) * r * ring,
              stemTop + math.sin(a) * r * ring,
            );
            final half = r * ring * 0.62;
            final path = Path()
              ..moveTo(cx, stemTop)
              ..quadraticBezierTo(
                cx + math.cos(a + 0.5) * half,
                stemTop + math.sin(a + 0.5) * half,
                tip.dx,
                tip.dy,
              )
              ..quadraticBezierTo(
                cx + math.cos(a - 0.5) * half,
                stemTop + math.sin(a - 0.5) * half,
                cx,
                stemTop,
              )
              ..close();
            canvas.drawPath(path, paint);
          }
        }
        canvas.drawCircle(
          Offset(cx, stemTop),
          r * 0.22,
          Paint()..color = _tint(const Color(0xFFFFE08A)),
        );
        return;
    }
  }

  /// A leaf blob. [droop] > 0 bends the tip downward, < 0 lifts it upward.
  void _leaf(
    Canvas canvas,
    Paint paint,
    Offset base,
    double size, {
    required bool left,
    double droop = 0.0,
  }) {
    final dir = left ? -1 : 1;
    final lift = -size * (0.8 - droop);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + dir * size,
        base.dy + lift,
        base.dx + dir * size * 1.6,
        base.dy - size * 0.2 + droop * size * 0.9,
      )
      ..quadraticBezierTo(
        base.dx + dir * size,
        base.dy + size * 0.3,
        base.dx,
        base.dy,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SproutPainter old) =>
      old.progress != progress ||
      old.allowBloom != allowBloom ||
      old.silhouette != silhouette ||
      old.species.id != species.id;
}

/// Convenience widget: a potted plant at a fixed, pleasant growth.
class SproutMark extends StatelessWidget {
  final double size;
  final double progress;
  final PlantSpecies species;
  final bool silhouette;

  const SproutMark({
    super.key,
    this.size = 120,
    this.progress = 0.6,
    this.species = PlantSpecies.sprout,
    this.silhouette = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SproutPainter(
          progress: progress,
          species: species,
          silhouette: silhouette,
        ),
      ),
    );
  }
}
