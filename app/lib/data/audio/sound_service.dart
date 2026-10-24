import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Short UI cues plus the real cries from Showdown's audio pack.
///
/// Sounds are fire-and-forget: a failed asset or a missing network connection
/// must never break gameplay.
class SoundService {
  SoundService({
    this.enabled = true,
    this.haptics = true,
    this.musicEnabled = true,
  });

  bool enabled;
  bool haptics;
  bool musicEnabled;

  static const _cueFiles = <String, String>{
    'tap': 'audio/tap.wav',
    'throw': 'audio/throw.wav',
    'wobble': 'audio/wobble.wav',
    'catch': 'audio/catch.wav',
    'fail': 'audio/fail.wav',
    'shiny': 'audio/shiny.wav',
    'levelup': 'audio/levelup.wav',
    'purchase': 'audio/purchase.wav',
    'error': 'audio/error.wav',
  };

  static const _criesBase = 'https://play.pokemonshowdown.com/audio/cries';

  final List<AudioPlayer> _sfx = [];
  final AudioPlayer _cries = AudioPlayer();
  final AudioPlayer _music = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  int _cursor = 0;
  bool _musicStarted = false;

  AudioPlayer _nextPlayer() {
    if (_sfx.length < 4) {
      final player = AudioPlayer();
      _sfx.add(player);
      return player;
    }
    _cursor = (_cursor + 1) % _sfx.length;
    return _sfx[_cursor];
  }

  Future<void> play(String cue, {double volume = 0.7}) async {
    if (!enabled) return;
    final asset = _cueFiles[cue];
    if (asset == null) return;
    try {
      final player = _nextPlayer();
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } on Object {
      // Audio is decorative; ignore platform/asset errors.
    }
  }

  Future<void> cry(String slug, {double volume = 0.6}) async {
    if (!enabled || slug.isEmpty) return;
    try {
      await _cries.stop();
      await _cries.play(UrlSource('$_criesBase/$slug.mp3'), volume: volume);
    } on Object {
      // Cries are optional (offline, unsupported codec on some platforms).
    }
  }

  void tap() {
    play('tap', volume: 0.4);
    if (haptics) HapticFeedback.selectionClick();
  }

  void impact() {
    if (haptics) HapticFeedback.lightImpact();
  }

  void success() {
    play('catch');
    if (haptics) HapticFeedback.mediumImpact();
  }

  void failure() {
    play('fail');
    if (haptics) HapticFeedback.heavyImpact();
  }

  void levelUp() {
    play('levelup');
    if (haptics) HapticFeedback.mediumImpact();
  }

  void shiny() {
    play('shiny');
    if (haptics) HapticFeedback.lightImpact();
  }

  void purchase() {
    play('purchase');
    if (haptics) HapticFeedback.selectionClick();
  }

  void error() {
    play('error');
    if (haptics) HapticFeedback.heavyImpact();
  }

  /// Starts the looping theme if music is enabled. Safe to call repeatedly.
  Future<void> startMusic() async {
    if (!musicEnabled) return;
    if (_musicStarted) return;
    _musicStarted = true;
    try {
      await _music.setVolume(0.22);
      await _music.play(AssetSource('audio/theme.wav'));
    } on Object {
      _musicStarted = false;
    }
  }

  Future<void> pauseMusic() async {
    if (!_musicStarted) return;
    try {
      await _music.pause();
    } on Object {
      // Ignore audio errors.
    }
  }

  Future<void> resumeMusic() async {
    if (!musicEnabled || !_musicStarted) return;
    try {
      await _music.resume();
    } on Object {
      // Ignore audio errors.
    }
  }

  Future<void> setMusic(bool value) async {
    musicEnabled = value;
    if (!value) {
      try {
        await _music.pause();
      } on Object {
        // Ignore audio errors.
      }
      return;
    }
    try {
      if (_musicStarted) {
        await _music.resume();
      } else {
        await startMusic();
      }
    } on Object {
      // Ignore audio errors.
    }
  }

  Future<void> dispose() async {
    for (final player in _sfx) {
      await player.dispose();
    }
    await _cries.dispose();
    await _music.dispose();
  }
}
