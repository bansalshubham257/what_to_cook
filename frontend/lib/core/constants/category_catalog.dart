import 'package:flutter/material.dart';

export 'cuisine_category_dishes.dart';

/// A single dish shown in a category. Curated dishes are hardcoded in the app;
/// user-added dishes are persisted locally and carry a stable [id]. When a user
/// adds only a name, the AI fills in the optional recipe details below.
class CategoryDish {
  final String id;
  final String name;
  final String? description;
  final int timeMinutes;
  final String? difficulty;
  final String? dietType;
  final String? healthCategory;
  final String? cuisine;
  final List<String>? mealTypes;
  final List<String>? tags;
  final List<String>? ingredients;
  final String? instructions;

  const CategoryDish({
    required this.id,
    required this.name,
    this.description,
    this.timeMinutes = 0,
    this.difficulty,
    this.dietType,
    this.healthCategory,
    this.cuisine,
    this.mealTypes,
    this.tags,
    this.ingredients,
    this.instructions,
  });

  factory CategoryDish.fromJson(Map<String, dynamic> json) => CategoryDish(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        timeMinutes: (json['time_minutes'] ?? 0) as int,
        difficulty: json['difficulty'],
        dietType: json['diet_type'],
        healthCategory: json['health_category'],
        cuisine: json['cuisine'],
        mealTypes: json['meal_types'] != null
            ? List<String>.from(json['meal_types'] as List)
            : null,
        tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
        ingredients: json['ingredients'] != null
            ? List<String>.from(json['ingredients'] as List)
            : null,
        instructions: json['instructions'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'time_minutes': timeMinutes,
        'difficulty': difficulty,
        'diet_type': dietType,
        'health_category': healthCategory,
        'cuisine': cuisine,
        'meal_types': mealTypes,
        'tags': tags,
        'ingredients': ingredients,
        'instructions': instructions,
      };
}

/// Describes one discover category. A category can be:
/// - a special/tag based category (breakfast, healthy, quick, kids...)
/// - a cuisine category coming from the database (cuisine + optional meal type)
///
/// Each category shows curated (hardcoded) dishes + up to 5 dishes fetched from
/// the database + dishes the user added locally.
class CategoryConfig {
  final String slug;
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;

  /// Cuisine slug (from DB) when this is a cuisine category.
  final String? cuisine;

  /// Meal-type filter (breakfast/lunch/dinner/snacks).
  final String? mealType;

  /// Free-text term sent to the search API (e.g. "healthy", "kids").
  final String? query;

  /// True to filter dishes that take <= 30 minutes.
  final bool quick;

  /// Curated dishes hardcoded in the app for this category.
  final List<CategoryDish> hardcoded;

  const CategoryConfig({
    required this.slug,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.color,
    this.cuisine,
    this.mealType,
    this.query,
    this.quick = false,
    this.hardcoded = const [],
  });

  /// Search query sent to the backend for the "from database" section.
  String get searchQuery {
    if (query != null && query!.isNotEmpty) return query!;
    final parts = <String>[];
    if (mealType != null) parts.add(mealType!);
    if (quick) parts.add('quick');
    return parts.join(' ');
  }

  bool get isCuisineCategory => cuisine != null;
}

/// Builds a cuisine category from a database cuisine row
/// (as returned by `/recipes/cuisines`).
CategoryConfig categoryForCuisine(
  Map<String, dynamic> cuisine, {
  String? mealType,
  List<CategoryDish> hardcoded = const [],
}) {
  final name = (cuisine['name'] ?? '') as String;
  final displayName = (cuisine['display_name'] ?? name) as String;
  final count = (cuisine['recipe_count'] ?? 0) as int;
  final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
  final color = _cuisineColors[hash % _cuisineColors.length];

  String slug = 'cuisine-$name';
  if (mealType != null) slug = 'cuisine-$name-$mealType';
  final suffix = mealType != null ? ' ${mealType[0].toUpperCase()}${mealType.substring(1)}' : '';

  return CategoryConfig(
    slug: slug,
    label: '$displayName$suffix',
    subtitle: count > 0 ? '$count dishes' : null,
    icon: _cuisineIcon(name),
    color: color,
    cuisine: name,
    mealType: mealType,
    hardcoded: hardcoded,
  );
}

/// The full ordered list of special (non-cuisine) categories shown on Discover.
final List<CategoryConfig> kSpecialCategories = [
  const CategoryConfig(
    slug: 'breakfast',
    label: 'Breakfast',
    subtitle: 'Start your day right',
    icon: Icons.free_breakfast,
    color: Color(0xFFF57C00),
    mealType: 'breakfast',
    hardcoded: _breakfastDishes,
  ),
  const CategoryConfig(
    slug: 'lunch',
    label: 'Lunch',
    subtitle: 'Midday comfort food',
    icon: Icons.lunch_dining,
    color: Color(0xFF00897B),
    mealType: 'lunch',
    hardcoded: _lunchDishes,
  ),
  const CategoryConfig(
    slug: 'healthy',
    label: 'Healthy',
    subtitle: 'Light & nutritious',
    icon: Icons.spa,
    color: Color(0xFF2E7D32),
    query: 'healthy',
    hardcoded: _healthyDishes,
  ),
  const CategoryConfig(
    slug: 'quick',
    label: 'Quick <30 min',
    subtitle: 'Done in a flash',
    icon: Icons.bolt,
    color: Color(0xFF1565C0),
    quick: true,
    hardcoded: _quickDishes,
  ),
  const CategoryConfig(
    slug: 'kids',
    label: 'Kids',
    subtitle: 'Little ones love it',
    icon: Icons.child_care,
    color: Color(0xFFC2185B),
    query: 'kids',
    hardcoded: _kidsDishes,
  ),
  const CategoryConfig(
    slug: 'sweet',
    label: 'Sweet',
    subtitle: 'Craving something sweet',
    icon: Icons.icecream,
    color: Color(0xFF6A1B9A),
    query: 'sweet',
    hardcoded: _sweetDishes,
  ),
  const CategoryConfig(
    slug: 'snacks',
    label: 'Snacks',
    subtitle: 'Evening bites',
    icon: Icons.cookie,
    color: Color(0xFF00838F),
    mealType: 'snacks',
    hardcoded: _snackDishes,
  ),
  const CategoryConfig(
    slug: 'veg',
    label: 'Veg',
    subtitle: 'Pure vegetarian',
    icon: Icons.eco,
    color: Color(0xFF33691E),
    query: 'veg',
    hardcoded: _vegDishes,
  ),
  const CategoryConfig(
    slug: 'dinner',
    label: 'Dinner',
    subtitle: 'End the day well',
    icon: Icons.dinner_dining,
    color: Color(0xFF37474F),
    mealType: 'dinner',
    hardcoded: _dinnerDishes,
  ),
];

/// Curated hardcoded dishes keyed by cuisine slug. Cuisines not listed here
/// fall back to database dishes only.
final Map<String, List<CategoryDish>> curatedCuisineDishes = {
  'goan': _goanDishes,
  'thai': _thaiDishes,
  'japanese': _japaneseDishes,
  'italian': _italianDishes,
  'chinese': _chineseDishes,
  'mexican': _mexicanDishes,
  'korean': _koreanDishes,
  'vietnamese': _vietnameseDishes,
  'mediterranean': _mediterraneanDishes,
  'french': _frenchDishes,
  'north_indian': _northIndianDishes,
  'south_indian': _southIndianDishes,
  'punjabi': _punjabiDishes,
  'bengali': _bengaliDishes,
  'maharashtrian': _maharashtrianDishes,
  'indo_chinese': _indoChineseDishes,
  'kerala': _keralaDishes,
  'tamil': _tamilDishes,
  'awadhi': _awadhiDishes,
  'rajasthani': _rajasthaniDishes,
};

// ---------------------------------------------------------------- curated dishes

const _breakfastDishes = [
  CategoryDish(id: 'hb-poha', name: 'Poha', description: 'Flattened rice tossed with peanuts, curry leaves and lemon.', timeMinutes: 20),
  CategoryDish(id: 'hb-aloo-paratha', name: 'Aloo Paratha', description: 'Whole wheat flatbread stuffed with spiced potato, served with curd.', timeMinutes: 40),
  CategoryDish(id: 'hb-upma', name: 'Rava Upma', description: 'Semolina tempered with mustard, cashews and vegetables.', timeMinutes: 20),
  CategoryDish(id: 'hb-omelette', name: 'Masala Omelette', description: 'Fluffy eggs with onion, green chilli and fresh coriander.', timeMinutes: 15),
  CategoryDish(id: 'hb-dosa', name: 'Masala Dosa', description: 'Crisp rice-lentil crepe with spiced potato filling.', timeMinutes: 30),
];

const _lunchDishes = [
  CategoryDish(id: 'hl-pulao', name: 'Veg Pulao', description: 'Fragrant basmati rice with vegetables and whole spices.', timeMinutes: 30),
  CategoryDish(id: 'hl-dal-chawal', name: 'Dal Chawal', description: 'Comforting dal over steamed rice with ghee and pickle.', timeMinutes: 35),
  CategoryDish(id: 'hl-biryani', name: 'Veg Biryani', description: 'Basmati layered with vegetables, saffron and mint.', timeMinutes: 50),
  CategoryDish(id: 'hl-curd-rice', name: 'Curd Rice', description: 'Rice tempered with curd, ginger and curry leaves.', timeMinutes: 15),
  CategoryDish(id: 'hl-fried-rice', name: 'Veg Fried Rice', description: 'Wok-tossed rice with crunchy vegetables.', timeMinutes: 25),
];

const _healthyDishes = [
  CategoryDish(id: 'hh-moong-khichdi', name: 'Moong Dal Khichdi', description: 'Gentle one-pot mung bean and rice porridge with ghee.', timeMinutes: 30),
  CategoryDish(id: 'hh-vegetable-soup', name: 'Clear Vegetable Soup', description: 'Broth of seasonal vegetables, ginger and black pepper.', timeMinutes: 25),
  CategoryDish(id: 'hh-greek-salad', name: 'Fresh Vegetable Salad', description: 'Cucumber, tomato and onion tossed with lemon and herbs.', timeMinutes: 15),
  CategoryDish(id: 'hh-dalia', name: 'Dalia Veg Pulao', description: 'Broken wheat cooked with assorted vegetables and spices.', timeMinutes: 30),
  CategoryDish(id: 'hh-palak-soup', name: 'Palak Dal', description: 'Lentils simmered with spinach, garlic and cumin.', timeMinutes: 35),
];

const _quickDishes = [
  CategoryDish(id: 'hq-maggi', name: 'Masala Noodles', description: 'Instant noodles dressed up with veggies and masala.', timeMinutes: 10),
  CategoryDish(id: 'hq-sandwich', name: 'Veg Sandwich', description: 'Grilled sandwich with cucumber, tomato and chutney.', timeMinutes: 15),
  CategoryDish(id: 'hq-bhurji', name: 'Paneer Bhurji', description: 'Crumbled paneer sauteed with onion, tomato and spices.', timeMinutes: 15),
  CategoryDish(id: 'hq-eggs', name: 'Scrambled Eggs', description: 'Soft scrambled eggs with butter and black pepper.', timeMinutes: 10),
  CategoryDish(id: 'hq-corn', name: 'Corn Chaat', description: 'Steamed corn tossed with lemon, chaat masala and coriander.', timeMinutes: 12),
];

const _kidsDishes = [
  CategoryDish(id: 'hk-mac-cheese', name: 'Veg Macaroni', description: 'Creamy macaroni with mild cheese sauce and veggies.', timeMinutes: 20),
  CategoryDish(id: 'hk-fried-rice', name: 'Veg Fried Rice', description: 'Mild rice with sweet corn, carrot and spring onion.', timeMinutes: 25),
  CategoryDish(id: 'hk-pancake', name: 'Banana Pancakes', description: 'Fluffy pancakes with banana and a drizzle of honey.', timeMinutes: 20),
  CategoryDish(id: 'hk-cutlets', name: 'Aloo Cutlets', description: 'Golden potato cutlets, crisp outside and soft inside.', timeMinutes: 30),
  CategoryDish(id: 'hk-pizza', name: 'Veggie Pizza', description: 'Kid-friendly pizza with tomato, corn and cheese.', timeMinutes: 30),
];

const _sweetDishes = [
  CategoryDish(id: 'hs-gulab-jamun', name: 'Gulab Jamun', description: 'Soft milk dumplings soaked in rose-cardamom syrup.', timeMinutes: 45),
  CategoryDish(id: 'hs-mishti', name: 'Mishti Doi', description: 'Bengali caramelised jaggery yogurt, set overnight.', timeMinutes: 40),
  CategoryDish(id: 'hs-halwa', name: 'Gajar Halwa', description: 'Slow-cooked carrot pudding with ghee and nuts.', timeMinutes: 45),
  CategoryDish(id: 'hs-kheer', name: 'Rice Kheer', description: 'Creamy rice pudding with cardamom, saffron and almonds.', timeMinutes: 40),
  CategoryDish(id: 'hs-mango', name: 'Mango Shrikhand', description: 'Hung curd whipped with saffron and ripe mango.', timeMinutes: 20),
];

const _snackDishes = [
  CategoryDish(id: 'hsk-samosa', name: 'Veg Samosa', description: 'Crisp pastry triangles stuffed with spiced potato and peas.', timeMinutes: 45),
  CategoryDish(id: 'hsk-bhel', name: 'Bhel Puri', description: 'Puffed rice with sev, onion, tomato and tangy chutneys.', timeMinutes: 15),
  CategoryDish(id: 'hsk-pakora', name: 'Onion Pakora', description: 'Crunchy gram-flour fritters, perfect with chai.', timeMinutes: 20),
  CategoryDish(id: 'hsk-spring', name: 'Veg Spring Rolls', description: 'Crispy rolls stuffed with cabbage, carrot and noodles.', timeMinutes: 35),
  CategoryDish(id: 'hsk-dhokla', name: 'Khaman Dhokla', description: 'Steamed gram-flour cakes tempered with mustard seeds.', timeMinutes: 35),
];

const _vegDishes = [
  CategoryDish(id: 'hv-paneer', name: 'Palak Paneer', description: 'Paneer cubes in a creamy spinach gravy.', timeMinutes: 35),
  CategoryDish(id: 'hv-dal', name: 'Dal Tadka', description: 'Toor dal finished with a smoky ghee tempering.', timeMinutes: 30),
  CategoryDish(id: 'hv-chana', name: 'Chana Masala', description: 'Chickpeas simmered in an onion-tomato masala.', timeMinutes: 35),
  CategoryDish(id: 'hv-veg', name: 'Mixed Veg Curry', description: 'Seasonal vegetables in a home-style gravy.', timeMinutes: 35),
  CategoryDish(id: 'hv-biryani', name: 'Veg Biryani', description: 'Fragrant basmati layered with vegetables and saffron.', timeMinutes: 50),
];

const _dinnerDishes = [
  CategoryDish(id: 'hd-paneer', name: 'Paneer Butter Masala', description: 'Paneer in a rich, buttery tomato-cashew gravy.', timeMinutes: 40),
  CategoryDish(id: 'hd-dal', name: 'Dal Makhani', description: 'Slow-simmered black lentils with cream and butter.', timeMinutes: 60),
  CategoryDish(id: 'hd-roti', name: 'Stuffed Kulcha', description: 'Leavened flatbread stuffed with spiced potato.', timeMinutes: 45),
  CategoryDish(id: 'hd-curry', name: 'Egg Curry', description: 'Boiled eggs simmered in an onion-tomato masala.', timeMinutes: 30),
  CategoryDish(id: 'hd-rajma', name: 'Rajma Chawal', description: 'Kidney beans in a Punjabi masala, served with rice.', timeMinutes: 45),
];

const _goanDishes = [
  CategoryDish(id: 'hg-poi', name: 'Sanna & Poee', description: 'Steamed rice cakes and Goa\'s leavened bread for breakfast.', timeMinutes: 30),
  CategoryDish(id: 'hg-chicken', name: 'Goan Chicken Cafreal', description: 'Green masala-marinated chicken, bright with coriander.', timeMinutes: 45),
  CategoryDish(id: 'hg-prawn', name: 'Goan Prawn Curry', description: 'Tangy coconut prawn curry with kokum.', timeMinutes: 35),
  CategoryDish(id: 'hg-xacuti', name: 'Xacuti', description: 'Roasted coconut and poppy seed curry from Goa.', timeMinutes: 60),
  CategoryDish(id: 'hg-bebinca', name: 'Bebinca', description: 'Goa\'s layered coconut-egg pudding dessert.', timeMinutes: 90),
];

const _thaiDishes = [
  CategoryDish(id: 'hi-padthai', name: 'Pad Thai', description: 'Stir-fried rice noodles with tofu, beansprouts and peanuts.', timeMinutes: 35),
  CategoryDish(id: 'hi-green', name: 'Thai Green Curry', description: 'Coconut curry with vegetables and fresh basil.', timeMinutes: 45),
  CategoryDish(id: 'hi-tomyum', name: 'Tom Yum Soup', description: 'Hot-and-sour soup with mushroom and lemongrass.', timeMinutes: 35),
  CategoryDish(id: 'hi-mango', name: 'Mango Sticky Rice', description: 'Sweet coconut rice served with ripe mango.', timeMinutes: 40),
  CategoryDish(id: 'hi-basil', name: 'Thai Basil Tofu', description: 'Stir-fried tofu with garlic, chilli and basil.', timeMinutes: 30),
];

const _japaneseDishes = [
  CategoryDish(id: 'hj-sushi', name: 'Veg Sushi Rolls', description: 'Nori rolls with seasoned rice, cucumber and avocado.', timeMinutes: 50),
  CategoryDish(id: 'hj-miso', name: 'Miso Soup', description: 'Warming broth with tofu, wakame and spring onion.', timeMinutes: 20),
  CategoryDish(id: 'hj-tempura', name: 'Veg Tempura', description: 'Crisp battered vegetables with a soy dip.', timeMinutes: 30),
  CategoryDish(id: 'hj-omurice', name: 'Omurice', description: 'Tomato fried rice wrapped in a soft omelette.', timeMinutes: 25),
  CategoryDish(id: 'hj-mochi', name: 'Matcha Mochi', description: 'Chewy green-tea rice cakes, lightly sweetened.', timeMinutes: 30),
];

const _italianDishes = [
  CategoryDish(id: 'hii-pizza', name: 'Margherita Pizza', description: 'Classic pizza with tomato, mozzarella and basil.', timeMinutes: 45),
  CategoryDish(id: 'hii-agno', name: 'Spaghetti Aglio e Olio', description: 'Garlic, olive oil and chilli tossed pasta.', timeMinutes: 25),
  CategoryDish(id: 'hii-risotto', name: 'Risotto alla Milanese', description: 'Creamy saffron risotto with parmesan.', timeMinutes: 50),
  CategoryDish(id: 'hii-brus', name: 'Bruschetta', description: 'Toasted bread with fresh tomato, garlic and basil.', timeMinutes: 20),
  CategoryDish(id: 'hii-tira', name: 'Tiramisu', description: 'Espresso-soaked mascarpone dessert with cocoa.', timeMinutes: 20),
];

const _chineseDishes = [
  CategoryDish(id: 'hc-fried', name: 'Veg Fried Rice', description: 'Wok-tossed rice with crunchy vegetables and egg.', timeMinutes: 25),
  CategoryDish(id: 'hc-chowmein', name: 'Veg Chow Mein', description: 'Noodles stir-fried with cabbage and capsicum.', timeMinutes: 25),
  CategoryDish(id: 'hc-spring', name: 'Veg Spring Rolls', description: 'Crispy rolls stuffed with noodles and vegetables.', timeMinutes: 35),
  CategoryDish(id: 'hc-kungpao', name: 'Kung Pao Tofu', description: 'Crispy tofu and peanuts in a spicy-sweet sauce.', timeMinutes: 30),
  CategoryDish(id: 'hc-eggdrop', name: 'Egg Drop Soup', description: 'Silky egg ribbons in a light gingery broth.', timeMinutes: 20),
];

const _mexicanDishes = [
  CategoryDish(id: 'hm-taco', name: 'Veg Tacos', description: 'Soft tortillas with beans, avocado and lime.', timeMinutes: 30),
  CategoryDish(id: 'hm-guac', name: 'Guacamole', description: 'Mashed avocado with lime, onion and chilli.', timeMinutes: 10),
  CategoryDish(id: 'hm-enchi', name: 'Cheesy Enchiladas', description: 'Rolled tortillas baked in tomato sauce with cheese.', timeMinutes: 45),
  CategoryDish(id: 'hm-huevos', name: 'Huevos Rancheros', description: 'Fried eggs on tortillas with spicy tomato sauce.', timeMinutes: 25),
  CategoryDish(id: 'hm-churro', name: 'Churros', description: 'Cinnamon-sugar fried dough with chocolate dip.', timeMinutes: 35),
];

const _koreanDishes = [
  CategoryDish(id: 'hkk-kimchi', name: 'Kimchi Fried Rice', description: 'Spicy rice stir-fried with kimchi and gochujang.', timeMinutes: 25),
  CategoryDish(id: 'hkk-bibim', name: 'Bibimbap', description: 'Rice bowl with seasoned vegetables and a fried egg.', timeMinutes: 35),
  CategoryDish(id: 'hkk-pancake', name: 'Korean Veg Pancake', description: 'Crisp scallion and vegetable pancake with soy dip.', timeMinutes: 30),
  CategoryDish(id: 'hkk-tteok', name: 'Tteokbokki', description: 'Chewy rice cakes in a spicy-sweet sauce.', timeMinutes: 30),
  CategoryDish(id: 'hkk-bbq', name: 'Korean BBQ Tofu', description: 'Glazed tofu steaks in a smoky gochujang marinade.', timeMinutes: 35),
];

const _vietnameseDishes = [
  CategoryDish(id: 'hv-p6', name: 'Veg Pho', description: 'Fragrant noodle soup with herbs, tofu and lime.', timeMinutes: 50),
  CategoryDish(id: 'hv-rolls', name: 'Vietnamese Spring Rolls', description: 'Fresh rice-paper rolls with herbs and noodles.', timeMinutes: 20),
  CategoryDish(id: 'hv-banhmi', name: 'Veg Banh Mi', description: 'Crisp baguette with tofu, pickled veg and herbs.', timeMinutes: 25),
  CategoryDish(id: 'hv-noodle', name: 'Vietnamese Noodle Salad', description: 'Cool vermicelli with herbs, peanuts and lime dressing.', timeMinutes: 30),
  CategoryDish(id: 'hv-coconut', name: 'Coconut Sticky Rice', description: 'Sweet coconut-glazed sticky rice with sesame.', timeMinutes: 40),
];

const _mediterraneanDishes = [
  CategoryDish(id: 'hmd-falafel', name: 'Falafel Wrap', description: 'Crisp chickpea falafel with tahini in a wrap.', timeMinutes: 45),
  CategoryDish(id: 'hmd-salad', name: 'Greek Salad', description: 'Tomato, cucumber and olive salad with lemon dressing.', timeMinutes: 15),
  CategoryDish(id: 'hmd-hummus', name: 'Hummus', description: 'Silky chickpea and tahini dip with garlic and lemon.', timeMinutes: 35),
  CategoryDish(id: 'hmd-shak', name: 'Shakshuka', description: 'Eggs poached in a spiced tomato-pepper sauce.', timeMinutes: 35),
  CategoryDish(id: 'hmd-baklava', name: 'Baklava', description: 'Layers of crisp pastry with nuts and honey syrup.', timeMinutes: 60),
];

const _frenchDishes = [
  CategoryDish(id: 'hf-croissant', name: 'Butter Croissant', description: 'Flaky, buttery laminated pastry for breakfast.', timeMinutes: 60),
  CategoryDish(id: 'hf-rata', name: 'Ratatouille', description: 'Provencal stewed vegetables in olive oil.', timeMinutes: 55),
  CategoryDish(id: 'hf-onion', name: 'French Onion Soup', description: 'Caramelised onions with a melted cheese toast.', timeMinutes: 55),
  CategoryDish(id: 'hf-crepe', name: 'Crepes Suzette', description: 'Thin pancakes in a buttery orange sauce.', timeMinutes: 25),
  CategoryDish(id: 'hf-brulee', name: 'Creme Brulee', description: 'Silky vanilla custard with a caramel crust.', timeMinutes: 50),
];

const _northIndianDishes = [
  CategoryDish(id: 'hn-daltadka', name: 'Dal Tadka', description: 'Toor dal finished with ghee tempering.', timeMinutes: 30),
  CategoryDish(id: 'hn-paneer', name: 'Paneer Butter Masala', description: 'Paneer in a rich tomato-cashew gravy.', timeMinutes: 40),
  CategoryDish(id: 'hn-chana', name: 'Chana Masala', description: 'Chickpeas in a tangy onion-tomato masala.', timeMinutes: 35),
  CategoryDish(id: 'hn-aloo', name: 'Aloo Gobhi', description: 'Cauliflower and potato with cumin and turmeric.', timeMinutes: 30),
  CategoryDish(id: 'hn-biryani', name: 'Veg Biryani', description: 'Fragrant basmati layered with vegetables.', timeMinutes: 50),
];

const _southIndianDishes = [
  CategoryDish(id: 'hs-dosa', name: 'Masala Dosa', description: 'Crisp rice-lentil crepe with potato filling.', timeMinutes: 30),
  CategoryDish(id: 'hs-idli', name: 'Idli Sambar', description: 'Steamed rice cakes with lentil-vegetable sambar.', timeMinutes: 35),
  CategoryDish(id: 'hs-uttapam', name: 'Veg Uttapam', description: 'Thick pancake topped with onion, tomato and chilli.', timeMinutes: 25),
  CategoryDish(id: 'hs-rasam', name: 'Rasam', description: 'Spicy-sour tomato-pepper soup, great with rice.', timeMinutes: 25),
  CategoryDish(id: 'hs-avial', name: 'Avial', description: 'Mixed vegetables in a coconut-curd gravy.', timeMinutes: 40),
];

const _punjabiDishes = [
  CategoryDish(id: 'hp-makki', name: 'Makki ki Roti', description: 'Corn flatbread with sarson ka saag.', timeMinutes: 45),
  CategoryDish(id: 'hp-dalmakh', name: 'Dal Makhani', description: 'Slow-simmered black lentils with cream.', timeMinutes: 60),
  CategoryDish(id: 'hp-paratha', name: 'Aloo Paratha', description: 'Wheat flatbread stuffed with spiced potato.', timeMinutes: 40),
  CategoryDish(id: 'hp-lassi', name: 'Sweet Lassi', description: 'Chilled yogurt drink with cardamom and cream.', timeMinutes: 10),
  CategoryDish(id: 'hp-paneer', name: 'Paneer Tikka', description: 'Char-grilled marinated paneer cubes.', timeMinutes: 40),
];

const _bengaliDishes = [
  CategoryDish(id: 'hb-macher', name: 'Macher Jhol', description: 'Light fish curry with mustard and spices.', timeMinutes: 40),
  CategoryDish(id: 'hb-shukto', name: 'Shukto', description: 'Bitter-sweet mixed vegetable stew.', timeMinutes: 35),
  CategoryDish(id: 'hb-mishti', name: 'Mishti Doi', description: 'Caramelised jaggery yogurt dessert.', timeMinutes: 40),
  CategoryDish(id: 'hb-luchi', name: 'Luchi Aloo', description: 'Deep-fried puffy bread with spicy potato.', timeMinutes: 35),
  CategoryDish(id: 'hb-cholar', name: 'Cholar Dal', description: 'Bengal gram dal with coconut and ghee.', timeMinutes: 35),
];

const _maharashtrianDishes = [
  CategoryDish(id: 'hmh-poha', name: 'Kanda Poha', description: 'Flattened rice with peanut, curry leaves and lemon.', timeMinutes: 20),
  CategoryDish(id: 'hmh-vada', name: 'Misal Pav', description: 'Sprouted bean curry topped with farsan and pav.', timeMinutes: 40),
  CategoryDish(id: 'hmh-dhokla', name: 'Khaman Dhokla', description: 'Steamed gram-flour cakes with mustard tempering.', timeMinutes: 35),
  CategoryDish(id: 'hmh-pav', name: 'Veg Wada Pav', description: 'Crisp potato fritter in a soft pav bun.', timeMinutes: 30),
  CategoryDish(id: 'hmh-modak', name: 'Modak', description: 'Steamed dumplings with coconut-jaggery filling.', timeMinutes: 60),
];

const _indoChineseDishes = [
  CategoryDish(id: 'hic-manchurian', name: 'Veg Manchurian', description: 'Crisp veggie balls in a spicy-sweet gravy.', timeMinutes: 40),
  CategoryDish(id: 'hic-chowmein', name: 'Hakka Noodles', description: 'Wok-tossed noodles with cabbage and capsicum.', timeMinutes: 25),
  CategoryDish(id: 'hic-chilli', name: 'Chilli Paneer', description: 'Paneer tossed with capsicum in soy-chilli sauce.', timeMinutes: 30),
  CategoryDish(id: 'hic-fried', name: 'Veg Fried Rice', description: 'Desi-style fried rice with soy and spring onion.', timeMinutes: 25),
  CategoryDish(id: 'hic-soup', name: 'Veg Manchow Soup', description: 'Spicy-sour soup topped with crispy noodles.', timeMinutes: 30),
];

const _keralaDishes = [
  CategoryDish(id: 'hk-puttu', name: 'Puttu Kadala', description: 'Steamed rice cakes with black chickpea curry.', timeMinutes: 40),
  CategoryDish(id: 'hk-appam', name: 'Appam Stew', description: 'Lacy fermented rice pancakes with vegetable stew.', timeMinutes: 45),
  CategoryDish(id: 'hk-avial', name: 'Avial', description: 'Mixed vegetables in coconut-curd gravy.', timeMinutes: 40),
  CategoryDish(id: 'hk-payasam', name: 'Payasam', description: 'Creamy rice and milk pudding with jaggery.', timeMinutes: 40),
  CategoryDish(id: 'hk-prawn', name: 'Kerala Prawn Curry', description: 'Coconut and curry-leaf prawn curry.', timeMinutes: 35),
];

const _tamilDishes = [
  CategoryDish(id: 'ht-idli', name: 'Idli Sambar', description: 'Steamed rice cakes with lentil-vegetable sambar.', timeMinutes: 35),
  CategoryDish(id: 'ht-curd', name: 'Curd Rice', description: 'Rice with tempered curd, ginger and coriander.', timeMinutes: 15),
  CategoryDish(id: 'ht-upma', name: 'Kara Pongal', description: 'Spicy rice and moong dal with pepper and ghee.', timeMinutes: 30),
  CategoryDish(id: 'ht-lasagne', name: 'Chettinad Paneer', description: 'Spicy pepper-and-fennel paneer curry.', timeMinutes: 40),
  CategoryDish(id: 'ht-kuzhi', name: 'Rasam', description: 'Spicy-sour tamarind-pepper soup.', timeMinutes: 25),
];

const _awadhiDishes = [
  CategoryDish(id: 'ha-kebab', name: 'Veg Galouti Kebab', description: 'Melt-in-the-mouth patties with warm spices.', timeMinutes: 50),
  CategoryDish(id: 'ha-biryani', name: 'Awadhi Veg Biryani', description: 'Slow-cooked saffron biryani with vegetables.', timeMinutes: 60),
  CategoryDish(id: 'ha-shahi', name: 'Shahi Paneer', description: 'Paneer in a rich saffron-almond gravy.', timeMinutes: 45),
  CategoryDish(id: 'ha-sheermal', name: 'Sheermal', description: 'Saffron-scented leavened flatbread.', timeMinutes: 45),
  CategoryDish(id: 'ha-kheer', name: 'Shahi Tukda', description: 'Fried bread in saffron milk with nuts.', timeMinutes: 40),
];

const _rajasthaniDishes = [
  CategoryDish(id: 'hr-dalbati', name: 'Dal Baati Churma', description: 'Baked wheat balls with dal and sweet churma.', timeMinutes: 70),
  CategoryDish(id: 'hr-ker', name: 'Ker Sangri', description: 'Desert beans and berries in a rustic masala.', timeMinutes: 45),
  CategoryDish(id: 'hr-gatte', name: 'Gatte ki Sabzi', description: 'Gram-flour dumplings in a tangy yogurt gravy.', timeMinutes: 50),
  CategoryDish(id: 'hr-papad', name: 'Pyaaz Kachori', description: 'Crisp pastry stuffed with spiced onion.', timeMinutes: 50),
  CategoryDish(id: 'hr-mal', name: 'Ghevar', description: 'Honeycomb-like fried sweet soaked in syrup.', timeMinutes: 60),
];

// ---------------------------------------------------------------- icons & colors

const _cuisineIcons = <String, IconData>{
  'north_indian': Icons.landscape,
  'south_indian': Icons.local_florist,
  'punjabi': Icons.whatshot,
  'bengali': Icons.water_drop,
  'odia': Icons.waves,
  'gujarati': Icons.emoji_events,
  'rajasthani': Icons.sunny,
  'maharashtrian': Icons.missed_video_call,
  'indo_chinese': Icons.ramen_dining,
  'continental': Icons.public,
  'kashmiri': Icons.ac_unit,
  'awadhi': Icons.diamond,
  'bihari': Icons.layers,
  'himachali': Icons.terrain,
  'haryanvi': Icons.grain,
  'goan': Icons.beach_access,
  'kerala': Icons.nature,
  'tamil': Icons.celebration,
  'telugu': Icons.local_fire_department,
  'karnataka': Icons.forest,
  'assamese': Icons.water,
  'nepali': Icons.flag,
  'sindhi': Icons.language,
  'parsi': Icons.flare,
  'hyderabadi': Icons.restaurant_menu,
  'muglai': Icons.fastfood,
  'italian': Icons.local_pizza,
  'french': Icons.local_cafe,
  'thai': Icons.local_florist,
  'chinese': Icons.ramen_dining,
  'mexican': Icons.lunch_dining,
  'japanese': Icons.set_meal,
  'mediterranean': Icons.lightbulb,
  'korean': Icons.emoji_food_beverage,
  'vietnamese': Icons.spa,
};

const _cuisineColors = <Color>[
  Color(0xFFFF6F00), Color(0xFF2E7D32), Color(0xFFC62828), Color(0xFF1565C0),
  Color(0xFFF9A825), Color(0xFF6A1B9A), Color(0xFF37474F), Color(0xFFE65100),
  Color(0xFF00838F), Color(0xFF5D4037), Color(0xFF7B1FA2), Color(0xFF00695C),
  Color(0xFFD84315), Color(0xFF283593), Color(0xFFAD1457), Color(0xFF33691E),
  Color(0xFF4E342E), Color(0xFF0277BD), Color(0xFFF06292), Color(0xFF00ACC1),
];

IconData _cuisineIcon(String name) => _cuisineIcons[name] ?? Icons.restaurant;
