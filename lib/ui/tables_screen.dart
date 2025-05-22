import 'dart:math';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../widgets/CreateTableWidget.dart';
import '../widgets/TablePlacementWidget.dart';
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
  Set<String> _usedTableNames = {};
  Set<String> _usedAreaNames = {};
  String? selectedArea;

  List<Map<String, dynamic>> placedTables = [];


  void _zoomIn() => setState(() => _scale += 0.1);
  void _zoomOut() => setState(() => _scale = (_scale - 0.1).clamp(0.5, 3.0));
  void _scaleToFit() => setState(() => _scale = 1.0);
  void _onNavItemTapped(int index) => setState(() => _selectedIndex = index);
  void _togglePopup() {
    setState(() {
      _showPopup = !_showPopup;
    });
  }

  bool _isOverlapping(Offset newPos, Size newSize, {int? skipIndex, String? areaName}) {
    const double tablePadding = 13.0;
    const double chairClearance = 17.0;

    final totalBuffer = tablePadding + chairClearance;

    final newRect = Rect.fromLTWH(
      newPos.dx - totalBuffer,
      newPos.dy - totalBuffer,
      newSize.width + totalBuffer * 2,
      newSize.height + totalBuffer * 2,
    );

    for (int i = 0; i < placedTables.length; i++) {
      if (i == skipIndex) continue;

      final table = placedTables[i];

      if (areaName != null && table['areaName'] != areaName) {
        continue;
      }

      final existingPos = table['position'] as Offset;
      final shape = table['shape'] as String;
      final capacity = table['capacity'];
      final existingSize = _getPlacedTableSize(capacity, shape);

      final existingRect = Rect.fromLTWH(
        existingPos.dx - totalBuffer,
        existingPos.dy - totalBuffer,
        existingSize.width + totalBuffer * 2,
        existingSize.height + totalBuffer * 2,
      );

      if (newRect.overlaps(existingRect)) return true;
    }

    return false;
  }

  Offset _findNonOverlappingPosition(Offset pos, Size size, {int? skipIndex, String? areaName}) {
    const int maxAttempts = 1000;
    const double step = 27.0;

    Offset current = pos;
    int dx = 0, dy = 0;
    int segmentLength = 1;
    int xDir = 1, yDir = 0;

    for (int i = 0; i < maxAttempts; i++) {
      if (!_isOverlapping(current, size, skipIndex: skipIndex, areaName: areaName)) {
        return current;
      }

      current = Offset(pos.dx + dx * step, pos.dy + dy * step);

      if (i % segmentLength == 0) {
        final temp = xDir;
        xDir = -yDir;
        yDir = temp;
        if (yDir == 0) segmentLength++;
      }

      dx += xDir;
      dy += yDir;
    }

    return pos;
  }

  void _handleAreaDeletion(String areaName) {
    setState(() {
      final tablesToRemove =
          placedTables
              .where((t) => t['areaName'] == areaName)
              .map((t) => t['tableName'].toString().toLowerCase())
              .toList();

      placedTables.removeWhere((table) => table['areaName'] == areaName);

      _usedAreaNames.remove(areaName);

      _usedTableNames.removeAll(tablesToRemove);

      if (selectedArea == areaName) {
        selectedArea = _usedAreaNames.isNotEmpty ? _usedAreaNames.first : '';
      }
    });
  }

  Offset _clampPositionToCanvas(Offset position, Size tableSize) {
    final double canvasWidth = 90000;
    final double canvasHeight = 60000;
    const double buffer = 12.0;

    final double clampedX = position.dx.clamp(
      buffer,
      canvasWidth - tableSize.width - buffer,
    );
    final double clampedY = position.dy.clamp(
      buffer,
      canvasHeight - tableSize.height - buffer,
    );

    return Offset(clampedX, clampedY);
  }

  void _addTable(Map<String, dynamic> data, Offset position) {
    final tableSize = _getPlacedTableSize(data['capacity'], data['shape']);
    final clampedPos = _clampPositionToCanvas(position, tableSize);
    final adjustedPos = _findNonOverlappingPosition(
      clampedPos,
      tableSize,
      areaName: data['areaName'],
    );

    setState(() {
      placedTables.add({...data, 'position': adjustedPos});
      _usedTableNames.add(data['tableName'].toString().toLowerCase());
      _usedAreaNames.add(data['areaName'].toString().toLowerCase());
      selectedArea = data['areaName'];
    });
  }

  void _updateTablePosition(int index, Offset newPosition) {
    final shape = placedTables[index]['shape'];
    final capacity = placedTables[index]['capacity'];
    final areaName = placedTables[index]['areaName'];
    final tableSize = _getPlacedTableSize(capacity, shape);

    final clampedPos = _clampPositionToCanvas(newPosition, tableSize);
    final adjustedPos = _findNonOverlappingPosition(
      clampedPos,
      tableSize,
      skipIndex: index,
      areaName: areaName,
    );

    setState(() {
      placedTables[index]['position'] = adjustedPos;
      for (int i = 0; i < placedTables.length; i++) {
        if (i == index) continue;

        final otherTable = placedTables[i];

        if (otherTable['areaName'] != areaName) continue;

        final otherPos = otherTable['position'] as Offset;
        final otherShape = otherTable['shape'] as String;
        final otherCapacity = otherTable['capacity'];
        final otherSize = _getPlacedTableSize(otherCapacity, otherShape);

        final thisRect = Rect.fromLTWH(
          adjustedPos.dx,
          adjustedPos.dy,
          tableSize.width,
          tableSize.height,
        );
        final otherRect = Rect.fromLTWH(
          otherPos.dx,
          otherPos.dy,
          otherSize.width,
          otherSize.height,
        );

        if (thisRect.overlaps(otherRect)) {
          final newOtherPos = _findNonOverlappingPosition(
            otherPos,
            otherSize,
            skipIndex: i,
            areaName: areaName,
          );
          placedTables[i]['position'] = newOtherPos;
        }
      }
    });
  }


  Widget _buildPlacedTable(int index, Map<String, dynamic> tableData) {
    final capacity = tableData['capacity'];
    final name = tableData['tableName'];
    final area = tableData['areaName'];
    final shape = tableData['shape'];
    final Offset position = tableData['position'];
    final size = _getPlacedTableSize(capacity, shape);

    Widget tableContent = Stack(
      children: [
        _buildPlacedTableWidget(name, capacity, area, shape, size),
        if (_showPopup)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                _showDeleteConfirmationDialog(index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFFF4F4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(6),
                child: Image.asset('assets/trash.png', width: 19, height: 19),
              ),
            ),
          ),
      ],
    );
    if (_showPopup) {
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: Draggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(opacity: 0.7, child: tableContent),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: tableContent),
          child: tableContent,
        ),
      );
    } else {
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: tableContent,
      );
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    final table = placedTables[index];
    final tableName = table['tableName'];
    final areaName = table['areaName'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Color(0xFFFDFDFD),
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  child: Center(
                    child: Image.asset(
                      'assets/check-broken.png',
                      width: 70,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure ?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(text: 'Do you want to really delete the '),
                      TextSpan(
                        text: '$tableName',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: '? this will be deleted in '),
                      TextSpan(
                        text: '$areaName.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFFF1F4F8),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'No, Keep It.',
                        style: TextStyle(color: Color(0xFF4C5F7D)),
                      ),
                    ),
                    SizedBox(width: 12),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFFDA4A38),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          final removedTable = placedTables.removeAt(index);
                          _usedTableNames.remove(
                            removedTable['tableName'],
                          );
                        });

                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Yes, Delete!',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlacedTableWidget(
    String name,
    int capacity,
    String area,
    String shape,
    Size size,
  ) {
    const double chairSize = 20;
    const double offset = 10;
    final double extraSpace = chairSize + offset;

    final double stackWidth = size.width + extraSpace * 2;
    final double stackHeight = size.height + extraSpace * 2;

    Widget tableShape;

    if (shape == "circle") {
      tableShape = Positioned(
        left: extraSpace,
        top: extraSpace,
        child: ClipOval(
          child: Container(
            width: size.width,
            height: size.height,
            color: const Color(0x3F22D629),
            child: Center(child: _buildTableContent(name, area)),
          ),
        ),
      );
    } else {
      tableShape = Positioned(
        left: extraSpace,
        top: extraSpace,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: const Color(0x3F22D629),
            borderRadius: BorderRadius.circular(shape == "square" ? 8 : 16),
          ),
          child: Center(child: _buildTableContent(name, area)),
        ),
      );
    }

    return SizedBox(
      width: stackWidth,
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tableShape,
          ..._buildChairs(capacity, size, extraSpace, shape),
        ],
      ),
    );
  }

  List<Widget> _buildChairs(
    int capacity,
    Size tableSize,
    double margin,
    String shape,
  ) {
    const double chairWidth = 15;
    const double chairHeight = 48;

    final List<Widget> chairs = [];

    if (shape == 'circle') {
      // === Circle: circular placement ===
      final double centerX = (tableSize.width / 2) + margin;
      final double centerY = (tableSize.height / 2) + margin;
      final double radius =
          (tableSize.width > tableSize.height
                  ? tableSize.width
                  : tableSize.height) /
              2 +
          12;

      for (int i = 0; i < capacity && i < 12; i++) {
        final double angle = (2 * 3.1415926 / capacity) * i;
        final double dx = centerX + radius * cos(angle) - (chairWidth / 2);
        final double dy = centerY + radius * sin(angle) - (chairHeight / 2);

        chairs.add(
          Positioned(
            left: dx,
            top: dy,
            child: Transform.rotate(angle: angle, child: _buildChairRect()),
          ),
        );
      }
    } else {
      double left = margin;
      double top = margin;
      double right = margin + tableSize.width;
      double bottom = margin + tableSize.height;

      if (shape == 'rectangle') {
        double leftY = top + (tableSize.height / 2) - (chairWidth / 2);
        double chairTopOffset = -20;
        double chairLeftOffset = 17;

        if (capacity == 1) {
          chairs.add(
            Positioned(
              left: left + (tableSize.width / 2) - (chairWidth / 2),
              top: top - chairHeight,
              child: Transform.rotate(angle: -1.57, child: _buildChairRect()),
            ),
          );
        } else if (capacity == 2) {
          chairs.add(
            Positioned(
              left: (left - chairHeight) + chairLeftOffset,
              top: leftY + chairTopOffset,
              child: Transform.rotate(angle: 3.14, child: _buildChairRect()),
            ),
          );

          chairs.add(
            Positioned(
              left: right + 10,
              top: top + (tableSize.height / 3) - (chairWidth / 3) - 10,
              child: _buildChairRect(),
            ),
          );
        } else {
          int remaining = capacity - 2;
          int topChairs = remaining ~/ 2;
          int bottomChairs = remaining - topChairs;

          // Left chair
          chairs.add(
            Positioned(
              left: (left - chairHeight) + chairLeftOffset,
              top: leftY + chairTopOffset,
              child: Transform.rotate(angle: 3.14, child: _buildChairRect()),
            ),
          );

          // Right chair
          double rightY = top + (tableSize.height / 3) - (chairWidth / 3) - 10;
          double rightX = right + 10;
          chairs.add(
            Positioned(left: rightX, top: rightY, child: _buildChairRect()),
          );

          // Top side
          double topSpacing =
              (tableSize.width - (topChairs * chairWidth)) / (topChairs + 1);
          for (int i = 0; i < topChairs; i++) {
            double dx = left + topSpacing * (i + 1) + chairWidth * i;
            chairs.add(
              Positioned(
                left: dx,
                top: top - chairHeight,
                child: Transform.rotate(angle: -1.57, child: _buildChairRect()),
              ),
            );
          }

          // Bottom side
          double bottomSpacing =
              (tableSize.width - (bottomChairs * chairWidth)) /
              (bottomChairs + 1);
          for (int i = 0; i < bottomChairs; i++) {
            double dx = left + bottomSpacing * (i + 1) + chairWidth * i;
            chairs.add(
              Positioned(
                left: dx,
                top: bottom,
                child: Transform.rotate(angle: 1.57, child: _buildChairRect()),
              ),
            );
          }
        }
      } else {
        int sideCount = 4;
        int chairsPerSide = capacity ~/ sideCount;
        int extraChairs = capacity % sideCount;

        // Top
        int topChairs = chairsPerSide + (extraChairs > 0 ? 1 : 0);
        double topSpacing =
            (tableSize.width - (topChairs * chairWidth)) / (topChairs + 1);
        for (int i = 0; i < topChairs; i++) {
          double dx = left + topSpacing * (i + 1) + chairWidth * i;
          chairs.add(
            Positioned(
              left: dx,
              top: top - chairHeight,
              child: Transform.rotate(angle: -1.57, child: _buildChairRect()),
            ),
          );
        }

        // Right
        int rightChairs = chairsPerSide + (extraChairs > 1 ? 1 : 0);
        double rightSpacing =
            (tableSize.height - (rightChairs * chairWidth)) / (rightChairs + 1);

        for (int i = 0; i < rightChairs; i++) {
          double dy = top + rightSpacing * (i + 1) + chairWidth * i - 15.0;
          double dx = right + 15.0;

          chairs.add(Positioned(left: dx, top: dy, child: _buildChairRect()));
        }

        // Bottom
        int bottomChairs = chairsPerSide + (extraChairs > 2 ? 1 : 0);
        double bottomSpacing =
            (tableSize.width - (bottomChairs * chairWidth)) /
            (bottomChairs + 1);
        for (int i = 0; i < bottomChairs; i++) {
          double dx = left + bottomSpacing * (i + 1) + chairWidth * i;
          chairs.add(
            Positioned(
              left: dx,
              top: bottom,
              child: Transform.rotate(angle: 1.57, child: _buildChairRect()),
            ),
          );
        }

        // Left
        int leftChairs = chairsPerSide;
        double leftSpacing =
            (tableSize.height - (leftChairs * chairWidth)) / (leftChairs + 1);

        for (int i = 0; i < leftChairs; i++) {
          double dy = top + leftSpacing * (i + 1) + chairWidth * i;

          chairs.add(
            Positioned(
              left: left - chairHeight + 15,
              top: dy - 12,
              child: Transform.rotate(angle: 3.14, child: _buildChairRect()),
            ),
          );
        }
      }
    }

    return chairs;
  }

  Widget _buildChairRect() {
    return Container(
      width: 17,
      height: 52,
      decoration: const ShapeDecoration(
        color: Color(0xFF4CAF50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(9),
            bottomRight: Radius.circular(9),
          ),
        ),
      ),
    );
  }

  Widget _buildTableContent(String name, String area) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Table #$name',
          textAlign: TextAlign.center,

          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 13,
          ),
        ),
        SizedBox(height: 6),
        const SizedBox(height: 4),
        Icon(Icons.group, size: 25, color: Colors.green),
      ],
    );
  }

  Size _getPlacedTableSize(int capacity, String shape) {

    switch (shape) {
      case "circle":
        {
          double baseSize = 80.0;
          double increasePerSeat = 10.0;
          double size = (baseSize + (capacity * increasePerSeat)).clamp(
            90.0,
            160.0,
          );
          return Size(size, size);
        }
      case "square":
        {
          double baseSize = 80.0;
          double increasePerSeat = 10.0;
          double size = (baseSize + (capacity * increasePerSeat)).clamp(
            90.0,
            160.0,
          );
          return Size(size, size);
        }

      case "rectangle":
        {
          double baseWidth = 100.0;
          double increasePerSeat = 30.0;
          double width = (baseWidth + (capacity * increasePerSeat)).clamp(
            150.0,
            400.0,
          );
          double height = 100.0;
          return Size(width, height);
        }
      default:
        return Size(150, 150);
    }
  }

  @override
  Widget build(BuildContext context) {
    final popupWidth = MediaQuery.of(context).size.width * 0.34;
    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: TopBar(),
      ),
      body: Stack(
        children: [
          // Table layout content
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 0,
            left: 0,
            right: _showPopup ? popupWidth : 0,
            bottom: 0,
            child: TablePlacementWidget(
              placedTables: placedTables,
              scale: _scale,
              showPopup: _showPopup,
              addTable: _addTable,
              updateTablePosition: _updateTablePosition,
              buildAddContentPrompt: () => SizedBox.shrink(),
              buildPlacedTable: _buildPlacedTable,
              selectedArea: selectedArea,
            ),
          ),

          if (placedTables.isEmpty && !_showPopup)
            Center(child: _buildAddContentPrompt()),

          if (placedTables.isNotEmpty && !_showPopup)
            Positioned(
              top: 25,
              right: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF15315E),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(25, 0, 0, 0),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: _togglePopup,
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Table Setup',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.edit, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),

          _buildZoomControls(),

          // Popup panel
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 0,
            right: _showPopup ? 0 : -MediaQuery.of(context).size.width,
            bottom: 0,
            width: popupWidth,
            child: CreateTableWidget(
              onClose: _togglePopup,
              getTableData: (data) {},
              usedTableNames: _usedTableNames,
              usedAreaNames: _usedAreaNames,
              onAreaSelected: (areaName) {
                setState(() {
                  selectedArea = areaName;
                });
              },
              onAreaDeleted: _handleAreaDeletion,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 125,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendDot(Colors.green, "Available"),
                    SizedBox(width: 20),
                    _buildLegendDot(Colors.red, "Dine In"),
                    SizedBox(width: 20),
                    _buildLegendDot(Colors.grey, "Reserve"),
                    SizedBox(width: 20),
                    _buildLegendDot(Colors.orange, "Shared table"),
                    SizedBox(width: 20),
                    _buildLegendDot(Colors.blue, "Ready to Pay"),
                  ],
                ),
              ),
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
  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }



  Widget _buildAddContentPrompt() {
    return Stack(
      children: [
        Positioned(
          top: 160,
          left: 0,
          right: 0,
          child: Transform.scale(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Start by adding your first table\nor seating area.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
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
                            Text(
                              'Add table',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.blueGrey,
                              ),
                            ),
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
      ],
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

  Widget _buildZoomControls() {
    return Positioned(
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
    );
  }
}

