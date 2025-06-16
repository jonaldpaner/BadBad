import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:io';

import '../models/text_box.dart';
import '../utils/bounding_box_painter.dart';

// Private CustomPainter class for the drag handle shapes
class _DragHandleShapePainter extends CustomPainter {
  static const double _CIRCLE_RADIUS = 20;
  static const double _HANDLE_HEIGHT = 50; // This is the height of the main tear-drop body
  static const double _CONTAINER_WIDTH = 40; // The total width of the SizedBox for the painter
  static const double _CONTAINER_HEIGHT = 140; // The total height of the SizedBox for the painter

  final bool isLeftHandle;

  const _DragHandleShapePainter({required this.isLeftHandle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    final Path path = Path();

    // The 'center' here refers to the center of the rounded base of the teardrop
    final Offset center = Offset(size.width / 2, size.height - _CIRCLE_RADIUS);
    final double topY = center.dy - _HANDLE_HEIGHT;

    // Apply inward rotation transformations
    canvas.save();

    // Move pivot to the center of the overall SizedBox for rotation
    canvas.translate(size.width / 2, size.height / 1.15);

    // Apply slight rotation: inward tilt
    final double tiltAngle = isLeftHandle ? pi / 5 : -pi / 5; // ~15 degrees
    canvas.rotate(tiltAngle);

    // Move back after rotating
    canvas.translate(-size.width / 2, -size.height / 2);

    // Draw the teardrop shape
    path.moveTo(center.dx, topY); // Start from the pointed top

    // Left curve (from top to bottom-left of rounded part)
    path.quadraticBezierTo(
      center.dx - 20, // Control point X
      topY + 20,      // Control point Y
      center.dx - 10, // End point X (top-left of rounded part)
      center.dy - _CIRCLE_RADIUS, // End point Y
    );

    // Bottom arc (rounded part)
    path.arcToPoint(
      Offset(center.dx + 10, center.dy - _CIRCLE_RADIUS), // End point of arc (top-right of rounded part)
      radius: Radius.circular(_CIRCLE_RADIUS),
      clockwise: false, // Draw counter-clockwise to form bottom arc
    );

    // Right curve (from bottom-right of rounded part back to top)
    path.quadraticBezierTo(
      center.dx + 20, // Control point X
      topY + 20,      // Control point Y
      center.dx,      // End point X (back to pointed top)
      topY,           // End point Y
    );

    path.close(); // Close the path to form a solid shape

    // Draw with shadow
    canvas.drawShadow(path, Colors.black, 2, true); // The `true` makes it a softer, more blurred shadow
    canvas.drawPath(path, paint);
    canvas.restore(); // Restore the canvas to its state before transformations
  }

  @override
  bool shouldRepaint(_DragHandleShapePainter oldDelegate) =>
      oldDelegate.isLeftHandle != isLeftHandle; // Repaint only if handle type changes
}


class TextSelectionOverlay extends StatelessWidget {
  final List<TextBox> selectedWords;
  final File? capturedImageFile;
  final Size? previewSize;
  final Size originalImageSize;
  final TransformationController transformationController;
  final TextBox? fixedAnchorWord;
  final bool isDraggingLeftHandleCurrent;
  final Rect? transformedFixedAnchorRect;
  final Offset? currentDraggingHandleScreenPosition;
  final TextBox? leftHandleWord; // New: Explicit word for the left handle
  final TextBox? rightHandleWord; // New: Explicit word for the right handle
  final void Function(DragStartDetails) onHandlePanStartLeft;
  final void Function(DragStartDetails) onHandlePanStartRight;
  final void Function(DragUpdateDetails) onHandlePanUpdate;
  final void Function(DragEndDetails) onHandlePanEnd;
  final void Function(String) onTranslate;

  const TextSelectionOverlay({
    super.key,
    required this.selectedWords,
    this.capturedImageFile,
    this.previewSize,
    required this.originalImageSize,
    required this.transformationController,
    this.fixedAnchorWord,
    required this.isDraggingLeftHandleCurrent,
    this.transformedFixedAnchorRect,
    this.currentDraggingHandleScreenPosition,
    this.leftHandleWord, // Initialize the new properties
    this.rightHandleWord, // Initialize the new properties
    required this.onHandlePanStartLeft,
    required this.onHandlePanStartRight,
    required this.onHandlePanUpdate,
    required this.onHandlePanEnd,
    required this.onTranslate,
  });

  // Helper method to get the handle widget using CustomPaint
  Widget _dragHandle(bool isLeft) => SizedBox(
    width: _DragHandleShapePainter._CONTAINER_WIDTH,
    height: _DragHandleShapePainter._CONTAINER_HEIGHT,
    child: CustomPaint(
      painter: _DragHandleShapePainter(isLeftHandle: isLeft), // Use const constructor
    ),
  );

  /// Calculates the top-left offset for positioning the handle's SizedBox.
  /// The goal is to align the center of the handle's rounded base with the target point (bounding box corner or drag position).
  Offset _calculateHandlePosition({
    required bool isLeftHandle,
    required Rect overallTransformedScaledRect, // The combined scaled and transformed rect (fallback)
    required Offset? draggingScreenPosition, // The current position of the finger when dragging
    required TextBox? specificLeftHandleWord, // The actual word for the left handle (when not dragging)
    required TextBox? specificRightHandleWord, // The actual word for the right handle (when not dragging)
    required Size originalImageSize,
    required Size previewSize,
    required TransformationController transformationController,
  }) {
    // Get the internal coordinates of the handle's visual anchor point
    // This is the center of the rounded base of the teardrop, relative to the SizedBox's top-left (0,0)
    final double visualAnchorX = _DragHandleShapePainter._CONTAINER_WIDTH / 2;
    final double visualAnchorY = _DragHandleShapePainter._CONTAINER_HEIGHT - _DragHandleShapePainter._CIRCLE_RADIUS;

    double targetScreenX;
    double targetScreenY;

    if (draggingScreenPosition != null) {
      // If actively dragging, the handle's visual anchor point should follow the finger's current position.
      targetScreenX = draggingScreenPosition.dx;
      targetScreenY = draggingScreenPosition.dy;
    } else {
      // If not dragging, position the handle based on the explicit handle words.
      final TextBox? targetWord = isLeftHandle ? specificLeftHandleWord : specificRightHandleWord;

      if (targetWord != null) {
        // Scale and transform the specific handle word's bounding box
        final scaledWordRect = BoundingBoxPainter.scaleRectForFit(
          targetWord.rect,
          originalImageSize,
          previewSize,
          BoxFit.cover,
        );
        final transformedWordRect = MatrixUtils.transformRect(transformationController.value, scaledWordRect);

        if (isLeftHandle) {
          targetScreenX = transformedWordRect.bottomLeft.dx;
          targetScreenY = transformedWordRect.bottomLeft.dy;
        } else {
          targetScreenX = transformedWordRect.bottomRight.dx;
          targetScreenY = transformedWordRect.bottomRight.dy;
        }
      } else {
        // Fallback: If no specific handle word is set (e.g., initial state without selection),
        // use the corners of the overall selection rectangle.
        if (isLeftHandle) {
          targetScreenX = overallTransformedScaledRect.bottomLeft.dx;
          targetScreenY = overallTransformedScaledRect.bottomLeft.dy;
        } else {
          targetScreenX = overallTransformedScaledRect.bottomRight.dx;
          targetScreenY = overallTransformedScaledRect.bottomRight.dy;
        }
      }
    }

    // Calculate the top-left position (Offset) of the SizedBox for the Positioned widget.
    // This shifts the SizedBox so that its internal `visualAnchorX, visualAnchorY` point
    // is placed at the `targetScreenX, targetScreenY` on the screen.
    return Offset(
      targetScreenX - visualAnchorX,
      targetScreenY - visualAnchorY,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedWords.isEmpty || capturedImageFile == null || previewSize == null) {
      return const SizedBox.shrink();
    }

    // Calculate the combined bounding box of selected words
    // using fold to handle the first element.
    final combinedRect = selectedWords.fold<Rect?>(
      null,
          (rect, word) => rect == null ? word.rect : rect.expandToInclude(word.rect),
    )!; // The '!' asserts that combinedRect will not be null here.

    // Scale the combined bounding box to fit the preview area.
    final scaledRect = BoundingBoxPainter.scaleRectForFit(
      combinedRect,
      originalImageSize,
      previewSize!,
      BoxFit.cover,
    );

    // Apply the InteractiveViewer's transformations (zoom/pan) to the scaled rectangle.
    final matrix = transformationController.value;
    final transformedAndScaledRect = Rect.fromPoints(
      MatrixUtils.transformPoint(matrix, scaledRect.topLeft),
      MatrixUtils.transformPoint(matrix, scaledRect.bottomRight),
    );

    // Calculate positions for both handles using the helper method.
    final leftHandlePos = _calculateHandlePosition(
      isLeftHandle: true,
      overallTransformedScaledRect: transformedAndScaledRect,
      draggingScreenPosition: isDraggingLeftHandleCurrent ? currentDraggingHandleScreenPosition : null,
      specificLeftHandleWord: leftHandleWord,
      specificRightHandleWord: rightHandleWord,
      originalImageSize: originalImageSize,
      previewSize: previewSize!,
      transformationController: transformationController,
    );
    final rightHandlePos = _calculateHandlePosition(
      isLeftHandle: false,
      overallTransformedScaledRect: transformedAndScaledRect,
      draggingScreenPosition: !isDraggingLeftHandleCurrent ? currentDraggingHandleScreenPosition : null,
      specificLeftHandleWord: leftHandleWord,
      specificRightHandleWord: rightHandleWord,
      originalImageSize: originalImageSize,
      previewSize: previewSize!,
      transformationController: transformationController,
    );

    // --- Logic for Translate button positioning ---
    final double translateButtonApproxHeight = 40.0; // A safe estimate for button height
    final double verticalPadding = 15.0; // Padding between the button and the selected text

    // 1. Calculate position if placed ABOVE the selected text
    double topPositionAbove = transformedAndScaledRect.top - translateButtonApproxHeight - verticalPadding;

    // Determine the AppBar's actual height (status bar + toolbar)
    final double appBarAndStatusBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    // Define a threshold: if the button's top would be above this, move it below the selection
    final double topThreshold = appBarAndStatusBarHeight + 10.0; // 10.0 for a small margin below AppBar

    double actionBarTop; // The final Y position for the button

    // ***** IMPORTANT CHANGE HERE *****
    // Calculate the total visual height of the handle that extends BELOW its anchor point.
    // The handle's base is anchored at the bottom corner of the text box.
    // The handle's total height is _CONTAINER_HEIGHT, and its visual anchor is visualAnchorY.
    // So, the portion extending below is _CONTAINER_HEIGHT - visualAnchorY.
    // From _DragHandleShapePainter: visualAnchorY = _CONTAINER_HEIGHT - _CIRCLE_RADIUS
    // So, portion below = _CONTAINER_HEIGHT - (_CONTAINER_HEIGHT - _CIRCLE_RADIUS) = _CIRCLE_RADIUS
    final double handleOverlapHeight = _DragHandleShapePainter._CIRCLE_RADIUS; // This is the rounded part of the handle
    final double handleClearance = handleOverlapHeight + 5.0; // Add a small buffer for visual spacing


    if (topPositionAbove < topThreshold) {
      // If placing it above would overlap AppBar or be too high, place it BELOW the selected text.
      // Adjust the `transformedAndScaledRect.bottom` by the height of the handle that extends downwards
      // to prevent overlap.
      actionBarTop = transformedAndScaledRect.bottom + verticalPadding + handleClearance;


      // Ensure it doesn't go off the very bottom of the screen
      final double screenHeight = MediaQuery.of(context).size.height;
      if (actionBarTop + translateButtonApproxHeight > screenHeight - 10.0) { // Keep 10px from bottom edge
        actionBarTop = screenHeight - translateButtonApproxHeight - 10.0; // Clamp to bottom
      }

    } else {
      // Otherwise, place it ABOVE the selected text.
      actionBarTop = topPositionAbove;
    }

    // Horizontal centering relative to the combined rectangle
    double actionBarLeft = transformedAndScaledRect.left + transformedAndScaledRect.width / 2 - 60; // 60 is half the button width (approx 120)

    // Ensure it doesn't go off-screen left/right
    actionBarLeft = max(0.0, actionBarLeft);
    actionBarLeft = min(MediaQuery.of(context).size.width - 120, actionBarLeft); // 120 is approx button width
    // --- End of logic for Translate button positioning ---


    return Stack(
      children: [
        // Left Drag Handle
        Positioned(
          left: leftHandlePos.dx,
          top: leftHandlePos.dy,
          child: GestureDetector(
            onPanStart: onHandlePanStartLeft,
            onPanUpdate: onHandlePanUpdate,
            onPanEnd: onHandlePanEnd,
            child: _dragHandle(true), // Pass true for left handle
          ),
        ),

        // Right Drag Handle
        Positioned(
          left: rightHandlePos.dx,
          top: rightHandlePos.dy,
          child: GestureDetector(
            onPanStart: onHandlePanStartRight,
            onPanUpdate: onHandlePanUpdate,
            onPanEnd: onHandlePanEnd,
            child: _dragHandle(false), // Pass false for right handle
          ),
        ),

        // Translate Button (positioned intelligently)
        // Only show the button when not actively dragging a handle
        if (currentDraggingHandleScreenPosition == null)
          Positioned(
            left: actionBarLeft,
            top: actionBarTop,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent, // Ensure transparent background
              child: GestureDetector(
                onTap: () {
                  final text = selectedWords.map((e) => e.text).join(' ');
                  onTranslate(text);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, // Use theme's card color
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Translate",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}