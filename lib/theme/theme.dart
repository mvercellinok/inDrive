import 'package:flutter/material.dart';


// TIPOGRAFÍAS
class AppFonts {
  static const String fontFamily = 'Inter';
}

class AppTypography {
  
    static const TextStyle headline1 = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 64,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
  );

  static const TextStyle headline2 = TextStyle(
   fontFamily: AppFonts.fontFamily,
    fontSize: 60,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.5,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle headline4 = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle headline5 = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle headline6 = TextStyle(
   fontFamily: AppFonts.fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: AppFonts.fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
  );
}


// SPACING

class AppSpacing {
  static const double spacing100 = 4;
  static const double spacing200 = 8;
  static const double spacing300 = 12;
  static const double spacing400 = 16;
  static const double spacing500 = 20;
  static const double spacing600 = 24;
  static const double spacing700 = 32;
  static const double spacing800 = 40;
  static const double spacing900 = 48;
  static const double spacing1000 = 56;
  static const double spacing1100 = 64;
  static const double spacing1200 = 72;
}


// MARGIN

class AppMargin {
  static const double marginXs = 4;
  static const double marginSm = 8;
  static const double marginMd = 12;
  static const double marginLg = 16;
  static const double marginXl = 20;
  static const double margin2xl = 24;
  static const double margin3xl = 32;
  static const double margin4xl = 40;
  static const double margin5xl = 48;
}


// PADDING

class AppPadding {
  static const double paddingXs = 4;
  static const double paddingSm = 8;
  static const double paddingMd = 12;
  static const double paddingLg = 16;
  static const double paddingXl = 24;
  static const double padding2xl = 40;
}


// GAP

class AppGap {
  static const double gapTight = 4;
  static const double gapRelated = 8;
  static const double gapComponent = 16;
  static const double gapGroup = 20;
  static const double gapSection = 32;
  static const double gapNav = 40;
  static const double gapContainer = 48;
}


// RADIOS

class AppRadius {
  static const double radiusNone = 0;
  static const double radiusXs = 2;
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radius2xl = 20;
}


// COLORES PRIMITIVOS

class AppColors {
  // PRIMARY / BRAND
  static const primary50 = Color(0xFFF0F2E8);
  static const primary100 = Color(0xFFD8F5C8);
  static const primary200 = Color(0xFFAEEBA6);
  static const primary300 = Color(0xFF6ED96A);
  static const primary400 = Color(0xFF34C244);
  static const primary500 = Color(0xFF0D9F2F); // BASE
  static const primary600 = Color(0xFF0A7A2E);
  static const primary700 = Color(0xFF075A20);
  static const primary800 = Color(0xFF043D14);
  static const primary900 = Color(0xFF02240C);

  // SECONDARY
  static const secondary50 = Color(0xFFEEF3FC);
  static const secondary100 = Color(0xFFD6E4F7);
  static const secondary200 = Color(0xFFAECAEE);
  static const secondary300 = Color(0xFF7AAAE0);
  static const secondary400 = Color(0xFF5590D8);
  static const secondary500 = Color(0xFF3870D2); // BASE
  static const secondary600 = Color(0xFF2A58B0);
  static const secondary700 = Color(0xFF1A3E8A);
  static const secondary800 = Color(0xFF15277B);
  static const secondary900 = Color(0xFF0F2666);

  // ACCENT
  static const accent50 = Color(0xFFF5F3FF);
  static const accent100 = Color(0xFFEDE9FE);
  static const accent200 = Color(0xFFDDD6FE);
  static const accent300 = Color(0xFFC4B5FD);
  static const accent400 = Color(0xFFA78BFA);
  static const accent500 = Color(0xFF8B5CF6); // BASE
  static const accent600 = Color(0xFF7C3AED);
  static const accent700 = Color(0xFF6D28D9);
  static const accent800 = Color(0xFF4C1D95);
  static const accent900 = Color(0xFF2E1065);

  // NEUTRAL
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFF8F9FB);
  static const neutral100 = Color(0xFFF1F3F5);
  static const neutral200 = Color(0xFFE2E8EE);
  static const neutral300 = Color(0xFFCDD5DF);
  static const neutral400 = Color(0xFF9AA6B2);
  static const neutral500 = Color(0xFF6B7280);
  static const neutral600 = Color(0xFF4B5563);
  static const neutral700 = Color(0xFF374151);
  static const neutral800 = Color(0xFF1F2937);
  static const neutral900 = Color(0xFF111827);
  static const neutral1000 = Color(0xFF000000);

  // ERROR
  static const error50 = Color(0xFFFFF1F1);
  static const error200 = Color(0xFFFFC5C5);
  static const error500 = Color(0xFFF93333); // BASE
  static const error600 = Color(0xFFD41515);
  static const error800 = Color(0xFF700D0D);

  // WARNING
  
  static const warning50 = Color(0xFFFFFBEB);
  static const warning200 = Color(0xFFFDE68A);
  static const warning500 = Color(0xFFF59E08); // BASE
  static const warning600 = Color(0xFFD97706);
  static const warning800 = Color(0xFF451A03);

  // SUCCESS
  static const success50 = Color(0xFFE3F7EA);
  static const success200 = Color(0xFFBBF7D0);
  static const success500 = Color(0xFF22C55E); // BASE
  static const success600 = Color(0xFF16A34A);
  static const success800 = Color(0xFF14532D);
}


// TOKENS SEMÁNTICOS / MAPPING

class AppSemanticColors {
  // PRIMARY
  static const colorActionPrimaryEnabled = AppColors.primary500;
  static const colorActionPrimaryHover = AppColors.primary600;
  static const colorActionPrimaryActive = AppColors.primary700;
  static const colorActionPrimaryDisabled = AppColors.primary200;

  static const colorTextPrimary = AppColors.primary500;
  static const colorTextOnPrimary = AppColors.primary50;
  static const colorIconPrimary = AppColors.primary500;
  static const colorIconOnPrimary = AppColors.primary50;
  static const colorSurfacePrimary = AppColors.primary50;
  static const colorSurfacePrimaryContainer = AppColors.primary100;
  static const colorBorderPrimaryEnabled = AppColors.primary200;
  static const colorBorderPrimaryHover = AppColors.primary400;
  static const colorBorderPrimaryFocus = AppColors.primary500;

  // SECONDARY
  static const colorActionSecondaryEnabled = AppColors.secondary500;
  static const colorActionSecondaryHover = AppColors.secondary600;
  static const colorActionSecondaryActive = AppColors.secondary700;
  static const colorActionSecondaryDisabled = AppColors.secondary200;

  static const colorTextSecondaryBrand = AppColors.secondary500;
  static const colorTextOnSecondary = AppColors.secondary50;
  static const colorSurfaceSecondary = AppColors.secondary50;
  static const colorSurfaceSecondaryContainer = AppColors.secondary100;
  static const colorBorderSecondaryEnabled = AppColors.secondary200;
  static const colorBorderSecondaryHover = AppColors.secondary400;
  static const colorBorderSecondaryFocus = AppColors.secondary500;

  // ACCENT
  static const colorActionAccentEnabled = AppColors.accent500;
  static const colorActionAccentHover = AppColors.accent600;
  static const colorActionAccentActive = AppColors.accent700;
  static const colorActionAccentDisabled = AppColors.accent200;

  static const colorTextAccent = AppColors.accent600;
  static const colorTextOnAccent = AppColors.accent50;
  static const colorSurfaceAccent = AppColors.accent50;
  static const colorSurfaceAccentContainer = AppColors.accent100;
  static const colorBorderAccentEnabled = AppColors.accent200;
  static const colorBorderAccentHover = AppColors.accent400;
  static const colorBorderAccentFocus = AppColors.accent500;

  // NEUTRAL / SURFACE
  static const colorTextMain = AppColors.neutral900;
  static const colorTextSecondary = AppColors.neutral600;
  static const colorTextTertiary = AppColors.neutral400;
  static const colorTextDisabled = AppColors.neutral300;
  static const colorTextInverse = AppColors.neutral0;

  static const colorSurfaceDefault = AppColors.neutral0;
  static const colorSurfaceSubtle = AppColors.neutral50;
  static const colorSurfaceRaised = AppColors.neutral100;
  static const colorSurfaceSunken = AppColors.neutral200;
  static const colorSurfaceInverse = AppColors.neutral900;

  static const colorBorderSubtle = AppColors.neutral200;
  static const colorBorderEnabled = AppColors.neutral300;
  static const colorBorderStrong = AppColors.neutral500;

  // STATUS
  static const colorError = AppColors.error500;
  static const colorWarning = AppColors.warning500;
  static const colorSuccess = AppColors.success500;
}


// ELEVACIONES

class AppElevation {
  static const List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Color(0x0F111827), // 6%
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x1A111827), // 10%
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static const List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Color(0x14111827), // 8%
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
    BoxShadow(
      color: Color(0x1A111827), // 10%
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> elevation3 = [
    BoxShadow(
      color: Color(0x14111827), // 8%
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x1F111827), // 12%
      offset: Offset(0, 8),
      blurRadius: 16,
    ),
  ];

  static const List<BoxShadow> elevation4 = [
    BoxShadow(
      color: Color(0x1A111827), // 10%
      offset: Offset(0, 8),
      blurRadius: 16,
    ),
    BoxShadow(
      color: Color(0x24111827), // 14%
      offset: Offset(0, 16),
      blurRadius: 32,
    ),
  ];

  static const List<BoxShadow> elevation5 = [
    BoxShadow(
      color: Color(0x12111827), // 7%
      offset: Offset(0, -4),
      blurRadius: 20,
    ),
  ];
}


// TEMA GENERAL / MAPPING

final ThemeData inDrive = ThemeData(
  useMaterial3: true,
  fontFamily: AppFonts.fontFamily,

  colorScheme: const ColorScheme.light(
    // MAPA PRIMARY
    primary: AppColors.primary500,
    onPrimary: AppColors.primary50,
    primaryContainer: AppColors.primary100,
    onPrimaryContainer: AppColors.primary800,

    // MAPA SECONDARY
    secondary: AppColors.secondary500,
    onSecondary: AppColors.secondary50,
    secondaryContainer: AppColors.secondary100,
    onSecondaryContainer: AppColors.secondary800,

    // MAPA ACCENT
    tertiary: AppColors.accent500,
    onTertiary: AppColors.accent50,
    tertiaryContainer: AppColors.accent100,
    onTertiaryContainer: AppColors.accent800,

    // SUPERFICIES
    surface: AppColors.neutral0,
    onSurface: AppColors.neutral900,
    onSurfaceVariant: AppColors.neutral600,

    // BORDES
    outline: AppColors.neutral300,
    outlineVariant: AppColors.neutral200,

    // ERROR
    error: AppColors.error500,
    onError: AppColors.error50,
    errorContainer: AppColors.error200,
    onErrorContainer: AppColors.error800,

    // OTROS
    shadow: AppColors.neutral900,
    scrim: AppColors.neutral900,
  ),

  scaffoldBackgroundColor: AppColors.neutral50,

  textTheme: const TextTheme(
    displayLarge: AppTypography.headline1,
    displayMedium: AppTypography.headline2,
    displaySmall: AppTypography.headline3,
    headlineMedium: AppTypography.headline4,
    headlineSmall: AppTypography.headline5,
    titleLarge: AppTypography.headline6,
    titleMedium: AppTypography.subtitle1,
    titleSmall: AppTypography.subtitle2,
    bodyLarge: AppTypography.body1,
    bodyMedium: AppTypography.body2,
    labelLarge: AppTypography.buttonMedium,
    labelMedium: AppTypography.caption,
    labelSmall: AppTypography.overline,
  ),

  cardTheme: CardThemeData(
    color: AppColors.neutral100,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.radiusLg),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.neutral200,
    contentPadding: const EdgeInsets.all(AppPadding.paddingLg),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      borderSide: const BorderSide(color: AppColors.neutral300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      borderSide: const BorderSide(color: AppColors.neutral300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      borderSide: const BorderSide(
        color: AppColors.primary500,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      borderSide: const BorderSide(color: AppColors.error200),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      borderSide: const BorderSide(
        color: AppColors.error500,
        width: 2,
      ),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      textStyle: WidgetStateProperty.all(AppTypography.buttonMedium),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.neutral400;
        }
        return AppColors.primary50;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.primary200;
        }
        if (states.contains(WidgetState.pressed)) {
          return AppColors.primary700;
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.primary600;
        }
        return AppColors.primary500;
      }),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: AppPadding.paddingXl,
          vertical: AppPadding.paddingMd,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        ),
      ),
    ),
  ),
);
