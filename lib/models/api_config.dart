import 'package:hive/hive.dart';

part 'api_config.g.dart';

/// API配置模型
/// 存储翻译API的连接信息
@HiveType(typeId: 0)
class ApiConfig extends HiveObject {
  /// API名称（如：DeepSeek、Mimo、GPT）
  @HiveField(0)
  final String name;
  
  /// API端点地址
  @HiveField(1)
  final String endpoint;
  
  /// API密钥
  @HiveField(2)
  final String apiKey;
  
  /// 模型名称
  @HiveField(3)
  final String model;
  
  /// 自定义系统Prompt（可选）
  @HiveField(4)
  final String? systemPrompt;
  
  /// 是否为当前激活的API
  @HiveField(5)
  bool isActive;
  
  /// 创建时间
  @HiveField(6)
  final DateTime createdAt;
  
  /// 最后使用时间
  @HiveField(7)
  DateTime? lastUsedAt;

  ApiConfig({
    required this.name,
    required this.endpoint,
    required this.apiKey,
    required this.model,
    this.systemPrompt,
    this.isActive = false,
    DateTime? createdAt,
    this.lastUsedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 创建API配置的副本
  ApiConfig copyWith({
    String? name,
    String? endpoint,
    String? apiKey,
    String? model,
    String? systemPrompt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return ApiConfig(
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'endpoint': endpoint,
      'apiKey': apiKey,
      'model': model,
      'systemPrompt': systemPrompt,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  /// 从JSON创建
  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      name: json['name'] as String,
      endpoint: json['endpoint'] as String,
      apiKey: json['apiKey'] as String,
      model: json['model'] as String,
      systemPrompt: json['systemPrompt'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  /// 预设API配置模板
  static List<ApiConfig> get presets => [
        ApiConfig(
          name: 'DeepSeek',
          endpoint: 'https://api.deepseek.com',
          apiKey: '',
          model: 'deepseek-v4-flash',
        ),
        ApiConfig(
          name: 'Mimo',
          endpoint: 'https://api.mimo.ai',
          apiKey: '',
          model: 'mimo-v2-flash',
        ),
      ];

  @override
  String toString() {
    return 'ApiConfig(name: $name, endpoint: $endpoint, model: $model, isActive: $isActive)';
  }
}