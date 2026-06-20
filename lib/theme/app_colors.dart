import 'package:flutter/material.dart';

/// 浅色主题颜色常量
class AppColorsLight {
  AppColorsLight._();
  
  // ==================== 主色 ====================
  static const Color primary = Color(0xFF165DFF);
  static const Color primaryLight = Color(0xFF4080FF);
  static const Color primaryDark = Color(0xFF0045CC);
  static const Color primarySurface = Color(0xFFE8F0FF);
  
  // ==================== 中性色 ====================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray100 = Color(0xFFF7F8FA);
  static const Color gray200 = Color(0xFFF2F3F5);
  static const Color gray300 = Color(0xFFE5E6EB);
  static const Color gray400 = Color(0xFFC9CDD4);
  static const Color gray500 = Color(0xFF86909C);
  static const Color gray600 = Color(0xFF4E5969);
  static const Color gray700 = Color(0xFF1D2129);
  
  // ==================== 文字色 ====================
  static const Color textPrimary = Color(0xFF1D2129);
  static const Color textSecondary = Color(0xFF4E5969);
  static const Color textTertiary = Color(0xFF86909C);
  static const Color textDisabled = Color(0xFFC9CDD4);
  
  // ==================== 背景色 ====================
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F3F5);
  
  // ==================== 分割线 ====================
  static const Color divider = Color(0xFFE5E6EB);
  static const Color border = Color(0xFFE5E6EB);
  
  // ==================== 语义色 ====================
  static const Color success = Color(0xFF00B42A);
  static const Color successSurface = Color(0xFFE8FFEA);
  static const Color warning = Color(0xFFFF7D00);
  static const Color warningSurface = Color(0xFFFFF7E8);
  static const Color error = Color(0xFFF53F3F);
  static const Color errorSurface = Color(0xFFFFECE8);
  
  // ==================== 状态色 ====================
  static const Color disabled = Color(0xFFF2F3F5);
  static const Color hover = Color(0xFFF2F3F5);
  static const Color pressed = Color(0xFFE5E6EB);
}

/// 深色主题颜色常量
class AppColorsDark {
  AppColorsDark._();
  
  // ==================== 主色 ====================
  static const Color primary = Color(0xFF4080FF);
  static const Color primaryLight = Color(0xFF6B9FFF);
  static const Color primaryDark = Color(0xFF165DFF);
  static const Color primarySurface = Color(0xFF1A2A4A);
  
  // ==================== 中性色 ====================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray100 = Color(0xFF2E3238);
  static const Color gray200 = Color(0xFF3D4249);
  static const Color gray300 = Color(0xFF4E5969);
  static const Color gray400 = Color(0xFF7D8791);
  static const Color gray500 = Color(0xFFA9AEB8);
  static const Color gray600 = Color(0xFFC9CDD4);
  static const Color gray700 = Color(0xFFE5E6EB);
  
  // ==================== 文字色 ====================
  static const Color textPrimary = Color(0xFFE5E6EB);
  static const Color textSecondary = Color(0xFFC9CDD4);
  static const Color textTertiary = Color(0xFF86909C);
  static const Color textDisabled = Color(0xFF4E5969);
  
  // ==================== 背景色 ====================
  static const Color background = Color(0xFF17171A);
  static const Color surface = Color(0xFF232324);
  static const Color surfaceVariant = Color(0xFF2A2A2B);
  
  // ==================== 分割线 ====================
  static const Color divider = Color(0xFF3D4249);
  static const Color border = Color(0xFF3D4249);
  
  // ==================== 语义色 ====================
  static const Color success = Color(0xFF34D058);
  static const Color successSurface = Color(0xFF1A3A2A);
  static const Color warning = Color(0xFFFFAA2F);
  static const Color warningSurface = Color(0xFF3A3020);
  static const Color error = Color(0xFFFF7D75);
  static const Color errorSurface = Color(0xFF3A2020);
  
  // ==================== 状态色 ====================
  static const Color disabled = Color(0xFF2A2A2B);
  static const Color hover = Color(0xFF2A2A2B);
  static const Color pressed = Color(0xFF3D4249);
}

/// 颜色工具类
class AppColorUtils {
  AppColorUtils._();
  
  /// 根据主题模式获取对应颜色
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColorsLight.primary
        : AppColorsDark.primary;
  }
  
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColorsLight.background
        : AppColorsDark.background;
  }
  
  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColorsLight.surface
        : AppColorsDark.surface;
  }
  
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColorsLight.textPrimary
        : AppColorsDark.textPrimary;
  }
  
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColorsLight.textSecondary
        : AppColorsDark.textSecondary;
  }
}