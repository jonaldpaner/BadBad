import 'package:flutter/material.dart';
import 'package:ahhhtest/components/login_signup_dialog.dart';
import 'package:ahhhtest/pages/camera_page.dart';
import 'package:ahhhtest/pages/translation_page.dart';
import 'favorites_page.dart';
import 'history_page.dart';
import 'package:ahhhtest/components/translation_input_card.dart';

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

  bool isLoggedIn = false; // <-- Holds whether the user is logged in

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
      drawer: Drawer(
        elevation: 16,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close Menu',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(
                color: Color.fromRGBO(204, 214, 218, 1),
                thickness: 1.5,
              ),

              // Favorites
              ListTile(
                leading: const Icon(Icons.favorite_border_rounded),
                title: const Text('Favorites'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPageWidget(),
                    ),
                  );
                },
              ),

              // Recent History
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Recent History'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryPageWidget(),
                    ),
                  );
                },
              ),

              // Only show “Logout” if isLoggedIn == true
              if (isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    setState(() {
                      isLoggedIn = false;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CameraPage()),
                    );
                  },
                  onTranslatePressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TranslationPage()),
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
