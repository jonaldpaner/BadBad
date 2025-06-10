import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../components/capture_button.dart';
import '../components/icon_action_button.dart';
import '../components/language_selector.dart';
import '../components/camera_preview_placeholder.dart';
import 'translation_page.dart';
import '../services/camera_service.dart';

class TextBox {
  final Rect rect;
  final String text;
  final bool isWord;
  TextBox(this.rect, this.text, {this.isWord = true});

  Rect scaleTo(Size original, Size preview) {
    final sx = preview.width / original.width;
    final sy = preview.height / original.height;
    return Rect.fromLTRB(
      rect.left * sx,
      rect.top * sy,
      rect.right * sx,
      rect.bottom * sy,
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<TextBox> boxes;
  final Size originalSize;
  final Size previewSize;
  final List<TextBox> selectedWords;

  BoundingBoxPainter(this.boxes, this.originalSize, this.previewSize, {this.selectedWords = const []});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final selectedPaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (var b in boxes.where((b) => !b.isWord)) {
      final r = b.scaleTo(originalSize, previewSize);
      canvas.drawRect(r, linePaint);
    }

    for (var w in selectedWords) {
      final r = w.scaleTo(originalSize, previewSize);
      canvas.drawRect(r, selectedPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

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
  File? _capturedImage;
  String _fromLanguage = 'English';
  String _toLanguage = 'Ata Manobo';
  double _currentZoom = 1, _minZoom = 1, _maxZoom = 1, _baseZoom = 1;
  File? _capturedImageFile;
  Size _originalImageSize = Size(1280, 720);
  bool _hasCapturedImage = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    await _cameraService.initializeCamera(cams);
    _minZoom = await _cameraService.getMinZoomLevel();
    _maxZoom = await _cameraService.getMaxZoomLevel();
    _currentZoom = _minZoom;
    await _cameraService.setZoomLevel(_currentZoom);
    setState(() => _isCameraInitialized = true);
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _captureAndRecognizeText() async {
    setState(() {
      _textBoxes.clear();
      _capturedImageFile = null;
      _isLoading = true;
      _selectedWords.clear();
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

        List<TextBox> boxes = [];
        for (var block in recog.blocks) {
          for (var line in block.lines) {
            boxes.add(TextBox(line.boundingBox, line.text, isWord: false));
            for (var e in line.elements) {
              if (RegExp(r'\w').hasMatch(e.text)) {
                boxes.add(TextBox(e.boundingBox, e.text, isWord: true));
              }
            }
          }
        }

        setState(() {
          _capturedImageFile = file;
          _originalImageSize = origSize;
          _textBoxes = boxes;
          _hasCapturedImage = true;
        });

      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during capture: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onTapUp(Offset pos, Size previewSize) {
    for (int i = 0; i < _textBoxes.length; i++) {
      final b = _textBoxes[i];
      if (b.isWord && b.scaleTo(_originalImageSize, previewSize).contains(pos)) {
        setState(() => _selectedWords = [b]);
        break;
      }
    }
  }

  void _expandSelection(bool toRight) {
    if (_selectedWords.isEmpty) return;
    final allWords = _textBoxes.where((b) => b.isWord).toList();
    final currentIndices = _selectedWords.map((w) => allWords.indexOf(w)).toList();
    if (currentIndices.any((i) => i == -1)) return;
    final minIdx = currentIndices.reduce((a, b) => a < b ? a : b);
    final maxIdx = currentIndices.reduce((a, b) => a > b ? a : b);
    int newIdx = toRight ? maxIdx + 1 : minIdx - 1;
    if (newIdx >= 0 && newIdx < allWords.length) {
      setState(() {
        if (toRight) {
          _selectedWords.add(allWords[newIdx]);
        } else {
          _selectedWords.insert(0, allWords[newIdx]);
        }
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.1), // semi-transparent
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _hasCapturedImage ? 'Captured Image' : 'Take a Picture',
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
              setState(() {
                _hasCapturedImage = false;
                _capturedImage = null;
                _capturedImageFile = null;
                _textBoxes.clear();
                _selectedWords.clear();
              });
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
                height: size.height * 0.84,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _isCameraInitialized
                          ? GestureDetector(
                        onScaleStart: (_) => _baseZoom = _currentZoom,
                        onScaleUpdate: (s) async {
                          var z = (_baseZoom * s.scale).clamp(_minZoom, _maxZoom);
                          if (z != _currentZoom) {
                            _currentZoom = z;
                            await _cameraService.setZoomLevel(z);
                          }
                        },
                        child: _capturedImageFile != null
                            ? Image.file(_capturedImageFile!, fit: BoxFit.cover)
                            : CameraPreview(_cameraService.controller!),
                      )
                          : const CameraPreviewPlaceholder(),
                    ),
                    if (_textBoxes.isNotEmpty && _capturedImageFile != null)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final previewSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return GestureDetector(
                              onTapUp: (d) => _onTapUp(d.localPosition, previewSize),
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    size: Size.infinite,
                                    painter: BoundingBoxPainter(
                                      _textBoxes,
                                      _originalImageSize,
                                      previewSize,
                                      selectedWords: _selectedWords,
                                    ),
                                  ),
                                  if (_selectedWords.isNotEmpty)
                                    ...[
                                      Positioned(
                                        left: _selectedWords.first.scaleTo(_originalImageSize, previewSize).left +
                                            _selectedWords.first.scaleTo(_originalImageSize, previewSize).width / 2 -
                                            60, // Center horizontally
                                        top: _selectedWords.first.scaleTo(_originalImageSize, previewSize).top - 50,
                                        child: Material(
                                          elevation: 6,
                                          borderRadius: BorderRadius.circular(20),
                                          color: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor, // Matches your LanguageSelector card color
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
                                        left: _selectedWords.first.scaleTo(_originalImageSize, previewSize).left - 8,
                                        top: _selectedWords.first.scaleTo(_originalImageSize, previewSize).center.dy - 8,
                                        child: GestureDetector(
                                          onTap: () => _expandSelection(false),
                                          child: _dragHandle(),
                                        ),
                                      ),
                                      Positioned(
                                        left: _selectedWords.last.scaleTo(_originalImageSize, previewSize).right - 8,
                                        top: _selectedWords.last.scaleTo(_originalImageSize, previewSize).center.dy - 8,
                                        child: GestureDetector(
                                          onTap: () => _expandSelection(true),
                                          child: _dragHandle(),
                                        ),
                                      ),
                                    ]
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    if (_capturedImage == null)
                      Positioned(
                        bottom: 24,
                        left: 32,
                        right: 32,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconActionButton(
                              icon: Icons.photo_library_outlined,
                              size: size.width * 0.07,
                              onTap: () {},
                            ),
                            CaptureButton(onTap: _captureAndRecognizeText),
                            IconActionButton(
                              icon: _cameraService.isFlashOn ? Icons.flash_on : Icons.flash_off,
                              size: size.width * 0.07,
                              onTap: () async {
                                await _cameraService.toggleFlash();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
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
