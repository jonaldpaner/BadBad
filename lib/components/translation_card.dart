import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String language;
  final String text;
  final VoidCallback? onCopyPressed;
  final VoidCallback? onFavoritePressed;
  final bool isFavorited;  // new param

  const TranslationCard({
    super.key,
    required this.language,
    required this.text,
    this.onCopyPressed,
    this.onFavoritePressed,
    this.isFavorited = false, // default false
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(230, 234, 237, 1),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              language,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Text content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Action buttons
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _iconButton(Icons.content_copy_rounded, onCopyPressed ?? () {}),
                const SizedBox(width: 10),
                _iconButton(
                  isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  onFavoritePressed ?? () {},
                  color: isFavorited ? Colors.black : Colors.black54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onPressed, {Color color = Colors.black54}) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
