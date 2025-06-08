import 'package:flutter/material.dart';
import 'package:ahhhtest/components/favorites_card.dart';
import 'package:ahhhtest/pages/translation_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADDED: Firestore import
import 'package:firebase_auth/firebase_auth.dart';     // ADDED: Auth import

class FavoritesPageWidget extends StatefulWidget {
  const FavoritesPageWidget({Key? key}) : super(key: key);

  static String routeName = 'favorites_page';
  static String routePath = '/favoritesPage';

  @override
  State<FavoritesPageWidget> createState() => _FavoritesPageWidgetState();
}

class _FavoritesPageWidgetState extends State<FavoritesPageWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // ADDED: Initialize Firestore and FirebaseAuth instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // REMOVED: No longer need the local _favorites list

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
      builder: (context) {
        return AlertDialog(
          title: const Text('CLEAR ALL'),
          content: const Text('Are you sure to clear all favorites? This action cannot be undone.'),
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
            content: Text('All favorites cleared!'),
            duration: Duration(milliseconds: 500),
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

  // MODIFIED: _removeFavorite now updates Firestore
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
          duration: Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove favorite: $e')),
      );
      print('Error removing favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? user = _auth.currentUser; // Get current user here

    // Display message if user is not logged in
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.iconTheme.color, size: 25),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          title: Text(
            'Favorites',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, size: 25),
              color: theme.iconTheme.color,
              onPressed: _clearAllFavorites,
              tooltip: 'Clear all favorites',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 60, color: theme.iconTheme.color?.withOpacity(0.6)),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final List<DocumentSnapshot> documents = snapshot.data!.docs;

        if (documents.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 30),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              title: const Text(
                'Favorites',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
              ),
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 30),
                  color: Colors.black,
                  onPressed: _clearAllFavorites,
                  tooltip: 'Clear all favorites',
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 60, color: theme.iconTheme.color?.withOpacity(0.6)),
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
          appBar: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 30),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
            title: const Text(
              'Favorites',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, size: 30),
                color: Colors.black,
                onPressed: _clearAllFavorites,
                tooltip: 'Clear all favorites',
              ),
            ],
          ),
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

                // Determine which text to show as favorite in the card
                String displayedText;
                bool isOriginal; // To pass to _removeFavorite
                if (isOriginalFavorited) {
                  displayedText = originalText;
                  isOriginal = true;
                } else if (isTranslatedFavorited) {
                  displayedText = translatedText;
                  isOriginal = false;
                } else {
                  // Fallback: This case should ideally not happen if query is correct
                  displayedText = originalText;
                  isOriginal = true;
                }

                return FavoritesCardWidget(
                  text: displayedText,
                  onFavoritePressed: () => _removeFavorite(doc.id, isOriginal),
                  onTap: () {
                    // Navigate to TranslationPage, passing the original and translated text
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TranslationPage(
                          originalText: originalText,
                          fromLanguage: data['fromLanguage'] ?? 'English', // Pass actual languages
                          toLanguage: data['toLanguage'] ?? 'Ata Manobo',
                          // You might want to pass the document ID here if you want to
                          // display the exact saved state in TranslationPage (including favorite flags)
                          // For simplicity, we are passing the text values for now.
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