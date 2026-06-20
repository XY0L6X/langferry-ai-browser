import '../../models/usage_record.dart';
import '../core/services/database_service.dart';

/// 用量追踪服务（通过 Provider 注入）
class UsageTracker {
  final DatabaseService _database;

  UsageTracker(this._database);

  /// 记录一次翻译消耗
  Future<void> recordUsage({
    required String model,
    required int promptTokens,
    required int completionTokens,
    String? pageUrl,
    String? pageTitle,
    int translatedItems = 0,
  }) async {
    final cost = UsageRecord.calculateCost(model, promptTokens, completionTokens);
    final record = UsageRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      time: DateTime.now(),
      model: model,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      cost: cost,
      pageUrl: pageUrl,
      pageTitle: pageTitle,
      translatedItems: translatedItems,
    );
    await _database.saveUsageRecord(record);
  }

  /// 获取今日消费汇总
  double getTodayCost() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _database.getAllUsageRecords()
        .where((r) => r.time.isAfter(startOfDay))
        .fold(0.0, (sum, r) => sum + r.cost);
  }

  /// 获取本月消费汇总
  double getMonthCost() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _database.getAllUsageRecords()
        .where((r) => r.time.isAfter(startOfMonth))
        .fold(0.0, (sum, r) => sum + r.cost);
  }

  /// 获取总消费
  double getTotalCost() {
    return _database.getAllUsageRecords()
        .fold(0.0, (sum, r) => sum + r.cost);
  }

  /// 获取今日 Token 用量
  int getTodayTokens() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _database.getAllUsageRecords()
        .where((r) => r.time.isAfter(startOfDay))
        .fold(0, (sum, r) => sum + r.totalTokens);
  }

  /// 获取所有记录（最新在前）
  List<UsageRecord> getAllRecords() {
    final records = _database.getAllUsageRecords();
    records.sort((a, b) => b.time.compareTo(a.time));
    return records;
  }

  /// 按天分组的消费汇总
  Map<String, double> getDailyCosts({int days = 30}) {
    final costs = <String, double>{};
    for (final r in getAllRecords()) {
      final key = '${r.time.month}/${r.time.day}';
      costs[key] = (costs[key] ?? 0) + r.cost;
    }
    return costs;
  }
}
