import 'package:flutter/material.dart';
import 'package:ahhhtest/components/history_card.dart';

class HistoryPageWidget extends StatefulWidget {
  const HistoryPageWidget({Key? key}) : super(key: key);

  static String routeName = 'history_page';
  static String routePath = '/historyPage';

  @override
  _HistoryPageWidgetState createState() => _HistoryPageWidgetState();
}

class _HistoryPageWidgetState extends State<HistoryPageWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void _clearAllHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: const Text('CLEAR ALL'),
          content: const Text('Are you sure to clear all history?'),
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
      // TODO: implement your clear history logic here
      print('All history cleared');
    }
  }

  // Helper function to add spacing between cards
  List<Widget> withSpacing(List<Widget> cards) {
    return [
      for (int i = 0; i < cards.length; i++) ...[
        cards[i],
        if (i != cards.length - 1) const SizedBox(height: 8), // space between cards
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Simulated dynamic data (replace with real filtered lists)
    final List<Widget> todayHistory = [
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Hello, how are you today?',
      ),
      const HistoryCardWidget(
        contentType: 'camera',
        message: 'Photo taken at 12:00 PM',
      ),
    ];

    final List<Widget> yesterdayHistory = [
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),

    ];

    final List<Widget> lastWeekHistory = [
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),
      const HistoryCardWidget(
        contentType: 'type',
        message: 'Did you finish the report?',
      ),


    ];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
        body: SafeArea( // <--- Change this line
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todayHistory.isNotEmpty) ...[
                  Text(
                    'Today',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...withSpacing(todayHistory),
                  const SizedBox(height: 24),
                ],
                if (yesterdayHistory.isNotEmpty) ...[
                  Text(
                    'Yesterday',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...withSpacing(yesterdayHistory),
                  const SizedBox(height: 24),
                ],
                if (lastWeekHistory.isNotEmpty) ...[
                  Text(
                    'Last Week',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...withSpacing(lastWeekHistory),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
