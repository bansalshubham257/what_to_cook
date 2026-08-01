import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recipe_model.dart';

/// Simple in-memory cache that persists for the app session
class RecommendationCache {
  final Map<String, CachedRecommendation> _cache = {};
  final Duration ttl = const Duration(hours: 1);

  CachedRecommendation? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > ttl) {
      _cache.remove(key);
      return null;
    }
    return entry;
  }

  void set(String key, CachedRecommendation value) {
    _cache[key] = value;
  }

  void clear() => _cache.clear();
}

class CachedRecommendation {
  final List<RecommendationModel> recommendations;
  final DateTime timestamp;

  CachedRecommendation({required this.recommendations})
      : timestamp = DateTime.now();
}

/// Cache for kitchen inventory - persists for app session
class KitchenCache {
  final Map<String, CachedKitchen> _cache = {};
  final Duration ttl = const Duration(hours: 1);

  CachedKitchen? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > ttl) {
      _cache.remove(key);
      return null;
    }
    return entry;
  }

  void set(String key, CachedKitchen value) {
    _cache[key] = value;
  }

  void clear() => _cache.clear();
}

class CachedKitchen {
  final List<InventoryItemModel> items;
  final DateTime timestamp;

  CachedKitchen({required this.items})
      : timestamp = DateTime.now();
}

final recommendationCacheProvider = Provider<RecommendationCache>((ref) {
  return RecommendationCache();
});

final kitchenCacheProvider = Provider<KitchenCache>((ref) {
  return KitchenCache();
});