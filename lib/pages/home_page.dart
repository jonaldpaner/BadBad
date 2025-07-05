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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController textController = TextEditingController();
  final FocusNode textFieldFocusNode = FocusNode();

  String fromLanguage = 'English';
  String toLanguage = 'Ata Manobo';

  bool isTextFieldFocused = false;

  bool get _shouldShowLoginPrompt =>
      widget.currentUser == null || widget.currentUser!.isAnonymous;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    textFieldFocusNode.addListener(_onFocusChanged);
  }

  double get _responsiveRestingPadding {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * 0.08;
  }

  void _onFocusChanged() {
    final hasFocus = textFieldFocusNode.hasFocus;
    if (hasFocus != isTextFieldFocused) {
      setState(() {
        isTextFieldFocused = hasFocus;
      });
    }
    if (hasFocus) {
      HapticFeedback.selectionClick();
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

  void _performActionAndManageFocus(
    VoidCallback action, {
    Future<void> Function()? postAction,
  }) async {
    FocusScope.of(context).unfocus();
    if (isTextFieldFocused) {
      setState(() {
        isTextFieldFocused = false;
      });
    }

    textFieldFocusNode.canRequestFocus = false;
    action();
    if (postAction != null) await postAction();
    textFieldFocusNode.canRequestFocus = true;
  }

  @override
  void dispose() {
    textController.dispose();
    textFieldFocusNode.removeListener(_onFocusChanged);
    textFieldFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double bottomPadding = keyboardHeight > 0
        ? keyboardHeight + 20
        : _responsiveRestingPadding;

    return Scaffold(
      key: scaffoldKey,
      drawer: HomeDrawer(
        currentUser: widget.currentUser,
        onLogout: () async {
          try {
            await FirebaseAuth.instance.signOut();
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Logout Error: $e')));
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
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          if (isTextFieldFocused) {
            setState(() {
              isTextFieldFocused = false;
            });
          }
        },
        child: Stack(
          children: [
            if (!isDarkMode) const LightBackground(),

            // AppBar Row
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
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
                            _performActionAndManageFocus(
                              () => showDialog(
                                context: context,
                                builder: (context) => const InstructionDialog(),
                              ),
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
                                  _performActionAndManageFocus(
                                    () => showDialog(
                                      context: context,
                                      builder: (context) =>
                                          LoginSignUpDialog(onLogin: () {}),
                                    ),
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

            // Translation Input Card
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(
                  bottom: bottomPadding,
                  left: 20,
                  right: 20,
                ),
                child: TranslationInputCard(
                  fromLanguage: fromLanguage,
                  toLanguage: toLanguage,
                  onToggleLanguages: toggleLanguages,
                  textController: textController,
                  focusNode: textFieldFocusNode,
                  onCameraPressed: () async {
                    _performActionAndManageFocus(
                      () {},
                      postAction: () async {
                        await Future.delayed(const Duration(milliseconds: 250));
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const CameraPage(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SlideTransition(
                                    position: animation.drive(
                                      Tween(
                                        begin: const Offset(0.0, 1.0),
                                        end: Offset.zero,
                                      ).chain(
                                        CurveTween(curve: Curves.easeOutCubic),
                                      ),
                                    ),
                                    child: child,
                                  );
                                },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      },
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
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  TranslationPage(
                                    originalText: inputText,
                                    fromLanguage: fromLanguage,
                                    toLanguage: toLanguage,
                                  ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position: animation.drive(
                                    Tween(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).chain(
                                      CurveTween(curve: Curves.easeOutCubic),
                                    ),
                                  ),
                                  child: child,
                                );
                              },
                          transitionDuration: const Duration(milliseconds: 300),
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

// Extracted gradient widget
class LightBackground extends StatelessWidget {
  const LightBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Colors.white, Color(0xFFe2f3f9), Color(0xFFb8e1f1)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
