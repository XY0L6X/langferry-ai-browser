import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';

/// 通用列表项组件
/// 左侧图标、中间标题+副标题、右侧箭头/开关
class ListTileItem extends StatelessWidget {
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool isSelected;

  const ListTileItem({
    super.key,
    this.leadingIcon,
    this.leadingIconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        ListTile(
          leading: leadingIcon != null
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                  ),
                  child: Icon(
                    leadingIcon,
                    size: AppDimens.iconSizeMedium,
                    color: leadingIconColor ??
                        (isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant),
                  ),
                )
              : null,
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? theme.colorScheme.primary : null,
              fontWeight: isSelected ? FontWeight.w500 : null,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: leadingIcon != null ? 72 : 16,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
      ],
    );
  }
}

/// 带开关的列表项
class SwitchListItem extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchListItem({
    super.key,
    this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTileItem(
      leadingIcon: leadingIcon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }
}

/// 带单选的列表项
class RadioListItem<T> extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;
  final String? subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const RadioListItem({
    super.key,
    this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTileItem(
      leadingIcon: leadingIcon,
      title: title,
      subtitle: subtitle,
      trailing: Radio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      ),
      isSelected: value == groupValue,
      onTap: () => onChanged(value),
    );
  }
}

/// 带计数的列表项
class CountListItem extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;
  final String? subtitle;
  final int count;
  final VoidCallback? onTap;

  const CountListItem({
    super.key,
    this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTileItem(
      leadingIcon: leadingIcon,
      title: title,
      subtitle: subtitle,
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing8,
          vertical: AppDimens.spacing4,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Text(
          count.toString(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeCaption,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}