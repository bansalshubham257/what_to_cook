import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recipe_model.dart';
import 'api_provider.dart';

final mealHistoryProvider = FutureProvider<List<MealHistoryModel>>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  return repo.getMealHistory();
});

/// Bumped every time the user opens the Insights tab. The screen stays alive
/// inside the IndexedStack so it cannot rely on initState alone; listening to
/// this provider guarantees it reloads fresh data on every visit.
final insightsRefreshProvider =
    NotifierProvider<InsightsRefreshNotifier, int>(InsightsRefreshNotifier.new);

class InsightsRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
