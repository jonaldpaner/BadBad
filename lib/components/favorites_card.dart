import 'package:flutter/material.dart';

class FavoritesCardWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onTap;

  const FavoritesCardWidget({
    Key? key,
    required this.text,
    this.onLeftPressed,
    this.onFavoritePressed,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final iconBgColor = theme.colorScheme.secondary;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Left icon button (textsms)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: IconButton(
                    onPressed: onLeftPressed,
                    icon: Icon(Icons.textsms_outlined, size: 20, color: textColor),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                // Text message
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Favorite button
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: onFavoritePressed,
                    icon: const Icon(Icons.favorite_rounded),
                    iconSize: 20,
                    color: textColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
