import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/category_catalog.dart';
import 'api_provider.dart';
import 'local_dishes_provider.dart';
import 'meal_history_provider.dart';

/// The four meal slots a day can hold.
const mealPlanSlots = ['breakfast', 'lunch', 'snacks', 'dinner'];

const mealPlanSlotLabels = {
  'breakfast': 'Breakfast',
  'lunch': 'Lunch',
  'snacks': 'Snacks',
  'dinner': 'Dinner',
};

/// Absolute day number (days since epoch) shared by the week and month views so
/// both plans live in one store.
int dayNumberFor(DateTime date) => date.difference(DateTime(1970, 1, 1)).inDays;

DateTime dateFor(int dayNumber) =>
    DateTime(1970, 1, 1).add(Duration(days: dayNumber));

/// One planned meal: a dish assigned to a (dayNumber, slot) cell.
class MealPlanEntry {
  final int dayNumber;
  final String slot; // 'breakfast' | 'lunch' | 'snacks' | 'dinner'
  final String recipeId; // dish.id for curated dishes, DB id for recipes
  final String name;
  final int timeMinutes;

  /// Category slug that owns [recipeId] when the entry is a curated dish.
  final String? categorySlug;

  /// Whether the user marked this dish as made (used for today's meals).
  final bool made;

  const MealPlanEntry({
    required this.dayNumber,
    required this.slot,
    required this.recipeId,
    required this.name,
    this.timeMinutes = 0,
    this.categorySlug,
    this.made = false,
  });

  bool get isCurated => categorySlug != null;

  MealPlanEntry copyWith({bool? made}) => MealPlanEntry(
        dayNumber: dayNumber,
        slot: slot,
        recipeId: recipeId,
        name: name,
        timeMinutes: timeMinutes,
        categorySlug: categorySlug,
        made: made ?? this.made,
      );

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        dayNumber: (json['day_number'] ?? json['day'] ?? 0) as int,
        slot: json['slot'] ?? 'lunch',
        recipeId: json['recipe_id'] ?? '',
        name: json['name'] ?? '',
        timeMinutes: (json['time_minutes'] ?? 0) as int,
        categorySlug: json['category_slug'],
        made: json['made'] == true,
      );

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'slot': slot,
        'recipe_id': recipeId,
        'name': name,
        'time_minutes': timeMinutes,
        'category_slug': categorySlug,
        'made': made,
      };
}

/// Marks a planned meal as "made today": persists the local [made] flag and
/// logs it to meal history so it shows up under Recently Enjoyed / Meal
/// History / Insights. Returns true when the backend log succeeded (so
/// insights reflect it) and false when only the local flag could be saved.
Future<bool> markMealMade(WidgetRef ref, MealPlanEntry entry) async {
  await ref
      .read(mealPlanProvider.notifier)
      .markMade(entry.dayNumber, entry.slot);

  final synced = await _logEntryToBackend(ref, entry);
  ref.invalidate(mealHistoryProvider);
  return synced;
}

/// Re-attempts the backend log for an entry that is already marked made (for
/// example when an earlier sync failed). Does not touch the local flag.
Future<bool> reLogMeal(WidgetRef ref, MealPlanEntry entry) async {
  final synced = await _logEntryToBackend(ref, entry);
  ref.invalidate(mealHistoryProvider);
  return synced;
}

Future<bool> _logEntryToBackend(WidgetRef ref, MealPlanEntry entry) async {
  if (_isUuid(entry.recipeId)) {
    try {
      await ref
          .read(recipeRepositoryProvider)
          .logMeal(entry.recipeId, entry.slot);
      return true;
    } catch (_) {
      return false;
    }
  }

  CategoryDish? dish;
  if (entry.isCurated) {
    dish = curatedDishById(entry.recipeId);
  }
  if (dish == null && entry.categorySlug != null) {
    dish = (ref.read(localDishesProvider)[entry.categorySlug!] ??
            const <CategoryDish>[])
        .where((d) => d.id == entry.recipeId)
        .firstOrNull;
  }
  if (dish == null) return false;

  try {
    await ref.read(recipeRepositoryProvider).logDish(
          name: dish.name,
          mealType: entry.slot,
          cuisine: dish.cuisine ?? _cuisineFromSlug(entry.categorySlug),
          healthCategory: dish.healthCategory,
          dietType: dish.dietType,
          timeMinutes: dish.timeMinutes,
          description: dish.description,
        );
    return true;
  } catch (_) {
    return false;
  }
}

/// Extracts the cuisine name from a category slug like `cuisine-north_indian`
/// or `cuisine-gujarati-breakfast`.
String? _cuisineFromSlug(String? categorySlug) {
  if (categorySlug == null || !categorySlug.startsWith('cuisine-')) return null;
  final parts = categorySlug.split('-');
  if (parts.length == 2) return parts[1];
  return parts.sublist(1, parts.length - 1).join('-');
}

bool _isUuid(String value) {
  final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  return uuid.hasMatch(value);
}

/// Every curated dish that can be placed into the plan (dish, owning category).
List<(CategoryDish, String)> mealPlanOptions() {
  final result = <(CategoryDish, String)>[];
  for (final c in kSpecialCategories) {
    for (final d in c.hardcoded) {
      result.add((d, c.slug));
    }
  }
  return result;
}

List<(CategoryDish, String)> preferredMealPlanOptions({
  required List<String> cuisines,
  required String foodPreference,
}) {
  final result = <(CategoryDish, String)>[];
  final preferredCuisines =
      cuisines.isEmpty ? const ['north_indian'] : cuisines;

  for (final cuisine in preferredCuisines) {
    final byCategory = cuisineCategoryDishes[cuisine];
    if (byCategory != null) {
      for (final entry in byCategory.entries) {
        for (final dish in entry.value) {
          if (_allowedForFoodPreference(dish, foodPreference)) {
            result.add((dish, 'cuisine-$cuisine'));
          }
        }
      }
    }
    for (final dish
        in curatedCuisineDishes[cuisine] ?? const <CategoryDish>[]) {
      if (_allowedForFoodPreference(dish, foodPreference)) {
        result.add((dish, 'cuisine-$cuisine'));
      }
    }
  }

  for (final (dish, slug) in mealPlanOptions()) {
    if (_allowedForFoodPreference(dish, foodPreference)) {
      result.add((dish, slug));
    }
  }

  final seen = <String>{};
  return [
    for (final item in result)
      if (seen.add(item.$1.id)) item,
  ];
}

bool _allowedForFoodPreference(CategoryDish dish, String foodPreference) {
  final text = [
    dish.name,
    dish.description,
    dish.dietType,
    dish.healthCategory,
    ...?dish.tags,
    ...?dish.ingredients,
  ].whereType<String>().join(' ').toLowerCase();
  final nonVegWords = ['chicken', 'mutton', 'fish', 'prawn', 'shrimp', 'meat'];
  final eggWords = ['egg', 'omelette', 'omurice', 'huevos'];
  final hasNonVeg = nonVegWords.any(text.contains);
  final hasEgg = eggWords.any(text.contains);

  switch (foodPreference) {
    case 'vegan':
      return !hasNonVeg &&
          !hasEgg &&
          !text.contains('paneer') &&
          !text.contains('curd') &&
          !text.contains('milk') &&
          !text.contains('ghee') &&
          !text.contains('cheese');
    case 'vegetarian':
      return !hasNonVeg && !hasEgg;
    case 'vegetarian_egg':
      return !hasNonVeg;
    default:
      return true;
  }
}

/// Every curated dish across the special + cuisine catalogs, keyed by its
/// stable id. Built once so plan entries (which may come from either catalog)
/// can be resolved back to a dish when logging a meal.
final Map<String, CategoryDish> _curatedDishesById = () {
  final map = <String, CategoryDish>{};
  void addAll(Iterable<CategoryDish> dishes) {
    for (final d in dishes) {
      map.putIfAbsent(d.id, () => d);
    }
  }

  for (final c in kSpecialCategories) {
    addAll(c.hardcoded);
  }
  for (final list in curatedCuisineDishes.values) {
    addAll(list);
  }
  for (final byCategory in cuisineCategoryDishes.values) {
    for (final list in byCategory.values) {
      addAll(list);
    }
  }
  return map;
}();

/// Looks up a curated dish by its stable id across every catalog.
CategoryDish? curatedDishById(String id) => _curatedDishesById[id];

/// Category label for a special-category slug (used in the planner picker).
String specialCategoryLabel(String slug) {
  for (final c in kSpecialCategories) {
    if (c.slug == slug) return c.label;
  }
  return slug;
}

class MealPlanNotifier extends Notifier<Map<String, MealPlanEntry>> {
  static const _prefsKey = 'meal_plan_v2';

  @override
  Map<String, MealPlanEntry> build() {
    _load();
    return {};
  }

  String _key(int dayNumber, String slot) => '$dayNumber-$slot';

  MealPlanEntry? entryFor(int dayNumber, String slot) =>
      state[_key(dayNumber, slot)];

  /// Number of planned meals for a date range [from, from + days).
  int countForRange(int fromDay, int days, {List<String>? slots}) {
    var count = 0;
    for (var d = fromDay; d < fromDay + days; d++) {
      for (final s in slots ?? mealPlanSlots) {
        if (state.containsKey(_key(d, s))) count++;
      }
    }
    return count;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = decoded.map(
        (k, v) => MapEntry(
            k, MealPlanEntry.fromJson((v as Map).cast<String, dynamic>())),
      );
    } catch (_) {}
  }

  Future<void> setEntry(int dayNumber, String slot, MealPlanEntry entry) async {
    final updated = Map<String, MealPlanEntry>.from(state);
    updated[_key(dayNumber, slot)] = entry;
    state = updated;
    await _persist(updated);
  }

  Future<void> removeEntry(int dayNumber, String slot) async {
    final updated = Map<String, MealPlanEntry>.from(state)
      ..remove(_key(dayNumber, slot));
    state = updated;
    await _persist(updated);
  }

  /// Marks a planned meal as "made today" (no-op if already marked or empty).
  Future<void> markMade(int dayNumber, String slot) async {
    final key = _key(dayNumber, slot);
    final current = state[key];
    if (current == null || current.made) return;
    final updated = Map<String, MealPlanEntry>.from(state);
    updated[key] = current.copyWith(made: true);
    state = updated;
    await _persist(updated);
  }

  /// Auto-fills [days] days starting from [startDay] with all four slots.
  Future<void> generatePlan({required int startDay, required int days}) async {
    final prefs = await SharedPreferences.getInstance();
    final pool = preferredMealPlanOptions(
      cuisines:
          prefs.getStringList('cuisine_preferences') ?? const ['north_indian'],
      foodPreference: prefs.getString('food_preference') ?? 'vegetarian',
    );
    if (pool.isEmpty) return;
    final updated = Map<String, MealPlanEntry>.from(state);
    var idx = 0;
    for (var d = 0; d < days; d++) {
      for (final slot in mealPlanSlots) {
        final (dish, slug) = pool[idx % pool.length];
        idx++;
        updated[_key(startDay + d, slot)] = MealPlanEntry(
          dayNumber: startDay + d,
          slot: slot,
          recipeId: dish.id,
          name: dish.name,
          timeMinutes: dish.timeMinutes,
          categorySlug: slug,
        );
      }
    }
    state = updated;
    await _persist(updated);
  }

  Future<void> clearPlan() async {
    state = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _persist(Map<String, MealPlanEntry> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(map.map((k, v) => MapEntry(k, v.toJson()))),
      );
    } catch (_) {}
  }
}

final mealPlanProvider =
    NotifierProvider<MealPlanNotifier, Map<String, MealPlanEntry>>(
        MealPlanNotifier.new);
