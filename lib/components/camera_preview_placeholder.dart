import 'package:flutter/material.dart';

class CameraPreviewPlaceholder extends StatelessWidget {
  const CameraPreviewPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? Colors.grey[850] : Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.camera_alt_outlined,
          size: 100,
          color: isDarkMode ? Colors.white54 : Colors.white70,
        ),
      ),
    );
  }
}
