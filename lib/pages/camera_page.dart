import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart' hide TextSelectionOverlay;
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import '../components/camera_display_area.dart';
import '../components/language_selector.dart'; // Ensure this import is correct
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
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  List<TextBox> _textBoxes = [];
  List<TextBox> _selectedWords = [];
  String _fromLanguage = 'Ata Manobo';
  String _toLanguage = 'English';
  double _currentZoom = 1, _minZoom = 1, _maxZoom = 1, _baseZoom = 1;
  File? _capturedImageFile;
  Size _originalImageSize = const Size(1280, 720);
  bool _hasCapturedImage = false;
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

  static const int _maxTranslationCharacters = 70;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
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
      setState(() {
        _isCameraInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing camera: ${e.toString()}')),
      );
      setState(() {
        _isCameraInitialized = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    _resetSelectionState(shouldReinitializeCamera: false);

    setState(() {
      _isLoading = true;
      _isCameraInitialized = false;
    });
    await _cameraService.disposeCamera();

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      print('--- DEBUG: Raw Decoded Image Data ---');
      print('decodedImage.width: ${decodedImage.width}');
      print('decodedImage.height: ${decodedImage.height}');
      final origSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
      print('Calculated origSize: $origSize');
      final InputImage inputImage = InputImage.fromFile(file);
      final TextRecognizer recognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recog = await recognizer.processImage(inputImage);
      recognizer.close();

      List<TextBox> detectedBoxes = [];
      for (var block in recog.blocks) {
        for (var line in block.lines) {
          detectedBoxes.add(
            TextBox(
              line.boundingBox,
              line.text,
              line.cornerPoints
                  .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                  .toList(),
              isWord: false,
            ),
          );
          for (var e in line.elements) {
            if (RegExp(r'\w').hasMatch(e.text)) {
              detectedBoxes.add(
                TextBox(
                  e.boundingBox,
                  e.text,
                  e.cornerPoints
                      .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                      .toList(),
                  isWord: true,
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
        _transformationController.value = Matrix4.identity();
        print(
          'Original Image Size (set for capture AFTER setState): $_originalImageSize',
        );
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasCapturedImage = false;
      });
      await _initCamera();
    }
  }

  Future<void> _captureAndRecognizeText() async {
    _resetSelectionState(shouldReinitializeCamera: false);

    setState(() {
      _isLoading = true;
      _isCameraInitialized = false;
    });

    try {
      final recog = await _cameraService.captureAndGetRecognizedText();
      final imagePath = _cameraService.lastCapturedImagePath;

      await _cameraService.disposeCamera();

      if (recog != null && imagePath != null && mounted) {
        final file = File(imagePath);
        final bytes = await file.readAsBytes();
        final decodedImage = await decodeImageFromList(bytes);
        print('--- DEBUG: Raw Decoded Image Data ---');
        print('decodedImage.width: ${decodedImage.width}');
        print('decodedImage.height: ${decodedImage.height}');
        final origSize = Size(
          decodedImage.width.toDouble(),
          decodedImage.height.toDouble(),
        );
        print(
          'Calculated origSize: $origSize',
        ); // Print origSize before assignment

        List<TextBox> detectedBoxes = [];
        for (var block in recog.blocks) {
          for (var line in block.lines) {
            detectedBoxes.add(
              TextBox(
                line.boundingBox,
                line.text,
                line.cornerPoints
                    .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                    .toList(),
                isWord: false,
              ),
            );
            for (var e in line.elements) {
              if (RegExp(r'\w').hasMatch(e.text)) {
                detectedBoxes.add(
                  TextBox(
                    e.boundingBox,
                    e.text,
                    e.cornerPoints
                        .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                        .toList(),
                    isWord: true,
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
          _transformationController.value = Matrix4.identity();
          print(
            'Original Image Size (set for capture AFTER setState): $_originalImageSize',
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during capture: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
        _hasCapturedImage = false;
      });
      await _initCamera();
    }
  }

  void _resetSelectionState({bool shouldReinitializeCamera = true}) {
    _textBoxes.clear();
    _selectedWords.clear();
    _capturedImageFile = null;
    _hasCapturedImage = false;
    _isFromGallery = false;
    _transformationController.value = Matrix4.identity();
    _fixedAnchorWord = null;
    _isDraggingLeftHandleCurrent = false;
    _currentDraggingHandleScreenPosition = null;
    _leftHandleWord = null;
    _rightHandleWord = null;

    if (shouldReinitializeCamera) {
      _initCamera();
    } else {
      _isCameraInitialized = false;
    }
  }

  void _onTapUp(Offset pos, Size previewSize) {
    if (!_hasCapturedImage) return;

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
      fit: BoxFit.cover,
    );

    TextBox? tappedWord;
    for (final b in _textBoxes) {
      if (b.isWord) {
        if (TextRecognitionHelpers.isPointInPolygon(
          b.cornerPoints,
          tapInOriginalImageCoords,
        )) {
          tappedWord = b;
          break;
        }
      }
    }

    setState(() {
      if (tappedWord != null) {
        _selectedWords = [tappedWord];
        _leftHandleWord = tappedWord;
        _rightHandleWord = tappedWord;
        _fixedAnchorWord = tappedWord;
      }
    });
  }

  Offset _calculateCentroid(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    double sumX = 0;
    double sumY = 0;
    for (final p in points) {
      sumX += p.dx;
      sumY += p.dy;
    }
    return Offset(sumX / points.length, sumY / points.length);
  }

  TextBox? _getClosestWord(Offset point, List<TextBox> words) {
    if (words.isEmpty) return null;
    TextBox? closestWord;
    double minDistance = double.infinity;

    for (final word in words) {
      final Offset wordCentroid = _calculateCentroid(word.cornerPoints);
      final double distance = (wordCentroid - point).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestWord = word;
      }
    }
    return closestWord;
  }

  List<TextBox> _sortWordsByReadingOrder(List<TextBox> words) {
    return TextRecognitionHelpers.sortWordsByReadingOrder(words);
  }

  void _updateSelectionBasedOnHandleDrag(DragUpdateDetails details) {
    if (!_hasCapturedImage ||
        _previewSize == null ||
        _fixedAnchorWord == null ||
        _customPaintContext == null) {
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

    final List<TextBox> allWords = _textBoxes.where((b) => b.isWord).toList();

    TextBox? newTargetWord = _getClosestWord(
      currentDragPointInOriginalCoords,
      allWords,
    );

    if (newTargetWord == null) {
      return;
    }

    final List<TextBox> wordsInReadingOrder = _sortWordsByReadingOrder(
      allWords,
    );

    final int fixedAnchorIndex = wordsInReadingOrder.indexOf(_fixedAnchorWord!);
    final int targetWordIndex = wordsInReadingOrder.indexOf(newTargetWord);

    if (fixedAnchorIndex == -1 || targetWordIndex == -1) {
      return;
    }

    int newStartIndex = min(fixedAnchorIndex, targetWordIndex);
    int newEndIndex = max(fixedAnchorIndex, targetWordIndex);

    List<TextBox> newSelection = wordsInReadingOrder.sublist(
      newStartIndex,
      newEndIndex + 1,
    );

    final sortedNewSelection = _sortWordsByReadingOrder(newSelection);

    TextBox? newLeftHandleWord = sortedNewSelection.isNotEmpty
        ? sortedNewSelection.first
        : null;
    TextBox? newRightHandleWord = sortedNewSelection.isNotEmpty
        ? sortedNewSelection.last
        : null;

    if (!TextRecognitionHelpers.listEquals(_selectedWords, newSelection) ||
        _leftHandleWord != newLeftHandleWord ||
        _rightHandleWord != newRightHandleWord) {
      setState(() {
        _selectedWords = newSelection;
        _leftHandleWord = newLeftHandleWord;
        _rightHandleWord = newRightHandleWord;
      });
    }
  }

  void _showTranslationLimitDialog(
      BuildContext context,
      String fullText,
      int limit,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Translation Limit'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'The translation service currently supports a maximum of $limit characters.',
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF219EBC)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _gotoTranslate(String txt) {
    String textToTranslate = txt;

    if (textToTranslate.length > _maxTranslationCharacters) {
      _showTranslationLimitDialog(context, txt, _maxTranslationCharacters);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TranslationPage(
          originalText: textToTranslate,
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

    Rect? transformedFixedAnchorRect;
    if (_fixedAnchorWord != null && _previewSize != null) {
      final List<Offset> scaledPoints = BoundingBoxPainter.scalePointsForFit(
        _fixedAnchorWord!.cornerPoints,
        _originalImageSize,
        _previewSize!,
        BoxFit.cover,
      );
      final List<Offset> transformedPoints =
      TextRecognitionHelpers.transformPoints(
        scaledPoints,
        _transformationController.value,
      );

      transformedFixedAnchorRect = TextRecognitionHelpers.calculateBoundingRect(
        transformedPoints,
      );
    }

    Rect? currentSelectionRect;
    if (_selectedWords.isNotEmpty && _previewSize != null) {
      List<Offset> allSelectedCornerPoints = [];
      for (final word in _selectedWords) {
        allSelectedCornerPoints.addAll(word.cornerPoints);
      }

      final List<Offset> scaledAllPoints = BoundingBoxPainter.scalePointsForFit(
        allSelectedCornerPoints,
        _originalImageSize,
        _previewSize!,
        BoxFit.cover,
      );

      final List<Offset> transformedAllPoints =
      TextRecognitionHelpers.transformPoints(
        scaledAllPoints,
        _transformationController.value,
      );

      currentSelectionRect = TextRecognitionHelpers.calculateBoundingRect(
        transformedAllPoints,
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
              _resetSelectionState(shouldReinitializeCamera: true);
            } else {
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
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    else ...[
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
                      // Conditionally display the tip
                      if (!_hasCapturedImage) // Only show if no image is captured
                        Positioned(
                          bottom: 100,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "Tip: For best results, align text as straight as possible!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      TextSelectionOverlay(
                        selectedWords: _selectedWords,
                        capturedImageFile: _capturedImageFile,
                        previewSize: _previewSize,
                        originalImageSize: _originalImageSize,
                        transformationController: _transformationController,
                        fixedAnchorWord: _fixedAnchorWord,
                        isDraggingLeftHandleCurrent:
                        _isDraggingLeftHandleCurrent,
                        transformedFixedAnchorRect: transformedFixedAnchorRect,
                        currentDraggingHandleScreenPosition:
                        _currentDraggingHandleScreenPosition,
                        leftHandleWord: _leftHandleWord,
                        rightHandleWord: _rightHandleWord,
                        onHandlePanStartLeft: (details) {
                          if (_selectedWords.isNotEmpty) {
                            setState(() {
                              _fixedAnchorWord = _rightHandleWord;
                              _isDraggingLeftHandleCurrent = true;
                              final RenderBox renderBox =
                              _customPaintContext!.findRenderObject()
                              as RenderBox;
                              _currentDraggingHandleScreenPosition = renderBox
                                  .globalToLocal(details.globalPosition);
                            });
                          }
                        },
                        onHandlePanStartRight: (details) {
                          if (_selectedWords.isNotEmpty) {
                            setState(() {
                              _fixedAnchorWord = _leftHandleWord;
                              _isDraggingLeftHandleCurrent = false;
                              final RenderBox renderBox =
                              _customPaintContext!.findRenderObject()
                              as RenderBox;
                              _currentDraggingHandleScreenPosition = renderBox
                                  .globalToLocal(details.globalPosition);
                            });
                          }
                        },
                        onHandlePanUpdate: (details) {
                          _updateSelectionBasedOnHandleDrag(details);
                        },
                        onHandlePanEnd: (details) {
                          setState(() {
                            if (_selectedWords.isEmpty) {
                              _fixedAnchorWord = null;
                              _isDraggingLeftHandleCurrent = false;
                              _currentDraggingHandleScreenPosition = null;
                              _leftHandleWord = null;
                              _rightHandleWord = null;
                              return;
                            }

                            final sorted = _sortWordsByReadingOrder(
                              _selectedWords,
                            );

                            _leftHandleWord = sorted.isNotEmpty
                                ? sorted.first
                                : null;
                            _rightHandleWord = sorted.isNotEmpty
                                ? sorted.last
                                : null;

                            _fixedAnchorWord = null;
                            _isDraggingLeftHandleCurrent = false;
                            _currentDraggingHandleScreenPosition = null;
                          });
                        },
                        onTranslate: (text) {
                          _gotoTranslate(text);
                        },
                        // Pass the maxTranslationCharacters to the overlay
                        maxTranslationCharacters: _maxTranslationCharacters,
                      ),
                    ],
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
                child: const LanguageSelector(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}