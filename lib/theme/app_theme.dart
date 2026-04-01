import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeController extends ChangeNotifier {
  static final AppThemeController _instance = AppThemeController._();
  static AppThemeController get instance => _instance;

  AppThemeController._();

  static bool _isDark = true;
  static bool get isDark => _isDark;

  // Default to system theme instead of always dark
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  static void setDark(bool dark) {
    _isDark = dark;
    themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
  }

  // Method to follow system theme
  static void followSystemTheme() {
    themeNotifier.value = ThemeMode.system;
  }
}

ThemeData buildLightTheme() {
  final ThemeData base = ThemeData(brightness: Brightness.light, useMaterial3: false);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D3DF0), brightness: Brightness.light),
    textTheme: GoogleFonts.urbanistTextTheme().apply(bodyColor: const Color(0xFF0A0F2E), displayColor: const Color(0xFF0A0F2E)),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF0A0F2E), elevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2F4FF),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD6DBFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF9AA6FF), width: 1.2)),
      hintStyle: const TextStyle(color: Color(0xFF7C86B2)),
    ),
  );
}

ThemeData buildDarkTheme() {
  final ThemeData base = ThemeData(brightness: Brightness.dark, useMaterial3: false);
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF00002E),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
    textTheme: GoogleFonts.urbanistTextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF00002E), foregroundColor: Colors.white, elevation: 0),
  );
}


