import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'pages/main_page.dart';

class WebLingoApp extends ConsumerWidget {
  const WebLingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeOption = ref.watch(themeModeProvider);
    final themeMode = ref.read(themeModeProvider.notifier).flutterThemeMode;
    final fontScale = ref.watch(fontSizeProvider);
    
    double scale = 1.0;
    switch (fontScale) {
      case 'xsmall':
        scale = 0.8;
        break;
      case 'small':
        scale = 0.9;
        break;
      case 'large':
        scale = 1.1;
        break;
      case 'xlarge':
        scale = 1.2;
        break;
      default:
        scale = 1.0;
    }
    
    return MaterialApp(
      title: '文渡',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        );
      },
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: const MainPage(),
    );
  }
}