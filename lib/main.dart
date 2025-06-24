import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';

import 'Theme/light_mode.dart';
import 'Theme/dark_mode.dart';

void main() async {
  // Ensure Flutter binding is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// MyApp is now a StatefulWidget to manage the state of the anonymous sign-in attempt
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Flag to ensure anonymous sign-in is only attempted once per app session if no user is found
  bool _anonymousSignInAttempted = false;

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
      // Catch any other generic errors during sign-in
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
        stream: FirebaseAuth.instance.authStateChanges(), // Stream of user authentication state
        builder: (context, snapshot) {
          // Show a loading indicator while waiting for the initial connection to the auth stream
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(), // Loading circle
              ),
            );
          }

          // If there's no authenticated user and we haven't attempted anonymous sign-in yet
          if (!snapshot.hasData && !_anonymousSignInAttempted) {
            // Set the flag to true to prevent multiple attempts
            _anonymousSignInAttempted = true;
            // Trigger the anonymous sign-in. This will cause the authStateChanges stream to emit a new value
            // (either the anonymous user or null if sign-in failed) which will then rebuild this StreamBuilder.
            _signInAnonymously();
            // Continue showing a loading indicator until the stream emits a user
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(), // Show loading while signing anonymously
              ),
            );
          }

          return HomePage(
            currentUser: snapshot.data, // Pass the current User object (can be null if sign-in failed)
          );
        },
      ),
      // Disable the debug banner in the top-right corner
      debugShowCheckedModeBanner: false,
    );
  }
}