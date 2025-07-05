import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String language;
  final String text;
  final VoidCallback? onCopyPressed;
  final VoidCallback? onFavoritePressed;
  final bool isFavorited;
  final bool isLoading; // New property to indicate loading state for the text

  const TranslationCard({
    super.key,
    required this.language,
    required this.text,
    this.onCopyPressed,
    this.onFavoritePressed,
    this.isFavorited = false,
    this.isLoading = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              language,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 200, // minimum height to push text down a bit
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isLoading // Check the new isLoading flag
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skeleton lines
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: constraints.maxWidth * 0.7, // Shorter last line
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  )
                      : Text(
                    text,
                    textAlign: TextAlign.justify,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _iconButton(
                  Icons.content_copy_rounded,
                  onCopyPressed ?? () {},
                  theme.iconTheme.color ?? Colors.black54,
                ),
                if (onFavoritePressed != null) ...[
                  const SizedBox(width: 10),
                  _iconButton(
                    isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    onFavoritePressed!,
                    isFavorited
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : (theme.iconTheme.color ?? Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onPressed, Color color) {
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