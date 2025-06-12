import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ahhhtest/components/translation_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // Import for JSON decoding

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

  String? _currentTranslationDocId;
  String _translatedText = ''; // State variable to hold the actual translated text
  bool _isLoadingTranslation = true; // State to manage loading indicator

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Corrected to use .auth for consistency

  // NEW: Asynchronous function to fetch translation from the API
  Future<String> _fetchTranslation(String message) async {
    // Only proceed if 'fromLanguage' is 'Ata Manobo'
    if (widget.fromLanguage == 'Ata Manobo') {
      try {
        final encodedMessage = Uri.encodeComponent(message); // Encode the message for the URL
        final url = Uri.parse('https://badbad-api.onrender.com/translate/ata?message=$encodedMessage');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          // Extract the 'translation' field, handle potential null/missing
          return data['translation']?.toString() ?? 'Translation not found.';
        } else {
          print('Failed to load translation: ${response.statusCode}');
          return 'Error: Could not translate (Status Code: ${response.statusCode})';
        }
      } catch (e) {
        print('Error fetching translation: $e');
        return 'Error: Could not translate (Network Error)';
      }
    } else {
      // If fromLanguage is not 'Ata Manobo', return an empty string as requested
      return '';
    }
  }

  // Method to save translation history to Firestore and get the document ID
  Future<void> _saveTranslationHistory(String originalText, String translatedText) async {
    final User? user = _auth.currentUser;

    if (user != null) {
      try {
        final docRef = await _firestore.collection('users')
            .doc(user.uid)
            .collection('translations')
            .add({
          'originalText': originalText,
          'translatedText': translatedText,
          'fromLanguage': widget.fromLanguage,
          'toLanguage': widget.toLanguage,
          'timestamp': FieldValue.serverTimestamp(),
          'isOriginalFavorited': isOriginalFavorited,
          'isTranslatedFavorited': isTranslatedFavorited,
          'type': 'text',
        });
        _currentTranslationDocId = docRef.id;
        print('Translation history saved to Firestore. Doc ID: $_currentTranslationDocId');
      } catch (e) {
        print('Error saving translation history to Firestore: $e');
      }
    } else {
      print('User not logged in. Translation history not saved to Firestore.');
    }
  }

  // Method to update the favorite status in Firestore
  Future<void> _updateFavoriteStatusInFirestore(String fieldName, bool value) async {
    final User? user = _auth.currentUser;

    if (user != null && _currentTranslationDocId != null) {
      try {
        await _firestore.collection('users')
            .doc(user.uid)
            .collection('translations')
            .doc(_currentTranslationDocId!)
            .update({
          fieldName: value,
        });
        print('Firestore updated: $fieldName to $value for $_currentTranslationDocId');
      } catch (e) {
        print('Error updating $fieldName in Firestore: $e');
      }
    } else if (user == null) {
      print('User not logged in. Cannot update favorite status in Firestore.');
    } else {
      print('No translation document ID available to update favorite status.');
    }
  }

  @override
  void initState() {
    super.initState();
    // Start fetching translation when the page initializes
    _fetchAndSaveTranslation();
  }

  // New method to orchestrate fetching translation and saving history
  Future<void> _fetchAndSaveTranslation() async {
    setState(() {
      _isLoadingTranslation = true; // Show loading indicator
      _translatedText = ''; // Clear previous translation
    });

    final fetchedText = await _fetchTranslation(widget.originalText);

    setState(() {
      _translatedText = fetchedText; // Update with fetched translation
      _isLoadingTranslation = false; // Hide loading indicator
    });

    // Save history only after translation is available
    await _saveTranslationHistory(widget.originalText, _translatedText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      SnackBar(
                        content: const Text('Original text copied to clipboard'),
                        duration: const Duration(milliseconds: 500),
                        backgroundColor: theme.snackBarTheme.backgroundColor ?? theme.colorScheme.secondary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onFavoritePressed: () {
                    setState(() {
                      isOriginalFavorited = !isOriginalFavorited;
                    });
                    _updateFavoriteStatusInFirestore('isOriginalFavorited', isOriginalFavorited);
                  },
                ),
                const SizedBox(height: 16),
                // Display loading indicator or translated text
                _isLoadingTranslation
                    ? Center(
                  child: CircularProgressIndicator(color: theme.colorScheme.primary),
                )
                    : TranslationCard(
                  language: widget.toLanguage,
                  text: _translatedText, // Use the state variable
                  isFavorited: isTranslatedFavorited,
                  onCopyPressed: () {
                    Clipboard.setData(ClipboardData(text: _translatedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Translated text copied to clipboard'),
                        duration: const Duration(milliseconds: 500),
                        backgroundColor: theme.snackBarTheme.backgroundColor ?? theme.colorScheme.secondary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onFavoritePressed: () {
                    setState(() {
                      isTranslatedFavorited = !isTranslatedFavorited;
                    });
                    _updateFavoriteStatusInFirestore('isTranslatedFavorited', isTranslatedFavorited);
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
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(Icons.translate,color: const Color(0xFF219EBC)
      ),
      label: Text(
        'Translate More',
        style: TextStyle(fontSize: 16,color: const Color(0xFF219EBC)
        ),
      ),
    );
  }
}