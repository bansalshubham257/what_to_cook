import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recipe_model.dart';
import 'api_provider.dart';
import 'recommendation_cache_provider.dart';

String mealForCurrentTime() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) return 'breakfast';
  if (hour >= 11 && hour < 16) return 'lunch';
  if (hour >= 16 && hour < 20) return 'snacks';
  return 'dinner';
}

final selectedMealProvider = StateProvider<String>((ref) => mealForCurrentTime());
final selectedIntentProvider = StateProvider<String>((ref) => '');

/// Cached recommendations - only fetches once per app launch per meal/intent combo
final recommendationsProvider = FutureProvider<List<RecommendationModel>>((ref) async {
  final meal = ref.watch(selectedMealProvider);
  final intent = ref.watch(selectedIntentProvider);
  final cache = ref.watch(recommendationCacheProvider);
  
  final cacheKey = 'recommendations_${meal}_${intent}';
  
  // Check cache first
  final cached = cache.get(cacheKey);
  if (cached != null) {
    return cached.recommendations;
  }
  
  // Fetch from API
  final repo = ref.watch(recipeRepositoryProvider);
  final recommendations = await repo.getAiRecommendations(
    mealType: meal,
    intent: intent,
    limit: 10,
  );
  
  // Cache the result
  cache.set(cacheKey, CachedRecommendation(recommendations: recommendations));
  
  return recommendations;
});