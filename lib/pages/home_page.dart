import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'dart:async'; // Still needed for Future.delayed, but not StreamSubscription

import 'package:ahhhtest/components/home_drawer.dart';
import 'package:ahhhtest/components/login_signup_dialog.dart';
import 'package:ahhhtest/components/translation_input_card.dart';
import 'package:ahhhtest/pages/camera_page.dart';
import 'package:ahhhtest/pages/translation_page.dart';

class HomePage extends StatefulWidget {
  // 1. Add currentUser as a required parameter
  final User? currentUser;

  const HomePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController textController = TextEditingController();
  final FocusNode textFieldFocusNode = FocusNode();

  String fromLanguage = 'English';
  String toLanguage = 'Ata Manobo';

  // 2. Derive isLoggedIn directly from widget.currentUser
  bool get isLoggedIn => widget.currentUser != null;

  // 3. REMOVE the StreamSubscription as it's now handled by MyApp
  // late StreamSubscription<User?> _authStateChangesSubscription;

  @override
  void initState() {
    super.initState();
    print('HomePage: initState called.');
    // 4. REMOVE the old authStateChanges listener in initState
    // _authStateChangesSubscription = FirebaseAuth.instance.authStateChanges().listen((user) { ... });

    // Initial check now directly uses the currentUser passed in
    if (widget.currentUser != null) {
      print('HomePage: Initial user found via widget.currentUser: ${widget.currentUser!.uid}');
    } else {
      print('HomePage: No initial user found via widget.currentUser.');
    }
  }

  // 5. Add didUpdateWidget to log when currentUser changes
  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser) {
      print('HomePage: currentUser property updated. Now: ${widget.currentUser != null ? 'logged in' : 'logged out'}');
      // No need for setState here, as the parent (StreamBuilder) already rebuilt us
      // and Flutter will rebuild the UI reflecting the new widget.currentUser
    }
  }

  @override
  void dispose() {
    print('HomePage: dispose called.'); // This should now almost never print
    textController.dispose();
    textFieldFocusNode.dispose();
    // 6. REMOVE _authStateChangesSubscription.cancel();
    super.dispose();
  }

  void toggleLanguages() {
    setState(() {
      final temp = fromLanguage;
      fromLanguage = toLanguage;
      toLanguage = temp;
    });
  }

  void showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => LoginSignUpDialog(
        onLogin: () {
          print('HomePage: LoginSignUpDialog onLogin called. (User logged in)');
          // No manual setState needed here. The StreamBuilder in main.dart
          // will detect the Firebase login and rebuild HomePage with the User object.
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 7. isLoggedIn now comes from the getter
    print('HomePage: build method called. isLoggedIn: $isLoggedIn (derived from widget.currentUser)');
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      drawer: HomeDrawer(
        isLoggedIn: isLoggedIn, // Pass derived isLoggedIn
        onLogout: () async {
          print('HomePage: Logout button clicked!');
          try {
            await FirebaseAuth.instance.signOut();
            print('HomePage: FirebaseAuth signOut successful.');
          } on FirebaseAuthException catch (e) {
            print('HomePage: FirebaseAuthException during signOut: ${e.code} - ${e.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logout Error: ${e.message}')),
            );
          } catch (e) {
            print('HomePage: Unexpected error during signOut: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An unexpected error occurred during logout: $e')),
            );
          } finally {
            if (scaffoldKey.currentState?.isDrawerOpen == true) {
              Navigator.of(context).pop(); // This closes the drawer
              print('HomePage: Drawer closed after logout attempt.');
            }
          }
        },
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            if (!isDarkMode)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Colors.white,
                      Color(0xFFe2f3f9),
                      Color(0xFFb8e1f1),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

            // Top bar
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu_rounded, color: theme.iconTheme.color,size: 25,),
                      onPressed: () {
                        print('HomePage: Opening drawer.');
                        scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    // Optionally show login icon only if not logged in
                    IconButton(
                      icon: Icon(Icons.person_outline, color: theme.iconTheme.color, size: 25,),
                      onPressed: isLoggedIn ? null : showLoginDialog, // Disable if logged in
                    ),
                  ],
                ),
              ),
            ),

            // Translation input card
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TranslationInputCard(
                  fromLanguage: fromLanguage,
                  onToggleLanguages: toggleLanguages,
                  textController: textController,
                  focusNode: textFieldFocusNode,
                  onCameraPressed: () {
                    print('HomePage: Camera button pressed.');
                    FocusScope.of(context).unfocus();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CameraPage(),
                        ),
                      );
                    });
                  },
                  onTranslatePressed: () {
                    print('HomePage: Translate button pressed.');
                    final inputText = textController.text.trim();
                    if (inputText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter text to translate'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      print('HomePage: Empty text for translation.');
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TranslationPage(
                          originalText: inputText,
                          fromLanguage: fromLanguage,
                          toLanguage: toLanguage,
                        ),
                      ),
                    );
                    print('HomePage: Navigating to TranslationPage.');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}