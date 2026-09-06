import 'package:shared_preferences/shared_preferences.dart';

class TicketService {
  static const int maxStandardTickets = 5;
  static const Duration regenInterval = Duration(hours: 6);

  int standardTickets = maxStandardTickets;
  int bonusTickets = 0;
  DateTime? lastRegenTime;

  int get totalTickets => standardTickets + bonusTickets;

  Future<void> loadTicketData() async {
    final prefs = await SharedPreferences.getInstance();
    standardTickets = prefs.getInt('standardTickets') ?? maxStandardTickets;
    bonusTickets = prefs.getInt('bonusTickets') ?? 0;
    
    final lastRegenString = prefs.getString('lastRegenTime');
    if (lastRegenString != null) {
      lastRegenTime = DateTime.parse(lastRegenString);
    } else {
      lastRegenTime = DateTime.now();
    }

    _calculateOfflineRegen();
  }

  void _calculateOfflineRegen() {
    if (standardTickets >= maxStandardTickets || lastRegenTime == null) return;

    final now = DateTime.now();
    final difference = now.difference(lastRegenTime!);
    
    // Kaç adet 6 saatlik periyot geçti?
    final ticketsToAdd = difference.inSeconds ~/ regenInterval.inSeconds;

    if (ticketsToAdd > 0) {
      standardTickets += ticketsToAdd;
      if (standardTickets >= maxStandardTickets) {
        standardTickets = maxStandardTickets;
        lastRegenTime = now;
      } else {
        // Kalan süreyi koruyarak son yenilenme zamanını güncelle
        final remainderSeconds = difference.inSeconds % regenInterval.inSeconds;
        lastRegenTime = now.subtract(Duration(seconds: remainderSeconds));
      }
      _saveData();
    }
  }

  Future<bool> useTicket() async {
    if (totalTickets <= 0) return false;

    // Öncelik Standart Bilet'te
    if (standardTickets > 0) {
      if (standardTickets == maxStandardTickets) {
        // İlk bilet harcandığında 6 saatlik sayaç başlar
        lastRegenTime = DateTime.now();
      }
      standardTickets--;
    } else if (bonusTickets > 0) {
      bonusTickets--;
    }

    await _saveData();
    return true;
  }

  void addBonusTickets(int amount) {
    bonusTickets += amount;
    _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('standardTickets', standardTickets);
    await prefs.setInt('bonusTickets', bonusTickets);
    if (lastRegenTime != null) {
      await prefs.setString('lastRegenTime', lastRegenTime!.toIso8601String());
    }
  }
}