import 'package:flutter/material.dart';

import '../ui/CheckinPopup.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(100);

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

    return AppBar(
      backgroundColor:Colors.white,
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

            SizedBox(width: 160),

            /// Icon Buttons
            _buildModeToggle(),
            SizedBox(width: 15),
            _buildIconButton(Icons.light_mode),
            SizedBox(width: 15),
            _buildExitIconButton(),
            SizedBox(width: 15),
            _buildNotificationIconButton(),
            SizedBox(width: 15),
            _buildIconButton(Icons.settings),
            SizedBox(width: 15),
            _buildIconButton(Icons.sync),

            SizedBox(width: 25),

            /// Profile Info
            _buildProfileSection(),
            SizedBox(width: 20),
          ],
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
          builder: (context) => const Checkinpopup(),
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

  /// Builds the custom mode toggle button
  Widget _buildModeToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isLightMode = !isLightMode;
        });
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
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left Triangle
              CustomPaint(
                size: Size(7, 14),
                painter: TrianglePainter(
                  isLeft: true,
                  fillColor: isLightMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(width: 4),
              // Right Triangle
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
        // Base Icon Button
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_none_outlined,
            size: 20,
            color: Colors.black,
          ),
        ),
        // Red Dot Badge
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }



  /// Builds a circular icon button matching the uploaded image
  Widget _buildIconButton(IconData icon) {
    return Container(
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
    );
  }

  /// Builds the profile section on the right
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

    // Fill the triangle
    canvas.drawPath(path, paint);
    // Draw the border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}