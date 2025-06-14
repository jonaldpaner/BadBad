import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Function to handle anonymous sign-in
  Future<User?> _signInAnonymously() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("Signed in anonymously with UID: ${userCredential.user?.uid}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'operation-not-allowed':
          print("Anonymous auth not enabled. Enable it in the Firebase console.");
          break;
        default:
          print("Unknown error during anonymous sign-in: ${e.message}");
      }
      return null;
    } catch (e) {
      print("Generic error during anonymous sign-in: $e");
      return null;
    }
  }

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

          // trying to connect
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(), // Show a loading circle
              ),
            );
          }

          // If there's no user, attempt to sign in anonymously
          if (!snapshot.hasData || snapshot.data == null) {
            return FutureBuilder<User?>(
              future: _signInAnonymously(),
              builder: (context, anonymousSnapshot) {
                if (anonymousSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(), // Show loading while signing anonymously
                    ),
                  );
                }
                // Once anonymous sign-in completes, pass that user to HomePage
                return HomePage(
                  currentUser: anonymousSnapshot.data, // This will be the anonymous User or null if it failed
                );
              },
            );
          }

          // If there's an authenticated user (including an already signed-in anonymous user)
          return HomePage(
            currentUser: snapshot.data, // This will be User object or null
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}