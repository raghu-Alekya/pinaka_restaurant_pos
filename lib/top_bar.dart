import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OrderTypeFilter {
  all,
  dineIn,
  takeaway,
  online,
}

enum KotView {
  pending,
  active,
  repeated,
  history,
}

class TopBarWidget extends StatefulWidget {
  final String token;
  final int restaurantId;
  final KotView selectedView;
  final ValueChanged<KotView> onViewChanged;
  final VoidCallback? onLogout;
  final int pendingCount;
  final int activeCount;
  final int repeatedCount;

  const TopBarWidget({
    super.key,
    required this.token,
    required this.restaurantId,
    required this.selectedView,
    required this.onViewChanged,
    this.onLogout,
    this.pendingCount = 0,
    this.activeCount = 0,
    this.repeatedCount = 0,
  });

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  String _displayName = "Mohan Krishna";
  String _role = "I am manager";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString("display_name") ?? prefs.getString("employee_name") ?? "Mohan Krishna";
      final role = prefs.getString("role") ?? prefs.getString("employee_role") ?? "I am manager";
      if (mounted) {
        setState(() {
          _displayName = name;
          _role = role;
        });
      }
    } catch (e) {
      debugPrint("Failed to load profile in TopBarWidget: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xffe2e8f0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo Section
          Image.asset(
            "assets/pinaka_logo.png",
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                "PINAKA",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Color(0xff2F4376),
                ),
              );
            },
          ),
          
          const Spacer(),

          // Navigation buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navButton(
                title: "Pending KOTs",
                view: KotView.pending,
                icon: Icons.format_list_bulleted,
                isSelected: widget.selectedView == KotView.pending,
                count: widget.pendingCount,
                onTap: () => widget.onViewChanged(KotView.pending),
              ),
              _navButton(
                title: "Active KOTs",
                view: KotView.active,
                icon: Icons.cached,
                isSelected: widget.selectedView == KotView.active,
                count: widget.activeCount,
                onTap: () => widget.onViewChanged(KotView.active),
              ),
              _navButton(
                title: "Repeated Items",
                view: KotView.repeated,
                icon: Icons.sync,
                isSelected: widget.selectedView == KotView.repeated,
                count: widget.repeatedCount,
                onTap: () => widget.onViewChanged(KotView.repeated),
              ),
              _navButton(
                title: "KOT History",
                view: KotView.history,
                icon: Icons.history,
                isSelected: widget.selectedView == KotView.history,
                onTap: () => widget.onViewChanged(KotView.history),
              ),
            ],
          ),

          const Spacer(),

          // Logout Button
          GestureDetector(
            onTap: widget.onLogout,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xffFF5B4F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // User Profile Section
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xffe2e8f0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xfff1f5f9),
                  backgroundImage: const AssetImage("assets/chef.png"),
                  child: const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1e293b),
                      ),
                    ),
                    Text(
                      _role,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xff64748b),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required String title,
    required KotView view,
    required IconData icon,
    required bool isSelected,
    int? count,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xff7C3AED);
    final inactiveTextColor = const Color(0xff64748b);
    final inactiveIconColor = const Color(0xff94a3b8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffF0EEFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xffDCD6FF) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : inactiveIconColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : const Color(0xffe2e8f0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    color: isSelected ? Colors.white : inactiveTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}