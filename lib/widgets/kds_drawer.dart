import 'package:flutter/material.dart';

class KdsDrawer extends StatelessWidget {
  final VoidCallback? onDashboard;
  final VoidCallback? onSelectItemCategory;
  final VoidCallback? onStock;
  final VoidCallback? onRecall;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  const KdsDrawer({
    super.key,
    this.onDashboard,
    this.onSelectItemCategory,
    this.onStock,
    this.onRecall,
    this.onSettings,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [

            // ==================================================
            // HEADER
            // ==================================================

            Container(
              height: 65,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xffE4E7EC),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [

                  Expanded(
                    child: Image.asset(
                      'assets/pinaka.png',
                      height: 42,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (
                          context,
                          error,
                          stackTrace,
                          ) {
                        return const Text(
                          'PINAKA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff2F4376),
                          ),
                        );
                      },
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.chevron_left,
                        size: 26,
                        color: Color(0xff667085),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // MENU ITEMS
            // ==================================================

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  10,
                  12,
                  10,
                  10,
                ),
                child: Column(
                  children: [

                    _menuItem(
                      title: 'KDS Dashboard',
                      icon: Icons.grid_view_rounded,
                      onTap: onDashboard,
                    ),

                    const SizedBox(height: 7),

                    _menuItem(
                      title: 'Select Item / Category',
                      icon: Icons.format_list_bulleted,
                      onTap: onSelectItemCategory,
                    ),

                    const SizedBox(height: 7),

                    _menuItem(
                      title: 'Stock',
                      icon: Icons.inventory_2_outlined,
                      onTap: onStock,
                    ),

                    const SizedBox(height: 7),

                    _menuItem(
                      title: 'Recall',
                      icon: Icons.refresh,
                      onTap: onRecall,
                      isSelected: true,
                    ),

                    const SizedBox(height: 7),

                    _menuItem(
                      title: 'Settings',
                      icon: Icons.settings_outlined,
                      onTap: onSettings,
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // LOGOUT
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                10,
                10,
                15,
              ),
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 44,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xffffefec),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xffffa69b),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        size: 17,
                        color: Color(0xffff4f3d),
                      ),

                      SizedBox(width: 7),

                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffff4f3d),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xffff5b4f)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [

            Icon(
              icon,
              size: 19,
              color: isSelected
                  ? Colors.white
                  : const Color(0xff64748B),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xff1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}