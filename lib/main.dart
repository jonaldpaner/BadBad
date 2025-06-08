import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';

import 'Theme/light_mode.dart';
import 'Theme/dark_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BadBad',
      themeMode: ThemeMode.system,
      theme: lightModeTheme,
      darkTheme: darkModeTheme,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
