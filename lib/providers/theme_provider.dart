import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../core/constants/app_strings.dart';
import '../models/search_engine.dart';

/// 主题模式状态管理
enum ThemeModeOption {
  light,
  dark,
  system,
}

/// 主题模式状态提供者
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeModeOption>(
  (ref) => ThemeModeNotifier(),
);

/// 主题模式状态通知器
class ThemeModeNotifier extends StateNotifier<ThemeModeOption> {
  ThemeModeNotifier() : super(_loadSavedMode()) {
    // 监听状态变化并保存
   addListener((_) => _saveMode(state));
  }
  
  /// 从Hive加载保存的主题模式
  static ThemeModeOption _loadSavedMode() {
    try {
      final box = Hive.box('settings');
      final savedMode = box.get('theme_mode', defaultValue: 'system');
      switch (savedMode) {
        case 'light':
          return ThemeModeOption.light;
        case 'dark':
          return ThemeModeOption.dark;
        default:
          return ThemeModeOption.system;
      }
    } catch (e) {
      return ThemeModeOption.system;
    }
  }
  
  /// 保存主题模式到Hive
  void _saveMode(ThemeModeOption mode) {
    try {
      final box = Hive.box('settings');
      box.put('theme_mode', mode.name);
    } catch (e) {
      // 忽略保存错误
    }
  }
  
  /// 切换主题模式
  void setThemeMode(ThemeModeOption mode) {
    state = mode;
  }
  
  /// 获取Flutter的ThemeMode
  ThemeMode get flutterThemeMode {
    switch (state) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }
}

/// 主题模式显示名称提供者
final themeModeDisplayNameProvider = Provider<String>((ref) {
  final mode = ref.watch(themeModeProvider);
  switch (mode) {
    case ThemeModeOption.light:
      return '浅色模式';
    case ThemeModeOption.dark:
      return '深色模式';
    case ThemeModeOption.system:
      return '跟随系统';
  }
});

/// 主题模式图标提供者
final themeModeIconProvider = Provider<IconData>((ref) {
  final mode = ref.watch(themeModeProvider);
  switch (mode) {
    case ThemeModeOption.light:
      return Icons.light_mode_outlined;
    case ThemeModeOption.dark:
      return Icons.dark_mode_outlined;
    case ThemeModeOption.system:
      return Icons.brightness_auto_outlined;
  }
});

/// 字体大小状态提供者
final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, String>(
  (ref) => FontSizeNotifier(),
);

/// 字体大小状态通知器
class FontSizeNotifier extends StateNotifier<String> {
  FontSizeNotifier() : super(_loadSavedFontSize()) {
    addListener((_) => _saveFontSize(state));
  }
  
  /// 从Hive加载保存的字体大小
  static String _loadSavedFontSize() {
    try {
      final box = Hive.box('settings');
      return box.get('font_size', defaultValue: 'normal');
    } catch (e) {
      return 'normal';
    }
  }
  
  /// 保存字体大小到Hive
  void _saveFontSize(String size) {
    try {
      final box = Hive.box('settings');
      box.put('font_size', size);
    } catch (e) {
      // 忽略保存错误
    }
  }
  
  /// 设置字体大小
  void setFontSize(String size) {
    state = size;
  }
  
  /// 获取字体缩放因子
  double get fontScale {
    switch (state) {
      case 'xsmall':
        return 0.8;
      case 'small':
        return 0.9;
      case 'large':
        return 1.1;
      case 'xlarge':
        return 1.2;
      default:
        return 1.0;
    }
  }
  
  /// 获取字体大小名称
  String get displayName {
    switch (state) {
      case 'xsmall':
        return '超小';
      case 'small':
        return '小';
      case 'large':
        return '大';
      case 'xlarge':
        return '超大';
      default:
        return '正常';
    }
  }
}

// ==================== 搜索引擎 ====================

/// 搜索引擎选择提供者
final searchEngineProvider = StateNotifierProvider<SearchEngineNotifier, String>(
  (ref) => SearchEngineNotifier(),
);

/// 搜索引擎状态通知器
class SearchEngineNotifier extends StateNotifier<String> {
  SearchEngineNotifier() : super(_loadSavedEngine()) {
    addListener((_) => _saveEngine(state));
  }

  static String _loadSavedEngine() {
    try {
      final box = Hive.box('settings');
      return box.get('search_engine', defaultValue: 'google');
    } catch (e) {
      return 'google';
    }
  }

  void _saveEngine(String engineId) {
    try {
      final box = Hive.box('settings');
      box.put('search_engine', engineId);
    } catch (e) {
      // 忽略保存错误
    }
  }

  void setEngine(String engineId) {
    state = engineId;
  }
}

// ==================== PaddleOCR ====================

final paddleOcrTokenProvider = StateNotifierProvider<PaddleOcrNotifier, String>(
  (ref) => PaddleOcrNotifier(),
);

final paddleOcrModelProvider = StateNotifierProvider<PaddleOcrModelNotifier, String>(
  (ref) => PaddleOcrModelNotifier(),
);

class PaddleOcrNotifier extends StateNotifier<String> {
  PaddleOcrNotifier() : super(_loadSaved()) {
    addListener((_) => _save(state));
  }

  static String _loadSaved() {
    try {
      final box = Hive.box('settings');
      return box.get('paddleocr_token', defaultValue: '');
    } catch (e) {
      return '';
    }
  }

  void _save(String value) {
    try {
      final box = Hive.box('settings');
      box.put('paddleocr_token', value);
    } catch (e) {}
  }

  void setToken(String token) {
    state = token;
  }
}

/// PaddleOCR 模型选择
class PaddleOcrModelNotifier extends StateNotifier<String> {
  PaddleOcrModelNotifier() : super(_loadSaved()) {
    addListener((_) => _save(state));
  }

  static String _loadSaved() {
    try {
      final box = Hive.box('settings');
      return box.get('paddleocr_model', defaultValue: 'PaddleOCR-VL-1.6');
    } catch (e) {
      return 'PaddleOCR-VL-1.6';
    }
  }

  void _save(String value) {
    try {
      final box = Hive.box('settings');
      box.put('paddleocr_model', value);
    } catch (e) {}
  }

  void setModel(String model) {
    state = model;
  }

  static const List<String> availableModels = [
    'PaddleOCR-VL-1.6',
    'PP-OCRv6',
    'PP-StructureV3',
  ];
}

// ==================== 自动 OCR ====================

final autoOcrProvider = StateNotifierProvider<AutoOcrNotifier, bool>(
  (ref) => AutoOcrNotifier(),
);

class AutoOcrNotifier extends StateNotifier<bool> {
  AutoOcrNotifier() : super(_loadSaved()) {
    addListener((_) => _save(state));
  }

  static bool _loadSaved() {
    try {
      final box = Hive.box('settings');
      return box.get('auto_ocr', defaultValue: false);
    } catch (e) {
      return false;
    }
  }

  void _save(bool value) {
    try {
      final box = Hive.box('settings');
      box.put('auto_ocr', value);
    } catch (e) {}
  }

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

// ==================== 自动翻译 ====================

/// 自动翻译开关提供者
final autoTranslateProvider = StateNotifierProvider<AutoTranslateNotifier, bool>(
  (ref) => AutoTranslateNotifier(),
);

class AutoTranslateNotifier extends StateNotifier<bool> {
  AutoTranslateNotifier() : super(_loadSaved()) {
    addListener((_) => _save(state));
  }

  static bool _loadSaved() {
    try {
      final box = Hive.box('settings');
      return box.get('auto_translate', defaultValue: false);
    } catch (e) {
      return false;
    }
  }

  void _save(bool value) {
    try {
      final box = Hive.box('settings');
      box.put('auto_translate', value);
    } catch (e) {}
  }

  void toggle() {
    state = !state;
  }

  void set(bool value) {
    state = value;
  }
}