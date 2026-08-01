import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/recipe_model.dart';
import '../../providers/meal_history_provider.dart';
import '../../providers/suggestions_providers.dart';

/// "What should I cook?" tab: pick a meal + a style and get personalised recipe
/// ideas, plus your recently enjoyed meals.
class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  final _meals = ['breakfast', 'lunch', 'snacks', 'dinner'];
  final _mealLabels = {'breakfast': 'Breakfast', 'lunch': 'Lunch', 'snacks': 'Snacks', 'dinner': 'Dinner'};
  final _intents = [
    {'id': '', 'label': 'All', 'icon': Icons.restaurant},
    {'id': 'healthy', 'label': 'Healthy', 'icon': Icons.favorite},
    {'id': 'quick', 'label': 'Quick', 'icon': Icons.timer},
    {'id': 'roti_sabzi', 'label': 'Roti Sabzi', 'icon': Icons.circle},
    {'id': 'rice', 'label': 'Rice', 'icon': Icons.set_meal},
    {'id': 'kids', 'label': 'Kids', 'icon': Icons.child_care},
    {'id': 'indulgent', 'label': 'Indulgent', 'icon': Icons.cake},
    {'id': 'surprise', 'label': 'Surprise Me', 'icon': Icons.casino},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final mealHistoryAsync = ref.watch(mealHistoryProvider);
    final selectedMeal = ref.watch(selectedMealProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What should I cook?',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _meals.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final meal = _meals[i];
                          final selected = selectedMeal == meal;
                          return ChoiceChip(
                            label: Text(_mealLabels[meal]!),
                            selected: selected,
                            onSelected: (_) =>
                                ref.read(selectedMealProvider.notifier).state = meal,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _intents.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final intent = _intents[i];
                          final selected = ref.watch(selectedIntentProvider) == intent['id'];
                          return ChoiceChip(
                            avatar: Icon(intent['icon'] as IconData, size: 18),
                            label: Text(intent['label'] as String, style: const TextStyle(fontSize: 12)),
                            selected: selected,
                            onSelected: (_) {
                              if (intent['id'] == 'surprise') {
                                context.push('/explore');
                                return;
                              }
                              ref.read(selectedIntentProvider.notifier).state = intent['id'] as String;
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(_sectionTitle(selectedMeal),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              sliver: recommendationsAsync.when(
                data: (recommendations) {
                  if (recommendations.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text('No recommendations found', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildRecipeCard(theme, recommendations[i]),
                      childCount: recommendations.length,
                    ),
                  );
                },
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildShimmerRecipeCard(theme),
                    childCount: 3,
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: _buildErrorState(theme, 'Could not load recommendations'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Recently Enjoyed', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: mealHistoryAsync.when(
                data: (meals) {
                  if (meals.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text('No meal history yet', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildRecentMealCard(theme, meals[i]),
                      childCount: meals.length,
                    ),
                  );
                },
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildShimmerMealCard(theme),
                    childCount: 3,
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: _buildErrorState(theme, 'Could not load meal history'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(ThemeData theme, RecommendationModel item) {
    final recipe = item.recipe;
    final statusIcon = item.missingIngredientsCount > 0 ? Icons.error_outline : Icons.check_circle;
    final statusColor = item.missingIngredientsCount > 0 ? Colors.orange : Colors.green;
    String statusText;
    if (item.missingIngredientsCount > 0) {
      statusText = 'Missing ${item.missingIngredientsCount} item${item.missingIngredientsCount > 1 ? 's' : ''}';
    } else {
      statusText = 'Everything available';
    }
    if (item.useSoonIngredients.isNotEmpty) {
      statusText += ' • Use ${item.useSoonIngredients.first} soon';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(recipe.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (item.isFavorite)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.favorite, size: 14, color: Colors.red),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Expanded(child: Text(statusText, style: theme.textTheme.bodySmall)),
            ],
          ),
        ),
        trailing: Text('${recipe.totalTimeMinutes} min', style: theme.textTheme.bodySmall),
        onTap: () => context.push('/recipe/${recipe.id}'),
      ),
    );
  }

  Widget _buildShimmerRecipeCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180, height: 14,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity, height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMealCard(ThemeData theme, MealHistoryModel meal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: meal.recipeImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(meal.recipeImage!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.restaurant, color: theme.colorScheme.primary)),
                  )
                : Icon(Icons.restaurant, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.recipeName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text('${_formatDate(meal.cookedDate)} • ${meal.mealType}${meal.healthCategory != null ? ' • ${meal.healthCategory}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerMealCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120, height: 14,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 180, height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _sectionTitle(String meal) {
    switch (meal) {
      case 'breakfast':
        return 'Breakfast Ideas';
      case 'lunch':
        return 'Lunch Ideas';
      case 'snacks':
        return 'Snacks';
      default:
        return 'Dinner Tonight';
    }
  }
}
