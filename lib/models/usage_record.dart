import 'package:hive/hive.dart';

part 'usage_record.g.dart';

/// 消费记录
@HiveType(typeId: 2)
class UsageRecord extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime time;
  @HiveField(2)
  final String model;
  @HiveField(3)
  final int promptTokens;
  @HiveField(4)
  final int completionTokens;
  @HiveField(5)
  final double cost; // 人民币元
  @HiveField(6)
  final String? pageUrl;
  @HiveField(7)
  final String? pageTitle;
  @HiveField(8)
  final int translatedItems; // 翻译节点数

  UsageRecord({
    required this.id,
    required this.time,
    required this.model,
    required this.promptTokens,
    required this.completionTokens,
    required this.cost,
    this.pageUrl,
    this.pageTitle,
    this.translatedItems = 0,
  });

  int get totalTokens => promptTokens + completionTokens;

  String get formattedCost => '¥${cost.toStringAsFixed(6)}';

  String get formattedTokens {
    if (totalTokens >= 1000) {
      return '${(totalTokens / 1000).toStringAsFixed(1)}K';
    }
    return totalTokens.toString();
  }

  /// 模型定价（元/百万 tokens）
  static double getModelPriceInput(String model) {
    if (model.contains('deepseek')) return 0.004;
    if (model.contains('gpt-4')) return 0.15;
    if (model.contains('gpt-3.5')) return 0.003;
    return 0.004; // 默认
  }

  static double getModelPriceOutput(String model) {
    if (model.contains('deepseek')) return 0.012;
    if (model.contains('gpt-4')) return 0.60;
    if (model.contains('gpt-3.5')) return 0.006;
    return 0.012; // 默认
  }

  /// 计算费用
  static double calculateCost(String model, int promptTokens, int completionTokens) {
    final inputCost = (promptTokens / 1000000) * getModelPriceInput(model);
    final outputCost = (completionTokens / 1000000) * getModelPriceOutput(model);
    return inputCost + outputCost;
  }
}
