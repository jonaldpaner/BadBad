// pages/favorites_page.dart
import 'package:flutter/material.dart';
import 'package:ahhhtest/components/favorites_card.dart'; // Ensure this import is correct
import 'package:ahhhtest/pages/translation_page.dart'; // Ensure this import is correct
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _showLoadingIndicator = false;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _loadingTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _showLoadingIndicator = true;
        });
      }
    });
  }

  // loading time
  @override
  void dispose() {
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
          title: const Text('CLEAR ALL'),
          content: const Text('Are you sure to clear all favorites? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext, false),
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF219EBC),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext, true),
              child: const Text('Confirm'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF219EBC),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // --- IMPORTANT CHANGE HERE ---
        // Query favorited items from the 'favorites' collection
        final QuerySnapshot favoritesSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .get();

        WriteBatch batch = _firestore.batch();
        for (DocumentSnapshot doc in favoritesSnapshot.docs) {
          // Delete from the 'favorites' collection
          batch.delete(doc.reference);

          // Also, update the corresponding document in the 'translations' (history) collection
          // to set their favorite flags to false, maintaining consistency.
          final historyDocRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('translations')
              .doc(doc.id); // Use the same document ID

          batch.update(historyDocRef, {
            'isOriginalFavorited': false,
            'isTranslatedFavorited': false,
          });
        }
        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All favorites cleared!'),
            duration: Duration(milliseconds: 800),
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
      final DocumentReference favoriteDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(documentId);

      final DocumentReference historyDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('translations')
          .doc(documentId);

      // Get current favorite document to determine if both are being unfavorited
      final DocumentSnapshot favoriteSnapshot = await favoriteDocRef.get();
      if (!favoriteSnapshot.exists) return; // Should not happen if item is displayed

      final Map<String, dynamic> data = favoriteSnapshot.data() as Map<String, dynamic>;
      bool currentIsOriginalFavorited = data['isOriginalFavorited'] ?? false;
      bool currentIsTranslatedFavorited = data['isTranslatedFavorited'] ?? false;

      // Determine the new favorite statuses
      bool newIsOriginalFavorited = isOriginal ? false : currentIsOriginalFavorited;
      bool newIsTranslatedFavorited = !isOriginal ? false : currentIsTranslatedFavorited;

      if (!newIsOriginalFavorited && !newIsTranslatedFavorited) {
        // If both become false, delete the document from favorites collection
        await favoriteDocRef.delete();
        // Also update the history document to reflect unfavorited status
        await historyDocRef.update({
          'isOriginalFavorited': false,
          'isTranslatedFavorited': false,
        });
      } else {
        // Otherwise, just update the specific favorite flag in the favorites document
        await favoriteDocRef.update({
          isOriginal ? 'isOriginalFavorited' : 'isTranslatedFavorited': false,
        });
        // Also update the history document to reflect unfavorited status
        await historyDocRef.update({
          isOriginal ? 'isOriginalFavorited' : 'isTranslatedFavorited': false,
        });
      }

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

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation ?? 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: theme.scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
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
        'Favorites',
        style: theme.appBarTheme.titleTextStyle,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined, size: 25),
          color: theme.iconTheme.color,
          onPressed: _clearAllFavorites,
          tooltip: 'Clear all favorites',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: _buildAppBar(theme),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 60,
                color: theme.iconTheme.color?.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to view your favorites.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    }

    // StreamBuilder to fetch data from Firestore
    return StreamBuilder<QuerySnapshot>(
      // --- IMPORTANT CHANGE HERE ---
      // Stream from the NEW 'favorites' collection
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
      // No need for Filter.or here, as documents in 'favorites' only exist if favorited
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: _buildAppBar(theme),
            body: Center(
              child: _showLoadingIndicator
                  ? CircularProgressIndicator(color: theme.colorScheme.secondary)
                  : const SizedBox.shrink(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(theme),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final List<DocumentSnapshot> documents = snapshot.data!.docs;

        if (documents.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(theme),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: theme.iconTheme.color?.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet.',
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
          appBar: _buildAppBar(theme),
          body: SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                  // Prioritize displaying original if both are favorited or only original
                  displayedText = originalText;
                  isOriginal = true;
                } else if (isTranslatedFavorited) {
                  displayedText = translatedText;
                  isOriginal = false;
                } else {
                  // Fallback: This case should ideally not happen if query filters correctly
                  // but if it does, show original and treat as original favorite context.
                  displayedText = originalText;
                  isOriginal = true;
                }

                return FavoritesCardWidget(
                  text: displayedText,
                  contentType: data['type'] ?? 'text', // Make sure 'type' is saved in favorites collection
                  documentId: doc.id,
                  isOriginalTextFavorited: isOriginal,
                  onFavoriteRemoved: _removeFavorite,
                  onTap: () {
                    // --- Ensure documentId is passed to TranslationPage ---
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
                          documentId: doc.id, // Pass doc ID
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