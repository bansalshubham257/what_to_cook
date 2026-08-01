import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/recipe_model.dart';
import '../../providers/api_provider.dart';
import '../../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<RecipeModel> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final favorites = await repo.getFavorites();
      if (mounted) setState(() => _favorites = favorites);
    } catch (_) {
      if (mounted) setState(() => _favorites = []);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _removeFavorite(RecipeModel recipe) async {
    final ok = await ref.read(favoritesProvider.notifier).toggle(recipe.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '${recipe.name} removed from favorites' : 'Failed to remove favorite'),
          backgroundColor: ok ? Colors.grey[700] : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Set<String>>(favoritesProvider, (prev, next) {
      if ((prev?.length ?? 0) != next.length) {
        _load();
      }
    });
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favorites.isEmpty
                ? _EmptyFavorites(onExplore: () => context.push('/explore'))
                : _buildGroupedList(theme),
      ),
    );
  }

  Widget _buildGroupedList(ThemeData theme) {
    final grouped = <String, List<RecipeModel>>{};
    for (final recipe in _favorites) {
      final section = recipe.cuisineName ?? 'Other';
      grouped.putIfAbsent(section, () => []).add(recipe);
    }
    final sections = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Text(
                    section,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${grouped[section]!.length}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            for (final recipe in grouped[section]!)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: recipe.imageUrl != null
                          ? Image.network(recipe.imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[200],
                              child: const Icon(Icons.restaurant, color: Colors.grey),
                            ),
                    ),
                    title: Text(
                      recipe.name,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${recipe.totalTimeMinutes} min · ${recipe.difficulty ?? "Easy"}'
                      '${recipe.dietType != null ? ' · ${recipe.dietType == "vegetarian" ? "Veg" : recipe.dietType == "non_vegetarian" ? "Non-Veg" : recipe.dietType}' : ""}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
                      onPressed: () => _removeFavorite(recipe),
                      tooltip: 'Remove from favorites',
                    ),
                    onTap: () => context.push('/recipe/${recipe.id}'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyFavorites({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the heart icon on any recipe to save it here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.explore),
              label: const Text('Explore recipes'),
            ),
          ],
        ),
      ),
    );
  }
}
