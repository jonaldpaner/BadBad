// pages/translation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ahhhtest/components/translation_card.dart'; // Ensure this path is correct
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationPage extends StatefulWidget {
  final String originalText;
  final String fromLanguage;
  final String toLanguage;
  final String? initialTranslatedText;
  final bool? initialIsOriginalFavorited;
  final bool? initialIsTranslatedFavorited;
  final String? documentId; // This documentId is crucial for linking history and favorites

  const TranslationPage({
    Key? key,
    required this.originalText,
    required this.fromLanguage,
    required this.toLanguage,
    this.initialTranslatedText,
    this.initialIsOriginalFavorited,
    this.initialIsTranslatedFavorited,
    this.documentId,
  }) : super(key: key);

  @override
  _TranslationPageState createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  // These states reflect the current favorite status in the UI
  bool _isOriginalFavorited = false;
  bool _isTranslatedFavorited = false;

  String? _currentTranslationDocId; // Stores the document ID for the current translation
  String _translatedText = '';
  bool _isLoadingTranslation = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Initialize state from widget properties
    _currentTranslationDocId = widget.documentId;
    _isOriginalFavorited = widget.initialIsOriginalFavorited ?? false;
    _isTranslatedFavorited = widget.initialIsTranslatedFavorited ?? false;

    // Decide whether to fetch a new translation or use the initial one
    if (widget.initialTranslatedText != null && widget.initialTranslatedText!.isNotEmpty) {
      _translatedText = widget.initialTranslatedText!;
      _isLoadingTranslation = false;
    } else {
      // If no initial translation, fetch it and save to history
      _fetchNewTranslationAndSaveHistory();
    }
  }

  // Fetches translation from API
  Future<String> _fetchTranslation(String message) async {
    String? apiEndpoint;
    if (widget.fromLanguage == 'Ata Manobo') {
      apiEndpoint = 'ata';
    } else if (widget.fromLanguage == 'English') {
      apiEndpoint = 'eng';
    } else {
      return 'Unsupported language for translation.';
    }

    try {
      final encodedMessage = Uri.encodeComponent(message);
      final url = Uri.parse('https://badbad-api.onrender.com/translate/$apiEndpoint?message=$encodedMessage');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['translation']?.toString() ?? 'Translation not found.';
      } else {
        return 'Error: Could not translate (Status Code: ${response.statusCode})';
      }
    } catch (e) {
      return 'Error: Could not translate (Network Error)';
    }
  }

  // Saves a brand new translation to history
  Future<void> _saveNewTranslationHistory(String originalText, String translatedText) async {
    final User? user = _auth.currentUser;

    if (user != null) {
      try {
        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('translations')
            .add({
          'originalText': originalText,
          'translatedText': translatedText,
          'fromLanguage': widget.fromLanguage,
          'toLanguage': widget.toLanguage,
          'timestamp': FieldValue.serverTimestamp(),
          'isOriginalFavorited': false, // Newly saved translation starts as not favorited
          'isTranslatedFavorited': false, // Newly saved translation starts as not favorited
          'type': 'text', // Assuming text type for now
        });
        // Store the newly created document ID
        _currentTranslationDocId = docRef.id;
      } catch (e) {
        print('Error saving new translation to history: $e');
      }
    }
  }

  // --- NEW/UPDATED CORE LOGIC FOR FAVORITING ---
  Future<void> _toggleFavoriteStatus(bool isOriginal) async {
    final User? user = _auth.currentUser;

    // Ensure user is logged in and we have a document ID
    if (user == null || _currentTranslationDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in or save translation to favorite.')),
      );
      return;
    }

    // References to the documents in both collections
    final DocumentReference historyDocRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('translations')
        .doc(_currentTranslationDocId!);

    final DocumentReference favoriteDocRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(_currentTranslationDocId!); // Use the same ID for favorites

    // Determine the new favorite status based on which part is being toggled
    bool newOriginalFavoriteStatus = _isOriginalFavorited;
    bool newTranslatedFavoriteStatus = _isTranslatedFavorited;

    if (isOriginal) {
      newOriginalFavoriteStatus = !newOriginalFavoriteStatus;
    } else {
      newTranslatedFavoriteStatus = !newTranslatedFavoriteStatus;
    }

    // Use a batch write for atomicity: either all updates succeed or none do.
    WriteBatch batch = _firestore.batch();

    try {
      // 1. Update the favorite status in the HISTORY document
      batch.update(historyDocRef, {
        'isOriginalFavorited': newOriginalFavoriteStatus,
        'isTranslatedFavorited': newTranslatedFavoriteStatus,
      });

      // 2. Manage the FAVORITES document based on combined favorite status
      if (newOriginalFavoriteStatus || newTranslatedFavoriteStatus) {
        // If at least one part is now favorited, add/update in favorites collection
        // Merge ensures we don't overwrite if the document already exists
        batch.set(favoriteDocRef, {
          'originalText': widget.originalText,
          'translatedText': _translatedText, // Use the current translated text
          'fromLanguage': widget.fromLanguage,
          'toLanguage': widget.toLanguage,
          'timestamp': FieldValue.serverTimestamp(), // Update timestamp on favorite activity
          'isOriginalFavorited': newOriginalFavoriteStatus,
          'isTranslatedFavorited': newTranslatedFavoriteStatus,
          'type': 'text', // Assuming text type
        }, SetOptions(merge: true));
      } else {
        // If both original and translated are now unfavorited, delete from favorites collection
        batch.delete(favoriteDocRef);
      }

      // Commit the batch operations
      await batch.commit();

      // Update UI state only after successful Firestore operation
      setState(() {
        _isOriginalFavorited = newOriginalFavoriteStatus;
        _isTranslatedFavorited = newTranslatedFavoriteStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (newOriginalFavoriteStatus || newTranslatedFavoriteStatus)
                ? 'Added to favorites!'
                : 'Removed from favorites!',
          ),
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      // If batch fails, print error and show snackbar
      print('Error updating favorite status in Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite status: $e')),
      );
    }
  }

  Future<void> _fetchNewTranslationAndSaveHistory() async {
    setState(() {
      _isLoadingTranslation = true;
      _translatedText = '';
    });

    final fetchedText = await _fetchTranslation(widget.originalText);

    if (fetchedText.startsWith('Error')) {
      setState(() {
        _translatedText = fetchedText;
        _isLoadingTranslation = false;
      });
      return;
    }

    setState(() {
      _translatedText = fetchedText;
      _isLoadingTranslation = false;
    });

    // Save the new translation to history and get its ID
    await _saveNewTranslationHistory(widget.originalText, _translatedText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
          'Translation',
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TranslationCard(
                  language: widget.fromLanguage,
                  text: widget.originalText,
                  isFavorited: _isOriginalFavorited, // Use local state
                  onCopyPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.originalText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Original text copied to clipboard'),
                        duration: const Duration(milliseconds: 500),
                        backgroundColor: theme.colorScheme.secondary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onFavoritePressed: () async {
                    await _toggleFavoriteStatus(true); // Toggle original favorite
                  },
                ),
                const SizedBox(height: 16),
                _isLoadingTranslation
                    ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
                    : TranslationCard(
                  language: widget.toLanguage,
                  text: _translatedText,
                  isFavorited: _isTranslatedFavorited, // Use local state
                  onFavoritePressed: () async {
                    await _toggleFavoriteStatus(false); // Toggle translated favorite
                  },
                  onCopyPressed: () {
                    Clipboard.setData(ClipboardData(text: _translatedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Translated text copied to clipboard'),
                        duration: const Duration(milliseconds: 500),
                        backgroundColor: theme.colorScheme.secondary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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
      icon: const Icon(Icons.translate, color: Color(0xFF219EBC)),
      label: Text(
        'Translate More',
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, color: const Color(0xFF219EBC)),
      ),
    );
  }
}