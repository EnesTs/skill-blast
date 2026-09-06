import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skill_node_model.dart';

final skillTreeProvider =
    StateNotifierProvider<SkillTreeNotifier, List<SkillNodeModel>>((ref) {
  return SkillTreeNotifier();
});

class SkillTreeNotifier extends StateNotifier<List<SkillNodeModel>> {
  SkillTreeNotifier() : super([]) {
    _initSkills();
  }

  Future<void> _initSkills() async {
    final prefs = await SharedPreferences.getInstance();

    final defaultSkills = [
      // --- AKTİF YETENEKLER ---
      
      // 1. MAVİ YETENEK
      const SkillNodeModel(
        id: 'blue_moves',
        title: 'Mavi Yetenek: Hak Takviyesi',
        description: 'Oyuna doğrudan ek hamle kazandırır ve mavi çubuk yeteneğini güçlendirir.',
        type: SkillType.blueMoves,
        category: SkillCategory.active,
        maxLevel: 3,
        subUpgrades: [
          SkillSubUpgrade(level: 1, silverCost: 150, effectDescription: 'Aktifleşince +4 Hamle verir (Taban: +3)'),
          SkillSubUpgrade(level: 2, silverCost: 350, effectDescription: 'Aktifleşince +5 Hamle verir'),
          SkillSubUpgrade(level: 3, goldCost: 50, effectDescription: 'MAX: Aktifleşince +7 Hamle verir'),
        ],
      ),

      // 2. KIRMIZI YETENEK
      const SkillNodeModel(
        id: 'red_explosion',
        title: 'Kırmızı Yetenek: Bomba',
        description: 'Seçilen alan ve etrafındaki taşları yok eder.',
        type: SkillType.redExplosion,
        category: SkillCategory.active,
        maxLevel: 3,
        subUpgrades: [
          SkillSubUpgrade(level: 1, silverCost: 200, effectDescription: '4x4 Alanı Patlatır (Taban: 3x3)'),
          SkillSubUpgrade(level: 2, silverCost: 450, effectDescription: '5x5 Alanı Patlatır'),
          SkillSubUpgrade(level: 3, goldCost: 75, effectDescription: 'MAX: 6x6 Devasa Alanı Patlatır'),
        ],
      ),

      // 3. YEŞİL YETENEK
      const SkillNodeModel(
        id: 'green_transform',
        title: 'Yeşil Yetenek: Renk Dönüştürücü',
        description: 'Tahtadaki taşları hedef renge dönüştürür.',
        type: SkillType.greenTransform,
        category: SkillCategory.active,
        maxLevel: 3,
        subUpgrades: [
          SkillSubUpgrade(level: 1, silverCost: 180, effectDescription: 'Rastgele 6 Taşı Çevirir (Taban: 5 Taş)'),
          SkillSubUpgrade(level: 2, silverCost: 400, effectDescription: 'Rastgele 7 Taşı Çevirir'),
          SkillSubUpgrade(level: 3, goldCost: 60, effectDescription: 'MAX: Rastgele 10 Taşı Seçilen Renge Çevirir'),
        ],
      ),

      // 4. SARI YETENEK
      const SkillNodeModel(
        id: 'yellow_multiplier',
        title: 'Sarı Yetenek: Skor Çarpanı',
        description: 'Belirli hamle boyunca kazanılan puanı katlar.',
        type: SkillType.yellowMultiplier,
        category: SkillCategory.active,
        maxLevel: 3,
        subUpgrades: [
          SkillSubUpgrade(level: 1, silverCost: 250, effectDescription: '3 Hamle Boyunca x3 Puan (Taban: x2)'),
          SkillSubUpgrade(level: 2, silverCost: 500, effectDescription: '3 Hamle Boyunca x4 Puan'),
          SkillSubUpgrade(level: 3, goldCost: 80, effectDescription: 'MAX: 3 Hamle Boyunca x5 Puan'),
        ],
      ),

      // 5. MOR YETENEK
      const SkillNodeModel(
        id: 'purple_double_clear',
        title: 'Mor Yetenek: Çifte Temizlik',
        description: 'Seçilen rengi tahtadan iki kez peş peşe temizler.',
        type: SkillType.purpleDoubleClear,
        category: SkillCategory.active,
        maxLevel: 1,
        subUpgrades: [
          SkillSubUpgrade(level: 1, goldCost: 120, effectDescription: 'Açılış: Tüm tahtadaki 1 rengi yok eder'),
        ],
      ),

      // --- GENEL PASİF YÜKSELTMELER ---
      
      // 6. KUTU SKOR BONUSU
      const SkillNodeModel(
        id: 'passive_box_score',
        title: 'Kutu Bonusu',
        description: 'Patlatılan taşlardan gelen taban skoru artırır.',
        type: SkillType.passiveBoxScore,
        category: SkillCategory.passive,
        maxLevel: 3,
        subUpgrades: [
          SkillSubUpgrade(level: 1, silverCost: 100, effectDescription: 'Eşleşmelerden %10 Daha Fazla Puan'),
          SkillSubUpgrade(level: 2, silverCost: 250, effectDescription: 'Eşleşmelerden %20 Daha Fazla Puan'),
          SkillSubUpgrade(level: 3, goldCost: 40, effectDescription: 'MAX: Eşleşmelerden %35 Daha Fazla Puan'),
        ],
      ),

      // 7. BAŞLANGIÇ HAMLE YÜKSELTME
      const SkillNodeModel(
        id: 'passive_start_moves',
        title: 'Ekstra Başlangıç Hamlesi',
        description: 'Her levele başlarken ekstra hamle hakkı verir.',
        type: SkillType.passiveStartMoves,
        category: SkillCategory.passive,
        maxLevel: 1,
        subUpgrades: [
          SkillSubUpgrade(level: 1, goldCost: 100, effectDescription: 'Her bölüme direkt +5 Ekstra Hamle ile Başla'),
        ],
      ),

      // 8. SON ŞANS
      const SkillNodeModel(
        id: 'passive_last_chance',
        title: 'Son Şans',
        description: 'Hamlen bittiğinde pes etme! Belirli bir şansla oyuna anında +3 hamle kazandırır.',
        type: SkillType.passiveLastChance,
        category: SkillCategory.passive,
        maxLevel: 3,
        subUpgrades: [
          SkillSubUpgrade(level: 1, silverCost: 200, effectDescription: 'Hamle bitince %20 İhtimalle +3 Hamle'),
          SkillSubUpgrade(level: 2, silverCost: 450, effectDescription: 'Hamle bitince %40 İhtimalle +3 Hamle'),
          SkillSubUpgrade(level: 3, goldCost: 80, effectDescription: 'MAX: Hamle bitince %60 İhtimalle +3 Hamle'),
        ],
      ),

      // 9. KOMBO USTASI
      const SkillNodeModel(
        id: 'passive_combo_bonus',
        title: 'Kombo Ustası',
        description: 'Çoklu eşleştirmelerde ekstra şarj ve puan kazandırır.',
        type: SkillType.passiveComboBonus,
        category: SkillCategory.passive,
        maxLevel: 3,
        subUpgrades: [
          SkillSubUpgrade(level: 1, silverCost: 150, effectDescription: 'Yetenek barları %20 daha hızlı şarj olur'),
          SkillSubUpgrade(level: 2, silverCost: 300, effectDescription: 'Yetenek barları %40 daha hızlı şarj olur'),
          SkillSubUpgrade(level: 3, goldCost: 50, effectDescription: 'MAX: Yetenek barları %60 daha hızlı şarj olur'),
        ],
      ),
    ];

    state = defaultSkills.map((skill) {
      final savedLevel = prefs.getInt('skill_${skill.id}') ?? 0;
      return skill.copyWith(currentLevel: savedLevel);
    }).toList();
  }

  Future<void> upgradeSkill(String skillId) async {
    final prefs = await SharedPreferences.getInstance();

    state = [
      for (final skill in state)
        if (skill.id == skillId && !skill.isMaxed) ...[
          () {
            final updatedSkill = skill.copyWith(currentLevel: skill.currentLevel + 1);
            prefs.setInt('skill_${updatedSkill.id}', updatedSkill.currentLevel);
            return updatedSkill;
          }()
        ] else
          skill,
    ];
  }
}