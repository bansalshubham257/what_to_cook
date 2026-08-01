import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/recipe_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../providers/api_provider.dart';
import '../../providers/favorites_provider.dart';

/// Full-screen Explore page (opened from Home). Keeps the search + filters,
/// adds a simple meal-chip menu (breakfast/lunch/snacks/dinner/sweets/special)
/// and still shows cuisines + "buy missing items" opportunities.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();

  List<RecipeModel> _searchResults = [];
  bool _isSearching = false;

  List<Map<String, dynamic>> _missingOpportunities = [];
  bool _isLoadingMissing = true;

  final Set<String> _selectedFilters = {};
  bool _favoritesOnly = false;

  List<Map<String, dynamic>> _cuisines = [];
  bool _isLoadingCuisines = true;

  final _quickFilters = ['Quick (<30 min)', 'Healthy', 'Breakfast', 'Dinner', 'Veg', 'Non-Veg', 'Sweet', 'Kids'];

  static const _browseCategories = <(IconData, String, Color, String)>[
    (Icons.free_breakfast, 'Breakfast', Color(0xFFF57C00), 'breakfast'),
    (Icons.lunch_dining, 'Lunch', Color(0xFF00897B), 'lunch'),
    (Icons.cookie, 'Snacks', Color(0xFF00838F), 'snacks'),
    (Icons.dinner_dining, 'Dinner', Color(0xFF37474F), 'dinner'),
    (Icons.icecream, 'Sweets', Color(0xFF6A1B9A), 'sweet'),
    (Icons.star, 'Special Dishes', Color(0xFFC2185B), '_special'),
  ];

  static const _cuisineIcons = <String, IconData>{
    'north_indian': Icons.landscape,
    'south_indian': Icons.local_florist,
    'punjabi': Icons.whatshot,
    'bengali': Icons.water_drop,
    'odia': Icons.waves,
    'gujarati': Icons.emoji_events,
    'rajasthani': Icons.sunny,
    'maharashtrian': Icons.missed_video_call,
    'indo_chinese': Icons.ramen_dining,
    'continental': Icons.public,
    'kashmiri': Icons.ac_unit,
    'awadhi': Icons.diamond,
    'bihari': Icons.layers,
    'himachali': Icons.terrain,
    'haryanvi': Icons.grain,
    'goan': Icons.beach_access,
    'kerala': Icons.nature,
    'tamil': Icons.celebration,
    'telugu': Icons.local_fire_department,
    'karnataka': Icons.forest,
    'assamese': Icons.water,
    'nepali': Icons.flag,
    'sindhi': Icons.language,
    'parsi': Icons.flare,
    'hyderabadi': Icons.restaurant_menu,
    'muglai': Icons.fastfood,
  };

  static const _cuisineColors = <Color>[
    Color(0xFFFF6F00), Color(0xFF2E7D32), Color(0xFFC62828), Color(0xFF1565C0),
    Color(0xFFF9A825), Color(0xFF6A1B9A), Color(0xFF37474F), Color(0xFFE65100),
    Color(0xFF00838F), Color(0xFF5D4037), Color(0xFF7B1FA2), Color(0xFF00695C),
    Color(0xFFD84315), Color(0xFF283593), Color(0xFFAD1457), Color(0xFF33691E),
    Color(0xFF4E342E), Color(0xFF0277BD),
  ];

  (IconData, Color) _cuisineStyle(String name) {
    final icon = _cuisineIcons[name] ?? Icons.restaurant;
    var hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final color = _cuisineColors[hash % _cuisineColors.length];
    return (icon, color);
  }

  String _filterKeyFor(String label) {
    switch (label) {
      case 'Quick (<30 min)':
        return '_quick';
      case 'Healthy':
        return 'healthy';
      case 'Breakfast':
        return 'breakfast';
      case 'Dinner':
        return 'dinner';
      case 'Veg':
        return 'veg';
      case 'Non-Veg':
        return 'nonveg';
      case 'Sweet':
        return 'sweet';
      case 'Kids':
        return 'kids';
    }
    return label;
  }

  String _filtersParam() => _selectedFilters.map(_filterKeyFor).join(',');

  @override
  void initState() {
    super.initState();
    _loadMissingOpportunities();
    _loadCuisines();
  }

  Future<void> _loadCuisines() async {
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final cuisines = await repo.getCuisines();
      if (mounted) setState(() => _cuisines = cuisines);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingCuisines = false);
  }

  Future<void> _toggleFavorite(String recipeId, {String? recipeName}) async {
    final ok = await ref.read(favoritesProvider.notifier).toggle(recipeId);
    if (mounted) {
      final nowFavorite = ref.read(favoritesProvider).contains(recipeId);
      final name = recipeName != null && recipeName.isNotEmpty ? ' "$recipeName"' : '';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(ok
                ? (nowFavorite ? 'Added$name to favorites' : 'Removed$name from favorites')
                : 'Could not update favorite'),
            backgroundColor: ok ? (nowFavorite ? Colors.red : Colors.grey[700]) : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _showResults => _searchResults.isNotEmpty || _isSearching;

  Future<void> _loadMissingOpportunities() async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final data = await repo.getMissingIngredientOpportunities();
      if (mounted) setState(() => _missingOpportunities = data);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingMissing = false);
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedFilters.isEmpty && !_favoritesOnly) return;

    setState(() => _isSearching = true);

    try {
      final repo = ref.read(recipeRepositoryProvider);
      final filterTerms = _selectedFilters.map((f) {
        if (f == 'Quick (<30 min)') return 'quick';
        return f.toLowerCase();
      }).join(' ');
      final fullQuery = [if (query.isNotEmpty) query, if (filterTerms.isNotEmpty) filterTerms].join(' ');
      final results = await repo.searchRecipes(fullQuery, favorites: _favoritesOnly);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    }
    if (mounted) setState(() => _isSearching = false);
  }

  Future<void> _addToShoppingList(Map<String, dynamic> opportunity) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final missing = (opportunity['missing_ingredients'] as List<dynamic>?) ?? [];
      for (final ingredient in missing) {
        await apiClient.post(ApiConstants.shoppingAdd, data: {
          'name': ingredient,
          'quantity': '1',
          'unit': 'piece',
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${missing.length} item(s) to shopping list'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add items'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showVoiceSearch() async {
    final textController = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search by voice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tell us what you have or want, e.g. "i have dal, aloo, paneer"',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. dal aloo paneer',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    if (query == null || query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final results = await repo.naturalSearch(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    }
    if (mounted) setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoriteIds = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: Colors.red),
            tooltip: 'My Favorites',
            onPressed: () => context.push('/favorites'),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search recipes...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: _showResults
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchResults = [];
                                    _isSearching = false;
                                    _selectedFilters.clear();
                                    _favoritesOnly = false;
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.mic),
                                onPressed: _showVoiceSearch,
                              ),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickFilters.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return FilterChip(
                              avatar: Icon(
                                Icons.favorite,
                                size: 14,
                                color: _favoritesOnly ? Colors.white : Colors.red,
                              ),
                              label: const Text('My Favorites', style: TextStyle(fontSize: 12)),
                              selected: _favoritesOnly,
                              selectedColor: Colors.red,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: _favoritesOnly ? Colors.white : null,
                              ),
                              onSelected: (sel) {
                                setState(() => _favoritesOnly = sel);
                                _performSearch();
                              },
                            );
                          }
                          final f = _quickFilters[i - 1];
                          return FilterChip(
                            label: Text(f, style: const TextStyle(fontSize: 12)),
                            selected: _selectedFilters.contains(f),
                            onSelected: (sel) {
                              setState(() {
                                if (sel) {
                                  _selectedFilters.add(f);
                                } else {
                                  _selectedFilters.remove(f);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    if (_selectedFilters.isNotEmpty && !_showResults)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Filters: ${_selectedFilters.join(', ')} · tap a category or cuisine to see filtered dishes',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_showResults) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    _isSearching ? 'Searching...' : 'Results (${_searchResults.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (_isSearching)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_searchResults.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No recipes found')),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final recipe = _searchResults[i];
                        final isFav = favoriteIds.contains(recipe.id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
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
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    recipe.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isFav) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '★ Favourite',
                                      style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '${recipe.totalTimeMinutes} min · ${recipe.difficulty ?? "Easy"}',
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(recipe.healthCategory ?? 'Balanced', style: const TextStyle(fontSize: 10)),
                                  backgroundColor: Colors.green[50],
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? Colors.red : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => _toggleFavorite(recipe.id, recipeName: recipe.name),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            onTap: () => context.push('/recipe/${recipe.id}'),
                          ),
                        );
                      },
                      childCount: _searchResults.length,
                    ),
                  ),
                ),
            ],
            if (!_showResults) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text('Browse by meal', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final (icon, label, color, slug) = _browseCategories[i];
                      return _BrowseTile(
                        icon: icon,
                        color: color,
                        label: label,
                        onTap: () {
                          if (slug == '_special') {
                            context.push('/explore-special');
                          } else {
                            context.push('/category/$slug');
                          }
                        },
                      );
                    },
                    childCount: _browseCategories.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text('Cuisines', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
              if (_isLoadingCuisines)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else
                SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i == 0) {
                        return _CuisineTile(
                          icon: Icons.favorite,
                          color: Colors.red,
                          label: 'My Favorites',
                          onTap: () => context.push('/favorites'),
                        );
                      }
                      final cuisine = _cuisines[i - 1];
                      final name = cuisine['name'] as String;
                      final displayName = cuisine['display_name'] as String;
                      final count = cuisine['recipe_count'] as int? ?? 0;
                      final (icon, color) = _cuisineStyle(name);
                      return _CuisineTile(
                        icon: icon,
                        color: color,
                        label: displayName,
                        badge: count,
                        onTap: () => context.push(
                          '/category/cuisine-$name'
                          '?label=${Uri.encodeComponent(displayName)}'
                          '&cuisine=$name'
                          '&filters=${Uri.encodeComponent(_filtersParam())}',
                        ),
                      );
                    },
                    childCount: _cuisines.length + 1,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Buy Missing Items & Unlock Meals',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: _isLoadingMissing
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    : _missingOpportunities.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: Text('No missing items found')),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                final opp = _missingOpportunities[i];
                                final recipeName = opp['recipe_name'] ?? '';
                                final missingCount = opp['missing_count'] ?? 0;
                                final missingList =
                                    (opp['missing_ingredients'] as List<dynamic>?)?.join(', ') ?? '';
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: const Icon(Icons.lock_open, color: Colors.orange),
                                    title: Text(
                                      'Buy ${missingCount > 0 ? '$missingCount items' : 'items'} → Unlock $recipeName',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(missingList, style: theme.textTheme.bodySmall),
                                    trailing: TextButton(
                                      onPressed: () => _addToShoppingList(opp),
                                      child: const Text('Add to List'),
                                    ),
                                  ),
                                );
                              },
                              childCount: _missingOpportunities.length,
                            ),
                          ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }
}

class _BrowseTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _BrowseTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CuisineTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int? badge;
  final VoidCallback onTap;

  const _CuisineTile({
    required this.icon,
    required this.color,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (badge != null) ...[
            const SizedBox(height: 2),
            Text(
              '$badge recipes',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
