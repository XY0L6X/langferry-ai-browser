import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../models/usage_record.dart';

class UsageLedgerPage extends ConsumerWidget {
  const UsageLedgerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(usageTrackerProvider);
    final records = tracker.getAllRecords();
    final todayCost = tracker.getTodayCost();
    final monthCost = tracker.getMonthCost();
    final totalCost = tracker.getTotalCost();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('消费明细')),
      body: Column(
        children: [
          // 汇总卡片
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CostTile('今日', '¥${todayCost.toStringAsFixed(4)}'),
                _CostTile('本月', '¥${monthCost.toStringAsFixed(4)}'),
                _CostTile('总计', '¥${totalCost.toStringAsFixed(4)}'),
              ],
            ),
          ),
          // 记录列表
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Text('暂无消费记录', style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    )),
                  )
                : ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final r = records[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          r.pageTitle ?? '翻译 ${r.translatedItems} 个文本段',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          '${r.model} · ${r.formattedTokens} tokens · ${r.time.hour}:${r.time.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          r.formattedCost,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CostTile extends StatelessWidget {
  final String label;
  final String value;
  const _CostTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        )),
      ],
    );
  }
}
