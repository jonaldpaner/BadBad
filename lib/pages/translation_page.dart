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
  bool isOriginalFavorited = false;
  bool isTranslatedFavorited = false;

  String? _currentTranslationDocId;
  String _translatedText = '';
  bool _isLoadingTranslation = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          'isOriginalFavorited': isOriginalFavorited,
          'isTranslatedFavorited': isTranslatedFavorited,
          'type': 'text',
        });
        _currentTranslationDocId = docRef.id;
      } catch (e) {
        print('Error saving translation: $e');
      }
    }
  }

  Future<bool> _updateFavoriteStatusInFirestore(String fieldName, bool value) async {
    final User? user = _auth.currentUser;

    if (user != null && _currentTranslationDocId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('translations')
            .doc(_currentTranslationDocId!)
            .update({fieldName: value});
        return true;
      } catch (e) {
        print('Error updating $fieldName: $e');
        return false;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _currentTranslationDocId = widget.documentId;
    isOriginalFavorited = widget.initialIsOriginalFavorited ?? false;
    isTranslatedFavorited = widget.initialIsTranslatedFavorited ?? false;

    if (widget.initialTranslatedText != null && widget.initialTranslatedText!.isNotEmpty) {
      _translatedText = widget.initialTranslatedText!;
      _isLoadingTranslation = false;
    } else {
      _fetchNewTranslationAndSaveHistory();
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
                  onFavoritePressed: () async {
                    final prev = isOriginalFavorited;
                    setState(() => isOriginalFavorited = !prev);
                    final success = await _updateFavoriteStatusInFirestore('isOriginalFavorited', !prev);
                    if (!success) {
                      setState(() => isOriginalFavorited = prev);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update favorite')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _isLoadingTranslation
                    ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
                    : TranslationCard(
                  language: widget.toLanguage,
                  text: _translatedText,
                  onFavoritePressed: null,
                  isFavorited: false,
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
