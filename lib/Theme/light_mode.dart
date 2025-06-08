import 'package:flutter/material.dart';

final ThemeData lightModeTheme = ThemeData.light().copyWith(
  primaryColor: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(color: Color(0xFF14181B), fontSize: 20, fontWeight: FontWeight.w600),
  ),
  cardColor: const Color.fromRGBO(230, 234, 237, 1),
  iconTheme: const IconThemeData(color: Colors.black),
  textTheme: ThemeData.light().textTheme.copyWith(
    bodyLarge: const TextStyle(color: Color(0xFF14181B), fontSize: 16),
    titleLarge: const TextStyle(color: Color(0xFF14181B), fontSize: 20, fontWeight: FontWeight.bold),
    titleMedium: const TextStyle(color: Colors.black54, fontSize: 18),
  ),
  colorScheme: ColorScheme.light().copyWith(
    secondary: const Color.fromRGBO(204, 214, 218, 0.64),
  ),
);
