// translation_input_card.dart
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
              color: const Color.fromRGBO(230, 234, 237, 1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      fromLanguage,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.compare_arrows_outlined),
                      onPressed: onToggleLanguages,
                      tooltip: 'Switch languages',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 150, // max height you want, adjust as needed
                  ),
                  child: TextFormField(
                    controller: textController,
                    focusNode: focusNode,
                    maxLines: null, // allow multiline
                    maxLength: 300,
                    keyboardType: TextInputType.multiline,
                    scrollPhysics: const BouncingScrollPhysics(), // enable scrolling inside field
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Type or paste text here',
                      filled: true,
                      fillColor: const Color.fromRGBO(230, 234, 237, 1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    buildCounter: (context,
                        {required currentLength, maxLength, required isFocused}) {
                      return Text(
                        '$currentLength / $maxLength',
                        style: TextStyle(
                          fontSize: 12,
                          color: currentLength > maxLength! ? Colors.red : Colors.grey[600],
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
                      backgroundColor: const Color.fromRGBO(204, 214, 218, 0.64),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
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
                        backgroundColor: const Color.fromRGBO(33, 158, 188, 1),
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
