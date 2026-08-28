import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Where the alarm screen's audio comes from.
///
/// The tone is bundled in the app rather than read from the system's default-alarm setting: that
/// setting returns nothing when the user has picked "None", and can name a ringtone this app cannot
/// open (one on a removed card, or another profile's) — either of which would leave a reminder
/// silent. A bundled tone always plays.
class AlarmAudio {
  AlarmAudio._();

  static const String _bundledTone = 'sounds/alarm_tone.wav';

  static final AudioPlayer _player = AudioPlayer(playerId: 'nirbhor_alarm');

  /// Starts the looping alarm tone over the alarm audio stream, and vibrates alongside it — the
  /// tone alone is not enough for a phone left on silent.
  static Future<void> start() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.duckOthers},
          ),
        ),
      );
      await _player.setVolume(1);
      await _player.play(AssetSource(_bundledTone));
    } catch (_) {
      // Audio focus can be refused (a call in progress); the vibration below still fires.
    }
    _vibrate();
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Stopping a player that never started is not an error.
    }
  }

  /// Mirrors the reminder channel's vibration pattern (0, 500, 350, 500, 350, 700).
  static Future<void> _vibrate() async {
    for (final gap in const [0, 850, 850]) {
      if (gap > 0) await Future<void>.delayed(Duration(milliseconds: gap));
      await HapticFeedback.heavyImpact();
    }
  }
}
