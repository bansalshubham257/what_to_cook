class RecipeModel {
  final String id;
  final String name;
  final String? description;
  final String? cuisineId;
  final String? cuisineName;
  final List<String>? mealTypes;
  final String? dietType;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int totalTimeMinutes;
  final String? difficulty;
  final int servings;
  final String? instructions;
  final int healthScore;
  final String? healthCategory;
  final String? imageUrl;
  final List<String>? tags;
  final List<RecipeIngredientModel>? ingredients;

  RecipeModel({
    required this.id,
    required this.name,
    this.description,
    this.cuisineId,
    this.cuisineName,
    this.mealTypes,
    this.dietType,
    this.prepTimeMinutes = 0,
    this.cookTimeMinutes = 0,
    this.totalTimeMinutes = 0,
    this.difficulty,
    this.servings = 2,
    this.instructions,
    this.healthScore = 50,
    this.healthCategory,
    this.imageUrl,
    this.tags,
    this.ingredients,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      cuisineId: json['cuisine_id'],
      cuisineName: json['cuisine_name'],
      mealTypes: json['meal_types'] != null ? List<String>.from(json['meal_types']) : null,
      dietType: json['diet_type'],
      prepTimeMinutes: json['prep_time_minutes'] ?? 0,
      cookTimeMinutes: json['cook_time_minutes'] ?? 0,
      totalTimeMinutes: json['total_time_minutes'] ?? 0,
      difficulty: json['difficulty'],
      servings: json['servings'] ?? 2,
      instructions: json['instructions'],
      healthScore: json['health_score'] ?? 50,
      healthCategory: json['health_category'],
      imageUrl: json['image_url'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List).map((e) => RecipeIngredientModel.fromJson(e)).toList()
          : null,
    );
  }
}

class RecipeIngredientModel {
  final String? ingredientId;
  final String? name;
  final String? quantity;
  final String? unit;
  final bool isRequired;
  final String? notes;

  RecipeIngredientModel({
    this.ingredientId,
    this.name,
    this.quantity,
    this.unit,
    this.isRequired = true,
    this.notes,
  });

  factory RecipeIngredientModel.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientModel(
      ingredientId: json['ingredient_id']?.toString(),
      name: json['name'],
      quantity: json['quantity'],
      unit: json['unit'],
      isRequired: json['is_required'] ?? true,
      notes: json['notes'],
    );
  }
}

class RecommendationModel {
  final RecipeModel recipe;
  final double score;
  final List<String> reasons;
  final int availableIngredientsCount;
  final int missingIngredientsCount;
  final List<String> missingIngredients;
  final List<String> useSoonIngredients;
  final bool isFavorite;

  RecommendationModel({
    required this.recipe,
    required this.score,
    required this.reasons,
    required this.availableIngredientsCount,
    required this.missingIngredientsCount,
    required this.missingIngredients,
    required this.useSoonIngredients,
    this.isFavorite = false,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      recipe: RecipeModel.fromJson(json['recipe'] ??
          (json['id'] != null ? json : json['recipe'] ?? {})),
      score: (json['score'] ?? 0).toDouble(),
      reasons: List<String>.from(json['reasons'] ?? []),
      availableIngredientsCount: json['available_ingredients_count'] ?? 0,
      missingIngredientsCount: json['missing_ingredients_count'] ?? 0,
      missingIngredients: List<String>.from(json['missing_ingredients'] ?? []),
      useSoonIngredients: List<String>.from(json['use_soon_ingredients'] ?? []),
      isFavorite: json['is_favorite'] ?? false,
    );
  }
}

class InventoryItemModel {
  final String id;
  final String ingredientId;
  final String name;
  final String category;
  final String status;
  final String? quantity;
  final String? unit;
  final String? dateAdded;
  final int? freshnessWindowDays;

  InventoryItemModel({
    required this.id,
    required this.ingredientId,
    required this.name,
    required this.category,
    required this.status,
    this.quantity,
    this.unit,
    this.dateAdded,
    this.freshnessWindowDays,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    final ingredient = json['ingredient'] ?? {};
    return InventoryItemModel(
      id: json['id'] ?? '',
      ingredientId: json['ingredient_id'] ?? ingredient['id'] ?? '',
      name: ingredient['display_name_en'] ?? json['ingredient_name'] ?? '',
      category: ingredient['category'] ?? '',
      status: json['status'] ?? 'available',
      quantity: json['quantity'],
      unit: json['unit'],
      dateAdded: json['date_added'],
      freshnessWindowDays: json['freshness_window_days'],
    );
  }
}

class MealHistoryModel {
  final String id;
  final String recipeId;
  final String recipeName;
  final String? recipeImage;
  final String mealType;
  final String cookedDate;
  final String? healthCategory;

  MealHistoryModel({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    this.recipeImage,
    required this.mealType,
    required this.cookedDate,
    this.healthCategory,
  });

  factory MealHistoryModel.fromJson(Map<String, dynamic> json) {
    return MealHistoryModel(
      id: json['id'] ?? '',
      recipeId: json['recipe_id'] ?? '',
      recipeName: json['recipe_name'] ?? '',
      recipeImage: json['recipe_image'],
      mealType: json['meal_type'] ?? '',
      cookedDate: json['cooked_date'] ?? '',
      healthCategory: json['health_category'],
    );
  }
}
