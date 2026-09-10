import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3/core/services/audio_service.dart';
import 'package:match3/features/shop/presentation/shop_exchange_screen.dart';
import 'package:match3/features/skills/logic/skill_tree_notifier.dart';
import 'package:match3/features/skills/models/skill_node_model.dart';
import '../logic/game_notifier.dart';
import '../logic/game_state.dart';
import '../models/tile_model.dart';
import 'package:match3/widgets/game_background.dart';
import 'package:match3/widgets/skill_effects_overlay.dart';

class ScorePopup {
  final String id;
  final int points;

  ScorePopup({
    required this.id,
    required this.points,
  });
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  bool _showPlusMovesAnimation = false;
  TileModel? _bombTargetTile;
  bool _isShakingBomb = false;

  TileType? _activeScreenEffect;

  Color _backgroundGlowColor = Colors.transparent;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final List<ScorePopup> _scorePopups = [];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    )..addListener(() => setState(() {}));
  }

  void _triggerSkillBurst(TileType type) {
    setState(() {
      _activeScreenEffect = type;
    });
  }

  void _triggerTileColorGlow(Color color) {
    setState(() {
      _backgroundGlowColor = color;
    });
    _glowController.forward(from: 0.0).then((_) {
      _glowController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _backgroundGlowColor = Colors.transparent;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _triggerPlusMovesEffect() {
    setState(() => _showPlusMovesAnimation = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showPlusMovesAnimation = false);
    });
  }

  void _spawnScorePopup(int gainedPoints) {
    if (gainedPoints <= 0) return;

    final popup = ScorePopup(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      points: gainedPoints,
    );

    setState(() {
      _scorePopups.add(popup);
    });

    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _scorePopups.removeWhere((p) => p.id == popup.id);
        });
      }
    });
  }

  Future<void> _handleTileClickWithSkill(TileModel tile) async {
    final gameState = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    // Kırmızı, Yeşil ve Mor skiller için hedef taşa tıklandığı an animasyonu patlat
    if (gameState.activeSkillMode == SkillMode.redBomb) {
      _triggerSkillBurst(TileType.red);
      _triggerTileColorGlow(Colors.redAccent);

      setState(() {
        _bombTargetTile = tile;
        _isShakingBomb = true;
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _isShakingBomb = false;
          _bombTargetTile = null;
        });
      }
    } else if (gameState.activeSkillMode == SkillMode.greenTransform) {
      _triggerSkillBurst(TileType.green);
      _triggerTileColorGlow(Colors.greenAccent);
    } else if (gameState.activeSkillMode == SkillMode.purpleClear) {
      _triggerSkillBurst(TileType.purple);
      _triggerTileColorGlow(Colors.purpleAccent);
    } else {
      _triggerTileColorGlow(tile.type.color);
    }

    notifier.onTileTap(tile);

    if (ref.read(gameProvider).movesLeft <= 0) {
      Future.microtask(() => _showGameOverDialog());
    }
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ana Menüye Dönülsün mü?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Mevcut skorunuz cüzdanınıza eklenecektir.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                await ref.read(gameProvider.notifier).addScoreToWallet();
                if (mounted) {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Çık ve Puanı Al',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showGameOverDialog() {
    final state = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final int earnedScore = state.score;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            '🎉 OYUN BİTTİ!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kazanılan Skor: $earnedScore Puan',
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Puanınız cüzdanınıza eklendi! Nereye gitmek istersiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await notifier.addScoreToWallet();
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ShopAndExchangeScreen()),
                    );
                  }
                },
                child: const Text('🛒 Mağazaya Git',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await notifier.addScoreToWallet();
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('🏠 Ana Menüye Dön',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPassiveBonusIndicators() {
    final skills = ref.watch(skillTreeProvider);

    final boxScoreLvl = skills.firstWhere((s) => s.type == SkillType.passiveBoxScore, orElse: () => const SkillNodeModel(id: '', title: '', description: '', type: SkillType.passiveBoxScore, category: SkillCategory.passive, maxLevel: 3, subUpgrades: [])).currentLevel;
    final startMovesLvl = skills.firstWhere((s) => s.type == SkillType.passiveStartMoves, orElse: () => const SkillNodeModel(id: '', title: '', description: '', type: SkillType.passiveStartMoves, category: SkillCategory.passive, maxLevel: 1, subUpgrades: [])).currentLevel;
    final lastChanceLvl = skills.firstWhere((s) => s.type == SkillType.passiveLastChance, orElse: () => const SkillNodeModel(id: '', title: '', description: '', type: SkillType.passiveLastChance, category: SkillCategory.passive, maxLevel: 3, subUpgrades: [])).currentLevel;
    final comboLvl = skills.firstWhere((s) => s.type == SkillType.passiveComboBonus, orElse: () => const SkillNodeModel(id: '', title: '', description: '', type: SkillType.passiveComboBonus, category: SkillCategory.passive, maxLevel: 3, subUpgrades: [])).currentLevel;

    List<Widget> activeBadges = [];

    if (boxScoreLvl > 0) {
      String text = boxScoreLvl == 1 ? '+%10 Puan' : (boxScoreLvl == 2 ? '+%20 Puan' : '+%35 Puan');
      activeBadges.add(_buildBadge(Icons.inventory_2, text, Colors.orangeAccent));
    }

    if (startMovesLvl > 0) {
      activeBadges.add(_buildBadge(Icons.play_circle_fill, '+5 Hamle', Colors.tealAccent));
    }

    if (lastChanceLvl > 0) {
      String text = lastChanceLvl == 1 ? '%20 Şans' : (lastChanceLvl == 2 ? '%40 Şans' : '%60 Şans');
      activeBadges.add(_buildBadge(Icons.replay_circle_filled, text, Colors.pinkAccent));
    }

    if (comboLvl > 0) {
      String text = comboLvl == 1 ? '+%20 Şarj' : (comboLvl == 2 ? '+%40 Şarj' : '+%60 Şarj');
      activeBadges.add(_buildBadge(Icons.stars, text, Colors.amberAccent));
    }

    if (activeBadges.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PASİFLER: ',
                style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
            ...activeBadges,
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Color> _getTileGradients(TileType type) {
    switch (type) {
      case TileType.blue:
        return [const Color(0xFF38BDF8), const Color(0xFF0284C7)];
      case TileType.red:
        return [const Color(0xFFF87171), const Color(0xFFDC2626)];
      case TileType.green:
        return [const Color(0xFF4ADE80), const Color(0xFF16A34A)];
      case TileType.yellow:
        return [const Color(0xFFFACC15), const Color(0xFFCA8A04)];
      case TileType.purple:
        return [const Color(0xFFC084FC), const Color(0xFF9333EA)];
    }
  }

  IconData _getTileInnerSymbol(TileType type) {
    switch (type) {
      case TileType.blue:
        return Icons.water_drop_rounded;
      case TileType.red:
        return Icons.local_fire_department_rounded;
      case TileType.green:
        return Icons.eco_rounded;
      case TileType.yellow:
        return Icons.bolt_rounded;
      case TileType.purple:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameProvider, (previous, next) {
      if (previous != null) {
        final gainedScore = next.score - previous.score;
        if (gainedScore > 0) {
          AudioService.playMatch();
          _spawnScorePopup(gainedScore);
        }
      }
    });

    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    final blueBonus = gameNotifier.getBlueSkillMoveBonus();
    final bool isBoardLocked = gameState.isProcessingBoard || gameState.isProcessingSkill;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Skill Blast',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: 'Ana Menüye Dön',
            onPressed: _showExitConfirmationDialog,
          )
        ],
      ),
      body: Stack(
        children: [
          GameBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildWalletItem(
                                icon: Icons.stars,
                                value: '${gameState.totalPoints}',
                                color: Colors.cyanAccent,
                                label: 'Puan'),
                            _buildWalletItem(
                                icon: Icons.monetization_on,
                                color: Colors.grey.shade300,
                                value: '${gameState.silverCoins}',
                                label: 'Gümüş'),
                            _buildWalletItem(
                                icon: Icons.monetization_on,
                                color: Colors.amber,
                                value: '${gameState.goldCoins}',
                                label: 'Altın'),
                          ],
                        ),
                      ),

                      _buildPassiveBonusIndicators(),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: TileType.values.map((type) {
                            final maxBar = gameNotifier.getRequiredSkillBarMax(type);
                            final currentVal = gameState.skillBars[type] ?? 0;
                            final progress = (currentVal / maxBar).clamp(0.0, 1.0);
                            final isReady = progress >= 1.0;

                            return GestureDetector(
                              onTap: () {
                                if (isBoardLocked) return;
                                if (isReady) {
                                  AudioService.playSkill();

                                  // Yalnızca anında tetiklenen Mavi ve Sarı buton anında patlar
                                  if (type == TileType.blue) {
                                    _triggerSkillBurst(TileType.blue);
                                    _triggerPlusMovesEffect();
                                  } else if (type == TileType.yellow) {
                                    _triggerSkillBurst(TileType.yellow);
                                  }

                                  _triggerTileColorGlow(type.color);
                                  gameNotifier.useSkill(type);
                                } else {
                                  _showSkillInfoDialog(context, type);
                                }
                              },
                              onLongPress: () => _showSkillInfoDialog(context, type),
                              child: Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (isReady)
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: type.color.withValues(alpha: 0.8),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      SizedBox(
                                        height: 46,
                                        width: 46,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.white10,
                                          color: type.color,
                                          strokeWidth: 5,
                                        ),
                                      ),
                                      Icon(
                                        _getTileInnerSymbol(type),
                                        color: isReady ? Colors.white : Colors.white38,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isReady ? 'KULLAN' : '$currentVal/$maxBar',
                                    style: TextStyle(
                                      color: isReady ? Colors.amber : Colors.white54,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (gameState.activeSkillMode != SkillMode.none)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade800,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.ads_click, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _getSkillInstructionText(gameState.activeSkillMode),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),

                      IgnorePointer(
                        ignoring: isBoardLocked,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: gameState.activeSkillMode != SkillMode.none
                                      ? Colors.amber
                                      : Colors.white24,
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _backgroundGlowColor != Colors.transparent
                                      ? _backgroundGlowColor.withValues(alpha: 0.6 * _glowAnimation.value)
                                      : Colors.black38,
                                  blurRadius: _backgroundGlowColor != Colors.transparent ? 35 : 15,
                                  spreadRadius: _backgroundGlowColor != Colors.transparent ? 5 : 1,
                                ),
                              ],
                            ),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gameState.gridCols,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                              ),
                              itemCount: gameState.gridRows * gameState.gridCols,
                              itemBuilder: (context, index) {
                                int r = index ~/ gameState.gridCols;
                                int c = index % gameState.gridCols;
                                final tile = gameState.grid.length > r &&
                                        gameState.grid[r].length > c
                                    ? gameState.grid[r][c]
                                    : null;

                                if (tile == null) {
                                  return const SizedBox.expand();
                                }

                                final isSelected = gameState.selectedTile?.id == tile.id;
                                final isHighlighted = gameState.highlightedTileIds.contains(tile.id);

                                bool isInsideBombZone = false;
                                if (_bombTargetTile != null) {
                                  int size = gameNotifier.getRedSkillGridSize();
                                  int halfLeft = (size - 1) ~/ 2;
                                  int halfRight = size - 1 - halfLeft;

                                  isInsideBombZone = r >= (_bombTargetTile!.row - halfLeft) &&
                                      r <= (_bombTargetTile!.row + halfRight) &&
                                      c >= (_bombTargetTile!.col - halfLeft) &&
                                      c <= (_bombTargetTile!.col + halfRight);
                                }

                                final isShaking = (_isShakingBomb && isInsideBombZone) || isHighlighted;
                                final tileGradients = _getTileGradients(tile.type);

                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 650),
                                  switchInCurve: Curves.bounceOut,
                                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: <Widget>[
                                        ...previousChildren,
                                        if (currentChild != null) currentChild,
                                      ],
                                    );
                                  },
                                  transitionBuilder: (child, animation) {
                                    if (child.key != ValueKey(tile.id)) {
                                      return const SizedBox.shrink();
                                    }

                                    if (tile.isFalling) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.0, -1.0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      );
                                    }

                                    return child;
                                  },
                                  child: SizedBox.expand(
                                    key: ValueKey(tile.id),
                                    child: GestureDetector(
                                      onTap: () => _handleTileClickWithSkill(tile),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        transform: Matrix4.translationValues(
                                            isShaking ? (Random().nextDouble() * 8 - 4) : 0,
                                            isShaking ? (Random().nextDouble() * 8 - 4) : 0,
                                            0),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isHighlighted
                                                ? [Colors.purpleAccent, Colors.deepPurple]
                                                : (isInsideBombZone
                                                    ? [Colors.redAccent, Colors.red.shade900]
                                                    : tileGradients),
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          border: isHighlighted
                                              ? Border.all(color: Colors.amberAccent, width: 3)
                                              : (isSelected
                                                  ? Border.all(color: Colors.white, width: 3)
                                                  : (isInsideBombZone
                                                      ? Border.all(color: Colors.yellow, width: 2)
                                                      : Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1))),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isHighlighted
                                                  ? Colors.purple.withValues(alpha: 0.9)
                                                  : (isSelected
                                                      ? tile.type.color.withValues(alpha: 0.9)
                                                      : tile.type.color.withValues(alpha: 0.3)),
                                              blurRadius: isSelected || isHighlighted ? 12 : 4,
                                              spreadRadius: isSelected || isHighlighted ? 2 : 0,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Positioned(
                                              top: 2,
                                              left: 4,
                                              right: 4,
                                              child: Container(
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.35),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              _getTileInnerSymbol(tile.type),
                                              color: Colors.white.withValues(alpha: 0.4),
                                              size: 20,
                                            ),
                                            if (_bombTargetTile?.id == tile.id)
                                              const Icon(Icons.local_fire_department,
                                                  color: Colors.amber, size: 28),
                                            if (isHighlighted)
                                              const Icon(Icons.auto_awesome,
                                              color: Colors.amberAccent, size: 22),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: gameState.doubleScoreMovesLeft > 0
                                    ? Colors.amber
                                    : Colors.white10,
                                width: gameState.doubleScoreMovesLeft > 0 ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard(
                                  title: 'KALAN HAMLE',
                                  value: '${gameState.movesLeft}',
                                  icon: Icons.touch_app,
                                  color: gameState.movesLeft <= 5
                                      ? Colors.redAccent
                                      : Colors.lightBlueAccent,
                                ),
                                Container(height: 36, width: 1, color: Colors.white24),
                                _buildStatCard(
                                  title: 'OYUN SKORU',
                                  value: '${gameState.score}',
                                  icon: Icons.stars,
                                  color: Colors.amber,
                                  badge: gameState.doubleScoreMovesLeft > 0
                                      ? '${gameNotifier.getYellowMultiplierValue()}X (${gameState.doubleScoreMovesLeft} Hamle)'
                                      : null,
                                ),
                              ],
                            ),
                          ),

                          ..._scorePopups.map((popup) {
                            return Positioned(
                              right: 35,
                              top: -15,
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 900),
                                tween: Tween(begin: 0.0, end: -40.0),
                                builder: (context, translateY, child) {
                                  return Transform.translate(
                                    offset: Offset(0, translateY),
                                    child: Opacity(
                                      opacity: (1.0 + (translateY / 40.0)).clamp(0.0, 1.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Colors.black45,
                                                blurRadius: 6)
                                          ],
                                        ),
                                        child: Text(
                                          '+${popup.points}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),

                          if (_showPlusMovesAnimation)
                            Positioned(
                              top: -30,
                              left: 40,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: _showPlusMovesAnimation ? 1.0 : 0.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black45, blurRadius: 8)
                                    ],
                                  ),
                                  child: Text(
                                    '+$blueBonus HAMLE!',
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

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // TAM EKRAN PARÇACIK VE TEMATİK ANİMASYON KATMANI
          if (_activeScreenEffect != null)
            Positioned.fill(
              child: SkillEffectsOverlay(
                type: _activeScreenEffect!,
                onFinished: () {
                  if (mounted) {
                    setState(() {
                      _activeScreenEffect = null;
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? badge,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text(title,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ]
          ],
        ),
      ],
    );
  }

  String _getSkillInstructionText(SkillMode mode) {
    final notifier = ref.read(gameProvider.notifier);
    switch (mode) {
      case SkillMode.redBomb:
        int size = notifier.getRedSkillGridSize();
        return 'Patlatmak istediğin ${size}x$size alanın merkezine dokun!';
      case SkillMode.greenTransform:
        return 'Dönüşmesini istediğin renkteki taşa dokun!';
      case SkillMode.purpleClear:
        return 'Tahtadan silmek istediğin renkteki taşa dokun!';
      default:
        return '';
    }
  }

  void _showSkillInfoDialog(BuildContext context, TileType type) {
    final skills = ref.read(skillTreeProvider);
    final skill = skills.firstWhere(
      (s) => s.type.name.toLowerCase().contains(type.name.toLowerCase()),
      orElse: () => skills.first,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_getTileInnerSymbol(type), color: type.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                skill.title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skill.description,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Mevcut Etki: ${skill.currentEffectDescription}',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}