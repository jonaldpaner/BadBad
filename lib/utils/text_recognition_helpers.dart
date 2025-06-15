import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/text_box.dart';

bool isPointInPolygon(List<Offset> points, Offset testPoint) {
  if (points.length < 3) return false;

  bool inside = false;
  for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
    final pI = points[i];
    final pJ = points[j];

    if (((pI.dy <= testPoint.dy && testPoint.dy < pJ.dy) ||
        (pJ.dy <= testPoint.dy && testPoint.dy < pI.dy)) &&
        (testPoint.dx < (pJ.dx - pI.dx) * (testPoint.dy - pI.dy) / (pJ.dy - pI.dy) + pI.dx)) {
      inside = !inside;
    }
  }
  return inside;
}

Offset toOriginalImageCoordinates(
    Offset localPos,
    Size previewSize, // Corrected parameter name
    Size originalImageSize,
    TransformationController transformationController,
    BoxFit fit,
    ) {
  // 1. Transform local widget coordinates (relative to CustomPaint/InteractiveViewer viewport)
  //    to the coordinate system of the InteractiveViewer's content *before* any zoom/pan.
  final Matrix4 inverseInteractiveViewerMatrix = Matrix4.inverted(transformationController.value);
  final Offset posInInteractiveViewerContentCoords = MatrixUtils.transformPoint(inverseInteractiveViewerMatrix, localPos);

  // 2. Now, `posInInteractiveViewerContentCoords` is in the space of `previewSize`
  //    (the dimensions of the area where the image/painter is drawn after BoxFit.cover).
  //    We need to reverse the BoxFit.cover transformation to get it back to
  //    the `originalImageSize` coordinate system, where the 'b.cornerPoints' are.

  final double hRatio = previewSize.width / originalImageSize.width;
  final double vRatio = previewSize.height / originalImageSize.height;

  double coverScale;
  double offsetX = 0.0;
  double offsetY = 0.0;

  if (fit == BoxFit.contain) {
    coverScale = originalImageSize.width / originalImageSize.height > previewSize.width / previewSize.height
        ? previewSize.width / originalImageSize.width
        : previewSize.height / originalImageSize.height;
    offsetX = (previewSize.width - originalImageSize.width * coverScale) / 2.0;
    offsetY = (previewSize.height - originalImageSize.height * coverScale) / 2.0;
  } else if (fit == BoxFit.cover) {
    coverScale = originalImageSize.width / originalImageSize.height < previewSize.width / previewSize.height
        ? previewSize.width / originalImageSize.width
        : previewSize.height / originalImageSize.height;
    offsetX = (previewSize.width - originalImageSize.width * coverScale) / 2.0;
    offsetY = (previewSize.height - originalImageSize.height * coverScale) / 2.0;
  } else {
    // Default behavior if an unhandled BoxFit is provided (e.g., BoxFit.fill)
    coverScale = 1.0;
    offsetX = 0.0;
    offsetY = 0.0;
  }

  // 3. Apply the inverse of the BoxFit.cover transformation
  return Offset(
    (posInInteractiveViewerContentCoords.dx - offsetX) / coverScale,
    (posInInteractiveViewerContentCoords.dy - offsetY) / coverScale,
  );
}

/// Helper to compare lists for setState optimization.
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == b) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Groups a list of TextBox objects into lines based on their vertical proximity.
///
/// [words]: A list of TextBox objects representing individual words.
/// [lineThreshold]: The maximum vertical distance between words to consider them on the same line.
List<List<TextBox>> groupWordsByLine(List<TextBox> words, {double lineThreshold = 10.0}) {
  List<List<TextBox>> lines = [];

  // Create a copy and sort words primarily by vertical position, then horizontal to facilitate grouping
  final sortedWords = List<TextBox>.from(words);
  sortedWords.sort((a, b) {
    int yCompare = a.rect.top.compareTo(b.rect.top);
    if (yCompare != 0) return yCompare;
    return a.rect.left.compareTo(b.rect.left);
  });

  for (final word in sortedWords) {
    bool added = false;
    for (final line in lines) {
      // Check if word's vertical position is close enough to the existing line's average vertical position
      if ((line.first.rect.top - word.rect.top).abs() < lineThreshold) {
        line.add(word);
        added = true;
        break;
      }
    }
    if (!added) {
      lines.add([word]);
    }
  }

  // Ensure words within each line are sorted horizontally (already done by initial sort implicitly for line adds)
  for (final line in lines) {
    line.sort((a, b) => a.rect.left.compareTo(b.rect.left));
  }

  return lines;
}
