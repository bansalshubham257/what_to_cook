import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/category_catalog.dart';

/// "Special Dishes" picker opened from Explore's meal menu. Shows the special
/// (tag-based) categories: kids, healthy, quick, veg, non-veg.
class ExploreSpecialScreen extends StatelessWidget {
  const ExploreSpecialScreen({super.key});

  static const _specialSlugs = ['healthy', 'quick', 'kids', 'veg'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = kSpecialCategories.where((c) => _specialSlugs.contains(c.slug)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Special Dishes')),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final c = categories[i];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/category/${c.slug}'),
              child: Container(
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c.icon, color: c.color, size: 36),
                    const SizedBox(height: 10),
                    Text(c.label,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    if (c.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(c.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
