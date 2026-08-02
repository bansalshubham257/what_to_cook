import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/api_provider.dart';
import '../../providers/meal_history_provider.dart';
import '../../providers/meal_plan_provider.dart';
import '../../../core/constants/api_constants.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _selectedPeriod = 'week';

  Map<String, dynamic>? _weeklyData;
  Map<String, dynamic>? _monthlyData;
  Map<String, dynamic>? _balanceData;
  Map<String, dynamic>? _cuisineData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Map<String, dynamic> get _stats =>
      _selectedPeriod == 'month' && _monthlyData != null ? _monthlyData! : _weeklyData ?? {};

  int get _totalMeals => _stats['total_meals'] ?? 0;
  double get _balancedPercent => (_stats['balanced_percent'] ?? 0).toDouble();
  double get _moderatePercent => (_stats['moderate_percent'] ?? 0).toDouble();
  double get _indulgentPercent => (_stats['indulgent_percent'] ?? 0).toDouble();
  int get _healthyStreak => _stats['healthy_streak_days'] ?? 0;

  String get _periodLabel => _selectedPeriod == 'week' ? 'Your Last 7 Days' : 'This Month';
  String get _periodSubtitle =>
      'Based on $_totalMeals ${_totalMeals == 1 ? 'meal' : 'meals'} you logged';

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);

      if (_selectedPeriod == 'week') {
        _weeklyData = (await apiClient.get(ApiConstants.weeklyInsights)).data as Map<String, dynamic>;
      } else if (_selectedPeriod == 'month') {
        final now = DateTime.now();
        _monthlyData = (await apiClient.get(
          ApiConstants.monthlyInsights,
          params: {'month': now.month, 'year': now.year},
        )).data as Map<String, dynamic>;
      }

      _balanceData = (await apiClient.get(ApiConstants.balance)).data as Map<String, dynamic>;
      _cuisineData = (await apiClient.get(
        '/insights/cuisine-distribution',
        params: {'days': 30},
      )).data as Map<String, dynamic>;
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mealHistoryProvider, (_, __) => _loadData());
    ref.listen(mealPlanProvider, (_, __) => _loadData());
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Food Insights',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _periodChip('week', '7 Days'),
                              const SizedBox(width: 8),
                              _periodChip('month', 'Month'),
                              const SizedBox(width: 8),
                              _periodChip('custom', 'Custom'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _periodLabel,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _periodSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 20),
                              _healthBar('Balanced', _balancedPercent / 100, Colors.green),
                              const SizedBox(height: 12),
                              _healthBar('Moderate', _moderatePercent / 100, Colors.orange),
                              const SizedBox(height: 12),
                              _healthBar('Indulgent', _indulgentPercent / 100, Colors.red),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _statItem('${_balancedPercent.toInt()}%', 'Balanced', Colors.green),
                                  _statItem('${_moderatePercent.toInt()}%', 'Moderate', Colors.orange),
                                  _statItem('${_indulgentPercent.toInt()}%', 'Indulgent', Colors.red),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$_healthyStreak days',
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      'Healthy Streak',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(Icons.restaurant, color: theme.colorScheme.primary, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$_totalMeals',
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      'Meals Logged',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                       child: Card(
                         child: ListTile(
                           onTap: () => context.push('/meal-plan'),
                           title: Text(
                            'Balance My Week',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _balanceData?['suggestion'] ??
                                'Your logged meals contained more indulgent choices this week.',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        'Cuisine Distribution',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildCuisineDistribution(),
                        ),
                      ),
                    ),
                  ),
                   const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                 ],
               ),
             ),
      ),
    );
  }

  Widget _buildCuisineDistribution() {
    final cuisines = (_cuisineData?['cuisines'] as Map<String, dynamic>?) ?? {};
    if (cuisines.isEmpty) {
      return const Text('No cuisine data available', style: TextStyle(color: Colors.grey));
    }
    final total = cuisines.values.fold<int>(0, (sum, v) => sum + (v as int));
    const colors = [
      Colors.orange, Colors.red, Colors.green, Colors.blue,
      Colors.purple, Colors.teal, Colors.brown, Colors.grey,
    ];
    int ci = 0;
    return Column(
      children: cuisines.entries.map((e) {
        final fraction = total > 0 ? (e.value as int) / total : 0.0;
        final color = colors[ci % colors.length];
        ci++;
        return _cuisineRow(e.key, fraction, color);
      }).toList(),
    );
  }

  Widget _periodChip(String value, String label) {
    final selected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (sel) {
        if (sel) {
          setState(() => _selectedPeriod = value);
          _loadData();
        }
      },
    );
  }

  Widget _healthBar(String label, double fraction, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            const Spacer(),
            Text('${(fraction * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _cuisineRow(String name, double fraction, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(name, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                color: color,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(fraction * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
