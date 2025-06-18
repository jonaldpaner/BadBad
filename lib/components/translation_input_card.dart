import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';

class TranslationInputCard extends StatefulWidget {
  final String fromLanguage;
  final String toLanguage;
  final VoidCallback onToggleLanguages;
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onCameraPressed;
  final VoidCallback onTranslatePressed;
  final Widget? languageSelector;

  const TranslationInputCard({
    Key? key,
    required this.fromLanguage,
    required this.toLanguage,
    required this.onToggleLanguages,
    required this.textController,
    required this.focusNode,
    required this.onCameraPressed,
    required this.onTranslatePressed,
    this.languageSelector,
  }) : super(key: key);

  @override
  State<TranslationInputCard> createState() => _TranslationInputCardState();
}

class _TranslationInputCardState extends State<TranslationInputCard> {
  // Removed _rotationTurns as rotation animation is no longer desired.
  // Initialize languages from widget properties
  late String _fromLanguage;
  late String _toLanguage;

  @override
  void initState() {
    super.initState();
    _fromLanguage = widget.fromLanguage;
    _toLanguage = widget.toLanguage;
  }

  // Update languages on toggle
  void _handleToggleLanguages() {
    setState(() {
      final temp = _fromLanguage;
      _fromLanguage = _toLanguage;
      _toLanguage = temp;
      // Rotation logic removed.
    });
    // Call the parent's toggle function
    widget.onToggleLanguages();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32, left: 25, right: 25),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)), // Made const
        child: BackdropFilter(
          // IMPORTANT PERFORMANCE NOTE: BackdropFilter can be very performance-intensive,
          // especially with high sigma values like 20. If you experience jank/low FPS
          // during animations or general usage, try reducing sigmaX and sigmaY (e.g., to 10 or 5)
          // or consider removing this effect if performance is critical.
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16), // Made const
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black
                  : const Color.fromRGBO(230, 234, 237, 1), // Made const for light mode color
              borderRadius: const BorderRadius.all(Radius.circular(24)), // Made const
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Use custom LanguageSelector if provided
                Align(
                  alignment: Alignment.centerLeft, // Made const
                  child: widget.languageSelector ??
                      GestureDetector(
                        onTap: _handleToggleLanguages,
                        child: Container(
                          width: 250, // Keep pill size fixed
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12), // Made const
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black : const Color.fromRGBO(230, 234, 237, 1), // Made const for light mode color
                            borderRadius: const BorderRadius.all(Radius.circular(24)), // Made const
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, // Made const
                            children: [
                              Expanded( // This Expanded widget should not be const if its child (AnimatedSwitcher) is dynamic
                                child: Align(
                                  alignment: Alignment.centerLeft, // Made const
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300), // Made const
                                    transitionBuilder: _scaleTransitionBuilder, // Moved to a static method/function
                                    child: Text(
                                      _fromLanguage, // Actual value used here
                                      key: ValueKey('from_lang_${_fromLanguage}'), // Updated key for AnimatedSwitcher
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis, // Made const
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10), // Made const
                              // Replaced AnimatedRotation with a static Icon
                              Icon(Icons.swap_horiz,
                                  size: 20, color: isDark ? Colors.white : Colors.black),
                              const SizedBox(width: 10), // Made const
                              Expanded( // This Expanded widget should not be const if its child (AnimatedSwitcher) is dynamic
                                child: Align(
                                  alignment: Alignment.centerRight, // Made const
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300), // Made const
                                    transitionBuilder: _scaleTransitionBuilder, // Moved to a static method/function
                                    child: Text(
                                      _toLanguage, // Actual value used here
                                      key: ValueKey('to_lang_${_toLanguage}'), // Updated key for AnimatedSwitcher
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis, // Made const
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
                const SizedBox(height: 4), // Made const
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150), // Made const
                  child: TextFormField(
                    controller: widget.textController,
                    focusNode: widget.focusNode,
                    maxLines: null,
                    maxLength: 300,
                    keyboardType: TextInputType.multiline, // Made const
                    scrollPhysics: const BouncingScrollPhysics(), // Made const
                    cursorColor: isDark ? Colors.white : Colors.black,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Type or paste text here',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.grey[900]
                          : const Color.fromRGBO(230, 234, 237, 1), // Made const for light mode color
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(12)), // Made const
                        borderSide: BorderSide.none, // Made const
                      ),
                    ),
                    style:
                    TextStyle(color: isDark ? Colors.white : Colors.black),
                    buildCounter: (context,
                        {required currentLength,
                          maxLength,
                          required isFocused}) {
                      return Text(
                        '$currentLength / $maxLength',
                        style: TextStyle(
                          fontSize: 12, // Made const
                          color: currentLength > maxLength!
                              ? Colors.red // Made const
                              : isDark
                              ? Colors.white70 // Made const
                              : Colors.grey[600], // Made const
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12), // Made const

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Made const
                  children: [
                    CircleAvatar(
                      backgroundColor: isDark
                          ? Colors.grey[850]
                          : const Color(0xA3CCD6DA), // Made const for light mode color
                      child: IconButton(
                        icon: Icon(Icons.camera_alt_outlined,
                            color: isDark ? Colors.white : Colors.black),
                        onPressed: widget.onCameraPressed,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.onTranslatePressed,
                      icon: const Icon( // Made const
                        Icons.auto_awesome_outlined,
                        color: Colors.white, // Made const
                      ),
                      label: const Text( // Made const
                        'Translate',
                        style: TextStyle(color: Colors.white), // Made const
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF219EBC), // Made const
                        shape: const RoundedRectangleBorder( // Made const
                          borderRadius: BorderRadius.all(Radius.circular(24)), // Made const
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function for AnimatedSwitcher transitionBuilder
  static Widget _scaleTransitionBuilder(Widget child, Animation<double> animation) {
    return ScaleTransition(scale: animation, child: child);
  }
}
