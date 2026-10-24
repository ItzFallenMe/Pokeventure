import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/sound_service.dart';
import '../data/local/key_value_store.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.dynamicColor = false,
    this.animations = true,
    this.accent = 'indigo',
    this.avatar = 'explorer',
    this.title = 'Rookie',
  });

  final ThemeMode themeMode;
  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;

  /// Material You wallpapers on Android 12+. Off by default so the game keeps
  /// its identity; type colours never follow the wallpaper.
  final bool dynamicColor;

  final bool animations;

  /// Accent palette slug (see `AppTheme.accents`).
  final String accent;
  final String avatar;
  final String title;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    bool? dynamicColor,
    bool? animations,
    String? accent,
    String? avatar,
    String? title,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      dynamicColor: dynamicColor ?? this.dynamicColor,
      animations: animations ?? this.animations,
      accent: accent ?? this.accent,
      avatar: avatar ?? this.avatar,
      title: title ?? this.title,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _themeKey = 'theme_mode';
  static const _soundKey = 'sound_enabled';
  static const _musicKey = 'music_enabled';
  static const _hapticsKey = 'haptics_enabled';
  static const _dynamicKey = 'dynamic_color';
  static const _animationsKey = 'animations_enabled';
  static const _accentKey = 'accent_palette';
  static const _avatarKey = 'trainer_avatar';
  static const _titleKey = 'trainer_title';

  KeyValueStore get _store => ref.read(storeProvider);

  @override
  AppSettings build() {
    final store = _store;
    return AppSettings(
      themeMode: switch (store.read(_themeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      soundEnabled: store.read(_soundKey) != 'false',
      musicEnabled: store.read(_musicKey) != 'false',
      hapticsEnabled: store.read(_hapticsKey) != 'false',
      dynamicColor: store.read(_dynamicKey) == 'true',
      animations: store.read(_animationsKey) != 'false',
      accent: store.read(_accentKey) ?? 'indigo',
      avatar: store.read(_avatarKey) ?? 'explorer',
      title: store.read(_titleKey) ?? 'Rookie',
    );
  }

  void select(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    unawaited(_store.write(_themeKey, mode.name));
  }

  void setSound(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    unawaited(_store.write(_soundKey, '$enabled'));
  }

  void setMusic(bool enabled) {
    state = state.copyWith(musicEnabled: enabled);
    unawaited(_store.write(_musicKey, '$enabled'));
    ref.read(soundServiceProvider).setMusic(enabled);
  }

  void setHaptics(bool enabled) {
    state = state.copyWith(hapticsEnabled: enabled);
    unawaited(_store.write(_hapticsKey, '$enabled'));
  }

  void setDynamicColor(bool enabled) {
    state = state.copyWith(dynamicColor: enabled);
    unawaited(_store.write(_dynamicKey, '$enabled'));
  }

  void setAnimations(bool enabled) {
    state = state.copyWith(animations: enabled);
    unawaited(_store.write(_animationsKey, '$enabled'));
  }

  void setAccent(String slug) {
    state = state.copyWith(accent: slug);
    unawaited(_store.write(_accentKey, slug));
  }

  void setAvatar(String slug) {
    state = state.copyWith(avatar: slug);
    unawaited(_store.write(_avatarKey, slug));
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
    unawaited(_store.write(_titleKey, title));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Kept for screens that only need the theme mode.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// The shared audio player, wired to the sound and haptics settings.
final soundServiceProvider = Provider<SoundService>((ref) {
  final settings = ref.read(settingsProvider);
  final service = SoundService(
    enabled: settings.soundEnabled,
    haptics: settings.hapticsEnabled,
    musicEnabled: settings.musicEnabled,
  );
  ref.listen(settingsProvider, (_, next) {
    service
      ..enabled = next.soundEnabled
      ..haptics = next.hapticsEnabled;
    if (service.musicEnabled != next.musicEnabled) {
      service.setMusic(next.musicEnabled);
    }
  });
  ref.onDispose(service.dispose);
  return service;
});
