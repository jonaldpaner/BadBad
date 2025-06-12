import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- THIS IS THE MISSING IMPORT!
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Listen for auth changes
        builder: (context, snapshot) {
          // You can show a simple loading indicator if the connection is waiting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(), // Show a loading circle
              ),
            );
          }
          // Always return HomePage, and pass the current user object
          // This keeps HomePage as the root, regardless of login status
          return HomePage(
            currentUser: snapshot.data, // This will be User object or null
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}