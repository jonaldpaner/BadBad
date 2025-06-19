import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:ahhhtest/components/home_drawer.dart';
import 'package:ahhhtest/components/login_signup_dialog.dart';
import 'package:ahhhtest/pages/camera_page.dart';
import 'package:ahhhtest/pages/translation_page.dart';
import 'package:ahhhtest/components/instruction_dialog.dart';

import '../components/translation_input_card.dart';

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

  bool get isLoggedIn => widget.currentUser != null;
  bool get _shouldShowLoginPrompt => widget.currentUser == null || widget.currentUser!.isAnonymous;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    textFieldFocusNode.addListener(_onFocusChanged);
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
    textFieldFocusNode.removeListener(_onFocusChanged);
    textFieldFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (textFieldFocusNode.hasFocus) {
      HapticFeedback.selectionClick();
    }
  }

  double _calculateKeyboardPadding(double keyboardHeight, double safeAreaBottom) {
    const double restingPadding = 50.0;
    const double minKeyboardPaddingAboveKeyboard = 20.0;

    if (keyboardHeight > 0 && textFieldFocusNode.hasFocus) {
      return keyboardHeight + safeAreaBottom + minKeyboardPaddingAboveKeyboard;
    } else {
      return safeAreaBottom + restingPadding;
    }
  }


  void toggleLanguages() {
    HapticFeedback.lightImpact();
    setState(() {
      final temp = fromLanguage;
      fromLanguage = toLanguage;
      toLanguage = temp;
    });
  }

  void _performActionAndManageFocus(VoidCallback action, {Future<void> Function()? postAction}) async {
    if (textFieldFocusNode.hasFocus) {
      textFieldFocusNode.unfocus();
    }
    textFieldFocusNode.canRequestFocus = false;

    action();

    if (postAction != null) {
      await postAction();
    }

    textFieldFocusNode.canRequestFocus = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final double safeAreaBottomPadding = MediaQuery.of(context).padding.bottom;

    final double naturalBottomPadding = _calculateKeyboardPadding(
        keyboardInset,
        safeAreaBottomPadding
    );

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
              Navigator.of(context).pop();
            }
          }
        },
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
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
                    IconButton(
                      icon: Icon(
                        Icons.menu_rounded,
                        color: theme.iconTheme.color,
                        size: 25,
                      ),
                      onPressed: () {
                        _performActionAndManageFocus(() {
                          scaffoldKey.currentState?.openDrawer();
                        });
                      },
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.help_outline,
                            color: theme.iconTheme.color,
                            size: 25,
                          ),
                          onPressed: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            _performActionAndManageFocus(
                                  () => showDialog(
                                context: context,
                                builder: (context) => const InstructionDialog(),
                              ),
                              postAction: () async => await null,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.person_outline,
                            color: theme.iconTheme.color,
                            size: 25,
                          ),
                          onPressed: _shouldShowLoginPrompt
                              ? () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            _performActionAndManageFocus(
                                  () => showDialog(
                                context: context,
                                builder: (context) => LoginSignUpDialog(
                                  onLogin: () {
                                    print('HomePage: User logged in via dialog.');
                                  },
                                ),
                              ),
                              postAction: () async => await null,
                            );
                          }
                              : null,
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
              child: AnimatedPadding(
                padding: EdgeInsets.only(
                  bottom: naturalBottomPadding,
                  left: 20.0,
                  right: 20.0,
                ),
                duration: Duration(
                  milliseconds: keyboardInset > 0 ? 250 : 200,
                ),
                curve: Curves.easeOutCubic,
                child: TranslationInputCard(
                  fromLanguage: fromLanguage,
                  toLanguage: toLanguage,
                  onToggleLanguages: toggleLanguages,
                  textController: textController,
                  focusNode: textFieldFocusNode,
                  onCameraPressed: () {
                    _performActionAndManageFocus(
                          () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const CameraPage(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: animation.drive(
                                Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                                    .chain(CurveTween(curve: Curves.easeOutCubic)),
                              ),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      ),
                      postAction: () async => await null,
                    );
                    HapticFeedback.lightImpact();
                  },
                  onTranslatePressed: () {
                    final inputText = textController.text.trim();
                    if (inputText.isEmpty) {
                      HapticFeedback.vibrate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter text to translate'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    HapticFeedback.lightImpact();
                    _performActionAndManageFocus(
                          () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => TranslationPage(
                            originalText: inputText,
                            fromLanguage: fromLanguage,
                            toLanguage: toLanguage,
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: animation.drive(
                                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                                    .chain(CurveTween(curve: Curves.easeOutCubic)),
                              ),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      ),
                      postAction: () async => await null,
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
