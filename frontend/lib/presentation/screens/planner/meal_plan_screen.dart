import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/category_catalog.dart';
import '../../../data/models/recipe_model.dart';
import '../../providers/api_provider.dart';
import '../../providers/meal_plan_provider.dart';

/// Weekly/monthly meal planner with a calendar-style tabular view. Four slots
/// per day (breakfast, lunch, snacks, dinner); today is highlighted and shown
/// first. Any slot can be replaced by searching across all categories.
class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  static const _slotIcons = {
    'breakfast': Icons.free_breakfast,
    'lunch': Icons.lunch_dining,
    'snacks': Icons.cookie,
    'dinner': Icons.dinner_dining,
  };
  static const _slotColors = {
    'breakfast': Color(0xFFF57C00),
    'lunch': Color(0xFF00897B),
    'snacks': Color(0xFF00838F),
    'dinner': Color(0xFF37474F),
  };

  bool _monthMode = false;
  int _monthOffset = 0;

  DateTime get _monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset, 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = ref.watch(mealPlanProvider);
    final today = DateTime.now();
    final todayNum = dayNumberFor(today);

    final startDay = _monthMode ? dayNumberFor(_monthStart) : todayNum;
    final days = _monthMode
        ? DateTime(_monthStart.year, _monthStart.month + 1, 0).day
        : 7;
    final filled = plan.isEmpty
        ? 0
        : ref.read(mealPlanProvider.notifier).countForRange(startDay, days);
    final total = days * mealPlanSlots.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_monthMode ? 'Month Planner' : 'Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear plan',
            onPressed: plan.isEmpty
                ? null
                : () => ref.read(mealPlanProvider.notifier).clearPlan(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_monthMode ? 'Plan your month' : 'Plan your week',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              filled == 0
                                  ? 'Auto-fill or tap any slot to pick a dish'
                                  : '$filled of $total meals planned',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          final notifier = ref.read(mealPlanProvider.notifier);
                          await notifier.generatePlan(startDay: startDay, days: days);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(_monthMode
                                      ? 'Month plan generated!'
                                      : 'Week plan generated!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                          }
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_monthMode ? 'Auto-fill' : 'Auto-fill'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Week'), icon: Icon(Icons.view_week_outlined)),
                      ButtonSegment(value: true, label: Text('Month'), icon: Icon(Icons.calendar_month_outlined)),
                    ],
                    selected: {_monthMode},
                    onSelectionChanged: (s) => setState(() {
                      _monthMode = s.first;
                      _monthOffset = 0;
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_monthMode)
            _buildMonthView(theme, plan)
          else
            _buildWeekView(theme, plan, today, todayNum),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- week view

  Widget _buildWeekView(ThemeData theme, Map<String, MealPlanEntry> plan,
      DateTime today, int todayNum) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var d = 0; d < 7; d++) ...[
          _buildDayRow(
            theme: theme,
            plan: plan,
            date: today.add(Duration(days: d)),
            dayNumber: todayNum + d,
            isToday: d == 0,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildDayRow({
    required ThemeData theme,
    required Map<String, MealPlanEntry> plan,
    required DateTime date,
    required int dayNumber,
    required bool isToday,
  }) {
    final weekday = DateFormat('EEE').format(date);
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isToday ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? theme.colorScheme.primary : Colors.grey.shade300,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isToday ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(weekday,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday ? theme.colorScheme.onPrimary : Colors.grey[600],
                    )),
                const SizedBox(height: 2),
                Text('${date.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isToday ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    )),
                if (isToday)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Today', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  for (final slot in mealPlanSlots)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _SlotCell(
                          dayNumber: dayNumber,
                          slot: slot,
                          entry: plan['$dayNumber-$slot'],
                          color: _slotColors[slot]!,
                          isToday: isToday,
                          onMade: isToday && plan['$dayNumber-$slot'] != null
                              ? () => _markMade(plan['$dayNumber-$slot']!)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- month view

  Widget _buildMonthView(ThemeData theme, Map<String, MealPlanEntry> plan) {
    final monthLabel = DateFormat('MMMM yyyy').format(_monthStart);
    final firstWeekday = _monthStart.weekday % 7; // 0 = Sunday
    final daysInMonth = DateTime(_monthStart.year, _monthStart.month + 1, 0).day;
    final today = DateTime.now();
    final todayNum = dayNumberFor(today);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _monthOffset--),
            ),
            Expanded(
              child: Text(monthLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _monthOffset++),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((w) => Expanded(
                    child: Center(
                      child: Text(w, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.85,
          ),
          itemCount: 42,
          itemBuilder: (_, index) {
            final dayNum = index - firstWeekday + 1;
            final valid = dayNum >= 1 && dayNum <= daysInMonth;
            if (!valid) return const SizedBox.shrink();
            final date = DateTime(_monthStart.year, _monthStart.month, dayNum);
            final number = dayNumberFor(date);
            final isToday = number == todayNum;
            final daySlots = mealPlanSlots.where((s) => plan.containsKey('$number-$s')).toList();
            return _MonthCell(
              dayNum: dayNum,
              isToday: isToday,
              daySlots: daySlots,
              colors: _slotColors,
              onTap: () => _showDaySheet(date, number),
            );
          },
        ),
        const SizedBox(height: 12),
        Text('Tap a day to plan its meals',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ],
    );
  }

  // ------------------------------------------------------------------- sheets

  Future<void> _showDaySheet(DateTime date, int dayNumber) async {
    final theme = Theme.of(context);
    final notifier = ref.read(mealPlanProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('EEEE, d MMMM').format(date),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final slot in mealPlanSlots)
                _DaySlotTile(
                  dayNumber: dayNumber,
                  slot: slot,
                  entry: notifier.entryFor(dayNumber, slot),
                  icon: _slotIcons[slot]!,
                  color: _slotColors[slot]!,
                  onTap: () => _showSlotPicker(ctx, dayNumber, slot),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSlotPicker(BuildContext context, int dayNumber, String slot) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _SlotPickerSheet(dayNumber: dayNumber, slot: slot),
      ),
    );
  }

  Future<void> _markMade(MealPlanEntry entry) async {
    await markMealMade(ref, entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Nice! ${entry.name} marked as made today'),
        backgroundColor: Colors.green,
      ));
  }
}

// -------------------------------------------------------------------- widgets

class _SlotCell extends StatelessWidget {
  final int dayNumber;
  final String slot;
  final MealPlanEntry? entry;
  final Color color;
  final bool isToday;
  final VoidCallback? onMade;

  const _SlotCell({
    required this.dayNumber,
    required this.slot,
    required this.entry,
    required this.color,
    required this.isToday,
    this.onMade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = entry != null;
    final made = entry?.made ?? false;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (ctx) => FractionallySizedBox(
            heightFactor: 0.85,
            child: _SlotPickerSheet(dayNumber: dayNumber, slot: slot),
          ),
        );
      },
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        decoration: BoxDecoration(
          color: made
              ? Colors.green.withValues(alpha: 0.18)
              : (filled ? color.withValues(alpha: 0.12) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: made ? Colors.green : Colors.grey.shade400,
            width: made ? 1.2 : 0.8,
          ),
        ),
        child: filled
            ? Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_slotIcon(slot),
                            size: 12,
                            color: made ? const Color(0xFF1B5E20) : color),
                        const SizedBox(height: 2),
                        Text(
                          entry!.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            decoration:
                                made ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onMade != null && !made)
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: onMade,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              size: 11, color: Colors.white),
                        ),
                      ),
                    )
                  else if (made)
                    const Align(
                      alignment: Alignment.topRight,
                      child: Icon(Icons.check_circle,
                          size: 16, color: Colors.green),
                    ),
                ],
              )
            : Center(
                child: Icon(Icons.add, size: 16, color: Colors.grey.shade400),
              ),
      ),
    );
  }

  IconData _slotIcon(String slot) {
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

class _DaySlotTile extends StatelessWidget {
  final int dayNumber;
  final String slot;
  final MealPlanEntry? entry;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DaySlotTile({
    required this.dayNumber,
    required this.slot,
    required this.entry,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = entry != null;
    final made = entry?.made ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: filled ? color.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
          child: Icon(icon, size: 20, color: made ? Colors.green : (filled ? color : Colors.grey)),
        ),
        title: filled
            ? Text(entry!.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: made ? TextDecoration.lineThrough : null))
            : Text('Tap to add ${mealPlanSlotLabels[slot]!.toLowerCase()}',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        subtitle: made
            ? Text('Made today',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF1B5E20)))
            : (filled && entry!.timeMinutes > 0
                ? Text('${entry!.timeMinutes} min', style: theme.textTheme.bodySmall)
                : null),
        trailing: made
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.add_circle_outline),
        onTap: onTap,
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final int dayNum;
  final bool isToday;
  final List<String> daySlots;
  final Map<String, Color> colors;
  final VoidCallback onTap;

  const _MonthCell({
    required this.dayNum,
    required this.isToday,
    required this.daySlots,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: daySlots.isNotEmpty
                ? (isToday ? theme.colorScheme.primary : Colors.grey.shade400)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNum',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isToday ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final slot in mealPlanSlots)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      daySlots.contains(slot)
                          ? Icons.circle
                          : Icons.circle_outlined,
                      size: 6,
                      color: daySlots.contains(slot)
                          ? (isToday ? theme.colorScheme.onPrimary : colors[slot])
                          : (isToday
                              ? theme.colorScheme.onPrimary.withValues(alpha: 0.4)
                              : Colors.grey.shade300),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet picker: search across curated dishes and database recipes, or
/// remove the currently planned dish.
class _SlotPickerSheet extends ConsumerStatefulWidget {
  final int dayNumber;
  final String slot;

  const _SlotPickerSheet({required this.dayNumber, required this.slot});

  @override
  ConsumerState<_SlotPickerSheet> createState() => _SlotPickerSheetState();
}

class _SlotPickerSheetState extends ConsumerState<_SlotPickerSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<RecipeModel> _dbResults = [];
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  MealPlanEntry? get _current =>
      ref.read(mealPlanProvider.notifier).entryFor(widget.dayNumber, widget.slot);

  List<(CategoryDish, String)> get _curatedOptions {
    final q = _search.text.trim().toLowerCase();
    final all = mealPlanOptions();
    if (q.isEmpty) return all;
    return all.where((o) => o.$1.name.toLowerCase().contains(q)).toList();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    final q = _search.text.trim();
    if (q.isEmpty) {
      setState(() {
        _dbResults = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final repo = ref.read(recipeRepositoryProvider);
      try {
        final results = await repo.searchRecipes(q, limit: 20);
        if (mounted) setState(() => _dbResults = results);
      } catch (_) {
        if (mounted) setState(() => _dbResults = []);
      }
      if (mounted) setState(() => _searching = false);
    });
    setState(() => _searching = true);
  }

  void _pickCurated(CategoryDish dish, String slug) async {
    final notifier = ref.read(mealPlanProvider.notifier);
    await notifier.setEntry(
      widget.dayNumber,
      widget.slot,
      MealPlanEntry(
        dayNumber: widget.dayNumber,
        slot: widget.slot,
        recipeId: dish.id,
        name: dish.name,
        timeMinutes: dish.timeMinutes,
        categorySlug: slug,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  void _pickRecipe(RecipeModel recipe) async {
    final notifier = ref.read(mealPlanProvider.notifier);
    await notifier.setEntry(
      widget.dayNumber,
      widget.slot,
      MealPlanEntry(
        dayNumber: widget.dayNumber,
        slot: widget.slot,
        recipeId: recipe.id,
        name: recipe.name,
        timeMinutes: recipe.totalTimeMinutes,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _current;
    final curated = _curatedOptions;
    final query = _search.text.trim();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              '${mealPlanSlotLabels[widget.slot]} · ${DateFormat('EEEE, d MMMM').format(dateFor(widget.dayNumber))}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (current != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Chip(
                      avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      label: Text(current.name, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(mealPlanProvider.notifier)
                          .removeEntry(widget.dayNumber, widget.slot);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Remove', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              controller: _search,
              autofocus: false,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search all categories...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                if (curated.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('Curated dishes',
                        style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
                  ),
                  ...curated.map((o) {
                    final (dish, slug) = o;
                    final isCurrent = current?.recipeId == dish.id;
                    return ListTile(
                      dense: true,
                      leading: Icon(specialIcon(slug), size: 22, color: specialColor(slug)),
                      title: Text(dish.name),
                      subtitle: dish.timeMinutes > 0
                          ? Text('${dish.timeMinutes} min · ${specialCategoryLabel(slug)}')
                          : Text(specialCategoryLabel(slug)),
                      trailing: isCurrent ? const Icon(Icons.check, color: Colors.green) : null,
                      onTap: () => _pickCurated(dish, slug),
                    );
                  }),
                ],
                if (query.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(_searching
                        ? 'Searching...'
                        : 'From database${_dbResults.isEmpty ? ' (no matches)' : ''}',
                        style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
                  ),
                  ..._dbResults.map(
                    (r) => ListTile(
                      dense: true,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: r.imageUrl != null
                            ? Image.network(r.imageUrl!, width: 32, height: 32, fit: BoxFit.cover)
                            : Container(
                                width: 32,
                                height: 32,
                                color: Colors.grey[200],
                                child: const Icon(Icons.restaurant, size: 16),
                              ),
                      ),
                      title: Text(r.name),
                      subtitle: Text('${r.totalTimeMinutes} min · ${r.healthCategory ?? 'Balanced'}'),
                      onTap: () => _pickRecipe(r),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData specialIcon(String slug) {
  for (final c in kSpecialCategories) {
    if (c.slug == slug) return c.icon;
  }
  return Icons.restaurant_menu;
}

Color specialColor(String slug) {
  for (final c in kSpecialCategories) {
    if (c.slug == slug) return c.color;
  }
  return Colors.grey;
}
