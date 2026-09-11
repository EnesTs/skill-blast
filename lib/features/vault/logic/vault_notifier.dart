import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:match3/features/game/logic/game_notifier.dart';
import '../models/relic_model.dart';

class VaultState {
  final Map<String, RelicProgress> relics;
  final bool isLoading;

  VaultState({
    required this.relics,
    this.isLoading = true,
  });

  int get totalPrestige {
    int prestige = 0;
    for (var data in RelicData.allRelics) {
      final prog = relics[data.id];
      if (prog != null) {
        if (prog.level >= 1) prestige += data.level1Prestige;
        if (prog.level >= 2) prestige += data.level2Prestige;
      }
    }
    return prestige;
  }

  String get leagueName {
    final p = totalPrestige;
    if (p >= 10000) return 'Titan Ligi';
    if (p >= 7000) return 'Elmas Lig';
    if (p >= 3800) return 'Platin Lig';
    if (p >= 1700) return 'Altın Lig';
    if (p >= 500) return 'Gümüş Lig';
    return 'Bronz Lig';
  }

  double get leagueProgress {
    final p = totalPrestige;
    if (p >= 10000) return 1.0;
    if (p >= 7000) return (p - 7000) / 3000;
    if (p >= 3800) return (p - 3800) / 3200;
    if (p >= 1700) return (p - 1700) / 2100;
    if (p >= 500) return (p - 500) / 1200;
    return (p / 500).clamp(0.0, 1.0);
  }

  int get nextLeagueGoal {
    final p = totalPrestige;
    if (p >= 10000) return 12000;
    if (p >= 7000) return 10000;
    if (p >= 3800) return 7000;
    if (p >= 1700) return 3800;
    if (p >= 500) return 1700;
    return 500;
  }

  int getPendingReward(RelicData data) {
    final prog = relics[data.id];
    if (prog == null || prog.level == 0) return 0;

    final diff = DateTime.now().difference(prog.lastCollectTime);
    int cappedSeconds = diff.inSeconds.clamp(0, 24 * 3600); // 24 saat tavan sınırı

    int hoursPerTick = prog.level == 1 ? data.level1HoursPerTick : data.level2HoursPerTick;
    int amountPerTick = prog.level == 1 ? data.level1RewardAmount : data.level2RewardAmount;

    int tickSeconds = hoursPerTick * 3600;
    int ticks = cappedSeconds ~/ tickSeconds;
    return ticks * amountPerTick;
  }
}

final vaultProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  return VaultNotifier(ref);
});

class VaultNotifier extends StateNotifier<VaultState> {
  final Ref ref;
  Timer? _tickerTimer;

  VaultNotifier(this.ref) : super(VaultState(relics: {})) {
    _loadVault();
    _tickerTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      state = VaultState(relics: Map.from(state.relics), isLoading: false);
    });
  }

  Future<void> _loadVault() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, RelicProgress> loaded = {};

    for (var data in RelicData.allRelics) {
      int lvl = prefs.getInt('relic_lvl_${data.id}') ?? 0;
      String? timeStr = prefs.getString('relic_time_${data.id}');
      DateTime time = timeStr != null ? DateTime.tryParse(timeStr) ?? DateTime.now() : DateTime.now();

      loaded[data.id] = RelicProgress(level: lvl, lastCollectTime: time);
    }

    state = VaultState(relics: loaded, isLoading: false);
  }

  Future<void> _saveRelic(String id, RelicProgress prog) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('relic_lvl_$id', prog.level);
    await prefs.setString('relic_time_$id', prog.lastCollectTime.toIso8601String());
  }

  bool unlockRelic(RelicData data) {
    final gameNotif = ref.read(gameProvider.notifier);
    final currentGold = ref.read(gameProvider).goldCoins;
    final current = state.relics[data.id] ?? RelicProgress(level: 0, lastCollectTime: DateTime.now());

    if (current.level != 0 || currentGold < data.unlockCost) return false;

    gameNotif.deductGold(data.unlockCost);
    final updated = current.copyWith(level: 1, lastCollectTime: DateTime.now());

    Map<String, RelicProgress> newMap = Map.from(state.relics);
    newMap[data.id] = updated;
    state = VaultState(relics: newMap, isLoading: false);

    _saveRelic(data.id, updated);
    return true;
  }

  bool upgradeRelic(RelicData data) {
    final gameNotif = ref.read(gameProvider.notifier);
    final currentGold = ref.read(gameProvider).goldCoins;
    final current = state.relics[data.id];

    if (current == null || current.level != 1 || currentGold < data.upgradeCost) return false;

    gameNotif.deductGold(data.upgradeCost);
    final updated = current.copyWith(level: 2);

    Map<String, RelicProgress> newMap = Map.from(state.relics);
    newMap[data.id] = updated;
    state = VaultState(relics: newMap, isLoading: false);

    _saveRelic(data.id, updated);
    return true;
  }

  bool collectRelicReward(RelicData data) {
    final amount = state.getPendingReward(data);
    if (amount <= 0) return false;

    final gameNotif = ref.read(gameProvider.notifier);
    if (data.rewardType == RelicRewardType.gold) {
      gameNotif.addGold(amount);
    } else {
      gameNotif.addSilver(amount);
    }

    final current = state.relics[data.id]!;
    final updated = current.copyWith(lastCollectTime: DateTime.now());

    Map<String, RelicProgress> newMap = Map.from(state.relics);
    newMap[data.id] = updated;
    state = VaultState(relics: newMap, isLoading: false);

    _saveRelic(data.id, updated);
    return true;
  }

  void collectAllRewards() {
    for (var data in RelicData.allRelics) {
      collectRelicReward(data);
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }
}