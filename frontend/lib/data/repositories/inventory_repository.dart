import '../datasources/remote/api_client.dart';
import '../models/recipe_model.dart';
import '../../core/constants/api_constants.dart';

class InventoryRepository {
  final ApiClient _client;

  InventoryRepository(this._client);

  Future<List<InventoryItemModel>> getInventory({String kitchenProfile = 'basic_north_indian_veg'}) async {
    final response = await _client.get(ApiConstants.inventory, params: {
      'kitchen_profile': kitchenProfile,
    });
    final List data = response.data['items'] ?? [];
    return data.map((e) => InventoryItemModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> voiceUpdate(String text, {String language = 'hi'}) async {
    final response = await _client.post(ApiConstants.voiceInventory, data: {
      'text': text,
      'language': language,
    });
    return response.data;
  }

  Future<void> confirmVoiceUpdate(String text, {String language = 'hi'}) async {
    await _client.post(ApiConstants.voiceConfirm, data: {
      'text': text,
      'language': language,
    });
  }

  Future<List<Map<String, dynamic>>> getUseSoon() async {
    final response = await _client.get(ApiConstants.useSoon);
    final List data = response.data['items'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> deleteItem(String itemId) async {
    await _client.delete('${ApiConstants.inventory}/$itemId');
  }

  Future<List<Map<String, dynamic>>> getMissingIngredientOpportunities() async {
    final response = await _client.get(ApiConstants.missingIngredients);
    final List data = response.data['opportunities'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}
