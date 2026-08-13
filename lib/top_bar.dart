import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OrderTypeFilter { all, dineIn, takeaway, online }

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

  // ==========================================================
  // OPTIONAL MENU CALLBACK
  // ==========================================================

  final VoidCallback? onMenuTap;

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

    this.onMenuTap,
  });

  @override
  State<TopBarWidget> createState() =>
      _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {

  // ==========================================================
  // PROFILE
  // ==========================================================

  String _displayName = "IDAA Restaurant";
  String _role = "Manager";

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  // ==========================================================
  // LOAD PROFILE
  // ==========================================================

  Future<void> _loadProfile() async {
    try {
      final prefs =
      await SharedPreferences.getInstance();

      final name =
          prefs.getString("display_name") ??
              prefs.getString("employee_name") ??
              "IDAA Restaurant";

      final role =
          prefs.getString("role") ??
              prefs.getString("employee_role") ??
              "Manager";

      if (!mounted) {
        return;
      }

      setState(() {
        _displayName = name;
        _role = role;
      });
    } catch (e) {
      debugPrint(
        "Failed to load profile in TopBarWidget: $e",
      );
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================


  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xffE4E7EC),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ====================================================
          // HAMBURGER MENU
          // ====================================================

          _buildMenuButton(),

          const SizedBox(width: 12),

          // ====================================================
          // PINAKA LOGO
          // ====================================================

          _buildLogo(),

          // ====================================================
          // SPACE BETWEEN LOGO AND PROFILE
          // ====================================================

          const Spacer(),

          // ====================================================
          // RIGHT DIVIDER
          // ====================================================

          Container(
            width: 1,
            height: 38,
            color: const Color(0xffE4E7EC),
          ),

          const SizedBox(width: 12),

          // ====================================================
          // PROFILE
          // ====================================================

          _buildProfileCard(),
        ],
      ),
    );
  }

  // ==========================================================
  // HAMBURGER BUTTON
  // ==========================================================

  Widget _buildMenuButton() {
    return InkWell(
      onTap: widget.onMenuTap,

      borderRadius:
      BorderRadius.circular(6),

      child: Container(
        width: 34,
        height: 34,

        alignment:
        Alignment.center,

        child: const Icon(
          Icons.menu,
          size: 24,
          color: Color(0xff172033),
        ),
      ),
    );
  }

  // ==========================================================
  // LOGO
  // ==========================================================

  Widget _buildLogo() {
    return SizedBox(
      width: 82,
      height: 44,

      child: Image.asset(
        "assets/pinaka.png",

        height: 44,

        fit: BoxFit.contain,

        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return const Center(
            child: Text(
              "PINAKA",
              style: TextStyle(
                fontWeight:
                FontWeight.w800,
                fontSize: 17,
                letterSpacing: 1.2,
                color:
                Color(0xff2F4376),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // NAVIGATION BUTTON
  // ==========================================================

  Widget _navButton({
    required String title,
    required KotView view,
    required IconData icon,
    required bool isSelected,
    int? count,
    required VoidCallback onTap,
  }) {

    // ========================================================
    // COLORS
    // ========================================================

    const activeColor =
    Color(0xff7C3AED);

    const activeBackground =
    Color(0xffF0EEFF);

    const activeBorder =
    Color(0xffDCD6FF);

    const inactiveText =
    Color(0xff64748B);

    const inactiveIcon =
    Color(0xff94A3B8);

    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 150,
        ),

        margin:
        const EdgeInsets.symmetric(
          horizontal: 3,
        ),

        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),

        decoration: BoxDecoration(
          color: isSelected
              ? activeBackground
              : Colors.transparent,

          borderRadius:
          BorderRadius.circular(7),

          border: Border.all(
            color: isSelected
                ? activeBorder
                : Colors.transparent,

            width: 1,
          ),
        ),

        child: Row(
          mainAxisSize:
          MainAxisSize.min,

          crossAxisAlignment:
          CrossAxisAlignment.center,

          children: [

            // ==================================================
            // ICON
            // ==================================================

            Icon(
              icon,

              size: 17,

              color: isSelected
                  ? activeColor
                  : inactiveIcon,
            ),

            const SizedBox(width: 6),

            // ==================================================
            // TITLE
            // ==================================================

            Text(
              title,

              style: TextStyle(
                color: isSelected
                    ? activeColor
                    : inactiveText,

                fontWeight:
                FontWeight.w600,

                fontSize: 13,
              ),
            ),

            // ==================================================
            // COUNT
            // ==================================================

            if (count != null) ...[
              const SizedBox(width: 6),

              Container(
                height: 19,

                constraints:
                const BoxConstraints(
                  minWidth: 19,
                ),

                alignment:
                Alignment.center,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 5,
                ),

                decoration:
                BoxDecoration(
                  color: isSelected
                      ? activeColor
                      : const Color(
                    0xffE2E8F0,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),

                child: Text(
                  "$count",

                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : inactiveText,

                    fontSize: 10,

                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LOGOUT BUTTON
  // ==========================================================

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: widget.onLogout,

      child: Container(
        height: 42,

        padding:
        const EdgeInsets.symmetric(
          horizontal: 13,
        ),

        decoration: BoxDecoration(
          color:
          const Color(0xffFF5B4F),

          borderRadius:
          BorderRadius.circular(7),
        ),

        child: Row(
          mainAxisSize:
          MainAxisSize.min,

          children: [

            const Icon(
              Icons.logout,
              color: Colors.white,
              size: 15,
            ),

            const SizedBox(width: 5),

            const Text(
              "Logout",

              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PROFILE CARD
  // ==========================================================

  Widget _buildProfileCard() {
    return Container(
      height: 42,

      constraints:
      const BoxConstraints(
        minWidth: 145,
      ),

      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(8),

        border: Border.all(
          color:
          const Color(0xffE2E8F0),
          width: 1,
        ),
      ),

      child: Row(
        mainAxisSize:
        MainAxisSize.min,

        crossAxisAlignment:
        CrossAxisAlignment.center,

        children: [

          // ==================================================
          // PROFILE IMAGE
          // ==================================================

          Container(
            width: 27,
            height: 27,

            clipBehavior:
            Clip.antiAlias,

            decoration:
            const BoxDecoration(
              shape: BoxShape.circle,

              color:
              Color(0xffF1F5F9),
            ),

            child: Image.asset(
              "assets/chef.png",

              fit: BoxFit.cover,

              errorBuilder: (
                  context,
                  error,
                  stackTrace,
                  ) {
                return const Icon(
                  Icons.person,
                  size: 17,
                  color:
                  Color(0xff64748B),
                );
              },
            ),
          ),

          const SizedBox(width: 7),

          // ==================================================
          // NAME + ROLE
          // ==================================================

          Flexible(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              mainAxisAlignment:
              MainAxisAlignment.center,

              children: [

                // --------------------------------------------
                // NAME
                // --------------------------------------------

                Text(
                  _displayName,

                  maxLines: 1,

                  overflow:
                  TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xff1E293B),
                  ),
                ),

                const SizedBox(height: 1),

                // --------------------------------------------
                // ROLE
                // --------------------------------------------

                Text(
                  _formattedRole(),

                  maxLines: 1,

                  overflow:
                  TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 8,
                    color:
                    Color(0xff64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FORMAT ROLE
  // ==========================================================

  String _formattedRole() {
    if (_role
        .toLowerCase()
        .startsWith("role-")) {
      return _role;
    }

    return "role- $_role";
  }
}