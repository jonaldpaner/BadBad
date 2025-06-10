import 'package:flutter/material.dart';
import 'dart:ui'; // Contains Size, Rect, Offset

class TextBox {
  final Rect rect; // The axis-aligned bounding box from ML Kit
  final List<Offset> cornerPoints; // The 4 corner points (quadrilateral) from ML Kit
  final String text; // The recognized text within this bounding box
  final bool isWord; // True if this TextBox represents a single word, false if it's a line

  TextBox(this.rect, this.text, this.cornerPoints, {this.isWord = true})
      : assert(cornerPoints.length == 4, 'cornerPoints must have exactly 4 points');

// Removed scaleRectTo and scaleCornerPointsTo as scaling logic is now handled
// by BoundingBoxPainter's static methods based on the BoxFit.
}

class BoundingBoxPainter extends CustomPainter {
  final List<TextBox> boxes; // All text boxes (lines and words) to be drawn
  final Size originalSize; // The original dimensions of the image where text was recognized
  final Size previewSize; // The current dimensions of the widget displaying the image/camera feed
  final List<TextBox> selectedWords; // The currently selected words to be highlighted
  final BoxFit fit; // <--- NEW: Added BoxFit parameter

  BoundingBoxPainter(this.boxes, this.originalSize, this.previewSize, {this.selectedWords = const [], this.fit = BoxFit.contain});

  // --- Static Helper Methods for Scaling (Re-usable by CameraPage for tap detection) ---

  /// Helper to calculate scaled points based on a given BoxFit.
  /// This accounts for potential cropping and offset when the image
  /// is displayed with a specific fit mode within a target area.
  static List<Offset> scalePointsForFit(List<Offset> points, Size original, Size display, BoxFit fit) {
    // Calculate scaling factors for width and height
    final double hRatio = display.width / original.width;
    final double vRatio = display.height / original.height;

    double scale;
    double offsetX = 0.0;
    double offsetY = 0.0;

    if (fit == BoxFit.contain) {
      // Image is scaled down to fit, maintaining aspect ratio.
      // Use the smaller ratio to ensure the entire image fits.
      scale = original.width / original.height > display.width / display.height
          ? display.width / original.width // Image is wider, scale based on width
          : display.height / original.height; // Image is taller, scale based on height
      offsetX = (display.width - original.width * scale) / 2.0;
      offsetY = (display.height - original.height * scale) / 2.0;
    } else if (fit == BoxFit.cover) {
      // Image is scaled to cover the display area, potentially cropping.
      // Use the larger ratio to ensure the display area is covered.
      scale = original.width / original.height < display.width / display.height // original aspect narrower than display
          ? display.width / original.width // scale to fit width (crop height)
          : display.height / original.height; // scale to fit height (crop width)
      offsetX = (display.width - original.width * scale) / 2.0;
      offsetY = (display.height - original.height * scale) / 2.0;
    } else {
      // Default behavior if an unhandled BoxFit is provided (e.g., BoxFit.fill)
      // For now, if it's not contain/cover, we won't apply specific scaling/offset.
      scale = 1.0;
      offsetX = 0.0;
      offsetY = 0.0;
    }

    // Apply the calculated scale and offset to each point
    return points.map((p) => Offset(p.dx * scale + offsetX, p.dy * scale + offsetY)).toList();
  }

  /// Helper to calculate scaled Rect based on a given BoxFit.
  /// Similar to scalePointsForFit, but for Rectangles.
  static Rect scaleRectForFit(Rect rect, Size original, Size display, BoxFit fit) {
    final double hRatio = display.width / original.width;
    final double vRatio = display.height / original.height;

    double scale;
    double offsetX = 0.0;
    double offsetY = 0.0;

    if (fit == BoxFit.contain) {
      scale = original.width / original.height > display.width / display.height
          ? display.width / original.width
          : display.height / original.height;
      offsetX = (display.width - original.width * scale) / 2.0;
      offsetY = (display.height - original.height * scale) / 2.0;
    } else if (fit == BoxFit.cover) {
      scale = original.width / original.height < display.width / display.height
          ? display.width / original.width
          : display.height / original.height;
      offsetX = (display.width - original.width * scale) / 2.0;
      offsetY = (display.height - original.height * scale) / 2.0;
    } else {
      scale = 1.0;
      offsetX = 0.0;
      offsetY = 0.0;
    }

    // Apply the calculated scale and offset to the rectangle's coordinates
    return Rect.fromLTRB(
      rect.left * scale + offsetX,
      rect.top * scale + offsetY,
      rect.right * scale + offsetX,
      rect.bottom * scale + offsetY,
    );
  }

  // --- CustomPainter Overrides ---

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final selectedPaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Draw bounding boxes for full lines of text (where isWord is false)
    for (final b in boxes.where((b) => !b.isWord)) {
      if (b.cornerPoints.length == 4) { // Ensure it's a valid quadrilateral
        // Use the static helper to scale points
        final scaledPoints = BoundingBoxPainter.scalePointsForFit(b.cornerPoints, originalSize, previewSize, fit);
        final path = Path();
        path.moveTo(scaledPoints[0].dx, scaledPoints[0].dy);
        for (var i = 1; i < scaledPoints.length; i++) {
          path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
        }
        path.close(); // Close the path to form a polygon
        canvas.drawPath(path, linePaint);
      } else {
        // Fallback to axis-aligned rect if corner points are not 4 (shouldn't happen for valid ML Kit results)
        final r = BoundingBoxPainter.scaleRectForFit(b.rect, originalSize, previewSize, fit);
        canvas.drawRect(r, linePaint);
      }
    }

    // Draw bounding boxes for selected individual words
    for (final w in selectedWords) {
      if (w.cornerPoints.length == 4) { // Ensure it's a valid quadrilateral
        // Use the static helper to scale points
        final scaledPoints = BoundingBoxPainter.scalePointsForFit(w.cornerPoints, originalSize, previewSize, fit);
        final path = Path();
        path.moveTo(scaledPoints[0].dx, scaledPoints[0].dy);
        for (var i = 1; i < scaledPoints.length; i++) {
          path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
        }
        path.close(); // Close the path to form a polygon
        canvas.drawPath(path, selectedPaint);
      } else {
        // Fallback to axis-aligned rect if corner points are not 4
        final r = BoundingBoxPainter.scaleRectForFit(w.rect, originalSize, previewSize, fit);
        canvas.drawRect(r, selectedPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes ||
        oldDelegate.originalSize != originalSize ||
        oldDelegate.previewSize != previewSize ||
        oldDelegate.selectedWords != selectedWords ||
        oldDelegate.fit != fit; // Include 'fit' in the repaint check
  }
}