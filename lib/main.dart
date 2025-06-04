import 'package:ahhhtest/pages/translation_page.dart';
import 'package:flutter/material.dart';
import 'pages/home_page.dart'; // <-- Import your converted HomePage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BadBad',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(), // <-- Use your custom HomePage here
      debugShowCheckedModeBanner: false,


    );
  }
}
