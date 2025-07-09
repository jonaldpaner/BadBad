import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ahhhtest/components/translation_card.dart';
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
  final String? documentId;

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
  bool _isOriginalFavorited = false;
  bool _isTranslatedFavorited = false;

  String? _currentTranslationDocId;
  String _translatedText = '';
  bool _isLoadingTranslation = true; // Keep this state

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _currentTranslationDocId = widget.documentId;
    _isOriginalFavorited = widget.initialIsOriginalFavorited ?? false;
    _isTranslatedFavorited = widget.initialIsTranslatedFavorited ?? false;

    if (widget.initialTranslatedText != null && widget.initialTranslatedText!.isNotEmpty) {
      _translatedText = widget.initialTranslatedText!;
      _isLoadingTranslation = false; // Not loading if initial text is provided
    } else {
      _fetchNewTranslationAndSaveHistory();
    }
  }

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
      final url = Uri.parse('http://127.0.0.1:5000/translate/$apiEndpoint?message=$encodedMessage');
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
          'isOriginalFavorited': false,
          'isTranslatedFavorited': false,
          'type': 'text',
        });
        _currentTranslationDocId = docRef.id;
      } catch (e) {
        print('Error saving new translation to history: $e');
      }
    }
  }

  Future<void> _toggleFavoriteStatus(bool isOriginal) async {
    final User? user = _auth.currentUser;

    if (user == null || _currentTranslationDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in or save translation to favorite.'),
          duration: const Duration(milliseconds: 500),),
      );
      return;
    }

    final DocumentReference historyDocRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('translations')
        .doc(_currentTranslationDocId!);

    final DocumentReference favoriteDocRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(_currentTranslationDocId!);

    bool newOriginalFavoriteStatus = _isOriginalFavorited;
    bool newTranslatedFavoriteStatus = _isTranslatedFavorited;

    if (isOriginal) {
      newOriginalFavoriteStatus = !newOriginalFavoriteStatus;
    } else {
      newTranslatedFavoriteStatus = !newTranslatedFavoriteStatus;
    }

    WriteBatch batch = _firestore.batch();

    try {
      batch.update(historyDocRef, {
        'isOriginalFavorited': newOriginalFavoriteStatus,
        'isTranslatedFavorited': newTranslatedFavoriteStatus,
      });

      if (newOriginalFavoriteStatus || newTranslatedFavoriteStatus) {
        batch.set(favoriteDocRef, {
          'originalText': widget.originalText,
          'translatedText': _translatedText,
          'fromLanguage': widget.fromLanguage,
          'toLanguage': widget.toLanguage,
          'timestamp': FieldValue.serverTimestamp(),
          'isOriginalFavorited': newOriginalFavoriteStatus,
          'isTranslatedFavorited': newTranslatedFavoriteStatus,
          'type': 'text',
        }, SetOptions(merge: true));
      } else {
        batch.delete(favoriteDocRef);
      }

      await batch.commit();

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
      print('Error updating favorite status in Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite status: $e'),
          duration: const Duration(milliseconds: 500),),
      );
    }
  }

  Future<void> _fetchNewTranslationAndSaveHistory() async {
    setState(() {
      _isLoadingTranslation = true; // Set loading to true
      _translatedText = ''; // Clear previous text
    });

    final fetchedText = await _fetchTranslation(widget.originalText);

    setState(() {
      _translatedText = fetchedText;
      _isLoadingTranslation = false; // Set loading to false once done
    });

    if (!fetchedText.startsWith('Error')) {
      await _saveNewTranslationHistory(widget.originalText, _translatedText);
    }
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
                  isFavorited: _isOriginalFavorited,
                  onCopyPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.originalText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Original text copied to clipboard'),
                        duration: const Duration(milliseconds: 500),
                      ),
                    );
                  },
                  onFavoritePressed: () async {
                    await _toggleFavoriteStatus(true);
                  },
                  // No isLoading for the original card as it's always available
                ),
                const SizedBox(height: 16),
                TranslationCard(
                  language: widget.toLanguage,
                  text: _translatedText,
                  isFavorited: _isTranslatedFavorited,
                  onFavoritePressed: () async {
                    // Only allow favoriting if not loading and text is valid
                    if (!_isLoadingTranslation && !_translatedText.startsWith('Error')) {
                      await _toggleFavoriteStatus(false);
                    } else if (_isLoadingTranslation) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please wait for the translation to complete.'),
                          duration: const Duration(milliseconds: 500),),
                      );
                    } else if (_translatedText.startsWith('Error')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot favorite an erroneous translation.'),
                          duration: const Duration(milliseconds: 500),),
                      );
                    }
                  },
                  onCopyPressed: () {
                    // Only allow copying if not loading and text is valid
                    if (!_isLoadingTranslation && !_translatedText.startsWith('Error')) {
                      Clipboard.setData(ClipboardData(text: _translatedText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Translated text copied to clipboard'),
                          duration: const Duration(milliseconds: 500),
                        ),
                      );
                    } else if (_isLoadingTranslation) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please wait for the translation to complete.'),
                          duration: const Duration(milliseconds: 500),),
                      );
                    } else if (_translatedText.startsWith('Error')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot copy an erroneous translation.'),
                          duration: const Duration(milliseconds: 500),),
                      );
                    }
                  },
                  isLoading: _isLoadingTranslation, // Pass the loading state here!
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