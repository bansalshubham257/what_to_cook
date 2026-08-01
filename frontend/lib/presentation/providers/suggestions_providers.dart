import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recipe_model.dart';
import 'api_provider.dart';

String mealForCurrentTime() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) return 'breakfast';
  if (hour >= 11 && hour < 16) return 'lunch';
  if (hour >= 16 && hour < 20) return 'snacks';
  return 'dinner';
}

final selectedMealProvider = StateProvider<String>((ref) => mealForCurrentTime());
final selectedIntentProvider = StateProvider<String>((ref) => '');

final recommendationsProvider = FutureProvider<List<RecommendationModel>>((ref) {
  final meal = ref.watch(selectedMealProvider);
  final intent = ref.watch(selectedIntentProvider);
  final repo = ref.watch(recipeRepositoryProvider);
  return repo.getAiRecommendations(
    mealType: meal,
    intent: intent,
    limit: 10,
  );
});
