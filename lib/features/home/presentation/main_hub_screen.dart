import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3/features/game/logic/game_notifier.dart';
import 'package:match3/features/game/presentation/game_screen.dart';
import 'package:match3/features/shop/presentation/shop_exchange_screen.dart';
import 'package:match3/features/skills/presentation/skill_tree_screen.dart';
import 'package:match3/features/vault/logic/vault_notifier.dart';
import 'package:match3/features/vault/views/vault_screen.dart';
import 'package:match3/features/home/presentation/widgets/fortune_games_modal.dart';
import 'package:match3/features/home/presentation/widgets/daily_reward_modal.dart';
import 'package:match3/widgets/game_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sparkleController;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _tickerTimer?.cancel();
    super.dispose();
  }

  String _getRemainingTimeString(DateTime? nextTicketTime) {
    if (nextTicketTime == null) return 'Dolu (5/5)';
    final diff = nextTicketTime.difference(DateTime.now());
    if (diff.isNegative) return '00:00:00';

    int hours = diff.inHours;
    int minutes = diff.inMinutes % 60;
    int seconds = diff.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showLeaderboardComingSoonModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text(
              'Savaş Ligleri',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Haftalık ligler ve sıralama yarışları çok yakında açılıyor!\n\nŞimdiden Kadim Hazine Mahzenindeki emanetleri açarak prestijini artır, lig basamaklarını tırman ve ilk sezona damganı vur!',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anlaşıldı!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final vaultState = ref.watch(vaultProvider);
    final totalTickets = gameState.regenTickets + gameState.bonusTickets;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTicketBadge(
                        regenTickets: gameState.regenTickets,
                        bonusTickets: gameState.bonusTickets,
                        nextTicketTime: gameState.nextTicketTime,
                      ),
                      const SizedBox(width: 6),
                      _buildResourceBadge(Icons.stars, '${gameState.totalPoints}', Colors.cyanAccent),
                      const SizedBox(width: 6),
                      _buildResourceBadge(Icons.monetization_on, '${gameState.goldCoins}', Colors.amber),
                      const SizedBox(width: 6),
                      _buildResourceBadge(Icons.monetization_on_outlined, '${gameState.silverCoins}', Colors.grey.shade300),
                      const SizedBox(width: 6),
                      _buildResourceBadge(Icons.military_tech_rounded, '${vaultState.totalPrestige} P (${vaultState.leagueName})', Colors.purpleAccent),
                    ],
                  ),
                ),
                const Spacer(),

                Column(
                  children: [
                    // --- OYUN İKONU / LOGO ---
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 3,
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/app_icon.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- OYUN ADI ---
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.amberAccent, Colors.orangeAccent, Colors.redAccent],
                      ).createShader(bounds),
                      child: const Text(
                        'SKILL BLAST',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Text(
                      'MATCH 3 & PUZZLE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeatureCard(
                            emoji: '🎡',
                            title: 'Çark',
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              showFortuneGamesModal(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFeatureCard(
                            emoji: '🎁',
                            title: 'Ödüller',
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              showDailyRewardModal(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFeatureCard(
                            emoji: '🏆',
                            title: 'Sıralama',
                            badgeText: 'YAKINDA',
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _showLeaderboardComingSoonModal(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();

                    if (totalTickets > 0) {
                      bool success = ref.read(gameProvider.notifier).useTicket(); 

                      if (success) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GameScreen()),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yeterli biletin yok! Mağazadan satın alabilir veya sürenin dolmasını bekleyebilirsin.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orangeAccent, Colors.redAccent],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.black, size: 34),
                        SizedBox(width: 6),
                        Text(
                          'OYUNA BAŞLA',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildMenuButton(
                        title: 'Skill Ağacı',
                        icon: '⚡',
                        color: Colors.purpleAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SkillTreeScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMenuButton(
                        title: 'Mağaza',
                        icon: '🛒',
                        color: Colors.greenAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ShopAndExchangeScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMenuButton(
                        title: 'Mahzen',
                        icon: '🏛️',
                        color: Colors.amberAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VaultScreen()),
                          );
                        },
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
    );
  }

  Widget _buildFeatureCard({
    required String emoji,
    required String title,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketBadge({
    required int regenTickets,
    required int bonusTickets,
    required DateTime? nextTicketTime,
  }) {
    final bool isFull = regenTickets >= 5;
    final int totalTickets = regenTickets + bonusTickets;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎟️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '$totalTickets',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  if (bonusTickets > 0)
                    Text(
                      ' (+$bonusTickets)',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              Text(
                isFull ? 'Dolu (5/5)' : _getRemainingTimeString(nextTicketTime),
                style: TextStyle(
                  color: isFull ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopAndExchangeScreen()),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.greenAccent.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}