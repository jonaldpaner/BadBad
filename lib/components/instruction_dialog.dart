import 'package:flutter/material.dart';

class InstructionDialog extends StatelessWidget {
  const InstructionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextStyle? bodyTextStyle = theme.textTheme.bodyMedium;
    final Color? iconColor = theme.iconTheme.color;
    final double iconSize = (bodyTextStyle?.fontSize ?? 14) + 2;

    return AlertDialog(
      title: Text(
        'How to Use This App',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '1. Fixed Translation Direction: ', // Updated title
                    style: bodyTextStyle?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    // Clarified the fixed direction
                    text: 'This app translates from Ata Manobo to English.',
                    style: bodyTextStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '2. Enter Text: ', // Re-numbered
                    style: bodyTextStyle?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Type or paste the text you want to translate into the input box at the bottom of the screen.',
                    style: bodyTextStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // REMOVED: Instruction for "Toggle Languages"
            // It's no longer relevant since the language direction is fixed.
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '3. Use Camera: ', // Re-numbered
                    style: bodyTextStyle?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Tap the camera icon (',
                    style: bodyTextStyle,
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: iconSize,
                      color: iconColor,
                    ),
                  ),
                  TextSpan(
                    text: ') to translate text from an image using your device\'s camera.',
                    style: bodyTextStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '4. Translate: ', // Re-numbered
                    style: bodyTextStyle?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Press the "Translate" button to see the translation.',
                    style: bodyTextStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '5. Manage Account: ', // Re-numbered
                    style: bodyTextStyle?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Tap the profile icon (',
                    style: bodyTextStyle,
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.person_outline,
                      size: iconSize,
                      color: iconColor,
                    ),
                  ),
                  TextSpan(
                    text: ') to log in or create an account for more features.',
                    style: bodyTextStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '6. Navigation Drawer: ', // Re-numbered
                    style: bodyTextStyle?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Tap the menu icon (',
                    style: bodyTextStyle,
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.menu_rounded,
                      size: iconSize,
                      color: iconColor,
                    ),
                  ),
                  TextSpan(
                    text: ') to access favorites, history, and other options.',
                    style: bodyTextStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'Got It!',
            style: TextStyle(color: Color(0xFF219EBC)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}