import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for clipboard
import 'package:ahhhtest/components/translation_card.dart'; // your card import

class TranslationPage extends StatefulWidget {
  final String originalText;
  final String fromLanguage;
  final String toLanguage;

  const TranslationPage({
    Key? key,
    required this.originalText,
    required this.fromLanguage,
    required this.toLanguage,
  }) : super(key: key);

  @override
  _TranslationPageState createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  bool isOriginalFavorited = false;
  bool isTranslatedFavorited = false;

  String _mockTranslate(String input, String from, String to) {
    return " $input";
  }

  @override
  Widget build(BuildContext context) {
    final translatedText = _mockTranslate(widget.originalText, widget.fromLanguage, widget.toLanguage);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TranslationCard(
                  language: widget.fromLanguage,
                  text: widget.originalText,
                  isFavorited: isOriginalFavorited,
                  onCopyPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.originalText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Original text copied to clipboard'),
                        duration: Duration(milliseconds: 500), // Show for only 2 seconds
                      ),
                    );
                  },
                  onFavoritePressed: () {
                    setState(() {
                      isOriginalFavorited = !isOriginalFavorited;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TranslationCard(
                  language: widget.toLanguage,
                  text: translatedText,
                  isFavorited: isTranslatedFavorited,
                  onCopyPressed: () {
                    Clipboard.setData(ClipboardData(text: translatedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Translated text copied to clipboard'),
                        duration: Duration(milliseconds: 500), // Show for only 2 seconds
                      ),
                    );
                  },
                  onFavoritePressed: () {
                    setState(() {
                      isTranslatedFavorited = !isTranslatedFavorited;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const _TranslateMoreButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TranslateMoreButton extends StatelessWidget {
  const _TranslateMoreButton();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.translate, color: Colors.blue),
      label: const Text(
        'Translate More',
        style: TextStyle(fontSize: 16, color: Colors.blue),
      ),
    );
  }
}
