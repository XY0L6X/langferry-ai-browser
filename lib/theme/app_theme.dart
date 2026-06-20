import 'package:flutter/material.dart';
import '../core/constants/app_dimens.dart';
import 'app_colors.dart';

/// 应用主题配置
/// 支持浅色/深色双主题，Material 3设计规范
class AppTheme {
  AppTheme._();
  
  // ==================== 浅色主题 ====================
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColorsLight.primary,
      brightness: Brightness.light,
      primary: AppColorsLight.primary,
      onPrimary: AppColorsLight.white,
      primaryContainer: AppColorsLight.primarySurface,
      secondary: AppColorsLight.gray500,
      surface: AppColorsLight.surface,
      background: AppColorsLight.background,
      error: AppColorsLight.error,
      outline: AppColorsLight.divider,
    );
    
    return _buildTheme(colorScheme, Brightness.light);
  }
  
  // ==================== 深色主题 ====================
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColorsDark.primary,
      brightness: Brightness.dark,
      primary: AppColorsDark.primary,
      onPrimary: AppColorsDark.white,
      primaryContainer: AppColorsDark.primarySurface,
      secondary: AppColorsDark.gray500,
      surface: AppColorsDark.surface,
      background: AppColorsDark.background,
      error: AppColorsDark.error,
      outline: AppColorsDark.divider,
    );
    
    return _buildTheme(colorScheme, Brightness.dark);
  }
  
  // ==================== 主题构建 ====================
  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final textTheme = _buildTextTheme(brightness);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: isLight ? AppColorsLight.background : AppColorsDark.background,
      
      // 文字主题
      textTheme: textTheme,
      
      // AppBar主题
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: AppDimens.fontSizeTitle,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: AppDimens.fontSizeCaption,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppDimens.fontSizeCaption,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // NavigationBar主题（Material 3）
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: AppDimens.fontSizeCaption,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            );
          }
          return TextStyle(
            fontSize: AppDimens.fontSizeCaption,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface.withOpacity(0.5),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.primary,
              size: AppDimens.iconSizeMedium,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurface.withOpacity(0.5),
            size: AppDimens.iconSizeMedium,
          );
        }),
      ),
      
      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing16,
          vertical: AppDimens.spacing8,
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing16,
          vertical: AppDimens.spacing12,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.4),
          fontSize: AppDimens.fontSizeBody,
        ),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            double.infinity,
            AppDimens.buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            double.infinity,
            AppDimens.buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
        ),
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),
      
      // 标签主题
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
        selectedColor: colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: AppDimens.fontSizeBody,
        ),
      ),
      
      // 底部Sheet主题
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusBottomSheet),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: colorScheme.outline.withOpacity(0.4),
      ),
      
      // Switch主题
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.5);
          }
          return colorScheme.surfaceVariant;
        }),
      ),
      
      // 列表瓦片主题
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacing16,
          vertical: AppDimens.spacing8,
        ),
        minVerticalPadding: AppDimens.spacing8,
        titleTextStyle: TextStyle(
          fontSize: AppDimens.fontSizeBody,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: AppDimens.fontSizeCaption,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      
      // Dialog主题
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusDialog),
        ),
        titleTextStyle: TextStyle(
          fontSize: AppDimens.fontSizeTitle,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: AppDimens.fontSizeBody,
          color: colorScheme.onSurface,
        ),
      ),
      
      // SnackBar主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: AppDimens.fontSizeBody,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusButton),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // ==================== 文字主题构建 ====================
  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final Color textColor = isLight ? AppColorsLight.textPrimary : AppColorsDark.textPrimary;
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: AppDimens.fontSizeDisplay,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: AppDimens.fontSizeHeadline,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: AppDimens.fontSizeTitle,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: AppDimens.fontSizeHeadline,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: AppDimens.fontSizeTitle,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: AppDimens.fontSizeSubtitle,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: AppDimens.fontSizeTitle,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: AppDimens.fontSizeSubtitle,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: AppDimens.fontSizeBody,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: AppDimens.fontSizeSubtitle,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: AppDimens.fontSizeBody,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: AppDimens.fontSizeCaption,
        fontWeight: FontWeight.w400,
        color: textColor.withOpacity(0.7),
      ),
      labelLarge: TextStyle(
        fontSize: AppDimens.fontSizeBody,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: AppDimens.fontSizeCaption,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }
}