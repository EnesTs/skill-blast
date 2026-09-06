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
  final Random _random = Random();

  // 🎡 Rulet Çarkı & Top Durumu
  bool _isSpinning = false;
  String _lastWheelResult = 'Bahsini Seç ve Topu Yuvarla!';
  double _wheelRotation = 0;
  double _ballRotation = 0;
  int _selectedBet = 50; // Min bahis 50 Gümüş

  // 📦 Gizem Kasası
  bool _isOpeningBox = false;
  String _lastBoxResult = 'Kutudan ne çıkacağını gör!';

  // 🎲 Çift Zar
  int _diceResult1 = 1;
  int _diceResult2 = 1;
  String _lastDiceResult = 'Tahminini Yap!';

  // ⛏️ Şans Kazısı (Mines)
  bool _minesGameActive = false;
  List<bool> _revealedTiles = List.generate(9, (_) => false);
  List<bool> _mineLocations = List.generate(9, (_) => false);
  int _minesCurrentReward = 0;
  int _minesPickCount = 0;
  String _minesStatusText = 'Mayınlara basmadan altınları topla!';

  // Çark Dilimleri (8 Sektör)
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
    _rouletteController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rouletteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '🎡 ŞANS SALONU',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),

          TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Text('🎡', style: TextStyle(fontSize: 16)), text: 'Top & Çark'),
              Tab(icon: Text('📦', style: TextStyle(fontSize: 16)), text: 'Kasa'),
              Tab(icon: Text('🎲', style: TextStyle(fontSize: 16)), text: 'Zar'),
              Tab(icon: Text('⛏️', style: TextStyle(fontSize: 16)), text: 'Kazı'),
            ],
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
    );
  }

  // --- 1. TOP & RULET ÇARKI ---
  Widget _buildBallRouletteGame(dynamic gameState, GameNotifier notifier) {
    int maxSilver = gameState.silverCoins;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        children: [
          Text(
            _lastWheelResult,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
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
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 15,
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
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
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
                    _buildBetAdjustButton('-50', () {
                      if (_selectedBet > 50) {
                        setState(() => _selectedBet = max(50, _selectedBet - 50));
                      }
                    }),
                    const SizedBox(width: 8),
                    _buildBetAdjustButton('+50', () {
                      setState(() => _selectedBet += 50);
                    }),
                    const SizedBox(width: 8),
                    _buildBetAdjustButton('+100', () {
                      setState(() => _selectedBet += 100);
                    }),
                    const SizedBox(width: 8),
                    _buildBetAdjustButton('MAX', () {
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
            ),
            onPressed: _isSpinning
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
                    }

                    setState(() {
                      _isSpinning = false;
                      _lastWheelResult = msg;
                    });
                  },
            child: Text(
              _isSpinning ? 'ÇARK DÖNÜYOR...' : 'TOPU YUVARLA ($_selectedBet Gümüş)',
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

  Widget _buildBetAdjustButton(String label, VoidCallback onTap, {Color? color}) {
    return Expanded(
      child: SizedBox(
        height: 36,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? const Color(0xFF334155),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isSpinning ? null : onTap,
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

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _lastBoxResult,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedScale(
            scale: _isOpeningBox ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: const Text('🎁', style: TextStyle(fontSize: 70)),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: _isOpeningBox
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
                    } else {
                      notifier.buyPackage(addGold: 10);
                      msg = '✨ Amorti! 10 Altın Geldi.\nHarcanan: 10 Altın | Kazanılan: 10 (Net: 0 Altın)';
                    }

                    setState(() {
                      _isOpeningBox = false;
                      _lastBoxResult = msg;
                    });
                  },
            child: const Text(
              'KASAYI AÇ (-10 Altın)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  // --- 3. ÇİFT ZAR (7 İADE SİSTEMİ EKLENDİ) ---
  Widget _buildDiceGame(dynamic gameState, GameNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _lastDiceResult,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
          Text(
            'Toplam Zarlar: ${_diceResult1 + _diceResult2}',
            style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _playDice(gameState, notifier, isHigh: false),
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
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _playDice(gameState, notifier, isHigh: true),
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
      // 🔄 7 Geldiğinde 50 Gümüş İade Edilir
      notifier.buyPackage(addSilver: cost);
      msg = '🎲 Zarlar Tam 7 Geldi (BERABERLİK)!\nBahis İade Edildi (+50 Gümüş | Net: 0 Gümüş)';
    } else if (won) {
      notifier.buyPackage(addSilver: cost * 2);
      msg = '🎉 Doğru Tahmin!\nHarcanan: 50 Gümüş | Kazanılan: 100 (Net: +50 Gümüş)';
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- 4. ŞANS KAZISI (MINES) ---
  Widget _buildMinesGame(dynamic gameState, GameNotifier notifier) {
    const int entryCost = 100;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _minesStatusText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                onTap: _minesGameActive && !isRevealed ? () => _revealMinesTile(index, notifier) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isRevealed
                        ? (isMine ? Colors.red.shade900 : Colors.green.shade800)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRevealed ? Colors.white54 : Colors.amber.withOpacity(0.3),
                      width: 1.5,
                    ),
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
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () {
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
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: _minesCurrentReward > 0
                  ? () {
                      HapticFeedback.heavyImpact();
                      notifier.buyPackage(addSilver: _minesCurrentReward);
                      int net = _minesCurrentReward - entryCost;

                      setState(() {
                        _minesGameActive = false;
                        _minesStatusText =
                            '🎉 Kazanç Çekildi!\nHarcanan: 100 Gümüş | Kazanılan: $_minesCurrentReward (Net: ${net >= 0 ? "+$net" : net} Gümüş)';
                      });
                    }
                  : null,
              child: Text(
                _minesCurrentReward > 0 ? 'KAZANCI TOPLA ($_minesCurrentReward Gümüş)' : 'BİR KARE SEÇ',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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