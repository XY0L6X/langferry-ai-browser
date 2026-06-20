import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';

/// 通用错误页组件
/// 包含错误图标、提示文字、重试按钮
class ErrorPlaceholder extends StatelessWidget {
  final String? message;
  final String? retryText;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool compact;

  const ErrorPlaceholder({
    super.key,
    this.message,
    this.retryText,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (compact) {
      return _CompactError(
        message: message ?? AppStrings.errorUnknown,
        retryText: retryText,
        onRetry: onRetry,
        icon: icon,
      );
    }
    
    return _FullError(
      message: message ?? AppStrings.errorUnknown,
      retryText: retryText,
      onRetry: onRetry,
      icon: icon,
    );
  }
}

/// 全屏错误页
class _FullError extends StatelessWidget {
  final String message;
  final String? retryText;
  final VoidCallback? onRetry;
  final IconData icon;

  const _FullError({
    required this.message,
    this.retryText,
    this.onRetry,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 错误图标
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: AppDimens.spacing16),
            
            // 错误信息
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            
            // 重试按钮
            if (onRetry != null) ...[
              const SizedBox(height: AppDimens.spacing24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 紧凑型错误提示
class _CompactError extends StatelessWidget {
  final String message;
  final String? retryText;
  final VoidCallback? onRetry;
  final IconData icon;

  const _CompactError({
    required this.message,
    this.retryText,
    this.onRetry,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusButton),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimens.iconSizeMedium,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: AppDimens.spacing12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(retryText ?? AppStrings.retry),
            ),
        ],
      ),
    );
  }
}