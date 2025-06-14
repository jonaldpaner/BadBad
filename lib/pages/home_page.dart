import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:ahhhtest/components/home_drawer.dart';
import 'package:ahhhtest/components/login_signup_dialog.dart';
import 'package:ahhhtest/components/translation_input_card.dart';
import 'package:ahhhtest/pages/camera_page.dart';
import 'package:ahhhtest/pages/translation_page.dart';

class HomePage extends StatefulWidget {
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

  // This getter determines if a user is logged in at all (anonymous or permanent)
  bool get isLoggedIn => widget.currentUser != null;

  // New getter: determines if the login/signup prompt should be shown.
  // This is true if there's no user OR the current user is anonymous.
  bool get _shouldShowLoginPrompt => widget.currentUser == null || widget.currentUser!.isAnonymous;

  @override
  void initState() {
    super.initState();

    // Set status bar overlay style to match light background (dark icons)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    if (widget.currentUser != null) {
      print('HomePage: Initial user found: ${widget.currentUser!.uid}');
    } else {
      print('HomePage: No initial user.');
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser) {
      print('HomePage: currentUser updated: ${widget.currentUser != null ? 'logged in' : 'logged out'}');
    }
  }

  @override
  void dispose() {
    textController.dispose();
    textFieldFocusNode.dispose();
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
          print('HomePage: User logged in via dialog.');
          // No need to dismiss here, StreamBuilder in main.dart handles rebuild
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      drawer: HomeDrawer(
        currentUser: widget.currentUser,
        onLogout: () async {
          try {
            await FirebaseAuth.instance.signOut();
            print('User signed out.');
          } catch (e) {
            print('Logout error: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logout Error: $e')),
            );
          } finally {
            if (scaffoldKey.currentState?.isDrawerOpen == true) {
              Navigator.of(context).pop(); // Close the drawer
            }
          }
        },
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Gradient background
          if (!isDarkMode)
            Positioned.fill(
              child: Container(
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
            ),

          // Top bar (no SafeArea so it can paint behind status bar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8, // Dynamic top padding
                left: 8,
                right: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: theme.iconTheme.color,
                      size: 25,
                    ),
                    onPressed: () {
                      scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  // MODIFIED: This button is now enabled if no user OR if user is anonymous
                  IconButton(
                    icon: Icon(
                      Icons.person_outline,
                      color: theme.iconTheme.color,
                      size: 25,
                    ),
                    onPressed: _shouldShowLoginPrompt ? showLoginDialog : null,
                  ),
                ],
              ),
            ),
          ),

          // Bottom input
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: TranslationInputCard(
                fromLanguage: fromLanguage,
                toLanguage: toLanguage,
                onToggleLanguages: toggleLanguages,
                textController: textController,
                focusNode: textFieldFocusNode,
                onCameraPressed: () {
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
                  final inputText = textController.text.trim();
                  if (inputText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter text to translate'),
                        duration: Duration(seconds: 1),
                      ),
                    );
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
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
