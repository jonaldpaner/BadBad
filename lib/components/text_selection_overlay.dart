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
    this.rightHandleWord,
    required this.onHandlePanStartLeft,
    required this.onHandlePanStartRight,
    required this.onHandlePanUpdate,
    required this.onHandlePanEnd,
    required this.onTranslate,
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
    required Rect overallTransformedScaledRect,
    required Offset? draggingScreenPosition,
    required TextBox? specificLeftHandleWord,
    required TextBox? specificRightHandleWord,
    required Size originalImageSize,
    required Size previewSize,
    required TransformationController transformationController,
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

      if (targetWord != null) {
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
          visualAnchorX = _DragHandleShapePainter._CONTAINER_WIDTH / 2 + 12;
        } else {
          targetScreenX = transformedWordRect.bottomRight.dx;
          targetScreenY = transformedWordRect.bottomRight.dy;
          visualAnchorX = _DragHandleShapePainter._CONTAINER_WIDTH / 2 - 12;
        }
      } else {
        if (isLeftHandle) {
          targetScreenX = overallTransformedScaledRect.bottomLeft.dx;
          targetScreenY = overallTransformedScaledRect.bottomLeft.dy;
          visualAnchorX = _DragHandleShapePainter._CONTAINER_WIDTH / 2 + 12;
        } else {
          targetScreenX = overallTransformedScaledRect.bottomRight.dx;
          targetScreenY = overallTransformedScaledRect.bottomRight.dy;
          visualAnchorX = _DragHandleShapePainter._CONTAINER_WIDTH / 2 - 12.0;
        }
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
    if (selectedWords.isEmpty || capturedImageFile == null || previewSize == null) {
      return const SizedBox.shrink();
    }

    final combinedRect = selectedWords.fold<Rect?>(
      null,
          (rect, word) => rect == null ? word.rect : rect.expandToInclude(word.rect),
    )!;

    final scaledRect = BoundingBoxPainter.scaleRectForFit(
      combinedRect,
      originalImageSize,
      previewSize!,
      BoxFit.cover,
    );

    final matrix = transformationController.value;
    final transformedAndScaledRect = Rect.fromPoints(
      MatrixUtils.transformPoint(matrix, scaledRect.topLeft),
      MatrixUtils.transformPoint(matrix, scaledRect.bottomRight),
    );

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

    final double translateButtonApproxHeight = 40.0;
    final double verticalPadding = 15.0;

    double topPositionAbove = transformedAndScaledRect.top - translateButtonApproxHeight - verticalPadding;

    final double appBarAndStatusBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final double topThreshold = appBarAndStatusBarHeight + 10.0;

    double actionBarTop;

    final double handleOverlapHeight = _DragHandleShapePainter._CIRCLE_RADIUS;
    final double handleClearance = handleOverlapHeight + 5.0;

    if (topPositionAbove < topThreshold) {
      actionBarTop = transformedAndScaledRect.bottom + verticalPadding + handleClearance;

      final double screenHeight = MediaQuery.of(context).size.height;
      if (actionBarTop + translateButtonApproxHeight > screenHeight - 10.0) {
        actionBarTop = screenHeight - translateButtonApproxHeight - 10.0;
      }
    } else {
      actionBarTop = topPositionAbove;
    }

    double actionBarLeft = transformedAndScaledRect.left + transformedAndScaledRect.width / 2 - 60;

    actionBarLeft = max(0.0, actionBarLeft);
    actionBarLeft = min(MediaQuery.of(context).size.width - 120, actionBarLeft);

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
        if (currentDraggingHandleScreenPosition == null)
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