import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_catalog.dart';
import 'local_dishes_provider.dart';
import 'meal_plan_provider.dart';
import 'suggestions_providers.dart';
import 'user_preferences_provider.dart';

/// The two suggestions shown on the simplified Home page.
class HomeSuggestions {
  /// First meal planned for today (falling back to the nearest future meal).
  final MealPlanEntry? planEntry;

  /// Whether the plan has any meals at all (so we can prompt to open planner).
  final bool hasPlan;

  /// A random dish from user-added dishes, preferred cuisines, or curated list.
  final CategoryDish? randomDish;
  final String? randomSlug;

  const HomeSuggestions({
    this.planEntry,
    this.hasPlan = false,
    this.randomDish,
    this.randomSlug,
  });
}

final homeSuggestionsProvider = FutureProvider<HomeSuggestions>((ref) async {
  ref.watch(mealPlanProvider);
  ref.watch(localDishesProvider);
  final preferred = ref.watch(cuisinePreferencesProvider).value ?? const [];
  final foodPreference = ref.watch(foodPreferenceProvider).value ?? 'vegetarian';

  final plan = ref.read(mealPlanProvider);
  final planEntry = _firstPlannedMeal(plan);
  final hasPlan = plan.isNotEmpty;

  final local = <(CategoryDish, String)>[];
  ref.read(localDishesProvider).forEach((slug, dishes) {
    for (final d in dishes) {
      local.add((d, slug));
    }
  });
  final (dish, slug) = _randomDish(local, preferred, foodPreference);
  return HomeSuggestions(
    planEntry: planEntry,
    hasPlan: hasPlan,
    randomDish: dish,
    randomSlug: slug,
  );
});

MealPlanEntry? _firstPlannedMeal(Map<String, MealPlanEntry> plan) {
  if (plan.isEmpty) return null;
  final today = dayNumberFor(DateTime.now());
  final currentSlot = mealForCurrentTime();
  // Prefer today's entry for the current meal slot, then today, then the next days.
  final now = plan.values.where((e) => e.dayNumber == today).toList();
  for (final e in now) {
    if (e.slot == currentSlot) return e;
  }
  if (now.isNotEmpty) return now.first;
  for (var d = 1; d <= 7; d++) {
    final day = plan.values.where((e) => e.dayNumber == today + d).toList();
    if (day.isNotEmpty) return day.first;
  }
  return null;
}

(CategoryDish?, String?) _randomDish(
    List<(CategoryDish, String)> local, List<String> preferred, String foodPreference) {
  final rng = Random();

  // 1. User-added local dishes.
  if (local.isNotEmpty) {
    final (d, s) = local[rng.nextInt(local.length)];
    return (d, s);
  }

  // 2. Dishes from the user's preferred cuisines.
  final prefDishes = preferredMealPlanOptions(cuisines: preferred, foodPreference: foodPreference);
  if (prefDishes.isNotEmpty) {
    final (d, s) = prefDishes[rng.nextInt(prefDishes.length)];
    return (d, s);
  }

  // 3. Fallback: any curated dish.
  final all = mealPlanOptions();
  if (all.isEmpty) return (null, null);
  final (d, s) = all[rng.nextInt(all.length)];
  return (d, s);
}
