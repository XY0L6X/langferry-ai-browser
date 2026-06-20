import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';

/// 底部导航栏组件
/// 5个Tab项：浏览器、历史、收藏、下载、设置
class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: AppDimens.bottomNavBarHeight,
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.primary.withOpacity(0.1),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.language_outlined),
          selectedIcon: Icon(Icons.language),
          label: AppStrings.navBrowser,
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: AppStrings.navHistory,
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: AppStrings.navFavorites,
        ),
        NavigationDestination(
          icon: Icon(Icons.download_outlined),
          selectedIcon: Icon(Icons.download),
          label: '下载',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: AppStrings.navSettings,
        ),
      ],
    );
  }
}