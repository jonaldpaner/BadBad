import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart' hide TextSelectionOverlay;
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import '../components/camera_display_area.dart';
import '../components/language_selector.dart';
import 'translation_page.dart';
import '../services/camera_service.dart';
import '../utils/bounding_box_painter.dart';
import '../models/text_box.dart';
import '../utils/text_recognition_helpers.dart' as TextRecognitionHelpers;
import '../components/camera_control_bar.dart';
import '../components/text_selection_overlay.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  bool _isCameraInitialized = false; // Controls CameraPreview visibility
  bool _isLoading = false;
  List<TextBox> _textBoxes = [];
  List<TextBox> _selectedWords = [];
  String _fromLanguage = 'English';
  String _toLanguage = 'Ata Manobo';
  double _currentZoom = 1, _minZoom = 1, _maxZoom = 1, _baseZoom = 1;
  File? _capturedImageFile;
  Size _originalImageSize = const Size(1280, 720); // Default placeholder size
  bool _hasCapturedImage = false; // Controls Image.file vs CameraPreview
  bool _isFromGallery = false;
  final TransformationController _transformationController =
  TransformationController();

  Size? _previewSize;
  BuildContext? _customPaintContext;

  TextBox? _fixedAnchorWord;
  bool _isDraggingLeftHandleCurrent = false;
  Offset? _currentDraggingHandleScreenPosition;

  TextBox? _leftHandleWord;
  TextBox? _rightHandleWord;

  static const double _verticalLineTolerance = 25.0; // Still a fixed pixel value for this page's usage

  @override
  void initState() {
    super.initState();
    _initCamera(); // Initialize camera on first load
  }

  Future<void> _initCamera() async {
    // Set loading state and ensure CameraPreview is not shown during initialization
    setState(() {
      _isLoading = true;
      _isCameraInitialized = false;
    });

    try {
      final cameras = await availableCameras();
      await _cameraService.initializeCamera(cameras);
      _minZoom = await _cameraService.getMinZoomLevel();
      _maxZoom = await _cameraService.getMaxZoomLevel();
      _currentZoom = _minZoom;
      await _cameraService.setZoomLevel(_currentZoom);
      // Only set true if initialization was successful
      setState(() {
        _isCameraInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      print("Failed to initialize camera: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing camera: ${e.toString()}')),
      );
      // Ensure it's false on error
      setState(() {
        _isCameraInitialized = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose(); // This disposes both camera and text recognizer
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    _resetSelectionState(
      shouldReinitializeCamera: false,
    ); // Clears data, but doesn't re-init camera yet

    // Immediately stop camera and update UI to show placeholder/loading
    setState(() {
      _isLoading = true;
      _isCameraInitialized = false; // Ensure CameraPreview is gone
    });
    await _cameraService.disposeCamera(); // Stop camera before opening gallery

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Process picked image
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      final origSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );

      final InputImage inputImage = InputImage.fromFile(file);
      final TextRecognizer recognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recog = await recognizer.processImage(inputImage);
      recognizer.close(); // Close temporary recognizer

      List<TextBox> detectedBoxes = [];
      for (var block in recog.blocks) {
        for (var line in block.lines) {
          // Add the whole line as a TextBox
          detectedBoxes.add(
            TextBox(
              line.boundingBox,
              line.text,
              line.cornerPoints
                  .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                  .toList(),
              isWord: false, // Mark as a line
            ),
          );
          for (var e in line.elements) {
            // Add individual words (elements) as TextBox
            if (RegExp(r'\w').hasMatch(e.text)) {
              // Basic word validation
              detectedBoxes.add(
                TextBox(
                  e.boundingBox,
                  e.text,
                  e.cornerPoints
                      .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                      .toList(),
                  isWord: true, // Mark as a word
                ),
              );
            }
          }
        }
      }

      setState(() {
        _capturedImageFile = file;
        _originalImageSize = origSize;
        _textBoxes = detectedBoxes;
        _hasCapturedImage = true;
        _isLoading = false;
        _isFromGallery = true;
        _transformationController.value =
            Matrix4.identity(); // Reset zoom/pan for new image
      });
    } else {
      // User cancelled gallery pick. Re-initialize camera.
      setState(() {
        _isLoading = false;
        _hasCapturedImage = false; // Go back to camera view
      });
      // Re-initialize the camera only if we didn't show an image
      await _initCamera();
    }
  }

  Future<void> _captureAndRecognizeText() async {
    _resetSelectionState(
      shouldReinitializeCamera: false,
    ); // Clear previous state, but don't re-init camera yet

    // Immediately update UI to show loading/placeholder while capture happens
    setState(() {
      _isLoading = true;
      _isCameraInitialized = false; // Ensure CameraPreview is gone
    });
    // Do NOT dispose camera here yet, it's needed for capture!

    try {
      final recog = await _cameraService.captureAndGetRecognizedText();
      final imagePath = _cameraService.lastCapturedImagePath;

      // Dispose camera AFTER successful capture
      await _cameraService.disposeCamera();

      if (recog != null && imagePath != null && mounted) {
        final file = File(imagePath);
        final bytes = await file.readAsBytes();
        final decodedImage = await decodeImageFromList(bytes);

        final origSize = Size(
          decodedImage.width.toDouble(),
          decodedImage.height.toDouble(),
        );

        List<TextBox> detectedBoxes = [];
        for (var block in recog.blocks) {
          for (var line in block.lines) {
            // Add the whole line as a TextBox
            detectedBoxes.add(
              TextBox(
                line.boundingBox,
                line.text,
                line.cornerPoints
                    .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                    .toList(),
                isWord: false, // Mark as a line
              ),
            );
            for (var e in line.elements) {
              // Add individual words (elements) as TextBox
              if (RegExp(r'\w').hasMatch(e.text)) {
                // Basic word validation
                detectedBoxes.add(
                  TextBox(
                    e.boundingBox,
                    e.text,
                    e.cornerPoints
                        .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                        .toList(),
                    isWord: true, // Mark as a word
                  ),
                );
              }
            }
          }
        }

        setState(() {
          _capturedImageFile = file;
          _originalImageSize = origSize;
          _textBoxes = detectedBoxes;
          _hasCapturedImage = true;
          _isLoading = false;
          _isFromGallery = false;
          _transformationController.value =
              Matrix4.identity(); // Reset zoom/pan for new image
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during capture: ${e.toString()}')),
      );
      // On error, if no image was captured, re-initialize camera
      setState(() {
        _isLoading = false;
        _hasCapturedImage = false; // Go back to camera view
      });
      await _initCamera(); // Re-initialize camera on capture error
    }
  }

  void _resetSelectionState({bool shouldReinitializeCamera = true}) {
    _textBoxes.clear();
    _selectedWords.clear();
    _capturedImageFile = null;
    _hasCapturedImage = false;
    _isFromGallery = false;
    _transformationController.value =
        Matrix4.identity(); // Always reset transformation
    _fixedAnchorWord = null;
    _isDraggingLeftHandleCurrent = false;
    _currentDraggingHandleScreenPosition = null;
    _leftHandleWord = null;
    _rightHandleWord = null;

    if (shouldReinitializeCamera) {
      _initCamera(); // This will handle setting _isCameraInitialized to true/false
    } else {
      // If we're not immediately re-initializing, ensure the camera is considered not initialized.
      // This is crucial to prevent CameraPreview from trying to render disposed controller.
      _isCameraInitialized = false;
    }
  }

  /// Handles tap events on the image to select words.
  void _onTapUp(Offset pos, Size previewSize) {
    if (!_hasCapturedImage) return;

    // Reset current selection state before finding new tap
    setState(() {
      _selectedWords.clear();
      _fixedAnchorWord = null;
      _isDraggingLeftHandleCurrent = false;
      _currentDraggingHandleScreenPosition = null;
      _leftHandleWord = null;
      _rightHandleWord = null;
    });

    final Offset tapInOriginalImageCoords =
    TextRecognitionHelpers.toOriginalImageCoordinates(
      localPos: pos,
      previewSize: previewSize,
      originalImageSize: _originalImageSize,
      transformationController: _transformationController,
      fit: BoxFit.cover, // Assumes BoxFit.cover is used for the image display
    );

    TextBox? tappedWord;
    for (final b in _textBoxes) {
      if (b.isWord) {
        // Only consider words for selection
        if (TextRecognitionHelpers.isPointInPolygon(
          b.cornerPoints,
          tapInOriginalImageCoords,
        )) {
          tappedWord = b;
          break; // Found the first word under the tap, stop searching
        }
      }
    }

    setState(() {
      if (tappedWord != null) {
        _selectedWords = [tappedWord];
        _leftHandleWord = tappedWord;
        _rightHandleWord = tappedWord;
      }
      // If tappedWord is null, _selectedWords remains empty (already cleared)
    });
  }

  /// Updates the selection based on dragging one of the handles.
  void _updateSelectionBasedOnHandleDrag(DragUpdateDetails details) {
    if (!_hasCapturedImage ||
        _previewSize == null ||
        _fixedAnchorWord == null ||
        _customPaintContext == null) {
      print(
          "UpdateSelection: Pre-conditions not met. fixedAnchorWord is null: ${_fixedAnchorWord == null}");
      return;
    }

    final RenderBox renderBox =
    _customPaintContext!.findRenderObject() as RenderBox;
    final Offset localPos = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _currentDraggingHandleScreenPosition = localPos;
    });

    final Offset currentDragPointInOriginalCoords =
    TextRecognitionHelpers.toOriginalImageCoordinates(
      localPos: localPos,
      previewSize: _previewSize!,
      originalImageSize: _originalImageSize,
      transformationController: _transformationController,
      fit: BoxFit.cover,
    );

    // Filter and sort only words, as lines are not meant for individual selection
    final allWordsSorted = _textBoxes.where((b) => b.isWord).toList()
      ..sort((a, b) {
        // Sort primarily by vertical center, then horizontal left
        int yCompare = a.rect.center.dy.compareTo(b.rect.center.dy);
        if (yCompare != 0) return yCompare;
        return a.rect.left.compareTo(b.rect.left);
      });

    // We're using _fixedAnchorWord directly, so ensure it's in the sorted list.
    // If it's not (e.g., filtered out or somehow missing), we should handle that.
    if (!allWordsSorted.contains(_fixedAnchorWord)) {
      print("Error: Fixed anchor word not found in the allWordsSorted list. This might indicate a data inconsistency.");
      return;
    }

    TextBox? newTargetWord;
    double minDistanceToPoint = double.infinity;

    // Determine the Y-range of the fixed anchor word to define its "line" or general vertical area
    final double fixedAnchorWordCenterY = _fixedAnchorWord!.rect.center.dy;

    for (final word in allWordsSorted) {
      // Calculate vertical distance from the word's center to the drag point
      final double verticalDistanceToDragPoint =
      (word.rect.center.dy - currentDragPointInOriginalCoords.dy).abs();

      // Calculate vertical distance from the word's center to the fixed anchor's line
      final double verticalDistanceToFixedAnchorLine =
      (word.rect.center.dy - fixedAnchorWordCenterY).abs();

      bool isVerticallyCloseToDragPoint =
          verticalDistanceToDragPoint < _verticalLineTolerance;
      bool isVerticallyCloseToFixedAnchor =
          verticalDistanceToFixedAnchorLine < _verticalLineTolerance;

      // The word must be vertically close to *either* the drag point OR the fixed anchor's line.
      // This allows the selection to extend onto new lines as the drag point moves,
      // but also keeps words on the same line as the anchor in consideration.
      if (isVerticallyCloseToDragPoint || isVerticallyCloseToFixedAnchor) {
        final Offset wordCenter = word.rect.center;
        final double distance =
            (wordCenter - currentDragPointInOriginalCoords).distance;

        // Prioritize words that are closer to the drag point.
        if (distance < minDistanceToPoint) {
          minDistanceToPoint = distance;
          newTargetWord = word;
        }
      }
    }

    // If no new target word is found nearby, maintain current selection or default to anchor
    if (newTargetWord == null) {
      if (_selectedWords.length > 1) {
        // If multiple words were selected, reduce to just anchor
        setState(() {
          _selectedWords = [_fixedAnchorWord!];
          _leftHandleWord = _fixedAnchorWord; // Ensure handles stay on fixed anchor
          _rightHandleWord = _fixedAnchorWord; // Ensure handles stay on fixed anchor
        });
      }
      return;
    }

    // Determine the new range of words to select
    // Find the indices of the fixed anchor word and the new target word
    int fixedAnchorWordIndex = allWordsSorted.indexOf(_fixedAnchorWord!);
    int targetWordIndex = allWordsSorted.indexOf(newTargetWord);

    // If for some reason newTargetWord is not in allWordsSorted (shouldn't happen with current logic),
    // handle it gracefully.
    if (fixedAnchorWordIndex == -1 || targetWordIndex == -1) {
      print("Error: Anchor or target word not found in sorted list for selection range.");
      return;
    }

    int newStartIndex = min(fixedAnchorWordIndex, targetWordIndex);
    int newEndIndex = max(fixedAnchorWordIndex, targetWordIndex);

    List<TextBox> newSelection = allWordsSorted.sublist(
      newStartIndex,
      newEndIndex + 1,
    );

    // Ensure _leftHandleWord and _rightHandleWord are updated based on the *current* selection
    // Sort the new selection to correctly identify its visual leftmost and rightmost words
    final sortedNewSelection = List<TextBox>.from(newSelection)
      ..sort((TextBox a, TextBox b) { // Explicitly typing for safety
        int yCompare = a.rect.top.compareTo(b.rect.top);
        if (yCompare != 0) return yCompare;
        return a.rect.left.compareTo(b.rect.left);
      });

    TextBox? newLeftHandleWord = sortedNewSelection.first;
    TextBox? newRightHandleWord = sortedNewSelection.last;

    // Update state only if the selection or handle words have actually changed
    if (!TextRecognitionHelpers.listEquals(_selectedWords, newSelection) ||
        _leftHandleWord != newLeftHandleWord ||
        _rightHandleWord != newRightHandleWord) {
      setState(() {
        _selectedWords = newSelection;
        _leftHandleWord = newLeftHandleWord; // Update the left handle word
        _rightHandleWord = newRightHandleWord; // Update the right handle word
      });
    }
  }

  void _gotoTranslate(String txt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TranslationPage(
          originalText: txt,
          fromLanguage: _fromLanguage,
          toLanguage: _toLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Calculate transformedFixedAnchorRect for TextSelectionOverlay handles
    Rect? transformedFixedAnchorRect;
    if (_fixedAnchorWord != null && _previewSize != null) {
      final Rect scaledFixedAnchorRect = BoundingBoxPainter.scaleRectForFit(
        _fixedAnchorWord!.rect,
        _originalImageSize,
        _previewSize!,
        BoxFit.cover,
      );
      transformedFixedAnchorRect = MatrixUtils.transformRect(
        _transformationController.value,
        scaledFixedAnchorRect,
      );
    }
    // Calculate the overall selection rectangle for BoundingBoxPainter
    Rect? currentSelectionRect;
    if (_selectedWords.isNotEmpty && _previewSize != null) {
      // Start with the first word's scaled rectangle
      Rect combinedRect = BoundingBoxPainter.scaleRectForFit(
        _selectedWords.first.rect,
        _originalImageSize,
        _previewSize!,
        BoxFit.cover,
      );
      // Expand to include all other selected words
      for (int i = 1; i < _selectedWords.length; i++) {
        final scaledWordRect = BoundingBoxPainter.scaleRectForFit(
          _selectedWords[i].rect,
          _originalImageSize,
          _previewSize!,
          BoxFit.cover,
        );
        combinedRect = combinedRect.expandToInclude(scaledWordRect);
      }
      // Apply InteractiveViewer's transformation to the combined rectangle
      currentSelectionRect = MatrixUtils.transformRect(
        _transformationController.value,
        combinedRect,
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.1),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _hasCapturedImage
              ? (_isFromGallery ? 'Selected Image' : 'Captured Image')
              : 'Take a Picture',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            _hasCapturedImage
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            if (_hasCapturedImage) {
              // When exiting captured image, reset state and re-initialize camera
              _resetSelectionState(shouldReinitializeCamera: true);
            } else {
              // When going back from live camera, dispose camera before popping the page
              _cameraService.disposeCamera();
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        top: false,
        child: Column(
          children: [
            // ClipRRect and SizedBox define the overall display area with rounded bottom corners
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              child: SizedBox(
                height: size.height * 0.84,
                width: double.infinity,
                child: Stack(
                  children: [
                    if (_isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black, // Solid black background to hide content
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ), // White loading indicator
                            ),
                          ),
                        ),
                      )
                    else // Not loading, show the main camera/image UI
                      ...[
                        // Positioned.fill ensures CameraDisplayArea fills its parent SizedBox
                        Positioned.fill(
                          child: CameraDisplayArea(
                            isCameraInitialized: _isCameraInitialized,
                            capturedImageFile: _capturedImageFile,
                            cameraController: _cameraService.controller,
                            transformationController: _transformationController,
                            textBoxes: _textBoxes,
                            originalImageSize: _originalImageSize,
                            selectedWords: _selectedWords,
                            currentSelectionRect: currentSelectionRect,
                            onCameraScaleStart: (details) =>
                            _baseZoom = _currentZoom,
                            onCameraScaleUpdate: (scale) async {
                              var z = (_baseZoom * scale).clamp(
                                _minZoom,
                                _maxZoom,
                              );
                              if (z != _currentZoom) {
                                _currentZoom = z;
                                await _cameraService.setZoomLevel(z);
                              }
                            },
                            onTapUp: _onTapUp,
                            onPreviewSizeAndContextChanged: (size, context) {
                              setState(() {
                                _previewSize = size;
                                _customPaintContext = context;
                              });
                            },
                          ),
                        ),
                        // CameraControlBar positioned over the camera/image display
                        CameraControlBar(
                          hasCapturedImage: _hasCapturedImage,
                          isFromGallery: _isFromGallery,
                          isFlashOn: _cameraService.isFlashOn,
                          onPickImage: _pickImageFromGallery,
                          onCapture: _captureAndRecognizeText,
                          onToggleFlash: () async {
                            await _cameraService.toggleFlash();
                            setState(() {});
                          },
                        ),
                        // TextSelectionOverlay positioned over the camera/image display for interaction
                        TextSelectionOverlay(
                          selectedWords: _selectedWords,
                          capturedImageFile: _capturedImageFile,
                          previewSize: _previewSize,
                          originalImageSize: _originalImageSize,
                          transformationController: _transformationController,
                          fixedAnchorWord: _fixedAnchorWord,
                          isDraggingLeftHandleCurrent:
                          _isDraggingLeftHandleCurrent,
                          transformedFixedAnchorRect:
                          transformedFixedAnchorRect,
                          currentDraggingHandleScreenPosition:
                          _currentDraggingHandleScreenPosition,
                          leftHandleWord: _leftHandleWord,
                          rightHandleWord: _rightHandleWord,
                          onHandlePanStartLeft: (details) {
                            print("onHandlePanStartLeft: called.");
                            if (_selectedWords.isNotEmpty) {
                              setState(() {
                                // For dragging the LEFT handle, the FIXED anchor is the CURRENT right handle word
                                // This is crucial for multi-line selections to expand correctly.
                                _fixedAnchorWord = _rightHandleWord;
                                _isDraggingLeftHandleCurrent = true;
                                print(
                                    "onHandlePanStartLeft: _fixedAnchorWord set to: ${_fixedAnchorWord?.text}");
                                // Get the screen position of the drag start for visual feedback
                                final RenderBox renderBox = _customPaintContext!
                                    .findRenderObject() as RenderBox;
                                _currentDraggingHandleScreenPosition =
                                    renderBox.globalToLocal(
                                        details.globalPosition);
                              });
                            } else {
                              print(
                                  "onHandlePanStartLeft: _selectedWords is empty, cannot start drag.");
                            }
                          },
                          onHandlePanStartRight: (details) {
                            print("onHandlePanStartRight: called.");
                            if (_selectedWords.isNotEmpty) {
                              setState(() {
                                // For dragging the RIGHT handle, the FIXED anchor is the CURRENT left handle word
                                // This is crucial for multi-line selections to expand correctly.
                                _fixedAnchorWord = _leftHandleWord;
                                _isDraggingLeftHandleCurrent = false;
                                print(
                                    "onHandlePanStartRight: _fixedAnchorWord set to: ${_fixedAnchorWord?.text}");

                                // Get the screen position of the drag start for visual feedback
                                final RenderBox renderBox = _customPaintContext!
                                    .findRenderObject() as RenderBox;
                                _currentDraggingHandleScreenPosition =
                                    renderBox.globalToLocal(
                                        details.globalPosition);
                              });
                            } else {
                              print(
                                  "onHandlePanStartRight: _selectedWords is empty, cannot start drag.");
                            }
                          },
                          onHandlePanUpdate: _updateSelectionBasedOnHandleDrag,
                          onHandlePanEnd: (details) {
                            setState(() {
                              print(
                                  "onHandlePanEnd: _selectedWords.length = ${_selectedWords.length}");
                              if (_selectedWords.isEmpty) {
                                print(
                                    "onHandlePanEnd: _selectedWords is empty, resetting all.");
                                _fixedAnchorWord = null;
                                _isDraggingLeftHandleCurrent = false;
                                _currentDraggingHandleScreenPosition = null;
                                _leftHandleWord = null;
                                _rightHandleWord = null;
                                return;
                              }

                              final sorted = List<TextBox>.from(_selectedWords)
                                ..sort((TextBox a, TextBox b) {
                                  // Explicitly type 'a' and 'b' and use 'rect'
                                  int yCompare =
                                  a.rect.top.compareTo(b.rect.top);
                                  if (yCompare != 0) return yCompare;
                                  return a.rect.left.compareTo(b.rect.left);
                                });

                              _leftHandleWord = sorted.first;
                              _rightHandleWord = sorted.last;
                              print(
                                  "onHandlePanEnd: Final _leftHandleWord: ${_leftHandleWord?.text}, _rightHandleWord: ${_rightHandleWord?.text}");

                              _fixedAnchorWord =
                              null; // Important: Clear this after the drag ends
                              _isDraggingLeftHandleCurrent = false;
                              _currentDraggingHandleScreenPosition = null;
                              print("onHandlePanEnd: Drag state variables reset.");
                            });
                          },
                          onTranslate: (text) {
                            _gotoTranslate(text);
                          },
                        ),
                      ],
                  ],
                ),
              ),
            ),
            const Spacer(), // Spacer to push the language selector to the bottom
            // Language selection bar at the bottom
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: LanguageSelector(
                  onLanguageChanged: (s, t) {
                    setState(() {
                      _fromLanguage = s;
                      _toLanguage = t;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}