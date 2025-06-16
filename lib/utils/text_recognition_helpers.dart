import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/text_box.dart'; // Assuming this defines TextBox with a 'rect' property

/// Determines if a given testPoint lies inside a polygon defined by a list of points.
/// Uses the winding number algorithm for robustness with complex polygons.
bool isPointInPolygon(List<Offset> points, Offset testPoint) {
  if (points.length < 3) return false;

  int windingNumber = 0;
  for (int i = 0; i < points.length; i++) {
    final p1 = points[i];
    final p2 = points[(i + 1) % points.length]; // Connects last point to first

    // Check if the ray from testPoint crosses the edge (p1, p2)
    if (p1.dy <= testPoint.dy) {
      if (p2.dy > testPoint.dy) { // An upward crossing
        if ((p2.dx - p1.dx) * (testPoint.dy - p1.dy) -
            (testPoint.dx - p1.dx) * (p2.dy - p1.dy) > 0) {
          windingNumber++;
        }
      }
    } else {
      if (p2.dy <= testPoint.dy) { // A downward crossing
        if ((p2.dx - p1.dx) * (testPoint.dy - p1.dy) -
            (testPoint.dx - p1.dx) * (p2.dy - p1.dy) < 0) {
          windingNumber--;
        }
      }
    }
  }
  return windingNumber != 0;
}

/// Converts local widget coordinates to the original image's coordinate system,
/// accounting for InteractiveViewer transformations and BoxFit.
Offset toOriginalImageCoordinates({
  required Offset localPos,
  required Size previewSize,
  required Size originalImageSize,
  required TransformationController transformationController,
  required BoxFit fit,
}) {
  // 1. Transform local widget coordinates to the InteractiveViewer's content coordinates
  final Matrix4 inverseInteractiveViewerMatrix = Matrix4.inverted(transformationController.value);
  final Offset posInInteractiveViewerContentCoords = MatrixUtils.transformPoint(inverseInteractiveViewerMatrix, localPos);

  // 2. Calculate the effective scale and offset applied by BoxFit
  double effectiveScale;
  double offsetX = 0.0;
  double offsetY = 0.0;

  final double originalAspectRatio = originalImageSize.width / originalImageSize.height;
  final double previewAspectRatio = previewSize.width / previewSize.height;

  switch (fit) {
    case BoxFit.contain:
      if (originalAspectRatio > previewAspectRatio) {
        effectiveScale = previewSize.width / originalImageSize.width;
        offsetY = (previewSize.height - originalImageSize.height * effectiveScale) / 2.0;
      } else {
        effectiveScale = previewSize.height / originalImageSize.height;
        offsetX = (previewSize.width - originalImageSize.width * effectiveScale) / 2.0;
      }
      break;
    case BoxFit.cover:
      if (originalAspectRatio < previewAspectRatio) {
        effectiveScale = previewSize.width / originalImageSize.width;
        offsetY = (previewSize.height - originalImageSize.height * effectiveScale) / 2.0;
      } else {
        effectiveScale = previewSize.height / originalImageSize.height;
        offsetX = (previewSize.width - originalImageSize.width * effectiveScale) / 2.0;
      }
      break;
    case BoxFit.fill:
    // BoxFit.fill stretches the image to fill the previewSize entirely
      effectiveScale = previewSize.width / originalImageSize.width; // Horizontal scale
      final double effectiveScaleY = previewSize.height / originalImageSize.height; // Vertical scale
      return Offset(
        (posInInteractiveViewerContentCoords.dx - offsetX) / effectiveScale,
        (posInInteractiveViewerContentCoords.dy - offsetY) / effectiveScaleY, // Use different scale for Y
      );
    case BoxFit.fitWidth:
      effectiveScale = previewSize.width / originalImageSize.width;
      offsetY = (previewSize.height - originalImageSize.height * effectiveScale) / 2.0;
      break;
    case BoxFit.fitHeight:
      effectiveScale = previewSize.height / originalImageSize.height;
      offsetX = (previewSize.width - originalImageSize.width * effectiveScale) / 2.0;
      break;
    case BoxFit.none:
    // No scaling, just positioning. Assumes top-left alignment by default.
      effectiveScale = 1.0;
      break;
    case BoxFit.scaleDown:
    // Scales down if image is larger than preview, otherwise no scaling.
      effectiveScale = min(
        1.0,
        min(
          previewSize.width / originalImageSize.width,
          previewSize.height / originalImageSize.height,
        ),
      );
      offsetX = (previewSize.width - originalImageSize.width * effectiveScale) / 2.0;
      offsetY = (previewSize.height - originalImageSize.height * effectiveScale) / 2.0;
      break;
    default:
    // Fallback for any unhandled BoxFit, treat as BoxFit.none
      effectiveScale = 1.0;
      offsetX = 0.0;
      offsetY = 0.0;
  }

  // 3. Apply the inverse of the BoxFit transformation
  return Offset(
    (posInInteractiveViewerContentCoords.dx - offsetX) / effectiveScale,
    (posInInteractiveViewerContentCoords.dy - offsetY) / effectiveScale,
  );
}

/// Helper to compare lists for setState optimization.
/// Uses `IterableExtension` for a potentially more concise implementation.
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == b) return true;
  if (a == null || b == null || a.length != b.length) return false;

  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}


List<List<TextBox>> groupWordsByLine(
    List<TextBox> words, {
      double verticalTolerance = 0.5, // Percentage of average word height for vertical grouping
      double maxLineHeightDeviation = 0.3, // Max deviation for word height within a line
      double? averageWordHeight,
    }) {
  if (words.isEmpty) return [];

  // Calculate an initial average word height if not provided
  final double avgHeight = averageWordHeight ?? words.map((w) => w.rect.height).reduce((a, b) => a + b) / words.length;
  final double effectiveVerticalThreshold = avgHeight * verticalTolerance;

  // Create a copy and sort words primarily by vertical position, then horizontal
  final sortedWords = List<TextBox>.from(words);
  sortedWords.sort((a, b) {
    // Sort by the vertical center of the word for better line alignment
    int yCompare = a.rect.center.dy.compareTo(b.rect.center.dy);
    if (yCompare != 0) return yCompare;
    return a.rect.left.compareTo(b.rect.left);
  });

  List<List<TextBox>> lines = [];

  for (final word in sortedWords) {
    bool added = false;
    for (final line in lines) {
      // Calculate the current line's vertical center based on its words
      final double lineCenterY = line.map((w) => w.rect.center.dy).reduce((a, b) => a + b) / line.length;
      final double lineAvgHeight = line.map((w) => w.rect.height).reduce((a, b) => a + b) / line.length;

      // Check vertical proximity and height consistency
      if ((word.rect.center.dy - lineCenterY).abs() <= effectiveVerticalThreshold &&
          (word.rect.height - lineAvgHeight).abs() <= lineAvgHeight * maxLineHeightDeviation) {
        line.add(word);
        added = true;
        break;
      }
    }
    if (!added) {
      lines.add([word]);
    }
  }

  // Sort words within each line horizontally
  for (final line in lines) {
    line.sort((a, b) => a.rect.left.compareTo(b.rect.left));
  }


  return lines;
}

// --- New Utility Functions ---

/// Calculates the center of a list of points (e.g., a polygon).
Offset calculateCentroid(List<Offset> points) {
  if (points.isEmpty) return Offset.zero;
  double sumX = 0;
  double sumY = 0;
  for (final p in points) {
    sumX += p.dx;
    sumY += p.dy;
  }
  return Offset(sumX / points.length, sumY / points.length);
}

/// Calculates the bounding box (Rect) of a list of points.
Rect calculateBoundingRect(List<Offset> points) {
  if (points.isEmpty) return Rect.zero;
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;

  for (final p in points) {
    minX = min(minX, p.dx);
    minY = min(minY, p.dy);
    maxX = max(maxX, p.dx);
    maxY = max(maxY, p.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

/// Transforms a list of Offset points by a given Matrix4.
List<Offset> transformPoints(List<Offset> points, Matrix4 matrix) {
  return points.map((p) => MatrixUtils.transformPoint(matrix, p)).toList();
}

/// Helper function to create a Rect from corner points (e.g., a rotated bounding box).
/// Assumes corner points are ordered, e.g., top-left, top-right, bottom-right, bottom-left.
/// This is a simplified version; for true rotated bounding boxes, more complex geometry might be needed.
Rect rectFromCornerPoints(List<Offset> cornerPoints) {
  if (cornerPoints.length < 2) return Rect.zero;
  double minX = cornerPoints.first.dx;
  double minY = cornerPoints.first.dy;
  double maxX = cornerPoints.first.dx;
  double maxY = cornerPoints.first.dy;

  for (final p in cornerPoints) {
    minX = min(minX, p.dx);
    minY = min(minY, p.dy);
    maxX = max(maxX, p.dx);
    maxY = max(maxY, p.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}