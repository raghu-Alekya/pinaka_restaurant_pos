import 'package:flutter/material.dart';
import '../../models/theme/theme_model.dart';
// import '../models/theme/theme_model.dart';

class TopBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const TopBarWidget({super.key, required String token, required String restaurantId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      toolbarHeight: 100,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // App logo
            Image.asset('assets/icon/logo.png', height: 40),
            const SizedBox(width: 20),

            // 🔍 Search Box
            Expanded(
              flex: 3,
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFECEBEB)),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFFA19999), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: Color(0xFFA19999),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search item or short code....',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // 👉 Action Icons
            _iconButton('assets/icon/mode2.png', 'mode2', () {
              // Your download logic here
              print('mode 2 tapped');
            }),
            const SizedBox(width: 12),

            _iconButton('assets/icon/settings.png', 'Settings', () {
              // Open settings
              print('Settings tapped');
            }),
            const SizedBox(width: 12),

            _iconButton('assets/icon/notification.png', 'Notifications', () {
              // Show notifications
              print('Notifications tapped');
            }),
            const SizedBox(width: 12),

            _iconButton('assets/icon/light.png', 'Theme', () {
              // Toggle theme
              ThemeController.toggleTheme();
            }),
            const SizedBox(width: 12),

            _iconButton('assets/icon/logout-02.png', 'Logout', () {
              _showLogoutDialog(context);
            }),

            const SizedBox(width: 20),

            _buildProfileSection(),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(String iconPath, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 35,
          height:35,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
          ),
          child: Image.asset(iconPath),
        ),
      ),
    );
  }
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Add logout logic
                print('User logged out');
              },
              child: const Text('Logout')),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/icon/loginname.png'),
                radius: 16,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("A Raghav Kumar",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  Text("I am Captain",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }



  @override
  Size get preferredSize => const Size.fromHeight(100);
}
