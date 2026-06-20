import 'package:flutter/material.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';

/// URL输入栏组件
class UrlBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final double loadProgress;
  final ValueChanged<String> onSubmit;
  final VoidCallback onMenuPressed;
  final VoidCallback onTabPressed;
  final VoidCallback onMorePressed;
  final VoidCallback onFavoritePressed;
  final VoidCallback onClearPressed;
  final int tabCount;

  const UrlBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.loadProgress,
    required this.onSubmit,
    required this.onMenuPressed,
    required this.onTabPressed,
    required this.onMorePressed,
    required this.onFavoritePressed,
    required this.onClearPressed,
    required this.tabCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // URL输入区
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacing8,
              vertical: AppDimens.spacing8,
            ),
            child: Row(
              children: [
                // 菜单按钮
                _IconButton(
                  icon: Icons.menu,
                  onTap: onMenuPressed,
                ),
                
                // URL输入框
                Expanded(
                  child: Container(
                    height: AppDimens.buttonHeight,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 网站图标
                        const Padding(
                          padding: EdgeInsets.only(left: AppDimens.spacing12),
                          child: Icon(
                            Icons.language,
                            size: AppDimens.iconSizeSmall,
                          ),
                        ),
                        
                        // URL输入框
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: theme.textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              hintText: AppStrings.urlHint,
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppDimens.spacing8,
                                vertical: 0,
                              ),
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.go,
                            onSubmitted: onSubmit,
                          ),
                        ),
                        
                        // 清除按钮
                        if (controller.text.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              controller.clear();
                              onClearPressed();
                            },
                            icon: const Icon(
                              Icons.close,
                              size: AppDimens.iconSizeSmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // 收藏按钮
                _IconButton(
                  icon: Icons.favorite_border,
                  onTap: onFavoritePressed,
                ),
                
                // 标签页按钮
                _TabCountButton(
                  count: tabCount,
                  onPressed: onTabPressed,
                ),
                
                // 更多按钮
                _IconButton(
                  icon: Icons.more_vert,
                  onTap: onMorePressed,
                ),
              ],
            ),
          ),
          
          // 加载进度条
          if (isLoading)
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: loadProgress > 0 ? loadProgress : null,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 图标按钮
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusButton),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacing8),
        child: Icon(
          icon,
          size: AppDimens.iconSizeMedium,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}

/// 标签页计数按钮
class _TabCountButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _TabCountButton({
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: AppDimens.iconSizeMedium,
        height: AppDimens.iconSizeMedium,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeCaption,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}