import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' hide TextBox;

import '../utils/bounding_box_painter.dart';
import '../utils/text_recognition_helpers.dart' as TextRecognitionHelpers;
import '../models/text_box.dart';
import '../components/camera_preview_placeholder.dart';

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
  final Rect? currentSelectionRect;
  final void Function(ScaleStartDetails)? onCameraScaleStart;
  final Future<void> Function(double)? onCameraScaleUpdate;
  final void Function(Offset, Size)? onTapUp;

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
    this.currentSelectionRect,
    this.onCameraScaleStart,
    this.onCameraScaleUpdate,
    this.onTapUp,
    required this.onPreviewSizeAndContextChanged,
  });

  @override
  @override
  Widget build(BuildContext context) {
    if (capturedImageFile != null) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              capturedImageFile!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onPreviewSizeAndContextChanged(
                    Size(constraints.maxWidth, constraints.maxHeight),
                    context,
                  );
                });
                final previewSize = Size(constraints.maxWidth, constraints.maxHeight); // Get previewSize here

                return GestureDetector(
                  onTapUp: (d) => onTapUp?.call(d.localPosition, previewSize), // Pass previewSize
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: BoundingBoxPainter(
                      textBoxes,
                      originalImageSize,
                      previewSize, // Pass the calculated previewSize
                      selectedWords: selectedWords,
                      fit: BoxFit.cover,
                      selectionRect: currentSelectionRect,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      // Live camera view: remains the same with GestureDetector for zoom
      return GestureDetector(
        onScaleStart: (details) => onCameraScaleStart?.call(details),
        onScaleUpdate: (s) async {
          if (onCameraScaleUpdate != null) {
            await onCameraScaleUpdate!(s.scale);
          }
        },
        child: isCameraInitialized && cameraController != null && cameraController!.value.isInitialized
            ? CameraPreview(cameraController!)
            : const CameraPreviewPlaceholder(),
      );
    }
  }}