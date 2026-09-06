import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static AudioPool? _matchPool;
  static AudioPool? _skillPool;

  static Future<void> initialize() async {
    try {
      FlameAudio.bgm.initialize();

      // Sesleri belleğe yükleyip hazır havuzlar (pool) oluşturuyoruz
      _matchPool = await FlameAudio.createPool(
        'match.mp3',
        minPlayers: 3,
        maxPlayers: 5,
      );

      _skillPool = await FlameAudio.createPool(
        'skill.mp3',
        minPlayers: 2,
        maxPlayers: 4,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ses havuzları oluşturulurken hata oluştu: $e');
      }
    }
  }

  /// Kutu patlama / eşleşme sesi
  static void playMatch() {
    _playFromPool(_matchPool);
  }

  /// Skill / Özel güç kullanma sesi
  static void playSkill() {
    _playFromPool(_skillPool);
  }

  static void _playFromPool(AudioPool? pool) {
    try {
      if (pool != null) {
        pool.start(volume: 0.8);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ses çalınırken hata oluştu: $e');
      }
    }
  }
}