import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum SoundType { click, success, error, complete }

class SoundService {
  static final SoundService _instance = SoundService._internal();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;

  factory SoundService() {
    return _instance;
  }

  SoundService._internal();

  bool get isSoundEnabled => _soundEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  Future<void> playSound(SoundType type) async {
    if (!_soundEnabled) return;

    String soundPath;

    switch (type) {
      case SoundType.click:
        soundPath = 'sounds/click.mp3';
        break;
      case SoundType.success:
        soundPath = 'sounds/success.mp3';
        break;
      case SoundType.error:
        soundPath = 'sounds/error.mp3';
        break;
      case SoundType.complete:
        soundPath = 'sounds/complete.mp3';
        break;
    }

    try {
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
