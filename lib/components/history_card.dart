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
      padding: const EdgeInsets.all(1), // Made const
      child: Container(
        width: double.infinity, // Made const
        decoration: BoxDecoration(
          color: theme.cardColor, // dynamic card background
          borderRadius: BorderRadius.circular(20), // Made const
        ),
        child: Row( // Use a Row as the direct child of the Container
          children: [
            // Tappable Area (Left Icon + Message Text)
            Expanded( // The Expanded widget ensures this section takes available space
              child: InkWell( // This InkWell makes the expanded area tappable
                onTap: () {
                  print('HistoryCardWidget tapped for document: $documentId');
                  if (onTap != null) {
                    onTap!();
                  }
                },
                borderRadius: BorderRadius.circular(20), // Match the outer container's border radius
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Made const
                  child: Row( // Inner Row for the icon and text content
                    children: [
                      // Left Icon Button Container
                      Container(
                        width: 40, // Made const
                        height: 40, // Made const
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(50), // Made const
                        ),
                        child: IconButton(
                          onPressed: () {
                            // This onPressed is for the icon itself, separate from card tap
                            print('Left icon button pressed in HistoryCardWidget for $documentId ...');
                          },
                          icon: Icon(leftIcon, size: 20), // Icon can't be const due to dynamic 'leftIcon' and theme color
                          color: theme.iconTheme.color,
                          padding: EdgeInsets.zero, // Made const
                        ),
                      ),
                      const SizedBox(width: 12), // Made const

                      // Message Text
                      Expanded( // Made const
                        child: Text(
                          message,
                          maxLines: 1, // Made const
                          overflow: TextOverflow.ellipsis, // Made const
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 16, // Made const
                            fontWeight: FontWeight.normal, // Made const
                            fontStyle: FontStyle.normal, // Made const
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
              height: 40, // Made const
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), // Made const
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outlined, size: 20), // Made const
                color: theme.iconTheme.color,
                padding: const EdgeInsets.symmetric(horizontal: 8), // Made const
                onPressed: () async {
                  print('More options button pressed for $documentId ...');
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (alertDialogContext) => AlertDialog( // Changed parameter name to avoid conflict
                      title: const Text('DELETE'), // Made const
                      content: const Text('Confirm Delete'), // Made const
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(alertDialogContext).pop(false),
                          child: const Text('Cancel'), // Made const
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF219EBC), // Made const
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(alertDialogContext).pop(true),
                          child: const Text('Confirm'), // Made const
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF219EBC), // Made const
                          ),
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
            const SizedBox(width: 8), // Made const // Small space to the right of the delete button
          ],
        ),
      ),
    );
  }
}
