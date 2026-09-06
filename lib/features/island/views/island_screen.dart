// island_screen.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3/features/game/logic/game_notifier.dart';
import '../logic/island_notifier.dart';
import '../models/island_model.dart';

enum IslandSeason { spring, summer, autumn, winter }

class IslandScreen extends ConsumerStatefulWidget {
  const IslandScreen({super.key});

  @override
  ConsumerState<IslandScreen> createState() => _IslandScreenState();
}

class _IslandScreenState extends ConsumerState<IslandScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _mainAnimationController;
  late AnimationController _floatAnimationController;
  late Animation<double> _floatAnimation;

  bool _isNight = false;
  IslandSeason _currentSeason = IslandSeason.summer;

  bool _showSimpleToast = false;
  String _toastMessage = '';

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(islandProvider).activeIslandIndex;
    _pageController = PageController(initialPage: initialIndex);

    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _floatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _floatAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mainAnimationController.dispose();
    _floatAnimationController.dispose();
    super.dispose();
  }

  void _triggerSleekUpgradeNotice(String text) {
    HapticFeedback.lightImpact();
    setState(() {
      _toastMessage = text;
      _showSimpleToast = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSimpleToast = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kayıtlı veriler yüklenince PageController'ı senkronize et
    ref.listen<IslandState>(islandProvider, (previous, next) {
      if (previous?.activeIslandIndex != next.activeIslandIndex) {
        if (_pageController.hasClients &&
            _pageController.page?.round() != next.activeIslandIndex) {
          _pageController.jumpToPage(next.activeIslandIndex);
        }
      }
    });

    final islandState = ref.watch(islandProvider);
    final islandNotifier = ref.read(islandProvider.notifier);
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor:
          _isNight ? const Color(0xFF090D16) : const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('🏝️ Krallık Adaları',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isNight ? Icons.nightlight_round : Icons.wb_sunny,
                color: _isNight ? Colors.amberAccent : Colors.amber),
            onPressed: () => setState(() => _isNight = !_isNight),
          ),
          PopupMenuButton<IslandSeason>(
            icon: const Icon(Icons.style, color: Colors.white),
            onSelected: (season) => setState(() => _currentSeason = season),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: IslandSeason.spring, child: Text('🌸 Bahar')),
              const PopupMenuItem(
                  value: IslandSeason.summer, child: Text('☀️ Yaz')),
              const PopupMenuItem(
                  value: IslandSeason.autumn, child: Text('🍁 Sonbahar')),
              const PopupMenuItem(
                  value: IslandSeason.winter, child: Text('❄️ Kış')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Info Bar
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (_isNight
                            ? const Color(0xFF151D2A)
                            : const Color(0xFF1E293B))
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.amber.shade300, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PRESTİJ PUANI',
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                              Text('${islandState.totalPrestijScore} Puan',
                                  style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on,
                              color: Colors.amberAccent, size: 22),
                          const SizedBox(width: 4),
                          Text('${gameState.goldCoins}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Island Page View
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: islandState.islands.length,
                    onPageChanged: (index) => islandNotifier.changePage(index),
                    itemBuilder: (context, index) {
                      final island = islandState.islands[index];
                      return _buildIslandCard(island);
                    },
                  ),
                ),

                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(islandState.islands.length, (index) {
                    bool isActive = index == islandState.activeIslandIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 12),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.amber : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),

            if (_showSimpleToast)
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10)
                      ],
                    ),
                    child: Text(
                      _toastMessage,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIslandCard(IslandModel island) {
    int totalLevels =
        island.buildings.fold(0, (sum, b) => sum + b.currentLevel);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. DİNAMİK ARKA PLAN
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: DynamicEnvironmentWidget(
              isNight: _isNight,
              season: _currentSeason,
              animationController: _mainAnimationController,
            ),
          ),

          // 2. MEVSİMSEL HAVA PARÇACIKLARI
          ..._buildSeasonalWeatherEffects(),

          // 3. GÖKYÜZÜ SİMGELERİ
          ..._buildSkyDecorations(island.id, totalLevels),

          // 4. DENİZ SİMGELERİ
          ..._buildSeaDecorations(island.id, totalLevels),

          // 5. ADA VE KARASAL YAŞAM
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: child,
            ),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Text(island.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('Ada Gelişimi: Lvl $totalLevels',
                          style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Spacer(),

                // KARA KATMANLARI VE KARASAL OBJELER
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Kumsal
                    Container(
                      width: 290,
                      height: 290,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getSandColor(island.id, _currentSeason),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black38,
                              blurRadius: 20,
                              offset: Offset(0, 10))
                        ],
                      ),
                    ),

                    // İç Çim/KARA Alanı
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                            colors: _getIslandGradients(
                                island.id, _currentSeason)),
                        border: Border.all(
                            color: _getSandColor(island.id, _currentSeason),
                            width: 3),
                      ),
                      child: Stack(
                        children: [
                          ..._buildLandDecorations(island.id, totalLevels),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 16,
                              children: island.buildings.map((building) {
                                return _buildCleanBuildingWidget(
                                    island, building);
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),

          // KİLİTLİ ADA EKRANI
          if (!island.isUnlocked)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            color: Colors.amber, size: 60),
                        const SizedBox(height: 8),
                        const Text('KİLİTLİ ADA',
                            style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(
                            'Açmak için ${island.unlockGoldCost} Altın gerekli',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber),
                          onPressed: () {
                            bool success = ref
                                .read(islandProvider.notifier)
                                .unlockIsland(island.id);
                            if (success) {
                              _triggerSleekUpgradeNotice(
                                  'Yeni Ada Keşfedildi! 🏝️');
                            }
                          },
                          icon: const Icon(Icons.monetization_on,
                              color: Colors.black),
                          label: const Text('Kilidi Aç',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSkyDecorations(String islandId, int totalLevels) {
    List<Widget> sky = [];
    if (islandId == 'island_1') {
      if (totalLevels >= 1) {
        sky.add(_movingSkyWidget(
            top: 25,
            speed: 0.8,
            child: const Text('☁️', style: TextStyle(fontSize: 26))));
      }
      if (totalLevels >= 3) {
        sky.add(_movingSkyWidget(
            top: 55,
            speed: 1.5,
            child: const Text('🕊️', style: TextStyle(fontSize: 20))));
      }
      if (totalLevels >= 6) {
        sky.add(_movingSkyWidget(
            top: 35,
            speed: 1.1,
            child: const Text('🎈', style: TextStyle(fontSize: 22))));
      }
      if (totalLevels >= 9) {
        sky.add(_movingSkyWidget(
            top: 70,
            speed: 2.0,
            child: const Text('🦅', style: TextStyle(fontSize: 24))));
      }
    } else if (islandId == 'island_2') {
      if (totalLevels >= 1) {
        sky.add(_movingSkyWidget(
            top: 30,
            speed: 1.6,
            child: const Text('🦜', style: TextStyle(fontSize: 22))));
      }
      if (totalLevels >= 4) {
        sky.add(_movingSkyWidget(
            top: 60,
            speed: 0.9,
            child: const Text('🛸', style: TextStyle(fontSize: 24))));
      }
      if (totalLevels >= 8) {
        sky.add(_movingSkyWidget(
            top: 20,
            speed: 2.2,
            child: const Text('🦅', style: TextStyle(fontSize: 22))));
      }
    } else if (islandId == 'island_3') {
      if (totalLevels >= 1) {
        sky.add(_movingSkyWidget(
            top: 40,
            speed: 2.5,
            child: const Text('🦇', style: TextStyle(fontSize: 22))));
      }
      if (totalLevels >= 4) {
        sky.add(_movingSkyWidget(
            top: 20,
            speed: 1.2,
            child: const Text('🐉', style: TextStyle(fontSize: 32))));
      }
      if (totalLevels >= 7) {
        sky.add(_movingSkyWidget(
            top: 65,
            speed: 3.2,
            child: const Text('☄️', style: TextStyle(fontSize: 24))));
      }
    }
    return sky;
  }

  List<Widget> _buildSeaDecorations(String islandId, int totalLevels) {
    List<Widget> sea = [];
    if (islandId == 'island_1') {
      if (totalLevels >= 2) {
        sea.add(const Positioned(
            bottom: 30,
            left: 35,
            child: Text('🚣', style: TextStyle(fontSize: 22))));
      }
      if (totalLevels >= 5) {
        sea.add(const Positioned(
            bottom: 75,
            right: 30,
            child: Text('🐬', style: TextStyle(fontSize: 24))));
      }
      if (totalLevels >= 8) {
        sea.add(const Positioned(
            bottom: 25,
            right: 110,
            child: Text('🦢', style: TextStyle(fontSize: 20))));
      }
    } else if (islandId == 'island_2') {
      if (totalLevels >= 1) {
        sea.add(const Positioned(
            bottom: 35,
            right: 30,
            child: Text('🦈', style: TextStyle(fontSize: 24))));
      }
      if (totalLevels >= 3) {
        sea.add(const Positioned(
            bottom: 100,
            left: 25,
            child: Text('⛵', style: TextStyle(fontSize: 28))));
      }
      if (totalLevels >= 7) {
        sea.add(const Positioned(
            bottom: 25,
            left: 105,
            child: Text('🧜‍♀️', style: TextStyle(fontSize: 22))));
      }
    } else if (islandId == 'island_3') {
      if (totalLevels >= 2) {
        sea.add(const Positioned(
            bottom: 35,
            left: 30,
            child: Text('🪨', style: TextStyle(fontSize: 20))));
      }
      if (totalLevels >= 5) {
        sea.add(const Positioned(
            bottom: 90,
            right: 35,
            child: Text('🦑', style: TextStyle(fontSize: 28))));
      }
      if (totalLevels >= 9) {
        sea.add(const Positioned(
            bottom: 25,
            right: 110,
            child: Text('🔮', style: TextStyle(fontSize: 22))));
      }
    }
    return sea;
  }

  List<Widget> _buildLandDecorations(String islandId, int totalLevels) {
    List<Widget> land = [];
    if (islandId == 'island_1') {
      if (totalLevels >= 1) {
        land.add(const Positioned(
            top: 15, left: 15, child: Text('🚶‍♂️', style: TextStyle(fontSize: 16))));
      }
      if (totalLevels >= 2) {
        land.add(const Positioned(
            top: 15, right: 20, child: Text('🌸', style: TextStyle(fontSize: 14))));
      }
      if (totalLevels >= 3) {
        land.add(const Positioned(
            bottom: 15,
            left: 20,
            child: Text('🍄', style: TextStyle(fontSize: 14))));
      }
      if (totalLevels >= 5) {
        land.add(const Positioned(
            bottom: 15,
            right: 20,
            child: Text('🐕', style: TextStyle(fontSize: 16))));
      }
      if (totalLevels >= 7) {
        land.add(const Positioned(
            top: 95, left: 8, child: Text('⛺', style: TextStyle(fontSize: 16))));
      }
      if (totalLevels >= 10) {
        land.add(const Positioned(
            top: 95, right: 8, child: Text('🌾', style: TextStyle(fontSize: 16))));
      }
    } else if (islandId == 'island_2') {
      if (totalLevels >= 1) {
        land.add(const Positioned(
            top: 15,
            right: 15,
            child: Text('🏴‍☠️', style: TextStyle(fontSize: 16))));
      }
      if (totalLevels >= 2) {
        land.add(const Positioned(
            top: 15, left: 20, child: Text('🚶‍♀️', style: TextStyle(fontSize: 16))));
      }
      if (totalLevels >= 4) {
        land.add(const Positioned(
            bottom: 15,
            left: 15,
            child: Text('💎', style: TextStyle(fontSize: 15))));
      }
      if (totalLevels >= 6) {
        land.add(const Positioned(
            bottom: 15,
            right: 15,
            child: Text('💣', style: TextStyle(fontSize: 15))));
      }
      if (totalLevels >= 8) {
        land.add(const Positioned(
            top: 95, left: 8, child: Text('🗿', style: TextStyle(fontSize: 16))));
      }
      if (totalLevels >= 11) {
        land.add(const Positioned(
            top: 95, right: 8, child: Text('📜', style: TextStyle(fontSize: 15))));
      }
    } else if (islandId == 'island_3') {
      if (totalLevels >= 1) {
        land.add(const Positioned(
            bottom: 15,
            right: 20,
            child: Text('🔥', style: TextStyle(fontSize: 15))));
      }
      if (totalLevels >= 3) {
        land.add(const Positioned(
            top: 15,
            left: 15,
            child: Text('🧙‍♂️', style: TextStyle(fontSize: 16))));
      }
      if (totalLevels >= 5) {
        land.add(const Positioned(
            top: 15,
            right: 15,
            child: Text('🥚', style: TextStyle(fontSize: 15))));
      }
      if (totalLevels >= 8) {
        land.add(const Positioned(
            bottom: 15,
            left: 20,
            child: Text('⚔️', style: TextStyle(fontSize: 15))));
      }
      if (totalLevels >= 10) {
        land.add(const Positioned(
            top: 95, left: 8, child: Text('👑', style: TextStyle(fontSize: 16))));
      }
    }
    return land;
  }

  Widget _movingSkyWidget(
      {required double top, required double speed, required Widget child}) {
    return AnimatedBuilder(
      animation: _mainAnimationController,
      builder: (context, _) {
        double offset = _mainAnimationController.value * 340 * speed;
        return Positioned(
          top: top,
          left: -40 + (offset % 360),
          child: child,
        );
      },
    );
  }

  List<Widget> _buildSeasonalWeatherEffects() {
    List<Widget> weather = [];
    String symbol = '✨';

    if (_isNight) {
      symbol = '🌙';
    } else {
      if (_currentSeason == IslandSeason.winter) symbol = '❄️';
      if (_currentSeason == IslandSeason.spring) symbol = '🌸';
      if (_currentSeason == IslandSeason.autumn) symbol = '🍁';
      if (_currentSeason == IslandSeason.summer) symbol = '☀️';
    }

    for (int i = 0; i < 5; i++) {
      weather.add(
        AnimatedBuilder(
          animation: _mainAnimationController,
          builder: (context, _) {
            double progress =
                (_mainAnimationController.value + (i * 0.2)) % 1.0;
            double topPos = progress * 420;
            double leftPos =
                (i * 65.0) + (math.sin(progress * math.pi * 2) * 12);

            return Positioned(
              top: topPos,
              left: leftPos,
              child: Opacity(
                opacity: (1.0 - progress).clamp(0.2, 0.75),
                child: Text(symbol, style: const TextStyle(fontSize: 13)),
              ),
            );
          },
        ),
      );
    }
    return weather;
  }

  Widget _buildCleanBuildingWidget(
      IslandModel island, BuildingModel building) {
    bool isConstructed = building.currentLevel > 0;
    bool isMaxLevel = building.currentLevel >= building.maxLevel;

    return GestureDetector(
      onTap: () => _showUpgradeDialog(island, building),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConstructed
                      ? const Color(0xFF1E293B)
                      : Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMaxLevel
                        ? Colors.amber
                        : (isConstructed
                            ? Colors.amberAccent
                            : Colors.white24),
                    width: isConstructed ? 2 : 1,
                  ),
                  boxShadow: isMaxLevel
                      ? [
                          BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              blurRadius: 10)
                        ]
                      : [],
                ),
                child: Opacity(
                  opacity: isConstructed ? 1.0 : 0.35,
                  child: Text(building.emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              if (isMaxLevel)
                const Positioned(
                    top: -6, child: Text('👑', style: TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      isConstructed ? Colors.amberAccent : Colors.transparent,
                  width: 0.5),
            ),
            child: Text(
              isConstructed
                  ? (isMaxLevel ? 'MAX' : 'Lvl ${building.currentLevel}')
                  : 'İnşa Et',
              style: TextStyle(
                color: isConstructed ? Colors.white : Colors.amberAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(IslandModel island, BuildingModel building) {
    final bool isMax = building.currentLevel >= building.maxLevel;
    final int cost = building.nextUpgradeCost;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Text(building.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(building.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seviye: ${building.currentLevel} / ${building.maxLevel}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('Prestij Kazancı: +${building.totalPrestij} Puan',
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (!isMax)
                Text('Maliyet: $cost Altın',
                    style: const TextStyle(
                        color: Colors.cyanAccent, fontWeight: FontWeight.bold))
              else
                const Text('Maksimum Seviyeye Ulaşıldı! 👑',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  const Text('Kapat', style: TextStyle(color: Colors.white54)),
            ),
            if (!isMax)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  bool success = ref
                      .read(islandProvider.notifier)
                      .upgradeBuilding(island.id, building.id);
                  Navigator.pop(dialogContext);

                  if (success) {
                    _triggerSleekUpgradeNotice(
                        'Ada Gelişti! Adada Yeni Bir Sürpriz Açıldı! ✨');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yeterli altınınız yok!')),
                    );
                  }
                },
                child: Text(building.currentLevel == 0 ? 'İnşa Et' : 'Yükselt',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
          ],
        );
      },
    );
  }

  Color _getSandColor(String islandId, IslandSeason season) {
    if (islandId == 'island_3') return const Color(0xFF4A3E3D);
    switch (season) {
      case IslandSeason.winter:
        return const Color(0xFFCBD5E1);
      case IslandSeason.autumn:
        return const Color(0xFFD97706);
      default:
        return const Color(0xFFE6C280);
    }
  }

  List<Color> _getIslandGradients(String islandId, IslandSeason season) {
    if (islandId == 'island_3') {
      return [Colors.deepOrange.shade900, Colors.red.shade900, Colors.black54];
    }
    switch (season) {
      case IslandSeason.winter:
        return [Colors.white, Colors.blue.shade100, Colors.blue.shade300];
      case IslandSeason.autumn:
        return [
          Colors.amber.shade600,
          Colors.deepOrange.shade700,
          Colors.brown.shade800
        ];
      case IslandSeason.spring:
        return [
          Colors.pink.shade300,
          Colors.green.shade500,
          Colors.green.shade800
        ];
      case IslandSeason.summer:
      default:
        return [
          Colors.green.shade500,
          Colors.green.shade800,
          Colors.green.shade900
        ];
    }
  }
}

class DynamicEnvironmentWidget extends StatelessWidget {
  final bool isNight;
  final IslandSeason season;
  final AnimationController animationController;

  const DynamicEnvironmentWidget({
    super.key,
    required this.isNight,
    required this.season,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 55,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isNight
                    ? [const Color(0xFF070A12), const Color(0xFF0F172A)]
                    : [const Color(0xFF38BDF8), const Color(0xFF7DD3FC)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  right: 25,
                  child: Text(isNight ? '🌙' : '☀️',
                      style: const TextStyle(fontSize: 28)),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 45,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              border: const Border(
                  top: BorderSide(color: Colors.white24, width: 1.5)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isNight
                    ? [
                        const Color(0xFF0284C7).withOpacity(0.4),
                        const Color(0xFF0369A1).withOpacity(0.8),
                        const Color(0xFF020617)
                      ]
                    : [
                        const Color(0xFF0284C7),
                        const Color(0xFF0369A1),
                        const Color(0xFF0C4A6E)
                      ],
              ),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: animationController,
                  builder: (context, _) {
                    double offset =
                        math.sin(animationController.value * 2 * math.pi) * 6;
                    return Positioned(
                      top: 4 + offset,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        color: Colors.white24,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}