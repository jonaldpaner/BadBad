import 'package:flutter/material.dart';

class FavoritesCardWidget extends StatelessWidget {
  const FavoritesCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.fromRGBO(230, 234, 237, 1),
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
                  color: Color.fromRGBO(204, 214, 218, 0.64),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  onPressed: () {
                    print('Left button pressed ...');
                  },
                  icon: const Icon(Icons.textsms_outlined, size: 20),
                  color: Colors.black,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 12),
              // Text message
              Expanded(
                child: Text(
                  'Hello, how are you today?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF14181B),
                    fontSize: 16,
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
                  color: Color.fromRGBO(230, 234, 237, 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    print('Favorite button pressed ...');
                  },
                  icon: const Icon(Icons.favorite_border_rounded),
                  iconSize: 20,
                  color: theme.textTheme.bodyLarge?.color,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
