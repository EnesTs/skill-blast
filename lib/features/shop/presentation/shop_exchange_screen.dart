import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/logic/game_notifier.dart';
import '../../game/logic/game_state.dart';
import 'package:match3/widgets/game_background.dart';

class ShopAndExchangeScreen extends ConsumerStatefulWidget {
  const ShopAndExchangeScreen({super.key});

  @override
  ConsumerState<ShopAndExchangeScreen> createState() =>
      _ShopAndExchangeScreenState();
}

class _ShopAndExchangeScreenState extends ConsumerState<ShopAndExchangeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  double _pointsForGoldSlider = 10000;
  double _pointsForSilverSlider = 5000;
  double _silverForGoldSlider = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GameState gameState = ref.watch(gameProvider);
    final GameNotifier notifier = ref.read(gameProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'MAĞAZA & BORSA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'MAĞAZA'),
            Tab(icon: Icon(Icons.currency_exchange), text: 'BORSA / DÖNÜŞTÜR'),
          ],
        ),
      ),
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              // GÜNCEL BAKİYE TAKİP BARI
              _buildTopLiveBalanceBar(gameState),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildShopTab(context, gameState, notifier),
                    _buildExchangeTab(context, gameState, notifier),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- OYUNCUNUN GÜNCEL VARLIKLARINI TAKİP ETTİĞİ CANLI PANEL ---
  Widget _buildTopLiveBalanceBar(GameState gameState) {
    final int tickets = gameState.totalTickets;
    final int goldCoins = gameState.goldCoins;
    final int silverCoins = gameState.silverCoins;
    final int totalPoints = gameState.totalPoints;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniBalancePill('BİLET', '$tickets', '🎟️', Colors.pinkAccent),
          _buildPillDivider(),
          _buildMiniBalancePill('ALTIN', '$goldCoins', '🪙', Colors.amber),
          _buildPillDivider(),
          _buildMiniBalancePill('GÜMÜŞ', '$silverCoins', '🥈', Colors.grey.shade300),
          _buildPillDivider(),
          _buildMiniBalancePill('PUAN', '$totalPoints', '💎', Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _buildMiniBalancePill(String label, String value, String icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillDivider() {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white10,
    );
  }

  Widget _buildShopTab(BuildContext context, GameState gameState, GameNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. EFSANEVİ PAKETLER VİTRİNİ (HER ZAMAN GÖRÜNÜR)
        _buildLegendaryPackageCard(gameState, notifier),
        const SizedBox(height: 24),

        // 2. BİLET VE HAK SATIŞLARI
        const Text('🎟️ BİLET & HAK SATIŞLARI',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildShopCard(
              title: 'Tekli Bilet',
              amount: '1 Bilet',
              price: '₺25.00',
              icon: '🎟️',
              onTap: () {
                notifier.buyPackage(addTickets: 1);
                _showPurchaseSuccess(context, '1 Bilet');
              },
            ),
            const SizedBox(width: 12),
            _buildShopCard(
              title: 'Maceracı Zulası',
              amount: '5 Bilet',
              price: '₺100.00',
              icon: '🎟️',
              badge: 'POPÜLER',
              onTap: () {
                notifier.buyPackage(addTickets: 5);
                _showPurchaseSuccess(context, '5 Bilet Paket');
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. ALTIN MAĞAZASI
        const Text('🟡 ALTIN MAĞAZASI (ADA & SON SEVİYE SKİLL İÇİN)',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildShopCard(
              title: 'Kese Altın',
              amount: '50 Altın',
              price: '₺30.00',
              icon: '💰',
              onTap: () {
                notifier.buyPackage(addGold: 50);
                _showPurchaseSuccess(context, '50 Altın');
              },
            ),
            const SizedBox(width: 12),
            _buildShopCard(
              title: 'Hazine Sandığı',
              amount: '100 Altın',
              price: '₺50.00',
              icon: '🧰',
              badge: 'KÂRLI',
              onTap: () {
                notifier.buyPackage(addGold: 100);
                _showPurchaseSuccess(context, '100 Altın');
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4. GÜMÜŞ MAĞAZASI
        const Text('⚪ GÜMÜŞ MAĞAZASI (SKİLL YÜKSELTMELERİ İÇİN)',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildShopCard(
              title: 'Gümüş Torbası',
              amount: '500 Gümüş',
              price: '₺50.00',
              icon: '🥈',
              onTap: () {
                notifier.buyPackage(addSilver: 500);
                _showPurchaseSuccess(context, '500 Gümüş');
              },
            ),
            const SizedBox(width: 12),
            _buildShopCard(
              title: 'Gümüş Kasası',
              amount: '1.250 Gümüş',
              price: '₺100.00',
              icon: '🏛️',
              onTap: () {
                notifier.buyPackage(addSilver: 1250);
                _showPurchaseSuccess(context, '1.250 Gümüş');
              },
            ),
          ],
        ),
      ],
    );
  }

  // --- EFSANEVİ PAKET KARTI (KAYBOLMAYAN & MAKS SEVİYE BİLGİLENDİRMELİ) ---
  Widget _buildLegendaryPackageCard(GameState gameState, GameNotifier notifier) {
    final int currentTier = gameState.legendaryPackageTier;
    final bool isMax = currentTier >= 3;

    String title = '';
    String itemsText = '';
    String priceText = '';
    int tickets = 0;
    int gold = 0;
    int silver = 0;

    if (currentTier == 0) {
      title = 'EFSANEVİ BAŞLANGIÇ PAKETİ (1/3)';
      itemsText = '5 Bilet + 50 Altın + 500 Gümüş';
      priceText = '₺150.00';
      tickets = 5;
      gold = 50;
      silver = 500;
    } else if (currentTier == 1) {
      title = 'EFSANEVİ ORTA SEVİYE PAKET (2/3)';
      itemsText = '10 Bilet + 100 Altın + 1.000 Gümüş';
      priceText = '₺270.00';
      tickets = 10;
      gold = 100;
      silver = 1000;
    } else if (currentTier == 2) {
      title = 'EFSANEVİ PREMIUM PAKET (3/3)';
      itemsText = '15 Bilet + 200 Altın + 2.000 Gümüş';
      priceText = '₺450.00';
      tickets = 15;
      gold = 200;
      silver = 2000;
    } else {
      // 3 veya daha büyükse oyuncunun tüm aşamaları tamamladığını gösterir
      title = 'EFSANEVİ PAKETLER';
      itemsText = 'Tüm kademeler tamamlandı! Mahzen ve yeteneklerinde gücünü göster.';
      priceText = 'TAMAMLANDI';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.purple.withValues(alpha: 0.4), blurRadius: 14)
        ],
      ),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Colors.amber)),
                const SizedBox(height: 4),
                Text(itemsText,
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isMax ? Colors.white24 : Colors.amber,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isMax
                ? null
                : () {
                    notifier.buyPackage(addTickets: tickets, addGold: gold, addSilver: silver);
                    notifier.incrementLegendaryTier();
                    _showPurchaseSuccess(context, title);
                  },
            child: Text(
              priceText,
              style: TextStyle(
                color: isMax ? Colors.white54 : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: isMax ? 11 : 14,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExchangeTab(
      BuildContext context, GameState gameState, GameNotifier notifier) {
    final int totalPoints = gameState.totalPoints;
    final int silverCoins = gameState.silverCoins;

    int maxGoldConvertible = totalPoints ~/ 10000;
    int maxSilverConvertible = totalPoints ~/ 5000;
    int maxSilverToGoldConvertible = silverCoins ~/ 5;

    double maxGoldSlider = maxGoldConvertible > 0
        ? (maxGoldConvertible * 10000).toDouble()
        : 10000.0;

    double maxSilverSlider = maxSilverConvertible > 0
        ? (maxSilverConvertible * 5000).toDouble()
        : 5000.0;

    double maxSilverToGoldSlider = maxSilverToGoldConvertible > 0
        ? (maxSilverToGoldConvertible * 5).toDouble()
        : 5.0;

    int goldToGainFromPoints = (_pointsForGoldSlider ~/ 10000);
    int silverToGainFromPoints = (_pointsForSilverSlider ~/ 5000);
    int goldToGainFromSilver = (_silverForGoldSlider ~/ 5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExchangeCard(
            title: 'Gümüş ➔ Altın Borsa',
            rateText: '5 Gümüş = 1 Altın',
            unitLabel: 'Gümüş',
            gainText: '= $goldToGainFromSilver Altın',
            gainColor: Colors.amber,
            sliderValue: _silverForGoldSlider,
            maxSliderValue: maxSilverToGoldSlider,
            divisions: maxSilverToGoldConvertible > 0 ? maxSilverToGoldConvertible : 1,
            onChanged: maxSilverToGoldConvertible > 0
                ? (val) {
                    setState(() {
                      _silverForGoldSlider = (val ~/ 5) * 5.0;
                    });
                  }
                : null,
            onConvertPressed: silverCoins >= 5 && goldToGainFromSilver > 0
                ? () {
                    int silverToSpend = _silverForGoldSlider.toInt();
                    int goldToGain = silverToSpend ~/ 5;
                    notifier.deductSilver(silverToSpend);
                    notifier.addGold(goldToGain);
                    if (context.mounted) {
                      _showPurchaseSuccess(context, '$goldToGain Altın Dönüştürüldü');
                      setState(() {
                        _silverForGoldSlider = 5;
                      });
                    }
                  }
                : null,
          ),

          const SizedBox(height: 20),

          _buildExchangeCard(
            title: 'Puan ➔ Altın Borsa',
            rateText: '10.000 Puan = 1 Altın',
            unitLabel: 'Puan',
            gainText: '= $goldToGainFromPoints Altın',
            gainColor: Colors.amber,
            sliderValue: _pointsForGoldSlider,
            maxSliderValue: maxGoldSlider,
            divisions: maxGoldConvertible > 0 ? maxGoldConvertible : 1,
            onChanged: maxGoldConvertible > 0
                ? (val) {
                    setState(() {
                      _pointsForGoldSlider = (val ~/ 10000) * 10000.0;
                    });
                  }
                : null,
            onConvertPressed: totalPoints >= 10000 && goldToGainFromPoints > 0
                ? () {
                    bool success = notifier.convertCustomPointsToGold(
                        _pointsForGoldSlider.toInt());
                    if (success && context.mounted) {
                      _showPurchaseSuccess(context, '$goldToGainFromPoints Altın Dönüştürüldü');
                    }
                  }
                : null,
          ),

          const SizedBox(height: 20),

          _buildExchangeCard(
            title: 'Puan ➔ Gümüş Borsa',
            rateText: '5.000 Puan = 1 Gümüş',
            unitLabel: 'Puan',
            gainText: '= $silverToGainFromPoints Gümüş',
            gainColor: Colors.grey.shade300,
            sliderValue: _pointsForSilverSlider,
            maxSliderValue: maxSilverSlider,
            divisions: maxSilverConvertible > 0 ? maxSilverConvertible : 1,
            onChanged: maxSilverConvertible > 0
                ? (val) {
                    setState(() {
                      _pointsForSilverSlider = (val ~/ 5000) * 5000.0;
                    });
                  }
                : null,
            onConvertPressed: totalPoints >= 5000 && silverToGainFromPoints > 0
                ? () {
                    bool success = notifier.convertCustomPointsToSilver(
                        _pointsForSilverSlider.toInt());
                    if (success && context.mounted) {
                      _showPurchaseSuccess(context, '$silverToGainFromPoints Gümüş Dönüştürüldü');
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard({
    required String title,
    required String amount,
    required String price,
    required String icon,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(amount,
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onTap();
                  },
                  child: Text(price,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                      color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExchangeCard({
    required String title,
    required String rateText,
    required String unitLabel,
    required String gainText,
    required Color gainColor,
    required double sliderValue,
    required double maxSliderValue,
    required int divisions,
    required ValueChanged<double>? onChanged,
    required VoidCallback? onConvertPressed,
  }) {
    double safeSliderValue = sliderValue.clamp(0.0, maxSliderValue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(rateText,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${safeSliderValue.toInt()} $unitLabel',
                  style: const TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              Text(gainText,
                  style: TextStyle(
                      color: gainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          Slider(
            value: safeSliderValue,
            min: 0,
            max: maxSliderValue,
            divisions: divisions > 0 ? divisions : 1,
            activeColor: gainColor,
            onChanged: onChanged,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gainColor,
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onConvertPressed,
              child: const Text('DÖNÜŞTÜRMEYİ ONAYLA',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }

  void _showPurchaseSuccess(BuildContext context, String itemName) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName başarıyla alındı!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}