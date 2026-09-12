import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3/features/game/logic/game_notifier.dart';

void showFortuneGamesModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const FortuneGamesSheet(),
  );
}

class FortuneGamesSheet extends ConsumerStatefulWidget {
  const FortuneGamesSheet({super.key});

  @override
  ConsumerState<FortuneGamesSheet> createState() => _FortuneGamesSheetState();
}

class _FortuneGamesSheetState extends ConsumerState<FortuneGamesSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _rouletteController;
  late AnimationController _winAnimController;
  final Random _random = Random();

  bool _showWinOverlay = false;
  int _activeEffectTab = 0;
  List<_ThematicWinParticle> _particles = [];

  bool _isSpinning = false;
  String _lastWheelResult = 'Bahsini Seç ve Topu Yuvarla!';
  double _wheelRotation = 0;
  double _ballRotation = 0;
  int _selectedBet = 50;

  bool _isOpeningBox = false;
  String _lastBoxResult = 'Kutudan ne çıkacağını gör!';

  int _diceResult1 = 1;
  int _diceResult2 = 1;
  String _lastDiceResult = 'Tahminini Yap!';

  bool _minesGameActive = false;
  List<bool> _revealedTiles = List.generate(9, (_) => false);
  List<bool> _mineLocations = List.generate(9, (_) => false);
  int _minesCurrentReward = 0;
  int _minesPickCount = 0;
  String _minesStatusText = 'Mayınlara basmadan altınları topla!';

  final List<Map<String, dynamic>> _wheelSectors = [
    {'label': '0x', 'multiplier': 0, 'color': const Color(0xFFDC2626)},
    {'label': '2x', 'multiplier': 2, 'color': const Color(0xFF2563EB)},
    {'label': '0x', 'multiplier': 0, 'color': const Color(0xFFDC2626)},
    {'label': '3x', 'multiplier': 3, 'color': const Color(0xFF9333EA)},
    {'label': '0x', 'multiplier': 0, 'color': const Color(0xFFDC2626)},
    {'label': '2x', 'multiplier': 2, 'color': const Color(0xFF2563EB)},
    {'label': '0x', 'multiplier': 0, 'color': const Color(0xFFDC2626)},
    {'label': '5x', 'multiplier': 5, 'color': const Color(0xFFD97706)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _rouletteController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Aşağıya kadar inişin net izlenmesi için ideal 1.6 saniyelik süre
    _winAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _showWinOverlay = false;
          });
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rouletteController.dispose();
    _winAnimController.dispose();
    super.dispose();
  }

  // 💥 BELİRGİN, AŞAĞIYA KADAR İNEN ÖZEL EFEKT BAŞLATICI
  void _triggerWinAnimation(int tabIndex) {
    HapticFeedback.lightImpact();
    List<_ThematicWinParticle> list = [];

    switch (tabIndex) {
      case 0:
        // 1. RULET: Alttan Tepeye Havai Fişek Volkanı
        for (int i = 0; i < 40; i++) {
          bool isLeft = i % 2 == 0;
          double angle = isLeft
              ? (-pi * 0.15 - (_random.nextDouble() * pi * 0.35))
              : (-pi * 0.50 - (_random.nextDouble() * pi * 0.35));
          double speed = 300.0 + _random.nextDouble() * 260.0;
          list.add(_ThematicWinParticle(
            startXRatio: isLeft ? 0.08 : 0.92,
            startYRatio: 0.88,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            color: [Colors.amber, Colors.orangeAccent, Colors.yellowAccent][_random.nextInt(3)],
            emoji: ['🪙', '✨', '⭐', '🎉'][_random.nextInt(4)],
            size: 24.0 + _random.nextDouble() * 8.0,
            delay: _random.nextDouble() * 0.15,
          ));
        }
        break;

      case 1:
        // 2. KASA: İKİ ÇAPRAZDAN BİRBİRİNİ KESEN ŞERİT ŞELALESİ (SOL ÜST->SAĞ ALT & SAĞ ÜST->SOL ALT)
        for (int i = 0; i < 46; i++) {
          bool fromLeftStream = i % 2 == 0;
          double startX = fromLeftStream 
              ? 0.05 + (_random.nextDouble() * 0.20) 
              : 0.75 + (_random.nextDouble() * 0.20);
          double vx = fromLeftStream 
              ? (260.0 + _random.nextDouble() * 120.0) 
              : (-260.0 - _random.nextDouble() * 120.0);

          list.add(_ThematicWinParticle(
            startXRatio: startX,
            startYRatio: -0.15 - (_random.nextDouble() * 0.25),
            vx: vx,
            vy: 680.0 + _random.nextDouble() * 220.0, // Ekranın en altına kadar hızla iner
            color: [Colors.purpleAccent, Colors.pinkAccent, Colors.deepPurpleAccent][_random.nextInt(3)],
            emoji: ['💎', '👑', '🎁', '✨', '🟣'][_random.nextInt(5)],
            size: 28.0 + _random.nextDouble() * 8.0, // Büyük ve çok net
            delay: (i / 46.0) * 0.35, // Sıralı şerit akışı
          ));
        }
        break;

      case 2:
        // 3. ZAR: EKRANI KAPLAYAN 5 KULVARLI DİK ŞELALE (TAVANDAN TABANA NET DÖKÜLME)
        for (int i = 0; i < 45; i++) {
          int lane = i % 5; // 5 farklı kulvardan dökülür
          double laneX = 0.10 + (lane * 0.20) + ((_random.nextDouble() - 0.5) * 0.06);

          list.add(_ThematicWinParticle(
            startXRatio: laneX,
            startYRatio: -0.15 - (_random.nextDouble() * 0.30),
            vx: (_random.nextDouble() - 0.5) * 20.0, // Sapmasız, dik iniş
            vy: 720.0 + _random.nextDouble() * 240.0, // En alt tabana kadar kesintisiz iniş
            color: [Colors.redAccent, Colors.amber, Colors.orange][_random.nextInt(3)],
            emoji: ['🎲', '🔥', '🏆', '🎯', '♦️'][_random.nextInt(5)],
            size: 30.0 + _random.nextDouble() * 6.0, // Çok net iri zarlar
            delay: _random.nextDouble() * 0.30,
          ));
        }
        break;

      case 3:
      default:
        // 4. KAZI: 360 Derece Genişleyen Halka Şok Dalgası
        for (int i = 0; i < 38; i++) {
          double angle = (i / 38.0) * 2 * pi;
          double speed = 200.0 + _random.nextDouble() * 160.0;
          list.add(_ThematicWinParticle(
            startXRatio: 0.5,
            startYRatio: 0.52,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            color: [Colors.cyanAccent, Colors.greenAccent, Colors.yellowAccent][_random.nextInt(3)],
            emoji: ['💎', '⛏️', '💰', '⚡', '🟢'][_random.nextInt(5)],
            size: 24.0 + _random.nextDouble() * 8.0,
            delay: (_random.nextDouble() * 0.12),
          ));
        }
        break;
    }

    setState(() {
      _particles = list;
      _activeEffectTab = tabIndex;
      _showWinOverlay = true;
    });

    _winAnimController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0F1D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 25,
            spreadRadius: 5,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _tabController.animation ?? _tabController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _DenseIconWallpaperPainter(tabIndex: _tabController.index),
                  );
                },
              ),
            ),
            AbsorbPointer(
              absorbing: _showWinOverlay,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withOpacity(0.45)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.15),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🎲', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Text(
                              'ŞANS SALONU',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('✨', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: _getTabIndicatorColor(_tabController.index).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _getTabIndicatorColor(_tabController.index), width: 1.5),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      tabs: const [
                        Tab(icon: Text('🎡', style: TextStyle(fontSize: 16)), text: 'Rulet'),
                        Tab(icon: Text('📦', style: TextStyle(fontSize: 16)), text: 'Kasa'),
                        Tab(icon: Text('🎲', style: TextStyle(fontSize: 16)), text: 'Zar'),
                        Tab(icon: Text('⛏️', style: TextStyle(fontSize: 16)), text: 'Kazı'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBallRouletteGame(gameState, notifier),
                        _buildMysteryBoxGame(gameState, notifier),
                        _buildDiceGame(gameState, notifier),
                        _buildMinesGame(gameState, notifier),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // EN DİBE KADAR İNEN KESİNTİSİZ KAZANÇ ŞERİTLERİ KATMANI
            if (_showWinOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _winAnimController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: MediaQuery.of(context).size,
                        painter: _DeepCascadingWinPainter(
                          progress: _winAnimController.value,
                          particles: _particles,
                          tabIndex: _activeEffectTab,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTabIndicatorColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.purpleAccent;
      case 2:
        return Colors.redAccent;
      case 3:
        return Colors.cyanAccent;
      default:
        return Colors.amber;
    }
  }

  // --- 1. TOP & RULET ÇARKI ---
  Widget _buildBallRouletteGame(dynamic gameState, GameNotifier notifier) {
    int maxSilver = gameState.silverCoins;
    bool isLocked = _isSpinning || _showWinOverlay;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.35)),
            ),
            child: Text(
              _lastWheelResult,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: 230,
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedRotation(
                  turns: _wheelRotation,
                  duration: const Duration(seconds: 4),
                  curve: Curves.decelerate,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.35),
                          blurRadius: 18,
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(220, 220),
                            painter: WheelPainter(sectors: _wheelSectors),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.amber, blurRadius: 4)
                              ],
                            ),
                            child: const Center(
                              child: Text('⭐', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _ballRotation,
                  duration: const Duration(seconds: 4),
                  curve: Curves.decelerate,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bahis Miktarı:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      '$_selectedBet Gümüş',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBetAdjustButton('-50', isLocked ? null : () {
                      if (_selectedBet > 50) {
                        setState(() => _selectedBet = max(50, _selectedBet - 50));
                      }
                    }),
                    const SizedBox(width: 8),
                    _buildBetAdjustButton('+50', isLocked ? null : () {
                      setState(() => _selectedBet += 50);
                    }),
                    const SizedBox(width: 8),
                    _buildBetAdjustButton('+100', isLocked ? null : () {
                      setState(() => _selectedBet += 100);
                    }),
                    const SizedBox(width: 8),
                    _buildBetAdjustButton('MAX', isLocked ? null : () {
                      if (maxSilver >= 50) {
                        setState(() => _selectedBet = maxSilver);
                      }
                    }, color: Colors.amber.shade800),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            onPressed: isLocked
                ? null
                : () async {
                    if (gameState.silverCoins < _selectedBet) {
                      _showSnack('Yetersiz Gümüş! Sahip olunan: ${gameState.silverCoins}');
                      return;
                    }
                    if (_selectedBet < 50) {
                      _showSnack('Minimum bahis miktarı 50 Gümüştür!');
                      return;
                    }

                    HapticFeedback.heavyImpact();
                    int betAmount = _selectedBet;
                    notifier.buyPackage(addSilver: -betAmount);

                    int selectedSectorIndex = _random.nextInt(_wheelSectors.length);
                    var winningSector = _wheelSectors[selectedSectorIndex];
                    int multiplier = winningSector['multiplier'];

                    double sectorAngleTurns = (selectedSectorIndex / _wheelSectors.length) + (1 / (_wheelSectors.length * 2));
                    double currentWheelBase = (_wheelRotation.floor()).toDouble();
                    double targetWheelRotation = currentWheelBase + 5 + (1.0 - sectorAngleTurns);

                    setState(() {
                      _isSpinning = true;
                      _lastWheelResult = 'Top Yavaşlıyor... (-$betAmount Gümüş)';
                      _wheelRotation = targetWheelRotation;
                      _ballRotation = (_ballRotation.floor()).toDouble() - 5;
                    });

                    await Future.delayed(const Duration(seconds: 4));

                    if (!mounted) return;

                    int rewardSilver = betAmount * multiplier;
                    int netGain = rewardSilver - betAmount;
                    String msg = '';

                    if (multiplier == 0) {
                      msg = '💥 Top 0x Dilimine Düştü!\nHarcanan: $betAmount Gümüş | Kazanılan: 0 (Net: -$betAmount Gümüş)';
                    } else {
                      notifier.buyPackage(addSilver: rewardSilver);
                      msg = '🎉 Tebrikler! Top ${multiplier}x Dilimine Düştü!\nHarcanan: $betAmount | Kazanılan: $rewardSilver Gümüş (Net: +$netGain Gümüş)';
                      _triggerWinAnimation(0);
                    }

                    setState(() {
                      _isSpinning = false;
                      _lastWheelResult = msg;
                    });
                  },
            child: Text(
              _isSpinning ? 'ÇARK DÖNÜYOR...' : (_showWinOverlay ? 'KAZANILDI!' : 'TOPU YUVARLA ($_selectedBet Gümüş)'),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBetAdjustButton(String label, VoidCallback? onTap, {Color? color}) {
    return Expanded(
      child: SizedBox(
        height: 36,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? const Color(0xFF1E293B),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: const BorderSide(color: Colors.white12),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }

  // --- 2. GİZEM KASASI ---
  Widget _buildMysteryBoxGame(dynamic gameState, GameNotifier notifier) {
    const int cost = 10;
    bool isLocked = _isOpeningBox || _showWinOverlay;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.35)),
            ),
            child: Text(
              _lastBoxResult,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedScale(
            scale: _isOpeningBox ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purpleAccent.withOpacity(0.4),
                    Colors.deepPurple.shade900.withOpacity(0.2),
                  ],
                ),
                border: Border.all(color: Colors.purpleAccent, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.45),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Text('🎁', style: TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: isLocked
                ? null
                : () async {
                    if (gameState.goldCoins < cost) {
                      _showSnack('Yetersiz Altın! Gerekli: 10 Altın');
                      return;
                    }
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _isOpeningBox = true;
                      _lastBoxResult = 'Kasa Açılıyor... (-10 Altın)';
                    });

                    notifier.buyPackage(addGold: -cost);
                    await Future.delayed(const Duration(milliseconds: 600));

                    if (!mounted) return;

                    int outcome = _random.nextInt(3);
                    String msg = '';

                    if (outcome == 0) {
                      msg = '💥 Boş Çıktı!\nHarcanan: 10 Altın | Kazanılan: 0 (Net: -10 Altın)';
                    } else if (outcome == 1) {
                      notifier.buyPackage(addGold: 30);
                      msg = '🌟 Büyük Ödül! 30 Altın Çıktı!\nHarcanan: 10 Altın | Kazanılan: 30 (Net: +20 Altın)';
                      _triggerWinAnimation(1); // Çift çapraz şerit şelalesi
                    } else {
                      notifier.buyPackage(addGold: 10);
                      msg = '✨ Amorti! 10 Altın Geldi.\nHarcanan: 10 Altın | Kazanılan: 10 (Net: 0 Altın)';
                      _triggerWinAnimation(1);
                    }

                    setState(() {
                      _isOpeningBox = false;
                      _lastBoxResult = msg;
                    });
                  },
            child: Text(
              _isOpeningBox ? 'AÇILIYOR...' : (_showWinOverlay ? 'KAZANILDI!' : 'KASAYI AÇ (-10 Altın)'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          )
        ],
      ),
    );
  }

  // --- 3. ÇİFT ZAR ---
  Widget _buildDiceGame(dynamic gameState, GameNotifier notifier) {
    bool isLocked = _showWinOverlay;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
            ),
            child: Text(
              _lastDiceResult,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDiceTile(_diceResult1),
              const SizedBox(width: 16),
              _buildDiceTile(_diceResult2),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Text(
              'Toplam Zarlar: ${_diceResult1 + _diceResult2}',
              style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLocked ? null : () => _playDice(gameState, notifier, isHigh: false),
                  child: const Text(
                    '7\'den DÜŞÜK\n(-50 Gümüş)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLocked ? null : () => _playDice(gameState, notifier, isHigh: true),
                  child: const Text(
                    '7\'den YÜKSEK\n(-50 Gümüş)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _playDice(dynamic gameState, GameNotifier notifier, {required bool isHigh}) {
    const cost = 50;
    if (gameState.silverCoins < cost) {
      _showSnack('Yetersiz Gümüş! Gerekli: 50 Gümüş');
      return;
    }

    notifier.buyPackage(addSilver: -cost);

    int d1 = _random.nextInt(6) + 1;
    int d2 = _random.nextInt(6) + 1;
    int sum = d1 + d2;
    bool won = isHigh ? (sum > 7) : (sum < 7);

    String msg = '';
    if (sum == 7) {
      notifier.buyPackage(addSilver: cost);
      msg = '🎲 Zarlar Tam 7 Geldi (BERABERLİK)!\nBahis İade Edildi (+50 Gümüş | Net: 0 Gümüş)';
    } else if (won) {
      notifier.buyPackage(addSilver: cost * 2);
      msg = '🎉 Doğru Tahmin!\nHarcanan: 50 Gümüş | Kazanılan: 100 (Net: +50 Gümüş)';
      _triggerWinAnimation(2); // 5 Kulvarlı net dikey perde şelalesi
    } else {
      msg = '💥 Yanlış Tahmin!\nHarcanan: 50 Gümüş | Kazanılan: 0 (Net: -50 Gümüş)';
    }

    setState(() {
      _diceResult1 = d1;
      _diceResult2 = d2;
      _lastDiceResult = msg;
    });
  }

  Widget _buildDiceTile(int value) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  // --- 4. ŞANS KAZISI (MINES) ---
  Widget _buildMinesGame(dynamic gameState, GameNotifier notifier) {
    const int entryCost = 100;
    bool isLocked = _showWinOverlay;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.35)),
            ),
            child: Text(
              _minesStatusText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _minesGameActive ? 'Biriken Ödül: $_minesCurrentReward Gümüş' : 'Giriş Ücreti: $entryCost Gümüş',
            style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              bool isRevealed = _revealedTiles[index];
              bool isMine = _mineLocations[index];

              return InkWell(
                onTap: _minesGameActive && !isRevealed && !isLocked ? () => _revealMinesTile(index, notifier) : null,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isRevealed
                        ? (isMine ? Colors.red.shade900 : Colors.green.shade800)
                        : Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isRevealed ? Colors.white54 : Colors.cyanAccent.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isRevealed ? (isMine ? '💣' : '💰') : '❓',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          if (!_minesGameActive)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLocked
                  ? null
                  : () {
                      if (gameState.silverCoins < entryCost) {
                        _showSnack('Yetersiz Gümüş! Gerekli: 100 Gümüş');
                        return;
                      }
                      HapticFeedback.mediumImpact();
                      notifier.buyPackage(addSilver: -entryCost);

                      List<bool> mines = List.generate(9, (_) => false);
                      int placed = 0;
                      while (placed < 2) {
                        int r = _random.nextInt(9);
                        if (!mines[r]) {
                          mines[r] = true;
                          placed++;
                        }
                      }

                      setState(() {
                        _minesGameActive = true;
                        _revealedTiles = List.generate(9, (_) => false);
                        _mineLocations = mines;
                        _minesCurrentReward = 0;
                        _minesPickCount = 0;
                        _minesStatusText = 'Kare Seç! Mayından Kaçın!';
                      });
                    },
              child: const Text(
                'OYUNA BAŞLA (-100 Gümüş)',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade700,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_minesCurrentReward > 0 && !isLocked)
                  ? () {
                      HapticFeedback.heavyImpact();
                      notifier.buyPackage(addSilver: _minesCurrentReward);
                      int net = _minesCurrentReward - entryCost;

                      _triggerWinAnimation(3); // 360 Derece Halka Şok Dalgası

                      setState(() {
                        _minesGameActive = false;
                        _minesStatusText =
                            '🎉 Kazanç Çekildi!\nHarcanan: 100 Gümüş | Kazanılan: $_minesCurrentReward (Net: ${net >= 0 ? "+$net" : net} Gümüş)';
                      });
                    }
                  : null,
              child: Text(
                _minesCurrentReward > 0 ? 'KAZANCI TOPLA ($_minesCurrentReward Gümüş)' : 'BİR KARE SEÇ',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  void _revealMinesTile(int index, GameNotifier notifier) {
    HapticFeedback.lightImpact();
    bool isMine = _mineLocations[index];

    setState(() {
      _revealedTiles[index] = true;

      if (isMine) {
        _minesGameActive = false;
        _revealedTiles = List.generate(9, (_) => true);
        _minesStatusText = '💣 MAYINA BASTIN!\nHarcanan: 100 Gümüş | Kazanılan: 0 (Net: -100 Gümüş)';
      } else {
        _minesPickCount++;
        _minesCurrentReward = 100 + (_minesPickCount * 50) + (_minesPickCount * _minesPickCount * 10);
        _minesStatusText = '🔥 Başarılı! Devam et ya da kazancı topla!';

        if (_minesPickCount == 7) {
          notifier.buyPackage(addSilver: _minesCurrentReward);
          _minesGameActive = false;
          _minesStatusText =
              '🏆 MÜKEMMEL! TÜM GÜVENLİ KARELER AÇILDI!\nKazanılan: $_minesCurrentReward Gümüş';
          _triggerWinAnimation(3);
        }
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}

// --- PARTİKÜL MODELİ ---
class _ThematicWinParticle {
  final double startXRatio;
  final double startYRatio;
  final double vx;
  final double vy;
  final Color color;
  final String emoji;
  final double size;
  final double delay;

  _ThematicWinParticle({
    required this.startXRatio,
    required this.startYRatio,
    required this.vx,
    required this.vy,
    required this.color,
    required this.emoji,
    required this.size,
    required this.delay,
  });
}

// --- EN DİBE KADAR İNEN KESİNTİSİZ ŞERİT VE PERDE ÇİZİCİSİ ---
class _DeepCascadingWinPainter extends CustomPainter {
  final double progress;
  final List<_ThematicWinParticle> particles;
  final int tabIndex;

  _DeepCascadingWinPainter({
    required this.progress,
    required this.particles,
    required this.tabIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final p in particles) {
      if (progress < p.delay) continue;
      double localT = (progress - p.delay) / (1.0 - p.delay);
      if (localT > 1.0) localT = 1.0;

      double startX = size.width * p.startXRatio;
      double startY = size.height * p.startYRatio;

      double x = startX + p.vx * localT;
      double y = startY + p.vy * localT;

      // Sadece ekranın en alt sınırına (%92) ulaşıldığında yumuşakça kaybolur
      double opacity = y > (size.height * 0.88)
          ? ((size.height - y) / (size.height * 0.12)).clamp(0.0, 1.0)
          : (localT > 0.90 ? (1.0 - localT) / 0.10 : 1.0);

      // İkon arkasında net görünürlük sağlayan neon aura
      final glowPaint = Paint()
        ..color = p.color.withOpacity((opacity * 0.55).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(x, y), p.size * 0.45, glowPaint);

      // Titreşimsiz, iri ve doğrudan gözle seçilen emoji
      textPainter.text = TextSpan(
        text: p.emoji,
        style: TextStyle(
          fontSize: p.size,
          color: Colors.white.withOpacity(opacity.clamp(0.0, 1.0)),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DeepCascadingWinPainter oldDelegate) => true;
}

// --- DÜZENLİ VE YOĞUN İKON DUVAR KAĞIDI ÇİZİCİ ---
class _DenseIconWallpaperPainter extends CustomPainter {
  final int tabIndex;

  _DenseIconWallpaperPainter({required this.tabIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    List<Color> gradientColors;
    List<String> icons;
    Color iconColor;

    switch (tabIndex) {
      case 0:
        gradientColors = const [Color(0xFF0F3A27), Color(0xFF082015), Color(0xFF030E09)];
        icons = ['🎡', '🪙', '⭐', '💎', '♠️', '♥️'];
        iconColor = Colors.amber.withOpacity(0.18);
        break;
      case 1:
        gradientColors = const [Color(0xFF381478), Color(0xFF1B0A3B), Color(0xFF0A0318)];
        icons = ['🎁', '📦', '✨', '💎', '🗝️', '👑'];
        iconColor = Colors.purpleAccent.withOpacity(0.22);
        break;
      case 2:
        gradientColors = const [Color(0xFF5C0B22), Color(0xFF300411), Color(0xFF120106)];
        icons = ['🎲', '🎯', '🔥', '🏆', '♦️', '♣️'];
        iconColor = Colors.redAccent.withOpacity(0.22);
        break;
      case 3:
      default:
        gradientColors = const [Color(0xFF0C3D5E), Color(0xFF061E2E), Color(0xFF020D14)];
        icons = ['⛏️', '💣', '💎', '💰', '🛡️', '⚡'];
        iconColor = Colors.cyanAccent.withOpacity(0.22);
        break;
    }

    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 1.2,
        colors: gradientColors,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final gridPaint = Paint()
      ..color = iconColor.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double cellSize = 54.0;
    for (double x = -size.height; x < size.width + size.height; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), gridPaint);
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), gridPaint);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    int iconIdx = 0;

    for (double y = 20; y < size.height; y += cellSize) {
      final double rowOffset = ((y ~/ cellSize) % 2) * (cellSize / 2);
      for (double x = rowOffset; x < size.width; x += cellSize) {
        final glyph = icons[iconIdx % icons.length];
        iconIdx++;

        textPainter.text = TextSpan(
          text: glyph,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.13),
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DenseIconWallpaperPainter oldDelegate) =>
      oldDelegate.tabIndex != tabIndex;
}

class WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> sectors;

  WheelPainter({required this.sectors});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double sweepAngle = (2 * pi) / sectors.length;

    for (int i = 0; i < sectors.length; i++) {
      final double startAngle = (i * sweepAngle) - (pi / 2);

      final Paint sectorPaint = Paint()
        ..color = sectors[i]['color'] as Color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        sectorPaint,
      );

      final Paint linePaint = Paint()
        ..color = Colors.amber.withOpacity(0.5)
        ..strokeWidth = 2;

      final double lineAngle = startAngle;
      final Offset lineEdge = Offset(
        center.dx + radius * cos(lineAngle),
        center.dy + radius * sin(lineAngle),
      );
      canvas.drawLine(center, lineEdge, linePaint);

      final String label = sectors[i]['label'] as String;
      final double textAngle = startAngle + (sweepAngle / 2);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double textRadius = radius * 0.65;
      final Offset textCenter = Offset(
        center.dx + textRadius * cos(textAngle),
        center.dy + textRadius * sin(textAngle),
      );

      canvas.save();
      canvas.translate(textCenter.dx, textCenter.dy);
      canvas.rotate(textAngle + (pi / 2));
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}