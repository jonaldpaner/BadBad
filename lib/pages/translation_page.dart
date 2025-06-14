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
  final String? initialTranslatedText; // ADDED: Optional parameter for pre-existing translation

  const TranslationPage({
    Key? key,
    required this.originalText,
    required this.fromLanguage,
    required this.toLanguage,
    this.initialTranslatedText,
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Asynchronous function to fetch translation from the API
  Future<String> _fetchTranslation(String message) async {
    // Determine the API endpoint based on the fromLanguage
    String? apiEndpoint;
    if (widget.fromLanguage == 'Ata Manobo') {
      apiEndpoint = 'ata';
    } else if (widget.fromLanguage == 'English') {
      apiEndpoint = 'eng';
    } else {
      return 'Unsupported language for translation.';
    }

    try {
      final encodedMessage = Uri.encodeComponent(message); // Encode the message for the URL
      final url = Uri.parse('https://badbad-api.onrender.com/translate/$apiEndpoint?message=$encodedMessage');
      print('Fetching translation from URL: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['translation']?.toString() ?? 'Translation not found.';
      } else {
        print('Failed to load translation: ${response.statusCode}, Body: ${response.body}');
        return 'Error: Could not translate (Status Code: ${response.statusCode})';
      }
    } catch (e) {
      print('Error fetching translation: $e');
      return 'Error: Could not translate (Network Error)';
    }
  }

  // Method to save translation history to Firestore and get the document ID
  Future<void> _saveNewTranslationHistory(String originalText, String translatedText) async {
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
        print('New translation history saved to Firestore. Doc ID: $_currentTranslationDocId');
      } catch (e) {
        print('Error saving new translation history to Firestore: $e');
      }
    } else {
      print('User not logged in. New translation history not saved to Firestore.');
    }
  }

  // Method to update the favorite status in Firestore for the current displayed translation
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
    print('TranslationPage: initState called.');
    print('TranslationPage: originalText received: "${widget.originalText}"');
    print('TranslationPage: initialTranslatedText received: "${widget.initialTranslatedText}"');

    if (widget.initialTranslatedText != null && widget.initialTranslatedText!.isNotEmpty) {
      _translatedText = widget.initialTranslatedText!;
      _isLoadingTranslation = false;
      print('TranslationPage: Displaying initial translated text from history.');
    } else {
      print('TranslationPage: No initial translated text, fetching new translation from API.');
      _fetchNewTranslationAndSaveHistory();
    }
  }

  // Orchestrates fetching translation and saving history for NEW translations
  Future<void> _fetchNewTranslationAndSaveHistory() async {
    setState(() {
      _isLoadingTranslation = true;
      _translatedText = '';
    });

    final fetchedText = await _fetchTranslation(widget.originalText);

    setState(() {
      _translatedText = fetchedText;
      _isLoadingTranslation = false;
    });

    await _saveNewTranslationHistory(widget.originalText, _translatedText);
  }

  @override
  Widget build(BuildContext context) {
    print('TranslationPage: build method called. Current translated text: "${_translatedText}"');
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.iconTheme.color, size: 25),
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
                // Removed the temporary Text widget
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
                        backgroundColor: theme.colorScheme.secondary,
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
                _isLoadingTranslation
                    ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
                    : TranslationCard(
                  language: widget.toLanguage,
                  text: _translatedText,
                  isFavorited: isTranslatedFavorited,
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
      icon: Icon(Icons.translate,color: Color(0xFF219EBC)),
      label: Text(
        'Translate More',
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, color: const Color(0xFF219EBC)),
      ),
    );
  }
}
