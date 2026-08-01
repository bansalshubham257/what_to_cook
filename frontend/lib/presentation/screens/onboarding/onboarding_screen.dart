import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  String _dietType = 'vegetarian';
  final Set<String> _cuisinePreferences = {'north_indian'};
  String _kitchenProfile = 'basic_north_indian_veg';
  int _adultsCount = 2;
  bool _hasChildren = false;
  int _childrenCount = 0;
  final Set<String> _childAgeGroups = {};
  String _language = 'en';

  final _kitchenProfiles = [
    {'id': 'basic_north_indian_veg', 'title': 'Basic North Indian Veg', 'desc': 'Complete North Indian vegetarian kitchen'},
    {'id': 'north_indian_non_veg', 'title': 'North Indian Non-Veg', 'desc': 'North Indian kitchen with eggs & meat'},
    {'id': 'south_indian', 'title': 'South Indian', 'desc': 'Standard South Indian kitchen'},
    {'id': 'mixed_indian', 'title': 'Mixed Indian', 'desc': 'Combination kitchen with common staples'},
    {'id': 'custom', 'title': 'Build Manually', 'desc': 'Start from scratch'},
  ];

  final _dietTypes = [
    {'id': 'vegetarian', 'title': 'Vegetarian', 'icon': Icons.eco},
    {'id': 'vegetarian_egg', 'title': 'Vegetarian + Egg', 'icon': Icons.egg_outlined},
    {'id': 'non_vegetarian', 'title': 'Non-Vegetarian', 'icon': Icons.restaurant},
    {'id': 'vegan', 'title': 'Vegan', 'icon': Icons.spa},
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

  List<Widget> get _pages => [
    _buildHouseholdPage(),
    _buildDietPage(),
    _buildCuisinePage(),
    _buildKitchenProfilePage(),
    _buildSummaryPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
                  const Spacer(),
                  Text('${_currentPage + 1} / ${_pages.length}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: _pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Household', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Text('Number of adults', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(onPressed: _adultsCount > 1 ? () => setState(() => _adultsCount--) : null, icon: const Icon(Icons.remove_circle)),
              Text('$_adultsCount', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(onPressed: () => setState(() => _adultsCount++), icon: const Icon(Icons.add_circle)),
            ],
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Children in household'),
            value: _hasChildren,
            onChanged: (v) => setState(() => _hasChildren = v),
          ),
          if (_hasChildren) ...[
            const SizedBox(height: 16),
            Text('Number of children'),
            Row(
              children: [
                IconButton(onPressed: _childrenCount > 0 ? () => setState(() => _childrenCount--) : null, icon: const Icon(Icons.remove_circle)),
                Text('$_childrenCount', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(onPressed: () => setState(() => _childrenCount++), icon: const Icon(Icons.add_circle)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _ageChip('Toddler', 'toddler'),
                _ageChip('Young Child', 'young_child'),
                _ageChip('Older Child', 'older_child'),
              ],
            ),
          ],
          const Spacer(),
          FilledButton(onPressed: _nextPage, child: const Text('Next')),
        ],
      ),
    );
  }

  Widget _ageChip(String label, String value) {
    final selected = _childAgeGroups.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) { _childAgeGroups.add(value); } else { _childAgeGroups.remove(value); }
        });
      },
    );
  }

  Widget _buildDietPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Food Preference', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('What best describes your diet?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          ...(_dietTypes.map((d) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(d['icon'] as IconData, color: _dietType == d['id'] ? Theme.of(context).colorScheme.primary : null),
              title: Text(d['title'] as String),
              trailing: Radio<String>(
                value: d['id'] as String,
                groupValue: _dietType,
                onChanged: (v) => setState(() => _dietType = v!),
              ),
              onTap: () => setState(() => _dietType = d['id'] as String),
            ),
          ))),
          const Spacer(),
          FilledButton(onPressed: _nextPage, child: const Text('Next')),
        ],
      ),
    );
  }

  Widget _buildCuisinePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cuisine Preferences', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Select your favorite cuisines', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cuisines.map((c) => FilterChip(
                label: Text(_cuisineNames[c] ?? c),
                selected: _cuisinePreferences.contains(c),
                onSelected: (v) {
                  setState(() {
                    if (v) { _cuisinePreferences.add(c); } else { _cuisinePreferences.remove(c); }
                  });
                },
              )).toList(),
            ),
          ),
          FilledButton(onPressed: _nextPage, child: const Text('Next')),
        ],
      ),
    );
  }

  Widget _buildKitchenProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kitchen Profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('What kind of kitchen do you have?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: _kitchenProfiles.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(p['title'] as String),
                  subtitle: Text(p['desc'] as String),
                  trailing: Radio<String>(
                    value: p['id'] as String,
                    groupValue: _kitchenProfile,
                    onChanged: (v) => setState(() => _kitchenProfile = v!),
                  ),
                  onTap: () => setState(() => _kitchenProfile = p['id'] as String),
                ),
              )).toList(),
            ),
          ),
          FilledButton(onPressed: _nextPage, child: const Text('Next')),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("You're all set!", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _summaryTile('Diet', _dietTypes.firstWhere((d) => d['id'] == _dietType)['title'] as String),
          _summaryTile('Cuisines', _cuisinePreferences.map((c) => _cuisineNames[c] ?? c).join(', ')),
          _summaryTile('Kitchen', _kitchenProfiles.firstWhere((p) => p['id'] == _kitchenProfile)['title'] as String),
          _summaryTile('Household', '$_adultsCount adults${_hasChildren ? ", $_childrenCount children" : ""}'),
          const Spacer(),
          Text(
            'Your kitchen will be pre-filled with common ingredients.\nYou can change anything later.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _completeOnboarding, child: const Text('Start Cooking!')),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _completeOnboarding() {
    context.go('/home');
  }
}
