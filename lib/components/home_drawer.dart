import 'package:flutter/material.dart';
import 'package:ahhhtest/pages/favorites_page.dart';
import 'package:ahhhtest/pages/history_page.dart';

class HomeDrawer extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onLogout;

  const HomeDrawer({
    Key? key,
    required this.isLoggedIn,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 16,
      child: Container(
        color: Colors.white,
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close Menu',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(
              color: Color.fromRGBO(204, 214, 218, 1),
              thickness: 1.5,
            ),

            // Favorites navigation item
            ListTile(
              leading: const Icon(Icons.favorite_border_rounded),
              title: const Text('Favorites'),
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

            // History navigation item
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Recent History'),
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

            // Only show “Logout” if isLoggedIn == true
            if (isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  onLogout();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
