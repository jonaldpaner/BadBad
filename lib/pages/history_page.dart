import 'package:flutter/material.dart';
import 'package:ahhhtest/components/history_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ahhhtest/pages/translation_page.dart'; // Import TranslationPage

class HistoryPageWidget extends StatefulWidget {
  const HistoryPageWidget({Key? key}) : super(key: key);

  static String routeName = 'history_page';
  static String routePath = '/historyPage';

  @override
  _HistoryPageWidgetState createState() => _HistoryPageWidgetState();
}

class _HistoryPageWidgetState extends State<HistoryPageWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _clearAllHistory() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to clear history.')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: const Text('CLEAR ALL'),
          content: const Text('Are you sure to clear all history? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('translations')
            .get();

        WriteBatch batch = _firestore.batch();
        for (DocumentSnapshot doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All history cleared!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear history: $e')),
        );
        print('Error clearing history: $e');
      }
    }
  }

  void _deleteHistoryItem(String documentId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to delete history items.')),
      );
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('translations')
          .doc(documentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History item deleted!'),
          duration: Duration(milliseconds: 500),
        ),
      );
      print('Document $documentId deleted from Firestore.');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete history item: $e')),
      );
      print('Error deleting document $documentId: $e');
    }
  }

  List<Widget> withSpacing(List<Widget> cards) {
    return [
      for (int i = 0; i < cards.length; i++) ...[
        cards[i],
        if (i != cards.length - 1) const SizedBox(height: 8),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
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
            'Recent History',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 60, color: theme.disabledColor),
              const SizedBox(height: 16),
              Text(
                'Please log in to view your history.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('translations')
          .orderBy('timestamp', descending: true)
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
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
                'Recent History',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 25),
                  color: theme.iconTheme.color,
                  onPressed: _clearAllHistory,
                  tooltip: 'Clear all history',
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 60, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'No translation history yet.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
                  ),
                ],
              ),
            ),
          );
        }

        final List<DocumentSnapshot> documents = snapshot.data!.docs;

        final Map<String, List<Widget>> groupedHistory = {
          'Today': [],
          'Yesterday': [],
          'Last Week': [],
          'Older': [],
        };

        final DateTime now = DateTime.now();
        final DateTime today = DateTime(now.year, now.month, now.day);
        final DateTime yesterday = today.subtract(const Duration(days: 1));
        final DateTime lastWeek = today.subtract(const Duration(days: 7));

        for (var doc in documents) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp timestamp = data['timestamp'] as Timestamp;
          final DateTime docDate = timestamp.toDate();
          final DateTime normalizedDocDate = DateTime(docDate.year, docDate.month, docDate.day);

          String groupKey;
          if (normalizedDocDate.isAtSameMomentAs(today)) {
            groupKey = 'Today';
          } else if (normalizedDocDate.isAtSameMomentAs(yesterday)) {
            groupKey = 'Yesterday';
          } else if (normalizedDocDate.isAfter(lastWeek)) {
            groupKey = 'Last Week';
          } else {
            groupKey = 'Older';
          }

          groupedHistory[groupKey]?.add(
            HistoryCardWidget(
              contentType: data['type'] ?? 'text',
              message: data['originalText'] ?? 'N/A',
              documentId: doc.id,
              onDelete: () => _deleteHistoryItem(doc.id),
              onTap: () { // ADDED: onTap to navigate to TranslationPage
                print('Attempting to navigate to TranslationPage for document: ${doc.id}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TranslationPage(
                      originalText: data['originalText'] ?? '',
                      fromLanguage: data['fromLanguage'] ?? 'English',
                      toLanguage: data['toLanguage'] ?? 'Ata Manobo',
                      initialTranslatedText: data['translatedText'] ?? '',
                    ),
                  ),
                );
              },
            ),
          );
        }

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
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
              'Recent History',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, size: 25),
                color: theme.iconTheme.color,
                onPressed: _clearAllHistory,
                tooltip: 'Clear all history',
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (groupedHistory['Today']!.isNotEmpty) ...[
                    Text(
                      'Today',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...withSpacing(groupedHistory['Today']!),
                    const SizedBox(height: 24),
                  ],
                  if (groupedHistory['Yesterday']!.isNotEmpty) ...[
                    Text(
                      'Yesterday',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...withSpacing(groupedHistory['Yesterday']!),
                    const SizedBox(height: 24),
                  ],
                  if (groupedHistory['Last Week']!.isNotEmpty) ...[
                    Text(
                      'Last Week',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...withSpacing(groupedHistory['Last Week']!),
                    const SizedBox(height: 24),
                  ],
                  if (groupedHistory['Older']!.isNotEmpty) ...[
                    Text(
                      'Older',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...withSpacing(groupedHistory['Older']!),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
