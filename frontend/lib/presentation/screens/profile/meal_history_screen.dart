import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/recipe_model.dart';
import '../../providers/meal_history_provider.dart';

/// Full list of meals the user has logged as made ("I Made This").
class MealHistoryScreen extends ConsumerWidget {
  const MealHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(mealHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meal History')),
      body: historyAsync.when(
        data: (meals) {
          if (meals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 56, color: theme.colorScheme.primary.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text('No meals logged yet',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Tap "I Made This" on any recipe to log a meal',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: meals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _mealTile(context, theme, meals[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text('Could not load meal history',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _mealTile(BuildContext context, ThemeData theme, MealHistoryModel meal) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: meal.recipeImage != null
              ? Image.network(meal.recipeImage!, width: 48, height: 48, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(theme))
              : _fallback(theme),
        ),
        title: Text(meal.recipeName,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${_formatDate(meal.cookedDate)} · ${meal.mealType}'
          '${meal.healthCategory != null ? ' · ${meal.healthCategory}' : ''}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => context.push('/recipe/${meal.recipeId}'),
      ),
    );
  }

  Widget _fallback(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.restaurant, color: theme.colorScheme.primary),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM d, yyyy · h:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
