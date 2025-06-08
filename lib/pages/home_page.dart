import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:ahhhtest/components/home_drawer.dart';
import 'package:ahhhtest/components/login_signup_dialog.dart';
import 'package:ahhhtest/components/translation_input_card.dart';
import 'package:ahhhtest/pages/camera_page.dart';
import 'package:ahhhtest/pages/translation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController textController = TextEditingController();
  final FocusNode textFieldFocusNode = FocusNode();

  String fromLanguage = 'English';
  String toLanguage = 'Ata Manobo';

  bool isLoggedIn = false;

  late StreamSubscription<User?> _authStateChangesSubscription;

  @override
  void initState() {
    super.initState();
    _authStateChangesSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        isLoggedIn = user != null;
      });
    });
  }

  @override
  void dispose() {
    textController.dispose();
    textFieldFocusNode.dispose();
    _authStateChangesSubscription.cancel();
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
        onLogin: () {},
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
        isLoggedIn: isLoggedIn,
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pop();
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
                      icon: Icon(Icons.menu_rounded, color: theme.iconTheme.color),
                      onPressed: () => scaffoldKey.currentState?.openDrawer(),
                    ),
                    IconButton(
                      icon: Icon(Icons.person_outline, color: theme.iconTheme.color),
                      onPressed: showLoginDialog,
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
            ),
          ],
        ),
      ),
    );
  }
}
