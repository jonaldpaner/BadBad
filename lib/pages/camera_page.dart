import 'package:flutter/material.dart';
import '../components/capture_button.dart';
import '../components/language_selector.dart';
import '../components/camera_preview_placeholder.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
            const Expanded(
              child: CameraPreviewPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.photo_library_outlined, size: 30, color: Colors.black),
                  SizedBox(width: 40),
                  CaptureButton(),
                  SizedBox(width: 40),
                  Icon(Icons.flash_off, size: 30, color: Colors.black), // placeholder icon
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: LanguageSelector(),
            ),
          ],
        ),
      ),
    );
  }
}
