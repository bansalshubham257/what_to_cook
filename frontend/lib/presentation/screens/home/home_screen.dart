import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/home_suggestions_provider.dart';
import '../../providers/local_dishes_provider.dart';
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
    final l10n = AppLocalizations.of(context);
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
                              Text(_greeting(l10n),
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(color: Colors.grey)),
                              Text(
                                  DateFormat('EEEE, MMMM d')
                                      .format(DateTime.now()),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.person,
                                color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.today,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildTodayPlan(
                        ref, context, theme, plan, suggestions.value, l10n),
                    const SizedBox(height: 10),
                    _buildRandomSuggestion(
                        context, theme, suggestions.value, l10n),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(l10n.everything,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
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

  Widget _buildTodayPlan(
      WidgetRef ref,
      BuildContext context,
      ThemeData theme,
      Map<String, MealPlanEntry> plan,
      HomeSuggestions? suggestions,
      AppLocalizations l10n) {
    final today = dayNumberFor(DateTime.now());
    final currentSlot = mealForCurrentTime();
    final entries = {
      for (final slot in mealPlanSlots) slot: plan['$today-$slot'],
    };

    if (entries.values.every((entry) => entry == null)) {
      return _SuggestionCard(
        icon: Icons.event_note,
        title: suggestions?.hasPlan == true
            ? l10n.openYourMealPlanner
            : l10n.nothingPlannedYet,
        subtitle: suggestions?.hasPlan == true
            ? l10n.reviewUpcomingMeals
            : l10n.planYourWeek,
        actionLabel: l10n.openPlanner,
        onTap: () => context.push('/meal-plan'),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 106,
          ),
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
                    : () => _openPlanEntry(context, ref, entries[slot]!),
                onMade: entries[slot] == null || entries[slot]!.made
                    ? null
                    : () => _markMade(ref, context, entries[slot]!, l10n),
                onReSync: entries[slot]?.made == true
                    ? () => _reSync(ref, context, entries[slot]!, l10n)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _markMade(WidgetRef ref, BuildContext context,
      MealPlanEntry entry, AppLocalizations l10n) async {
    final synced = await markMealMade(ref, entry);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(synced
            ? l10n.niceMarkedAsMade(entry.name)
            : 'Marked as made — but couldn\'t sync to insights yet. Tap the ✓ to retry.'),
        backgroundColor: synced ? Colors.green : Colors.orange,
      ));
  }

  Future<void> _reSync(WidgetRef ref, BuildContext context, MealPlanEntry entry,
      AppLocalizations l10n) async {
    final synced = await reLogMeal(ref, entry);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(synced
            ? 'Synced to insights'
            : 'Could not sync to insights. Try again.'),
        backgroundColor: synced ? Colors.green : Colors.orange,
      ));
  }

  Widget _buildRandomSuggestion(BuildContext context, ThemeData theme,
      HomeSuggestions? suggestions, AppLocalizations l10n) {
    final dish = suggestions?.randomDish;
    if (dish == null) {
      return _SuggestionCard(
        icon: Icons.casino,
        title: l10n.addDishToGetSuggestions,
        subtitle: l10n.addDishesInExplore,
        actionLabel: l10n.exploreTitle,
        onTap: () => context.push('/explore'),
      );
    }
    final time =
        dish.timeMinutes > 0 ? ' · ${dish.timeMinutes} ${l10n.minLabel}' : '';
    return _SuggestionCard(
      icon: Icons.casino,
      title: dish.name,
      subtitle: '${dish.description ?? l10n.aTastyPickForYou}$time',
      actionLabel: l10n.surpriseMeAgain,
      onTap: () =>
          context.push('/dish', extra: (dish, suggestions!.randomSlug)),
    );
  }

  void _openPlanEntry(
      BuildContext context, WidgetRef ref, MealPlanEntry entry) {
    final dish = curatedDishById(entry.recipeId);
    if (dish != null) {
      context.push('/dish', extra: (dish, entry.categorySlug ?? entry.slot));
      return;
    }
    final slug = entry.categorySlug;
    if (slug == null) {
      context.push('/recipe/${entry.recipeId}');
      return;
    }
    final local = ref
        .read(localDishesProvider)[slug]
        ?.where((d) => d.id == entry.recipeId)
        .firstOrNull;
    if (local != null) {
      context.push('/dish', extra: (local, slug));
    }
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  static List<_Link> _links(BuildContext context) => [
        _Link(Icons.explore, 'Explore', const Color(0xFF1565C0),
            () => context.push('/explore')),
        _Link(Icons.event_note, 'Planner', const Color(0xFFF57C00),
            () => context.push('/meal-plan')),
        _Link(Icons.bar_chart, 'Insights', const Color(0xFF2E7D32),
            () => context.go('/insights')),
        _Link(Icons.kitchen, 'Kitchen', const Color(0xFF6A1B9A),
            () => context.go('/kitchen')),
        _Link(Icons.favorite, 'Favorites', Colors.red,
            () => context.push('/favorites')),
        _Link(Icons.shopping_cart, 'Shopping', const Color(0xFF00838F),
            () => context.push('/shopping-list')),
        _Link(Icons.history, 'Meal History', const Color(0xFF37474F),
            () => context.push('/meal-history')),
        _Link(Icons.person, 'Profile', const Color(0xFFAD1457),
            () => context.go('/profile')),
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
  final VoidCallback? onReSync;

  const _TodayMealTile({
    required this.entry,
    required this.slot,
    required this.active,
    required this.onOpen,
    this.onMade,
    this.onReSync,
  });

  static const _slotColors = {
    'breakfast': Color(0xFFF59E0B),
    'lunch': Color(0xFF10B981),
    'snacks': Color(0xFFEC4899),
    'dinner': Color(0xFF6366F1),
  };

  static const _slotIcons = {
    'breakfast': Icons.free_breakfast_outlined,
    'lunch': Icons.restaurant_outlined,
    'snacks': Icons.emoji_food_beverage_outlined,
    'dinner': Icons.nights_stay_outlined,
  };

  static const _slotTimes = {
    'breakfast': '7–10 AM',
    'lunch': '12–3 PM',
    'snacks': '4–6 PM',
    'dinner': '7–10 PM',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final label = mealPlanSlotLabels[slot] ?? slot;
    final color = _slotColors[slot] ?? theme.colorScheme.primary;
    final icon = _slotIcons[slot] ?? Icons.restaurant;
    final time = _slotTimes[slot] ?? '';
    final isMade = entry?.made == true;
    final isPlanned = entry != null;

    final bgGradient = isPlanned
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              Color.lerp(color, Colors.black, 0.38)!,
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              theme.colorScheme.surface.withValues(alpha: 0.3),
            ],
          );
    final onColor =
        isPlanned ? Colors.white : theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? Colors.white.withValues(alpha: 0.75)
              : Colors.transparent,
          width: 1.6,
        ),
        boxShadow: active && isPlanned
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isPlanned
                            ? Colors.white.withValues(alpha: 0.22)
                            : color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 15, color: onColor),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isPlanned
                                ? Colors.white.withValues(alpha: 0.92)
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                    const SizedBox(width: 4),
                    if (isMade)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 22, minHeight: 22),
                        tooltip: 'Sync to insights',
                        onPressed: onReSync,
                        icon: const Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                      )
                    else if (onMade != null)
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: IconButton.filledTonal(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: color,
                            padding: EdgeInsets.zero,
                          ),
                          tooltip: l10n.markMade,
                          onPressed: onMade,
                          icon: const Icon(Icons.check, size: 14),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry?.name ?? l10n.notPlanned,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.15,
                    color: isPlanned ? Colors.white : Colors.grey,
                    decoration: isMade ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (active && isPlanned) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(l10n.now,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                            )),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isPlanned
                                ? Colors.white.withValues(alpha: 0.85)
                                : Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    const Spacer(),
                    if (isMade)
                      Text(l10n.done,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[700])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}
