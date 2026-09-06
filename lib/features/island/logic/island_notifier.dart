// island_notifier.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:match3/features/game/logic/game_notifier.dart';
import '../models/island_model.dart';

class IslandState {
  final List<IslandModel> islands;
  final int activeIslandIndex;

  const IslandState({
    required this.islands,
    this.activeIslandIndex = 0,
  });

  IslandState copyWith({
    List<IslandModel>? islands,
    int? activeIslandIndex,
  }) {
    return IslandState(
      islands: islands ?? this.islands,
      activeIslandIndex: activeIslandIndex ?? this.activeIslandIndex,
    );
  }

  int get totalPrestijScore {
    int total = 0;
    for (var island in islands) {
      total += island.totalIslandPrestij;
    }
    return total;
  }
}

class IslandNotifier extends StateNotifier<IslandState> {
  final Ref ref;
  bool _isDataLoaded = false;

  IslandNotifier(this.ref) : super(_initialState()) {
    _initNotifier();
  }

  Future<void> _initNotifier() async {
    await _loadSavedData();
  }

  static IslandState _initialState() {
    return IslandState(
      islands: [
        // 1. TROPİKAL ADA
        const IslandModel(
          id: 'island_1',
          name: '🌴 Tropikal Cennet',
          description: 'Huzurlu ve palmiyelerle dolu ilk adanız.',
          isUnlocked: true,
          unlockGoldCost: 0,
          unlockPrestijBonus: 100,
          buildings: [
            BuildingModel(
              id: 'b1_castle',
              name: 'Sahil Şatosu',
              type: BuildingType.castle,
              emoji: '🏰',
              basePrestijPoints: 100,
              upgradeGoldCost: 50,
            ),
            BuildingModel(
              id: 'b1_lighthouse',
              name: 'Deniz Feneri',
              type: BuildingType.lighthouse,
              emoji: '🌊',
              basePrestijPoints: 50,
              upgradeGoldCost: 25,
            ),
            BuildingModel(
              id: 'b1_harbor',
              name: 'Ahşap İskele',
              type: BuildingType.harbor,
              emoji: '⚓',
              basePrestijPoints: 75,
              upgradeGoldCost: 35,
            ),
          ],
        ),

        // 2. KORSAN KOYU
        const IslandModel(
          id: 'island_2',
          name: '🏴‍☠️ Korsan Koyu',
          description: 'Gizli definelerin ve tehlikeli suların adası.',
          isUnlocked: false,
          unlockGoldCost: 300,
          unlockPrestijBonus: 300,
          buildings: [
            BuildingModel(
              id: 'b2_castle',
              name: 'Korsan Kalesi',
              type: BuildingType.castle,
              emoji: '🏴‍☠️',
              basePrestijPoints: 250,
              upgradeGoldCost: 100,
            ),
            BuildingModel(
              id: 'b2_harbor',
              name: 'Karakol Limanı',
              type: BuildingType.harbor,
              emoji: '⛓️',
              basePrestijPoints: 150,
              upgradeGoldCost: 80,
            ),
            BuildingModel(
              id: 'b2_mine',
              name: 'Hazine Mağarası',
              type: BuildingType.mine,
              emoji: '💎',
              basePrestijPoints: 300,
              upgradeGoldCost: 150,
            ),
          ],
        ),

        // 3. VOLKANİK TAPINAK
        const IslandModel(
          id: 'island_3',
          name: '🌋 Volkanik Tapınak',
          description: 'Ateşin ve kadim güçlerin yükseldiği tepe.',
          isUnlocked: false,
          unlockGoldCost: 800,
          unlockPrestijBonus: 600,
          buildings: [
            BuildingModel(
              id: 'b3_dragon',
              name: 'Ejderha Yuvası',
              type: BuildingType.castle,
              emoji: '🐉',
              basePrestijPoints: 500,
              upgradeGoldCost: 250,
            ),
            BuildingModel(
              id: 'b3_mine',
              name: 'Lav Madeni',
              type: BuildingType.mine,
              emoji: '🌋',
              basePrestijPoints: 400,
              upgradeGoldCost: 200,
            ),
            BuildingModel(
              id: 'b3_temple',
              name: 'Ateş Tapınağı',
              type: BuildingType.lighthouse,
              emoji: '🔥',
              basePrestijPoints: 600,
              upgradeGoldCost: 300,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIslandsString = prefs.getString('saved_islands_data');
    final savedIndex = prefs.getInt('active_island_index') ?? 0;

    if (savedIslandsString != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(savedIslandsString);
        final loadedIslands =
            decodedList.map((item) => IslandModel.fromJson(item)).toList();

        state = state.copyWith(
          islands: loadedIslands,
          activeIslandIndex: savedIndex.clamp(0, loadedIslands.length - 1),
        );
      } catch (_) {
        // Hata durumunda varsayılan state korunur
      }
    }

    _isDataLoaded = true;
    await _saveData();
  }

  Future<void> _saveData() async {
    if (!_isDataLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final String encodedIslands =
        jsonEncode(state.islands.map((i) => i.toJson()).toList());

    await prefs.setString('saved_islands_data', encodedIslands);
    await prefs.setInt('active_island_index', state.activeIslandIndex);
  }

  void changePage(int index) {
    state = state.copyWith(activeIslandIndex: index);
    _saveData();
  }

  bool unlockIsland(String islandId) {
    final gameNotifier = ref.read(gameProvider.notifier);
    final gameState = ref.read(gameProvider);

    final islandIndex = state.islands.indexWhere((i) => i.id == islandId);
    if (islandIndex == -1) return false;

    final island = state.islands[islandIndex];

    if (gameState.goldCoins >= island.unlockGoldCost) {
      gameNotifier.deductGold(island.unlockGoldCost);

      final updatedIslands = List<IslandModel>.from(state.islands);
      updatedIslands[islandIndex] = island.copyWith(isUnlocked: true);

      state = state.copyWith(islands: updatedIslands);
      _saveData();
      return true;
    }
    return false;
  }

  bool upgradeBuilding(String islandId, String buildingId) {
    final gameNotifier = ref.read(gameProvider.notifier);
    final gameState = ref.read(gameProvider);

    final islandIndex = state.islands.indexWhere((i) => i.id == islandId);
    if (islandIndex == -1) return false;

    final island = state.islands[islandIndex];
    final buildingIndex =
        island.buildings.indexWhere((b) => b.id == buildingId);
    if (buildingIndex == -1) return false;

    final building = island.buildings[buildingIndex];

    if (building.currentLevel >= building.maxLevel) return false;

    final cost = building.nextUpgradeCost;

    if (gameState.goldCoins >= cost) {
      gameNotifier.deductGold(cost);

      final updatedBuildings = List<BuildingModel>.from(island.buildings);
      updatedBuildings[buildingIndex] = building.copyWith(
        currentLevel: building.currentLevel + 1,
      );

      final updatedIslands = List<IslandModel>.from(state.islands);
      updatedIslands[islandIndex] =
          island.copyWith(buildings: updatedBuildings);

      state = state.copyWith(islands: updatedIslands);
      _saveData();
      return true;
    }

    return false;
  }
}

final islandProvider =
    StateNotifierProvider<IslandNotifier, IslandState>((ref) {
  return IslandNotifier(ref);
});