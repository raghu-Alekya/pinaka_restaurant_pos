import 'package:flutter/material.dart';

/// A custom AppBar widget with a logo, search box, action buttons,
/// and profile section including a mode toggle and notification icon.
class TopBar extends StatefulWidget implements PreferredSizeWidget {
  /// The preferred height of the AppBar.
  @override
  Size get preferredSize => Size.fromHeight(100);

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  /// Tracks the current mode state (true for light mode, false for dark mode).
  bool isLightMode = true;

  /// Toggles the mode state between light and dark.
  void toggleMode() {
    setState(() {
      isLightMode = !isLightMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AppBar(
      backgroundColor: Colors.white,
      toolbarHeight: 90,
      automaticallyImplyLeading: false,
      titleSpacing: 0,

      /// The main content of the AppBar, scrollable horizontally to
      /// accommodate smaller screens.
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(width: 10),

            /// Logo image
            Image.asset(
              'assets/pinaka.png',
              height: 60,
              width: 55,
            ),
            SizedBox(width: 25),

            /// Search box with icon and text field
            Container(
              width: screenWidth * 0.37,
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

            SizedBox(width: 40),

            /// Buttons for actions: Reserved table, Transfer table, Merge table
            _buildTopBarButton('+ Reserved table'),
            SizedBox(width: 20),
            _buildTopBarButton('Transfer table'),
            SizedBox(width: 20),
            _buildTopBarButton('Merge table'),

            SizedBox(width: 45),

            /// Profile section including mode toggle, user info and notification
            _buildProfileSection(),
          ],
        ),
      ),
    );
  }

  /// Helper to build an outlined button with the given label.
  Widget _buildTopBarButton(String label) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: () {
        // Action handler for button press can be added here.
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  /// Builds the profile section on the right side of the TopBar
  /// including mode toggle, user avatar & name, and notification icon.
  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Align children to bottom
        children: [

          /// Mode toggle button (custom double triangle icon)
          GestureDetector(
            onTap: toggleMode,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 7,
                      height: 16,
                      child: CustomPaint(
                        painter: TrianglePainter(
                          isLeft: true,
                          fillColor: isLightMode ? Colors.white : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    SizedBox(width: 2),
                    SizedBox(
                      width: 7,
                      height: 16,
                      child: CustomPaint(
                        painter: TrianglePainter(
                          isLeft: false,
                          fillColor: isLightMode ? Color(0xFF999393) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  "Mode",
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFA19999),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 10),

          /// Profile avatar and user information
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Mohan Krishna",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    Text("I am manager",
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 15),

          /// Notification icon with red badge indicator
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
                  ],
                ),
                child: Icon(
                  Icons.notifications_none_outlined,
                  size: 23,
                  color: Colors.black,
                ),
              ),
              Positioned(
                right: 14,
                top: 12,
                child: Container(
                  width: 5,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

/// Custom painter to draw a triangle shape.
///
/// Used in the mode toggle button to visually represent left and right triangles.
class TrianglePainter extends CustomPainter {
  /// If true, draws a left-pointing triangle; otherwise, right-pointing.
  final bool isLeft;

  /// The fill color of the triangle.
  final Color fillColor;

  TrianglePainter({required this.isLeft, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    Path path = Path();

    // Draw left or right triangle based on isLeft flag
    if (isLeft) {
      path.moveTo(size.width - 1, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width - 1, size.height);
    } else {
      path.moveTo(1, 0); // inward by 1px to avoid overlapping border
      path.lineTo(size.width, size.height / 2);
      path.lineTo(1, size.height);
    }

    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
