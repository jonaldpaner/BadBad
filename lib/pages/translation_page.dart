import 'package:flutter/material.dart';
import 'package:ahhhtest/components/translation_card.dart';

class TranslationPage extends StatelessWidget {
  const TranslationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TranslationCard(
                language: 'English',
                text: 'How are you today? It is nice to meet you. Life has been so challenging these days.',
                onCopyPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied English text')),
                  );
                },
                onFavoritePressed: () {
                  // favorite logic here
                },
              ),
              const SizedBox(height: 12),
              TranslationCard(
                language: 'Ata Manobo',
                text: 'Kumusta ka karon? Madayaw nga nakililala ta. Maglimbasog gayud an kinabuhi karon nga mga adlaw.',
                onCopyPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied Ata Manobo text')),
                  );
                },
                onFavoritePressed: () {
                  // favorite logic here
                },
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // goes back to Home Page
                },
                icon: const Icon(Icons.translate, color: Colors.blue),
                label: const Text(
                  'Translate More',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
