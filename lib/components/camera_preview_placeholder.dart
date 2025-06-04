import 'package:flutter/material.dart';

class CameraPreviewPlaceholder extends StatelessWidget {
  const CameraPreviewPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Text(
        'Camera Preview Area',
        style: TextStyle(fontSize: 20, color: Colors.grey),
      ),
    );
  }
}
