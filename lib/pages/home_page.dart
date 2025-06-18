import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:ahhhtest/components/home_drawer.dart';
import 'package:ahhhtest/components/login_signup_dialog.dart';
import 'package:ahhhtest/pages/camera_page.dart';
import 'package:ahhhtest/pages/translation_page.dart';
import 'package:ahhhtest/components/instruction_dialog.dart';

import '../components/translation_input_card.dart'; // <--- NEW IMPORT

class HomePage extends StatefulWidget {
  final User? currentUser;

  const HomePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // GlobalKey for the Scaffold to control the Drawer
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  // TextEditingController for the text input field
  final TextEditingController textController = TextEditingController();
  // FocusNode for managing the focus of the text field
  final FocusNode textFieldFocusNode = FocusNode();

  // State variables for language selection
  String fromLanguage = 'English';
  String toLanguage = 'Ata Manobo';

  // Getters for authentication status and login prompt visibility
  bool get isLoggedIn => widget.currentUser != null;
  bool get _shouldShowLoginPrompt => widget.currentUser == null || widget.currentUser!.isAnonymous;

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style once when the widget is initialized
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent status bar
        statusBarIconBrightness: Brightness.dark, // Dark icons on light status bar
        statusBarBrightness: Brightness.light, // Light status bar content (iOS)
      ),
    );
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
    // Dispose controllers and focus nodes to prevent memory leaks
    textController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  // Toggles the selected 'from' and 'to' languages
  void toggleLanguages() {
    setState(() {
      final temp = fromLanguage;
      fromLanguage = toLanguage;
      toLanguage = temp;
    });
  }

  // Shows the login/signup dialog
  void showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => LoginSignUpDialog(
        onLogin: () {
          // Callback after successful login
          print('HomePage: User logged in via dialog.');
        },
      ),
    );
  }

  // Method to show the instruction dialog, now using the external component
  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const InstructionDialog();
      },
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
            // Close the drawer after logout attempt
            if (scaffoldKey.currentState?.isDrawerOpen == true) {
              Navigator.of(context).pop();
            }
          }
        },
      ),
      backgroundColor: theme.scaffoldBackgroundColor, // Set background color based on theme
      extendBodyBehindAppBar: true, // Extends the body behind the app bar area
      body: Stack(
        children: [
          // Background gradient for light mode
          if (!isDarkMode)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration( // BoxDecoration can be const as colors/stops are static
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
          // Top row for menu, help, and profile icons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu icon button
                  IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: theme.iconTheme.color,
                      size: 25,
                    ),
                    onPressed: () {
                      scaffoldKey.currentState?.openDrawer(); // Open the navigation drawer
                    },
                  ),
                  // Row for help and person icons
                  Row(
                    children: [
                      // Help icon button
                      IconButton(
                        icon: Icon(
                          Icons.help_outline,
                          color: theme.iconTheme.color,
                          size: 25,
                        ),
                        onPressed: _showInstructionsDialog, // Show instructions dialog
                      ),
                      // Person icon button (shows login dialog if not logged in)
                      IconButton(
                        icon: Icon(
                          Icons.person_outline,
                          color: theme.iconTheme.color,
                          size: 25,
                        ),
                        onPressed: _shouldShowLoginPrompt ? showLoginDialog : null, // Conditional onPressed
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Translation input card at the bottom
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
                  FocusScope.of(context).unfocus(); // Unfocus the text field
                  Future.delayed(const Duration(milliseconds: 300), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraPage(), // CameraPage can be const
                      ),
                    );
                  });
                },
                onTranslatePressed: () {
                  final inputText = textController.text.trim();
                  if (inputText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter text to translate'), // Text widget can be const
                        duration: Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  // Navigate to translation page with input text and languages
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
