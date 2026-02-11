import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/employee_repository.dart';
import '../ui/CheckinPopup.dart';
import '../ui/DailyAttendanceScreen.dart';
import '../ui/SettingsScreen.dart';
import '../ui/employee_login_page.dart';
import 'LogoutConfirmationDialog.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String token;
  final String pin;
  final UserPermissions? userPermissions;
  final Function(UserPermissions)? onPermissionsReceived;

  const TopBar({
    Key? key,
    required this.token,
    required this.pin,
    this.userPermissions,
    this.onPermissionsReceived, Map<String, dynamic>? selectedUser,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  bool isLightMode = true;

  void toggleMode() {
    setState(() {
      isLightMode = !isLightMode;
    });
  }

  bool _isAttendanceDialogOpen = false;

  void _handlePermissions(UserPermissions permissions) {
    setState(() {
      _permissions = permissions;
    });
    widget.onPermissionsReceived?.call(permissions);
  }

  bool _isCheckInDone = false;
  UserPermissions? _permissions;

  @override
  Size get preferredSize => Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.3 * 255).toInt()),
            spreadRadius: 0,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0.0,
        titleSpacing: 0,
        title:Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              /// LEFT SIDE — Logo
              Image.asset(
                'assets/pinaka.png',
                height: 40,
                width: 100,
                fit: BoxFit.contain,
              ),

              const SizedBox(width: 15),

              /// (Optional) Search box here later 👈

              /// PUSH EVERYTHING ELSE TO RIGHT
              const Spacer(),

              /// RIGHT SIDE — ACTIONS
              // _buildExitIconButton(),
              // const SizedBox(width: 10),

              if (widget.userPermissions?.canUpdateShiftAttendance ?? false) ...[
                _buildAttendanceIconButton(context),
                const SizedBox(width: 10),
              ],
              _buildExitIconButton(),
              const SizedBox(width: 10),

              _buildNotificationIconButton(),
              const SizedBox(width: 10),

              _buildIconButton(
                label: "Settings",
                color: const Color(0xFF4CAF50),
                icon: Image.asset(
                  'assets/setting.png', // 👈 your asset path
                  width: 20,
                  height: 20,
                  color: const Color(0xFF4CAF50), // optional (remove if image already colored)
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        token: widget.token,
                        pin: widget.pin,
                        userId: widget.userPermissions?.userId ?? '',
                        displayName: widget.userPermissions?.displayName ?? '',
                        role: widget.userPermissions?.role ?? '',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 10),

    _buildIconButton(
    label: "Logout",
    color: const Color(0xFFFF9800),
    icon: Image.asset(
    'assets/logout.png',
    width: 24,
    height: 24,
    color: const Color(0xFFFF9800),
    ),
    onPressed: () async {
    final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => LogoutConfirmationDialog(
    onCancel: () => Navigator.pop(context, false),
    onConfirm: () => Navigator.pop(context, true),
    ),
    );

    if (result != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final authRepository = AuthRepository();
    final success = await authRepository.logout(token);

    if (!context.mounted) return;

    if (success) {
    Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
    builder: (_) => const EmployeeLoginPage(),
    ),
    (route) => false,
    );
    } else {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
    content: Text('Logout failed. Please try again.'),
    ),
    );
    }
    },
    ),


    const SizedBox(width: 10),

              /// PROFILE — LAST (Right aligned)
              _buildProfileSection(),
            ],
          ),
        )

      ),
    );
  }

  Widget _buildAttendanceIconButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isAttendanceDialogOpen) return;

        setState(() {
          _isAttendanceDialogOpen = true;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final repository = EmployeeRepository();
          final response = await repository.getAllEmployees(widget.token);

          final List<Employee> employees = response.map((e) {
            return Employee(
              id: e['ID'].toString(),
              name: e['name'].toString(),
            );
          }).toList();

          final currentShift =
          await repository.getCurrentShift(widget.token);

          if (currentShift != null) {
            final presentIds =
            List<int>.from(currentShift['shift_emp'] ?? []);
            final absentIds =
            List<int>.from(currentShift['shift_absent_emp'] ?? []);

            for (var emp in employees) {
              final empId = int.tryParse(emp.id);
              if (presentIds.contains(empId)) {
                emp.status = 'Present';
              } else if (absentIds.contains(empId)) {
                emp.status = 'Absent';
              } else {
                emp.status = '';
              }
            }
          }

          if (context.mounted) {
            Navigator.pop(context);

            final shiftData =
            await EmployeeRepository().getCurrentShift(widget.token);

            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AttendancePopup(
                token: widget.token,
                employees: employees,
                isUpdateMode: true,
                currentShiftData: shiftData,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to load employees')),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isAttendanceDialogOpen = false;
            });
          }
        }
      },

      /// ✅ NEW DASHBOARD TILE UI
      child: _buildIconButton(
        label: "Attendance",
        color: const Color(0xFF4F7CFF),
        icon: Image.asset(
          'assets/attendance.png',
          width: 20,
          height: 20,
          color: const Color(0xFF4F7CFF),
        ),
      ),
    );
  }


  Widget _buildExitIconButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Checkinpopup(
            token: widget.token,
            onCheckIn: () {
              Navigator.of(context).pop();
              setState(() {
                _isCheckInDone = true;
              });
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
            onPermissionsReceived: (permissions) {
              _handlePermissions(permissions);
            },
          ),
        );
      },

      /// ✅ DASHBOARD TILE UI
      child: _buildIconButton(
        label: "CheckIn",
        color: const Color(0xFFFF5A3C),
        icon: Image.asset(
          'assets/checkin.png', // or checkin icon if you have
          width: 20,
          height: 20,
          color: const Color(0xFFFF5A3C),
        ),
      ),
    );
  }

  // Widget _buildModeToggle() {
  //   return GestureDetector(
  //     onTap: toggleMode,
  //     child: Container(
  //       width: 34,
  //       height: 34,
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         shape: BoxShape.circle,
  //         boxShadow: [
  //           BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
  //         ],
  //       ),
  //       child: Center(
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             CustomPaint(
  //               size: Size(7, 14),
  //               painter: TrianglePainter(
  //                 isLeft: true,
  //                 fillColor: isLightMode ? Colors.white : Colors.black,
  //               ),
  //             ),
  //             SizedBox(width: 4),
  //             CustomPaint(
  //               size: Size(7, 14),
  //               painter: TrianglePainter(
  //                 isLeft: false,
  //                 fillColor: isLightMode ? Colors.black : Colors.white,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildNotificationIconButton({VoidCallback? onPressed}) {
    return _buildIconButton(
      label: "Notification",
      color: const Color(0xFFFFC107),
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_outlined,
            size: 24,
            color: Color(0xFFFFC107),
          ),

          /// 🔴 Notification Dot
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildIconButton({
    required Widget icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 65, // ⬅ slightly wider like image
        height: 55,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          // border: Border.all(
          //   color: color.withOpacity(0.35),
          //   width: 1,
          // ),
          boxShadow: [
            /// MAIN soft shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),

            /// COLORED glow shadow (very subtle)
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProfileSection() {
    final avatarUrl = widget.userPermissions?.avatar;

    return Container(
      height: 55, // matches image height
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14), // 🔥 rectangle with rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : const AssetImage('assets/loginname.png') as ImageProvider,
          ),

          const SizedBox(width: 12),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userPermissions?.displayName ?? "username",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.userPermissions?.role ?? "role",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }




}
class TrianglePainter extends CustomPainter {
  final bool isLeft;
  final Color fillColor;
  final Color borderColor;

  TrianglePainter({
    required this.isLeft,
    required this.fillColor,
    this.borderColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}