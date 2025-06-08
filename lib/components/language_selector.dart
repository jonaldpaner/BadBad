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
  double _rotationTurns = 0.0;

  void _swapLanguages() {
    setState(() {
      final temp = sourceLanguage;
      sourceLanguage = targetLanguage;
      targetLanguage = temp;
      _rotationTurns += 0.5;
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
        style: theme.textTheme.bodyLarge,
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
          AnimatedRotation(
            turns: _rotationTurns,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: GestureDetector(
              onTap: _swapLanguages,
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
