import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_preferences_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _foodPreference = 'vegetarian';
  final Set<String> _cuisinePreferences = {'north_indian'};
  String _kitchenProfile = 'basic_north_indian_veg';
  int _adultsCount = 2;
  bool _hasChildren = false;
  int _childrenCount = 0;
  String _language = 'en';
  bool _useSoonReminders = true;
  bool _mealSuggestions = true;
  bool _weeklyReport = true;
  bool _loaded = false;

  static const _keyFoodPref = 'food_preference';
  static const _keyCuisines = 'cuisine_preferences';
  static const _keyKitchenProfile = 'kitchen_profile';
  static const _keyAdultsCount = 'adults_count';
  static const _keyHasChildren = 'has_children';
  static const _keyChildrenCount = 'children_count';
  static const _keyLanguage = 'language';
  static const _keyUseSoonReminders = 'use_soon_reminders';
  static const _keyMealSuggestions = 'meal_suggestions';
  static const _keyWeeklyReport = 'weekly_report';

  final _dietTypes = [
    {'id': 'vegetarian', 'title': 'Vegetarian', 'icon': Icons.eco},
    {'id': 'vegetarian_egg', 'title': 'Vegetarian + Egg', 'icon': Icons.egg_outlined},
    {'id': 'non_vegetarian', 'title': 'Non-Vegetarian', 'icon': Icons.restaurant},
    {'id': 'vegan', 'title': 'Vegan', 'icon': Icons.spa},
  ];

  final _kitchenProfiles = [
    {'id': 'basic_north_indian_veg', 'title': 'Basic North Indian Veg', 'desc': 'Complete North Indian vegetarian kitchen'},
    {'id': 'north_indian_non_veg', 'title': 'North Indian Non-Veg', 'desc': 'North Indian kitchen with eggs & meat'},
    {'id': 'south_indian', 'title': 'South Indian', 'desc': 'Standard South Indian kitchen'},
    {'id': 'mixed_indian', 'title': 'Mixed Indian', 'desc': 'Combination kitchen with common staples'},
    {'id': 'custom', 'title': 'Build Manually', 'desc': 'Start from scratch'},
  ];

  final _cuisines = [
    'north_indian', 'south_indian', 'punjabi', 'bengali', 'odia',
    'gujarati', 'rajasthani', 'maharashtrian', 'indo_chinese', 'continental',
  ];

  final _cuisineNames = {
    'north_indian': 'North Indian', 'south_indian': 'South Indian', 'punjabi': 'Punjabi',
    'bengali': 'Bengali', 'odia': 'Odia', 'gujarati': 'Gujarati',
    'rajasthani': 'Rajasthani', 'maharashtrian': 'Maharashtrian',
    'indo_chinese': 'Indo-Chinese', 'continental': 'Continental',
  };

  final _languageNames = {
    'en': 'English',
    'hi': 'Hindi',
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _foodPreference = prefs.getString(_keyFoodPref) ?? 'vegetarian';
      final savedCuisines = prefs.getStringList(_keyCuisines);
      if (savedCuisines != null && savedCuisines.isNotEmpty) {
        _cuisinePreferences.clear();
        _cuisinePreferences.addAll(savedCuisines);
      }
      _kitchenProfile = prefs.getString(_keyKitchenProfile) ?? 'basic_north_indian_veg';
      _adultsCount = prefs.getInt(_keyAdultsCount) ?? 2;
      _hasChildren = prefs.getBool(_keyHasChildren) ?? false;
      _childrenCount = prefs.getInt(_keyChildrenCount) ?? 0;
      _language = prefs.getString(_keyLanguage) ?? 'en';
      _useSoonReminders = prefs.getBool(_keyUseSoonReminders) ?? true;
      _mealSuggestions = prefs.getBool(_keyMealSuggestions) ?? true;
      _weeklyReport = prefs.getBool(_keyWeeklyReport) ?? true;
      _loaded = true;
    });
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  String get _foodPreferenceLabel {
    return _dietTypes.firstWhere((d) => d['id'] == _foodPreference)['title'] as String;
  }

  String get _cuisinePreferenceLabel {
    return _cuisinePreferences.map((c) => _cuisineNames[c] ?? c).join(', ');
  }

  String get _kitchenProfileLabel {
    return _kitchenProfiles.firstWhere((p) => p['id'] == _kitchenProfile)['title'] as String;
  }

  String get _householdLabel {
    final buffer = StringBuffer();
    buffer.write('$_adultsCount ${_adultsCount == 1 ? 'Adult' : 'Adults'}');
    if (_hasChildren && _childrenCount > 0) {
      buffer.write(', $_childrenCount ${_childrenCount == 1 ? 'Child' : 'Children'}');
    }
    return buffer.toString();
  }

  String get _languageLabel {
    return _languageNames[_language] ?? 'English';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    Text('Profile', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.person, size: 32, color: theme.colorScheme.primary),
                        ),
                        title: const Text('Cook'),
                        subtitle: Text(_foodPreferenceLabel),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Preferences', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _preferenceTile(
                      theme: theme,
                      icon: Icons.restaurant,
                      title: 'Food Preference',
                      subtitle: _foodPreferenceLabel,
                      onTap: () => _showFoodPreferenceSheet(context),
                    ),
                    _preferenceTile(
                      theme: theme,
                      icon: Icons.flag,
                      title: 'Cuisine Preferences',
                      subtitle: _cuisinePreferenceLabel,
                      onTap: () => _showCuisinePreferenceSheet(context),
                    ),
                    _preferenceTile(
                      theme: theme,
                      icon: Icons.kitchen,
                      title: 'Kitchen Profile',
                      subtitle: _kitchenProfileLabel,
                      onTap: () => _showKitchenProfileSheet(context),
                    ),
                    _preferenceTile(
                      theme: theme,
                      icon: Icons.people,
                      title: 'Household',
                      subtitle: _householdLabel,
                      onTap: () => _showHouseholdSheet(context),
                    ),
                    _preferenceTile(
                      theme: theme,
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: _languageLabel,
                      onTap: () => _showLanguageSheet(context),
                    ),
                    const SizedBox(height: 24),
                    Text('Notifications', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Use-Soon Reminders'),
                            value: _useSoonReminders,
                            onChanged: (v) {
                              setState(() => _useSoonReminders = v);
                              _saveBool(_keyUseSoonReminders, v);
                            },
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          SwitchListTile(
                            title: const Text('Meal Suggestions'),
                            value: _mealSuggestions,
                            onChanged: (v) {
                              setState(() => _mealSuggestions = v);
                              _saveBool(_keyMealSuggestions, v);
                            },
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          SwitchListTile(
                            title: const Text('Weekly Report'),
                            value: _weeklyReport,
                            onChanged: (v) {
                              setState(() => _weeklyReport = v);
                              _saveBool(_keyWeeklyReport, v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Account', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _preferenceTile(
                      theme: theme,
                      icon: Icons.shopping_cart,
                      title: 'Shopping List',
                      subtitle: '',
                      onTap: () => context.push('/shopping-list'),
                    ),
                    _preferenceTile(
                      theme: theme,
                      icon: Icons.favorite,
                      title: 'Favorites',
                      subtitle: '',
                      onTap: () => context.push('/favorites'),
                    ),
                    _preferenceTile(
                      theme: theme,
                      icon: Icons.history,
                      title: 'Meal History',
                      subtitle: '',
                      onTap: () => context.push('/meal-history'),
                    ),
                    _preferenceTile(
                      theme: theme,
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'v1.0.0',
                      onTap: () => _showAboutDialog(context),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preferenceTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: theme.textTheme.bodyMedium),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)) : null,
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showFoodPreferenceSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        String selected = _foodPreference;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Food Preference', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ..._dietTypes.map((d) => RadioListTile<String>(
                  value: d['id'] as String,
                  groupValue: selected,
                  title: Text(d['title'] as String),
                  onChanged: (v) {
                    setSheetState(() => selected = v!);
                  },
                )),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => _foodPreference = selected);
                    _saveString(_keyFoodPref, selected);
                    ref.invalidate(foodPreferenceProvider);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCuisinePreferenceSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final selected = Set<String>.from(_cuisinePreferences);
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuisine Preferences', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _cuisines.map((c) => FilterChip(
                        label: Text(_cuisineNames[c] ?? c),
                        selected: selected.contains(c),
                        onSelected: (v) {
                          setSheetState(() {
                            if (v) { selected.add(c); } else { selected.remove(c); }
                          });
                        },
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _cuisinePreferences.clear();
                      _cuisinePreferences.addAll(selected);
                    });
                    _saveStringList(_keyCuisines, selected.toList());
                    ref.invalidate(cuisinePreferencesProvider);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showKitchenProfileSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String selected = _kitchenProfile;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kitchen Profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  ..._kitchenProfiles.map((p) => RadioListTile<String>(
                    value: p['id'] as String,
                    groupValue: selected,
                    title: Text(p['title'] as String),
                    subtitle: Text(p['desc'] as String),
                    onChanged: (v) {
                      setSheetState(() => selected = v!);
                    },
                  )),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() => _kitchenProfile = selected);
                      _saveString(_keyKitchenProfile, selected);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHouseholdSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        int adults = _adultsCount;
        bool hasChildren = _hasChildren;
        int children = _childrenCount;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Household', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Adults: ', style: theme.textTheme.bodyLarge),
                    IconButton(
                      onPressed: adults > 1 ? () => setSheetState(() => adults--) : null,
                      icon: const Icon(Icons.remove_circle),
                    ),
                    Text('$adults', style: theme.textTheme.headlineSmall),
                    IconButton(
                      onPressed: () => setSheetState(() => adults++),
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Children in household'),
                  value: hasChildren,
                  onChanged: (v) => setSheetState(() => hasChildren = v),
                ),
                if (hasChildren)
                  Row(
                    children: [
                      Text('Children: ', style: theme.textTheme.bodyLarge),
                      IconButton(
                        onPressed: children > 0 ? () => setSheetState(() => children--) : null,
                        icon: const Icon(Icons.remove_circle),
                      ),
                      Text('$children', style: theme.textTheme.headlineSmall),
                      IconButton(
                        onPressed: () => setSheetState(() => children++),
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _adultsCount = adults;
                      _hasChildren = hasChildren;
                      _childrenCount = children;
                    });
                    _saveInt(_keyAdultsCount, adults);
                    _saveBool(_keyHasChildren, hasChildren);
                    _saveInt(_keyChildrenCount, children);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        String selected = _language;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Language', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: selected,
                  title: const Text('English'),
                  onChanged: (v) => setSheetState(() => selected = v!),
                ),
                RadioListTile<String>(
                  value: 'hi',
                  groupValue: selected,
                  title: const Text('Hindi'),
                  onChanged: (v) => setSheetState(() => selected = v!),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => _language = selected);
                    _saveString(_keyLanguage, selected);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What to Cook?'),
            SizedBox(height: 8),
            Text('AI Smart Kitchen', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Your personal AI-powered kitchen assistant.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
