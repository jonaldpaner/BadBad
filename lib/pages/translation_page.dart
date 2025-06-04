import 'package:flutter/material.dart';
import 'package:ahhhtest/components/translation_card.dart';

class TranslationPage extends StatelessWidget {
  const TranslationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TranslationCard(
                language: 'English',
                text:
                'How are you today? It is nice to meet you. Life has been so challenging these days.',
                onCopyPressed: null,
                onFavoritePressed: null,
              ),
              SizedBox(height: 12),
              TranslationCard(
                language: 'Ata Manobo',
                text:
                'Kumusta ka karon? Madayaw nga nakililala ta. Maglimbasog gayud an kinabuhi karon nga mga adlaw.',
                onCopyPressed: null,
                onFavoritePressed: null,
              ),
              SizedBox(height: 16),
              _TranslateMoreButton(),
              SizedBox(height: 24),
            ],
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
      onPressed: () {
        Navigator.of(context).pop();
      },
      icon: const Icon(Icons.translate, color: Colors.blue),
      label: const Text(
        'Translate More',
        style: TextStyle(fontSize: 16, color: Colors.blue),
      ),
    );
  }
}
