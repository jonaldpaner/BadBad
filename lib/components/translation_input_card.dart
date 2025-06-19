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
  late String _fromLanguage;
  late String _toLanguage;

  @override
  void initState() {
    super.initState();
    _fromLanguage = widget.fromLanguage;
    _toLanguage = widget.toLanguage;
  }

  // No need for _handleToggleLanguages here if it's just calling widget.onToggleLanguages
  // You can directly call widget.onToggleLanguages in the GestureDetector onTap
  // But keeping it here is also fine if you plan to add more internal logic.
  void _handleToggleLanguages() {
    setState(() {
      final temp = _fromLanguage;
      _fromLanguage = _toLanguage;
      _toLanguage = temp;
    });
    widget.onToggleLanguages(); // Calls the HomePage's toggleLanguages
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black
                : const Color.fromRGBO(230, 234, 237, 1),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: widget.languageSelector ??
                    GestureDetector(
                      onTap: _handleToggleLanguages,
                      child: Container(
                        width: 250,
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black : const Color.fromRGBO(230, 234, 237, 1),
                          borderRadius: const BorderRadius.all(Radius.circular(24)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: _scaleTransitionBuilder,
                                  child: Text(
                                    _fromLanguage,
                                    key: ValueKey('from_lang_${_fromLanguage}'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.swap_horiz,
                                size: 20, color: isDark ? Colors.white : Colors.black),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: _scaleTransitionBuilder,
                                  child: Text(
                                    _toLanguage,
                                    key: ValueKey('to_lang_${_toLanguage}'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: TextFormField(
                  controller: widget.textController,
                  focusNode: widget.focusNode,
                  autofocus: false,
                  maxLines: null,
                  maxLength: 300,
                  keyboardType: TextInputType.multiline,
                  scrollPhysics: const BouncingScrollPhysics(),
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
                        : const Color.fromRGBO(230, 234, 237, 1),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
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
                        fontSize: 12,
                        color: currentLength > maxLength!
                            ? Colors.red
                            : isDark
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: isDark
                        ? Colors.grey[850]
                        : const Color(0xA3CCD6DA),
                    child: IconButton(
                      icon: Icon(Icons.camera_alt_outlined,
                          color: isDark ? Colors.white : Colors.black),
                      onPressed: widget.onCameraPressed,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onTranslatePressed,
                    icon: const Icon(
                      Icons.auto_awesome_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Translate',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF219EBC),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _scaleTransitionBuilder(Widget child, Animation<double> animation) {
    return ScaleTransition(scale: animation, child: child);
  }
}