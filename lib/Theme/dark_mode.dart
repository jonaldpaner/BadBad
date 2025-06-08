import 'package:flutter/material.dart';

final ThemeData darkModeTheme = ThemeData.dark().copyWith(
  primaryColor: Colors.deepPurple,
  scaffoldBackgroundColor: const Color(0xFF121212), // same as AppBar

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF121212),
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),

  cardColor: Colors.black, // 🟤 Card background as pure black

  iconTheme: const IconThemeData(color: Colors.white),

  textTheme: ThemeData.dark().textTheme.copyWith(
    bodyLarge: const TextStyle(color: Colors.white, fontSize: 16),
  ),

  colorScheme: ColorScheme.dark().copyWith(
    secondary: const Color(0xFF3A3F44), // Icon button background (slightly lighter gray)
  ),
);
