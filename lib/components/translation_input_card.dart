import 'dart:ui';
import 'package:flutter/material.dart';
import 'language_selector.dart';

class TranslationInputCard extends StatefulWidget {
  final String fromLanguage;
  final String toLanguage;
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onCameraPressed;
  final VoidCallback onTranslatePressed;
  final Widget? languageSelector;

  const TranslationInputCard({
    Key? key,
    required this.fromLanguage,
    required this.toLanguage,
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
  final int _maxLength = 70;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : const Color(0xFFE6EAED),
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
                      const LanguageSelector(),
                ),
                const SizedBox(height: 4),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: TextFormField(
                        controller: widget.textController,
                        focusNode: widget.focusNode,
                        maxLength: _maxLength,
                        maxLines: null,
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
                              : const Color(0xFFEBEEF1),
                          border: const OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.textController,
                      builder: (context, value, _) {
                        final currentLength = value.text.length;
                        final isLimitReached = currentLength >= _maxLength;
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8, right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLimitReached)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              Text(
                                '$currentLength/$_maxLength',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLimitReached
                                      ? Colors.red
                                      : isDark
                                      ? Colors.white70
                                      : Colors.grey[600],
                                  fontWeight: isLimitReached
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: isDark
                          ? Colors.grey[850]
                          : const Color(0xA3CCD6DA),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        splashColor:
                        (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.1),
                        highlightColor:
                        (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.05),
                        onTap: widget.onCameraPressed,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 24,
                          ),
                        ),
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
      ),
    );
  }
}
