import 'package:flutter/material.dart';

class FavoritesCardWidget extends StatelessWidget {
  final String text;
  final String contentType; // ADDED: To determine the left icon (e.g., 'text', 'camera')
  final VoidCallback? onLeftPressed;
  final String documentId;
  final bool isOriginalTextFavorited;
  final Function(String documentId, bool isOriginal) onFavoriteRemoved;
  final VoidCallback? onTap;

  const FavoritesCardWidget({
    Key? key,
    required this.text,
    required this.contentType, // Required
    this.onLeftPressed,
    required this.documentId,
    required this.isOriginalTextFavorited,
    required this.onFavoriteRemoved,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final iconBgColor = theme.colorScheme.secondary;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    // Choose the left icon based on contentType
    IconData leftIcon;
    if (contentType == 'camera') {
      leftIcon = Icons.camera_alt_outlined;
    } else if (contentType == 'text') { // Match the Firebase 'type' field
      leftIcon = Icons.textsms_outlined;
    } else {
      leftIcon = Icons.help_outline; // Default icon for unknown types
    }

    return Padding(
      padding: const EdgeInsets.all(1), // Made const
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20), // Made const
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20), // Made const
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Made const
            child: Row(
              children: [
                // Left icon button (now dynamic)
                Container(
                  width: 40, // Made const
                  height: 40, // Made const
                  decoration: BoxDecoration(
                    color: iconBgColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50), // Made const
                  ),
                  child: IconButton(
                    onPressed: onLeftPressed,
                    icon: Icon(leftIcon, size: 20, color: theme.iconTheme.color), // Icon can't be const due to dynamic 'leftIcon' and theme color
                    padding: EdgeInsets.zero, // Made const
                  ),
                ),
                const SizedBox(width: 12), // Made const
                // Text message
                Expanded( // Made const
                  child: Text(
                    text,
                    maxLines: 1, // Made const
                    overflow: TextOverflow.ellipsis, // Made const
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.normal, // Made const
                      fontStyle: FontStyle.normal, // Made const
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Made const
                // Favorite button (handles confirmation)
                Container(
                  height: 40, // Made const
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), // Made const
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (alertDialogContext) => AlertDialog( // Changed parameter name to avoid conflict
                          title: const Text('REMOVE FAVORITE'), // Made const
                          content: const Text('Are you sure you want to remove this from favorites?'), // Made const
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(alertDialogContext).pop(false), // Use alertDialogContext
                              child: const Text('Cancel'), // Made const
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(alertDialogContext).pop(true), // Use alertDialogContext
                              child: const Text('Confirm'), // Made const
                            ),
                          ],
                        ),
                      ) ?? false;

                      if (confirmed) {
                        onFavoriteRemoved(documentId, isOriginalTextFavorited);
                        print('Favorite removal confirmed for document: $documentId');
                      }
                    },
                    icon: const Icon(Icons.favorite_rounded), // Made const
                    iconSize: 20, // Made const
                    color: theme.iconTheme.color,
                    padding: const EdgeInsets.symmetric(horizontal: 8), // Made const
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
