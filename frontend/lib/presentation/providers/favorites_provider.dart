import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final ids = await repo.getFavoriteIds();
      state = ids;
    } catch (_) {}
  }

  bool contains(String recipeId) => state.contains(recipeId);

  /// Optimistically toggles a favorite. Returns true on success, false on failure.
  Future<bool> toggle(String recipeId) async {
    final repo = ref.read(recipeRepositoryProvider);
    final wasFavorite = state.contains(recipeId);

    final optimistic = Set<String>.from(state);
    if (wasFavorite) {
      optimistic.remove(recipeId);
    } else {
      optimistic.add(recipeId);
    }
    state = optimistic;

    try {
      if (wasFavorite) {
        await repo.unfavoriteRecipe(recipeId);
      } else {
        await repo.favoriteRecipe(recipeId);
      }
      return true;
    } catch (_) {
      final revert = Set<String>.from(state);
      if (wasFavorite) {
        revert.add(recipeId);
      } else {
        revert.remove(recipeId);
      }
      state = revert;
      return false;
    }
  }

  Future<void> add(String recipeId) async {
    if (state.contains(recipeId)) return;
    await toggle(recipeId);
  }

  Future<void> remove(String recipeId) async {
    if (!state.contains(recipeId)) return;
    await toggle(recipeId);
  }

  Future<void> refresh() => _load();
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
