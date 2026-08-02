import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists dishes the user chose to hide (per category) so they stop showing
/// up in category screens. Local user-added dishes are removed instead via
/// [LocalDishesNotifier.removeDish].
class HiddenDishesNotifier extends Notifier<Map<String, Set<String>>> {
  static const _prefsKey = 'category_hidden_dishes_v1';

  @override
  Map<String, Set<String>> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = <String, Set<String>>{};
      decoded.forEach((slug, list) {
        map[slug] = (list as List).map((e) => e.toString()).toSet();
      });
      state = map;
    } catch (_) {}
  }

  Set<String> hiddenFor(String categorySlug) =>
      state[categorySlug] ?? const {};

  Future<void> hideDish(String categorySlug, String dishName) async {
    final updated = Map<String, Set<String>>.from(state);
    updated[categorySlug] = {...(updated[categorySlug] ?? {}), dishName};
    state = updated;
    await _persist(updated);
  }

  Future<void> unhideDish(String categorySlug, String dishName) async {
    final updated = Map<String, Set<String>>.from(state);
    updated[categorySlug] =
        {...(updated[categorySlug] ?? {})}..remove(dishName);
    state = updated;
    await _persist(updated);
  }

  Future<void> _persist(Map<String, Set<String>> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(map.map(
          (k, v) => MapEntry(k, v.toList())));
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {}
  }
}

final hiddenDishesProvider =
    NotifierProvider<HiddenDishesNotifier, Map<String, Set<String>>>(
        HiddenDishesNotifier.new);
