import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3/features/game/logic/game_notifier.dart';

void showDailyRewardModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const DailyRewardModal(),
  );
}

class DailyRewardModal extends ConsumerWidget {
  const DailyRewardModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    final rewards = [
      {'day': 1, 'title': '100 Gümüş', 'icon': '🥈'},
      {'day': 2, 'title': '1 Bilet', 'icon': '🎟️'},
      {'day': 3, 'title': '200 Gümüş', 'icon': '🥈'},
      {'day': 4, 'title': '20 Altın', 'icon': '🥇'},
      {'day': 5, 'title': '2 Bilet', 'icon': '🎟️'},
      {'day': 6, 'title': '400 Gümüş', 'icon': '🥈'},
      {'day': 7, 'title': '2 Bilet\n200 Gümüş\n50 Altın', 'icon': '🎁'},
      {'day': 8, 'title': '500 Gümüş', 'icon': '🥈'},
      {'day': 9, 'title': '3 Bilet', 'icon': '🎟️'},
      {'day': 10, 'title': '40 Altın', 'icon': '🥇'},
      {'day': 11, 'title': '750 Gümüş', 'icon': '🥈'},
      {'day': 12, 'title': '4 Bilet', 'icon': '🎟️'},
      {'day': 13, 'title': '75 Altın', 'icon': '🥇'},
      {'day': 14, 'title': '1000 Gümüş', 'icon': '🥈'},
      {'day': 15, 'title': '5 Bilet\n500 Gümüş\n150 Altın', 'icon': '👑'},
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '15 GÜNLÜK ÖDÜL SERİSİ',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Her gün giriş yap, ödülleri katlayarak topla!',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: 15,
                itemBuilder: (context, index) {
                  int day = index + 1;
                  bool isCurrentDay = gameState.dailyRewardDay == day;
                  bool isClaimed = day < gameState.dailyRewardDay;

                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isCurrentDay
                          ? Colors.amber.withOpacity(0.2)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentDay
                            ? Colors.amber
                            : (isClaimed ? Colors.green : Colors.white12),
                        width: isCurrentDay ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Gün $day',
                          style: TextStyle(
                            color: isCurrentDay ? Colors.amber : Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rewards[index]['icon'].toString(),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rewards[index]['title'].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isClaimed) ...[
                          const SizedBox(height: 2),
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 10),
                        ]
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gameState.isDailyRewardClaimable
                    ? Colors.amber
                    : Colors.grey.shade700,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: gameState.isDailyRewardClaimable
                  ? () {
                      HapticFeedback.heavyImpact();
                      bool success = notifier.claimDailyReward();
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tebrikler! Ödülün hesabına eklendi.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  : null,
              child: Text(
                gameState.isDailyRewardClaimable
                    ? 'ÖDÜLÜ AL'
                    : 'BUGÜNKÜ ÖDÜL ALINDI',
                style: TextStyle(
                  color: gameState.isDailyRewardClaimable
                      ? Colors.black
                      : Colors.white38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}