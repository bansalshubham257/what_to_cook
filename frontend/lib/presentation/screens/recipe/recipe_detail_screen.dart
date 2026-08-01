import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/recipe_model.dart';
import '../../providers/api_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/recipe_video_links_section.dart';

final recipeDetailProvider = FutureProvider.family<RecipeModel, String>((ref, id) {
  final repo = ref.watch(recipeRepositoryProvider);
  return repo.getRecipeDetail(id);
});

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  bool _showCookingMode = false;
  int _currentStep = 0;

  bool get _isFavorite => ref.watch(favoritesProvider).contains(widget.recipeId);

  Future<void> _toggleFavorite() async {
    final recipeName = ref.read(recipeDetailProvider(widget.recipeId)).valueOrNull?.name;
    final ok = await ref.read(favoritesProvider.notifier).toggle(widget.recipeId);
    final nowFavorite = ref.read(favoritesProvider).contains(widget.recipeId);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(ok
                ? (nowFavorite ? 'Added "$recipeName" to favorites' : 'Removed "$recipeName" from favorites')
                : 'Could not update favorite'),
            backgroundColor: ok ? (nowFavorite ? Colors.red : Colors.grey[700]) : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return recipeAsync.when(
      data: (recipe) {
        final steps = recipe.instructions
                ?.split('\n')
                .where((s) => s.trim().isNotEmpty)
                .toList() ??
            [];

        if (_showCookingMode) return _buildCookingMode(theme, steps);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : null),
                    onPressed: _toggleFavorite,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primary.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: recipe.imageUrl != null
                        ? Image.network(recipe.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackImage(theme))
                        : _buildFallbackImage(theme),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(recipe.name,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${recipe.healthScore}% Match',
                                style: const TextStyle(
                                    color: Colors.green, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (recipe.totalTimeMinutes > 0) ...[
                            _infoChip(Icons.timer, '${recipe.totalTimeMinutes} min'),
                            const SizedBox(width: 8),
                          ],
                          if (recipe.difficulty != null) ...[
                            _infoChip(Icons.restaurant, recipe.difficulty!),
                            const SizedBox(width: 8),
                          ],
                          if (recipe.servings > 0)
                            _infoChip(Icons.people, '${recipe.servings} servings'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (recipe.dietType != null) ...[
                            _infoChip(Icons.eco, recipe.dietType!),
                            const SizedBox(width: 8),
                          ],
                          if (recipe.cuisineId != null)
                            _infoChip(Icons.flag, recipe.cuisineId!),
                        ],
                      ),
                      if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(recipe.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() {
                                _currentStep = 0;
                                _showCookingMode = true;
                              }),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Cooking'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _logMeal(context),
                              icon: const Icon(Icons.check),
                              label: const Text('I Made This'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      RecipeVideoLinksSection(recipeId: recipe.id),
                      const SizedBox(height: 20),
                      Text('Ingredients',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty)
                        ...recipe.ingredients!.map((ing) => _ingredientRow(
                              ing.name ?? '',
                              ing.quantity != null
                                  ? '${ing.quantity}${ing.unit != null ? ' ${ing.unit}' : ''}'
                                  : '',
                              ing.isRequired,
                            ))
                      else
                        Text('No ingredients listed',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                      const Divider(height: 32),
                      Text('Instructions',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      if (steps.isEmpty)
                        Text('No instructions available',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey))
                      else
                        ...List.generate(steps.length, (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: theme.colorScheme.primary,
                                    child: Text('${i + 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(steps[i].trim(),
                                        style: theme.textTheme.bodyMedium),
                                  ),
                                ],
                              ),
                            )),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Could not load recipe', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(error.toString(),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(recipeDetailProvider(widget.recipeId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage(ThemeData theme) {
    return Center(
      child: Icon(Icons.restaurant,
          size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
    );
  }

  Widget _buildCookingMode(ThemeData theme, List<String> steps) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _showCookingMode = false),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / steps.length,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  Text('${_currentStep + 1}/${steps.length}',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Step ${_currentStep + 1}',
                          style: const TextStyle(color: Colors.white54, fontSize: 16)),
                      const SizedBox(height: 16),
                      Text(steps[_currentStep],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: () => setState(() => _currentStep--),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text('Previous', style: TextStyle(color: Colors.white)),
                    ),
                  const Spacer(),
                  if (_currentStep < steps.length - 1)
                    FilledButton.icon(
                      onPressed: () => setState(() => _currentStep++),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => _showCookingMode = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Meal completed!')),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logMeal(BuildContext context) {
    ref.read(recipeRepositoryProvider).logMeal(widget.recipeId, 'dinner');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meal logged!')),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _ingredientRow(String name, String quantity, bool available) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: available ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 15))),
          if (quantity.isNotEmpty)
            Text(quantity, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
