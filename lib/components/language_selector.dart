import 'package:flutter/material.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final String sourceLanguage = 'Ata Manobo';
  final String targetLanguage = 'English';


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
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.transparent,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.arrow_right_alt, size: 22, color: theme.iconTheme.color),
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