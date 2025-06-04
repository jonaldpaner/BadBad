import 'package:flutter/material.dart';
import '../components/capture_button.dart';
import '../components/language_selector.dart';
import '../components/camera_preview_placeholder.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Take a picture',
            style: TextStyle(color: Colors.black),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const Expanded(
            child: CameraPreviewPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.photo_library, size: 30, color: Colors.black),
                SizedBox(width: 40),
                CaptureButton(),
                SizedBox(width: 40),
                SizedBox(width: 30),
              ],
            ),
          ),
          const LanguageSelector(),
        ],
      ),
    );
  }
}
