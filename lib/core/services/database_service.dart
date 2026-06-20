import 'package:hive_flutter/hive_flutter.dart';
import '../../models/api_config.dart';
import '../../models/translation_record.dart';
import '../../models/favorite_item.dart';
import '../../models/usage_record.dart';
import '../constants/app_strings.dart';

/// 数据库服务
/// 管理Hive本地存储
class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  
  DatabaseService._();
  
  bool _isInitialized = false;
  
  /// 初始化数据库
  Future<void> init() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    
    // 注册适配器
    Hive.registerAdapter(ApiConfigAdapter());
    Hive.registerAdapter(TranslationRecordAdapter());
    Hive.registerAdapter(FavoriteItemAdapter());
    Hive.registerAdapter(UsageRecordAdapter());
    
    // 打开Box
    await Hive.openBox<ApiConfig>(AppStrings.boxApiConfigs);
    await Hive.openBox<TranslationRecord>(AppStrings.boxHistory);
    await Hive.openBox<FavoriteItem>(AppStrings.boxFavorites);
    await Hive.openBox(AppStrings.boxSettings);
    await Hive.openBox(AppStrings.boxTranslationCache);
    await Hive.openBox<UsageRecord>('usage_records');
    
    _isInitialized = true;
  }
  
  // ==================== API配置相关 ====================
  
  /// 获取API配置Box
  Box<ApiConfig> get _apiConfigsBox => Hive.box<ApiConfig>(AppStrings.boxApiConfigs);
  
  /// 获取所有API配置
  List<ApiConfig> getAllApiConfigs() {
    return _apiConfigsBox.values.toList();
  }
  
  /// 获取激活的API配置
  ApiConfig? getActiveApiConfig() {
    try {
      return _apiConfigsBox.values.firstWhere((config) => config.isActive);
    } catch (e) {
      return null;
    }
  }
  
  /// 保存API配置
  Future<void> saveApiConfig(ApiConfig config) async {
    await _apiConfigsBox.put(config.name, config);
  }
  
  /// 删除API配置
  Future<void> deleteApiConfig(String name) async {
    await _apiConfigsBox.delete(name);
  }
  
  /// 设置激活的API
  Future<void> setActiveApi(String name) async {
    final configs = getAllApiConfigs();
    for (final config in configs) {
      if (config.name == name) {
        await saveApiConfig(config.copyWith(isActive: true));
      } else if (config.isActive) {
        await saveApiConfig(config.copyWith(isActive: false));
      }
    }
  }
  
  // ==================== 翻译历史相关 ====================
  
  /// 获取历史记录Box
  Box<TranslationRecord> get _historyBox => Hive.box<TranslationRecord>(AppStrings.boxHistory);
  
  /// 获取所有历史记录
  List<TranslationRecord> getAllHistory() {
    final records = _historyBox.values.toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }
  
  /// 获取收藏的历史记录
  List<TranslationRecord> getFavoriteHistory() {
    return getAllHistory().where((record) => record.isFavorite).toList();
  }
  
  /// 搜索历史记录
  List<TranslationRecord> searchHistory(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllHistory().where((record) {
      return record.title.toLowerCase().contains(lowercaseQuery) ||
          record.url.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
  
  /// 保存翻译记录
  Future<void> saveTranslationRecord(TranslationRecord record) async {
    await _historyBox.put(record.id, record);
  }
  
  /// 删除翻译记录
  Future<void> deleteTranslationRecord(String id) async {
    await _historyBox.delete(id);
  }
  
  /// 清空所有历史记录
  Future<void> clearAllHistory() async {
    await _historyBox.clear();
  }
  
  /// 切换收藏状态
  Future<void> toggleFavorite(String id) async {
    final record = _historyBox.get(id);
    if (record != null) {
      await _historyBox.put(id, record.copyWith(isFavorite: !record.isFavorite));
    }
  }
  
  // ==================== 收藏夹相关 ====================
  
  /// 获取收藏夹Box
  Box<FavoriteItem> get _favoritesBox => Hive.box<FavoriteItem>(AppStrings.boxFavorites);
  
  /// 获取所有收藏
  List<FavoriteItem> getAllFavorites() {
    final items = _favoritesBox.values.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }
  
  /// 按分类获取收藏
  List<FavoriteItem> getFavoritesByCategory(String category) {
    return getAllFavorites().where((item) => item.category == category).toList();
  }
  
  /// 获取所有收藏分类
  List<String> getAllCategories() {
    final categories = <String>{};
    for (final item in getAllFavorites()) {
      if (item.category != null) {
        categories.add(item.category!);
      }
    }
    return categories.toList()..sort();
  }
  
  /// 搜索收藏
  List<FavoriteItem> searchFavorites(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllFavorites().where((item) {
      return item.title.toLowerCase().contains(lowercaseQuery) ||
          item.url.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
  
  /// 保存收藏
  Future<void> saveFavorite(FavoriteItem item) async {
    await _favoritesBox.put(item.id, item);
  }
  
  /// 删除收藏
  Future<void> deleteFavorite(String id) async {
    await _favoritesBox.delete(id);
  }
  
  /// 检查是否已收藏
  bool isFavorite(String url) {
    return _favoritesBox.values.any((item) => item.url == url);
  }
  
  // ==================== 设置相关 ====================
  
  /// 获取设置Box
  Box get _settingsBox => Hive.box(AppStrings.boxSettings);
  
  /// 获取设置值
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }
  
  /// 保存设置值
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }
  
  /// 删除设置值
  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }
  
  // ==================== 翻译缓存相关 ====================
  
  /// 获取缓存Box
  Box get _cacheBox => Hive.box(AppStrings.boxTranslationCache);
  
  /// 获取缓存的翻译
  String? getCachedTranslation(String cacheKey) {
    return _cacheBox.get(cacheKey) as String?;
  }
  
  /// 保存翻译缓存
  Future<void> saveTranslationCache(String cacheKey, String translation) async {
    await _cacheBox.put(cacheKey, translation);
  }
  
  /// 清除翻译缓存
  Future<void> clearTranslationCache() async {
    await _cacheBox.clear();
  }
  
  // ==================== 数据管理 ====================
  
  /// 导出所有数据
  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'apiConfigs': getAllApiConfigs().map((c) {
        final json = c.toJson();
        json.remove('apiKey');
        json['hasApiKey'] = c.apiKey.isNotEmpty;
        return json;
      }).toList(),
      'history': getAllHistory().map((r) => r.toJson()).toList(),
      'favorites': getAllFavorites().map((f) => f.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
  
  /// 导入数据
  Future<void> importData(Map<String, dynamic> data) async {
    // 导入API配置
    if (data['apiConfigs'] != null) {
      for (final configJson in data['apiConfigs']) {
        final config = ApiConfig.fromJson(configJson);
        await saveApiConfig(config);
      }
    }
    
    // 导入历史记录
    if (data['history'] != null) {
      for (final recordJson in data['history']) {
        final record = TranslationRecord.fromJson(recordJson);
        await saveTranslationRecord(record);
      }
    }
    
    // 导入收藏
    if (data['favorites'] != null) {
      for (final favoriteJson in data['favorites']) {
        final favorite = FavoriteItem.fromJson(favoriteJson);
        await saveFavorite(favorite);
      }
    }
  }
  
  /// 清除所有数据
  Future<void> clearAllData() async {
    await _apiConfigsBox.clear();
    await _historyBox.clear();
    await _favoritesBox.clear();
    await _settingsBox.clear();
    await _cacheBox.clear();
  }

  // ==================== 用量记录 ====================

  Box<UsageRecord> get _usageBox => Hive.box<UsageRecord>('usage_records');

  Future<void> saveUsageRecord(UsageRecord record) async {
    await _usageBox.put(record.id, record);
  }

  List<UsageRecord> getAllUsageRecords() {
    return _usageBox.values.toList();
  }

  Future<void> clearUsageRecords() async {
    await _usageBox.clear();
  }
}