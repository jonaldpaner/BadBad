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
      padding: const EdgeInsets.all(1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Left icon button (now dynamic)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: IconButton(
                    onPressed: onLeftPressed,
                    icon: Icon(leftIcon, size: 20, color: theme.iconTheme.color), // Use dynamic icon
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                // Text message
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Favorite button (handles confirmation)
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('REMOVE FAVORITE'),
                          content: const Text('Are you sure you want to remove this from favorites?'),
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
                        onFavoriteRemoved(documentId, isOriginalTextFavorited);
                        print('Favorite removal confirmed for document: $documentId');
                      }
                    },
                    icon: const Icon(Icons.favorite_rounded),
                    iconSize: 20,
                    color: theme.iconTheme.color,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
