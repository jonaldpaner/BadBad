import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../components/capture_button.dart';
import '../components/language_selector.dart';
import '../components/camera_preview_placeholder.dart';

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

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.medium);
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
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        print('Picked image path: ${image.path}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Picked image: ${image.name}')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Flash will be used when capturing photo')),
    );
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Take a Picture',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera preview or placeholder with bottom rounded corners
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: _isCameraInitialized
                    ? CameraPreview(_cameraController)
                    : const CameraPreviewPlaceholder(),
              ),
            ),

            // Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _pickImageFromGallery,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.photo_library_outlined, size: 28),
                    ),
                  ),
                  CaptureButton(onTap: _captureAndRecognizeText),
                  InkWell(
                    onTap: _toggleFlash,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Language selector box
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 40),
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
    );
  }
}
