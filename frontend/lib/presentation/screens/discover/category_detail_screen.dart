import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/category_catalog.dart';
import '../../../data/models/recipe_model.dart';
import '../../providers/api_provider.dart';
import '../../providers/hidden_dishes_provider.dart';
import '../../providers/local_dishes_provider.dart';
import '../../providers/user_preferences_provider.dart';

/// Shows one category's dishes as a single combined list:
/// curated dishes + database dishes + locally-added dishes. User-added dishes
/// are marked with a small "Added by you" label on their name instead of a
/// separate section. When a user adds only a name, the AI fills in the details.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  /// Query params used to rebuild cuisine categories.
  final String? label;
  final String? cuisine;
  final String? meal;

  /// Comma-separated category keys pre-selected from Discover
  /// (e.g. "healthy,veg"); "_quick" enables the quick toggle.
  final String? filters;

  const CategoryDetailScreen({
    super.key,
    required this.slug,
    this.label,
    this.cuisine,
    this.meal,
    this.filters,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  static const _uuid = Uuid();

  /// The 7 sub-categories every cuisine supports (label, key). Selecting one
  /// switches the screen to that cuisine's category view (5 hardcoded dishes
  /// + up to 5 from the database + local dishes).
  static const _categoryChips = <(String, String)>[
    ('Breakfast', 'breakfast'),
    ('Healthy', 'healthy'),
    ('Dinner', 'dinner'),
    ('Veg', 'veg'),
    ('Non-Veg', 'nonveg'),
    ('Sweet', 'sweet'),
    ('Kids', 'kids'),
  ];

  late final CategoryConfig _category;

  List<RecipeModel> _dbRecipes = [];
  bool _isLoadingDb = true;

  /// Currently selected sub-categories (subset of the 7 keys). Empty means the
  /// cuisine's general view. Dishes matching any selected key are shown.
  final Set<String> _activeCategoryKeys = {};

  /// Extra toggle that only keeps dishes under 30 minutes.
  bool _quickOnly = false;

  @override
  void initState() {
    super.initState();
    _category = _buildCategory();
    final filters = widget.filters;
    if (filters != null && filters.isNotEmpty) {
      final keys = filters
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      for (final key in keys) {
        if (key == '_quick') {
          _quickOnly = true;
        } else if (_categoryChips.any((c) => c.$2 == key)) {
          _activeCategoryKeys.add(key);
        }
      }
    }
    _loadDbDishes();
  }

  CategoryConfig _buildCategory() {
    if (widget.cuisine != null) {
      final name = widget.cuisine!;
      final hardcoded = curatedCuisineDishes[name] ?? const <CategoryDish>[];
      return categoryForCuisine(
        {
          'name': name,
          'display_name': widget.label ?? name,
        },
        mealType: widget.meal,
        hardcoded: hardcoded,
      );
    }
    return kSpecialCategories.firstWhere(
      (c) => c.slug == widget.slug,
      orElse: () => kSpecialCategories.first,
    );
  }

  Future<void> _loadDbDishes({Set<String>? categoryKeys}) async {
    final keys = categoryKeys ?? _activeCategoryKeys;
    setState(() => _isLoadingDb = true);
    final multi = keys.length > 1;
    final (dbQuery, dbMealType) = _dbParamsFor(keys);
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final results = await repo.searchRecipes(
        dbQuery,
        cuisine: _category.cuisine,
        mealType: dbMealType,
        limit: multi ? 20 : 5,
      );
      var filtered = results;
      if (multi) {
        final labels = keys.map(_labelFor).toList();
        filtered = results.where((r) => _recipeMatchesAll(r, labels)).toList();
      }
      if (mounted) setState(() => _dbRecipes = filtered);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingDb = false);
  }

  bool _recipeMatchesAll(RecipeModel r, Iterable<String> labels) {
    return labels.every(
      (label) =>
          _matchesFilter(label, CategoryDish(id: '', name: r.name), recipe: r),
    );
  }

  /// (query, meal_type) sent to the database for the selected sub-categories.
  (String, String?) _dbParamsFor(Set<String> keys) {
    if (keys.length == 1) {
      switch (keys.first) {
        case 'breakfast':
          return ('breakfast', null);
        case 'healthy':
          return ('healthy', null);
        case 'dinner':
          return ('dinner', null);
        case 'veg':
          return ('veg', null);
        case 'nonveg':
          return ('non-veg', null);
        case 'sweet':
          return ('sweet', null);
        case 'kids':
          return ('kids', null);
      }
    }
    return (_category.searchQuery, _category.mealType);
  }

  String _labelFor(String key) {
    for (final (label, k) in _categoryChips) {
      if (k == key) return label;
    }
    return key;
  }

  /// Hardcoded dishes for the currently active sub-category view.
  List<CategoryDish> _hardcodedList(String? key) {
    if (key == null) return _category.hardcoded;
    if (_category.cuisine != null) {
      return cuisineCategoryDishes[_category.cuisine!]?[key] ??
          const <CategoryDish>[];
    }
    for (final c in kSpecialCategories) {
      if (c.slug == key) return c.hardcoded;
    }
    return const <CategoryDish>[];
  }

  /// Curated dishes for the selected sub-categories (union of their lists, or
  /// the category's general list when none are selected).
  List<CategoryDish> _curatedList() {
    if (_activeCategoryKeys.isEmpty) return _category.hardcoded;
    final result = <CategoryDish>[];
    for (final key in _activeCategoryKeys) {
      result.addAll(_hardcodedList(key));
    }
    return result;
  }

  String get _activeCategorySummary {
    if (_activeCategoryKeys.isEmpty) return 'All';
    return _activeCategoryKeys.map(_labelFor).join(' + ');
  }

  /// Dishes from the user's preferred cuisines for this category, shown as a
  /// "For you" block at the top of meal-based categories (breakfast, lunch,
  /// dinner, snacks, sweet). Falls back to a cuisine's general dishes when the
  /// cuisine has no list for the category key (e.g. lunch/snacks).
  List<CategoryDish> _forYouDishes() {
    if (_category.cuisine != null) return const [];
    final preferred = ref.watch(cuisinePreferencesProvider).value ?? const [];
    if (preferred.isEmpty) return const [];
    final result = <CategoryDish>[];
    final seen = <String>{};
    final existingNames =
        _category.hardcoded.map((d) => d.name.toLowerCase()).toSet();
    for (final cuisine in preferred) {
      final perCat = cuisineCategoryDishes[cuisine];
      List<CategoryDish> list;
      if (perCat != null && perCat.containsKey(_category.slug)) {
        list = perCat[_category.slug]!;
      } else {
        list = curatedCuisineDishes[cuisine] ?? const <CategoryDish>[];
      }
      for (final d in list) {
        final name = d.name.toLowerCase();
        if (existingNames.contains(name)) continue;
        if (seen.add(name)) result.add(d);
      }
    }
    return result;
  }

  Future<void> _showAddDishDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final timeController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a dish'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Dish name',
                  hintText: 'e.g. Hakka Noodles',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: timeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Time (minutes, optional)',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Just a name is enough — we will fetch the recipe details for you.',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final name = nameController.text.trim();
    if (saved != true || name.isEmpty) return;

    final userDesc =
        descController.text.trim().isEmpty ? null : descController.text.trim();
    final userTime = int.tryParse(timeController.text.trim());

    await _saveDish(name, userDesc: userDesc, userTime: userTime);
  }

  Future<void> _saveDish(
    String name, {
    String? userDesc,
    int? userTime,
  }) async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Flexible(child: Text('Fetching recipe details...')),
          ],
        ),
      ),
    );

    Map<String, dynamic>? details;
    for (var attempt = 0; attempt < 2 && details == null; attempt++) {
      try {
        details = await ref.read(recipeRepositoryProvider).enrichDish(
              name,
              cuisine: _category.cuisine,
              mealType: _activeCategoryKeys.isEmpty
                  ? null
                  : _activeCategoryKeys.first,
            );
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    final fetched = details != null &&
        (details['ingredients'] as List?)?.isNotEmpty == true &&
        (details['instructions'] as String?)?.isNotEmpty == true;

    final dish = _dishFromDetails(
      name,
      userDesc: userDesc,
      userTime: userTime,
      details: details,
    );

    await ref.read(localDishesProvider.notifier).addDish(_category.slug, dish);

    if (!mounted) return;
    Navigator.of(context).pop(); // close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fetched
              ? '"${dish.name}" added with full recipe & ingredients'
              : '"$name" added — recipe details could not be fetched, tap it to retry',
        ),
        backgroundColor: fetched ? Colors.green : Colors.orange,
      ),
    );
  }

  CategoryDish _dishFromDetails(
    String name, {
    String? userDesc,
    int? userTime,
    Map<String, dynamic>? details,
  }) {
    final rawIngredients = (details?['ingredients'] as List?) ?? const [];
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

    final aiTime = (details?['total_time_minutes'] as num?)?.toInt() ?? 0;

    return CategoryDish(
      id: _uuid.v4(),
      name: (details?['name'] ?? name).toString().trim().isNotEmpty
          ? (details?['name'] ?? name).toString().trim()
          : name,
      description: (userDesc != null && userDesc.isNotEmpty)
          ? userDesc
          : (details?['description'] as String?),
      timeMinutes: (userTime != null && userTime > 0) ? userTime : aiTime,
      difficulty: details?['difficulty'] as String?,
      dietType: details?['diet_type'] as String?,
      healthCategory: details?['health_category'] as String?,
      cuisine: details?['cuisine'] as String?,
      mealTypes: details?['meal_types'] != null
          ? List<String>.from(details!['meal_types'] as List)
          : null,
      tags: details?['tags'] != null
          ? List<String>.from(details!['tags'] as List)
          : null,
      ingredients: ingredients,
      instructions: details?['instructions'] as String?,
    );
  }

  void _toggleQuickOnly() {
    setState(() => _quickOnly = !_quickOnly);
  }

  /// Hides a curated or database dish for this category (with undo).
  void _hideDish(String dishName) {
    ref.read(hiddenDishesProvider.notifier).hideDish(_category.slug, dishName);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"$dishName" removed from this category'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => ref
                .read(hiddenDishesProvider.notifier)
                .unhideDish(_category.slug, dishName),
          ),
        ),
      );
  }

  /// Permanently removes a user-added dish from this category (with undo).
  void _deleteLocalDish(CategoryDish dish) {
    ref.read(localDishesProvider.notifier).removeDish(_category.slug, dish.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${dish.name}" deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => ref
                .read(localDishesProvider.notifier)
                .addDish(_category.slug, dish),
          ),
        ),
      );
  }

  bool _matchesFilter(String filter, CategoryDish dish, {RecipeModel? recipe}) {
    final time = recipe?.totalTimeMinutes ?? dish.timeMinutes;
    final mealTypes = recipe?.mealTypes ?? dish.mealTypes ?? const <String>[];
    final dietType = (recipe?.dietType ?? dish.dietType ?? '').toLowerCase();
    final tags = (recipe?.tags ?? dish.tags ?? const <String>[])
        .map((t) => t.toLowerCase());
    final name = dish.name.toLowerCase();
    final desc = (recipe?.description ?? dish.description ?? '').toLowerCase();
    final searchable = [name, desc, ...tags].join(' ');

    switch (filter) {
      case 'Quick (<30 min)':
        return time > 0 && time < 30;
      case 'Healthy':
        return tags.any((t) => t.contains('health')) ||
            searchable.contains('health');
      case 'Breakfast':
        return mealTypes.any((m) => m.toLowerCase().contains('breakfast'));
      case 'Dinner':
        return mealTypes.any((m) => m.toLowerCase().contains('dinner'));
      case 'Veg':
        return dietType.contains('veg') && !dietType.contains('non');
      case 'Non-Veg':
        return dietType.contains('non');
      case 'Sweet':
        return tags.any((t) => t.contains('sweet') || t.contains('dessert')) ||
            mealTypes.any((m) => m.toLowerCase().contains('dessert')) ||
            searchable.contains('sweet');
      case 'Kids':
        return tags.any((t) => t.contains('kid'));
    }
    return true;
  }

  void _showDishInfo(CategoryDish dish, {bool isLocal = false}) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(dish.name, style: theme.textTheme.titleLarge),
                    ),
                    if (isLocal) _badge('Added by you'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dish.description ?? 'A tasty homemade dish.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (dish.timeMinutes > 0)
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 16),
                        label: Text('${dish.timeMinutes} min'),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (dish.difficulty != null)
                      Chip(
                        avatar:
                            const Icon(Icons.local_fire_department, size: 16),
                        label: Text(dish.difficulty!),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (dish.healthCategory != null)
                      Chip(
                        avatar: const Icon(Icons.spa, size: 16),
                        label: Text(dish.healthCategory!),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (dish.dietType != null)
                      Chip(
                        avatar: const Icon(Icons.eco, size: 16),
                        label: Text(dish.dietType!),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (dish.mealTypes != null)
                      ...dish.mealTypes!.map(
                        (m) => Chip(
                          label: Text(m),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                if (dish.ingredients != null &&
                    dish.ingredients!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Ingredients',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...dish.ingredients!.map(
                    (ing) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(ing)),
                        ],
                      ),
                    ),
                  ),
                ],
                if (dish.tags != null && dish.tags!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: dish.tags!
                        .map((t) => Chip(
                              label: Text(t),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.grey[200],
                            ))
                        .toList(),
                  ),
                ],
                if (dish.instructions != null &&
                    dish.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Instructions',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...dish.instructions!
                      .split('\n')
                      .where((s) => s.trim().isNotEmpty)
                      .map(
                        (step) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(step.trim(),
                              style: theme.textTheme.bodyMedium),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.blueGrey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localDishes = ref.watch(localDishesProvider)[_category.slug] ??
        const <CategoryDish>[];
    final hidden = ref.watch(hiddenDishesProvider);

    var curated = _curatedList()
        .where((d) => !(hidden[_category.slug]?.contains(d.name) ?? false))
        .toList();
    var dbDishes = _dbRecipes
        .where((r) => !(hidden[_category.slug]?.contains(r.name) ?? false))
        .toList();
    List<CategoryDish> visibleLocal = localDishes;

    if (_activeCategoryKeys.isNotEmpty) {
      final labels = _activeCategoryKeys.map(_labelFor).toList();
      visibleLocal = localDishes
          .where((d) => labels.every((l) => _matchesFilter(l, d)))
          .toList();
    }
    if (_quickOnly) {
      curated = curated
          .where((d) => d.timeMinutes > 0 && d.timeMinutes < 30)
          .toList();
      visibleLocal = visibleLocal
          .where((d) => d.timeMinutes > 0 && d.timeMinutes < 30)
          .toList();
      dbDishes = dbDishes
          .where((r) => r.totalTimeMinutes > 0 && r.totalTimeMinutes < 30)
          .toList();
    }

    var forYou = _forYouDishes()
        .where((d) => !(hidden[_category.slug]?.contains(d.name) ?? false))
        .toList();
    if (_quickOnly) {
      forYou =
          forYou.where((d) => d.timeMinutes > 0 && d.timeMinutes < 30).toList();
    }

    final totalVisible =
        curated.length + dbDishes.length + visibleLocal.length + forYou.length;
    final hasActiveView = _activeCategoryKeys.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_category.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add a dish',
            onPressed: _showAddDishDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDishDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add dish'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
          children: [
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categoryChips.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return FilterChip(
                      avatar: const Icon(Icons.bolt, size: 14),
                      label: const Text('Quick (<30 min)',
                          style: TextStyle(fontSize: 12)),
                      selected: _quickOnly,
                      onSelected: (_) => _toggleQuickOnly(),
                    );
                  }
                  final (label, key) = _categoryChips[i - 1];
                  return FilterChip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: _activeCategoryKeys.contains(key),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _activeCategoryKeys.add(key);
                        } else {
                          _activeCategoryKeys.remove(key);
                        }
                      });
                      _loadDbDishes(categoryKeys: _activeCategoryKeys);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (hasActiveView || _quickOnly)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$_activeCategorySummary${_quickOnly ? ' · Quick' : ''} · $totalVisible dish(es)',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            if (curated.isEmpty &&
                dbDishes.isEmpty &&
                visibleLocal.isEmpty &&
                forYou.isEmpty &&
                !_isLoadingDb)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    hasActiveView
                        ? 'No dishes match this category.'
                        : 'No dishes here yet. Tap "Add dish" to add your own.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else ...[
              if (forYou.isNotEmpty && !hasActiveView) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text('For you',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary)),
                ),
                ...forYou.map((d) => _curatedTile(theme, d)),
                const Divider(height: 24),
              ],
              ...curated.map((d) => _curatedTile(theme, d)),
              if (_isLoadingDb)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...dbDishes.map((r) => _dbTile(theme, r)),
              ...visibleLocal.map((d) => _localTile(theme, d)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _curatedTile(ThemeData theme, CategoryDish dish) {
    return _unifiedTile(
      theme: theme,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _category.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_category.icon, color: _category.color),
      ),
      title: dish.name,
      subtitle: dish.description ?? '',
      trailingText: dish.timeMinutes > 0 ? '${dish.timeMinutes} min' : '',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dish.timeMinutes > 0)
            Text('${dish.timeMinutes} min',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove',
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => _hideDish(dish.name),
          ),
        ],
      ),
      onTap: () => _showDishInfo(dish),
    );
  }

  Widget _dbTile(ThemeData theme, RecipeModel recipe) {
    return _unifiedTile(
      theme: theme,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: recipe.imageUrl != null
            ? Image.network(recipe.imageUrl!,
                width: 44, height: 44, fit: BoxFit.cover)
            : Container(
                width: 44,
                height: 44,
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant, color: Colors.grey),
              ),
      ),
      title: recipe.name,
      subtitle:
          '${recipe.totalTimeMinutes} min · ${recipe.healthCategory ?? 'Balanced'}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove',
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => _hideDish(recipe.name),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => context.push('/recipe/${recipe.id}'),
    );
  }

  Widget _localTile(ThemeData theme, CategoryDish dish) {
    return _unifiedTile(
      theme: theme,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.bookmark, color: Colors.blueGrey),
      ),
      title: dish.name,
      badge: 'Added by you',
      subtitle: dish.description ?? '',
      trailingText: dish.timeMinutes > 0 ? '${dish.timeMinutes} min' : '',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dish.timeMinutes > 0)
            Text('${dish.timeMinutes} min',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _deleteLocalDish(dish),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            onPressed: () =>
                context.push('/dish', extra: (dish, _category.slug)),
          ),
        ],
      ),
      onTap: () => context.push('/dish', extra: (dish, _category.slug)),
    );
  }

  Widget _unifiedTile({
    required ThemeData theme,
    required Widget leading,
    required String title,
    String? badge,
    String subtitle = '',
    String trailingText = '',
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: leading,
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              _badge(badge),
            ],
          ],
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
        trailing: trailing ??
            (trailingText.isNotEmpty
                ? Text(trailingText,
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.grey))
                : null),
        onTap: onTap,
      ),
    );
  }
}
