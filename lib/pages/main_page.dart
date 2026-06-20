import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_dimens.dart';
import '../core/utils/platform_utils.dart';
import '../widgets/common/main_bottom_nav.dart';
import 'browser/browser_page.dart';
import 'history/history_page.dart';
import 'favorite/favorite_page.dart';
import 'download/download_page.dart';
import 'settings/settings_page.dart';

/// 主页面
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;
  
  // 全局URL加载回调
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final List<Function(String)> _urlCallbacks = [];
  
  static void registerUrlCallback(Function(String) callback) {
    _urlCallbacks.add(callback);
  }
  
  static void loadUrl(String url) {
    for (final callback in _urlCallbacks) {
      callback(url);
    }
  }

  @override
  void initState() {
    super.initState();
    PlatformUtils.enableEdgeToEdge();
  }

  void _openUrl(String url) {
    setState(() {
      _currentIndex = 0;
    });
    // 使用回调加载URL
    loadUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    
    PlatformUtils.setStatusBarStyle(brightness: brightness);
    PlatformUtils.setNavigationBarStyle(brightness: brightness);
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final now = DateTime.now();
        if (_lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('再按一次退出'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: IndexedStack(
            index: _currentIndex,
            children: [
              BrowserPage(onUrlLoaded: _registerBrowserCallback),
              HistoryPage(onUrlSelected: _openUrl),
              FavoritePage(onUrlSelected: _openUrl),
              const DownloadPage(),
              const SettingsPage(),
            ],
          ),
        ),
        bottomNavigationBar: MainBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
  
  void _registerBrowserCallback(Function(String) callback) {
    _urlCallbacks.add(callback);
  }
}