import 'dart:math';
import 'package:flutter/material.dart';
import 'package:match3/features/game/models/tile_model.dart';

class SkillEffectsOverlay extends StatefulWidget {
  final TileType type;
  final VoidCallback onFinished;

  const SkillEffectsOverlay({
    super.key,
    required this.type,
    required this.onFinished,
  });

  @override
  State<SkillEffectsOverlay> createState() => _SkillEffectsOverlayState();
}

class _SkillEffectsOverlayState extends State<SkillEffectsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _controller.forward().then((_) {
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _SkillThemePainter(
              progress: _controller.value,
              type: widget.type,
              rand: _rand,
            ),
          );
        },
      ),
    );
  }
}

class _SkillThemePainter extends CustomPainter {
  final double progress;
  final TileType type;
  final Random rand;

  _SkillThemePainter({
    required this.progress,
    required this.type,
    required this.rand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case TileType.red:
        _drawFireAndTossedBombs(canvas, size);
        break;
      case TileType.blue:
        _drawWaterEffect(canvas, size);
        break;
      case TileType.yellow:
        _drawEightWayLightningEffect(canvas, size);
        break;
      case TileType.green:
        _drawOmniDirectionalLeaves(canvas, size);
        break;
      case TileType.purple:
        _drawMultiDirectionalStars(canvas, size);
        break;
    }
  }

  // 1. KIRMIZI: ALEVLER VE PARABOLİK BOMBALAR
  void _drawFireAndTossedBombs(Canvas canvas, Size size) {
    final paint = Paint();
    double opacity = (sin(progress * pi)).clamp(0.0, 1.0);

    paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 0.95,
      colors: [
        Colors.transparent,
        Colors.orange.withValues(alpha: opacity * 0.35),
        Colors.red.shade900.withValues(alpha: opacity * 0.75),
      ],
      stops: const [0.45, 0.8, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    final flamePath = Path();
    flamePath.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 20) {
      double h = sin((x / 25) + (progress * 14)) * 28 + 55 * opacity;
      flamePath.lineTo(x, size.height - h);
    }
    flamePath.lineTo(size.width, size.height);
    flamePath.close();

    paint.style = PaintingStyle.fill;
    paint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.red.shade900.withValues(alpha: opacity * 0.85),
        Colors.orangeAccent.withValues(alpha: opacity * 0.5),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, size.height - 120, size.width, 120));
    canvas.drawPath(flamePath, paint);
    paint.shader = null;

    final bombOrigins = [
      {'startX': size.width * 0.1, 'endX': size.width * 0.35, 'delay': 0.0},
      {'startX': size.width * 0.88, 'endX': size.width * 0.6, 'delay': 0.1},
      {'startX': size.width * 0.2, 'endX': size.width * 0.48, 'delay': 0.18},
      {'startX': size.width * 0.92, 'endX': size.width * 0.75, 'delay': 0.08},
      {'startX': size.width * 0.05, 'endX': size.width * 0.28, 'delay': 0.24},
    ];

    for (var b in bombOrigins) {
      double t = ((progress - (b['delay'] as double)) * 1.4).clamp(0.0, 1.0);
      if (t <= 0.0 || t >= 1.0) continue;

      double curX = (b['startX'] as double) + ((b['endX'] as double) - (b['startX'] as double)) * t;
      double curY = (size.height * 0.2) + (pow(t, 2) * size.height * 0.68) - (sin(t * pi) * 70);

      paint.color = const Color(0xFF0F172A).withValues(alpha: opacity);
      canvas.drawCircle(Offset(curX, curY), 13, paint);

      paint.color = Colors.redAccent.withValues(alpha: opacity * 0.9);
      canvas.drawCircle(Offset(curX, curY), 5.5, paint);

      paint.color = Colors.amber;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.5;
      canvas.drawLine(Offset(curX, curY - 13), Offset(curX + 5, curY - 20), paint);

      paint.style = PaintingStyle.fill;
      paint.color = Colors.yellowAccent;
      canvas.drawCircle(Offset(curX + 5, curY - 20), 4, paint);
    }
  }

  // 2. MAVİ: TSUNAMİ SU DALGASI
  void _drawWaterEffect(Canvas canvas, Size size) {
    final paint = Paint();
    double waveProgress = (progress * 1.3).clamp(0.0, 1.0);
    double waveTop = size.height * (1.1 - waveProgress * 1.3);

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, waveTop);

    for (double x = 0; x <= size.width; x += 15) {
      double y = waveTop + sin((x / 30) + (progress * 10)) * 22;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.cyanAccent.withValues(alpha: 0.85),
        Colors.blue.shade900.withValues(alpha: 0.65),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    paint.shader = null;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 6;
    paint.color = Colors.white.withValues(alpha: (1.0 - progress).clamp(0.0, 0.9));
    canvas.drawPath(path, paint);
  }

  // 3. SARI: 8 YÖNLÜ ELEKTRİK FIRTINASI
  void _drawEightWayLightningEffect(Canvas canvas, Size size) {
    final paint = Paint();
    double flash = (sin(progress * pi * 12)).abs() * (1.0 - progress);

    paint.color = Colors.amberAccent.withValues(alpha: flash * 0.35);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);

    final eightDirections = [
      const Offset(0, 0),
      Offset(size.width * 0.5, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height * 0.5),
      Offset(size.width, size.height),
      Offset(size.width * 0.5, size.height),
      Offset(0, size.height),
      Offset(0, size.height * 0.5),
    ];

    for (int i = 0; i < eightDirections.length; i++) {
      double alpha = (1.0 - progress) * (flash + 0.4);
      paint.strokeWidth = (i % 2 == 0) ? 3.8 : 2.6;
      _drawEightWayBolt(canvas, eightDirections[i], center, paint, alpha);
    }
  }

  void _drawEightWayBolt(Canvas canvas, Offset start, Offset end, Paint paint, double alpha) {
    paint.color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0));
    final path = Path();
    path.moveTo(start.dx, start.dy);

    double curX = start.dx;
    double curY = start.dy;
    int steps = 8;

    for (int i = 1; i <= steps; i++) {
      double targetX = start.dx + (end.dx - start.dx) * (i / steps);
      double targetY = start.dy + (end.dy - start.dy) * (i / steps);

      curX = targetX + (rand.nextDouble() * 32 - 16);
      curY = targetY + (rand.nextDouble() * 32 - 16);
      path.lineTo(curX, curY);
    }
    path.lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  // 4. YEŞİL: HER YÖNE SAVRULAN YOĞUN YAPRAK FIRTINASI (95 YAPRAK)
  void _drawOmniDirectionalLeaves(Canvas canvas, Size size) {
    final paint = Paint();
    double opacity = (sin(progress * pi)).clamp(0.0, 1.0);

    paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 0.95,
      colors: [
        Colors.greenAccent.withValues(alpha: opacity * 0.35),
        const Color(0xFF047857).withValues(alpha: opacity * 0.5),
        Colors.transparent,
      ],
      stops: const [0.3, 0.75, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    paint.style = PaintingStyle.fill;
    const int leafCount = 95;

    for (int i = 0; i < leafCount; i++) {
      // Her yaprağa özel rastgele yön açısı (0 - 360 derece)
      double angle = (i * 137.5) * (pi / 180.0); // Altın oran açısı
      double baseSpeed = 120 + ((i % 7) * 35);
      
      // Ekranın farklı başlangıç noktaları
      double startX = (sin(i * 37.1) * 0.5 + 0.5) * size.width;
      double startY = (cos(i * 53.3) * 0.5 + 0.5) * size.height;

      // Her yaprak kendi açısında ileri fırlar ve rüzgarla salınır
      double curX = startX + cos(angle) * (progress * baseSpeed) + sin(progress * 8 + i) * 25;
      double curY = startY + sin(angle) * (progress * baseSpeed) + cos(progress * 6 + i) * 25;

      paint.color = i % 3 == 0
          ? Colors.lightGreenAccent.withValues(alpha: opacity * 0.9)
          : (i % 3 == 1
              ? const Color(0xFF10B981).withValues(alpha: opacity * 0.9)
              : Colors.green.shade700.withValues(alpha: opacity * 0.85));

      canvas.save();
      canvas.translate(curX, curY);
      // Havada takla atma ve dönme
      canvas.rotate(angle + (progress * 9) + (i * 0.4));
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 22 * opacity, height: 11 * opacity),
        paint,
      );
      canvas.restore();
    }
  }

  // 5. MOR: HER YÖNE AKAN VE KAYAN YOĞUN YILDIZ YAĞMURU (90 YILDIZ)
  void _drawMultiDirectionalStars(Canvas canvas, Size size) {
    final paint = Paint();
    double opacity = (sin(progress * pi)).clamp(0.0, 1.0);

    paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.deepPurple.shade900.withValues(alpha: opacity * 0.7),
        Colors.purple.withValues(alpha: opacity * 0.45),
        Colors.transparent,
      ],
      stops: const [0.3, 0.75, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    const int starCount = 90;

    for (int i = 0; i < starCount; i++) {
      // Her yıldız için deterministik yön açısı
      double trajectoryAngle = (i * 47.3) * (pi / 180.0);
      double velocity = 140.0 + ((i % 8) * 30.0);

      // Ekran geneline serpiştirilmiş başlangıç noktaları
      double startX = (sin(i * 89.7) * 0.5 + 0.5) * size.width;
      double startY = (cos(i * 43.1) * 0.5 + 0.5) * size.height;

      // Kendi yönünde ilerleme
      double curX = startX + cos(trajectoryAngle) * (progress * velocity);
      double curY = startY + sin(trajectoryAngle) * (progress * velocity);

      double starSize = (i % 4 == 0 ? 10.5 : (i % 2 == 0 ? 7.5 : 5.0)) * opacity;

      paint.style = PaintingStyle.fill;
      paint.color = i % 2 == 0 ? Colors.white : Colors.purpleAccent.shade100;
      _drawStar(canvas, Offset(curX, curY), starSize, paint);

      // Kayan yıldızın gittiği yönün tam tersine çizilen dinamik kuyruk
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.6;
      paint.color = (i % 2 == 0 ? Colors.white : Colors.purpleAccent.shade100)
          .withValues(alpha: opacity * 0.6);

      double tailLength = 24.0;
      double tailX = curX - cos(trajectoryAngle) * tailLength;
      double tailY = curY - sin(trajectoryAngle) * tailLength;
      canvas.drawLine(Offset(curX, curY), Offset(tailX, tailY), paint);
    }
  }

  // 4 Köşeli Parlayan Yıldız
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    double innerRadius = radius * 0.28;

    for (int i = 0; i < 4; i++) {
      double angle = i * (pi / 2);
      double x = center.dx + cos(angle) * radius;
      double y = center.dy + sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      double midAngle = angle + (pi / 4);
      path.lineTo(center.dx + cos(midAngle) * innerRadius, center.dy + sin(midAngle) * innerRadius);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SkillThemePainter oldDelegate) => true;
}