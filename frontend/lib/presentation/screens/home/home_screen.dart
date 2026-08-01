import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/home_suggestions_provider.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/suggestions_providers.dart';
import '../../widgets/notes_card.dart';

/// Simplified Home hub: two quick suggestions, links to every feature, and a
/// checklist/notes card.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final suggestions = ref.watch(homeSuggestionsProvider);
    final plan = ref.watch(mealPlanProvider);

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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Good ${_getGreeting()},',
                                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                              Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.person, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Today', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildTodayPlan(ref, context, theme, plan, suggestions.value),
                    const SizedBox(height: 10),
                    _buildRandomSuggestion(context, theme, suggestions.value),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('Everything', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _LinkTile(link: _links(context)[i]),
                  childCount: _links(context).length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: NotesCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPlan(WidgetRef ref, BuildContext context, ThemeData theme,
      Map<String, MealPlanEntry> plan, HomeSuggestions? suggestions) {
    final today = dayNumberFor(DateTime.now());
    final currentSlot = mealForCurrentTime();
    final entries = {
      for (final slot in mealPlanSlots)
        slot: plan['$today-$slot'],
    };

    if (entries.values.every((entry) => entry == null)) {
      return _SuggestionCard(
        icon: Icons.event_note,
        color: theme.colorScheme.primary,
        title: suggestions?.hasPlan == true ? 'Open your meal planner' : 'Nothing planned yet',
        subtitle: suggestions?.hasPlan == true
            ? 'Review your upcoming meals for the week.'
            : 'Plan your week of meals in the planner.',
        actionLabel: 'Open planner',
        onTap: () => context.push('/meal-plan'),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final slot in mealPlanSlots)
              _TodayMealTile(
                entry: entries[slot],
                slot: slot,
                active: slot == currentSlot,
                onOpen: entries[slot] == null
                    ? () => context.push('/meal-plan')
                    : () => _openPlanEntry(context, entries[slot]!),
                onMade: entries[slot] == null || entries[slot]!.made
                    ? null
                    : () => _markMade(ref, context, entries[slot]!),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _markMade(
      WidgetRef ref, BuildContext context, MealPlanEntry entry) async {
    await markMealMade(ref, entry);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Nice! ${entry.name} marked as made today'),
        backgroundColor: Colors.green,
      ));
  }

  Widget _buildRandomSuggestion(
      BuildContext context, ThemeData theme, HomeSuggestions? suggestions) {
    final dish = suggestions?.randomDish;
    if (dish == null) {
      return _SuggestionCard(
        icon: Icons.casino,
        color: theme.colorScheme.tertiary,
        title: 'Add a dish to get suggestions',
        subtitle: 'Add dishes in Explore or pick cuisines in Profile.',
        actionLabel: 'Explore',
        onTap: () => context.push('/explore'),
      );
    }
    final time = dish.timeMinutes > 0 ? ' · ${dish.timeMinutes} min' : '';
    return _SuggestionCard(
      icon: Icons.casino,
      color: theme.colorScheme.tertiary,
      title: dish.name,
      subtitle: '${dish.description ?? 'A tasty pick for you'}$time',
      actionLabel: 'Surprise me again',
      onTap: () => context.push('/dish', extra: (dish, suggestions!.randomSlug)),
    );
  }

  void _openPlanEntry(BuildContext context, MealPlanEntry entry) {
    if (entry.categorySlug == null) {
      context.push('/recipe/${entry.recipeId}');
      return;
    }
    final dish = curatedDishById(entry.recipeId);
    if (dish == null) return;
    context.push('/dish', extra: (dish, entry.categorySlug));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  static List<_Link> _links(BuildContext context) => [
        _Link(Icons.explore, 'Explore', const Color(0xFF1565C0), () => context.push('/explore')),
        _Link(Icons.event_note, 'Planner', const Color(0xFFF57C00), () => context.push('/meal-plan')),
        _Link(Icons.bar_chart, 'Insights', const Color(0xFF2E7D32), () => context.go('/insights')),
        _Link(Icons.kitchen, 'Kitchen', const Color(0xFF6A1B9A), () => context.go('/kitchen')),
        _Link(Icons.favorite, 'Favorites', Colors.red, () => context.push('/favorites')),
        _Link(Icons.shopping_cart, 'Shopping', const Color(0xFF00838F), () => context.push('/shopping-list')),
        _Link(Icons.history, 'Meal History', const Color(0xFF37474F), () => context.push('/meal-history')),
        _Link(Icons.person, 'Profile', const Color(0xFFAD1457), () => context.go('/profile')),
      ];
}

class _Link {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Link(this.icon, this.label, this.color, this.onTap);
}

class _TodayMealTile extends StatelessWidget {
  final MealPlanEntry? entry;
  final String slot;
  final bool active;
  final VoidCallback onOpen;
  final VoidCallback? onMade;

  const _TodayMealTile({
    required this.entry,
    required this.slot,
    required this.active,
    required this.onOpen,
    this.onMade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = mealPlanSlotLabels[slot] ?? slot;
    final color = entry?.made == true
        ? Colors.green
        : active
            ? theme.colorScheme.primary
            : theme.colorScheme.outline;
    return Material(
      color: active
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.72)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_slotIcon(slot), color: color, size: 18),
                  ),
                  const Spacer(),
                  if (entry?.made == true)
                    const Icon(Icons.check_circle, color: Colors.green, size: 22)
                  else if (onMade != null)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton.filledTonal(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Mark made',
                        onPressed: onMade,
                        icon: const Icon(Icons.check, size: 17),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: active ? theme.colorScheme.primary : Colors.grey[700],
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                  if (active) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Now',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                entry?.name ?? 'Not planned',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                  decoration: entry?.made == true ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _slotIcon(String slot) {
    switch (slot) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'snacks':
        return Icons.cookie;
      default:
        return Icons.dinner_dining;
    }
  }
}

class _LinkTile extends StatelessWidget {
  final _Link link;
  const _LinkTile({required this.link});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: link.onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: link.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(link.icon, color: link.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            link.label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
