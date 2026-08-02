import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recipe_model.dart';
import 'api_provider.dart';
import 'recommendation_cache_provider.dart';
import 'local_dishes_provider.dart';

String mealForCurrentTime() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) return 'breakfast';
  if (hour >= 11 && hour < 16) return 'lunch';
  if (hour >= 16 && hour < 20) return 'snacks';
  return 'dinner';
}

final selectedMealProvider = StateProvider<String>((ref) => mealForCurrentTime());
final selectedIntentProvider = StateProvider<String>((ref) => '');

/// Cached recommendations - only fetches once per app launch per meal/intent combo, combined with local user-added dishes
final recommendationsProvider = FutureProvider<List<RecommendationModel>>((ref) async {
  final meal = ref.watch(selectedMealProvider);
  final intent = ref.watch(selectedIntentProvider);
  final cache = ref.watch(recommendationCacheProvider);
  final localDishesMap = ref.watch(localDishesProvider);
  
  // Collect local dishes added by user for this meal type
  final localDishesForMeal = <RecommendationModel>[];
  localDishesMap.forEach((categorySlug, dishes) {
    for (final dish in dishes) {
      if (dish.mealTypes == null || dish.mealTypes!.contains(meal) || dish.tags?.contains(meal) == true || categorySlug == meal) {
        localDishesForMeal.add(RecommendationModel(
          recipe: RecipeModel(
            id: dish.id,
            name: dish.name,
            description: dish.description,
            mealTypes: dish.mealTypes ?? [meal],
            dietType: dish.dietType,
            totalTimeMinutes: dish.timeMinutes,
            difficulty: dish.difficulty,
            healthCategory: dish.healthCategory,
            instructions: dish.instructions,
            tags: dish.tags,
          ),
          score: 1.0,
          reasons: ['Added by you'],
          availableIngredientsCount: 5,
          missingIngredientsCount: 0,
          missingIngredients: [],
          useSoonIngredients: [],
        ));
      }
    }
  });

  final cacheKey = 'recommendations_${meal}_${intent}';
  
  List<RecommendationModel> apiRecommendations;
  final cached = cache.get(cacheKey);
  if (cached != null) {
    apiRecommendations = cached.recommendations;
  } else {
    final repo = ref.watch(recipeRepositoryProvider);
    apiRecommendations = await repo.getAiRecommendations(
      mealType: meal,
      intent: intent,
      limit: 10,
    );
    cache.set(cacheKey, CachedRecommendation(recommendations: apiRecommendations));
  }
  
  // Prepend user-added local dishes so they appear instantly in the list (e.g. Dhokla in breakfast)
  return [...localDishesForMeal, ...apiRecommendations];
});