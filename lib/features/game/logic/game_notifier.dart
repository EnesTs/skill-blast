import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:match3/features/skills/logic/skill_tree_notifier.dart';
import 'package:match3/features/skills/models/skill_node_model.dart';
import '../models/tile_model.dart';
import 'game_state.dart';

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref);
});

class GameNotifier extends StateNotifier<GameState> {
  final Ref ref;
  final Random _random = Random();
  Timer? _ticketTimer;
  bool _hasUsedLastChanceInCurrentGame = false;
  bool _isDataLoaded = false;

  static const int _maxRegenTickets = 5;

  GameNotifier(this.ref)
      : super(GameState(
          grid: [],
          skillBars: {for (var type in TileType.values) type: 0},
          skillCostMultipliers: {for (var type in TileType.values) type: 1},
        )) {
    _initNotifier();
  }

  Future<void> _initNotifier() async {
    await _loadSavedData();
    initBoard();
    _startTicketTimer();
  }

  void incrementLegendaryTier() {
    state = state.copyWith(
      legendaryPackageTier: state.legendaryPackageTier + 1,
    );
    _saveData();
  }

  bool claimDailyReward() {
    if (!state.isDailyRewardClaimable) return false;

    int currentDay = state.dailyRewardDay;
    int newGold = state.goldCoins;
    int newSilver = state.silverCoins;
    int newBonusTickets = state.bonusTickets;

    switch (currentDay) {
      case 1: newSilver += 100; break;
      case 2: newBonusTickets += 1; break;
      case 3: newSilver += 200; break;
      case 4: newGold += 20; break;
      case 5: newBonusTickets += 2; break;
      case 6: newSilver += 400; break;
      case 7:
        newBonusTickets += 2;
        newSilver += 200;
        newGold += 50;
        break;
      case 8: newSilver += 500; break;
      case 9: newBonusTickets += 3; break;
      case 10: newGold += 40; break;
      case 11: newSilver += 750; break;
      case 12: newBonusTickets += 4; break;
      case 13: newGold += 75; break;
      case 14: newSilver += 1000; break;
      case 15:
        newBonusTickets += 5;
        newSilver += 500;
        newGold += 150;
        break;
    }

    int nextDay = currentDay >= 15 ? 1 : currentDay + 1;

    state = state.copyWith(
      goldCoins: newGold,
      silverCoins: newSilver,
      bonusTickets: newBonusTickets,
      dailyRewardDay: nextDay,
      lastDailyRewardTime: DateTime.now(),
    );

    _saveData();
    return true;
  }

  void addRegenTicket(int amount) {
    int updatedRegen = (state.regenTickets + amount).clamp(0, _maxRegenTickets);
    bool shouldClearTime = updatedRegen >= _maxRegenTickets;

    state = state.copyWith(
      regenTickets: updatedRegen,
      nextTicketTime: shouldClearTime ? null : state.nextTicketTime,
      clearNextTicketTime: shouldClearTime,
    );
    _saveData();
  }

  void addBonusTicket(int amount) {
    state = state.copyWith(
      bonusTickets: state.bonusTickets + amount,
    );
    _saveData();
  }

  bool startGameWithTicket() {
    int regen = state.regenTickets;
    int bonus = state.bonusTickets;

    if (regen <= 0 && bonus <= 0) return false;

    DateTime? nextTime = state.nextTicketTime;

    if (regen > 0) {
      regen--;
      if (nextTime == null) {
        nextTime = DateTime.now().add(const Duration(hours: 6));
      }
    } else {
      bonus--;
    }

    initBoard();

    state = state.copyWith(
      regenTickets: regen,
      bonusTickets: bonus,
      nextTicketTime: nextTime,
    );

    _saveData();
    return true;
  }

  bool useTicket() => startGameWithTicket();

  void addGold(int amount) {
    state = state.copyWith(goldCoins: state.goldCoins + amount);
    _saveData();
  }

  void addSilver(int amount) {
    state = state.copyWith(silverCoins: state.silverCoins + amount);
    _saveData();
  }

  void deductGold(int amount) {
    if (state.goldCoins >= amount) {
      state = state.copyWith(goldCoins: state.goldCoins - amount);
      _saveData();
    }
  }

  void deductSilver(int amount) {
    if (state.silverCoins >= amount) {
      state = state.copyWith(silverCoins: state.silverCoins - amount);
      _saveData();
    }
  }

  int getSkillLevel(SkillType type) {
    final skills = ref.read(skillTreeProvider);
    try {
      final skill = skills.firstWhere((s) => s.type == type);
      return skill.currentLevel;
    } catch (_) {
      return 0;
    }
  }

  int getRequiredSkillBarMax(TileType type) {
    int multiplier = state.skillCostMultipliers[type] ?? 1;
    return 100 + ((multiplier - 1) * 40);
  }

  int getBlueSkillMoveBonus() {
    int lvl = getSkillLevel(SkillType.blueMoves);
    return lvl == 0 ? 3 : (lvl == 1 ? 4 : (lvl == 2 ? 5 : 7));
  }

  int getRedSkillGridSize() {
    int lvl = getSkillLevel(SkillType.redExplosion);
    switch (lvl) {
      case 1: return 4;
      case 2: return 5;
      case 3: return 6;
      case 0:
      default: return 3;
    }
  }

  int getGreenTransformCount() {
    int lvl = getSkillLevel(SkillType.greenTransform);
    return lvl == 0 ? 5 : (lvl == 1 ? 6 : (lvl == 2 ? 7 : 10));
  }

  int getYellowMultiplierValue() {
    int lvl = getSkillLevel(SkillType.yellowMultiplier);
    return lvl == 0 ? 2 : (lvl == 1 ? 3 : (lvl == 2 ? 4 : 5));
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    int savedRegenTickets = prefs.getInt('regenTickets') ?? _maxRegenTickets;
    int savedBonusTickets = prefs.getInt('bonusTickets') ?? 0;

    if (prefs.containsKey('tickets') && !prefs.containsKey('regenTickets')) {
      savedRegenTickets = (prefs.getInt('tickets') ?? 5).clamp(0, _maxRegenTickets);
    }

    final savedPoints = prefs.getInt('totalPoints') ?? 0;
    final savedSilver = prefs.getInt('silverCoins') ?? 0;
    final savedGold = prefs.getInt('goldCoins') ?? 0;
    final savedNextTimeStr = prefs.getString('nextTicketTime');

    final savedRewardDay = prefs.getInt('dailyRewardDay') ?? 1;
    final savedRewardTimeStr = prefs.getString('lastDailyRewardTime');
    DateTime? lastRewardTime = savedRewardTimeStr != null ? DateTime.tryParse(savedRewardTimeStr) : null;
    final savedLegendaryTier = prefs.getInt('legendaryPackageTier') ?? 0;

    DateTime? nextTime =
        savedNextTimeStr != null ? DateTime.tryParse(savedNextTimeStr) : null;

    if (savedRegenTickets < _maxRegenTickets && nextTime != null) {
      final now = DateTime.now();
      while (now.isAfter(nextTime!) && savedRegenTickets < _maxRegenTickets) {
        savedRegenTickets++;
        nextTime = nextTime.add(const Duration(hours: 6));
      }
      if (savedRegenTickets >= _maxRegenTickets) {
        nextTime = null;
      }
    }

    state = state.copyWith(
      regenTickets: savedRegenTickets,
      bonusTickets: savedBonusTickets,
      totalPoints: savedPoints,
      silverCoins: savedSilver,
      goldCoins: savedGold,
      nextTicketTime: nextTime,
      clearNextTicketTime: nextTime == null,
      dailyRewardDay: savedRewardDay,
      lastDailyRewardTime: lastRewardTime,
      legendaryPackageTier: savedLegendaryTier,
    );

    _isDataLoaded = true;
    await _saveData();
  }

  Future<void> _saveData() async {
    if (!_isDataLoaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('regenTickets', state.regenTickets);
    await prefs.setInt('bonusTickets', state.bonusTickets);
    await prefs.setInt('totalPoints', state.totalPoints);
    await prefs.setInt('silverCoins', state.silverCoins);
    await prefs.setInt('goldCoins', state.goldCoins);

    await prefs.setInt('dailyRewardDay', state.dailyRewardDay);
    if (state.lastDailyRewardTime != null) {
      await prefs.setString('lastDailyRewardTime', state.lastDailyRewardTime!.toIso8601String());
    }

    await prefs.setInt('legendaryPackageTier', state.legendaryPackageTier);

    if (state.nextTicketTime != null) {
      await prefs.setString('nextTicketTime', state.nextTicketTime!.toIso8601String());
    } else {
      await prefs.remove('nextTicketTime');
    }
  }

  void _startTicketTimer() {
    _ticketTimer?.cancel();
    _ticketTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDataLoaded) return;

      if (state.regenTickets >= _maxRegenTickets) {
        if (state.nextTicketTime != null) {
          state = state.copyWith(clearNextTicketTime: true);
          _saveData();
        }
        return;
      }

      if (state.nextTicketTime != null &&
          DateTime.now().isAfter(state.nextTicketTime!)) {
        int newRegenTickets = state.regenTickets + 1;
        DateTime? nextTime = newRegenTickets >= _maxRegenTickets
            ? null
            : state.nextTicketTime!.add(const Duration(hours: 6));

        state = state.copyWith(
          regenTickets: newRegenTickets,
          nextTicketTime: nextTime,
          clearNextTicketTime: nextTime == null,
        );
        _saveData();
      } else {
        state = state.copyWith();
      }
    });
  }

  void initBoard() {
    List<List<TileModel?>> newGrid = List.generate(
      state.gridRows,
      (r) => List.generate(state.gridCols, (c) => null),
    );

    for (int r = 0; r < state.gridRows; r++) {
      for (int c = 0; c < state.gridCols; c++) {
        TileType type;
        do {
          type = TileType.values[_random.nextInt(TileType.values.length)];
        } while (_createsMatchOnSpawn(newGrid, r, c, type));

        newGrid[r][c] = TileModel(
          id: 'tile_${r}_${c}_${DateTime.now().microsecondsSinceEpoch}',
          row: r,
          col: c,
          type: type,
          isFalling: false,
          fallDistance: 1,
        );
      }
    }

    _hasUsedLastChanceInCurrentGame = false;

    int startMovesLvl = getSkillLevel(SkillType.passiveStartMoves);
    int baseMoves = 15;
    int extraMoves = startMovesLvl > 0 ? 5 : 0;

    state = state.copyWith(
      grid: newGrid,
      movesLeft: baseMoves + extraMoves,
      score: 0,
      skillBars: {for (var type in TileType.values) type: 0},
      skillCostMultipliers: {for (var type in TileType.values) type: 1},
      clearSelected: true,
      activeSkillMode: SkillMode.none,
      doubleScoreMovesLeft: 0,
      highlightedTileIds: {},
      isProcessingSkill: false,
      isProcessingBoard: false,
    );
  }

  bool _createsMatchOnSpawn(
      List<List<TileModel?>> grid, int r, int c, TileType type) {
    if (r >= 2 &&
        grid[r - 1][c]?.type == type &&
        grid[r - 2][c]?.type == type) {
      return true;
    }
    if (c >= 2 &&
        grid[r][c - 1]?.type == type &&
        grid[r][c - 2]?.type == type) {
      return true;
    }
    return false;
  }

  void onTileTap(TileModel tile) async {
    if (state.movesLeft <= 0 ||
        state.highlightedTileIds.isNotEmpty ||
        state.isProcessingSkill ||
        state.isProcessingBoard) return;

    if (state.activeSkillMode != SkillMode.none) {
      final mode = state.activeSkillMode;
      state = state.copyWith(
        activeSkillMode: SkillMode.none,
        isProcessingSkill: true,
      );

      try {
        if (mode == SkillMode.redBomb) {
          int size = getRedSkillGridSize();
          int halfLeft = (size - 1) ~/ 2;
          int halfRight = size - 1 - halfLeft;

          List<TileModel> toExplode = [];
          for (int r = tile.row - halfLeft; r <= tile.row + halfRight; r++) {
            for (int c = tile.col - halfLeft; c <= tile.col + halfRight; c++) {
              if (r >= 0 && r < state.gridRows && c >= 0 && c < state.gridCols) {
                final t = state.grid[r][c];
                if (t != null) toExplode.add(t);
              }
            }
          }
          await _processMatches(toExplode);
        } else if (mode == SkillMode.greenTransform) {
          TileType targetType = tile.type;
          int transformCount = getGreenTransformCount();

          List<TileModel> candidates = [];
          for (int r = 0; r < state.gridRows; r++) {
            for (int c = 0; c < state.gridCols; c++) {
              final current = state.grid[r][c];
              if (current != null && current.type != targetType) {
                candidates.add(current);
              }
            }
          }

          candidates.shuffle(_random);
          List<TileModel> targetTiles = candidates.take(transformCount).toList();

          if (targetTiles.isNotEmpty) {
            state = state.copyWith(
              highlightedTileIds: targetTiles.map((t) => t.id).toSet(),
            );

            await Future.delayed(const Duration(milliseconds: 850));

            List<List<TileModel?>> grid = _cloneGrid(state.grid);
            for (var t in targetTiles) {
              grid[t.row][t.col] = t.copyWith(type: targetType, isFalling: false);
            }

            state = state.copyWith(grid: grid, highlightedTileIds: {});

            final newMatches = _findMatches(grid);
            if (newMatches.isNotEmpty) await _processMatches(newMatches);
          }
        } else if (mode == SkillMode.purpleClear) {
          int purpleLvl = getSkillLevel(SkillType.purpleDoubleClear);

          List<TileModel> firstBatch = [];
          for (int r = 0; r < state.gridRows; r++) {
            for (int c = 0; c < state.gridCols; c++) {
              final t = state.grid[r][c];
              if (t != null && t.type == tile.type) {
                firstBatch.add(t);
              }
            }
          }

          if (firstBatch.isNotEmpty) {
            state = state.copyWith(
              highlightedTileIds: firstBatch.map((t) => t.id).toSet(),
            );
            await Future.delayed(const Duration(milliseconds: 600));
            state = state.copyWith(highlightedTileIds: {});

            await _processMatches(firstBatch);

            if (purpleLvl >= 1) {
              await Future.delayed(const Duration(milliseconds: 500));

              Map<TileType, int> typeCounts = {};
              for (int r = 0; r < state.gridRows; r++) {
                for (int c = 0; c < state.gridCols; c++) {
                  final t = state.grid[r][c];
                  if (t != null) {
                    typeCounts[t.type] = (typeCounts[t.type] ?? 0) + 1;
                  }
                }
              }

              if (typeCounts.isNotEmpty) {
                TileType dominantType = typeCounts.entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key;

                List<TileModel> secondBatch = [];
                for (int r = 0; r < state.gridRows; r++) {
                  for (int c = 0; c < state.gridCols; c++) {
                    final t = state.grid[r][c];
                    if (t != null && t.type == dominantType) {
                      secondBatch.add(t);
                    }
                  }
                }

                if (secondBatch.isNotEmpty) {
                  state = state.copyWith(
                    highlightedTileIds: secondBatch.map((t) => t.id).toSet(),
                  );
                  await Future.delayed(const Duration(milliseconds: 600));
                  state = state.copyWith(highlightedTileIds: {});

                  await _processMatches(secondBatch);
                }
              }
            }
          }
        }
      } finally {
        state = state.copyWith(isProcessingSkill: false);
      }
      return;
    }

    if (state.selectedTile == null) {
      state = state.copyWith(selectedTile: tile);
    } else {
      final selected = state.selectedTile!;
      if (selected.id == tile.id) {
        state = state.copyWith(clearSelected: true);
      } else if (_isAdjacent(selected, tile)) {
        _swapAndCheckMatches(selected, tile);
      } else {
        state = state.copyWith(selectedTile: tile);
      }
    }
  }

  bool _isAdjacent(TileModel a, TileModel b) {
    return (a.row == b.row && (a.col - b.col).abs() == 1) ||
        (a.col == b.col && (a.row - b.row).abs() == 1);
  }

  Future<void> _swapAndCheckMatches(TileModel a, TileModel b) async {
    state = state.copyWith(isProcessingBoard: true);

    List<List<TileModel?>> tempGrid = _cloneGrid(state.grid);
    tempGrid[a.row][a.col] = b.copyWith(row: a.row, col: a.col, isFalling: false);
    tempGrid[b.row][b.col] = a.copyWith(row: b.row, col: b.col, isFalling: false);

    int newDoubleScoreMoves = state.doubleScoreMovesLeft;
    if (newDoubleScoreMoves > 0) newDoubleScoreMoves--;

    int remainingMoves = state.movesLeft - 1;

    state = state.copyWith(
      grid: tempGrid,
      clearSelected: true,
      movesLeft: remainingMoves,
      doubleScoreMovesLeft: newDoubleScoreMoves,
    );

    final matches = _findMatches(tempGrid);
    if (matches.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      tempGrid[a.row][a.col] = a.copyWith(isFalling: false);
      tempGrid[b.row][b.col] = b.copyWith(isFalling: false);
      state = state.copyWith(
        grid: tempGrid,
        movesLeft: state.movesLeft + 1,
        doubleScoreMovesLeft: state.doubleScoreMovesLeft > 0 ? state.doubleScoreMovesLeft + 1 : 0,
        isProcessingBoard: false,
      );
    } else {
      await _processMatches(matches);
      state = state.copyWith(isProcessingBoard: false);
    }

    if (state.movesLeft <= 0 && !_hasUsedLastChanceInCurrentGame) {
      int lastChanceLvl = getSkillLevel(SkillType.passiveLastChance);
      if (lastChanceLvl > 0) {
        double chance =
            lastChanceLvl == 1 ? 0.20 : (lastChanceLvl == 2 ? 0.40 : 0.60);
        if (_random.nextDouble() < chance) {
          _hasUsedLastChanceInCurrentGame = true;
          state = state.copyWith(movesLeft: 3);
        }
      }
    }
  }

  List<TileModel> _findMatches(List<List<TileModel?>> grid) {
    Set<TileModel> matched = {};

    for (int r = 0; r < state.gridRows; r++) {
      for (int c = 0; c < state.gridCols - 2; c++) {
        final t1 = grid[r][c];
        final t2 = grid[r][c + 1];
        final t3 = grid[r][c + 2];
        if (t1 != null && t2 != null && t3 != null) {
          if (t1.type == t2.type && t2.type == t3.type) {
            matched.addAll([t1, t2, t3]);
          }
        }
      }
    }

    for (int c = 0; c < state.gridCols; c++) {
      for (int r = 0; r < state.gridRows - 2; r++) {
        final t1 = grid[r][c];
        final t2 = grid[r + 1][c];
        final t3 = grid[r + 2][c];
        if (t1 != null && t2 != null && t3 != null) {
          if (t1.type == t2.type && t2.type == t3.type) {
            matched.addAll([t1, t2, t3]);
          }
        }
      }
    }

    return matched.toList();
  }

  Future<void> _processMatches(List<TileModel> matches) async {
    if (matches.isEmpty) return;

    state = state.copyWith(isProcessingBoard: true);

    int boxScoreLvl = getSkillLevel(SkillType.passiveBoxScore);
    int fastSkillLvl = getSkillLevel(SkillType.passiveComboBonus);

    int baseScore = matches.length * 100;

    double bonusMultiplier = 1.0;
    if (boxScoreLvl == 1) bonusMultiplier = 1.10;
    if (boxScoreLvl == 2) bonusMultiplier = 1.20;
    if (boxScoreLvl == 3) bonusMultiplier = 1.35;

    int addedScore = (baseScore * bonusMultiplier).round();
    if (state.doubleScoreMovesLeft > 0) {
      addedScore *= getYellowMultiplierValue();
    }

    Map<TileType, int> updatedBars = Map.from(state.skillBars);

    double chargeMultiplier = 1.0;
    if (fastSkillLvl == 1) chargeMultiplier = 1.20;
    if (fastSkillLvl == 2) chargeMultiplier = 1.40;
    if (fastSkillLvl == 3) chargeMultiplier = 1.60;

    int baseCharge = (8 * chargeMultiplier).round();

    for (var tile in matches) {
      int maxBar = getRequiredSkillBarMax(tile.type);
      int currentVal = updatedBars[tile.type] ?? 0;
      updatedBars[tile.type] = min(maxBar, currentVal + baseCharge);
    }

    // 1. Patlayan kutuları tahtadan sil
    List<List<TileModel?>> grid = _cloneGrid(state.grid);
    for (var m in matches) {
      if (m.row < state.gridRows && m.col < state.gridCols) {
        grid[m.row][m.col] = null;
      }
    }

    state = state.copyWith(
      grid: grid,
      score: state.score + addedScore,
      skillBars: updatedBars,
    );

    // Boşluk bekleme süresi optimize edildi (Siyah boşlukta takılmadan hemen düşüş başlar)
    await Future.delayed(const Duration(milliseconds: 120));

    // 2. Taşların düşürülmesi
    await _applyGravityAndRefill(grid);
  }

  Future<void> _applyGravityAndRefill(List<List<TileModel?>> grid) async {
    final int dropSessionId = DateTime.now().microsecondsSinceEpoch;

    for (int c = 0; c < state.gridCols; c++) {
      int emptySpaces = 0;
      for (int r = state.gridRows - 1; r >= 0; r--) {
        if (grid[r][c] == null) {
          emptySpaces++;
        } else if (emptySpaces > 0) {
          TileModel original = grid[r][c]!;
          // Konumu değişen taşın ID'si session id ile yenilenerek AnimatedSwitcher'ın tetiklenmesi sağlanır
          grid[r + emptySpaces][c] = original.copyWith(
            id: 'fall_${original.type.name}_${r + emptySpaces}_${c}_$dropSessionId',
            row: r + emptySpaces,
            isFalling: true,
            fallDistance: emptySpaces,
          );
          grid[r][c] = null;
        } else {
          grid[r][c] = grid[r][c]!.copyWith(isFalling: false);
        }
      }

      // Tepeden boşluklara yeni giren taşlar
      for (int i = 0; i < emptySpaces; i++) {
        final type = TileType.values[_random.nextInt(TileType.values.length)];
        grid[i][c] = TileModel(
          id: 'spawn_${type.name}_${i}_${c}_$dropSessionId',
          row: i,
          col: c,
          type: type,
          isFalling: true,
          fallDistance: emptySpaces + (emptySpaces - i),
        );
      }
    }

    state = state.copyWith(grid: grid);

    // Salınımın tamamlanması için bekleme süresi
    await Future.delayed(const Duration(milliseconds: 550));

    // 3. Kombo kontrolü
    final cascadeMatches = _findMatches(grid);
    if (cascadeMatches.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 180));
      await _processMatches(cascadeMatches);
    } else {
      state = state.copyWith(isProcessingBoard: false);
    }
  }

  void useSkill(TileType type) {
    if (state.isProcessingSkill || state.isProcessingBoard || state.activeSkillMode != SkillMode.none) return;

    int currentMax = getRequiredSkillBarMax(type);
    if ((state.skillBars[type] ?? 0) < currentMax) return;

    Map<TileType, int> updatedBars = Map.from(state.skillBars);
    Map<TileType, int> updatedMultipliers = Map.from(state.skillCostMultipliers);

    updatedBars[type] = 0;
    updatedMultipliers[type] = (updatedMultipliers[type] ?? 1) + 1;

    switch (type) {
      case TileType.blue:
        int bonusMoves = getBlueSkillMoveBonus();
        state = state.copyWith(
          movesLeft: state.movesLeft + bonusMoves,
          skillBars: updatedBars,
          skillCostMultipliers: updatedMultipliers,
        );
        break;

      case TileType.yellow:
        state = state.copyWith(
          skillBars: updatedBars,
          skillCostMultipliers: updatedMultipliers,
          doubleScoreMovesLeft: 3,
          activeSkillMode: SkillMode.none,
        );
        break;

      case TileType.red:
        state = state.copyWith(
          skillBars: updatedBars,
          skillCostMultipliers: updatedMultipliers,
          activeSkillMode: SkillMode.redBomb,
        );
        break;

      case TileType.green:
        state = state.copyWith(
          skillBars: updatedBars,
          skillCostMultipliers: updatedMultipliers,
          activeSkillMode: SkillMode.greenTransform,
        );
        break;

      case TileType.purple:
        state = state.copyWith(
          skillBars: updatedBars,
          skillCostMultipliers: updatedMultipliers,
          activeSkillMode: SkillMode.purpleClear,
        );
        break;
    }
  }

  Future<void> addScoreToWallet() async {
    if (state.score <= 0) return;
    final updatedTotalPoints = state.totalPoints + state.score;
    state = state.copyWith(totalPoints: updatedTotalPoints, score: 0);
    await _saveData();
  }

  Future<void> convertEarnedScoreToGold() async {
    int goldGained = state.score ~/ 100000;
    int usedPoints = goldGained * 100000;
    int remainingScorePoints = state.score - usedPoints;

    state = state.copyWith(
      goldCoins: state.goldCoins + goldGained,
      totalPoints: state.totalPoints + remainingScorePoints,
      score: 0,
    );
    await _saveData();
  }

  Future<void> convertEarnedScoreToSilver() async {
    int silverGained = state.score ~/ 10000;
    int usedPoints = silverGained * 10000;
    int remainingScorePoints = state.score - usedPoints;

    state = state.copyWith(
      silverCoins: state.silverCoins + silverGained,
      totalPoints: state.totalPoints + remainingScorePoints,
      score: 0,
    );
    await _saveData();
  }

  void buyPackage({int addTickets = 0, int addGold = 0, int addSilver = 0}) {
    state = state.copyWith(
      bonusTickets: state.bonusTickets + addTickets,
      goldCoins: state.goldCoins + addGold,
      silverCoins: state.silverCoins + addSilver,
    );
    _saveData();
  }

  bool convertCustomPointsToGold(int pointsToConvert) {
    if (state.totalPoints >= pointsToConvert && pointsToConvert >= 100000) {
      int goldGained = pointsToConvert ~/ 100000;
      int pointsUsed = goldGained * 100000;

      state = state.copyWith(
        totalPoints: state.totalPoints - pointsUsed,
        goldCoins: state.goldCoins + goldGained,
      );
      _saveData();
      return true;
    }
    return false;
  }

  bool convertCustomPointsToSilver(int pointsToConvert) {
    if (state.totalPoints >= pointsToConvert && pointsToConvert >= 10000) {
      int silverGained = pointsToConvert ~/ 10000;
      int pointsUsed = silverGained * 10000;

      state = state.copyWith(
        totalPoints: state.totalPoints - pointsUsed,
        silverCoins: state.silverCoins + silverGained,
      );
      _saveData();
      return true;
    }
    return false;
  }

  List<List<TileModel?>> _cloneGrid(List<List<TileModel?>> original) {
    return List.generate(
      original.length,
      (r) => List.generate(original[r].length, (c) => original[r][c]),
    );
  }

  @override
  void dispose() {
    _ticketTimer?.cancel();
    super.dispose();
  }
}