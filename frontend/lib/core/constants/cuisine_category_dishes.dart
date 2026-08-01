import 'category_catalog.dart';
import 'cuisine_category_dishes_1.dart';
import 'cuisine_category_dishes_2.dart';
import 'cuisine_category_dishes_3.dart';
import 'cuisine_category_dishes_4.dart';
import 'cuisine_category_dishes_5.dart';
import 'cuisine_category_dishes_6.dart';
import 'cuisine_category_dishes_7.dart';
import 'cuisine_category_dishes_8.dart';

/// Per-cuisine, per-category hardcoded dishes: cuisine slug -> category key
/// (breakfast, healthy, dinner, veg, nonveg, sweet, kids) -> 5 dishes each.
final Map<String, Map<String, List<CategoryDish>>> cuisineCategoryDishes = {
  ...cuisineCategoryDishesPart1,
  ...cuisineCategoryDishesPart2,
  ...cuisineCategoryDishesPart3,
  ...cuisineCategoryDishesPart4,
  ...cuisineCategoryDishesPart5,
  ...cuisineCategoryDishesPart6,
  ...cuisineCategoryDishesPart7,
  ...cuisineCategoryDishesPart8,
};
