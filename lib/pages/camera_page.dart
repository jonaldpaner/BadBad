import 'dart:io';
import 'dart:ui'; // Contains Size, Rect, Offset
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../components/capture_button.dart';
import '../components/icon_action_button.dart';
import '../components/language_selector.dart';
import '../components/camera_preview_placeholder.dart';
import 'translation_page.dart';
import '../services/camera_service.dart';
import 'package:image_picker/image_picker.dart';

// Import the BoundingBoxPainter from your utils directory
import '../utils/bounding_box_painter.dart'; // Make sure this file is updated as well!


class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  _CameraPageState createState() => _CameraPageState();
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

  // Added for InteractiveViewer
  TransformationController _transformationController = TransformationController();


  @override
  void initState() {
    super.initState();
    _initCamera();
  }


  Future<void> _pickImageFromGallery() async {
    setState(() {
      _isLoading = true;
      _textBoxes.clear();
      _selectedWords.clear();
      _hasCapturedImage = false; // Reset to ensure loading state is clear before new pick
      _isFromGallery = false; // Reset initially
      _transformationController.value = Matrix4.identity(); // Reset zoom/pan
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
    setState(() {
      _isLoading = true;
      _textBoxes.clear();
      _selectedWords.clear();
      _capturedImageFile = null;
      _hasCapturedImage = false;
      _isFromGallery = false;
      _transformationController.value = Matrix4.identity(); // Reset zoom/pan
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

  /// Helper function to check if a point is inside a polygon (using winding number algorithm).
  bool _isPointInPolygon(List<Offset> points, Offset testPoint) {
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

  /// Handles tap events on the image to select words.
  void _onTapUp(Offset pos, Size previewSize) {
    if (!_hasCapturedImage) return;

    // 1. Transform tap position from local widget coordinates (relative to CustomPaint/InteractiveViewer viewport)
    //    to the coordinate system of the InteractiveViewer's content *before* any zoom/pan.
    final Matrix4 inverseInteractiveViewerMatrix = Matrix4.inverted(_transformationController.value);
    final Offset tapInInteractiveViewerContentCoords = MatrixUtils.transformPoint(inverseInteractiveViewerMatrix, pos);

    // 2. Now, `tapInInteractiveViewerContentCoords` is in the space of `previewSize`
    //    (the dimensions of the area where the image/painter is drawn after BoxFit.cover).
    //    We need to reverse the BoxFit.cover transformation to get it back to
    //    the `_originalImageSize` coordinate system, where the 'b.cornerPoints' are.

    final double hRatio = previewSize.width / _originalImageSize.width;
    final double vRatio = previewSize.height / _originalImageSize.height;

    double coverScale;
    double coverOffsetX = 0.0;
    double coverOffsetY = 0.0;

    // This logic must exactly mirror the BoxFit.cover logic in BoundingBoxPainter.scalePointsForFit
    if (_originalImageSize.width / _originalImageSize.height < previewSize.width / previewSize.height) {
      // Original image aspect ratio is narrower than display area.
      // Image will be scaled to match display width, height will be cropped.
      coverScale = hRatio;
      coverOffsetY = (previewSize.height - _originalImageSize.height * coverScale) / 2.0;
    } else {
      // Original image aspect ratio is wider than display area.
      // Image will be scaled to match display height, width will be cropped.
      coverScale = vRatio;
      coverOffsetX = (previewSize.width - _originalImageSize.width * coverScale) / 2.0;
    }

    // 3. Apply the inverse of the BoxFit.cover transformation
    final Offset tapInOriginalImageCoords = Offset(
      (tapInInteractiveViewerContentCoords.dx - coverOffsetX) / coverScale,
      (tapInInteractiveViewerContentCoords.dy - coverOffsetY) / coverScale,
    );

    TextBox? tappedWord;
    for (final b in _textBoxes) {
      if (b.isWord) {
        // Now, compare the tap point (in original image coords) directly with
        // the original corner points from ML Kit (also in original image coords).
        if (_isPointInPolygon(b.cornerPoints, tapInOriginalImageCoords)) {
          tappedWord = b;
          break;
        }
      }
    }

    setState(() {
      if (tappedWord != null) {
        if (_selectedWords.isNotEmpty && _selectedWords.first == tappedWord) {
          _selectedWords.clear();
        } else {
          _selectedWords = [tappedWord];
        }
      } else {
        _selectedWords.clear();
      }
    });
  }

  /// Expands the current word selection to the left or right.
  void _expandSelection(bool toRight) {
    if (_selectedWords.isEmpty) return;

    final allWords = _textBoxes.where((b) => b.isWord).toList();
    allWords.sort((a, b) {
      int yCompare = a.rect.top.compareTo(b.rect.top);
      if (yCompare != 0) return yCompare;
      return a.rect.left.compareTo(b.rect.left);
    });

    final currentIndices = _selectedWords.map((w) => allWords.indexOf(w)).toList();
    if (currentIndices.any((i) => i == -1)) {
      print("Error: Selected word not found in allWords list.");
      return;
    }

    final int minIdx = currentIndices.reduce((a, b) => a < b ? a : b);
    final int maxIdx = currentIndices.reduce((a, b) => a > b ? a : b);

    int newIdx = toRight ? maxIdx + 1 : minIdx - 1;

    if (newIdx >= 0 && newIdx < allWords.length) {
      setState(() {
        if (toRight) {
          if (!_selectedWords.contains(allWords[newIdx])) {
            _selectedWords.add(allWords[newIdx]);
          }
        } else {
          if (!_selectedWords.contains(allWords[newIdx])) {
            _selectedWords.insert(0, allWords[newIdx]);
          }
        }
        _selectedWords.sort((a, b) => a.rect.left.compareTo(b.rect.left));
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
              // Clear captured image and go back to camera preview
              setState(() {
                _hasCapturedImage = false;
                _capturedImageFile = null;
                _textBoxes.clear();
                _selectedWords.clear();
                _isFromGallery = false;
                _transformationController.value = Matrix4.identity(); // Reset zoom/pan
              });
            } else {
              // If no image, then it means go back (pop)
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
                    Positioned.fill(
                      child: _isCameraInitialized
                          ? (_capturedImageFile != null
                          ? InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1.0,
                        maxScale: 4.0, // Adjust max zoom as needed
                        child: Stack( // Wrap image and CustomPaint in a Stack for InteractiveViewer
                          children: [
                            Positioned.fill(
                              child: Image.file(
                                _capturedImageFile!,
                                fit: BoxFit.cover, // Image fills the available space
                                alignment: Alignment.center,
                              ),
                            ),
                            // Overlay CustomPaint for bounding boxes.
                            // Its size will match the InteractiveViewer's content area.
                            Positioned.fill(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final previewSize = Size(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  );
                                  return GestureDetector(
                                    onTapUp: (d) => _onTapUp(d.localPosition, previewSize),
                                    child: CustomPaint(
                                      size: Size.infinite, // Fills its parent
                                      painter: BoundingBoxPainter(
                                        _textBoxes,
                                        _originalImageSize,
                                        previewSize,
                                        selectedWords: _selectedWords,
                                        fit: BoxFit.cover, // Indicate the fit type
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                          : GestureDetector( // Live camera view, only zoom on camera
                        onScaleStart: (_) => _baseZoom = _currentZoom,
                        onScaleUpdate: (s) async {
                          var z = (_baseZoom * s.scale).clamp(_minZoom, _maxZoom);
                          if (z != _currentZoom) {
                            _currentZoom = z;
                            await _cameraService.setZoomLevel(z);
                          }
                        },
                        child: CameraPreview(_cameraService.controller!),
                      ))
                          : const CameraPreviewPlaceholder(),
                    ),
                    // UI controls at the bottom of the camera frame area
                    Positioned(
                      bottom: 24,
                      left: 32,
                      right: 32,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Gallery Button (visible if in live camera OR if from gallery)
                          if (!_hasCapturedImage || _isFromGallery)
                            IconActionButton(
                              icon: Icons.photo_library_outlined,
                              size: size.width * 0.07,
                              onTap: _pickImageFromGallery,
                            ),
                          // Capture Button (only visible when in live camera mode)
                          if (!_hasCapturedImage)
                            CaptureButton(onTap: _captureAndRecognizeText),
                          // Flash Button (only visible when in live camera mode)
                          if (!_hasCapturedImage)
                            IconActionButton(
                              icon: _cameraService.isFlashOn ? Icons.flash_on : Icons.flash_off,
                              size: size.width * 0.07,
                              onTap: () async {
                                await _cameraService.toggleFlash();
                                setState(() {});
                              },
                            ),
                          // Spacer to maintain alignment if buttons are conditionally hidden
                          if (_hasCapturedImage) // If any image is present (captured or gallery)
                            SizedBox(width: size.width * 0.07 * 2), // Two empty slots
                        ],
                      ),
                    ),
                    // Translate button and drag handles (positioned within the overlay)
                    if (_selectedWords.isNotEmpty && _capturedImageFile != null)
                      LayoutBuilder( // Use LayoutBuilder for consistent positioning
                        builder: (context, constraints) {
                          final previewSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );

                          // First, get the rect scaled according to BoxFit.cover
                          final Rect scaledRect = BoundingBoxPainter.scaleRectForFit(
                            _selectedWords.first.rect,
                            _originalImageSize,
                            previewSize,
                            BoxFit.cover,
                          );

                          // Then, apply InteractiveViewer's transform to this scaled rect's points
                          final Matrix4 currentTransform = _transformationController.value;
                          final Offset translatedTopLeft = MatrixUtils.transformPoint(currentTransform, scaledRect.topLeft);
                          final Offset translatedBottomRight = MatrixUtils.transformPoint(currentTransform, scaledRect.bottomRight);
                          final Rect transformedAndScaledRect = Rect.fromPoints(translatedTopLeft, translatedBottomRight);


                          return Stack(
                            children: [
                              Positioned(
                                // Position based on the transformed and scaled rect
                                left: transformedAndScaledRect.left + transformedAndScaledRect.width / 2 - 60,
                                top: transformedAndScaledRect.top - 50,
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        final combinedText = _selectedWords.map((e) => e.text).join(' ');
                                        _gotoTranslate(combinedText);
                                      },
                                      child: Text(
                                        "Translate",
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: transformedAndScaledRect.left - 8,
                                top: transformedAndScaledRect.center.dy - 8,
                                child: GestureDetector(
                                  onTap: () => _expandSelection(false),
                                  child: _dragHandle(),
                                ),
                              ),
                              Positioned(
                                left: transformedAndScaledRect.right - 8,
                                top: transformedAndScaledRect.center.dy - 8,
                                child: GestureDetector(
                                  onTap: () => _expandSelection(true),
                                  child: _dragHandle(),
                                ),
                              ),
                            ],
                          );
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

  Widget _dragHandle() => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: Colors.blue,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
  );
}