import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData build() {
    return ThemeData(
      primaryColor: kPrimaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimaryColor,
        secondary: kAccentColor,
      ),
      scaffoldBackgroundColor: Colors.grey[100],
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: kPrimaryColor),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
    );
  }
}