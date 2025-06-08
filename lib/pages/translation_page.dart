import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ahhhtest/components/translation_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADDED: Firestore import
import 'package:firebase_auth/firebase_auth.dart'; // ADDED: Auth import to get current user ID

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

  // Initializing Firestore and FirebaseAuth instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _mockTranslate(String input, String from, String to) {
    // For now, keep this static. You can integrate an actual API later.
    return "Translated: $input (from $from to $to)";
  }

  // ADDED: Method to save translation history to Firestore
  Future<void> _saveTranslationHistory(String originalText, String translatedText) async {
    final User? user = _auth.currentUser; // Get the currently logged-in user

    if (user != null) {
      // If a user is logged in, save to their specific collection
      await _firestore.collection('users')
          .doc(user.uid) // Use user's UID as document ID for their data
          .collection('translations') // Subcollection for translations
          .add({
        'originalText': originalText,
        'translatedText': translatedText,
        'fromLanguage': widget.fromLanguage,
        'toLanguage': widget.toLanguage,
        'timestamp': FieldValue.serverTimestamp(), // Firestore generates server timestamp
        'isOriginalFavorited': isOriginalFavorited, // Store current favorite status
        'isTranslatedFavorited': isTranslatedFavorited, // Store current favorite status
        'type': 'text', // Assuming text input for now, can be 'camera' later
      });
      // Optional: Show a confirmation, or just let it happen silently
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Translation saved to history!')),
      // );
    } else {
      // Handle cases where the user is not logged in
      // For a translation app, you might still want to save history locally (e.g., SharedPreferences)
      // or simply not save history for guest users.
      print('User not logged in. Translation history not saved to Firestore.');
    }
  }

  @override
  void initState() {
    super.initState();
    // CALL THE SAVE METHOD AFTER THE WIDGET IS BUILT (or once the translation is ready)
    // Using a post-frame callback ensures the context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final translatedText = _mockTranslate(widget.originalText, widget.fromLanguage, widget.toLanguage);
      _saveTranslationHistory(widget.originalText, translatedText);
    });
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
                        duration: Duration(milliseconds: 500),
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
