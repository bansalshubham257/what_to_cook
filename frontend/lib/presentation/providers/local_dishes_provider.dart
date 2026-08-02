import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/category_catalog.dart';

/// Persists user-added dishes per category on the device so each category can
/// grow beyond the app's curated dishes and the database dishes.
class LocalDishesNotifier extends Notifier<Map<String, List<CategoryDish>>> {
  static const _prefsKey = 'category_local_dishes_v1';

  @override
  Map<String, List<CategoryDish>> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = <String, List<CategoryDish>>{};
      decoded.forEach((slug, list) {
        map[slug] = (list as List)
            .map((e) =>
                CategoryDish.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });
      state = map;
    } catch (_) {}
  }

  List<CategoryDish> dishesFor(String categorySlug) =>
      state[categorySlug] ?? const [];

  Future<void> addDish(String categorySlug, CategoryDish dish) async {
    final updated = Map<String, List<CategoryDish>>.from(state);
    updated[categorySlug] = [...(updated[categorySlug] ?? []), dish];
    state = updated;
    await _persist(updated);
  }

  Future<void> removeDish(String categorySlug, String dishId) async {
    final current = state[categorySlug] ?? [];
    final updated = Map<String, List<CategoryDish>>.from(state);
    updated[categorySlug] = current.where((d) => d.id != dishId).toList();
    state = updated;
    await _persist(updated);
  }

  /// Replaces a dish in a category with an enriched copy (used when the AI
  /// recipe details are (re)fetched after the dish was added with just a name).
  Future<void> updateDish(String categorySlug, CategoryDish dish) async {
    final current = state[categorySlug] ?? [];
    final updated = Map<String, List<CategoryDish>>.from(state);
    updated[categorySlug] =
        current.map((d) => d.id == dish.id ? dish : d).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> _persist(Map<String, List<CategoryDish>> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
          map.map((k, v) => MapEntry(k, v.map((d) => d.toJson()).toList())));
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {}
  }
}

final localDishesProvider =
    NotifierProvider<LocalDishesNotifier, Map<String, List<CategoryDish>>>(
        LocalDishesNotifier.new);
