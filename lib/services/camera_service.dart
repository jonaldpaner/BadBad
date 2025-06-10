import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraService {
  CameraController? _cameraController;
  bool _isFlashOn = false;
  final TextRecognizer _textRecognizer = TextRecognizer(); // Initialize once

  CameraController? get controller => _cameraController;
  bool get isFlashOn => _isFlashOn;
  String? lastCapturedImagePath;

  // New method to explicitly dispose of the camera controller
  Future<void> disposeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null; // Set to null after disposing
      _isFlashOn = false; // Reset flash state
    }
  }

  Future<RecognizedText?> captureAndGetRecognizedText() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) {
      return null;
    }

    await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    final picture = await _cameraController!.takePicture();
    lastCapturedImagePath = picture.path; // Save for later access
    await _cameraController!.setFlashMode(FlashMode.off); // Turn off flash after capture

    final inputImage = InputImage.fromFilePath(picture.path);
    return await _textRecognizer.processImage(inputImage);
  }

  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    // If a controller already exists and is initialized, dispose it first
    // to ensure a clean re-initialization.
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false); // Added enableAudio: false
    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(FlashMode.off); // Default to off
    _isFlashOn = false; // Sync internal state
  }

  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _isFlashOn = !_isFlashOn; // Toggle internal state first
    await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  // Renamed from takePictureAndRecognize to avoid confusion with the existing captureAndGetRecognizedText
  // You might want to consolidate these two methods if their functionality is redundant.
  // For now, keeping it as is, but consider if both are truly needed.
  Future<(XFile, RecognizedText)?> takePictureAndRecognizeAdvanced() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) {
      return null;
    }

    // Maintain flash state during capture
    await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    final picture = await _cameraController!.takePicture();
    await _cameraController!.setFlashMode(FlashMode.off);

    final inputImage = InputImage.fromFilePath(picture.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return (picture, recognizedText);
  }


  Future<double> getMinZoomLevel() =>
      _cameraController?.getMinZoomLevel() ?? Future.value(1.0);

  Future<double> getMaxZoomLevel() =>
      _cameraController?.getMaxZoomLevel() ?? Future.value(1.0);

  Future<void> setZoomLevel(double z) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _cameraController!.setZoomLevel(z);
    }
  }

  @override
  void dispose() {
    disposeCamera(); // Use the new method to dispose camera controller
    _textRecognizer.close(); // Close the TextRecognizer when the service is finally disposed
  }
}