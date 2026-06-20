import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/database_provider.dart';
import '../../models/translation_record.dart';
import '../../models/favorite_item.dart';

/// 历史记录页面
class HistoryPage extends ConsumerStatefulWidget {
  final ValueChanged<String>? onUrlSelected;
  
  const HistoryPage({
    super.key,
    this.onUrlSelected,
  });

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 按日期分组
  Map<String, List<TranslationRecord>> _groupByDate(List<TranslationRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final Map<String, List<TranslationRecord>> grouped = {
      AppStrings.today: [],
      AppStrings.yesterday: [],
      AppStrings.earlier: [],
    };
    
    for (final record in records) {
      final recordDate = DateTime(
        record.createdAt.year,
        record.createdAt.month,
        record.createdAt.day,
      );
      
      if (recordDate.isAtSameMomentAs(today)) {
        grouped[AppStrings.today]!.add(record);
      } else if (recordDate.isAtSameMomentAs(yesterday)) {
        grouped[AppStrings.yesterday]!.add(record);
      } else {
        grouped[AppStrings.earlier]!.add(record);
      }
    }
    
    return grouped;
  }

  /// 获取过滤后的记录
  List<TranslationRecord> _getFilteredHistory(List<TranslationRecord> history) {
    if (_searchQuery.isEmpty) return history;
    
    return history.where((record) {
      return record.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          record.url.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<TranslationRecord> records) {
    setState(() {
      if (_selectedIds.length == records.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(records.map((r) => r.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    final historyNotifier = ref.read(historyProvider.notifier);
    for (final id in _selectedIds) {
      await historyNotifier.deleteRecord(id);
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = ref.watch(historyProvider);
    final filteredHistory = _getFilteredHistory(history);
    final groupedHistory = _groupByDate(filteredHistory);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${AppStrings.selectedCount.replaceAll('%d', _selectedIds.length.toString())}')
            : const Text(AppStrings.historyTitle),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              onPressed: () => _selectAll(filteredHistory),
              icon: Icon(
                _selectedIds.length == filteredHistory.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              tooltip: AppStrings.selectAll,
            ),
            IconButton(
              onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
              icon: const Icon(Icons.delete),
              tooltip: AppStrings.delete,
            ),
            IconButton(
              onPressed: _toggleSelectionMode,
              icon: const Icon(Icons.close),
              tooltip: AppStrings.cancel,
            ),
          ] else ...[
            if (history.isNotEmpty)
              IconButton(
                onPressed: _toggleSelectionMode,
                icon: const Icon(Icons.checklist),
                tooltip: AppStrings.batchManage,
              ),
            if (history.isNotEmpty)
              IconButton(
                onPressed: _showClearAllDialog,
                icon: const Icon(Icons.delete_sweep),
                tooltip: AppStrings.clearAll,
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(AppDimens.spacing16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchHistory,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // 历史列表
          Expanded(
            child: filteredHistory.isEmpty
                ? _buildEmptyState(theme)
                : _buildHistoryList(theme, groupedHistory),
          ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimens.spacing16),
          Text(
            _searchQuery.isEmpty ? AppStrings.noHistory : AppStrings.noMatchHistory,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 历史列表
  Widget _buildHistoryList(ThemeData theme, Map<String, List<TranslationRecord>> grouped) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacing16,
      ),
      itemCount: _calculateItemCount(grouped),
      itemBuilder: (context, index) {
        return _buildListItem(context, theme, grouped, index);
      },
    );
  }

  int _calculateItemCount(Map<String, List<TranslationRecord>> grouped) {
    int count = 0;
    for (final entry in grouped.entries) {
      if (entry.value.isNotEmpty) {
        count += 1 + entry.value.length; // 标题 + 列表项
      }
    }
    return count;
  }

  Widget _buildListItem(
    BuildContext context,
    ThemeData theme,
    Map<String, List<TranslationRecord>> grouped,
    int index,
  ) {
    int currentIndex = 0;
    
    for (final entry in grouped.entries) {
      if (entry.value.isEmpty) continue;
      
      // 日期标题
      if (currentIndex == index) {
        return Padding(
          padding: const EdgeInsets.only(
            top: AppDimens.spacing16,
            bottom: AppDimens.spacing8,
          ),
          child: Text(
            entry.key,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        );
      }
      currentIndex++;
      
      // 列表项
      for (int i = 0; i < entry.value.length; i++) {
        if (currentIndex == index) {
          final record = entry.value[i];
          final isSelected = _selectedIds.contains(record.id);
          
          return _HistoryItem(
            record: record,
            isSelected: isSelected,
            isSelectionMode: _isSelectionMode,
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(record.id);
              } else if (record.url.isNotEmpty) {
                // 跳转到浏览器页面并打开URL
                if (widget.onUrlSelected != null) {
                  widget.onUrlSelected!(record.url);
                }
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                _toggleSelectionMode();
              }
              _toggleSelection(record.id);
            },
            onDelete: () async {
              await ref.read(historyProvider.notifier).deleteRecord(record.id);
            },
            onToggleFavorite: () async {
              // 添加到收藏夹
              final favoriteItem = FavoriteItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                url: record.url,
                title: record.title.isNotEmpty ? record.title : record.url,
                category: '其他',
              );
              await ref.read(favoritesProvider.notifier).addFavorite(favoriteItem);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已添加到收藏')),
                );
              }
            },
          );
        }
        currentIndex++;
      }
    }
    
    return const SizedBox();
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.clearAll),
        content: const Text(AppStrings.clearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(historyProvider.notifier).clearAll();
              if (mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }
}

/// 历史记录项
class _HistoryItem extends StatelessWidget {
  final TranslationRecord record;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _HistoryItem({
    required this.record,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(
        bottom: AppDimens.spacing8,
      ),
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.1)
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacing12),
          child: Row(
            children: [
              // 选择框或图标
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                  ),
                  child: const Icon(
                    Icons.language,
                    size: AppDimens.iconSizeMedium,
                  ),
                ),
              
              const SizedBox(width: AppDimens.spacing12),
              
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacing4),
                    Text(
                      record.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppDimens.spacing4),
                    Text(
                      record.formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 操作按钮
              if (!isSelectionMode) ...[
                IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    record.isFavorite ? Icons.favorite : Icons.favorite_outline,
                    color: record.isFavorite ? theme.colorScheme.error : null,
                    size: AppDimens.iconSizeSmall,
                  ),
                  tooltip: record.isFavorite ? '取消收藏' : '收藏',
                ),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 8),
                          Text(AppStrings.delete),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}