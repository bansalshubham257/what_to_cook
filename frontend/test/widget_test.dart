import 'package:flutter_test/flutter_test.dart';
import 'package:what_to_cook/core/constants/category_catalog.dart';

void main() {
  test('every special category has at least 5 curated dishes', () {
    expect(kSpecialCategories.length, greaterThanOrEqualTo(5));
    for (final c in kSpecialCategories) {
      expect(
        c.hardcoded.length,
        greaterThanOrEqualTo(5),
        reason: '${c.slug} should have at least 5 curated dishes, found ${c.hardcoded.length}',
      );
    }
  });

  test('international cuisines have curated hardcoded dishes', () {
    const international = [
      'thai', 'japanese', 'italian', 'chinese', 'mexican', 'korean',
      'vietnamese', 'mediterranean', 'french',
    ];
    for (final cuisine in international) {
      expect(
        curatedCuisineDishes[cuisine],
        isNotNull,
        reason: '$cuisine should have curated dishes in the app',
      );
    }
  });

  test('every curated cuisine has at least 5 dishes', () {
    curatedCuisineDishes.forEach((slug, dishes) {
      expect(
        dishes.length,
        greaterThanOrEqualTo(5),
        reason: '$slug has ${dishes.length} curated dishes',
      );
    });
  });

  test('cuisine categories build a stable search query', () {
    final breakfast = categoryForCuisine(
      {'name': 'goan', 'display_name': 'Goan'},
      mealType: 'breakfast',
    );
    expect(breakfast.slug, 'cuisine-goan-breakfast');
    expect(breakfast.cuisine, 'goan');
    expect(breakfast.mealType, 'breakfast');
    expect(breakfast.searchQuery, 'breakfast');
  });
}
