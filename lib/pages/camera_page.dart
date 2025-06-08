import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../components/capture_button.dart';
import '../components/language_selector.dart';
import '../components/camera_preview_placeholder.dart';
import '../components/icon_action_button.dart';
import 'translation_page.dart';
import '../services/camera_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  bool _isCameraInitialized = false;
  bool _isLoading = false;
  File? _pickedImageFile;

  String _fromLanguage = 'English';
  String _toLanguage = 'Ata Manobo';

  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    await _cameraService.initializeCamera(cameras);

    _minZoomLevel = await _cameraService.getMinZoomLevel();
    _maxZoomLevel = await _cameraService.getMaxZoomLevel();
    _currentZoomLevel = _minZoomLevel;
    await _cameraService.setZoomLevel(_currentZoomLevel);

    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    setState(() => _isLoading = true);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _pickedImageFile = File(image.path);

        final inputImage = InputImage.fromFile(_pickedImageFile!);
        final recognizedText = await _textRecognizer.processImage(inputImage);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TranslationPage(
                originalText: recognizedText.text.isNotEmpty
                    ? recognizedText.text
                    : 'No text found',
                fromLanguage: _fromLanguage,
                toLanguage: _toLanguage,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFlash() async {
    await _cameraService.toggleFlash();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_cameraService.isFlashOn ? 'Flash ON' : 'Flash OFF'),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _captureAndRecognizeText() async {
    try {
      final text = await _cameraService.captureAndRecognizeText();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TranslationPage(
              originalText: text.isNotEmpty ? text : 'No text found',
              fromLanguage: _fromLanguage,
              toLanguage: _toLanguage,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true, // remove top padding so camera goes full screen to top
        child: SafeArea(
          bottom: false, // keep bottom safe area for nav bar / language selector
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Camera with Rounded Bottom Corners
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                child: SizedBox(
                  height: size.height * 0.84,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Camera Preview or Placeholder
                      Positioned.fill(
                        child: _isCameraInitialized &&
                            _cameraService.controller != null
                            ? GestureDetector(
                          onScaleStart: (_) => _baseZoomLevel = _currentZoomLevel,
                          onScaleUpdate: (details) async {
                            double newZoom = _baseZoomLevel * details.scale;
                            newZoom = newZoom.clamp(_minZoomLevel, _maxZoomLevel);
                            if (newZoom != _currentZoomLevel) {
                              _currentZoomLevel = newZoom;
                              await _cameraService.setZoomLevel(_currentZoomLevel);
                              setState(() {});
                            }
                          },
                          child: CameraPreview(_cameraService.controller!),
                        )
                            : const CameraPreviewPlaceholder(),
                      ),

                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top,
                            left: 12,
                            right: 12,
                            bottom: 8,
                          ),
                          child: Opacity(
                            opacity: 0.8,  // 70% visibility
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Take a Picture',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Bottom Buttons inside camera frame
                      if (!_isLoading)
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
                                onTap: _pickImageFromGallery,
                              ),
                              CaptureButton(onTap: _captureAndRecognizeText),
                              IconActionButton(
                                icon: _cameraService.isFlashOn
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                                size: size.width * 0.07,
                                onTap: _toggleFlash,
                              ),
                            ],
                          ),
                        ),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ),

              // Spacer pushes selector to bottom of screen
              const Spacer(),

              // Language Selector positioned just above the nav bar
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: LanguageSelector(
                    onLanguageChanged: (source, target) {
                      setState(() {
                        _fromLanguage = source;
                        _toLanguage = target;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}