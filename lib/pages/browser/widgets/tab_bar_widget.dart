import 'package:flutter/material.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';

/// 标签页数据模型
class TabItem {
  final String id;
  final String url;
  final String title;

  const TabItem({
    required this.id,
    required this.url,
    required this.title,
  });

  TabItem copyWith({String? id, String? url, String? title}) {
    return TabItem(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
    );
  }
}

/// 标签栏组件
class TabBarWidget extends StatelessWidget {
  final List<TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<int> onTabClosed;
  final VoidCallback onAddTab;

  const TabBarWidget({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onAddTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: AppDimens.tabBarHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacing8,
              ),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = index == currentIndex;
                
                return _TabItemWidget(
                  tab: tab,
                  isSelected: isSelected,
                  onTap: () => onTabSelected(index),
                  onClose: tabs.length > 1
                      ? () => onTabClosed(index)
                      : null,
                );
              },
            ),
          ),
          IconButton(
            onPressed: onAddTab,
            icon: const Icon(
              Icons.add,
              size: AppDimens.iconSizeMedium,
            ),
            tooltip: AppStrings.newTabTooltip,
          ),
        ],
      ),
    );
  }
}

/// 单个标签项
class _TabItemWidget extends StatelessWidget {
  final TabItem tab;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  const _TabItemWidget({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 160,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing4,
          vertical: AppDimens.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacing8,
                ),
                child: Text(
                  tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ),
            if (onClose != null)
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.spacing4),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}