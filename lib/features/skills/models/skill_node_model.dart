enum SkillCategory { active, passive }

enum SkillType { 
  blueMoves, 
  redExplosion, 
  greenTransform, 
  yellowMultiplier, 
  purpleDoubleClear,
  passiveBoxScore,
  passiveStartMoves,
  passiveLastChance,
  passiveComboBonus,
}

class SkillSubUpgrade {
  final int level;
  final int silverCost;
  final int goldCost;
  final String effectDescription;

  const SkillSubUpgrade({
    required this.level,
    this.silverCost = 0,
    this.goldCost = 0,
    required this.effectDescription,
  });

  bool get requiresGold => goldCost > 0;
}

class SkillNodeModel {
  final String id;
  final String title;
  final String description;
  final SkillType type;
  final SkillCategory category;
  final int currentLevel;
  final int maxLevel;
  final List<SkillSubUpgrade> subUpgrades;

  const SkillNodeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.currentLevel = 0,
    required this.maxLevel,
    required this.subUpgrades,
  });

  bool get isMaxed => currentLevel >= maxLevel;
  
  SkillSubUpgrade? get nextUpgrade {
    if (isMaxed) return null;
    return subUpgrades.firstWhere((sub) => sub.level == currentLevel + 1);
  }

  // Seviyeye göre anlık aktif olan etki açıklamasını döner
  String get currentEffectDescription {
    if (currentLevel == 0) return 'Henüz Aktif Değil (Taban Etki)';
    return subUpgrades.firstWhere(
      (sub) => sub.level == currentLevel,
      orElse: () => subUpgrades.first,
    ).effectDescription;
  }

  SkillNodeModel copyWith({
    String? id,
    String? title,
    String? description,
    SkillType? type,
    SkillCategory? category,
    int? currentLevel,
    int? maxLevel,
    List<SkillSubUpgrade>? subUpgrades,
  }) {
    return SkillNodeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      currentLevel: currentLevel ?? this.currentLevel,
      maxLevel: maxLevel ?? this.maxLevel,
      subUpgrades: subUpgrades ?? this.subUpgrades,
    );
  }
}