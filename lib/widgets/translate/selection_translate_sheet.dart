import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/translation_provider.dart';

/// 划词翻译底部面板
/// 使用DraggableScrollableSheet实现
class SelectionTranslateSheet extends ConsumerStatefulWidget {
  final String originalText;
  final String? selectedModel;
  final ValueChanged<String>? onModelChanged;

  const SelectionTranslateSheet({
    super.key,
    required this.originalText,
    this.selectedModel,
    this.onModelChanged,
  });

  @override
  ConsumerState<SelectionTranslateSheet> createState() =>
      _SelectionTranslateSheetState();
}

class _SelectionTranslateSheetState
    extends ConsumerState<SelectionTranslateSheet> {
  String? _selectedModel;
  String _translatedText = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.selectedModel;
    _startTranslation();
  }

  @override
  void dispose() {
    // 重置翻译状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(translationProvider.notifier).reset();
    });
    super.dispose();
  }

  void _startTranslation() {
    setState(() {
      _isLoading = true;
    });

    final translationService = ref.read(translationServiceProvider);

    translationService
        .translate(
      text: widget.originalText,
      targetLanguage: 'zh-CN',
    )
        .then((result) {
      if (mounted) {
        setState(() {
          _translatedText = result.translatedText;
          _isLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('翻译失败: $error')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimens.radiusBottomSheet),
            ),
          ),
          child: Column(
            children: [
              // 拖拽指示条
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(
                    vertical: AppDimens.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 顶部：模型选择
              _buildModelSelector(theme),

              const Divider(height: 1),

              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppDimens.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 原文区域
                      _buildOriginalSection(theme),

                      const SizedBox(height: AppDimens.spacing16),

                      // 分割线
                      Divider(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),

                      const SizedBox(height: AppDimens.spacing16),

                      // 译文区域
                      _buildTranslatedSection(theme),
                    ],
                  ),
                ),
              ),

              // 底部操作栏
              _buildActionBar(theme),
            ],
          ),
        );
      },
    );
  }

  /// 模型选择器
  Widget _buildModelSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacing16,
        vertical: AppDimens.spacing8,
      ),
      child: Row(
        children: [
          Text(
            AppStrings.selectModel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: AppDimens.spacing8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacing8,
              vertical: AppDimens.spacing4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusButton),
            ),
            child: DropdownButton<String>(
              value: _selectedModel,
              underline: const SizedBox(),
              isDense: true,
              items: const [
                DropdownMenuItem(
                  value: 'deepseek',
                  child: Text('DeepSeek'),
                ),
                DropdownMenuItem(
                  value: 'mimo',
                  child: Text('Mimo'),
                ),
                DropdownMenuItem(
                  value: 'gpt4',
                  child: Text('GPT-4o'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedModel = value;
                });
                widget.onModelChanged?.call(value ?? '');
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 原文区域
  Widget _buildOriginalSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.sourceLanguage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppDimens.spacing8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimens.spacing12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          child: SelectableText(
            widget.originalText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: AppDimens.fontSizeCaption,
            ),
          ),
        ),
      ],
    );
  }

  /// 译文区域
  Widget _buildTranslatedSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.targetLanguage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.spacing8),

        if (_isLoading)
          _buildLoadingPlaceholder(theme)
        else if (_translatedText.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.spacing12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDimens.radiusButton),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: SelectableText(
              _translatedText,
              style: theme.textTheme.bodyLarge,
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.spacing12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppDimens.radiusButton),
            ),
            child: Text(
              '等待翻译...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
      ],
    );
  }

  /// 加载占位符
  Widget _buildLoadingPlaceholder(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.spacing12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimens.radiusButton),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(
              bottom: AppDimens.spacing8,
            ),
            height: 14,
            width: index == 2 ? 120 : double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  /// 底部操作栏
  Widget _buildActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacing16,
        vertical: AppDimens.spacing12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 复制按钮
          _ActionButton(
            icon: Icons.copy,
            label: AppStrings.copy,
            onTap: () {
              final textToCopy =
                  _translatedText.isNotEmpty ? _translatedText : widget.originalText;
              Clipboard.setData(ClipboardData(text: textToCopy));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.copySuccess)),
              );
            },
          ),

          // 收藏按钮
          _ActionButton(
            icon: Icons.favorite_outline,
            label: AppStrings.collect,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.collectSuccess)),
              );
            },
          ),

          // 分享按钮
          _ActionButton(
            icon: Icons.share,
            label: AppStrings.share,
            onTap: () {
              // TODO: 实现分享功能
            },
          ),
        ],
      ),
    );
  }
}

/// 操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusButton),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing16,
          vertical: AppDimens.spacing8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppDimens.iconSizeMedium,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: AppDimens.spacing4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}