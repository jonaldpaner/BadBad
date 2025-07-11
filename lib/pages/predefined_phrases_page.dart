import 'package:flutter/material.dart';

class PredefinedPhrasesPage extends StatelessWidget {
  const PredefinedPhrasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final phrases = [
      {'ata': 'Kasi-kasi', 'english': 'Hello'},
      {'ata': 'Kumusta ka?', 'english': 'How are you?'},
      {'ata': 'Salamat', 'english': 'Thank you'},
      {'ata': 'Baybay', 'english': 'Goodbye'},
      {'ata': 'Pasensya', 'english': 'Sorry'},
      {'ata': 'Wala ko kasabot', 'english': 'I don’t understand'},
      {'ata': 'Tabang!', 'english': 'Help!'},
      {'ata': 'Pila ini?', 'english': 'How much is this?'},
      {'ata': 'Asa ang banyo?', 'english': 'Where is the bathroom?'},
      {'ata': 'Lami', 'english': 'Delicious'},
    ];

    return Scaffold(
      appBar: buildAppBar(context, theme),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: phrases.length,
        itemBuilder: (context, index) {
          final phrase = phrases[index];
          return Card(
            color: theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            elevation: theme.brightness == Brightness.dark ? 2 : 4,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              title: Text(
                phrase['ata'] ?? '',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                phrase['english'] ?? '',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.9),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation ?? 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: theme.iconTheme.color,
          size: 25,
        ),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back',
      ),
      title: Text(
        'Learn',
        style: theme.appBarTheme.titleTextStyle,
      ),
      centerTitle: true,
    );
  }
}
