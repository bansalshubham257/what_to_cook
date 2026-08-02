import '../datasources/remote/api_client.dart';
import '../models/recipe_model.dart';
import '../../core/constants/api_constants.dart';

class RecipeRepository {
  final ApiClient _client;

  RecipeRepository(this._client);

  Future<List<RecommendationModel>> getRecommendations({
    String? mealType,
    String? cuisine,
    String? intent,
    int limit = 5,
  }) async {
    final response = await _client.get(ApiConstants.recommendations, params: {
      if (mealType != null) 'meal_type': mealType,
      if (cuisine != null) 'cuisine': cuisine,
      if (intent != null) 'intent': intent,
      'limit': limit,
    });
    final List data = response.data['recommendations'] ?? [];
    return data.map((e) => RecommendationModel.fromJson(e)).toList();
  }

  Future<RecipeModel> getRecipeDetail(String id) async {
    final response = await _client.get('${ApiConstants.recipeDetail}/$id');
    return RecipeModel.fromJson(response.data);
  }

  Future<List<RecipeModel>> searchRecipes(
    String query, {
    bool favorites = false,
    String? cuisine,
    String? mealType,
    int limit = 20,
  }) async {
    final response = await _client.get(ApiConstants.recipeSearch, params: {
      'q': query,
      if (favorites) 'favorites': 1,
      if (cuisine != null) 'cuisine': cuisine,
      if (mealType != null) 'meal_type': mealType,
      'limit': limit,
    });
    final List data = response.data['recipes'] ?? [];
    return data.map((e) => RecipeModel.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getCuisines() async {
    final response = await _client.get(ApiConstants.cuisines);
    final List data = response.data['cuisines'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<RecipeModel>> getFavorites() async {
    final response = await _client.get(ApiConstants.favorites);
    final List data = response.data['recipes'] ?? [];
    return data.map((e) => RecipeModel.fromJson(e)).toList();
  }

  Future<List<RecipeModel>> naturalSearch(String query) async {
    final response = await _client.post('${ApiConstants.recipeSearch}/natural', data: {'query': query});
    final List data = response.data['recipes'] ?? [];
    return data.map((e) => RecipeModel.fromJson(e)).toList();
  }

  /// Asks the AI to fill in recipe details (description, time, ingredients,
  /// difficulty, ...) for a dish the user added to a category with just a name.
  Future<Map<String, dynamic>> enrichDish(String name,
      {String? cuisine, String? mealType}) async {
    final response = await _client.post(ApiConstants.enrichDish, data: {
      'name': name,
      if (cuisine != null && cuisine.isNotEmpty) 'cuisine': cuisine,
      if (mealType != null && mealType.isNotEmpty) 'meal_type': mealType,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> surpriseMe() async {
    final response = await _client.get(ApiConstants.surpriseMe);
    return response.data;
  }

  Future<void> logMeal(String recipeId, String mealType, {Map<String, dynamic>? feedback}) async {
    await _client.post(ApiConstants.logMeal, data: {
      'recipe_id': recipeId,
      'meal_type': mealType,
      if (feedback != null) 'feedback': feedback,
    });
  }

  /// Logs a curated/user dish that may not exist in the recipes table, so it
  /// shows up in meal history and insights. The backend finds or creates a
  /// recipe by name using the dish details provided.
  Future<void> logDish({
    required String name,
    required String mealType,
    String? cuisine,
    String? healthCategory,
    String? dietType,
    int? timeMinutes,
    String? description,
  }) async {
    await _client.post(ApiConstants.logDish, data: {
      'name': name,
      'meal_type': mealType,
      if (cuisine != null && cuisine.isNotEmpty) 'cuisine': cuisine,
      if (healthCategory != null && healthCategory.isNotEmpty) 'health_category': healthCategory,
      if (dietType != null && dietType.isNotEmpty) 'diet_type': dietType,
      if (timeMinutes != null && timeMinutes > 0) 'time_minutes': timeMinutes,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }

  Future<List<MealHistoryModel>> getMealHistory({int days = 30}) async {
    final response = await _client.get(ApiConstants.mealHistory, params: {'days': days});
    final List data = response.data['meals'] ?? [];
    return data.map((e) => MealHistoryModel.fromJson(e)).toList();
  }

  Future<void> favoriteRecipe(String recipeId) async {
    await _client.post('${ApiConstants.recipeDetail}/$recipeId/favorite');
  }

  Future<void> unfavoriteRecipe(String recipeId) async {
    await _client.delete('${ApiConstants.recipeDetail}/$recipeId/favorite');
  }

  Future<Set<String>> getFavoriteIds() async {
    final response = await _client.get(ApiConstants.favoriteIds);
    final List ids = response.data['ids'] ?? [];
    return ids.cast<String>().toSet();
  }

  Future<List<RecommendationModel>> getAiRecommendations({
    String? mealType,
    String? intent,
    int limit = 5,
  }) async {
    final response = await _client.get('${ApiConstants.recommendations}ai', params: {
      if (mealType != null) 'meal_type': mealType,
      if (intent != null && intent.isNotEmpty) 'intent': intent,
      'limit': limit,
    });
    final List data = response.data['recommendations'] ?? [];
    return data.map((e) => RecommendationModel.fromJson(e)).toList();
  }
}
