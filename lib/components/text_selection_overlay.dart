import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:io';
import '../models/text_box.dart';
import '../utils/bounding_box_painter.dart';

class _DragHandleShapePainter extends CustomPainter {
  static const double _CIRCLE_RADIUS = 15;
  static const double _HANDLE_BODY_HEIGHT = 40;
  static const double _CONTAINER_WIDTH = 40;

  final bool isLeftHandle;
  final Offset containerPosition;
  final Size imageBounds;

  const _DragHandleShapePainter({
    required this.isLeftHandle,
    required this.containerPosition,
    required this.imageBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    final Path path = Path();

    final Offset center = Offset(size.width / 2, size.height - _CIRCLE_RADIUS);
    final double topY = center.dy - _HANDLE_BODY_HEIGHT;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    double tiltAngle = isLeftHandle ? pi / 10 : -pi / 10;

    final double handleSizedBoxLeftScreenX = containerPosition.dx;
    final double handleSizedBoxTopScreenY = containerPosition.dy;
    final double handleBaseCenterScreenX = handleSizedBoxLeftScreenX + size.width / 2;
    final double handleBaseCenterScreenY = handleSizedBoxTopScreenY + size.height - _CIRCLE_RADIUS;

    final double cornerToleranceX = 40.0;
    final double cornerToleranceY = 40.0;

    if (isLeftHandle) {
      if (handleBaseCenterScreenX < cornerToleranceX) {
        if (handleBaseCenterScreenY < cornerToleranceY) {
          tiltAngle = -pi / 4;
        } else if (handleBaseCenterScreenY > imageBounds.height - _CIRCLE_RADIUS - cornerToleranceY) {
          tiltAngle = pi / 4;
        } else {
          tiltAngle = pi / 12;
        }
      }
    } else {
      if (handleBaseCenterScreenX > imageBounds.width - cornerToleranceX) {
        if (handleBaseCenterScreenY < cornerToleranceY) {
          tiltAngle = pi / 4;
        } else if (handleBaseCenterScreenY > imageBounds.height - _CIRCLE_RADIUS - cornerToleranceY) {
          tiltAngle = -pi / 4;
        } else {
          tiltAngle = -pi / 12;
        }
      }
    }

    canvas.rotate(tiltAngle);

    canvas.translate(-center.dx, -center.dy);

    path.moveTo(center.dx, topY);

    path.quadraticBezierTo(
      center.dx - 20,
      topY + 20,
      center.dx - 10,
      center.dy - _CIRCLE_RADIUS,
    );

    path.arcToPoint(
      Offset(center.dx + 10, center.dy - _CIRCLE_RADIUS),
      radius: Radius.circular(_CIRCLE_RADIUS),
      clockwise: false,
    );

    path.quadraticBezierTo(
      center.dx + 20,
      topY + 20,
      center.dx,
      topY,
    );

    path.close();

    canvas.drawShadow(path, Colors.black, 2, true);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DragHandleShapePainter oldDelegate) =>
      oldDelegate.isLeftHandle != isLeftHandle ||
          oldDelegate.containerPosition != containerPosition ||
          oldDelegate.imageBounds != imageBounds;
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
  final TextBox? leftHandleWord;
  final TextBox? rightHandleWord;
  final void Function(DragStartDetails) onHandlePanStartLeft;
  final void Function(DragStartDetails) onHandlePanStartRight;
  final void Function(DragUpdateDetails) onHandlePanUpdate;
  final void Function(DragEndDetails) onHandlePanEnd;
  final void Function(String) onTranslate;
  final int maxTranslationCharacters;

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
    this.leftHandleWord,
    required this.rightHandleWord, // Ensure this is not null if used
    required this.onHandlePanStartLeft,
    required this.onHandlePanStartRight,
    required this.onHandlePanUpdate,
    required this.onHandlePanEnd,
    required this.onTranslate,
    required this.maxTranslationCharacters,
  });

  Widget _dragHandle(bool isLeft, Offset currentPosition) {
    final double desiredSizedBoxHeight =
        _DragHandleShapePainter._HANDLE_BODY_HEIGHT + _DragHandleShapePainter._CIRCLE_RADIUS;
    final double verticalPaddingAboveHandle = 10.0;
    final double totalSizedBoxHeight = desiredSizedBoxHeight + verticalPaddingAboveHandle;

    return SizedBox(
      width: _DragHandleShapePainter._CONTAINER_WIDTH,
      height: totalSizedBoxHeight,
      child: CustomPaint(
        painter: _DragHandleShapePainter(
          isLeftHandle: isLeft,
          containerPosition: currentPosition,
          imageBounds: previewSize!,
        ),
      ),
    );
  }

  Offset _calculateHandlePosition({
    required bool isLeftHandle,
    required List<TextBox> allSelectedWords, // New parameter to get words
    required Offset? draggingScreenPosition,
    required TextBox? specificLeftHandleWord,
    required TextBox? specificRightHandleWord,
    required Size originalImageSize,
    required Size previewSize,
    required TransformationController transformationController,
    required bool isCapturedImage,
  }) {
    double visualAnchorX;

    final double currentSizedBoxHeight =
        _DragHandleShapePainter._HANDLE_BODY_HEIGHT + _DragHandleShapePainter._CIRCLE_RADIUS + 10.0;

    final double handleBaseYInSizedBox = currentSizedBoxHeight - _DragHandleShapePainter._CIRCLE_RADIUS;
    final double verticalOffsetFromWordBottom = 38;

    double targetScreenX;
    double targetScreenY;

    if (draggingScreenPosition != null) {
      targetScreenX = draggingScreenPosition.dx;
      targetScreenY = draggingScreenPosition.dy;

      visualAnchorX = _DragHandleShapePainter._CONTAINER_WIDTH / 2;
    } else {
      final TextBox? targetWord = isLeftHandle ? specificLeftHandleWord : specificRightHandleWord;

      // Determine the point in original image coordinates to anchor the handle to
      Offset originalAnchorPoint;

      if (targetWord != null) {
        // Anchor to the specific word's bottom-left/right point
        if (isLeftHandle) {
          originalAnchorPoint = targetWord.rect.bottomLeft;
        } else {
          originalAnchorPoint = targetWord.rect.bottomRight;
        }
      } else {
        // Fallback: Anchor to the overall selection's bottom-left/right point
        // This calculates the combined rect if a specific word isn't available (e.g., empty selection initially)
        final combinedRect = allSelectedWords.fold<Rect?>(
          null,
              (rect, word) => rect == null ? word.rect : rect.expandToInclude(word.rect),
        )!; // ! is safe because this only runs if selectedWords is not empty

        if (isLeftHandle) {
          originalAnchorPoint = combinedRect.bottomLeft;
        } else {
          originalAnchorPoint = combinedRect.bottomRight;
        }
      }

      if (isCapturedImage) {
        // Manually apply BoxFit.cover transformation for captured images
        final FittedSizes fittedSizes = applyBoxFit(BoxFit.cover, originalImageSize, previewSize);
        final double scale = fittedSizes.destination.width / fittedSizes.source.width;
        final double offsetX = (previewSize.width - originalImageSize.width * scale) / 2;
        final double offsetY = (previewSize.height - originalImageSize.height * scale) / 2;

        targetScreenX = originalAnchorPoint.dx * scale + offsetX;
        targetScreenY = originalAnchorPoint.dy * scale + offsetY;
      } else {
        // For live camera or other cases, use the transformationController
        // First scale the point based on BoxFit.cover to the preview area
        final FittedSizes fittedSizes = applyBoxFit(BoxFit.cover, originalImageSize, previewSize);
        final double scale = fittedSizes.destination.width / fittedSizes.source.width;
        final double offsetX = (previewSize.width - originalImageSize.width * scale) / 2;
        final double offsetY = (previewSize.height - originalImageSize.height * scale) / 2;

        final Offset scaledPointPreTransform = Offset(
          originalAnchorPoint.dx * scale + offsetX,
          originalAnchorPoint.dy * scale + offsetY,
        );

        // Then apply the InteractiveViewer's transformation matrix
        final transformedPoint =
        MatrixUtils.transformPoint(transformationController.value, scaledPointPreTransform);
        targetScreenX = transformedPoint.dx;
        targetScreenY = transformedPoint.dy;
      }

      if (isLeftHandle) {
        visualAnchorX = _DragHandleShapePainter._CONTAINER_WIDTH / 2 + 12;
      } else {
        visualAnchorX = _DragHandleShapePainter._CONTAINER_WIDTH / 2 - 12;
      }
    }

    double rawHandleSizedBoxX = targetScreenX - visualAnchorX;
    double rawHandleSizedBoxY = targetScreenY - handleBaseYInSizedBox + verticalOffsetFromWordBottom;

    final double handleSizedBoxWidth = _DragHandleShapePainter._CONTAINER_WIDTH;
    final double handleSizedBoxHeight = currentSizedBoxHeight;

    final double clampedX = rawHandleSizedBoxX.clamp(0.0, previewSize.width - handleSizedBoxWidth);
    final double clampedY = rawHandleSizedBoxY.clamp(0.0, previewSize.height - handleSizedBoxHeight);

    return Offset(clampedX, clampedY);
  }

  @override
  Widget build(BuildContext context) {
    if (selectedWords.isEmpty || previewSize == null) {
      return const SizedBox.shrink();
    }

    final Rect combinedRectOriginal = selectedWords.fold<Rect?>(
      null,
          (rect, word) => rect == null ? word.rect : rect.expandToInclude(word.rect),
    )!;

    Rect transformedAndScaledRectForActionBar;

    if (capturedImageFile != null) {
      final FittedSizes fittedSizes = applyBoxFit(BoxFit.cover, originalImageSize, previewSize!);
      final double scale = fittedSizes.destination.width / fittedSizes.source.width;
      final double offsetX = (previewSize!.width - originalImageSize.width * scale) / 2;
      final double offsetY = (previewSize!.height - originalImageSize.height * scale) / 2;

      transformedAndScaledRectForActionBar = Rect.fromPoints(
        Offset(
            combinedRectOriginal.topLeft.dx * scale + offsetX,
            combinedRectOriginal.topLeft.dy * scale + offsetY),
        Offset(
            combinedRectOriginal.bottomRight.dx * scale + offsetX,
            combinedRectOriginal.bottomRight.dy * scale + offsetY),
      );
    } else {
      final scaledRectPreTransform = BoundingBoxPainter.scaleRectForFit(
        combinedRectOriginal,
        originalImageSize,
        previewSize!,
        BoxFit.cover,
      );
      transformedAndScaledRectForActionBar =
          MatrixUtils.transformRect(transformationController.value, scaledRectPreTransform);
    }

    final leftHandlePos = _calculateHandlePosition(
      isLeftHandle: true,
      allSelectedWords: selectedWords,
      draggingScreenPosition: isDraggingLeftHandleCurrent ? currentDraggingHandleScreenPosition : null,
      specificLeftHandleWord: leftHandleWord,
      specificRightHandleWord: rightHandleWord,
      originalImageSize: originalImageSize,
      previewSize: previewSize!,
      transformationController: transformationController,
      isCapturedImage: capturedImageFile != null,
    );
    final rightHandlePos = _calculateHandlePosition(
      isLeftHandle: false,
      allSelectedWords: selectedWords,
      draggingScreenPosition: !isDraggingLeftHandleCurrent ? currentDraggingHandleScreenPosition : null,
      specificLeftHandleWord: rightHandleWord, // Fixed: Should use rightHandleWord for right handle
      specificRightHandleWord: rightHandleWord, // Fixed: Should use rightHandleWord for right handle
      originalImageSize: originalImageSize,
      previewSize: previewSize!,
      transformationController: transformationController,
      isCapturedImage: capturedImageFile != null,
    );

    final double translateButtonApproxHeight = 40.0;
    final double verticalPadding = 15.0;

    double topPositionAbove = transformedAndScaledRectForActionBar.top - translateButtonApproxHeight - verticalPadding;

    final double appBarAndStatusBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final double topThreshold = appBarAndStatusBarHeight + 10.0;

    double actionBarTop;

    final double handleOverlapHeight = _DragHandleShapePainter._CIRCLE_RADIUS;
    final double handleClearance = handleOverlapHeight + 5.0;

    if (topPositionAbove < topThreshold) {
      actionBarTop = transformedAndScaledRectForActionBar.bottom + verticalPadding + handleClearance;

      final double screenHeight = MediaQuery.of(context).size.height;
      if (actionBarTop + translateButtonApproxHeight > screenHeight - 10.0) {
        actionBarTop = screenHeight - translateButtonApproxHeight - 10.0;
      }
    } else {
      actionBarTop = topPositionAbove;
    }

    double actionBarLeft = transformedAndScaledRectForActionBar.left + transformedAndScaledRectForActionBar.width / 2 - 70; // Adjusted for wider button
    actionBarLeft = max(0.0, actionBarLeft);
    actionBarLeft = min(MediaQuery.of(context).size.width - 140, actionBarLeft); // Adjusted for wider button

    final String selectedText = selectedWords.map((e) => e.text).join(' ');
    final int charCount = selectedText.length;
    final bool isOverLimit = charCount > maxTranslationCharacters;

    return Stack(
      children: [
        Positioned(
          left: leftHandlePos.dx,
          top: leftHandlePos.dy,
          child: GestureDetector(
            onPanStart: onHandlePanStartLeft,
            onPanUpdate: onHandlePanUpdate,
            onPanEnd: onHandlePanEnd,
            child: _dragHandle(true, leftHandlePos),
          ),
        ),
        Positioned(
          left: rightHandlePos.dx,
          top: rightHandlePos.dy,
          child: GestureDetector(
            onPanStart: onHandlePanStartRight,
            onPanUpdate: onHandlePanUpdate,
            onPanEnd: onHandlePanEnd,
            child: _dragHandle(false, rightHandlePos),
          ),
        ),
        // Removed the `if (currentDraggingHandleScreenPosition == null)` condition
        Positioned(
          left: actionBarLeft,
          top: actionBarTop,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(20),
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                final text = selectedWords.map((e) => e.text).join(' ');
                onTranslate(text);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Translate",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    if (selectedWords.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOverLimit ? Colors.red.withOpacity(0.8) : Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$charCount/$maxTranslationCharacters',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}