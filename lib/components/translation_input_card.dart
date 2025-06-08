import 'dart:ui';
import 'package:flutter/material.dart';

class TranslationInputCard extends StatelessWidget {
  final String fromLanguage;
  final VoidCallback onToggleLanguages;
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onCameraPressed;
  final VoidCallback onTranslatePressed;

  const TranslationInputCard({
    Key? key,
    required this.fromLanguage,
    required this.onToggleLanguages,
    required this.textController,
    required this.focusNode,
    required this.onCameraPressed,
    required this.onTranslatePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32, left: 50, right: 50),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black
                  : const Color.fromRGBO(230, 234, 237, 1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      fromLanguage,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.compare_arrows_outlined,
                          color: isDark ? Colors.white : Colors.black),
                      onPressed: onToggleLanguages,
                      tooltip: 'Switch languages',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: TextFormField(
                    controller: textController,
                    focusNode: focusNode,
                    maxLines: null,
                    maxLength: 300,
                    keyboardType: TextInputType.multiline,
                    scrollPhysics: const BouncingScrollPhysics(),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
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
                      backgroundColor:
                      isDark ? Colors.grey[850] : const Color(0xA3CCD6DA),
                      child: IconButton(
                        icon: Icon(Icons.camera_alt_outlined,
                            color: isDark ? Colors.white : Colors.black),
                        onPressed: onCameraPressed,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onTranslatePressed,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
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
