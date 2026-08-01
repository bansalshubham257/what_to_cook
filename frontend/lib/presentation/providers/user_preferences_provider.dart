import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cuisine preferences chosen at first-launch onboarding (editable from
/// Profile). Used to personalise category lists, suggestions and the planner.
final cuisinePreferencesProvider = FutureProvider<List<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList('cuisine_preferences');
  return (saved == null || saved.isEmpty) ? ['north_indian'] : saved;
});

/// Diet preference chosen at onboarding (vegetarian, vegetarian_egg,
/// non_vegetarian, vegan).
final foodPreferenceProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('food_preference') ?? 'vegetarian';
});
