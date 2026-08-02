import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/recipe_model.dart';
import '../../providers/api_provider.dart';
import '../../providers/meal_history_provider.dart';
import '../../providers/suggestions_providers.dart';
import '../../providers/local_dishes_provider.dart';
import '../../../core/constants/category_catalog.dart';

/// "What should I cook?" tab: pick a meal + a style and get personalised recipe
/// ideas, plus your recently enjoyed meals.
class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  final _meals = ['breakfast', 'lunch', 'snacks', 'dinner'];
  final _mealLabels = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'snacks': 'Snacks',
    'dinner': 'Dinner'
  };
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDishDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Dish'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
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
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
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
                            onSelected: (_) => ref
                                .read(selectedMealProvider.notifier)
                                .state = meal,
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
                          final selected =
                              ref.watch(selectedIntentProvider) == intent['id'];
                          return ChoiceChip(
                            avatar: Icon(intent['icon'] as IconData, size: 18),
                            label: Text(intent['label'] as String,
                                style: const TextStyle(fontSize: 12)),
                            selected: selected,
                            onSelected: (_) {
                              if (intent['id'] == 'surprise') {
                                context.push('/explore');
                                return;
                              }
                              ref.read(selectedIntentProvider.notifier).state =
                                  intent['id'] as String;
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
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
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
                          child: Text('No recommendations found',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey)),
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
                  child:
                      _buildErrorState(theme, 'Could not load recommendations'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Recently Enjoyed',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
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
                          child: Text('No meal history yet',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey)),
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
    final statusIcon = item.missingIngredientsCount > 0
        ? Icons.error_outline
        : Icons.check_circle;
    final statusColor =
        item.missingIngredientsCount > 0 ? Colors.orange : Colors.green;
    String statusText;
    if (item.missingIngredientsCount > 0) {
      statusText =
          'Missing ${item.missingIngredientsCount} item${item.missingIngredientsCount > 1 ? 's' : ''}';
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
              child: Text(recipe.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
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
              Expanded(
                  child: Text(statusText, style: theme.textTheme.bodySmall)),
            ],
          ),
        ),
        trailing: Text('${recipe.totalTimeMinutes} min',
            style: theme.textTheme.bodySmall),
        onTap: () => _openRecipe(recipe.id),
      ),
    );
  }

  void _openRecipe(String recipeId) {
    if (recipeId.startsWith('local-')) {
      final localDishesMap = ref.read(localDishesProvider);
      CategoryDish? foundDish;
      String foundCategory = ref.read(selectedMealProvider);
      localDishesMap.forEach((cat, dishes) {
        for (final d in dishes) {
          if (d.id == recipeId) {
            foundDish = d;
            foundCategory = cat;
          }
        }
      });
      if (foundDish != null) {
        context.push('/dish', extra: (foundDish!, foundCategory));
        return;
      }
    }
    context.push('/recipe/$recipeId');
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
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 12,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: meal.recipeImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(meal.recipeImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.restaurant,
                            color: theme.colorScheme.primary)),
                  )
                : Icon(Icons.restaurant, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.recipeName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                Text(
                    '${_formatDate(meal.cookedDate)} • ${meal.mealType}${meal.healthCategory != null ? ' • ${meal.healthCategory}' : ''}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey)),
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
            width: 48,
            height: 48,
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
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 180,
                  height: 12,
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
            Text(message,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
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

  Future<void> _showAddDishDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final timeController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'breakfast';
    String selectedCuisine = 'north_indian';
    String selectedMealType = 'breakfast';
    String? selectedDifficulty = 'easy';
    String? selectedDietType = 'vegetarian';
    var isFetchingRecipe = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                  const Expanded(
                    child: Text(
                      'Add New Dish',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(
                          labelText: 'Dish Name',
                          hintText: 'e.g., Paneer Butter Masala'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: kSpecialCategories
                          .map((c) => DropdownMenuItem(
                              value: c.slug, child: Text(c.label)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCuisine,
                      decoration: const InputDecoration(labelText: 'Cuisine'),
                      items: curatedCuisineDishes.keys
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child:
                                  Text(c.replaceAll('_', ' ').toUpperCase())))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedCuisine = v!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMealType,
                      decoration: const InputDecoration(labelText: 'Meal Type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'breakfast', child: Text('Breakfast')),
                        DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                        DropdownMenuItem(
                            value: 'snacks', child: Text('Snacks')),
                        DropdownMenuItem(
                            value: 'dinner', child: Text('Dinner')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedMealType = v!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDifficulty,
                      decoration:
                          const InputDecoration(labelText: 'Difficulty'),
                      items: const [
                        DropdownMenuItem(value: 'easy', child: Text('Easy')),
                        DropdownMenuItem(
                            value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'hard', child: Text('Hard')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedDifficulty = v),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDietType,
                      decoration: const InputDecoration(labelText: 'Diet Type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'vegetarian', child: Text('Vegetarian')),
                        DropdownMenuItem(
                            value: 'non_vegetarian',
                            child: Text('Non-Vegetarian')),
                        DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                        DropdownMenuItem(
                            value: 'vegetarian_egg',
                            child: Text('Vegetarian + Egg')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedDietType = v),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: timeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Time (minutes)', hintText: 'e.g., 30'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                          labelText: 'Description', alignLabelWithHint: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    setDialogState(() => isFetchingRecipe = true);

                    final userDesc = descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim();
                    final userTime = int.tryParse(timeController.text.trim());

                    // Fetch full recipe details (ingredients, instructions,
                    // time, difficulty, diet, cuisine) from the AI, so a dish
                    // added with just a name still gets a complete recipe.
                    Map<String, dynamic>? details;
                    try {
                      details = await ref
                          .read(recipeRepositoryProvider)
                          .enrichDish(name,
                              cuisine: selectedCuisine,
                              mealType: selectedMealType);
                    } catch (_) {}

                    final rawIngredients =
                        (details?['ingredients'] as List?) ?? const [];
                    final ingredients = rawIngredients
                        .map((item) {
                          final m = (item as Map).cast<String, dynamic>();
                          final qty = (m['quantity'] ?? '').toString().trim();
                          final unit = (m['unit'] ?? '').toString().trim();
                          final ingName = (m['name'] ?? '').toString().trim();
                          final parts = <String>[
                            if (qty.isNotEmpty) qty,
                            if (unit.isNotEmpty && unit != 'to taste') unit,
                            if (ingName.isNotEmpty) ingName,
                          ];
                          return parts.join(' ');
                        })
                        .where((s) => s.isNotEmpty)
                        .toList();

                    final aiTime =
                        (details?['total_time_minutes'] as num?)?.toInt() ?? 0;
                    final aiName = (details?['name'] ?? name).toString().trim();

                    final dish = CategoryDish(
                      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
                      name: aiName.isNotEmpty ? aiName : name,
                      description: (userDesc != null && userDesc.isNotEmpty)
                          ? userDesc
                          : details?['description'] as String?,
                      timeMinutes: (userTime != null && userTime > 0)
                          ? userTime
                          : aiTime,
                      difficulty: (selectedDifficulty?.isNotEmpty ?? false)
                          ? selectedDifficulty
                          : details?['difficulty'] as String?,
                      dietType: (selectedDietType?.isNotEmpty ?? false)
                          ? selectedDietType
                          : details?['diet_type'] as String?,
                      cuisine:
                          details?['cuisine'] as String? ?? selectedCuisine,
                      mealTypes: details?['meal_types'] != null
                          ? List<String>.from(details!['meal_types'] as List)
                          : [selectedMealType],
                      tags: details?['tags'] != null
                          ? List<String>.from(details!['tags'] as List)
                          : [selectedCategory],
                      ingredients: ingredients,
                      instructions: details?['instructions'] as String?,
                    );

                    await ref
                        .read(localDishesProvider.notifier)
                        .addDish(selectedCategory, dish);

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            details == null
                                ? '"$name" added — recipe details could not be fetched'
                                : '"$name" added with full recipe & ingredients',
                          ),
                          backgroundColor:
                              details == null ? Colors.orange : Colors.green,
                        ),
                      );
                    }
                  },
                  child: isFetchingRecipe
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add Dish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
