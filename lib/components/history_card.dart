import 'package:flutter/material.dart';

class HistoryCardWidget extends StatelessWidget {
  final String contentType; // 'type', 'camera', or others
  final String message;

  const HistoryCardWidget({
    Key? key,
    required this.contentType,
    this.message = 'Hello, how are you today?',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Choose icon based on contentType
    IconData leftIcon;
    if (contentType == 'camera') {
      leftIcon = Icons.camera_alt_outlined;
    } else if (contentType == 'type') {
      leftIcon = Icons.textsms_outlined;
    } else {
      leftIcon = Icons.help_outline;
    }

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.fromRGBO(230, 234, 237, 1),
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
                  color: Color.fromRGBO(204, 214, 218, 0.64),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  onPressed: () {
                    print('Left button pressed ...');
                  },
                  icon: Icon(leftIcon, size: 20),
                  color: theme.textTheme.bodyLarge?.color,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 12),
              // Message Text
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF14181B),
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Right Icon Button Container (like favorite button style)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(230, 234, 237, 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  color: theme.textTheme.bodyLarge?.color,
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
                      // Handle delete action here
                      print('Item deleted');
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
