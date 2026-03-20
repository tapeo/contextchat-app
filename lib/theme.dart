import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const double radiusSmall = 6;
  static const double radiusMedium = 10;
  static const double radiusLarge = 14;

  static const Color _systemBlue = Color(0xFF0A84FF);

  static const Color _lightBackground = Color(0xfff3f5f5);
  static const Color _lightSurface = Color(0x80FFFFFF);
  static const Color _lightLabel = Color(0xFF0A0A0A);

  static const Color _darkBackground = Color(0xff1c1c1e);
  static const Color _darkSurface = Color(0x801C1C1E);
  static const Color _darkLabel = Color(0xFFFFFFFF);

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.light(
      primary: _systemBlue,
      onPrimary: Colors.white,
      surface: _lightSurface,
      onSurface: _lightLabel,
    ),
    scaffoldBackgroundColor: _lightBackground,
    canvasColor: _lightBackground,
    primaryColor: _systemBlue,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: _lightLabel,
      iconTheme: IconThemeData(color: _lightLabel),
    ),
    cardColor: _lightSurface,
    dividerColor: _lightLabel.withValues(alpha: 0.1),
    dividerTheme: DividerThemeData(
      color: _lightLabel.withValues(alpha: 0.1),
      thickness: 1,
      space: 1,
    ),
    textTheme: GoogleFonts.geistTextTheme(Typography.blackMountainView),
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return _systemBlue;
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return _systemBlue;
        }
        return null;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return _systemBlue;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return _systemBlue;
        }
        return null;
      }),
    ),
    dialogTheme: DialogThemeData(backgroundColor: _lightSurface),
  );

  static final ThemeData dark = ThemeData(
    colorScheme: ColorScheme.dark(
      primary: _systemBlue,
      onPrimary: Colors.white,
      surface: _darkSurface,
      onSurface: _darkLabel,
    ),
    scaffoldBackgroundColor: _darkBackground,
    canvasColor: _darkBackground,
    primaryColor: _systemBlue,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: _darkLabel,
      iconTheme: IconThemeData(color: _darkLabel),
    ),
    cardColor: _darkSurface,
    dividerColor: _darkLabel.withValues(alpha: 0.1),
    dividerTheme: DividerThemeData(
      color: _darkLabel.withValues(alpha: 0.1),
      thickness: 1,
      space: 1,
    ),
    textTheme: GoogleFonts.geistTextTheme(Typography.whiteMountainView),
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return _systemBlue;
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return _systemBlue;
        }
        return null;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return _systemBlue;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return _systemBlue;
        }
        return null;
      }),
    ),
    dialogTheme: DialogThemeData(backgroundColor: _darkSurface),
  );
}
