import 'package:flutter/material.dart';

import '../components/capture_button.dart';
import '../components/icon_action_button.dart';

class CameraControlBar extends StatelessWidget {
  final bool hasCapturedImage;
  final bool isFromGallery;
  final bool isFlashOn;
  final VoidCallback onPickImage;
  final VoidCallback onCapture;
  final VoidCallback onToggleFlash;

  const CameraControlBar({
    super.key,
    required this.hasCapturedImage,
    required this.isFromGallery,
    required this.isFlashOn,
    required this.onPickImage,
    required this.onCapture,
    required this.onToggleFlash,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // Get size here if needed for sizing buttons

    return Positioned(
      bottom: 24,
      left: 32,
      right: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!hasCapturedImage || isFromGallery)
            IconActionButton(
              icon: Icons.photo_library_outlined,
              size: size.width * 0.07,
              onTap: onPickImage,
            ),
          if (!hasCapturedImage)
            CaptureButton(onTap: onCapture),
          if (!hasCapturedImage)
            IconActionButton(
              icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
              size: size.width * 0.07,
              onTap: onToggleFlash,
            ),
          if (hasCapturedImage) // Placeholder to maintain alignment if buttons are conditionally hidden
            SizedBox(width: size.width * 0.07 * 2),
        ],
      ),
    );
  }
}
