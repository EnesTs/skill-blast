// island_model.dart

enum BuildingType { castle, lighthouse, harbor, mine, temple }

class BuildingModel {
  final String id;
  final String name;
  final BuildingType type;
  final String emoji;
  final int currentLevel;
  final int maxLevel;
  final int basePrestijPoints;
  final int upgradeGoldCost;

  const BuildingModel({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
    this.currentLevel = 0,
    this.maxLevel = 5,
    required this.basePrestijPoints,
    required this.upgradeGoldCost,
  });

  int get nextUpgradeCost => (currentLevel + 1) * upgradeGoldCost;
  int get totalPrestij => currentLevel * basePrestijPoints;

  BuildingModel copyWith({
    String? id,
    String? name,
    BuildingType? type,
    String? emoji,
    int? currentLevel,
    int? maxLevel,
    int? basePrestijPoints,
    int? upgradeGoldCost,
  }) {
    return BuildingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      emoji: emoji ?? this.emoji,
      currentLevel: currentLevel ?? this.currentLevel,
      maxLevel: maxLevel ?? this.maxLevel,
      basePrestijPoints: basePrestijPoints ?? this.basePrestijPoints,
      upgradeGoldCost: upgradeGoldCost ?? this.upgradeGoldCost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'emoji': emoji,
      'currentLevel': currentLevel,
      'maxLevel': maxLevel,
      'basePrestijPoints': basePrestijPoints,
      'upgradeGoldCost': upgradeGoldCost,
    };
  }

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      id: json['id'],
      name: json['name'],
      type: BuildingType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BuildingType.castle,
      ),
      emoji: json['emoji'],
      currentLevel: json['currentLevel'] ?? 0,
      maxLevel: json['maxLevel'] ?? 5,
      basePrestijPoints: json['basePrestijPoints'],
      upgradeGoldCost: json['upgradeGoldCost'],
    );
  }
}

class IslandModel {
  final String id;
  final String name;
  final String description;
  final bool isUnlocked;
  final int unlockGoldCost;
  final int unlockPrestijBonus; // Ada açılınca doğrudan gelen prestij
  final List<BuildingModel> buildings;

  const IslandModel({
    required this.id,
    required this.name,
    required this.description,
    this.isUnlocked = false,
    required this.unlockGoldCost,
    this.unlockPrestijBonus = 200, // Varsayılan ada açma prestiji
    required this.buildings,
  });

  int get totalIslandPrestij {
    int buildingPrestij = buildings.fold(0, (sum, b) => sum + b.totalPrestij);
    return isUnlocked ? (buildingPrestij + unlockPrestijBonus) : 0;
  }

  IslandModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isUnlocked,
    int? unlockGoldCost,
    int? unlockPrestijBonus,
    List<BuildingModel>? buildings,
  }) {
    return IslandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockGoldCost: unlockGoldCost ?? this.unlockGoldCost,
      unlockPrestijBonus: unlockPrestijBonus ?? this.unlockPrestijBonus,
      buildings: buildings ?? this.buildings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isUnlocked': isUnlocked,
      'unlockGoldCost': unlockGoldCost,
      'unlockPrestijBonus': unlockPrestijBonus,
      'buildings': buildings.map((b) => b.toJson()).toList(),
    };
  }

  factory IslandModel.fromJson(Map<String, dynamic> json) {
    return IslandModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockGoldCost: json['unlockGoldCost'] ?? 0,
      unlockPrestijBonus: json['unlockPrestijBonus'] ?? 200,
      buildings: (json['buildings'] as List<dynamic>?)
              ?.map((b) => BuildingModel.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}