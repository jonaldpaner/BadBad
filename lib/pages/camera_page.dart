import 'dart:io';
import 'dart:ui'; // Contains Size, Rect, Offset
import 'package:flutter/material.dart' hide TextSelectionOverlay; // HIDDEN: Hide TextSelectionOverlay from material.dart
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math'; // For min/max, sqrt
import '../components/camera_display_area.dart';
import '../components/camera_preview_placeholder.dart';
import '../components/language_selector.dart';
import 'translation_page.dart';
import '../services/camera_service.dart';
import '../utils/bounding_box_painter.dart';
import '../models/text_box.dart'; // Import the standalone TextBox model
import '../utils/text_recognition_helpers.dart' as TextRecognitionHelpers; // Import helpers
import '../components/camera_control_bar.dart';
import '../components/text_selection_overlay.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  List<TextBox> _textBoxes = [];
  List<TextBox> _selectedWords = [];
  String _fromLanguage = 'English';
  String _toLanguage = 'Ata Manobo';
  double _currentZoom = 1, _minZoom = 1, _maxZoom = 1, _baseZoom = 1;
  File? _capturedImageFile;
  Size _originalImageSize = Size(1280, 720); // Default size, will be updated
  bool _hasCapturedImage = false;
  bool _isFromGallery = false;
  TransformationController _transformationController = TransformationController();

  Size? _previewSize; // To store the actual render size of the image/painter
  BuildContext? _customPaintContext; // To get the RenderBox of the CustomPaint for globalToLocal

  // Variables for drag handle expansion control
  TextBox? _fixedAnchorWord; // The word that defines the fixed end of the selection
  bool _isDraggingLeftHandleCurrent = false; // True if left handle is actively being dragged
  Offset? _currentDraggingHandleScreenPosition; // Stores the screen position of the dragged handle

  // New state variables to explicitly track handle positions
  TextBox? _leftHandleWord;
  TextBox? _rightHandleWord;

  // Tolerance for how far off-axis a word can be to be considered "on the same line"
  static const double _verticalLineTolerance = 25.0; // Adjust as needed based on font size/line spacing

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _pickImageFromGallery() async {
    _resetSelectionState(); // Reset all selection related states
    setState(() {
      _isLoading = true;
    });

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      final origSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

      final InputImage inputImage = InputImage.fromFile(file);
      final TextRecognizer recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recog = await recognizer.processImage(inputImage);

      List<TextBox> detectedBoxes = [];
      for (var block in recog.blocks) {
        for (var line in block.lines) {
          final List<Offset> lineCornerOffsets = line.cornerPoints
              .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
              .toList();
          detectedBoxes.add(TextBox(line.boundingBox, line.text, lineCornerOffsets, isWord: false));

          for (var e in line.elements) {
            if (RegExp(r'\w').hasMatch(e.text)) {
              final List<Offset> wordCornerOffsets = e.cornerPoints
                  .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                  .toList();
              detectedBoxes.add(TextBox(e.boundingBox, e.text, wordCornerOffsets, isWord: true));
            }
          }
        }
      }

      recognizer.close();

      setState(() {
        _capturedImageFile = file;
        _originalImageSize = origSize;
        _textBoxes = detectedBoxes;
        _hasCapturedImage = true;
        _isLoading = false;
        _isFromGallery = true; // Set to true for gallery image
      });
    } else {
      setState(() {
        _isLoading = false;
        // If no image is picked, and there was a previous image, keep it
        // If there was no previous image, stay in camera preview
        if (_capturedImageFile == null) {
          _hasCapturedImage = false;
        }
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      await _cameraService.initializeCamera(cams);
      _minZoom = await _cameraService.getMinZoomLevel();
      _maxZoom = await _cameraService.getMaxZoomLevel();
      _currentZoom = _minZoom;
      await _cameraService.setZoomLevel(_currentZoom);
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      print("Failed to initialize camera: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing camera: ${e.toString()}')),
      );
      setState(() => _isCameraInitialized = false);
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _transformationController.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<void> _captureAndRecognizeText() async {
    _resetSelectionState(); // Reset all selection related states
    setState(() {
      _isLoading = true;
    });

    try {
      final recog = await _cameraService.captureAndGetRecognizedText();
      final imagePath = _cameraService.lastCapturedImagePath;

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
            final List<Offset> lineCornerOffsets = line.cornerPoints
                .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                .toList();
            detectedBoxes.add(TextBox(line.boundingBox, line.text, lineCornerOffsets, isWord: false));

            for (var e in line.elements) {
              if (RegExp(r'\w').hasMatch(e.text)) {
                final List<Offset> wordCornerOffsets = e.cornerPoints
                    .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                    .toList();
                detectedBoxes.add(TextBox(e.boundingBox, e.text, wordCornerOffsets, isWord: true));
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
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during capture: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper to reset all selection-related state variables
  void _resetSelectionState() {
    _textBoxes.clear();
    _selectedWords.clear();
    _capturedImageFile = null;
    _hasCapturedImage = false;
    _isFromGallery = false;
    _transformationController.value = Matrix4.identity(); // Reset zoom/pan
    _fixedAnchorWord = null;
    _isDraggingLeftHandleCurrent = false;
    _currentDraggingHandleScreenPosition = null;
    _leftHandleWord = null; // Reset new handle words
    _rightHandleWord = null; // Reset new handle words
  }

  /// Handles tap events on the image to select words.
  void _onTapUp(Offset pos, Size previewSize) {
    if (!_hasCapturedImage) return;

    setState(() {
      // Clear any previous selection
      _selectedWords.clear();
      // Ensure handle drag state is reset on tap
      _fixedAnchorWord = null;
      _isDraggingLeftHandleCurrent = false;
      _currentDraggingHandleScreenPosition = null;
      _leftHandleWord = null; // Clear handle words on tap
      _rightHandleWord = null; // Clear handle words on tap
    });

    final Offset tapInOriginalImageCoords = TextRecognitionHelpers.toOriginalImageCoordinates(
      pos,
      previewSize,
      _originalImageSize,
      _transformationController,
      BoxFit.cover,
    );

    TextBox? tappedWord;
    for (final b in _textBoxes) {
      if (b.isWord) {
        if (TextRecognitionHelpers.isPointInPolygon(b.cornerPoints, tapInOriginalImageCoords)) {
          tappedWord = b;
          break;
        }
      }
    }

    setState(() {
      if (tappedWord != null) {
        _selectedWords = [tappedWord]; // Select the new word
        _leftHandleWord = tappedWord; // Set both handles to the tapped word for single selection
        _rightHandleWord = tappedWord;
      } else {
        _selectedWords.clear(); // Clear selection if no word is tapped
        _leftHandleWord = null;
        _rightHandleWord = null;
      }
    });
  }

  /// Updates the selection based on dragging one of the handles.
  void _updateSelectionBasedOnHandleDrag(DragUpdateDetails details) {
    if (!_hasCapturedImage || _previewSize == null || _fixedAnchorWord == null || _customPaintContext == null) return;

    final RenderBox renderBox = _customPaintContext!.findRenderObject() as RenderBox;
    final Offset localPos = renderBox.globalToLocal(details.globalPosition);

    // Update the screen position of the dragged handle for real-time visual feedback
    setState(() {
      _currentDraggingHandleScreenPosition = localPos;
    });

    final Offset currentDragPointInOriginalCoords = TextRecognitionHelpers.toOriginalImageCoordinates(
      localPos,
      _previewSize!,
      _originalImageSize,
      _transformationController,
      BoxFit.cover,
    );

    final allWordsSorted = _textBoxes.where((b) => b.isWord).toList()
      ..sort((a, b) {
        int yCompare = a.rect.top.compareTo(b.rect.top);
        return yCompare != 0 ? yCompare : a.rect.left.compareTo(b.rect.left);
      });

    int fixedAnchorWordIndex = allWordsSorted.indexOf(_fixedAnchorWord!);
    if (fixedAnchorWordIndex == -1) {
      print("Error: Fixed anchor word not found in sorted list.");
      return;
    }

    TextBox? newTargetWord;
    double minDistanceToPoint = double.infinity;

    // Find the word whose bounding box center is closest to the drag point
    // among words that are roughly on the same line as the fixed anchor.
    for (final word in allWordsSorted) {
      final double wordVerticalCenter = word.rect.center.dy;
      final double anchorVerticalCenter = _fixedAnchorWord!.rect.center.dy;

      if ((wordVerticalCenter - anchorVerticalCenter).abs() < _verticalLineTolerance ||
          (wordVerticalCenter - currentDragPointInOriginalCoords.dy).abs() < _verticalLineTolerance) {

        final Offset wordCenter = word.rect.center;
        final double distance = (wordCenter - currentDragPointInOriginalCoords).distance;

        if (distance < minDistanceToPoint) {
          minDistanceToPoint = distance;
          newTargetWord = word;
        }
      }
    }

    if (newTargetWord == null) {
      // If no suitable word found within tolerance, keep the current selection or shrink to just the anchor
      // This prevents the selection from disappearing if the drag goes too far from any recognized text.
      if(_selectedWords.length > 1) { // If there was a selection, don't clear it entirely
        setState(() {
          _selectedWords = [_fixedAnchorWord!]; // Shrink to just the fixed anchor word
        });
      }
      return;
    }

    int targetWordIndex = allWordsSorted.indexOf(newTargetWord);
    if (targetWordIndex == -1) {
      print("Error: Target word not found in sorted list after selection logic.");
      return;
    }

    int newStartIndex = min(fixedAnchorWordIndex, targetWordIndex);
    int newEndIndex = max(fixedAnchorWordIndex, targetWordIndex);

    List<TextBox> newSelection = allWordsSorted.sublist(newStartIndex, newEndIndex + 1);

    // If the new selection is different, update state
    if (!TextRecognitionHelpers.listEquals(_selectedWords, newSelection)) {
      setState(() {
        _selectedWords = newSelection;
      });
    }
  }

  /// Navigates to the translation page with the selected text.
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

    // Calculate transformedFixedAnchorRect here
    Rect? transformedFixedAnchorRect;
    if (_fixedAnchorWord != null && _previewSize != null) {
      final Rect scaledFixedAnchorRect = BoundingBoxPainter.scaleRectForFit(
        _fixedAnchorWord!.rect,
        _originalImageSize,
        _previewSize!,
        BoxFit.cover,
      );
      transformedFixedAnchorRect = MatrixUtils.transformRect(_transformationController.value, scaledFixedAnchorRect);
    }

    // Calculate the overall selection rectangle to be drawn by BoundingBoxPainter
    Rect? currentSelectionRect;
    if (_selectedWords.isNotEmpty && _previewSize != null) {
      // Get the first word's scaled rect as a starting point
      Rect combinedRect = BoundingBoxPainter.scaleRectForFit(
        _selectedWords.first.rect,
        _originalImageSize,
        _previewSize!,
        BoxFit.cover, // Ensure this matches the BoxFit used for the image
      );

      // Iterate through the rest of the selected words and union their scaled rects
      for (int i = 1; i < _selectedWords.length; i++) {
        final scaledWordRect = BoundingBoxPainter.scaleRectForFit(
          _selectedWords[i].rect,
          _originalImageSize,
          _previewSize!,
          BoxFit.cover,
        );
        combinedRect = combinedRect.expandToInclude(scaledWordRect);
      }
      // Apply the transformation from the InteractionViewer/Image
      currentSelectionRect = MatrixUtils.transformRect(_transformationController.value, combinedRect);
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
            _hasCapturedImage ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            if (_hasCapturedImage) {
              _resetSelectionState(); // Clear all selection related states
            } else {
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
              child: SizedBox(
                height: size.height * 0.84, // This is your 'camera frame' area
                width: double.infinity,
                child: Stack(
                  children: [
                    // Extracted Camera Display Area
                    CameraDisplayArea(
                      isCameraInitialized: _isCameraInitialized,
                      capturedImageFile: _capturedImageFile,
                      cameraController: _cameraService.controller,
                      transformationController: _transformationController,
                      textBoxes: _textBoxes,
                      originalImageSize: _originalImageSize,
                      selectedWords: _selectedWords,
                      currentSelectionRect: currentSelectionRect, // Pass the calculated rect here
                      onCameraScaleStart: () => _baseZoom = _currentZoom,
                      onCameraScaleUpdate: (scale) async {
                        var z = (_baseZoom * scale).clamp(_minZoom, _maxZoom);
                        if (z != _currentZoom) {
                          _currentZoom = z;
                          await _cameraService.setZoomLevel(z);
                        }
                      },
                      onTapUp: _onTapUp,
                      onPreviewSizeAndContextChanged: (size, context) { // REQUIRED and IMPORTANT
                        setState(() {
                          _previewSize = size;
                          _customPaintContext = context;
                        });
                      },
                    ),
                    // Extracted Bottom Control Bar
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
                    // Extracted Text Selection Overlay
                    TextSelectionOverlay(
                      selectedWords: _selectedWords,
                      capturedImageFile: _capturedImageFile,
                      previewSize: _previewSize,
                      originalImageSize: _originalImageSize,
                      transformationController: _transformationController,
                      fixedAnchorWord: _fixedAnchorWord,
                      isDraggingLeftHandleCurrent: _isDraggingLeftHandleCurrent,
                      transformedFixedAnchorRect: transformedFixedAnchorRect,
                      currentDraggingHandleScreenPosition: _currentDraggingHandleScreenPosition,
                      leftHandleWord: _leftHandleWord, // Pass the explicit left handle word
                      rightHandleWord: _rightHandleWord, // Pass the explicit right handle word
                      onHandlePanStartLeft: (details) {
                        if (_selectedWords.isNotEmpty) {
                          setState(() {
                            // Sort visually from left to right
                            final sorted = List.from(_selectedWords)
                              ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

                            _fixedAnchorWord = sorted.last; // Visually right-most = anchor for LEFT handle drag
                            _isDraggingLeftHandleCurrent = true;

                            final RenderBox renderBox = _customPaintContext!.findRenderObject() as RenderBox;
                            _currentDraggingHandleScreenPosition = renderBox.globalToLocal(details.globalPosition);
                          });
                        }
                      },
                      onHandlePanStartRight: (details) {
                        if (_selectedWords.isNotEmpty) {
                          setState(() {
                            final sorted = List.from(_selectedWords)
                              ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

                            _fixedAnchorWord = sorted.first; // Visually left-most = anchor for RIGHT handle drag
                            _isDraggingLeftHandleCurrent = false;

                            final RenderBox renderBox = _customPaintContext!.findRenderObject() as RenderBox;
                            _currentDraggingHandleScreenPosition = renderBox.globalToLocal(details.globalPosition);
                          });
                        }
                      },
                      onHandlePanUpdate: _updateSelectionBasedOnHandleDrag,
                      onHandlePanEnd: (details) {
                        setState(() {
                          if (_selectedWords.isEmpty) {
                            // No selection or single word selection, reset handles
                            _fixedAnchorWord = null;
                            _isDraggingLeftHandleCurrent = false;
                            _currentDraggingHandleScreenPosition = null;
                            _leftHandleWord = null;
                            _rightHandleWord = null;
                            return;
                          }

                          // Sort visually (left to right, then top to bottom for consistency in multi-line selections)
                          final sorted = List<TextBox>.from(_selectedWords)
                            ..sort((a, b) {
                              // First sort by vertical position (top of the bounding box)
                              int yCompare = a.rect.top.compareTo(b.rect.top);
                              if (yCompare != 0) {
                                return yCompare;
                              }
                              // If vertical positions are similar, sort by horizontal position (left of the bounding box)
                              return a.rect.left.compareTo(b.rect.left);
                            });

                          // The untouched handle should stay at the first selected word
                          _leftHandleWord = sorted.first;
                          // The touched handle should stay at the last selected word
                          _rightHandleWord = sorted.last;

                          // Reset drag state variables
                          _fixedAnchorWord = null;
                          _isDraggingLeftHandleCurrent = false;
                          _currentDraggingHandleScreenPosition = null;
                        });
                      },

                      onTranslate: (text) {
                        _gotoTranslate(text);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
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
