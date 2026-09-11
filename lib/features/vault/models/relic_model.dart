import 'package:flutter/material.dart';

enum RelicRewardType { gold, silver }

class RelicData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color themeColor;
  final int unlockCost;
  final int upgradeCost;
  final int level1Prestige;
  final int level2Prestige;
  final RelicRewardType rewardType;
  final int level1HoursPerTick;
  final int level1RewardAmount;
  final int level2HoursPerTick;
  final int level2RewardAmount;

  const RelicData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.themeColor,
    required this.unlockCost,
    required this.upgradeCost,
    required this.level1Prestige,
    required this.level2Prestige,
    required this.rewardType,
    required this.level1HoursPerTick,
    required this.level1RewardAmount,
    required this.level2HoursPerTick,
    required this.level2RewardAmount,
  });

  static const List<RelicData> allRelics = [
    RelicData(
      id: 'coin_forge',
      title: 'Kadim Sikke Ocağı',
      description: 'Lav alevleriyle dövülen antik altın sikke ocağı.',
      icon: Icons.monetization_on_rounded,
      themeColor: Color(0xFFF59E0B),
      unlockCost: 150,
      upgradeCost: 300,
      level1Prestige: 200,
      level2Prestige: 300,
      rewardType: RelicRewardType.gold,
      level1HoursPerTick: 2,
      level1RewardAmount: 1,
      level2HoursPerTick: 1,
      level2RewardAmount: 1,
    ),
    RelicData(
      id: 'alchemist_flask',
      title: 'Simyacı İbriği',
      description: 'Sıvı gümüş damıtıp mahzene bereket akıtır.',
      icon: Icons.science_rounded,
      themeColor: Color(0xFF38BDF8),
      unlockCost: 350,
      upgradeCost: 600,
      level1Prestige: 500,
      level2Prestige: 700,
      rewardType: RelicRewardType.silver,
      level1HoursPerTick: 2,
      level1RewardAmount: 25,
      level2HoursPerTick: 1,
      level2RewardAmount: 25,
    ),
    RelicData(
      id: 'dragon_chalice',
      title: 'Ejderha Kadehi',
      description: 'Ejderha kanından arınmış saf altın kaynağı.',
      icon: Icons.emoji_events_rounded,
      themeColor: Color(0xFFEF4444),
      unlockCost: 800,
      upgradeCost: 1200,
      level1Prestige: 900,
      level2Prestige: 1200,
      rewardType: RelicRewardType.gold,
      level1HoursPerTick: 3,
      level1RewardAmount: 2,
      level2HoursPerTick: 3,
      level2RewardAmount: 4,
    ),
    RelicData(
      id: 'treasure_chest',
      title: 'Hazine Sandığı',
      description: 'Kilitleri kırıldıkça etrafa gümüş saçan kadim sandık.',
      icon: Icons.inventory_2_rounded,
      themeColor: Color(0xFF10B981),
      unlockCost: 1500,
      upgradeCost: 2200,
      level1Prestige: 1400,
      level2Prestige: 1800,
      rewardType: RelicRewardType.silver,
      level1HoursPerTick: 2,
      level1RewardAmount: 50,
      level2HoursPerTick: 1,
      level2RewardAmount: 50,
    ),
    RelicData(
      id: 'infinity_crown',
      title: 'Sonsuzluk Tacı',
      description: 'Mahzenin zirvesi, kudretli hükümdarların altın tacı.',
      icon: Icons.workspace_premium_rounded,
      themeColor: Color(0xFFA855F7),
      unlockCost: 3000,
      upgradeCost: 4500,
      level1Prestige: 2200,
      level2Prestige: 2800,
      rewardType: RelicRewardType.gold,
      level1HoursPerTick: 2,
      level1RewardAmount: 3,
      level2HoursPerTick: 1,
      level2RewardAmount: 3,
    ),
  ];
}

class RelicProgress {
  final int level; // 0: Kilitli, 1: Seviye 1, 2: Seviye 2
  final DateTime lastCollectTime;

  RelicProgress({
    required this.level,
    required this.lastCollectTime,
  });

  RelicProgress copyWith({
    int? level,
    DateTime? lastCollectTime,
  }) {
    return RelicProgress(
      level: level ?? this.level,
      lastCollectTime: lastCollectTime ?? this.lastCollectTime,
    );
  }
}