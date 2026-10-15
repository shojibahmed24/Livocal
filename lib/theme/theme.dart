import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/theme/app_tokens.dart';
import 'package:livocal/theme/color_theme.dart';
import 'package:livocal/theme/text_theme.dart';

class CustomThemeData {
  final textTheme = CustomTextTheme();
  late final ColorTheme colorTheme;

  CustomThemeData({required bool isDarkTheme}) {
    colorTheme = isDarkTheme
        ? ColorTheme(
            iconColor: AppColorsDark.iconColor,
            textColor1: AppColorsDark.textColor1,
            textColor2: AppColorsDark.textColor2,
            appBarColor: AppColorsDark.appBarColor,
            dividerColor: AppColorsDark.dividerColor,
            backgroundColor: AppColorsDark.backgroundColor,
            errorSnackBarColor: AppColorsDark.errorSnackBarColor,
            incomingMessageBubbleColor:
                AppColorsDark.incomingMessageBubbleColor,
            outgoingMessageBubbleColor:
                AppColorsDark.outgoingMessageBubbleColor,
            incomingEmbedColor: AppColorsDark.incomingEmbedColor,
            outgoingEmbedColor: AppColorsDark.outgoingEmbedColor,
            selectedLabelColor: AppColorsDark.selectedLabelColor,
            unselectedLabelColor: AppColorsDark.unselectedLabelColor,
            indicatorColor: AppColorsDark.indicatorColor,
            blueColor: AppColorsDark.blueColor,
            greenColor: AppColorsDark.greenColor,
            yellowColor: AppColorsDark.yellowColor,
            greyColor: AppColorsDark.greyColor,
            statusBarColor: AppColorsDark.statusBarColor,
            navigationBarColor: AppColorsDark.navigationBarColor,
          )
        : ColorTheme(
            iconColor: AppColorsLight.iconColor,
            textColor1: AppColorsLight.textColor1,
            textColor2: AppColorsLight.textColor2,
            appBarColor: AppColorsLight.appBarColor,
            dividerColor: AppColorsLight.dividerColor,
            backgroundColor: AppColorsLight.backgroundColor,
            errorSnackBarColor: AppColorsLight.errorSnackBarColor,
            incomingMessageBubbleColor:
                AppColorsLight.incomingMessageBubbleColor,
            outgoingMessageBubbleColor:
                AppColorsLight.outgoingMessageBubbleColor,
            incomingEmbedColor: AppColorsLight.incomingEmbedColor,
            outgoingEmbedColor: AppColorsLight.outgoingEmbedColor,
            selectedLabelColor: AppColorsLight.selectedLabelColor,
            unselectedLabelColor: AppColorsLight.unselectedLabelColor,
            indicatorColor: AppColorsLight.indicatorColor,
            blueColor: AppColorsLight.blueColor,
            greenColor: AppColorsLight.greenColor,
            yellowColor: AppColorsLight.yellowColor,
            greyColor: AppColorsLight.greyColor,
            statusBarColor: AppColorsLight.statusBarColor,
            navigationBarColor: AppColorsLight.navigationBarColor,
          );
  }
}

// THEME PROVIDERS
final darkThemeProvider = Provider((ref) => _darkTheme);
final lightThemeProvider = Provider((ref) => _theme);

// MATERIAL 3 COLOR SCHEMES
final _lightColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: Colors.white,
  primaryContainer: AppColors.primaryContainerLight,
  onPrimaryContainer: AppColors.primaryDark,
  surface: AppColors.lightBackground,
  onSurface: AppColors.lightTextPrimary,
  onSurfaceVariant: AppColors.lightTextSecondary,
  surfaceContainer: AppColors.lightSurfaceContainer,
  surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
  outline: AppColors.lightDivider,
  error: AppColors.errorLight,
  onError: Colors.white,
);

final _darkColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.dark,
  primary: AppColors.primary,
  onPrimary: Colors.white,
  primaryContainer: AppColors.primaryContainerDark,
  onPrimaryContainer: AppColors.primaryLight,
  surface: AppColors.darkBackground,
  onSurface: AppColors.darkTextPrimary,
  onSurfaceVariant: AppColors.darkTextSecondary,
  surfaceContainer: AppColors.darkSurface,
  surfaceContainerHigh: AppColors.darkSurfaceContainer,
  outline: AppColors.darkDivider,
  error: AppColors.error,
  onError: Colors.white,
);

// THEMES
final _customTheme = CustomThemeData(isDarkTheme: false);
final _theme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: _lightColorScheme,
  dialogTheme: const DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.lg,
    ),
    backgroundColor: AppColors.lightBackground,
    titleTextStyle: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: TextStyle(
      color: AppColors.lightTextSecondary,
      fontSize: 15,
      height: 1.4,
    ),
  ),
  appBarTheme: const AppBarTheme(
    elevation: AppElevation.flat,
    scrolledUnderElevation: AppElevation.flat,
    surfaceTintColor: Colors.transparent,
    actionsIconTheme: IconThemeData(
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: AppColors.primaryDark,
      systemNavigationBarColor: AppColors.lightBackground,
      systemNavigationBarDividerColor: AppColors.lightDivider,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
    elevation: AppElevation.medium,
  ),
  scaffoldBackgroundColor: AppColors.lightBackground,
  iconTheme: const IconThemeData(
    color: AppColors.lightIcon,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.lightDivider,
    thickness: 0.5,
  ),
  tabBarTheme: const TabBarThemeData(
    indicatorColor: Colors.white,
    indicatorSize: TabBarIndicatorSize.tab,
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,
    dividerHeight: 0,
  ),
  cardTheme: const CardThemeData(
    elevation: AppElevation.low,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
  ),
);

// Dark theme
final _customDarkTheme = CustomThemeData(isDarkTheme: true);
final _darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: _darkColorScheme,
  dialogTheme: const DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.lg,
    ),
    backgroundColor: AppColors.darkSurface,
    titleTextStyle: TextStyle(
      color: AppColors.darkTextPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: TextStyle(
      color: AppColors.darkTextSecondary,
      fontSize: 15,
      height: 1.4,
    ),
  ),
  appBarTheme: const AppBarTheme(
    elevation: AppElevation.flat,
    scrolledUnderElevation: AppElevation.flat,
    surfaceTintColor: Colors.transparent,
    actionsIconTheme: IconThemeData(
      color: AppColors.darkIcon,
    ),
    iconTheme: IconThemeData(
      color: AppColors.darkIcon,
    ),
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkTextPrimary,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: AppColors.darkSurface,
      systemNavigationBarColor: AppColors.darkBackground,
      systemNavigationBarDividerColor: AppColors.darkDivider,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
    elevation: AppElevation.medium,
  ),
  scaffoldBackgroundColor: AppColors.darkBackground,
  iconTheme: const IconThemeData(
    color: AppColors.darkIcon,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.darkDivider,
    thickness: 0.5,
  ),
  tabBarTheme: const TabBarThemeData(
    indicatorColor: AppColors.primary,
    indicatorSize: TabBarIndicatorSize.tab,
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.darkTextSecondary,
    dividerHeight: 0,
  ),
  cardTheme: const CardThemeData(
    elevation: AppElevation.low,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
  ),
);

// EXTENSION
extension CustomTheme on ThemeData {
  CustomThemeData get custom =>
      brightness == Brightness.dark ? _customDarkTheme : _customTheme;

  AssetImage themedImage(String name) {
    final path =
        brightness == Brightness.dark ? 'assets/images/dark' : 'assets/images';
    return AssetImage('$path/$name');
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_getInitialTheme());

  static ThemeMode _getInitialTheme() {
    try {
      final saved = SharedPref.instance.getString('app_theme_mode');
      if (saved == 'light') return ThemeMode.light;
      if (saved == 'dark') return ThemeMode.dark;
    } catch (e, st) {
      debugPrint('[ThemeModeNotifier] _getInitialTheme error: $e\n$st');
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final str = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
              ? 'dark'
              : 'system';
      await SharedPref.instance.setString('app_theme_mode', str);
    } catch (e, st) {
      debugPrint('[ThemeModeNotifier] setThemeMode error: $e\n$st');
    }
  }
}
