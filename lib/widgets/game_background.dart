import 'package:flutter/material.dart';
import 'game_background_painter.dart';

class GameBackground extends StatelessWidget {
  final Widget child;
  final Color themeColor;

  const GameBackground({
    super.key,
    required this.child,
    this.themeColor = const Color(0xFFFF4500),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Zemin Radyal Degrade (Daha Parlak Akkor Merkez)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF4A000A), // Merkez açıldı
                  Color(0xFF1E0004),
                  Color(0xFF0A0002),
                ],
                stops: [0.0, 0.65, 1.0],
              ),
            ),
          ),
        ),

        // 2. Canlı Neon Desenler ve Semboller
        Positioned.fill(
          child: Opacity(
            opacity: 0.8, // Neonların gözükmesi için opaklık yükseltildi
            child: CustomPaint(
              painter: GameBackgroundPainter(themeColor: themeColor),
              size: Size.infinite,
            ),
          ),
        ),

        // 3. İnce Hafif Karartma (Aşırı gölge oluşturmayacak şekilde %8'e çekildi)
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),

        // 4. Sayfa İçeriği
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}