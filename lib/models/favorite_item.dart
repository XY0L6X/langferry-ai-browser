import 'package:hive/hive.dart';

part 'favorite_item.g.dart';

/// 收藏夹项目模型
/// 存储用户收藏的网页信息
@HiveType(typeId: 2)
class FavoriteItem extends HiveObject {
  /// 唯一标识
  @HiveField(0)
  final String id;
  
  /// 网页URL
  @HiveField(1)
  final String url;
  
  /// 网页标题
  @HiveField(2)
  final String title;
  
  /// 收藏分类
  @HiveField(3)
  String? category;
  
  /// 创建时间
  @HiveField(4)
  final DateTime createdAt;
  
  /// 缩略图URL（可选）
  @HiveField(5)
  String? thumbnail;
  
  /// 网页描述（可选）
  @HiveField(6)
  String? description;
  
  /// 是否已翻译
  @HiveField(7)
  bool isTranslated;
  
  /// 最后翻译时间
  @HiveField(8)
  DateTime? lastTranslatedAt;

  FavoriteItem({
    required this.id,
    required this.url,
    required this.title,
    this.category,
    DateTime? createdAt,
    this.thumbnail,
    this.description,
    this.isTranslated = false,
    this.lastTranslatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 创建收藏项目的副本
  FavoriteItem copyWith({
    String? id,
    String? url,
    String? title,
    String? category,
    DateTime? createdAt,
    String? thumbnail,
    String? description,
    bool? isTranslated,
    DateTime? lastTranslatedAt,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      thumbnail: thumbnail ?? this.thumbnail,
      description: description ?? this.description,
      isTranslated: isTranslated ?? this.isTranslated,
      lastTranslatedAt: lastTranslatedAt ?? this.lastTranslatedAt,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'thumbnail': thumbnail,
      'description': description,
      'isTranslated': isTranslated,
      'lastTranslatedAt': lastTranslatedAt?.toIso8601String(),
    };
  }

  /// 从JSON创建
  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      thumbnail: json['thumbnail'] as String?,
      description: json['description'] as String?,
      isTranslated: json['isTranslated'] as bool? ?? false,
      lastTranslatedAt: json['lastTranslatedAt'] != null
          ? DateTime.parse(json['lastTranslatedAt'] as String)
          : null,
    );
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

  /// 获取域名
  String get domain {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  /// 预设收藏分类
  static List<String> get defaultCategories => [
        '技术',
        '新闻',
        '学习',
        '工作',
        '娱乐',
        '其他',
      ];

  @override
  String toString() {
    return 'FavoriteItem(id: $id, url: $url, title: $title, category: $category)';
  }
}