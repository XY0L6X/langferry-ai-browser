import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/database_service.dart';
import 'usage_provider.dart';
import '../models/api_config.dart';
import '../models/translation_record.dart';
import '../models/favorite_item.dart';
import '../models/usage_record.dart';

/// 数据库服务提供者
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

/// API配置列表提供者
final apiConfigsProvider = StateNotifierProvider<ApiConfigsNotifier, List<ApiConfig>>((ref) {
  final database = ref.watch(databaseServiceProvider);
  return ApiConfigsNotifier(database);
});

/// API配置状态通知器
class ApiConfigsNotifier extends StateNotifier<List<ApiConfig>> {
  final DatabaseService _database;
  
  ApiConfigsNotifier(this._database) : super([]) {
    _loadConfigs();
  }
  
  void _loadConfigs() {
    state = _database.getAllApiConfigs();
  }
  
  Future<void> addConfig(ApiConfig config) async {
    await _database.saveApiConfig(config);
    _loadConfigs();
  }
  
  Future<void> updateConfig(ApiConfig config) async {
    await _database.saveApiConfig(config);
    _loadConfigs();
  }
  
  Future<void> deleteConfig(String name) async {
    await _database.deleteApiConfig(name);
    _loadConfigs();
  }
  
  Future<void> setActive(String name) async {
    await _database.setActiveApi(name);
    _loadConfigs();
  }
  
  ApiConfig? getActiveConfig() {
    try {
      return state.firstWhere((c) => c.isActive);
    } catch (e) {
      return null;
    }
  }
}

/// 翻译历史列表提供者
final historyProvider = StateNotifierProvider<HistoryNotifier, List<TranslationRecord>>((ref) {
  final database = ref.watch(databaseServiceProvider);
  return HistoryNotifier(database);
});

/// 翻译历史状态通知器
class HistoryNotifier extends StateNotifier<List<TranslationRecord>> {
  final DatabaseService _database;
  
  HistoryNotifier(this._database) : super([]) {
    _loadHistory();
  }
  
  void _loadHistory() {
    state = _database.getAllHistory();
  }
  
  Future<void> addRecord(TranslationRecord record) async {
    try {
      await _database.saveTranslationRecord(record);
      _loadHistory();
    } catch (e) {
      if (kDebugMode) print('[HistoryNotifier] 保存历史失败: $e');
    }
  }
  
  Future<void> deleteRecord(String id) async {
    await _database.deleteTranslationRecord(id);
    _loadHistory();
  }
  
  Future<void> clearAll() async {
    await _database.clearAllHistory();
    _loadHistory();
  }
  
  Future<void> toggleFavorite(String id) async {
    await _database.toggleFavorite(id);
    _loadHistory();
  }
  
  List<TranslationRecord> search(String query) {
    return _database.searchHistory(query);
  }
  
  List<TranslationRecord> getFavorites() {
    return _database.getFavoriteHistory();
  }
}

/// 收藏夹列表提供者
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<FavoriteItem>>((ref) {
  final database = ref.watch(databaseServiceProvider);
  return FavoritesNotifier(database);
});

/// 收藏夹状态通知器
class FavoritesNotifier extends StateNotifier<List<FavoriteItem>> {
  final DatabaseService _database;
  
  FavoritesNotifier(this._database) : super([]) {
    _loadFavorites();
  }
  
  void _loadFavorites() {
    state = _database.getAllFavorites();
  }
  
  Future<void> addFavorite(FavoriteItem item) async {
    await _database.saveFavorite(item);
    _loadFavorites();
  }
  
  Future<void> deleteFavorite(String id) async {
    await _database.deleteFavorite(id);
    _loadFavorites();
  }
  
  Future<void> updateFavorite(FavoriteItem item) async {
    await _database.saveFavorite(item);
    _loadFavorites();
  }
  
  List<FavoriteItem> getByCategory(String category) {
    return _database.getFavoritesByCategory(category);
  }
  
  List<String> getAllCategories() {
    return _database.getAllCategories();
  }
  
  List<FavoriteItem> search(String query) {
    return _database.searchFavorites(query);
  }
  
  bool isFavorite(String url) {
    return _database.isFavorite(url);
  }
}

/// 当前激活的API配置提供者
final activeApiConfigProvider = Provider<ApiConfig?>((ref) {
  final configs = ref.watch(apiConfigsProvider);
  try {
    return configs.firstWhere((c) => c.isActive);
  } catch (e) {
    return null;
  }
});

/// 翻译缓存提供者
final translationCacheProvider = Provider<TranslationCacheService>((ref) {
  final database = ref.watch(databaseServiceProvider);
  return TranslationCacheService(database);
});

/// 翻译缓存服务
class TranslationCacheService {
  final DatabaseService _database;
  
  TranslationCacheService(this._database);
  
  String? getCachedTranslation(String cacheKey) {
    return _database.getCachedTranslation(cacheKey);
  }
  
  Future<void> saveTranslation(String cacheKey, String translation) async {
    await _database.saveTranslationCache(cacheKey, translation);
  }
  
  Future<void> clearCache() async {
    await _database.clearTranslationCache();
  }
}

// ==================== 用量追踪 ====================

final usageTrackerProvider = Provider<UsageTracker>((ref) {
  final database = ref.watch(databaseServiceProvider);
  return UsageTracker(database);
});