import 'package:flutter/material.dart';
import 'package:ahhhtest/components/history_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADDED: Firestore import
import 'package:firebase_auth/firebase_auth.dart'; // ADDED: Auth import

class HistoryPageWidget extends StatefulWidget {
  const HistoryPageWidget({Key? key}) : super(key: key);

  static String routeName = 'history_page';
  static String routePath = '/historyPage';

  @override
  _HistoryPageWidgetState createState() => _HistoryPageWidgetState();
}

class _HistoryPageWidgetState extends State<HistoryPageWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // ADDED: Initialize Firestore and FirebaseAuth instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // MODIFIED: Clear all history logic to use Firestore
  void _clearAllHistory() async {
    final User? user = _auth.currentUser; // Now _auth is defined
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
      // Get all documents in the user's translations subcollection and delete them
      try {
        final QuerySnapshot snapshot = await _firestore // Now _firestore is defined
            .collection('users')
            .doc(user.uid)
            .collection('translations')
            .get();

        // Use a batch write for efficiency when deleting multiple documents
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

  // Helper function to add spacing between cards
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
    final User? user = _auth.currentUser; // Get current user here

    // ADDED: Display message if user is not logged in
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
              size: 30,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          title: const Text(
            'Recent History',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Please log in to view your history.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // ADDED: StreamBuilder to fetch data from Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('translations')
          .orderBy('timestamp', descending: true) // Order by timestamp (most recent first)
          .snapshots(), // Listen for real-time updates
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

        // If no data, show a message
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              title: const Text(
                'Recent History',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 30),
                  color: Colors.black,
                  onPressed: _clearAllHistory,
                  tooltip: 'Clear all history',
                ),
              ],
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No translation history yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Process fetched data
        final List<DocumentSnapshot> documents = snapshot.data!.docs;

        // Group history by date (Today, Yesterday, Last Week, etc.)
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
              contentType: data['type'] ?? 'text', // Default to 'text' if not specified
              message: data['originalText'] ?? 'N/A', // Display original text
              // You might want to pass more data if your HistoryCardWidget can use it
              // e.g., translatedText: data['translatedText']
              // You could also add onTap to navigate back to TranslationPage with the saved data
            ),
          );
        }

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
                size: 30,
              ),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
            title: const Text(
              'Recent History',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, size: 30),
                color: Colors.black,
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
                  // Only show sections if they have data
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
                  // If all sections are empty, and snapshot.data!.docs was not empty,
                  // it means maybe data is not grouped correctly, or there's some filter.
                  // But the initial empty check handles total emptiness.
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}