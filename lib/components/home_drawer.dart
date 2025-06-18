import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to access User
import 'package:ahhhtest/pages/favorites_page.dart';
import 'package:ahhhtest/pages/history_page.dart';

class HomeDrawer extends StatelessWidget {
  final User? currentUser; // Change from bool isLoggedIn to User? currentUser
  final Future<void> Function() onLogout;

  const HomeDrawer({
    Key? key,
    required this.currentUser, // Now takes currentUser directly
    required this.onLogout,
  }) : super(key: key);

  // Helper getter to determine if the logout button should be shown
  // It shows if a user is logged in AND they are NOT anonymous.
  bool get _shouldShowLogoutButton => currentUser != null && !currentUser!.isAnonymous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme here
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      elevation: 16, // Made const
      child: Container(
        color: theme.scaffoldBackgroundColor, // Use theme for background color (e.g., white in light mode)
        child: Column(
          children: [
            // Drawer Header (Updated for consistent background and left alignment)
            DrawerHeader(
              decoration: BoxDecoration(
                // Use consistent white for light mode, or grey for dark mode
                color: isDark ? Colors.grey[800] : Colors.white,
              ),
              child: Align( // Use Align to ensure content is pushed to start
                alignment: Alignment.bottomLeft, // Align content to bottom-left
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Ensure content is left-aligned
                  mainAxisSize: MainAxisSize.min, // Wrap content tightly
                  children: [
                    Icon(
                      Icons.person_pin,
                      size: 60, // Made const
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    const SizedBox(height: 8), // Made const
                    Text(
                      // Display user email if available, otherwise "Guest"
                      currentUser?.email ?? 'Guest',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold, // Made const
                      ),
                    ),
                    Text(
                      // Display "Anonymous" or "Signed In" status
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

            // Removed the Divider as requested

            ListTile(
              leading: Icon(Icons.favorite_border_rounded,
                color: theme.iconTheme.color, // Use theme icon color
              ),
              title: Text('Favorites',
                style: theme.textTheme.bodyLarge, // Use theme text style
              ),
              onTap: () {
                Navigator.pop(context); // Pop the drawer first
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPageWidget(), // Made const
                    ),
                  );
                });
              },
            ),

            ListTile(
              leading: Icon(Icons.history_rounded,
                color: theme.iconTheme.color, // Use theme icon color
              ),
              title: Text('Recent History',
                style: theme.textTheme.bodyLarge, // Use theme text style
              ),
              onTap: () {
                Navigator.pop(context); // Pop the drawer first
                Future.delayed(const Duration(milliseconds: 200), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryPageWidget(), // Made const
                    ),
                  );
                });
              },
            ),

            // Conditionally show the Logout button
            if (_shouldShowLogoutButton) // Use the new getter here
              ListTile(
                leading: Icon(Icons.logout,
                  color: theme.iconTheme.color, // Use theme icon color
                ),
                title: Text('Logout',
                  style: theme.textTheme.bodyLarge, // Use theme text style
                ),
                onTap: () async {
                  await onLogout();
                },
              ),
          ],
        ),
      ),
    );
  }
}
