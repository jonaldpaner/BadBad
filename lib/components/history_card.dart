import 'package:flutter/material.dart';

class HistoryCardWidget extends StatelessWidget {
  final String contentType; // 'text', 'camera', or others (as per Firebase 'type' field)
  final String message; // This is intended to be the originalText from Firebase
  final String documentId; // To identify the document to delete
  final VoidCallback onDelete; // Callback for when delete is confirmed

  const HistoryCardWidget({
    Key? key,
    required this.contentType,
    required this.message, // Made required, as it comes from Firebase data
    required this.documentId,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Choose icon based on contentType (which directly comes from Firebase 'type' field)
    IconData leftIcon;
    if (contentType == 'camera') {
      leftIcon = Icons.camera_alt_outlined;
    } else if (contentType == 'text') { // FIXED: Changed 'type' to 'text' to match Firebase field
      leftIcon = Icons.textsms_outlined;
    } else {
      leftIcon = Icons.help_outline; // Default for unknown types
    }

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor, // dynamic card background
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Left Icon Button Container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.3), // dynamic circle bg
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  onPressed: () {
                    print('Left button pressed ...');
                  },
                  icon: Icon(leftIcon, size: 20),
                  color: theme.iconTheme.color, // dynamic icon color
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 12),

              // Message Text
              Expanded(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Right Icon Button Container
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.3), // dynamic bg
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  color: theme.iconTheme.color,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('DELETE'),
                        content: const Text('Confirm Delete'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ) ?? false;

                    if (confirmed) {
                      onDelete(); // CALL THE onDelete CALLBACK HERE
                      print('Item deleted from HistoryCardWidget'); // For debugging
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
