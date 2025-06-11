import 'dart:io'; // Added for File class
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' hide TextBox; // Hid TextBox from dart:ui to avoid conflict with custom TextBox

import '../utils/bounding_box_painter.dart';
import '../utils/text_recognition_helpers.dart' as TextRecognitionHelpers;
import '../models/text_box.dart'; // Explicitly import your custom TextBox model
import '../components/camera_preview_placeholder.dart'; // Import CameraPreviewPlaceholder

// Define a type for the callback that provides the preview size and context
typedef OnPreviewSizeAndContextChanged = void Function(Size size, BuildContext context);

class CameraDisplayArea extends StatelessWidget {
  final bool isCameraInitialized;
  final File? capturedImageFile;
  final CameraController? cameraController;
  final TransformationController transformationController;
  final List<TextBox> textBoxes;
  final Size originalImageSize;
  final List<TextBox> selectedWords;
  final Rect? currentSelectionRect; // Will be null as per our current design, kept for BoundingBoxPainter signature
  final VoidCallback? onCameraScaleStart;
  final Future<void> Function(double)? onCameraScaleUpdate;
  final void Function(Offset, Size)? onTapUp;
  // REMOVED: onPanStart, onPanUpdate, onPanEnd are no longer parameters here

  final OnPreviewSizeAndContextChanged onPreviewSizeAndContextChanged;


  const CameraDisplayArea({
    super.key,
    required this.isCameraInitialized,
    this.capturedImageFile,
    this.cameraController,
    required this.transformationController,
    required this.textBoxes,
    required this.originalImageSize,
    required this.selectedWords,
    this.currentSelectionRect, // Still in constructor for BoundingBoxPainter compatibility
    this.onCameraScaleStart,
    this.onCameraScaleUpdate,
    this.onTapUp,
    // REMOVED: onPanStart, onPanUpdate, onPanEnd from constructor
    required this.onPreviewSizeAndContextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: isCameraInitialized
          ? (capturedImageFile != null
          ? InteractiveViewer(
        transformationController: transformationController,
        minScale: 1.0,
        maxScale: 4.0, // Adjust max zoom as needed
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(
                capturedImageFile!,
                fit: BoxFit.cover, // Image fills the available space
                alignment: Alignment.center,
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Call the callback to pass previewSize and context back to parent
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onPreviewSizeAndContextChanged(
                      Size(constraints.maxWidth, constraints.maxHeight),
                      context,
                    );
                  });

                  return GestureDetector(
                    onTapUp: (d) => onTapUp?.call(d.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                    // REMOVED: onPanStart, onPanUpdate, onPanEnd listeners from here
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: BoundingBoxPainter(
                        textBoxes,
                        originalImageSize,
                        Size(constraints.maxWidth, constraints.maxHeight), // Pass directly
                        selectedWords: selectedWords,
                        fit: BoxFit.cover,
                        selectionRect: currentSelectionRect, // Still pass null to painter
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      )
          : GestureDetector( // Live camera view, only zoom on camera
        onScaleStart: (_) => onCameraScaleStart?.call(),
        onScaleUpdate: (s) async {
          if (onCameraScaleUpdate != null) {
            await onCameraScaleUpdate!(s.scale);
          }
        },
        child: cameraController != null
            ? CameraPreview(cameraController!)
            : const CameraPreviewPlaceholder(), // Use CameraPreviewPlaceholder here
      ))
          : const CameraPreviewPlaceholder(), // Use CameraPreviewPlaceholder here for initial camera loading
    );
  }
}
