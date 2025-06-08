import 'package:flutter/material.dart';

class CaptureButton extends StatelessWidget {
  final VoidCallback onTap;
  const CaptureButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.secondary.withOpacity(0.7),
          border: Border.all(color: theme.dividerColor, width: 2),
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
