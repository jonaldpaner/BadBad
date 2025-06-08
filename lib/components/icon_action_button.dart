import 'package:flutter/material.dart';

class IconActionButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const IconActionButton({
    Key? key,
    required this.icon,
    required this.size,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.secondary,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: size, color: theme.iconTheme.color),
      ),
    );
  }
}
