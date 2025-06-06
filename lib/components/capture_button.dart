import 'package:flutter/material.dart';

class CaptureButton extends StatelessWidget {
  final VoidCallback onTap;
  const CaptureButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[400],
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }
}
