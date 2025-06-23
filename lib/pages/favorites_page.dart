import 'package:flutter/material.dart';
import 'package:ahhhtest/components/favorites_card.dart';
import 'package:ahhhtest/pages/translation_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Import for Timer

class FavoritesPageWidget extends StatefulWidget {
  const FavoritesPageWidget({Key? key}) : super(key: key);

  static String routeName = 'favorites_page';
  static String routePath = '/favoritesPage';

  @override
  State<FavoritesPageWidget> createState() => _FavoritesPageWidgetState();
}

class _FavoritesPageWidgetState extends State<FavoritesPageWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Initialize Firestore and FirebaseAuth instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State to control delayed loading indicator visibility
  bool _showLoadingIndicator = false;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    // Start a timer to show the loading indicator after a short delay (e.g., 200ms).
    // If data loads before this timer fires, the indicator will not be shown.
    _loadingTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) { // Ensure the widget is still in the tree before updating state
        setState(() {
          _showLoadingIndicator = true;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer if the widget is disposed to prevent memory leaks
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _clearAllFavorites() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to clear favorites.')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: const Text('CLEAR ALL'), // Made const
          content: const Text('Are you sure to clear all favorites? This action cannot be undone.'), // Made const
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext, false),
              child: const Text('Cancel'), // Made const
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF219EBC), // Made const
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext, true),
              child: const Text('Confirm'), // Made const
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF219EBC), // Made const
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Query for documents where either original or translated text is favorited
        final QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('translations')
            .where(Filter.or(
            Filter('isOriginalFavorited', isEqualTo: true),
            Filter('isTranslatedFavorited', isEqualTo: true)
        ))
            .get();

        WriteBatch batch = _firestore.batch();
        for (DocumentSnapshot doc in snapshot.docs) {
          // Instead of deleting the whole document, we'll just set favorite flags to false
          batch.update(doc.reference, {
            'isOriginalFavorited': false,
            'isTranslatedFavorited': false,
          });
        }
        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All favorites cleared!'), // Made const
            duration: Duration(milliseconds: 800), // Made const
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear favorites: $e')),
        );
        print('Error clearing favorites: $e');
      }
    }
  }

  void _removeFavorite(String documentId, bool isOriginal) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to manage favorites.')),
      );
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('translations')
          .doc(documentId)
          .update({
        isOriginal ? 'isOriginalFavorited' : 'isTranslatedFavorited': false,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favorite removed!'),
          duration: Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove favorite: $e')),
      );
      print('Error removing favorite: $e');
    }
  }

  // Extracted AppBar creation into a method for reusability and potential const application
  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation ?? 0,
      scrolledUnderElevation: 0, // Made const
      surfaceTintColor: theme.scaffoldBackgroundColor,
      automaticallyImplyLeading: false, // Made const
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: theme.iconTheme.color,
          size: 25, // Made const
        ),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back', // Made const
      ),
      title: Text(
        'Favorites',
        style: theme.appBarTheme.titleTextStyle,
      ),
      centerTitle: true, // Made const
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, size: 25), // Made const
          color: theme.iconTheme.color,
          onPressed: _clearAllFavorites,
          tooltip: 'Clear all favorites', // Made const
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? user = _auth.currentUser;

    // Display message if user is not logged in
    if (user == null) {
      return Scaffold(
        appBar: _buildAppBar(theme), // Use the extracted AppBar method
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Made const
            children: [
              Icon(
                Icons.login,
                size: 60, // Made const
                color: theme.iconTheme.color?.withOpacity(0.6),
              ),
              const SizedBox(height: 16), // Made const
              Text(
                'Please log in to view your favorites.', // Made const
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    }

    // StreamBuilder to fetch data from Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('translations')
          .where(Filter.or(
          Filter('isOriginalFavorited', isEqualTo: true),
          Filter('isTranslatedFavorited', isEqualTo: true)
      ))
          .orderBy('timestamp', descending: true) // Order by most recent favorite
          .snapshots(),
      builder: (context, snapshot) {
        // Conditionally show CircularProgressIndicator based on _showLoadingIndicator state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor, // Match the theme's background
            appBar: _buildAppBar(theme), // Show app bar for consistent look
            body: Center( // Center the loading indicator
              child: _showLoadingIndicator // Only show indicator if timer has fired
                  ? CircularProgressIndicator(color: theme.colorScheme.secondary)
                  : const SizedBox.shrink(), // Otherwise, show nothing to avoid flicker
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(theme), // Use the extracted AppBar method
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final List<DocumentSnapshot> documents = snapshot.data!.docs;

        if (documents.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(theme), // Use the extracted AppBar method
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Made const
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 60, // Made const
                    color: theme.iconTheme.color?.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16), // Made const
                  Text(
                    'No favorites yet.', // Made const
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(theme), // Use the extracted AppBar method
          body: SafeArea( // Made const
            child: ListView.separated(
              padding: const EdgeInsets.all(16), // Made const
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8), // Made const
              itemBuilder: (context, index) {
                final doc = documents[index];
                final data = doc.data() as Map<String, dynamic>;
                final String originalText = data['originalText'] ?? 'N/A';
                final String translatedText = data['translatedText'] ?? 'N/A';
                final bool isOriginalFavorited = data['isOriginalFavorited'] ?? false;
                final bool isTranslatedFavorited = data['isTranslatedFavorited'] ?? false;

                String displayedText;
                bool isOriginal;
                if (isOriginalFavorited) {
                  displayedText = originalText;
                  isOriginal = true;
                } else if (isTranslatedFavorited) {
                  displayedText = translatedText;
                  isOriginal = false;
                } else {
                  displayedText = originalText;
                  isOriginal = true;
                }

                return FavoritesCardWidget(
                  text: displayedText,
                  contentType: data['type'] ?? 'text',
                  documentId: doc.id,
                  isOriginalTextFavorited: isOriginal,
                  onFavoriteRemoved: _removeFavorite,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TranslationPage(
                          originalText: originalText,
                          fromLanguage: data['fromLanguage'] ?? 'English',
                          toLanguage: data['toLanguage'] ?? 'Ata Manobo',
                          initialTranslatedText: translatedText,
                          initialIsOriginalFavorited: isOriginalFavorited,
                          initialIsTranslatedFavorited: isTranslatedFavorited,
                          documentId: doc.id, // <-- make sure this is not null
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
