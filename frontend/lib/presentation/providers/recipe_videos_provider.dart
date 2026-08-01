import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores multiple video links per recipe on the device.
class RecipeVideosNotifier extends Notifier<Map<String, List<String>>> {
  static const _prefsKey = 'recipe_video_links_v1';

  @override
  Map<String, List<String>> build() {
    _load();
    return {};
  }

  List<String> videosFor(String recipeId) => state[recipeId] ?? const [];

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = decoded.map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      );
    } catch (_) {}
  }

  Future<void> addVideo(String recipeId, String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final updated = Map<String, List<String>>.from(state);
    final current = List<String>.from(updated[recipeId] ?? []);
    if (current.contains(trimmed)) return;
    updated[recipeId] = [...current, trimmed];
    state = updated;
    await _persist(updated);
  }

  Future<void> removeVideo(String recipeId, int index) async {
    final current = state[recipeId] ?? [];
    if (index < 0 || index >= current.length) return;
    final updated = Map<String, List<String>>.from(state);
    final list = List<String>.from(current)..removeAt(index);
    updated[recipeId] = list;
    state = updated;
    await _persist(updated);
  }

  Future<void> _persist(Map<String, List<String>> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (_) {}
  }
}

final recipeVideosProvider =
    NotifierProvider<RecipeVideosNotifier, Map<String, List<String>>>(RecipeVideosNotifier.new);
