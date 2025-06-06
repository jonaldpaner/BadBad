import 'package:flutter/material.dart';
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

  bool isLoggedIn = false; // Holds whether the user is logged in

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
          setState(() {
            isLoggedIn = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: HomeDrawer(
        isLoggedIn: isLoggedIn,
        onLogout: () {
          setState(() {
            isLoggedIn = false;
          });
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
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

            // Top bar (menu button + profile button)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Hamburger menu
                    IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => scaffoldKey.currentState?.openDrawer(),
                    ),

                    // Profile / Login button
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      onPressed: showLoginDialog,
                    ),
                  ],
                ),
              ),
            ),

            // Translation input card (at bottom)
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
