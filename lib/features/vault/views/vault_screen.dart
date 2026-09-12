import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3/features/game/logic/game_notifier.dart';
import '../logic/vault_notifier.dart';
import '../models/relic_model.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen>
    with TickerProviderStateMixin {
  late AnimationController _ambientController;
  late AnimationController _weatherController;
  late AnimationController _fireController;
  late AnimationController _particleController;
  final ScrollController _scrollController = ScrollController();

  int _selectedSeason = 0; // 0: Bahar, 1: Yaz, 2: Güz, 3: Kış
  bool _isNight = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _weatherController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _weatherController.dispose();
    _fireController.dispose();
    _particleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- SAĞ ALTTAKİ BUTONA BASILDIĞINDA AÇILAN GELİŞMİŞ ATMOSFER MENÜSÜ ---
  void _showAtmosphereSettingsModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Atmosfer & Zaman Ayarı',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 1. GECE / GÜNDÜZ SEÇİMİ
                  const Text('GÖKYÜZÜ VE ZAMAN',
                      style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeOptionBtn(
                          title: 'Gündüz',
                          emoji: '☀️',
                          isSelected: !_isNight,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isNight = false);
                            setModalState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeOptionBtn(
                          title: 'Gece',
                          emoji: '🌙',
                          isSelected: _isNight,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isNight = true);
                            setModalState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. MEVSİM SEÇİMİ
                  const Text('MEVSİM HAVA DURUMU',
                      style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSeasonTile(0, '🌸', 'İlkbahar', setModalState),
                      _buildSeasonTile(1, '☀️', 'Yaz', setModalState),
                      _buildSeasonTile(2, '🍁', 'Sonbahar', setModalState),
                      _buildSeasonTile(3, '❄️', 'Kış', setModalState),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeOptionBtn({
    required String title,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withValues(alpha: 0.25) : Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? Colors.amber : Colors.white24, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.amber : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonTile(int index, String emoji, String title, StateSetter setModalState) {
    final bool isSelected = _selectedSeason == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedSeason = index);
        setModalState(() {});
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withValues(alpha: 0.22) : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.amber : Colors.white24, width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.amber : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChamberDetail(BuildContext context, RelicData relic, RelicProgress prog) {
    HapticFeedback.mediumImpact();
    final isLocked = prog.level == 0;
    final isMax = prog.level == 2;
    final unit = relic.rewardType == RelicRewardType.gold ? 'Altın' : 'Gümüş';
    final vaultNotif = ref.read(vaultProvider.notifier);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1422),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: relic.themeColor, width: 2),
        ),
        title: Row(
          children: [
            Icon(relic.icon, color: relic.themeColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                relic.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(relic.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildModalRow('Toplam Prestij:', '+${prog.level == 1 ? relic.level1Prestige : (prog.level == 2 ? relic.level1Prestige + relic.level2Prestige : 0)} Puan', Colors.purpleAccent),
                  const SizedBox(height: 8),
                  _buildModalRow(
                    'Şu Anki Üretim:',
                    isLocked ? 'Kilitli' : '${prog.level == 1 ? relic.level1HoursPerTick : relic.level2HoursPerTick} Saatte ${prog.level == 1 ? relic.level1RewardAmount : relic.level2RewardAmount} $unit',
                    Colors.amber,
                  ),
                  if (!isMax) ...[
                    const Divider(color: Colors.white10, height: 16),
                    _buildModalRow(
                      isLocked ? 'Açılış Bonusu:' : 'Lv.2 Yükseltme:',
                      isLocked
                          ? '${relic.level1HoursPerTick} Saatte ${relic.level1RewardAmount} $unit (+${relic.level1Prestige} P)'
                          : '${relic.level2HoursPerTick} Saatte ${relic.level2RewardAmount} $unit (+${relic.level2Prestige} P)',
                      Colors.greenAccent,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(color: Colors.white54)),
          ),
          if (isLocked)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade600),
              onPressed: () {
                vaultNotif.unlockRelic(relic);
                Navigator.pop(ctx);
              },
              child: Text('KİLİDİ AÇ (${relic.unlockCost} Altın)', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          else if (!isMax)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700),
              onPressed: () {
                vaultNotif.upgradeRelic(relic);
                Navigator.pop(ctx);
              },
              child: Text('GELİŞTİR (${relic.upgradeCost} Altın)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildModalRow(String title, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final vaultNotif = ref.read(vaultProvider.notifier);
    final gameState = ref.watch(gameProvider);

    int totalPendingGold = 0;
    int totalPendingSilver = 0;

    for (var data in RelicData.allRelics) {
      int p = vaultState.getPendingReward(data);
      if (data.rewardType == RelicRewardType.gold) {
        totalPendingGold += p;
      } else {
        totalPendingSilver += p;
      }
    }

    final hasPending = totalPendingGold > 0 || totalPendingSilver > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0503),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildIllustratedSurface(),
                _buildLivingUndergroundSpire(vaultState, vaultNotif),
              ],
            ),
          ),

          // ÜST HUD BARI (SABİT)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopHUD(context, gameState, vaultState),
          ),

          // SAĞ ALT KÖŞEDE SENİNLE AŞAĞI YUKARI GELEN YÜZEN ATMOSFER BUTONU
          Positioned(
            right: 18,
            bottom: 86,
            child: _buildFloatingAtmosphereButton(),
          ),

          // ALT TOPLAMA BUTONU (SABİT)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _buildBottomCollectButton(
              hasPending: hasPending,
              gold: totalPendingGold,
              silver: totalPendingSilver,
              onCollectAll: () {
                HapticFeedback.heavyImpact();
                vaultNotif.collectAllRewards();
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- SAĞ ALTTTAKİ YÜZEN ATMOSFER / HAVA DURUMU BUTONU ---
  Widget _buildFloatingAtmosphereButton() {
    return GestureDetector(
      onTap: () => _showAtmosphereSettingsModal(context),
      child: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.6 + _ambientController.value * 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.2 + _ambientController.value * 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_getSeasonEmoji()} ${_isNight ? '🌙' : '☀️'}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Hava',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const Icon(Icons.tune_rounded, color: Colors.amber, size: 14),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIllustratedSurface() {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _isNight
              ? [const Color(0xFF030511), const Color(0xFF0A1224), const Color(0xFF142038)]
              : (_selectedSeason == 3
                  ? [const Color(0xFF4C657D), const Color(0xFF7690A8), const Color(0xFFCAD8E6)]
                  : [const Color(0xFF0284C7), const Color(0xFF38BDF8), const Color(0xFFBAE6FD)]),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _weatherController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _IllustratedWeatherPainter(
                    progress: _weatherController.value,
                    season: _selectedSeason,
                    isNight: _isNight,
                  ),
                );
              },
            ),
          ),

          // GÜNEŞ VEYA AY
          Positioned(
            top: 110,
            right: 32,
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isNight ? const Color(0xFFF1F5F9) : const Color(0xFFFBBF24),
                    boxShadow: [
                      BoxShadow(
                        color: _isNight
                            ? Colors.cyanAccent.withValues(alpha: 0.4 + _ambientController.value * 0.3)
                            : Colors.amber.withValues(alpha: 0.6 + _ambientController.value * 0.3),
                        blurRadius: 35,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(_isNight ? '🌙' : '☀️', style: const TextStyle(fontSize: 28)),
                  ),
                );
              },
            ),
          ),

          // MANZARA ÇİZİMİ (EV, ÇİTLER, KUYU)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 140,
            child: CustomPaint(
              painter: _SurfaceLandscapePainter(
                season: _selectedSeason,
                isNight: _isNight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivingUndergroundSpire(VaultState vaultState, VaultNotifier vaultNotif) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F0805),
      child: Column(
        children: [
          ...RelicData.allRelics.asMap().entries.map((entry) {
            final index = entry.key;
            final relic = entry.value;
            final prog = vaultState.relics[relic.id] ??
                RelicProgress(level: 0, lastCollectTime: DateTime.now());
            final pending = vaultState.getPendingReward(relic);

            return _VignetteChamberFloor(
              floorIndex: index + 1,
              relic: relic,
              progress: prog,
              pendingReward: pending,
              fireFlicker: _fireController,
              ambientPulse: _ambientController,
              particleAnim: _particleController,
              onCollect: () {
                HapticFeedback.lightImpact();
                vaultNotif.collectRelicReward(relic);
              },
              onInspect: () {
                _showChamberDetail(context, relic, prog);
              },
            );
          }),
          const SizedBox(height: 130),
        ],
      ),
    );
  }

  Widget _buildTopHUD(BuildContext context, dynamic gameState, VaultState vaultState) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 14,
        right: 14,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        border: const Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.amber, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              _buildBadge(Icons.monetization_on, Colors.amber, '${gameState.goldCoins}'),
              const SizedBox(width: 8),
              _buildBadge(Icons.monetization_on_outlined, Colors.grey.shade300, '${gameState.silverCoins}'),
              const SizedBox(width: 8),
              _buildBadge(Icons.shield_rounded, Colors.purpleAccent, '${vaultState.totalPrestige} P'),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade900.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              vaultState.leagueName,
              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBottomCollectButton({
    required bool hasPending,
    required int gold,
    required int silver,
    required VoidCallback onCollectAll,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (hasPending)
            BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 3),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasPending ? Colors.amber.shade600 : const Color(0xFF1E293B),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: hasPending ? onCollectAll : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings_rounded, color: hasPending ? Colors.black : Colors.white24),
            const SizedBox(width: 8),
            Text(
              hasPending
                  ? 'TÜM MAHZENİ TOPLA (+${gold} Altın, +${silver} Gümüş)'
                  : 'BİRİKEN MADEN YOK',
              style: TextStyle(
                color: hasPending ? Colors.black : Colors.white24,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSeasonEmoji() {
    switch (_selectedSeason) {
      case 0: return '🌸';
      case 1: return '☀️';
      case 2: return '🍁';
      case 3: return '❄️';
      default: return '🌸';
    }
  }
}

class _VignetteChamberFloor extends StatelessWidget {
  final int floorIndex;
  final RelicData relic;
  final RelicProgress progress;
  final int pendingReward;
  final Animation<double> fireFlicker;
  final Animation<double> ambientPulse;
  final Animation<double> particleAnim;
  final VoidCallback onCollect;
  final VoidCallback onInspect;

  const _VignetteChamberFloor({
    required this.floorIndex,
    required this.relic,
    required this.progress,
    required this.pendingReward,
    required this.fireFlicker,
    required this.ambientPulse,
    required this.particleAnim,
    required this.onCollect,
    required this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    final locked = progress.level == 0;

    return SizedBox(
      height: 245,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            left: 48,
            right: 12,
            top: 8,
            bottom: 12,
            child: GestureDetector(
              onTap: onInspect,
              child: AnimatedBuilder(
                animation: Listenable.merge([fireFlicker, ambientPulse]),
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ArchitecturalBackdropPainter(
                      floorIndex: floorIndex,
                      locked: locked,
                      themeColor: relic.themeColor,
                      fireFlicker: fireFlicker,
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned(
            left: 56,
            right: 20,
            top: 18,
            bottom: 42,
            child: GestureDetector(
              onTap: onInspect,
              child: _buildChamberContents(locked),
            ),
          ),

          if (!locked)
            Positioned(
              left: 55,
              right: 20,
              top: 15,
              bottom: 40,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: particleAnim,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ChamberParticlesPainter(
                        floorIndex: floorIndex,
                        progress: particleAnim.value,
                        themeColor: relic.themeColor,
                      ),
                    );
                  },
                ),
              ),
            ),

          Positioned(
            left: 3,
            top: 0,
            bottom: 0,
            width: 50,
            child: AnimatedBuilder(
              animation: fireFlicker,
              builder: (context, child) {
                return CustomPaint(
                  painter: _VerticalStairsPainter(
                    locked: locked,
                    fireFlicker: fireFlicker,
                  ),
                );
              },
            ),
          ),

          Positioned(
            left: 13,
            top: 16,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked ? const Color(0xFF25201C) : relic.themeColor.withValues(alpha: .9),
                border: Border.all(color: locked ? Colors.white24 : Colors.white.withValues(alpha: .7), width: 1.5),
                boxShadow: [
                  if (!locked) BoxShadow(color: relic.themeColor.withValues(alpha: .5), blurRadius: 12),
                ],
              ),
              child: Center(
                child: Text(
                  '$floorIndex',
                  style: TextStyle(color: locked ? Colors.white38 : Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ),
          ),

          Positioned(
            left: 82,
            top: 17,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .75),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: locked ? Colors.white12 : relic.themeColor.withValues(alpha: .6)),
              ),
              child: Text(
                _floorName(floorIndex),
                style: TextStyle(
                  color: locked ? Colors.white30 : Colors.white.withValues(alpha: .95),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),

          Positioned(
            right: 28,
            top: 17,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .75),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: locked ? Colors.white12 : relic.themeColor.withValues(alpha: .6)),
              ),
              child: Text(
                locked ? 'KİLİTLİ' : 'LV.${progress.level}',
                style: TextStyle(
                  color: locked ? Colors.white38 : Colors.amberAccent,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          if (locked)
            Positioned.fill(
              left: 48,
              right: 12,
              top: 8,
              bottom: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber.shade700, width: 2),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.amber, size: 28),
                  ),
                ),
              ),
            ),

          Positioned(
            left: 74,
            right: 25,
            bottom: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onCollect,
                  child: AnimatedBuilder(
                    animation: ambientPulse,
                    builder: (context, child) {
                      double pulseScale = pendingReward > 0 ? 1.0 + sin(ambientPulse.value * pi) * 0.05 : 1.0;
                      return Transform.scale(
                        scale: pulseScale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: pendingReward > 0 ? Colors.greenAccent : (locked ? Colors.white12 : Colors.amber.withValues(alpha: 0.4)),
                              width: pendingReward > 0 ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              if (pendingReward > 0)
                                BoxShadow(color: Colors.greenAccent.withValues(alpha: .45), blurRadius: 12, spreadRadius: 1),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                pendingReward > 0 ? Icons.auto_awesome : (locked ? Icons.lock_outline : Icons.inventory_2_outlined),
                                color: pendingReward > 0 ? Colors.greenAccent : Colors.white38,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                pendingReward > 0 ? '+$pendingReward (TOPLA)' : (locked ? 'KİLİTLİ' : 'ÜRETİLİYOR'),
                                style: TextStyle(
                                  color: pendingReward > 0 ? Colors.greenAccent : Colors.white54,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                GestureDetector(
                  onTap: onInspect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: locked
                          ? Colors.amber.shade700
                          : progress.level == 1
                              ? Colors.green.shade700
                              : Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        if (!locked && progress.level == 1)
                          BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 8),
                      ],
                    ),
                    child: Text(
                      locked ? 'KİLİDİ AÇ' : (progress.level == 1 ? 'GELİŞTİR' : 'MAKS'),
                      style: TextStyle(
                        color: locked ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 8.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamberContents(bool locked) {
    Color itemColor = locked ? Colors.white24 : relic.themeColor;

    switch (floorIndex) {
      case 1:
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 18,
              bottom: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.inventory_2_rounded, size: 22, color: Colors.brown.shade400),
                  const SizedBox(width: 4),
                  Icon(Icons.widgets_rounded, size: 18, color: Colors.brown.shade300),
                ],
              ),
            ),
            Positioned(
              right: 22,
              bottom: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.archive_rounded, size: 22, color: Colors.brown.shade600),
                  const SizedBox(width: 4),
                  Icon(Icons.monetization_on_outlined, size: 16, color: Colors.amber.shade600),
                ],
              ),
            ),
            Positioned(
              bottom: 38,
              child: Icon(relic.icon, size: 26, color: itemColor),
            ),
          ],
        );

      case 2:
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 20,
              top: 24,
              child: Icon(Icons.menu_book_rounded, size: 18, color: Colors.brown.shade300),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              child: Icon(Icons.chair_rounded, size: 20, color: Colors.brown.shade400),
            ),
            Positioned(
              bottom: 48,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(relic.icon, size: 22, color: itemColor),
                  const SizedBox(width: 8),
                  Icon(Icons.wine_bar_rounded, size: 18, color: Colors.amber.shade700),
                ],
              ),
            ),
            Positioned(
              right: 28,
              bottom: 26,
              child: Icon(Icons.local_fire_department_rounded, size: 24, color: Colors.orangeAccent.shade700),
            ),
          ],
        );

      case 3:
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: 20.0,
              bottom: 24,
              child: Row(
                children: [
                  Icon(Icons.savings_rounded, size: 22, color: Colors.amber.shade600),
                  const SizedBox(width: 4),
                  Icon(Icons.monetization_on_rounded, size: 16, color: Colors.amber.shade400),
                ],
              ),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              child: Icon(Icons.fireplace_rounded, size: 22, color: Colors.orange.shade800),
            ),
            Positioned(
              bottom: 44,
              child: Icon(relic.icon, size: 26, color: itemColor),
            ),
          ],
        );

      case 4:
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 18,
              top: 24,
              child: Icon(Icons.build_rounded, size: 18, color: Colors.blueGrey.shade400),
            ),
            Positioned(
              left: 20,
              bottom: 22,
              child: Icon(Icons.hardware_rounded, size: 20, color: Colors.brown.shade400),
            ),
            Positioned(
              right: 22,
              top: 24,
              child: Icon(Icons.science_rounded, size: 20, color: Colors.greenAccent.shade400),
            ),
            Positioned(
              bottom: 46,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 18, color: Colors.purple.shade300),
                  const SizedBox(width: 8),
                  Icon(relic.icon, size: 24, color: itemColor),
                ],
              ),
            ),
          ],
        );

      case 5:
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 18,
              top: 18,
              bottom: 22,
              child: Icon(Icons.view_column_rounded, size: 34, color: Colors.blueGrey.shade700),
            ),
            Positioned(
              right: 22,
              top: 18,
              bottom: 22,
              child: Icon(Icons.view_column_rounded, size: 34, color: Colors.blueGrey.shade700),
            ),
            AnimatedBuilder(
              animation: ambientPulse,
              builder: (context, child) {
                double float = sin(ambientPulse.value * pi) * 5.0;
                return Positioned(
                  bottom: 34 + float,
                  child: Icon(relic.icon, size: 34, color: itemColor),
                );
              },
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  String _floorName(int index) {
    switch (index) {
      case 1: return '1. KAT  •  DEPO ODASI';
      case 2: return '2. KAT  •  YAŞAM ODASI';
      case 3: return '3. KAT  •  HAZİNE ODASI';
      case 4: return '4. KAT  •  ATÖLYE ODASI';
      case 5: return '5. KAT  •  GİZLİ SU TAPINAĞI';
      default: return '$index. KAT';
    }
  }
}

class _ArchitecturalBackdropPainter extends CustomPainter {
  final int floorIndex;
  final bool locked;
  final Color themeColor;
  final Animation<double> fireFlicker;

  _ArchitecturalBackdropPainter({
    required this.floorIndex,
    required this.locked,
    required this.themeColor,
    required this.fireFlicker,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final room = Rect.fromLTWH(0, 0, size.width, size.height);

    final wallPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 0.9,
        colors: locked
            ? const [Color(0xFF16100C), Color(0xFF060403)]
            : [Color.lerp(const Color(0xFF332015), themeColor, .15)!, const Color(0xFF0D0805)],
      ).createShader(room);
    canvas.drawRect(room, wallPaint);

    final mortar = Paint()..color = Colors.black.withValues(alpha: .4)..strokeWidth = 1.1;
    for (double y = 22; y < size.height * .75; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), mortar);
      final double offset = (((y ~/ 22) % 2) * 26).toDouble();
      for (double x = offset; x < size.width; x += 52) {
        canvas.drawLine(Offset(x, y - 22), Offset(x, y), mortar);
      }
    }

    final beamPaint = Paint()..color = const Color(0xFF28180E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 15), beamPaint);
    final beamHighlight = Paint()..color = const Color(0xFF4A2F1D)..strokeWidth = 1.5;
    canvas.drawLine(const Offset(0, 15), Offset(size.width, 15), beamHighlight);

    final postPaint = Paint()..color = const Color(0xFF22140C);
    canvas.drawRect(Rect.fromLTWH(size.width * .11, 0, 10, size.height * .78), postPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * .84, 0, 10, size.height * .78), postPaint);

    final floorTop = size.height * .75;
    final floorRect = Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop);
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3D2C21), Color(0xFF18100A)],
        ).createShader(floorRect),
    );

    final stoneLine = Paint()..color = Colors.black.withValues(alpha: .45)..strokeWidth = 1.2;
    for (double y = floorTop + 14; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), stoneLine);
    }
    for (double x = 12; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, floorTop), Offset(x - 10, size.height), stoneLine);
    }

    if (!locked && floorIndex <= 3) {
      final carpetRect = Rect.fromLTWH(size.width * .20, floorTop + 5, size.width * .56, 32);
      canvas.drawRRect(RRect.fromRectAndRadius(carpetRect, const Radius.circular(4)), Paint()..color = const Color(0xFF6B1817));
      canvas.drawRRect(RRect.fromRectAndRadius(carpetRect.deflate(3), const Radius.circular(2)), Paint()..color = const Color(0xFFB57038)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }

    switch (floorIndex) {
      case 1:
        _drawWallShelf(canvas, Offset(size.width * .16, size.height * .24), 70, 68);
        _drawWallShelf(canvas, Offset(size.width * .72, size.height * .24), 68, 68);
        final anvilBase = Paint()..color = const Color(0xFF383C42);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width * 0.50, size.height * 0.70), width: 44, height: 16), const Radius.circular(3)), anvilBase);
        break;

      case 2:
        _drawFireplace(canvas, size);
        _drawDiningTable(canvas, size);
        break;

      case 3:
        _drawVectorGuardianNiche(canvas, size);
        final pedestal = Paint()..color = const Color(0xFF4A2E1F);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width * 0.50, size.height * 0.70), width: 50, height: 18), const Radius.circular(4)), pedestal);
        break;

      case 4:
        _drawWallShelf(canvas, Offset(size.width * .14, size.height * .20), 72, 75);
        _drawWallShelf(canvas, Offset(size.width * .74, size.height * .20), 66, 75);
        _drawAlignedWorkbench(canvas, size);
        break;

      case 5:
        _drawSacredPool(canvas, size);
        break;
    }

    if (!locked) {
      _drawTorchGlow(canvas, Offset(24, size.height * .38));
      _drawTorchGlow(canvas, Offset(size.width - 24, size.height * .38));
    }

    canvas.drawRect(room, Paint()..color = const Color(0xFF422C1D)..style = PaintingStyle.stroke..strokeWidth = 4);
  }

  void _drawVectorGuardianNiche(Canvas canvas, Size size) {
    final cx = size.width * 0.50;

    final nicheRect = Rect.fromLTWH(cx - 36, size.height * 0.16, 72, size.height * 0.52);
    final nichePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0D0A08),
          const Color(0xFF1A130E),
        ],
      ).createShader(nicheRect);

    final nichePath = Path()
      ..moveTo(cx - 36, size.height * 0.68)
      ..lineTo(cx - 36, size.height * 0.28)
      ..quadraticBezierTo(cx, size.height * 0.14, cx + 36, size.height * 0.28)
      ..lineTo(cx + 36, size.height * 0.68)
      ..close();
    canvas.drawPath(nichePath, nichePaint);

    final archBorder = Paint()
      ..color = const Color(0xFF422E22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(nichePath, archBorder);

    final stoneGuardianPaint = Paint()
      ..color = locked ? const Color(0xFF26201B) : const Color(0xFF3E362E);

    final headPath = Path()
      ..moveTo(cx - 9, size.height * 0.29)
      ..lineTo(cx, size.height * 0.21)
      ..lineTo(cx + 9, size.height * 0.29)
      ..lineTo(cx + 6, size.height * 0.35)
      ..lineTo(cx - 6, size.height * 0.35)
      ..close();
    canvas.drawPath(headPath, stoneGuardianPaint);

    final hornPath = Path()
      ..moveTo(cx - 13, size.height * 0.23)
      ..lineTo(cx - 7, size.height * 0.27)
      ..lineTo(cx - 6, size.height * 0.24)
      ..close();
    canvas.drawPath(hornPath, stoneGuardianPaint);

    final hornPathRight = Path()
      ..moveTo(cx + 13, size.height * 0.23)
      ..lineTo(cx + 7, size.height * 0.27)
      ..lineTo(cx + 6, size.height * 0.24)
      ..close();
    canvas.drawPath(hornPathRight, stoneGuardianPaint);

    final bodyPath = Path()
      ..moveTo(cx - 16, size.height * 0.36)
      ..lineTo(cx + 16, size.height * 0.36)
      ..lineTo(cx + 12, size.height * 0.56)
      ..lineTo(cx - 12, size.height * 0.56)
      ..close();
    canvas.drawPath(bodyPath, stoneGuardianPaint);

    final bladePaint = Paint()
      ..color = locked ? const Color(0xFF332B25) : const Color(0xFF5A524A)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(cx, size.height * 0.34), Offset(cx, size.height * 0.65), bladePaint);
    canvas.drawLine(Offset(cx - 7, size.height * 0.40), Offset(cx + 7, size.height * 0.40), bladePaint);

    final bannerPaint = Paint()..color = const Color(0xFF7F1D1D);
    final bLeft = Path()
      ..moveTo(cx - 40, size.height * 0.22)
      ..lineTo(cx - 30, size.height * 0.22)
      ..lineTo(cx - 32, size.height * 0.52)
      ..lineTo(cx - 35, size.height * 0.48)
      ..lineTo(cx - 38, size.height * 0.52)
      ..close();
    canvas.drawPath(bLeft, bannerPaint);

    final bRight = Path()
      ..moveTo(cx + 30, size.height * 0.22)
      ..lineTo(cx + 40, size.height * 0.22)
      ..lineTo(cx + 38, size.height * 0.52)
      ..lineTo(cx + 35, size.height * 0.48)
      ..lineTo(cx + 32, size.height * 0.52)
      ..close();
    canvas.drawPath(bRight, bannerPaint);
  }

  void _drawWallShelf(Canvas canvas, Offset pos, double width, double height) {
    canvas.drawRect(Rect.fromLTWH(pos.dx, pos.dy, width, height), Paint()..color = const Color(0xFF3B2011));
    final shelf = Paint()..color = const Color(0xFF6B3E1E);
    for (int i = 1; i < 4; i++) {
      final y = pos.dy + (height / 4) * i;
      canvas.drawRect(Rect.fromLTWH(pos.dx, y, width, 3.5), shelf);
    }
  }

  void _drawFireplace(Canvas canvas, Size size) {
    final fpRect = Rect.fromLTWH(size.width * .77, size.height * .30, 58, 70);
    canvas.drawRRect(RRect.fromRectAndRadius(fpRect, const Radius.circular(6)), Paint()..color = const Color(0xFF2A1911));

    if (!locked) {
      final fireGlow = Paint()..color = Colors.orangeAccent.withValues(alpha: .4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(Offset(size.width * .85, size.height * .56), 16, fireGlow);
    }
  }

  void _drawDiningTable(Canvas canvas, Size size) {
    final table = Paint()..color = const Color(0xFF5A3620);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width * .48, size.height * .68), width: 104, height: 12), table);
    canvas.drawRect(Rect.fromLTWH(size.width * .34, size.height * .68, 6, 20), table);
    canvas.drawRect(Rect.fromLTWH(size.width * .58, size.height * .68, 6, 20), table);
  }

  void _drawAlignedWorkbench(Canvas canvas, Size size) {
    final table = Paint()..color = const Color(0xFF4A2C18);
    canvas.drawRect(Rect.fromLTWH(size.width * .30, size.height * .67, 130, 13), table);
    canvas.drawRect(Rect.fromLTWH(size.width * .32, size.height * .67, 7, 22), table);
    canvas.drawRect(Rect.fromLTWH(size.width * .48, size.height * .67, 7, 22), table);
    canvas.drawRect(Rect.fromLTWH(size.width * .64, size.height * .67, 7, 22), table);
  }

  void _drawSacredPool(Canvas canvas, Size size) {
    final col = Paint()..color = const Color(0xFF28343D);
    canvas.drawRect(Rect.fromLTWH(size.width * .14, size.height * .14, 16, size.height * .62), col);
    canvas.drawRect(Rect.fromLTWH(size.width * .81, size.height * .14, 16, size.height * .62), col);

    final poolStone = Paint()..color = const Color(0xFF1E2833);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.50, size.height * 0.72), width: 146, height: 46),
      poolStone,
    );

    final poolWaterDeep = Paint()..color = const Color(0xFF0C4A6E);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.50, size.height * 0.72), width: 130, height: 36),
      poolWaterDeep,
    );

    if (!locked) {
      final poolGlow = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.50, size.height * 0.72), width: 110, height: 26),
        poolGlow,
      );
      final waterSurface = Paint()..color = const Color(0xFF06B6D4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.50, size.height * 0.72), width: 96, height: 20),
        waterSurface,
      );
    }
  }

  void _drawTorchGlow(Canvas canvas, Offset pos) {
    final glow = Paint()..color = Colors.orangeAccent.withValues(alpha: .24)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(pos, 20, glow);

    final flame = Paint()..color = Colors.orangeAccent.withValues(alpha: .75 + fireFlicker.value * .22);
    canvas.drawCircle(pos, 6.5, flame);
    canvas.drawRect(Rect.fromLTWH(pos.dx - 2, pos.dy + 5, 4, 14), Paint()..color = const Color(0xFF331B0E));
  }

  @override
  bool shouldRepaint(covariant _ArchitecturalBackdropPainter oldDelegate) => true;
}

class _ChamberParticlesPainter extends CustomPainter {
  final int floorIndex;
  final double progress;
  final Color themeColor;

  _ChamberParticlesPainter({
    required this.floorIndex,
    required this.progress,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(floorIndex * 19);
    final paint = Paint()..color = themeColor.withValues(alpha: .7);

    for (int i = 0; i < 14; i++) {
      double x = rnd.nextDouble() * size.width;
      double speed = 0.5 + rnd.nextDouble();
      double y = size.height - (((progress * speed + rnd.nextDouble()) % 1.0) * size.height);
      double sway = sin((progress * 4 + i) * pi) * 6;

      if (floorIndex == 1) {
        canvas.drawCircle(Offset(x + sway, y), 1.6, paint..color = Colors.amberAccent);
      } else if (floorIndex == 4) {
        canvas.drawCircle(Offset(x + sway, y), 2.4, paint..style = PaintingStyle.stroke..strokeWidth = 1.3);
      } else if (floorIndex == 5) {
        canvas.drawCircle(Offset(x + sway, y), 2.0, paint..style = PaintingStyle.fill..color = Colors.cyanAccent);
      } else {
        canvas.drawCircle(Offset(x + sway, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChamberParticlesPainter oldDelegate) => true;
}

class _VerticalStairsPainter extends CustomPainter {
  final bool locked;
  final Animation<double> fireFlicker;

  _VerticalStairsPainter({
    required this.locked,
    required this.fireFlicker,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(5, 0, size.width - 10, size.height), Paint()..color = const Color(0xFF080604));
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, size.height), Paint()..color = const Color(0xFF422E20));
    canvas.drawRect(Rect.fromLTWH(size.width - 8, 0, 7, size.height), Paint()..color = const Color(0xFF332014));

    final stepPaint = Paint()..color = locked ? const Color(0xFF352922) : const Color(0xFF6B4832);
    for (double y = 18; y < size.height; y += 16) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8, y, size.width - 17, 5.5), const Radius.circular(2)), stepPaint);
    }

    if (!locked) {
      final glow = Paint()..color = Colors.orangeAccent.withValues(alpha: .18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      final torchPos = Offset(size.width / 2, size.height * .32);
      canvas.drawCircle(torchPos, 14, glow);
      canvas.drawCircle(torchPos, 4.5 + fireFlicker.value * 1.5, Paint()..color = Colors.orangeAccent);
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalStairsPainter oldDelegate) => true;
}

class _SurfaceLandscapePainter extends CustomPainter {
  final int season;
  final bool isNight;

  _SurfaceLandscapePainter({required this.season, required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final houseWall = Paint()..color = const Color(0xFF422F21);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(24, 35, 60, 45), const Radius.circular(4)),
      houseWall,
    );

    final roofPath = Path()
      ..moveTo(14, 35)
      ..lineTo(54, 5)
      ..lineTo(94, 35)
      ..close();
    final roofPaint = Paint()..color = const Color(0xFF63422C);
    canvas.drawPath(roofPath, roofPaint);

    final windowPaint = Paint()..color = Colors.amber.withValues(alpha: isNight ? 0.9 : 0.6);
    canvas.drawRect(const Rect.fromLTWH(44, 45, 18, 18), windowPaint);

    final wellPaint = Paint()..color = const Color(0xFF5A4D41);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 90, 45, 45, 35), const Radius.circular(4)),
      wellPaint,
    );
    final wellRoof = Paint()..color = const Color(0xFF3E2718);
    canvas.drawRect(Rect.fromLTWH(size.width - 96, 32, 57, 6), wellRoof);

    final fencePaint = Paint()..color = const Color(0xFF5D4037);
    for (double x = 95; x < size.width - 100; x += 16) {
      canvas.drawRect(Rect.fromLTWH(x, 52, 4, 25), fencePaint);
      canvas.drawRect(Rect.fromLTWH(x - 2, 60, 18, 3), fencePaint);
    }

    Color grassColor;
    if (season == 3) {
      grassColor = const Color(0xFFE2E8F0);
    } else if (season == 2) {
      grassColor = const Color(0xFFB45309);
    } else {
      grassColor = const Color(0xFF15803D);
    }

    final grassPaint = Paint()..color = grassColor;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 75, size.width, 22),
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
      ),
      grassPaint,
    );

    final soilPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3E2114), Color(0xFF1C0D06)],
      ).createShader(Rect.fromLTWH(0, 95, size.width, 45));
    canvas.drawRect(Rect.fromLTWH(0, 95, size.width, 45), soilPaint);

    final doorPaint = Paint()..color = const Color(0xFF110703);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(26, 92, 40, 48), const Radius.circular(6)),
      doorPaint,
    );
    final lightPaint = Paint()..color = Colors.amber;
    canvas.drawCircle(const Offset(46, 106), 4, lightPaint);
  }

  @override
  bool shouldRepaint(covariant _SurfaceLandscapePainter oldDelegate) => true;
}

class _IllustratedWeatherPainter extends CustomPainter {
  final double progress;
  final int season;
  final bool isNight;

  _IllustratedWeatherPainter({
    required this.progress,
    required this.season,
    required this.isNight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 22; i++) {
      double startX = random.nextDouble() * size.width;
      double speed = 0.4 + random.nextDouble() * 0.7;
      double currentY = ((progress * speed + random.nextDouble()) % 1.0) * size.height;
      double sway = sin((progress * 4 + i) * pi) * 14;

      String icon = '';
      if (isNight) {
        icon = '🌙';
      } else if (season == 3) {
        icon = '❄️';
      } else if (season == 2) {
        icon = '🍁';
      } else if (season == 0) {
        icon = '🌸';
      } else {
        icon = '☀️';
      }

      textPainter.text = TextSpan(
        text: icon,
        style: const TextStyle(fontSize: 13),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(startX + sway, currentY));
    }
  }

  @override
  bool shouldRepaint(covariant _IllustratedWeatherPainter oldDelegate) => true;
}