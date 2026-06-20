import 'package:hive/hive.dart';

part 'translation_record.g.dart';

/// 翻译记录模型
/// 存储网页翻译的历史信息
@HiveType(typeId: 1)
class TranslationRecord extends HiveObject {
  /// 唯一标识
  @HiveField(0)
  final String id;
  
  /// 网页URL
  @HiveField(1)
  final String url;
  
  /// 网页标题
  @HiveField(2)
  final String title;
  
  /// 原文内容
  @HiveField(3)
  final String originalText;
  
  /// 译文内容
  @HiveField(4)
  final String translatedText;
  
  /// 源语言
  @HiveField(5)
  final String sourceLanguage;
  
  /// 目标语言
  @HiveField(6)
  final String targetLanguage;
  
  /// 创建时间
  @HiveField(7)
  final DateTime createdAt;
  
  /// 是否已收藏
  @HiveField(8)
  bool isFavorite;
  
  /// 收藏分类
  @HiveField(9)
  String? favoriteCategory;
  
  /// 使用的API名称
  @HiveField(10)
  final String? apiName;
  
  /// 使用的模型名称
  @HiveField(11)
  final String? modelName;
  
  /// 缓存键（用于翻译缓存）
  @HiveField(12)
  final String? cacheKey;

  TranslationRecord({
    required this.id,
    required this.url,
    required this.title,
    required this.originalText,
    required this.translatedText,
    this.sourceLanguage = 'auto',
    this.targetLanguage = 'zh-CN',
    DateTime? createdAt,
    this.isFavorite = false,
    this.favoriteCategory,
    this.apiName,
    this.modelName,
    this.cacheKey,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 创建翻译记录的副本
  TranslationRecord copyWith({
    String? id,
    String? url,
    String? title,
    String? originalText,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? createdAt,
    bool? isFavorite,
    String? favoriteCategory,
    String? apiName,
    String? modelName,
    String? cacheKey,
  }) {
    return TranslationRecord(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      favoriteCategory: favoriteCategory ?? this.favoriteCategory,
      apiName: apiName ?? this.apiName,
      modelName: modelName ?? this.modelName,
      cacheKey: cacheKey ?? this.cacheKey,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'favoriteCategory': favoriteCategory,
      'apiName': apiName,
      'modelName': modelName,
      'cacheKey': cacheKey,
    };
  }

  /// 从JSON创建
  factory TranslationRecord.fromJson(Map<String, dynamic> json) {
    return TranslationRecord(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLanguage: json['sourceLanguage'] as String? ?? 'auto',
      targetLanguage: json['targetLanguage'] as String? ?? 'zh-CN',
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      favoriteCategory: json['favoriteCategory'] as String?,
      apiName: json['apiName'] as String?,
      modelName: json['modelName'] as String?,
      cacheKey: json['cacheKey'] as String?,
    );
  }

  /// 获取摘要（用于显示）
  String get summary {
    if (originalText.length > 50) {
      return '${originalText.substring(0, 50)}...';
    }
    return originalText;
  }

  /// 获取格式化的创建时间
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  String toString() {
    return 'TranslationRecord(id: $id, url: $url, title: $title, createdAt: $createdAt)';
  }
}