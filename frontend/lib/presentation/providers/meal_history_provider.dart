import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recipe_model.dart';
import 'api_provider.dart';

final mealHistoryProvider = FutureProvider<List<MealHistoryModel>>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  return repo.getMealHistory();
});
