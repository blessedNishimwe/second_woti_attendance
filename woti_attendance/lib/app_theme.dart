import 'package:flutter/material.dart';

// Brand Colors
const Color kDeloitteGreen = Color(0xFF00A859);
const Color kBackgroundDark = Color(0xFF111111);
const Color kCardDark = Color(0xFF222222);
const Color kTextBright = Colors.white;
const Color kTextFaint = Colors.white70;
const Color kTextHint = Colors.white54;

// Logo path (if you use an asset logo)
const String kAppLogoAsset = "assets/logo.png"; // Example

class AppTheme {
  // Light theme colors
  static const Color kBackgroundLight = Color(0xFFF5F5F5);
  static const Color kCardLight = Colors.white;
  static const Color kTextDark = Color(0xFF333333);
  static const Color kTextFaintLight = Color(0xFF666666);
  static const Color kTextHintLight = Color(0xFF999999);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: kBackgroundLight,
    primaryColor: kDeloitteGreen,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackgroundLight,
      foregroundColor: kDeloitteGreen,
      elevation: 0,
      iconTheme: IconThemeData(color: kDeloitteGreen),
      titleTextStyle: TextStyle(
        color: kDeloitteGreen,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardColor: kCardLight,
    colorScheme: ColorScheme.light(
      primary: kDeloitteGreen,
      secondary: kDeloitteGreen,
      background: kBackgroundLight,
      surface: kCardLight,
      onBackground: kTextDark,
      onSurface: kTextDark,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
        fontSize: 32,
        color: kDeloitteGreen,
        letterSpacing: 2,
      ),
      bodyMedium: TextStyle(
        color: kTextDark,
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        color: kTextFaintLight,
        fontSize: 14,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCardLight,
      labelStyle: const TextStyle(color: kTextDark, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: kTextHintLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDeloitteGreen),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDeloitteGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDeloitteGreen, width: 2),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kCardLight,
        labelStyle: const TextStyle(color: kTextDark),
        hintStyle: const TextStyle(color: kTextHintLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDeloitteGreen),
        ),
      ),
      textStyle: const TextStyle(color: kTextDark, fontSize: 16),
      menuStyle: MenuStyle(
        backgroundColor: MaterialStatePropertyAll(kCardLight),
        surfaceTintColor: MaterialStatePropertyAll(kCardLight),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDeloitteGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kDeloitteGreen,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    iconTheme: const IconThemeData(
      color: kDeloitteGreen,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBackgroundDark,
    primaryColor: kDeloitteGreen,
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBackgroundDark,
    primaryColor: kDeloitteGreen,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackgroundDark,
      foregroundColor: kDeloitteGreen,
      elevation: 0,
      iconTheme: IconThemeData(color: kDeloitteGreen),
      titleTextStyle: TextStyle(
        color: kDeloitteGreen,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardColor: kCardDark,
    colorScheme: ColorScheme.dark(
      primary: kDeloitteGreen,
      secondary: kDeloitteGreen,
      background: kBackgroundDark,
      surface: kCardDark,
      onBackground: kTextBright,
      onSurface: kTextBright,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
        fontSize: 32,
        color: kDeloitteGreen,
        letterSpacing: 2,
      ),
      bodyMedium: TextStyle(
        color: kTextBright,
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        color: kTextFaint,
        fontSize: 14,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCardDark,
      labelStyle: const TextStyle(color: kTextBright, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: kTextHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDeloitteGreen),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDeloitteGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDeloitteGreen, width: 2),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kCardDark,
        labelStyle: const TextStyle(color: kTextBright),
        hintStyle: const TextStyle(color: kTextHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDeloitteGreen),
        ),
      ),
      textStyle: const TextStyle(color: kTextBright, fontSize: 16),
      menuStyle: MenuStyle(
        backgroundColor: MaterialStatePropertyAll(kCardDark),
        surfaceTintColor: MaterialStatePropertyAll(kCardDark),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDeloitteGreen,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kDeloitteGreen,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    iconTheme: const IconThemeData(
      color: kDeloitteGreen,
    ),
  );
}