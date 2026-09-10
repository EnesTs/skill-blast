import '../models/tile_model.dart';

enum SkillMode { none, redBomb, greenTransform, purpleClear }

class GameState {
  final List<List<TileModel?>> grid;
  final int gridRows;
  final int gridCols;
  final int movesLeft;
  final int score;
  final int totalPoints;
  final int silverCoins;
  final int goldCoins;
  final int regenTickets;
  final int bonusTickets;
  final DateTime? nextTicketTime;
  final Map<TileType, int> skillBars;
  final Map<TileType, int> skillCostMultipliers;
  final TileModel? selectedTile;
  final SkillMode activeSkillMode;
  final int doubleScoreMovesLeft;
  final Set<String> highlightedTileIds;
  final bool isProcessingSkill;
  final bool isProcessingBoard; // Tahta akıştayken dokunmaları kilitler

  final int dailyRewardDay;
  final DateTime? lastDailyRewardTime;
  final int legendaryPackageTier;

  GameState({
    required this.grid,
    this.gridRows = 8,
    this.gridCols = 8,
    this.movesLeft = 15,
    this.score = 0,
    this.totalPoints = 0,
    this.silverCoins = 0,
    this.goldCoins = 0,
    this.regenTickets = 5,
    this.bonusTickets = 0,
    this.nextTicketTime,
    required this.skillBars,
    required this.skillCostMultipliers,
    this.selectedTile,
    this.activeSkillMode = SkillMode.none,
    this.doubleScoreMovesLeft = 0,
    this.highlightedTileIds = const {},
    this.isProcessingSkill = false,
    this.isProcessingBoard = false,
    this.dailyRewardDay = 1,
    this.lastDailyRewardTime,
    this.legendaryPackageTier = 0,
  });

  int get totalTickets => regenTickets + bonusTickets;

  bool get isDailyRewardClaimable {
    if (lastDailyRewardTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastDailyRewardTime!);
    return difference.inHours >= 24;
  }

  String get formattedNextTicketTime {
    if (nextTicketTime == null) return '';
    final remaining = nextTicketTime!.difference(DateTime.now());
    if (remaining.isNegative) return '00:00:00';
    
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    return '$hours:$minutes:$seconds';
  }

  GameState copyWith({
    List<List<TileModel?>>? grid,
    int? gridRows,
    int? gridCols,
    int? movesLeft,
    int? score,
    int? totalPoints,
    int? silverCoins,
    int? goldCoins,
    int? regenTickets,
    int? bonusTickets,
    DateTime? nextTicketTime,
    bool clearNextTicketTime = false,
    Map<TileType, int>? skillBars,
    Map<TileType, int>? skillCostMultipliers,
    TileModel? selectedTile,
    bool clearSelected = false,
    SkillMode? activeSkillMode,
    int? doubleScoreMovesLeft,
    Set<String>? highlightedTileIds,
    bool? isProcessingSkill,
    bool? isProcessingBoard,
    int? dailyRewardDay,
    DateTime? lastDailyRewardTime,
    int? legendaryPackageTier,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      gridRows: gridRows ?? this.gridRows,
      gridCols: gridCols ?? this.gridCols,
      movesLeft: movesLeft ?? this.movesLeft,
      score: score ?? this.score,
      totalPoints: totalPoints ?? this.totalPoints,
      silverCoins: silverCoins ?? this.silverCoins,
      goldCoins: goldCoins ?? this.goldCoins,
      regenTickets: regenTickets ?? this.regenTickets,
      bonusTickets: bonusTickets ?? this.bonusTickets,
      nextTicketTime: clearNextTicketTime ? null : (nextTicketTime ?? this.nextTicketTime),
      skillBars: skillBars ?? this.skillBars,
      skillCostMultipliers: skillCostMultipliers ?? this.skillCostMultipliers,
      selectedTile: clearSelected ? null : (selectedTile ?? this.selectedTile),
      activeSkillMode: activeSkillMode ?? this.activeSkillMode,
      doubleScoreMovesLeft: doubleScoreMovesLeft ?? this.doubleScoreMovesLeft,
      highlightedTileIds: highlightedTileIds ?? this.highlightedTileIds,
      isProcessingSkill: isProcessingSkill ?? this.isProcessingSkill,
      isProcessingBoard: isProcessingBoard ?? this.isProcessingBoard,
      dailyRewardDay: dailyRewardDay ?? this.dailyRewardDay,
      lastDailyRewardTime: lastDailyRewardTime ?? this.lastDailyRewardTime,
      legendaryPackageTier: legendaryPackageTier ?? this.legendaryPackageTier,
    );
  }
}