import 'package:flutter/material.dart';

class HistoryCardWidget extends StatelessWidget {
  final String contentType; // 'text', 'camera', or others (as per Firebase 'type' field)
  final String message; // This is intended to be the originalText from Firebase
  final String documentId; // To identify the document to delete
  final VoidCallback onDelete; // Callback for when delete is confirmed
  final VoidCallback? onTap; // Callback for when the main part of the card is tapped

  const HistoryCardWidget({
    Key? key,
    required this.contentType,
    required this.message,
    required this.documentId,
    required this.onDelete,
    this.onTap, // Make it optional
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Choose icon based on contentType (which directly comes from Firebase 'type' field)
    IconData leftIcon;
    if (contentType == 'camera') {
      leftIcon = Icons.camera_alt_outlined;
    } else if (contentType == 'text') {
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
        child: Row( // Use a Row as the direct child of the Container
          children: [
            // Tappable Area (Left Icon + Message Text)
            Expanded( // The Expanded widget ensures this section takes available space
              child: InkWell( // This InkWell makes the expanded area tappable
                onTap: () { // MODIFIED: Added print statement here
                  print('HistoryCardWidget tapped for document: $documentId');
                  if (onTap != null) {
                    onTap!();
                  }
                },
                borderRadius: BorderRadius.circular(20), // Match the outer container's border radius
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row( // Inner Row for the icon and text content
                    children: [
                      // Left Icon Button Container
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // This onPressed is for the icon itself, separate from card tap
                            print('Left icon button pressed in HistoryCardWidget for $documentId ...');
                          },
                          icon: Icon(leftIcon, size: 20),
                          color: theme.iconTheme.color,
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
                    ],
                  ),
                ),
              ),
            ),

            // Right Icon Button Container (for delete action - remains separate)
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                color: theme.iconTheme.color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: () async {
                  print('More options button pressed for $documentId ...'); // ADDED: Print for delete button
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
                    print('Item delete confirmed from HistoryCardWidget for $documentId');
                  } else {
                    print('Item delete cancelled for $documentId');
                  }
                },
              ),
            ),
            const SizedBox(width: 8), // Small space to the right of the delete button
          ],
        ),
      ),
    );
  }
}
