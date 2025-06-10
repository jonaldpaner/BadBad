import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraService {
  CameraController? _cameraController;
  bool _isFlashOn = false;
  final TextRecognizer _textRecognizer = TextRecognizer();

  CameraController? get controller => _cameraController;
  bool get isFlashOn => _isFlashOn;
  String? lastCapturedImagePath;


  Future<RecognizedText?> captureAndGetRecognizedText() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) {
      return null;
    }

    await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    final picture = await _cameraController!.takePicture();
    lastCapturedImagePath = picture.path; // Save for later access
    await _cameraController!.setFlashMode(FlashMode.off);

    final inputImage = InputImage.fromFilePath(picture.path);
    return await _textRecognizer.processImage(inputImage);
  }

  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    _cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await _cameraController!.initialize();
  }

  Future<void> toggleFlash() async {
    if (_cameraController == null) return;
    await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.off : FlashMode.torch);
    _isFlashOn = !_isFlashOn;
  }
  Future<(XFile, RecognizedText)?> takePictureAndRecognize() async {
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
    if (_cameraController != null) await _cameraController!.setZoomLevel(z);
  }


  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
  }
}
