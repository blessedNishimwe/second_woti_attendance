import 'package:flutter/material.dart';

class AppColors {
  static const Color deloitteGreen = Color(0xFF00A859);
  static const Color backgroundDark = Color(0xFF111111);
  static const Color cardDark = Color(0xFF222222);
  static const Color textBright = Colors.white;
  static const Color textFaint = Colors.white70;
  static const Color textHint = Colors.white54;
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF222222);
  static const Color textDarkFaint = Color(0xFF888888);
  static const Color textDarkHint = Color(0xFFAAAAAA);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    primaryColor: AppColors.deloitteGreen,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.deloitteGreen,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.deloitteGreen),
      titleTextStyle: TextStyle(
        color: AppColors.deloitteGreen,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardColor: AppColors.cardLight,
    colorScheme: ColorScheme.light(
      primary: AppColors.deloitteGreen,
      secondary: AppColors.deloitteGreen,
      background: AppColors.backgroundLight,
      surface: AppColors.cardLight,
      onBackground: AppColors.textDark,
      onSurface: AppColors.textDark,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
        fontSize: 32,
        color: AppColors.deloitteGreen,
        letterSpacing: 2,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        color: AppColors.textDarkFaint,
        fontSize: 14,
      ),
      titleMedium: TextStyle(
        color: AppColors.textDark,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardLight,
      labelStyle: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: AppColors.textDarkHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.deloitteGreen),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.deloitteGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.deloitteGreen, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deloitteGreen,
        foregroundColor: Colors.black,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.deloitteGreen,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    iconTheme: IconThemeData(
      color: AppColors.deloitteGreen,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        labelStyle: TextStyle(color: AppColors.textDark),
        hintStyle: TextStyle(color: AppColors.textDarkHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.deloitteGreen),
        ),
      ),
      textStyle: TextStyle(color: AppColors.textDark, fontSize: 16),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: AppColors.deloitteGreen,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.deloitteGreen,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.deloitteGreen),
      titleTextStyle: TextStyle(
        color: AppColors.deloitteGreen,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardColor: AppColors.cardDark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.deloitteGreen,
      secondary: AppColors.deloitteGreen,
      background: AppColors.backgroundDark,
      surface: AppColors.cardDark,
      onBackground: AppColors.textBright,
      onSurface: AppColors.textBright,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
        fontSize: 32,
        color: AppColors.deloitteGreen,
        letterSpacing: 2,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textBright,
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        color: AppColors.textFaint,
        fontSize: 14,
      ),
      titleMedium: TextStyle(
        color: AppColors.textBright,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      labelStyle: TextStyle(color: AppColors.textBright, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: AppColors.textHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.deloitteGreen),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.deloitteGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.deloitteGreen, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deloitteGreen,
        foregroundColor: Colors.black,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.deloitteGreen,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    iconTheme: IconThemeData(
      color: AppColors.deloitteGreen,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        labelStyle: TextStyle(color: AppColors.textBright),
        hintStyle: TextStyle(color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.deloitteGreen),
        ),
      ),
      textStyle: TextStyle(color: AppColors.textBright, fontSize: 16),
    ),
  );
}