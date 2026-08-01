import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../datasources/remote/api_client.dart';
import '../../core/constants/api_constants.dart';

class ShoppingItemModel {
  final String id;
  final String? ingredientId;
  final String name;
  final String? quantity;
  final String? unit;
  final String status;
  final String? notes;

  ShoppingItemModel({
    required this.id,
    this.ingredientId,
    required this.name,
    this.quantity,
    this.unit,
    required this.status,
    this.notes,
  });

  bool get isBought => status == 'bought';

  ShoppingItemModel copyWith({
    String? id,
    String? ingredientId,
    String? name,
    String? quantity,
    String? unit,
    String? status,
    String? notes,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  factory ShoppingItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingItemModel(
      id: json['id']?.toString() ?? '',
      ingredientId: json['ingredient_id']?.toString(),
      name: (json['name'] ?? json['ingredient_name'] ?? '').toString(),
      quantity: json['quantity']?.toString(),
      unit: json['unit']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredient_id': ingredientId,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'status': status,
        'notes': notes,
      };
}

class ShoppingRepository {
  static const _prefsKey = 'shopping_list_local_v1';
  final ApiClient _client;

  ShoppingRepository(this._client);

  Future<List<ShoppingItemModel>> getShoppingList() async {
    final local = await _loadLocal();
    try {
      final response = await _client.get(ApiConstants.shoppingList);
      final List data = response.data['items'] ?? [];
      final remote = data
          .map((e) => ShoppingItemModel.fromJson((e as Map).cast<String, dynamic>()))
          .where((e) => e.name.trim().isNotEmpty)
          .toList();
      final merged = _mergeById([...remote, ...local]);
      await _saveLocal(merged);
      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<Map<String, dynamic>> toggleItem(String itemId) async {
    final items = await _loadLocal();
    await _saveLocal(items
        .map((item) => item.id == itemId
            ? item.copyWith(status: item.isBought ? 'pending' : 'bought')
            : item)
        .toList());
    try {
      final response = await _client.post('/shopping/$itemId/toggle');
      return response.data;
    } catch (_) {
      return {'message': 'Item toggled locally'};
    }
  }

  Future<Map<String, dynamic>> removeItem(String itemId) async {
    final items = await _loadLocal();
    await _saveLocal(items.where((item) => item.id != itemId).toList());
    try {
      final response = await _client.delete('/shopping/$itemId');
      return response.data;
    } catch (_) {
      return {'message': 'Item removed locally'};
    }
  }

  Future<Map<String, dynamic>> addItem(String name, {String? quantity, String? unit}) async {
    final item = ShoppingItemModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      quantity: _clean(quantity),
      unit: _clean(unit),
      status: 'pending',
    );
    final items = await _loadLocal();
    await _saveLocal([...items, item]);
    return {'message': 'Added locally', 'item_id': item.id};
  }

  String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  List<ShoppingItemModel> _mergeById(List<ShoppingItemModel> items) {
    final seen = <String>{};
    final merged = <ShoppingItemModel>[];
    for (final item in items) {
      final key = item.id.isNotEmpty ? item.id : item.name.toLowerCase();
      if (seen.add(key)) merged.add(item);
    }
    return merged;
  }

  Future<List<ShoppingItemModel>> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ShoppingItemModel.fromJson((e as Map).cast<String, dynamic>()))
          .where((e) => e.name.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocal(List<ShoppingItemModel> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}
