// lib/components/language_selector.dart
import 'package:flutter/material.dart';

class LanguageSelector extends StatefulWidget {
  final void Function(String source, String target)? onLanguageChanged;

  const LanguageSelector({Key? key, this.onLanguageChanged}) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String sourceLanguage = 'English';
  String targetLanguage = 'Ata Manobo';

  void _swapLanguages() {
    setState(() {
      final temp = sourceLanguage;
      sourceLanguage = targetLanguage;
      targetLanguage = temp;
    });

    widget.onLanguageChanged?.call(sourceLanguage, targetLanguage);
  }

  Widget _buildLanguageChip(String language, Key key) {
    final theme = Theme.of(context);

    return Center(
      key: key,
      child: Text(
        language,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex: 3,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _buildLanguageChip(sourceLanguage, ValueKey(sourceLanguage)),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _swapLanguages,
            child: Container(
              width: 48.0, // Adjust as needed for the circle size and hitbox
              height: 48.0, // Adjust as needed
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.transparent,
                  width: 1.5, // Adjust border thickness
                ),
              ),
              alignment: Alignment.center, // Center the icon within the circle
              child: Icon(Icons.swap_horiz, size: 22, color: theme.iconTheme.color),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _buildLanguageChip(targetLanguage, ValueKey(targetLanguage)),
            ),
          ),
        ],
      ),
    );
  }
}
