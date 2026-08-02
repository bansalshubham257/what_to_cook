import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide appearance & language settings, persisted in [SharedPreferences].
class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;
  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.locale = const Locale('en'),
  });

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale}) => AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString(_themeKey) == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
      final code = prefs.getString(_languageKey) ?? 'en';
      final locale = code.isEmpty ? const Locale('en') : Locale(code);
      state = AppSettings(themeMode: mode, locale: locale);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
    } catch (_) {}
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
