import 'package:flutter/material.dart';
import 'package:ahhhtest/pages/favorites_page.dart';
import 'package:ahhhtest/pages/history_page.dart';

class HomeDrawer extends StatelessWidget {
  final bool isLoggedIn;
  final Future<void> Function() onLogout;

  const HomeDrawer({
    Key? key,
    required this.isLoggedIn,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      elevation: 16,
      child: Container(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close Menu',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : const Color.fromRGBO(204, 214, 218, 1),
              thickness: 1.5,
            ),

            ListTile(
              leading: Icon(Icons.favorite_border_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              title: Text('Favorites',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPageWidget(),
                  ),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.history_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              title: Text('Recent History',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryPageWidget(),
                  ),
                );
              },
            ),

            if (isLoggedIn)
              ListTile(
                leading: Icon(Icons.logout,
                  color: isDark ? Colors.white : Colors.black,
                ),
                title: Text('Logout',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () async {
                  await onLogout();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
