import 'package:flutter/material.dart';

class CameraPreviewPlaceholder extends StatelessWidget {
  const CameraPreviewPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.camera_alt_outlined,
          size: 100,
          color: Colors.white70,
        ),
      ),
    );
  }
}
