import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/database_service.dart';
import 'core/services/log_service.dart';
import 'core/utils/platform_utils.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据库
  await DatabaseService.instance.init();
  
  // 初始化日志服务
  await LogService.instance.init();
  
  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  
  // 设置屏幕方向
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    const ProviderScope(
      child: WebLingoApp(),
    ),
  );
}