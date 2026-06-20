import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 平台工具类
/// 处理安卓原生交互和适配
class PlatformUtils {
  PlatformUtils._();
  
  /// 拦截系统返回键
  static Future<bool> onWillPop(BuildContext context) async {
    // TODO: 检查WebView是否可以后退
    // 如果可以后退，先后退网页
    
    // 如果在首页，弹出退出确认
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出应用'),
        content: const Text('再按一次退出'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    
    return confirmed ?? false;
  }
  
  /// 设置状态栏样式
  static void setStatusBarStyle({required Brightness brightness}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: brightness,
      ),
    );
  }
  
  /// 设置导航栏样式
  static void setNavigationBarStyle({required Brightness brightness}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }
  
  /// 开启Edge-to-Edge模式
  static void enableEdgeToEdge() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }
  
  /// 设置屏幕方向
  static void setOrientation(List<DeviceOrientation> orientations) {
    SystemChrome.setPreferredOrientations(orientations);
  }
  
  /// 保持屏幕常亮
  static void keepScreenOn({required bool keepOn}) {
    if (keepOn) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    }
  }
}

/// 页面路由动画工具
class RouteAnimations {
  RouteAnimations._();
  
  /// 淡入淡出过渡
  static Route<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }
  
  /// 从底部滑入过渡
  static Route<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;
        
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  /// 从右侧滑入过渡
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;
        
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  /// 缩放过渡
  static Route<T> scaleTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        
        return ScaleTransition(
          scale: scaleAnimation,
          child: child,
        );
      },
    );
  }
}

/// 按压缩放效果
class PressScaleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const PressScaleEffect({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
  });

  @override
  State<PressScaleEffect> createState() => _PressScaleEffectState();
}

class _PressScaleEffectState extends State<PressScaleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}