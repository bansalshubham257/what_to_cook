import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/category_catalog.dart';
import '../../providers/local_dishes_provider.dart';
import '../../widgets/recipe_video_links_section.dart';

/// Full detail page for a user-added (local) dish. Mirrors the database recipe
/// page: shows info chips, ingredients, instructions and a Start Cooking mode.
class DishDetailScreen extends ConsumerStatefulWidget {
  final CategoryDish dish;
  final String categorySlug;
  const DishDetailScreen({super.key, required this.dish, required this.categorySlug});

  @override
  ConsumerState<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends ConsumerState<DishDetailScreen> {
  bool _showCookingMode = false;
  int _currentStep = 0;

  CategoryDish get dish => widget.dish;

  List<String> get _steps => (dish.instructions ?? '')
      .split('\n')
      .where((s) => s.trim().isNotEmpty)
      .map((s) => s.trim())
      .toList();

  Future<void> _deleteDish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete dish?'),
        content: Text('"${dish.name}" will be removed from this category.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(localDishesProvider.notifier)
        .removeDish(widget.categorySlug, dish.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _steps;

    if (_showCookingMode) return _buildCookingMode(theme, steps);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dish Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete dish',
            onPressed: _deleteDish,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(dish.name,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Added by you',
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (dish.timeMinutes > 0)
                  _infoChip(Icons.timer, '${dish.timeMinutes} min'),
                if (dish.difficulty != null)
                  _infoChip(Icons.local_fire_department, dish.difficulty!),
                if (dish.healthCategory != null)
                  _infoChip(Icons.spa, dish.healthCategory!),
                if (dish.dietType != null)
                  _infoChip(Icons.eco, dish.dietType!),
                if (dish.cuisine != null)
                  _infoChip(Icons.flag, dish.cuisine!),
                if (dish.mealTypes != null)
                  ...dish.mealTypes!.map((m) => _infoChip(Icons.schedule, m)),
              ],
            ),
            if (dish.description != null && dish.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(dish.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _currentStep = 0;
                  _showCookingMode = true;
                }),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Cooking'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            RecipeVideoLinksSection(recipeId: dish.id),
            const SizedBox(height: 20),
            Text('Ingredients',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (dish.ingredients != null && dish.ingredients!.isNotEmpty)
              ...dish.ingredients!.map((ing) => _ingredientRow(ing))
            else
              Text('No ingredients listed',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const Divider(height: 32),
            Text('Instructions',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (steps.isEmpty)
              Text('No instructions available',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey))
            else
              ...List.generate(steps.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text('${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(steps[i], style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCookingMode(ThemeData theme, List<String> steps) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _showCookingMode = false),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: steps.isEmpty ? 0 : (_currentStep + 1) / steps.length,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  Text('${steps.isEmpty ? 1 : _currentStep + 1}/${steps.isEmpty ? 1 : steps.length}',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Step ${steps.isEmpty ? 1 : _currentStep + 1}',
                          style: const TextStyle(color: Colors.white54, fontSize: 16)),
                      const SizedBox(height: 16),
                      Text(steps.isEmpty ? 'Enjoy your meal!' : steps[_currentStep],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: () => setState(() => _currentStep--),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text('Previous', style: TextStyle(color: Colors.white)),
                    ),
                  const Spacer(),
                  if (_currentStep < steps.length - 1)
                    FilledButton.icon(
                      onPressed: () => setState(() => _currentStep++),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => _showCookingMode = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Meal completed!')),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _ingredientRow(String ingredient) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(ingredient, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
