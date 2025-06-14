import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/text_box.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<TextBox> boxes; // Kept in constructor for now, but not used for painting general boxes
  final Size originalSize;
  final Size previewSize;
  final List<TextBox> selectedWords;
  final BoxFit fit;
  final Rect? selectionRect; // This parameter is no longer used for painting the red box

  BoundingBoxPainter(
      this.boxes, // This parameter is still accepted but its data is not used for general boxes
      this.originalSize,
      this.previewSize, {
        this.selectedWords = const [],
        this.fit = BoxFit.contain,
        this.selectionRect,
      });

  // --- Scaling Helpers ---

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
    // Paint for individual selected words
    final Paint selectedWordPaint = Paint()
      ..color = Colors.blue.withOpacity(0.4) // Semi-transparent blue
      ..style = PaintingStyle.fill; // Fill the shape

    // The paints for the overall selection rectangle (red box) are removed as requested.
    // final Paint selectionRectFillPaint = Paint()
    //   ..color = Colors.red.withOpacity(0.3) // Semi-transparent red fill
    //   ..style = PaintingStyle.fill;

    // final Paint selectionRectBorderPaint = Paint()
    //   ..color = Colors.red // Red border
    //   ..style = PaintingStyle.stroke // Stroke (outline)
    //   ..strokeWidth = 2.0; // 2 pixels thick

    // Draw individual selected word bounding boxes.
    // These are typically highlighted to show what's currently selected.
    for (final word in selectedWords) {
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

    // The drawing of the overall active drag selection area (the red box) is removed.
    // if (selectionRect != null) {
    //   canvas.drawRect(selectionRect!, selectionRectFillPaint);
    //   canvas.drawRect(selectionRect!, selectionRectBorderPaint);
    // }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter old) {
    // Repaint only if any of the relevant properties have changed,
    // ensuring efficient redrawing.
    return old.boxes != boxes ||
        old.originalSize != originalSize ||
        old.previewSize != previewSize ||
        old.selectedWords != selectedWords ||
        old.fit != fit ||
        old.selectionRect != selectionRect;
  }
}
