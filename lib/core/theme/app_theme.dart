import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _accent = Color(0xFFFF6B00);

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: _accent,
      surface: Color(0xFF0A0A0A),
      onSurface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.5,
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    useMaterial3: true,
  );

  static final light = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: _accent),
    appBarTheme: AppBarTheme(
      titleTextStyle: GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    useMaterial3: true,
  );
}
