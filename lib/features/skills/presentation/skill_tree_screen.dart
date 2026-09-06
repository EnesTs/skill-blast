import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/skill_tree_notifier.dart';
import '../models/skill_node_model.dart';
import 'package:match3/features/game/logic/game_notifier.dart';
import 'package:match3/widgets/game_background.dart';

class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(skillTreeProvider);
    final gameState = ref.watch(gameProvider);

    final activeSkills = skills.where((s) => s.category == SkillCategory.active).toList();
    final passiveSkills = skills.where((s) => s.category == SkillCategory.passive).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Geliştirme Merkezi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Yetenekler (Aktif)'),
              Tab(text: 'Genel (Pasif)'),
            ],
          ),
        ),
        body: GameBackground(
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.grey, size: 20),
                          const SizedBox(width: 6),
                          Text('${gameState.silverCoins} Gümüş',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(height: 16, width: 1, color: Colors.white24),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                          const SizedBox(width: 6),
                          Text('${gameState.goldCoins} Altın',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSkillList(context, ref, activeSkills),
                      _buildSkillList(context, ref, passiveSkills),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillList(BuildContext context, WidgetRef ref, List<SkillNodeModel> list) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final skill = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () => _showSkillDetailsBottomSheet(context, ref, skill),
            child: _buildSkillCard(skill),
          ),
        );
      },
    );
  }

  Widget _buildSkillCard(SkillNodeModel skill) {
    final Color skillColor = _getSkillColor(skill.type);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: skill.isMaxed ? Colors.amber : skillColor.withValues(alpha: 0.6),
          width: skill.isMaxed ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: skillColor.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: skillColor.withValues(alpha: 0.2),
            child: Icon(_getSkillIcon(skill.type), color: skillColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  skill.currentLevel > 0 
                      ? 'Aktif Etki: ${skill.currentEffectDescription}' 
                      : skill.description,
                  style: TextStyle(
                    color: skill.currentLevel > 0 ? Colors.greenAccent : Colors.white70,
                    fontSize: 12,
                    fontWeight: skill.currentLevel > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
            child: Text(
              'Lvl ${skill.currentLevel}/${skill.maxLevel}',
              style: TextStyle(
                color: skill.isMaxed ? Colors.amber : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSkillDetailsBottomSheet(BuildContext context, WidgetRef ref, SkillNodeModel skill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentSkills = ref.watch(skillTreeProvider);
            final updatedSkill = currentSkills.firstWhere((s) => s.id == skill.id);
            final gameState = ref.watch(gameProvider);

            final nextUpgrade = updatedSkill.nextUpgrade;
            bool canAfford = false;

            if (nextUpgrade != null) {
              canAfford = nextUpgrade.requiresGold
                  ? gameState.goldCoins >= nextUpgrade.goldCost
                  : gameState.silverCoins >= nextUpgrade.silverCost;
            }

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(updatedSkill.title,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),

                  Column(
                    children: updatedSkill.subUpgrades.map((sub) {
                      final isUnlockedStep = updatedSkill.currentLevel >= sub.level;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlockedStep ? Colors.indigoAccent.withValues(alpha: 0.2) : Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sub.requiresGold ? Colors.amber : Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUnlockedStep ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isUnlockedStep
                                  ? Colors.greenAccent
                                  : (sub.requiresGold ? Colors.amber : Colors.white38),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(sub.effectDescription,
                                  style: const TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                            Row(
                              children: [
                                Icon(Icons.monetization_on,
                                    size: 14, color: sub.requiresGold ? Colors.amber : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  sub.requiresGold ? '${sub.goldCost} Altın' : '${sub.silverCost} Gümüş',
                                  style: TextStyle(
                                    color: sub.requiresGold ? Colors.amber : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: updatedSkill.isMaxed
                            ? Colors.grey.shade800
                            : (nextUpgrade?.requiresGold ?? false ? Colors.amber : Colors.indigoAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (updatedSkill.isMaxed || !canAfford)
                          ? null
                          : () async {
                              if (nextUpgrade!.requiresGold) {
                                ref.read(gameProvider.notifier).deductGold(nextUpgrade.goldCost);
                              } else {
                                ref.read(gameProvider.notifier).deductSilver(nextUpgrade.silverCost);
                              }
                              await ref
                                  .read(skillTreeProvider.notifier)
                                  .upgradeSkill(updatedSkill.id);
                            },
                      child: Text(
                        updatedSkill.isMaxed
                            ? 'Maksimum Seviyede'
                            : (nextUpgrade!.requiresGold
                                ? 'Yükselt (${nextUpgrade.goldCost} Altın)'
                                : 'Yükselt (${nextUpgrade.silverCost} Gümüş)'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getSkillColor(SkillType type) {
    switch (type) {
      case SkillType.blueMoves:
        return Colors.blueAccent;
      case SkillType.redExplosion:
        return Colors.redAccent;
      case SkillType.greenTransform:
        return Colors.greenAccent;
      case SkillType.yellowMultiplier:
        return Colors.amber;
      case SkillType.purpleDoubleClear:
        return Colors.purpleAccent;
      case SkillType.passiveBoxScore:
        return Colors.orangeAccent;
      case SkillType.passiveStartMoves:
        return Colors.tealAccent;
      case SkillType.passiveLastChance:
        return Colors.pinkAccent;
      case SkillType.passiveComboBonus:
        return Colors.amberAccent;
    }
  }

  IconData _getSkillIcon(SkillType type) {
    switch (type) {
      case SkillType.blueMoves:
        return Icons.add_circle_outline;
      case SkillType.redExplosion:
        return Icons.local_fire_department;
      case SkillType.greenTransform:
        return Icons.color_lens;
      case SkillType.yellowMultiplier:
        return Icons.offline_bolt;
      case SkillType.purpleDoubleClear:
        return Icons.auto_awesome;
      case SkillType.passiveBoxScore:
        return Icons.inventory_2;
      case SkillType.passiveStartMoves:
        return Icons.play_circle_fill;
      case SkillType.passiveLastChance:
        return Icons.replay_circle_filled;
      case SkillType.passiveComboBonus:
        return Icons.stars;
    }
  }
}