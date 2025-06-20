import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/text_box.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<TextBox> boxes;
  final Size originalSize;
  final Size previewSize;
  final List<TextBox> selectedWords;
  final BoxFit fit;
  final Rect? selectionRect; // This can remain, though its specific usage is for a combined highlight if desired

  BoundingBoxPainter(
      this.boxes,
      this.originalSize,
      this.previewSize, {
        this.selectedWords = const [],
        this.fit = BoxFit.contain,
        this.selectionRect,
      });

  // --- Scaling Helpers (No changes here) ---

  /// Scales a list of Offset points from original image coordinates to display coordinates.
  /// Accounts for the BoxFit property (contain or cover) to correctly map points.
  static List<Offset> scalePointsForFit(List<Offset> points, Size original, Size display, BoxFit fit) {
    // Calculate aspect ratios for both original image and display area
    final double originalAspectRatio = original.width / original.height;
    final double displayAspectRatio = display.width / display.height;

    double scale;
    double offsetX = 0.0; // Horizontal offset for centering
    double offsetY = 0.0; // Vertical offset for centering

    if (fit == BoxFit.contain) {
      // Scale down image to fit within display, maintaining aspect ratio.
      // Image will be fully visible, possibly with empty space (letterboxing).
      scale = originalAspectRatio > displayAspectRatio
          ? display.width / original.width // Image is wider, limited by display width
          : display.height / original.height; // Image is taller, limited by display height
      // Calculate offsets to center the scaled image
      offsetX = (display.width - original.width * scale) / 2.0;
      offsetY = (display.height - original.height * scale) / 2.0;
    } else if (fit == BoxFit.cover) {
      // Scale up image to cover the entire display, maintaining aspect ratio.
      // Parts of the image might be cropped (pillarboxing/letterboxing removal).
      scale = originalAspectRatio < displayAspectRatio
          ? display.width / original.width // Image is taller, limited by display width
          : display.height / original.height; // Image is wider, limited by display height
      // Calculate offsets to center the scaled image
      offsetX = (display.width - original.width * scale) / 2.0;
      offsetY = (display.height - original.height * scale) / 2.0;
    } else {
      // Default to no scaling if fit is not contain or cover (e.g., fill, none).
      // This case might need more specific logic depending on other BoxFit values.
      scale = 1.0;
    }

    // Apply scaling and offset to each point
    return points.map((p) => Offset(p.dx * scale + offsetX, p.dy * scale + offsetY)).toList();
  }

  /// Scales a Rect from original image coordinates to display coordinates.
  /// Accounts for the BoxFit property (contain or cover) to correctly map the rectangle.
  static Rect scaleRectForFit(Rect rect, Size original, Size display, BoxFit fit) {
    // Calculate aspect ratios for both original image and display area
    final double originalAspectRatio = original.width / original.height;
    final double displayAspectRatio = display.width / display.height;

    double scale;
    double offsetX = 0.0; // Horizontal offset for centering
    double offsetY = 0.0; // Vertical offset for centering

    if (fit == BoxFit.contain) {
      // Scale down image to fit within display, maintaining aspect ratio.
      scale = originalAspectRatio > displayAspectRatio
          ? display.width / original.width
          : display.height / original.height;
      // Calculate offsets to center the scaled image
      offsetX = (display.width - original.width * scale) / 2.0;
      offsetY = (display.height - original.height * scale) / 2.0;
    } else if (fit == BoxFit.cover) {
      // Scale up image to cover the entire display, maintaining aspect ratio.
      scale = originalAspectRatio < displayAspectRatio
          ? display.width / original.width
          : display.height / original.height;
      // Calculate offsets to center the scaled image
      offsetX = (display.width - original.width * scale) / 2.0;
      offsetY = (display.height - original.height * scale) / 2.0;
    } else {
      scale = 1.0;
    }

    // Apply scaling and offset to the rectangle's corners
    return Rect.fromLTRB(
      rect.left * scale + offsetX,
      rect.top * scale + offsetY,
      rect.right * scale + offsetX,
      rect.bottom * scale + offsetY,
    );
  }

  // --- Painting Logic ---

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the initial line bounding boxes (white, borderless)
    final Paint lineBoxPaint = Paint()
      ..color = Colors.white.withOpacity(0.3) // Slightly transparent white for background
      ..style = PaintingStyle.fill; // Filled

    // Paint for individual selected words (semi-transparent blue fill)
    final Paint selectedWordPaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // First, draw the initial white bounding boxes for lines
    for (final box in boxes) {
      if (!box.isWord) { // Only draw if it's a line (isWord: false)
        if (box.cornerPoints.length == 4) {
          // Draw polygon for lines if corner points are available
          final scaledPoints = scalePointsForFit(box.cornerPoints, originalSize, previewSize, fit);
          final path = Path()..moveTo(scaledPoints[0].dx, scaledPoints[0].dy);
          for (int i = 1; i < scaledPoints.length; i++) {
            path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
          }
          path.close();
          canvas.drawPath(path, lineBoxPaint);
        } else {
          // Fallback to drawing a rectangle for lines
          final rect = scaleRectForFit(box.rect, originalSize, previewSize, fit);
          canvas.drawRect(rect, lineBoxPaint);
        }
      }
    }

    // Second, draw the blue highlight for selected words, on top of everything else
    for (final word in selectedWords) {
      // We already know these are words, but adding isWord check for robustness if structure changes
      if (word.isWord) {
        if (word.cornerPoints.length == 4) {
          // Draw polygon for words if corner points are available
          final scaledPoints = scalePointsForFit(word.cornerPoints, originalSize, previewSize, fit);
          final path = Path()..moveTo(scaledPoints[0].dx, scaledPoints[0].dy);
          for (int i = 1; i < scaledPoints.length; i++) {
            path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
          }
          path.close();
          canvas.drawPath(path, selectedWordPaint);
        } else {
          // Fallback to drawing a rectangle for words
          final rect = scaleRectForFit(word.rect, originalSize, previewSize, fit);
          canvas.drawRect(rect, selectedWordPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter old) {
    // Repaint only if any of the relevant properties have changed,
    // ensuring efficient redrawing.
    return old.boxes != boxes || // Now considers all boxes for line drawing
        old.originalSize != originalSize ||
        old.previewSize != previewSize ||
        old.selectedWords != selectedWords ||
        old.fit != fit ||
        old.selectionRect != selectionRect;
  }
}