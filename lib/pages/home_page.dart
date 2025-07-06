import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool _isDialogShowing = false;
  String fromLanguage = 'English';
  String toLanguage = 'Ata Manobo';

  bool isTextFieldFocused = false;
  bool isKeyboardVisible = false;

  late final KeyboardVisibilityController _keyboardVisibilityController;
  late final Stream<bool> _keyboardStream;

  bool get _shouldShowLoginPrompt =>
      widget.currentUser == null || widget.currentUser!.isAnonymous;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _keyboardVisibilityController = KeyboardVisibilityController();
    _keyboardStream = _keyboardVisibilityController.onChange;

    _keyboardStream.listen((visible) {
      if (!mounted) return;
      setState(() {
        isKeyboardVisible = visible;
      });
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    focusNode.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (focusNode.hasFocus != isTextFieldFocused) {
      setState(() {
        isTextFieldFocused = focusNode.hasFocus;
      });
    }
    if (focusNode.hasFocus) {
      HapticFeedback.selectionClick();
    }
  }

  void _dismissKeyboard() {
    if (focusNode.hasFocus) {
      focusNode.unfocus();
    }
  }

  void _performCleanAction(
      VoidCallback action, {
        Future<void> Function()? postAction,
      }) async {
    _dismissKeyboard();

    if (isKeyboardVisible) {
      await Future.delayed(const Duration(milliseconds: 250));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        action();
      }
    });

    if (postAction != null) {
      await postAction();
    }
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.removeListener(_handleFocus);
    focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: HomeDrawer(
        currentUser: widget.currentUser,
        onLogout: () async {
          try {
            await FirebaseAuth.instance.signOut();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logout Error: $e')),
              );
            }
          } finally {
            if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
              if (context.mounted) Navigator.of(context).pop();
            }
          }
        },
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            if (theme.brightness != Brightness.dark) const LightBackground(),
            SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(
                      icon: Icons.menu_rounded,
                      onTap: () => _performCleanAction(() {
                        scaffoldKey.currentState?.openDrawer();
                      }),
                    ),
                    Row(
                      children: [
                        _buildIconButton(
                          icon: Icons.help_outline,
                          onTap: () => _performCleanAction(() {
                            showDialog(
                              context: context,
                              builder: (_) => const InstructionDialog(),
                            );
                          }),
                        ),
                        _buildIconButton(
                          icon: Icons.person_outline,
                          onTap: _shouldShowLoginPrompt
                              ? () => _performCleanAction(() async { // Make this an async function
                            setState(() {
                              _isDialogShowing = true; // Set to true when dialog is about to show
                            });
                            await showDialog( // Await the dialog's dismissal
                              context: context,
                              builder: (_) => LoginSignUpDialog(
                                onLogin: () {
                                  // Your onLogin logic, e.g., Navigator.pop(context);
                                },
                              ),
                            );
                            // This code runs AFTER the dialog is dismissed (via Navigator.pop or user tapping outside)
                            if (mounted) { // Check if the widget is still mounted before setting state
                              setState(() {
                                _isDialogShowing = false; // Set to false after dialog is dismissed
                              });
                            }
                          })
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(
                  bottom: _isDialogShowing
                      ? MediaQuery.of(context).size.height * 0.08 // Keep at default height
                      : (bottomInset > 0 ? bottomInset + 8.0 : MediaQuery.of(context).size.height * 0.08),
                  left: 20,
                  right: 20,
                ),
                child: TranslationInputCard(
                  fromLanguage: fromLanguage,
                  toLanguage: toLanguage,
                  onToggleLanguages: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      final temp = fromLanguage;
                      fromLanguage = toLanguage;
                      toLanguage = temp;
                    });
                  },
                  textController: textController,
                  focusNode: focusNode,
                  languageSelector: null,
                  onCameraPressed: () {
                    _performCleanAction(() {}, postAction: () async {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const CameraPage(),
                          transitionsBuilder: (_, anim, __, child) {
                            return SlideTransition(
                              position: anim.drive(
                                Tween(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).chain(CurveTween(curve: Curves.easeOutCubic)),
                              ),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    });
                  },
                  onTranslatePressed: () {
                    final inputText = textController.text.trim();
                    if (inputText.isEmpty) {
                      HapticFeedback.vibrate();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter text to translate'),
                            duration: Duration(milliseconds: 500),
                          ),
                        );
                      }
                      return;
                    }

                    HapticFeedback.lightImpact();
                    _performCleanAction(() {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => TranslationPage(
                            originalText: inputText,
                            fromLanguage: fromLanguage,
                            toLanguage: toLanguage,
                          ),
                          transitionsBuilder: (_, anim, __, child) {
                            return SlideTransition(
                              position: anim.drive(
                                Tween(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).chain(CurveTween(curve: Curves.easeOutCubic)),
                              ),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    });
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, VoidCallback? onTap}) {
    return IconButton(
      icon: Icon(icon, size: 25),
      onPressed: onTap,
      splashRadius: 22,
      color: Theme.of(context).iconTheme.color,
    );
  }
}

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