import 'package:flutter/material.dart'; // For Rect, Offset

/// Represents a detected text box (either a line or a word) from ML Kit recognition.
class TextBox {
  final Rect rect; // The axis-aligned bounding box from ML Kit
  final List<Offset> cornerPoints; // The 4 corner points (quadrilateral) from ML Kit
  final String text; // The recognized text within this bounding box
  final bool isWord; // True if this TextBox represents a single word, false if it's a line

  TextBox(this.rect, this.text, this.cornerPoints, {this.isWord = true})
      : assert(cornerPoints.length == 4, 'cornerPoints must have exactly 4 points');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TextBox &&
              runtimeType == other.runtimeType &&
              rect == other.rect &&
              text == other.text;

  @override
  int get hashCode => rect.hashCode ^ text.hashCode;
}
