import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../widgets/CreateTableWidget.dart';
import '../widgets/EditTablePopup.dart';
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
  int? _selectedTableIndex;
  bool _showActionMenu = false;

  bool _showEditPopup = false;
  Map<String, dynamic>? _editingTableData;
  int? _editingTableIndex;


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

  void updateTableGuestCount(int index, int guestCount) {
    setState(() {
      placedTables[index]['guestCount'] = guestCount;
    });
  }


  bool _isOverlapping(
    Offset newPos,
    Size newSize, {
    int? skipIndex,
    String? areaName,
  }) {
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

  Offset _findNonOverlappingPosition(
    Offset pos,
    Size size, {
    int? skipIndex,
    String? areaName,
  }) {
    const int maxAttempts = 1000;
    const double step = 27.0;

    Offset current = pos;
    int dx = 0, dy = 0;
    int segmentLength = 1;
    int xDir = 1, yDir = 0;

    for (int i = 0; i < maxAttempts; i++) {
      if (!_isOverlapping(
        current,
        size,
        skipIndex: skipIndex,
        areaName: areaName,
      )) {
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

  Widget _buildActionButton(String type, VoidCallback onPressed) {
    IconData icon;
    Color backgroundColor;
    Color borderColor;
    Color iconColor;

    if (type == "edit") {
      icon = Icons.edit;
      backgroundColor = Colors.red;
      borderColor = Colors.transparent;
      iconColor = Colors.white;
    } else {
      icon = Icons.delete;
      backgroundColor = Color(0xFFFFF0F0);
      borderColor = Colors.red;
      iconColor = Colors.red;
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: iconColor, size: 15),
      ),
    );
  }



  Widget _buildPlacedTable(int index, Map<String, dynamic> tableData) {
    final capacity = tableData['capacity'];
    final name = tableData['tableName'];
    final area = tableData['areaName'];
    final shape = tableData['shape'];
    final Offset position = tableData['position'];
    final int guestCount = tableData['guestCount'] ?? 0;
    final size = _getPlacedTableSize(capacity, shape);

    Widget baseTable = _buildPlacedTableWidget(name, capacity, area, shape, size, guestCount);

    Widget highlightedTable = DottedBorder(
      color: Colors.red,
      strokeWidth: 2,
      dashPattern: [4, 3],
      borderType: BorderType.RRect,
      radius: Radius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: baseTable,
      ),
    );

    Widget tableContent;
    if (_showPopup) {
      tableContent = Stack(
        children: [
          baseTable,
          Positioned(
            top: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: _buildActionButton("delete", () {
                _showDeleteConfirmationDialog(index);
              }),
            ),
          ),
        ],
      );
    } else {
      tableContent = Stack(
        children: [
          _selectedTableIndex == index && _showActionMenu ? highlightedTable : baseTable,
          if (_selectedTableIndex == index && _showActionMenu)
            Positioned(
              top: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Column(
                  children: [
                    _buildActionButton("edit", () {
                      setState(() {
                        _editingTableIndex = index;
                        _editingTableData = Map<String, dynamic>.from(tableData);
                        _showEditPopup = true;
                        _showActionMenu = false;
                      });
                    }),

                    _buildActionButton("delete", () {
                      _showDeleteConfirmationDialog(index);
                    }),
                  ],
                ),
              ),
            ),
        ],
      );
    }


    Widget draggableWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: guestCount > 0
          ? null
          : () {
        if (!_showPopup) {
          _showGuestDetailsPopup(context, index, tableData);
        }
      },
      onDoubleTap: guestCount > 0
          ? null
          : () {
        if (!_showPopup) {
          setState(() {
            _selectedTableIndex = index;
            _showActionMenu = true;
          });
        }
      },
      child: tableContent,
    );


    return Positioned(
      left: position.dx,
      top: position.dy,
      child: _showPopup
          ? Draggable<int>(
        data: index,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.7, child: tableContent),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: tableContent),
        child: draggableWidget,
      )
          : draggableWidget,
    );
  }


  void _showGuestDetailsPopup(BuildContext context, int index, Map<String, dynamic> tableData){
    List<int> selectedGuests = [];
    String selectedCaptain = '';
    TextEditingController customerController = TextEditingController();

    List<Map<String, String>> captains = [
      {'name': 'A Raghav kumar', 'image': 'assets/loginname.png'},
      {'name': 'Anand vijay', 'image': 'assets/loginname.png'},
      {'name': 'mohan krishna', 'image': 'assets/loginname.png'},
      {'name': 'shak khalil', 'image': 'assets/loginname.png'},
      {'name': 'jagadeesh', 'image': 'assets/loginname.png'},
    ];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Guest Details",
      pageBuilder: (context, anim1, anim2) {
        return MediaQuery.removeViewInsets(
          removeBottom: true,
          context: context,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Material(
                type: MaterialType.transparency,
                child: Center(
                  child: Container(
                    width: 840,
                    height: 500,
                    padding: const EdgeInsets.all(45),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select Guest Numbers",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: List.generate(18, (index) {
                              int guest = index + 1;
                              bool isSelected = selectedGuests.contains(guest);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedGuests = List.generate(
                                      guest,
                                      (i) => i + 1,
                                    );
                                  });
                                },
                                child: Container(
                                  width: 60,
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? const Color(0xFFE4E4E7)
                                            : const Color(0xFFF6F6F7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$guest',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isSelected
                                              ? Colors.black
                                              : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "Customer Name",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 650,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: customerController,
                              style: TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "enter the customer name",
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Choose Captain",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children:
                                      captains.map((captain) {
                                        bool isSelected =
                                            selectedCaptain == captain['name'];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 14,
                                          ),
                                          child: GestureDetector(
                                            onTap:
                                                () => setState(
                                                  () =>
                                                      selectedCaptain =
                                                          captain['name']!,
                                                ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isSelected
                                                        ? const Color(
                                                          0xFFFF4D20,
                                                        )
                                                        : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                border: Border.all(
                                                  color:
                                                      isSelected
                                                          ? const Color(
                                                            0xFFFF4D20,
                                                          )
                                                          : Colors.transparent,
                                                  width: 1.5,
                                                ),
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
                                                  CircleAvatar(
                                                    backgroundImage: AssetImage(
                                                      captain['image']!,
                                                    ),
                                                    radius: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    captain['name']!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                              : Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "Back",
                                  style: TextStyle(
                                    color: Color(0xFF4C5F7D),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              ElevatedButton(
                                  onPressed: () {
                                    final guestCount = selectedGuests.length;

                                    updateTableGuestCount(index, guestCount); // Triggers parent UI update

                                    Navigator.pop(context);
                                  },

                                  style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF4D20),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "SELECT AND CONTINUE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
                Center(
                  child: Image.asset(
                    'assets/check-broken.png',
                    width: 70,
                    height: 50,
                    fit: BoxFit.cover,
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
                      TextSpan(text: '? This will be deleted in '),
                      TextSpan(
                        text: '$areaName.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFFF1F4F8),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          final removedTable = placedTables.removeAt(index);
                          _usedTableNames.remove(removedTable['tableName']);

                          // Reset selection and hide action menu
                          _selectedTableIndex = null;
                          _showActionMenu = false;
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
      int guestCount,
      ) {
    const double chairSize = 20;
    const double offset = 10;
    final double extraSpace = chairSize + offset;

    final double stackWidth = size.width + extraSpace * 2;
    final double stackHeight = size.height + extraSpace * 2;

    final hasGuests = guestCount > 0;
    final tableColor = hasGuests
        ? Colors.orange.withAlpha((0.25 * 255).round())
        : const Color(0x3F22D629);


    Widget tableShape;

    if (shape == "circle") {
      tableShape = Positioned(
        left: extraSpace,
        top: extraSpace,
        child: ClipOval(
          child: Container(
            width: size.width,
            height: size.height,
            color: tableColor,
            child: Center(child: _buildTableContent(name, area, guestCount)),
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
            color: tableColor,
            borderRadius: BorderRadius.circular(shape == "square" ? 8 : 16),
          ),
          child: Center(child: _buildTableContent(name, area, guestCount)),
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
          ..._buildChairs(capacity, size, extraSpace, shape, guestCount > 0 ? Colors.orange : Color(0xFF4CAF50)),
        ],

      ),
    );
  }


  List<Widget> _buildChairs(
    int capacity,
    Size tableSize,
    double margin,
    String shape, Color chairColor,
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
            child: Transform.rotate(angle: angle, child: _buildChairRect(chairColor)),
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
              child: Transform.rotate(angle: -1.57, child: _buildChairRect(chairColor)),
            ),
          );
        } else if (capacity == 2) {
          chairs.add(
            Positioned(
              left: (left - chairHeight) + chairLeftOffset,
              top: leftY + chairTopOffset,
              child: Transform.rotate(angle: 3.14, child: _buildChairRect(chairColor)),
            ),
          );

          chairs.add(
            Positioned(
              left: right + 10,
              top: top + (tableSize.height / 3) - (chairWidth / 3) - 10,
              child: _buildChairRect(chairColor),
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
              child: Transform.rotate(angle: 3.14, child: _buildChairRect(chairColor)),
            ),
          );

          // Right chair
          double rightY = top + (tableSize.height / 3) - (chairWidth / 3) - 10;
          double rightX = right + 10;
          chairs.add(
            Positioned(left: rightX, top: rightY, child: _buildChairRect(chairColor)),
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
                child: Transform.rotate(angle: -1.57, child: _buildChairRect(chairColor)),
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
                child: Transform.rotate(angle: 1.57, child: _buildChairRect(chairColor)),
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
              child: Transform.rotate(angle: -1.57, child: _buildChairRect(chairColor)),
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

          chairs.add(Positioned(left: dx, top: dy, child: _buildChairRect(chairColor)));
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
              child: Transform.rotate(angle: 1.57, child: _buildChairRect(chairColor)),
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
              child: Transform.rotate(angle: 3.14, child: _buildChairRect(chairColor)),
            ),
          );
        }
      }
    }

    return chairs;
  }

  Widget _buildChairRect(Color color) {
    return Container(
      width: 13,
      height: 45,
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(9),
            bottomRight: Radius.circular(9),
          ),
        ),
      ),
    );
  }


  Widget _buildTableContent(String name, String area, int guestCount) {
    final hasGuests = guestCount > 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Table #$name',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: hasGuests ? Colors.orange : Colors.green,
            fontSize: 13,
          ),
        ),
        SizedBox(height: 6),
        Icon(Icons.group, size: 25, color: hasGuests ? Colors.orange : Colors.green),
        if (hasGuests)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$guestCount',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }



  Size _getPlacedTableSize(int capacity, String shape) {
    switch (shape) {
      case "circle":
        {
          double baseSize = 50.0;
          double increasePerSeat = 10.0;
          double size = (baseSize + (capacity * increasePerSeat)).clamp(
            90.0,
            160.0,
          );
          return Size(size, size);
        }
      case "square":
        {
          double baseSize = 50.0;
          double increasePerSeat = 10.0;
          double size = (baseSize + (capacity * increasePerSeat)).clamp(
            90.0,
            160.0,
          );
          return Size(size, size);
        }

      case "rectangle":
        {
          double baseWidth = 70.0;
          double increasePerSeat = 30.0;
          double width = (baseWidth + (capacity * increasePerSeat)).clamp(
            150.0,
            400.0,
          );
          double height = 80.0;
          return Size(width, height);
        }
      default:
        return Size(120, 120);
    }
  }

  @override
  Widget build(BuildContext context) {
    final popupWidth = MediaQuery.of(context).size.width * 0.35;

    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: TopBar(),
      ),
      body: Stack(
        children: [
          // 1. Base TablePlacementWidget (the canvas)
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
              onTapOutside: () {
                if (_showActionMenu) {
                  setState(() {
                    _showActionMenu = false;
                    _selectedTableIndex = null;
                  });
                }
              },
            ),
          ),

          _buildZoomControls(),

          BottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onNavItemTapped,
          ),

          // 8. Legend at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 90,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFFAFBFF),
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
                    _buildLegendDot(Colors.orange, "Reserve"),
                    SizedBox(width: 20),
                    _buildLegendDot(Colors.blue, "Ready to Pay"),
                  ],
                ),
              ),
            ),
          ),

          // 2. Blur background when popup is shown
          if (_showEditPopup)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withAlpha((0.3 * 255).toInt()),
                ),
              ),
            ),

          // 3. Centered table preview popup
          if (_showEditPopup && _selectedTableIndex != null)
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Material(
                    elevation: 15,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _buildPlacedTableWidget(
                        placedTables[_selectedTableIndex!]['tableName'],
                        placedTables[_selectedTableIndex!]['capacity'],
                        placedTables[_selectedTableIndex!]['areaName'],
                        placedTables[_selectedTableIndex!]['shape'],
                        _getPlacedTableSize(
                          placedTables[_selectedTableIndex!]['capacity'],
                          placedTables[_selectedTableIndex!]['shape'],
                        ) *
                            0.8,
                        placedTables[_selectedTableIndex!]['guestCount'] ?? 0,
                      ),
                    ),
                  ),

                  // Red dotted border on top
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DottedBorder(
                        color: Colors.red,
                        strokeWidth: 2,
                        dashPattern: [10, 8],
                        borderType: BorderType.RRect,
                        radius: Radius.circular(16),
                        customPath: (size) {
                          return Path()
                            ..addRRect(RRect.fromRectAndRadius(
                              Offset.zero & size,
                              Radius.circular(16),
                            ));
                        },
                        child: Container(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 4. Show prompt when no tables
          if (placedTables.isEmpty && !_showPopup)
            Center(child: _buildAddContentPrompt()),

          // 5. Table Setup button
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

          // 6. Right-side edit popup (moved lower in Stack so it's on top)
          if (_showEditPopup)
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 0,
              right: 0,
              bottom: 0,
              width: popupWidth,
              child: EditTablePopup(
                tableData: _editingTableData!,
                usedTableNames: _usedTableNames,
                usedAreaNames: _usedAreaNames,
                onUpdate: (updatedData) {
                  setState(() {
                    _usedTableNames.remove(
                        _editingTableData!['tableName'].toString().toLowerCase());
                    _usedTableNames.add(
                        updatedData['tableName'].toString().toLowerCase());
                    placedTables[_editingTableIndex!] = updatedData;
                    _showEditPopup = false;
                    _editingTableData = null;
                    _editingTableIndex = null;
                  });
                },
                onClose: () {
                  setState(() {
                    _showEditPopup = false;
                    _editingTableData = null;
                    _editingTableIndex = null;
                  });
                },
              ),
            ),

          // 7. Right-side CreateTableWidget (Table Setup panel)
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
              onAreaSelected: (areaName) => setState(() => selectedArea = areaName),
              onAreaDeleted: _handleAreaDeletion,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
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
          top: 120,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                DottedBorder(
                  color: Colors.grey,
                  strokeWidth: 1,
                  borderType: BorderType.RRect,
                  radius: Radius.circular(20),
                  dashPattern: [6, 4],
                  child: InkWell(
                    onTap: _togglePopup,
                    child: Container(
                      padding: EdgeInsets.all(25),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Color(0xFFF1F3F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 20, color: Colors.blueGrey),
                            SizedBox(height: 8),
                            Text(
                              'Add table',
                              style: TextStyle(
                                fontSize: 16,
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
        width: 30,
        height: 30,
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
        child: Icon(icon, size: 15, color: Colors.black87),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      bottom: 120,
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
                width: 30,
                child: _zoomButton(icon: Icons.fit_screen, onTap: _scaleToFit),
              ),
              SizedBox(width: 8),
              Text(
                "Scaled to fit",
                style: TextStyle(
                  fontSize: 12,
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