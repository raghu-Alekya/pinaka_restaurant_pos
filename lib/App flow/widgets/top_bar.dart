import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../repositories/employee_repository.dart';
import '../ui/CheckinPopup.dart';
import '../ui/DailyAttendanceScreen.dart';
import '../ui/employee_login_page.dart';
import 'LogoutConfirmationDialog.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String token;
  final String pin;

  const TopBar({Key? key, required this.token, required this.pin}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(100);

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
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              /// Logo
              Image.asset(
                'assets/pinaka.png',
                height: 40,
                width: 100,
                fit: BoxFit.contain,
              ),

              SizedBox(width: 15),

              /// Search Box
              Container(
                width: screenWidth * 0.40,
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFFECEBEB)),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFFA19999), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: Color(0xFFA19999),
                          fontSize: 12,
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

              SizedBox(width: 140),

              /// Icon Buttons
              _buildModeToggle(),
              SizedBox(width: 15),
              _buildIconButton(Icons.light_mode),
              SizedBox(width: 15),
              _buildExitIconButton(),
              SizedBox(width: 15),
              _buildAttendanceIconButton(context),
              SizedBox(width: 15),
              _buildNotificationIconButton(),
              SizedBox(width: 15),
              _buildIconButton(Icons.settings),
              SizedBox(width: 15),
              _buildIconButton(Icons.logout, onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => LogoutConfirmationDialog(
                    onCancel: () => Navigator.pop(context, false),
                    onConfirm: () => Navigator.pop(context, true),
                  ),
                );

                if (result == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const EmployeeLoginPage()),
                          (route) => false,
                    );
                  }
                }
              }),
              SizedBox(width: 25),

              /// Profile Info
              _buildProfileSection(),
              SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAttendanceIconButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          final repository = EmployeeRepository();
          final response = await repository.getAllEmployees(widget.token);
          final List<Employee> employees = response.map((e) {
            return Employee(
              id: e['ID'].toString(),
              name: e['name'].toString(),
            );
          }).toList();
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => AttendancePopup(
                token: widget.token,
                employees: employees,
                isUpdateMode: true,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load employees')),
            );
          }
        }
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(7.0),
          child: Image.asset(
            'assets/attendance.png',
            fit: BoxFit.contain,
          ),
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
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(7.0),
          child: Image.asset(
            'assets/logout.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return GestureDetector(
      onTap: toggleMode,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: Size(7, 14),
                painter: TrianglePainter(
                  isLeft: true,
                  fillColor: isLightMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(width: 4),
              CustomPaint(
                size: Size(7, 14),
                painter: TrianglePainter(
                  isLeft: false,
                  fillColor: isLightMode ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIconButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
            ],
          ),
          child: Icon(
            Icons.notifications_none_outlined,
            size: 20,
            color: Colors.black,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, {VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 7),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage('assets/loginname.png'),
            radius: 14,
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "A Raghu Kumar",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Live Captain",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
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