import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../components/capture_button.dart';
import '../components/language_selector.dart';
import '../components/camera_preview_placeholder.dart';
import '../components/icon_action_button.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  bool _isLoading = false;
  String? _errorMessage;
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.high);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        _pickedImageFile = File(image.path);

        // Run OCR on picked image
        final inputImage = InputImage.fromFile(_pickedImageFile!);
        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Recognized Text'),
              content: SingleChildScrollView(
                child: Text(recognizedText.text.isNotEmpty ? recognizedText.text : 'No text found'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      if (_isFlashOn) {
        await _cameraController.setFlashMode(FlashMode.off);
      } else {
        await _cameraController.setFlashMode(FlashMode.torch);
      }

      setState(() {
        _isFlashOn = !_isFlashOn;
      });

      final flashMessage = _isFlashOn ? 'Flash is turned ON' : 'Flash is turned OFF';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(flashMessage),
          duration: const Duration(milliseconds: 500), // 0.5 seconds
        ),
      );
    } catch (e) {
      print('Flash toggle error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle flash: $e'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _captureAndRecognizeText() async {
    if (!_cameraController.value.isInitialized || _cameraController.value.isTakingPicture) {
      return;
    }

    try {
      if (_isFlashOn) {
        await _cameraController.setFlashMode(FlashMode.torch);
      } else {
        await _cameraController.setFlashMode(FlashMode.off);
      }

      final XFile picture = await _cameraController.takePicture();
      await _cameraController.setFlashMode(FlashMode.off);

      final inputImage = InputImage.fromFilePath(picture.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Recognized Text'),
          content: SingleChildScrollView(
            child: Text(recognizedText.text.isNotEmpty ? recognizedText.text : 'No text found'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      print('Error capturing photo or recognizing text: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              // Camera preview with rounded bottom
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: SizedBox(
                  height: screenHeight * 0.70,
                  width: double.infinity,
                  child: _isCameraInitialized
                      ? CameraPreview(_cameraController)
                      : const CameraPreviewPlaceholder(),
                ),
              ),
              // Bottom section with buttons and language selector
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.08,
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconActionButton(
                            icon: Icons.photo_library_outlined,
                            size: screenWidth * 0.07,
                            onTap: _pickImageFromGallery,
                          ),
                          CaptureButton(onTap: _captureAndRecognizeText),
                          IconActionButton(
                            icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            size: screenWidth * 0.07,
                            onTap: _toggleFlash,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.025),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.015,
                        ),
                        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const LanguageSelector(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Transparent AppBar overlaid on top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Take a Picture',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              centerTitle: true,
            ),
          ),
        ],
      ),
    );
  }
}
