import 'package:flutter/material.dart';
import 'package:match3/widgets/game_background.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const AnimatedSplashScreen({super.key, required this.nextScreen});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;

  // Oyunun 5 ana sembol rengi
  final List<Color> _gameColors = const [
    Color(0xFFFF4500), // Ateş Kırmızısı
    Color(0xFFFFD700), // Yıldız Sarısı
    Color(0xFF00BFFF), // Su Mavisi
    Color(0xFF32CD32), // Yaprak Yeşili
    Color(0xFF9370DB), // Hilal Moru
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Ölçeklenme animasyonu
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Belirme animasyonu
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );

    // Kırmızı -> Sarı -> Mavi -> Yeşil -> Mor sırasıyla kesintisiz geçiş
    _colorAnimation = TweenSequence<Color?>(
      List.generate(_gameColors.length, (index) {
        final nextIndex = (index + 1) % _gameColors.length;
        return TweenSequenceItem(
          tween: ColorTween(
            begin: _gameColors[index],
            end: _gameColors[nextIndex],
          ),
          weight: 1.0,
        );
      }),
    ).animate(_controller);

    _controller.forward();

    // Animasyon tamamlanınca menüye yönlendir
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => widget.nextScreen,
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final currentColor = _colorAnimation.value ?? _gameColors.first;

          return GameBackground(
            themeColor: currentColor,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Renk Geçişli Parlayan İkon Çerçevesi
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: currentColor.withValues(alpha: 0.8),
                              blurRadius: 45,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 110,
                            height: 110,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Renk Geçişli Gölgeye Sahip Oyun Başlığı
                      Text(
                        'MATCH 3',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: currentColor,
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Dinamik Renkli Yükleme Çubuğu
                      SizedBox(
                        width: 130,
                        child: LinearProgressIndicator(
                          color: currentColor,
                          backgroundColor: Colors.white10,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}