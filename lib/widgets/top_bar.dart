import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return AppBar(
      backgroundColor: Colors.white,
      toolbarHeight: 110,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(width: 30),

            // Logo
            Image.asset('assets/Pinaka.png', height: 40),

            SizedBox(width: 40),

            /// Search Box
            Container(
              width: screenWidth * 0.38,
              height: 45,
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

            SizedBox(width: 55),

            _buildTopBarButton('+ Reserved table'),
            SizedBox(width: 25),
            _buildTopBarButton('Transfer table'),
            SizedBox(width: 25),
            _buildTopBarButton('Merge table'),

            SizedBox(width: 60),

            _buildProfileSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBarButton(String label) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: () {},
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Row(
          children: [
            GestureDetector(
              onTap: toggleMode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 26,
                    child: CustomPaint(
                      painter: TrianglePainter(
                        isLeft: true,
                        fillColor: isLightMode ? Colors.white : Colors.grey
                            .shade400,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  SizedBox(
                    width: 14,
                    height: 26,
                    child: CustomPaint(
                      painter: TrianglePainter(
                        isLeft: false,
                        fillColor: isLightMode ? Colors.grey.shade400 : Colors
                            .white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),

            /// Profile Info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/loginname.png'),
                    radius: 16,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mohan Krishna",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Text("I am manager",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),

            /// Notification icon
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
                    size: 24,
                    color: Colors.black,
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
        Text(
          "Mode",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

  /// Custom triangle painter
class TrianglePainter extends CustomPainter {
  final bool isLeft;
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

    // Inside TrianglePainter
    if (isLeft) {
      path.moveTo(size.width - 1, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width - 1, size.height);
    } else {
      path.moveTo(1, 0); // inward by 1px
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
