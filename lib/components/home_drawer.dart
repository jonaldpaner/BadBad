import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ahhhtest/pages/favorites_page.dart';
import 'package:ahhhtest/pages/history_page.dart';

class HomeDrawer extends StatelessWidget {
  final User? currentUser;
  final Future<void> Function() onLogout;

  const HomeDrawer({
    Key? key,
    required this.currentUser,
    required this.onLogout,
  }) : super(key: key);

  bool get _shouldShowLogoutButton => currentUser != null && !currentUser!.isAnonymous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      elevation: 16,
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_pin,
                      size: 60,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentUser?.email ?? 'Guest',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUser != null
                          ? (currentUser!.isAnonymous ? 'Anonymous' : 'Signed In')
                          : 'Not Signed In',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.favorite_border_rounded,
                color: theme.iconTheme.color,
              ),
              title: Text(
                'Favorites',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPageWidget(),
                    ),
                  );
                });
              },
            ),
            ListTile(
              leading: Icon(
                Icons.history_rounded,
                color: theme.iconTheme.color,
              ),
              title: Text(
                'Recent History',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryPageWidget(),
                    ),
                  );
                });
              },
            ),
            if (_shouldShowLogoutButton)
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: theme.iconTheme.color,
                ),
                title: Text(
                  'Logout',
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () async {
                  await onLogout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have been logged out'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
