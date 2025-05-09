import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../widgets/CreateTableWidget.dart';
import '../widgets/add_table_popup.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav_bar.dart';

class TablesScreen extends StatefulWidget {
  @override
  _TablesScreenState createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  double _scale = 1.0;
  int _selectedIndex = 0;
  bool _showPopup = false;
  String? _areaName;
  List<Widget> placedTables = [];


  void _zoomIn() {
    setState(() {
      _scale += 0.1;
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale - 0.1).clamp(0.5, 3.0);
    });
  }

  void _scaleToFit() {
    setState(() {
      _scale = 1.0;
    });
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _togglePopup() {
    setState(() {
      _showPopup = !_showPopup;
    });
  }

  void _setAreaName(String name) {
    setState(() {
      _areaName = name.isNotEmpty ? name : null;
    });
  }

  void _removeArea() {
    setState(() {
      _areaName = null;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: TopBar(),
      ),
      body: Stack(
        children: [
          if (!_showPopup)
            Center(
              child: Transform.scale(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 120),
                    Text(
                      'Start by adding your first table\nor seating area.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    DottedBorder(
                      color: Colors.grey,
                      strokeWidth: 1,
                      borderType: BorderType.RRect,
                      radius: Radius.circular(20),
                      dashPattern: [6, 4],
                      child: InkWell(
                        onTap: _togglePopup,
                        child: Container(
                          padding: EdgeInsets.all(30),
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F3F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 40, color: Colors.blueGrey),
                                SizedBox(height: 8),
                                Text('Add table',
                                    style: TextStyle(fontSize: 20, color: Colors.blueGrey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Zoom Controls
          Positioned(
            bottom: 140,
            left: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _zoomButton(icon: Icons.add, onTap: _zoomIn),
                SizedBox(height: 10),
                _zoomButton(icon: Icons.remove, onTap: _zoomOut),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      child: _zoomButton(icon: Icons.fit_screen, onTap: _scaleToFit),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Scaled to fit",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4C5F7D),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),


          // Slide-in Popup
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 0,
            right: _showPopup ? 0 : -MediaQuery.of(context).size.width,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.34,
            child: CreateTableWidget(
              onClose: _togglePopup,
            ),
          ),

          BottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onNavItemTapped,
          ),
        ],
      ),
    );
  }

  Widget _zoomButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }
}