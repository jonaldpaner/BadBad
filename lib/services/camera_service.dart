import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraService {
  CameraController? _cameraController;
  bool _isFlashOn = false;
  final TextRecognizer _textRecognizer = TextRecognizer();

  CameraController? get controller => _cameraController;
  bool get isFlashOn => _isFlashOn;

  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    _cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await _cameraController!.initialize();
  }

  Future<void> toggleFlash() async {
    if (_cameraController == null) return;

    if (_isFlashOn) {
      await _cameraController!.setFlashMode(FlashMode.off);
    } else {
      await _cameraController!.setFlashMode(FlashMode.torch);
    }
    _isFlashOn = !_isFlashOn;
  }

  // Add zoom-related getters and setters
  Future<double> getMinZoomLevel() async {
    if (_cameraController == null) return 1.0;
    return await _cameraController!.getMinZoomLevel();
  }

  Future<double> getMaxZoomLevel() async {
    if (_cameraController == null) return 1.0;
    return await _cameraController!.getMaxZoomLevel();
  }

  Future<void> setZoomLevel(double zoom) async {
    if (_cameraController == null) return;
    await _cameraController!.setZoomLevel(zoom);
  }

  Future<String> captureAndRecognizeText() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _cameraController!.value.isTakingPicture) {
      return '';
    }

    if (_isFlashOn) {
      await _cameraController!.setFlashMode(FlashMode.torch);
    } else {
      await _cameraController!.setFlashMode(FlashMode.off);
    }

    final XFile picture = await _cameraController!.takePicture();

    await _cameraController!.setFlashMode(FlashMode.off);

    final inputImage = InputImage.fromFilePath(picture.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    return recognizedText.text;
  }

  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
  }
}
