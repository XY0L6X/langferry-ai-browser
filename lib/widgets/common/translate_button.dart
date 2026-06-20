import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';

/// 翻译按钮状态枚举
enum TranslateButtonState {
  idle,      // 空闲（原文）
  loading,   // 加载中（翻译中）
  success,   // 完成（译文）
  failed,    // 失败
}

/// 通用翻译按钮组件
/// 支持4种状态：空闲、加载中、完成、失败
class TranslateButton extends StatelessWidget {
  final TranslateButtonState state;
  final VoidCallback? onPressed;
  final String? customText;

  const TranslateButton({
    super.key,
    this.state = TranslateButtonState.idle,
    this.onPressed,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: AppDimens.durationNormal),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: _buildButton(context, theme),
    );
  }

  Widget _buildButton(BuildContext context, ThemeData theme) {
    switch (state) {
      case TranslateButtonState.idle:
        return _IdleButton(
          key: const ValueKey('idle'),
          onPressed: onPressed,
          text: customText ?? AppStrings.translate,
        );
      case TranslateButtonState.loading:
        return _LoadingButton(
          key: const ValueKey('loading'),
          text: customText ?? AppStrings.translating,
        );
      case TranslateButtonState.success:
        return _SuccessButton(
          key: const ValueKey('success'),
          onPressed: onPressed,
          text: customText ?? AppStrings.translateComplete,
        );
      case TranslateButtonState.failed:
        return _FailedButton(
          key: const ValueKey('failed'),
          onPressed: onPressed,
          text: customText ?? AppStrings.translateRetry,
        );
    }
  }
}

/// 空闲状态按钮
class _IdleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const _IdleButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        Icons.translate,
        size: AppDimens.iconSizeSmall,
      ),
      label: Text(text),
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing12,
          vertical: AppDimens.spacing8,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 加载中状态按钮
class _LoadingButton extends StatelessWidget {
  final String text;

  const _LoadingButton({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FilledButton.icon(
      onPressed: null,
      icon: SizedBox(
        width: AppDimens.iconSizeSmall,
        height: AppDimens.iconSizeSmall,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.colorScheme.onPrimary,
          ),
        ),
      ),
      label: Text(text),
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.7),
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing12,
          vertical: AppDimens.spacing8,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 完成状态按钮
class _SuccessButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const _SuccessButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        Icons.check_circle_outline,
        size: AppDimens.iconSizeSmall,
      ),
      label: Text(text),
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing12,
          vertical: AppDimens.spacing8,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 失败状态按钮
class _FailedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const _FailedButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        Icons.refresh,
        size: AppDimens.iconSizeSmall,
      ),
      label: Text(text),
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing12,
          vertical: AppDimens.spacing8,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}