import 'dart:math' as math;
import 'package:flutter/material.dart';

class GameBackgroundPainter extends CustomPainter {
  final Color themeColor;

  GameBackgroundPainter({this.themeColor = const Color(0xFFFF4500)});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double step = 45.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Neon Sembol Dizilimi
    _drawNeonSymbol(canvas, Offset(size.width * 0.15, size.height * 0.12), 24, -0.2, _drawIconFlame, const Color(0xFFFF3300), const Color(0xFFFFD700));
    _drawNeonSymbol(canvas, Offset(size.width * 0.50, size.height * 0.10), 22, 0.1, _drawWaterDrop, const Color(0xFF00E5FF), const Color(0xFFE0FFFF));
    _drawNeonSymbol(canvas, Offset(size.width * 0.85, size.height * 0.12), 22, 0.3, _drawDoubleLeaf, const Color(0xFF00FF66), const Color(0xFFCCFF00));

    _drawNeonSymbol(canvas, Offset(size.width * 0.28, size.height * 0.28), 24, -0.4, _drawRoundedStar, const Color(0xFFFFD700), const Color(0xFFFFFFE0));
    _drawNeonSymbol(canvas, Offset(size.width * 0.72, size.height * 0.28), 22, 0.25, _drawCrescentMoon, const Color(0xFFA855F7), const Color(0xFFF3E8FF));

    _drawNeonSymbol(canvas, Offset(size.width * 0.12, size.height * 0.50), 26, 0.15, _drawIconFlame, const Color(0xFFFF3300), const Color(0xFFFFD700));
    _drawNeonSymbol(canvas, Offset(size.width * 0.50, size.height * 0.52), 24, -0.3, _drawLightningSpark, const Color(0xFFFF9900), const Color(0xFFFFFF00));
    _drawNeonSymbol(canvas, Offset(size.width * 0.88, size.height * 0.50), 22, -0.1, _drawWaterDrop, const Color(0xFF00E5FF), const Color(0xFFE0FFFF));

    _drawNeonSymbol(canvas, Offset(size.width * 0.22, size.height * 0.72), 24, 0.35, _drawDoubleLeaf, const Color(0xFF00FF66), const Color(0xFFCCFF00));
    _drawNeonSymbol(canvas, Offset(size.width * 0.78, size.height * 0.72), 24, -0.2, _drawRoundedStar, const Color(0xFFFFD700), const Color(0xFFFFFFE0));

    _drawNeonSymbol(canvas, Offset(size.width * 0.15, size.height * 0.88), 22, 0.4, _drawCrescentMoon, const Color(0xFFA855F7), const Color(0xFFF3E8FF));
    _drawNeonSymbol(canvas, Offset(size.width * 0.50, size.height * 0.90), 28, -0.15, _drawIconFlame, const Color(0xFFFF3300), const Color(0xFFFFD700));
    _drawNeonSymbol(canvas, Offset(size.width * 0.85, size.height * 0.88), 22, 0.2, _drawLightningSpark, const Color(0xFFFF9900), const Color(0xFFFFFF00));

    // Parlayan Canlı Kıvılcımlar
    final random = math.Random(101);
    for (int i = 0; i < 35; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2.5 + 1;

      final glowPaint = Paint()
        ..color = Color.lerp(const Color(0xFFFF3300), const Color(0xFFFFD700), random.nextDouble())!
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(x, y), radius + 2, glowPaint);
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = Colors.white);
    }
  }

  // Neon Işıma Oluşturan Çizim Fonksiyonu
  void _drawNeonSymbol(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    void Function(Canvas, Offset, double, Paint) drawPath,
    Color neonColor,
    Color coreColor,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // 1. Geniş Dış Neon Işıması (Aura Glow)
    final outerGlow = Paint()
      ..color = neonColor.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.fill;
    drawPath(canvas, Offset.zero, size * 1.2, outerGlow);

    // 2. Keskin İç Parlama Efekti
    final innerGlow = Paint()
      ..color = neonColor.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    drawPath(canvas, Offset.zero, size, innerGlow);

    // 3. Yüksek Parlaklıktaki Merkez Katmanı
    final corePaint = Paint()
      ..color = coreColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    drawPath(canvas, Offset.zero, size * 0.85, corePaint);

    canvas.restore();
  }

  void _drawIconFlame(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size)
      ..cubicTo(center.dx - size * 0.9, center.dy + size * 0.8, center.dx - size * 0.9, center.dy - size * 0.2, center.dx - size * 0.3, center.dy - size)
      ..cubicTo(center.dx - size * 0.1, center.dy - size * 0.4, center.dx + size * 0.2, center.dy - size * 0.5, center.dx + size * 0.1, center.dy - size * 0.8)
      ..cubicTo(center.dx + size * 0.8, center.dy - size * 0.3, center.dx + size * 0.9, center.dy + size * 0.5, center.dx, center.dy + size)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawWaterDrop(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..cubicTo(center.dx + size * 0.85, center.dy + size * 0.1, center.dx + size * 0.75, center.dy + size, center.dx, center.dy + size)
      ..cubicTo(center.dx - size * 0.75, center.dy + size, center.dx - size * 0.85, center.dy + size * 0.1, center.dx, center.dy - size)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawDoubleLeaf(Canvas canvas, Offset center, double size, Paint paint) {
    final leftLeaf = Path()
      ..moveTo(center.dx - size * 0.1, center.dy + size * 0.6)
      ..cubicTo(center.dx - size * 0.9, center.dy + size * 0.2, center.dx - size * 0.8, center.dy - size * 0.6, center.dx - size * 0.1, center.dy - size * 0.8)
      ..cubicTo(center.dx - size * 0.2, center.dy - size * 0.1, center.dx - size * 0.1, center.dy + size * 0.2, center.dx - size * 0.1, center.dy + size * 0.6)
      ..close();

    final rightLeaf = Path()
      ..moveTo(center.dx + size * 0.05, center.dy + size * 0.5)
      ..cubicTo(center.dx + size * 0.8, center.dy + size * 0.1, center.dx + size * 0.9, center.dy - size * 0.5, center.dx + size * 0.3, center.dy - size * 0.7)
      ..cubicTo(center.dx + size * 0.1, center.dy - size * 0.2, center.dx + size * 0.05, center.dy + size * 0.1, center.dx + size * 0.05, center.dy + size * 0.5)
      ..close();

    canvas.drawPath(leftLeaf, paint);
    canvas.drawPath(rightLeaf, paint);
  }

  void _drawRoundedStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const int points = 5;
    final double outerRadius = size;
    final double innerRadius = size * 0.52;

    for (int i = 0; i < points * 2; i++) {
      final double r = (i % 2 == 0) ? outerRadius : innerRadius;
      final double angle = i * math.pi / points - math.pi / 2;
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCrescentMoon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..addArc(Rect.fromCircle(center: center, radius: size), -math.pi * 0.3, math.pi * 1.5)
      ..arcTo(Rect.fromCircle(center: Offset(center.dx + size * 0.3, center.dy - size * 0.1), radius: size * 0.75), math.pi * 1.2, -math.pi * 1.2, false);
    canvas.drawPath(path, paint);
  }

  void _drawLightningSpark(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx + size * 0.15, center.dy - size)
      ..lineTo(center.dx - size * 0.35, center.dy - size * 0.1)
      ..lineTo(center.dx + size * 0.05, center.dy - size * 0.1)
      ..lineTo(center.dx - size * 0.2, center.dy + size)
      ..lineTo(center.dx + size * 0.35, center.dy + size * 0.1)
      ..lineTo(center.dx - size * 0.05, center.dy + size * 0.1)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GameBackgroundPainter oldDelegate) =>
      oldDelegate.themeColor != themeColor;
}