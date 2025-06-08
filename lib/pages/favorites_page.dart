import 'package:flutter/material.dart';
import 'package:ahhhtest/components/favorites_card.dart';
import 'package:ahhhtest/pages/translation_page.dart';

class FavoritesPageWidget extends StatefulWidget {
  const FavoritesPageWidget({Key? key}) : super(key: key);

  static String routeName = 'favorites_page';
  static String routePath = '/favoritesPage';

  @override
  State<FavoritesPageWidget> createState() => _FavoritesPageWidgetState();
}

class _FavoritesPageWidgetState extends State<FavoritesPageWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> _favorites = [
    'Hello, how are you today?',
    'This is another favorite message',
  ];

  void _clearAllFavorites() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('CLEAR ALL'),
          content: const Text('Are you sure to clear all favorites?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _favorites.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All favorites cleared'),
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _removeFavorite(int index) {
    setState(() {
      _favorites.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 30),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          title: Text(
            'Favorites',
            style: theme.appBarTheme.titleTextStyle,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, size: 30),
              onPressed: _clearAllFavorites,
              tooltip: 'Clear all favorites',
            ),
          ],
        ),
        body: SafeArea(
          child: _favorites.isEmpty
              ? Center(
            child: Text(
              'No favorites yet',
              style: theme.textTheme.titleMedium,
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final text = _favorites[index];
              return FavoritesCardWidget(
                text: text,
                onFavoritePressed: () => _removeFavorite(index),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TranslationPage(
                        originalText: text,
                        fromLanguage: "English",
                        toLanguage: "Ata Manobo",
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
