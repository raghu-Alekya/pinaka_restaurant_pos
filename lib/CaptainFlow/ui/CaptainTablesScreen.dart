import 'dart:math';

import 'package:flutter/material.dart';

import '../../Manager flow/ui/guest_details_popup.dart';
import '../../Manager flow/widgets/ZoomControlsWidget.dart';
import '../../Manager flow/widgets/table_helpers.dart';
import '../../helpers/CaptainNavigationHelper.dart';
import '../../local database/area_dao.dart';
import '../../local database/login_dao.dart';
import '../../local database/table_dao.dart';
import '../Widgets/CaptainBottomNavBar.dart';
import '../Widgets/Captain_Top_bar.dart';

class CaptionTablesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> loadedTables;
  final String pin;
  final String associatedManagerPin;

  const CaptionTablesScreen({
    Key? key,
    required this.loadedTables,
    required this.pin,
    required this.associatedManagerPin,
  }) : super(key: key);

  @override
  _CaptionTablesScreenState createState() => _CaptionTablesScreenState();
}

enum ViewMode { normal, gridShapeBased, gridCommonImage }

ViewMode _currentViewMode = ViewMode.gridCommonImage;


class _CaptionTablesScreenState extends State<CaptionTablesScreen> {
  List<Map<String, dynamic>> placedTables = [];
  List<Map<String, dynamic>> allTables = [];
  List<Map<String, dynamic>> displayedTables = [];
  List<String> areas = [];
  String selectedArea = '';
  final ScrollController horizontalScrollController = ScrollController();
  final ScrollController verticalScrollController = ScrollController();
  final ScrollController gridScrollController = ScrollController();
  double _scale = 1.0;
  int _selectedIndex = 1;
  final areaDao = AreaDao();
  final tableDao = TableDao();
  final loginDao = LoginDao();

  void _onItemTapped(int index) {
    CaptionNavigationHelper.handleNavigation(context, _selectedIndex, index,widget.pin,widget.associatedManagerPin,);
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  void dispose() {
    horizontalScrollController.dispose();
    verticalScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final areaList = await areaDao.getAreasByPin(widget.associatedManagerPin);

    String initialArea = areaList.isNotEmpty ? areaList.first : '';

    setState(() {
      allTables = widget.loadedTables
          .where((table) => table['pin'] == widget.associatedManagerPin)
          .map((table) {
        return {...table, 'position': Offset(table['posX'], table['posY'])};
      }).toList();

      areas = areaList;
      selectedArea = initialArea;
      displayedTables = allTables
          .where((table) => table['areaName'] == selectedArea)
          .toList();
    });
  }



  void _selectArea(String area) {
    setState(() {
      selectedArea = area;
      displayedTables =
          allTables
              .where((table) => table['areaName'] == selectedArea)
              .toList();
    });
  }

  void _zoomIn() {
    setState(() {
      _scale += 0.1;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_scale > 0.2) {
        _scale -= 0.1;
      }
    });
  }

  void _scaleToFit() {
    setState(() {
      _scale = 1.0;
    });
  }

  Widget _buildAreaFilter() {
    if (areas.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children:
            areas.map((area) {
              final bool isSelected = area == selectedArea;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: TextButton(
                  onPressed: () => _selectArea(area),
                  style: TextButton.styleFrom(
                    backgroundColor:
                    isSelected
                        ? const Color(0xFFFD6464)
                        : Colors.transparent,
                    foregroundColor:
                    isSelected ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 13.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(area),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showGuestDetailsPopup(BuildContext context,
      int index,
      Map<String, dynamic> tableData,) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Guest Details",
      pageBuilder: (context, anim1, anim2) {
        return MediaQuery.removeViewInsets(
          removeBottom: true,
          context: context,
          child: GuestDetailsPopup(
            index: index,
            tableData: tableData,
            placedTables: displayedTables,
            updateTableGuestData: ({
              required int index,
              required int guestCount,
            }) {
              updateTableGuestData(index, guestCount: guestCount);
            },
          ),
        );
      },
    );
  }

  void updateTableGuestData(int index, {required int guestCount}) async {
    final tableId = displayedTables[index]['id'];

    setState(() {
      displayedTables[index]['guestCount'] = guestCount;
    });

    await tableDao.updateTable(tableId, {
      'guestCount': guestCount,
      'posX': displayedTables[index]['position'].dx,
      'posY': displayedTables[index]['position'].dy,
      'tableName': displayedTables[index]['tableName'],
      'capacity': displayedTables[index]['capacity'],
      'shape': displayedTables[index]['shape'],
      'areaName': displayedTables[index]['areaName'],
    });
  }
  Widget _buildPlacedTable(int index, Map<String, dynamic> tableData) {
    final capacity = tableData['capacity'];
    final name = tableData['tableName'];
    final area = tableData['areaName'];
    final shape = tableData['shape'];
    final Offset position = tableData['position'];
    final int guestCount = tableData['guestCount'] ?? 0;
    final double rotation = tableData['rotation'] ?? 0.0;

    final size = TableHelpers.getPlacedTableSize(capacity, shape);

    Widget baseTable = _buildPlacedTableWidget(
      name,
      capacity,
      area,
      shape,
      size,
      guestCount,
    );

    int quarterTurns = (rotation ~/ 90) % 4;

    Widget rotatedTable = RotatedBox(
      quarterTurns: quarterTurns,
      child: baseTable,
    );

    Widget gestureWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: guestCount > 0
          ? null
          : () {
        _showGuestDetailsPopup(context, index, tableData);
      },
      child: rotatedTable,
    );

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: gestureWidget,
    );
  }


  Widget _buildPlacedTableWidget(String name,
      int capacity,
      String area,
      String shape,
      Size size,
      int guestCount,) {
    const double chairSize = 20;
    const double offset = 10;
    final double extraSpace = chairSize + offset;

    final double stackWidth = size.width + extraSpace * 2;
    final double stackHeight = size.height + extraSpace * 2;

    final hasGuests = guestCount > 0;

    final tableColor =
    hasGuests
        ? Color(0xFFF44336).withAlpha(
      (0.25 * 255).round(),
    ) // red-transparent
        : const Color(0x3F22D629); // green-transparent

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
            child: Center(
              child: TableHelpers.buildTableContent(name, area, guestCount),
            ),
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
          child: Center(
            child: TableHelpers.buildTableContent(name, area, guestCount),
          ),
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
          ..._buildChairs(
            capacity,
            size,
            extraSpace,
            shape,
            guestCount > 0 ? Color(0xFFF44336) : Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChairs(int capacity,
      Size tableSize,
      double margin,
      String shape,
      Color chairColor,) {
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
            child: Transform.rotate(
              angle: angle,
              child: TableHelpers.buildChairRect(chairColor),
            ),
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
              child: Transform.rotate(
                angle: -1.57,
                child: TableHelpers.buildChairRect(chairColor),
              ),
            ),
          );
        } else if (capacity == 2) {
          chairs.add(
            Positioned(
              left: (left - chairHeight) + chairLeftOffset,
              top: leftY + chairTopOffset,
              child: Transform.rotate(
                angle: 3.14,
                child: TableHelpers.buildChairRect(chairColor),
              ),
            ),
          );

          chairs.add(
            Positioned(
              left: right + 10,
              top: top + (tableSize.height / 3) - (chairWidth / 3) - 10,
              child: TableHelpers.buildChairRect(chairColor),
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
              child: Transform.rotate(
                angle: 3.14,
                child: TableHelpers.buildChairRect(chairColor),
              ),
            ),
          );

          // Right chair
          double rightY = top + (tableSize.height / 3) - (chairWidth / 3) - 10;
          double rightX = right + 10;
          chairs.add(
            Positioned(
              left: rightX,
              top: rightY,
              child: TableHelpers.buildChairRect(chairColor),
            ),
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
                child: Transform.rotate(
                  angle: -1.57,
                  child: TableHelpers.buildChairRect(chairColor),
                ),
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
                child: Transform.rotate(
                  angle: 1.57,
                  child: TableHelpers.buildChairRect(chairColor),
                ),
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
              child: Transform.rotate(
                angle: -1.57,
                child: TableHelpers.buildChairRect(chairColor),
              ),
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

          chairs.add(
            Positioned(
              left: dx,
              top: dy,
              child: TableHelpers.buildChairRect(chairColor),
            ),
          );
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
              child: Transform.rotate(
                angle: 1.57,
                child: TableHelpers.buildChairRect(chairColor),
              ),
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
              child: Transform.rotate(
                angle: 3.14,
                child: TableHelpers.buildChairRect(chairColor),
              ),
            ),
          );
        }
      }
    }

    return chairs;
  }


  Widget _buildShapeBasedGridItem(Map<String, dynamic> tableData, int index) {
    final shape = tableData['shape'];
    final name = tableData['tableName'];
    final guestCount = tableData['guestCount'] ?? 0;

    String imagePath;
    if (shape == 'circle') {
      imagePath = guestCount > 0 ? 'assets/circle2.png' : 'assets/circle1.png';
    } else if (shape == 'square') {
      imagePath = guestCount > 0 ? 'assets/square2.png' : 'assets/square1.png';
    } else {
      imagePath =
      guestCount > 0 ? 'assets/rectangle2.png' : 'assets/rectangle1.png';
    }

    return GestureDetector(
      onTap: guestCount > 0
          ? null
          : () {
        _showGuestDetailsPopup(context, index, tableData);
      },
      child: _buildGridItem(imagePath, name, guestCount),
    );
  }

  Widget _buildCommonGridItem(Map<String, dynamic> tableData, int index) {
    final name = tableData['tableName'];
    final guestCount = tableData['guestCount'] ?? 0;

    return GestureDetector(
      onTap: guestCount > 0
          ? null
          : () {
        _showGuestDetailsPopup(context, index, tableData);
      },
      child: _buildGridItem1(name, guestCount),
    );
  }

  Widget _buildGridItem1(String name, int guestCount) {
    final bool isOccupied = guestCount > 0;

    // Define color schemes
    final Color backgroundColor = isOccupied ? Colors.red[100]! : Colors
        .green[100]!;
    final Color textColor = isOccupied ? Colors.red : Colors.green[800]!;
    final Color iconColor = textColor;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      // Increased padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group, size: 22, color: iconColor),
              SizedBox(width: 6),
              Text(
                isOccupied ? '$guestCount' : '-',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }


  Widget _buildGridItem(String imagePath, String name, int guestCount) {
    final bool isOccupied = guestCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOccupied ? Colors.red : Colors.green,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group, size: 16,
                  color: isOccupied ? Colors.red : Colors.green),
              SizedBox(width: 4),
              Text(
                isOccupied ? '$guestCount' : '-',
                style: TextStyle(
                  fontSize: 14,
                  color: isOccupied ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          Image.asset(
            imagePath,
            width: 45,
            height: 45,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Stack(
        children: [
          // Top Bar
          Positioned(top: 0, left: 0, right: 0, child: CaptainTopBar()),

          // Area Filter
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: _buildAreaFilter(),
            ),
          ),

          // Normal View
          if (_currentViewMode == ViewMode.normal)
            Padding(
              padding: const EdgeInsets.only(top: 125.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: displayedTables.isEmpty
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Text(
                            'No tables are present',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                        : ScrollbarTheme(
                      data: ScrollbarThemeData(
                        thickness: WidgetStateProperty.all(12.0),
                        radius: const Radius.circular(8),
                        thumbVisibility: WidgetStateProperty.all(true),
                        minThumbLength: 500,
                        thumbColor: WidgetStateProperty.all(
                          Color(0xFFB6B6B6),
                        ),
                        trackColor: WidgetStateProperty.all(
                          Colors.grey.shade800,
                        ),
                      ),
                      child: Scrollbar(
                        controller: horizontalScrollController,
                        child: Scrollbar(
                          controller: verticalScrollController,
                          notificationPredicate: (_) => true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            child: SingleChildScrollView(
                              controller: horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                controller: verticalScrollController,
                                scrollDirection: Axis.vertical,
                                child: Transform.scale(
                                  scale: _scale,
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    width: 90000,
                                    height: 60000,
                                    child: Stack(
                                      children: displayedTables
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key;
                                        Map<String, dynamic> tableData =
                                            entry.value;
                                        return _buildPlacedTable(
                                            index, tableData);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_currentViewMode == ViewMode.gridShapeBased || _currentViewMode == ViewMode.gridCommonImage)
            Padding(
              padding: const EdgeInsets.only(top: 170.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: displayedTables.isEmpty
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 160),
                        Center(
                          child: Text(
                            'No tables are present',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                        : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thickness: WidgetStateProperty.all(10.0),
                          radius: const Radius.circular(8),
                          thumbVisibility: WidgetStateProperty.all(true),
                          thumbColor: WidgetStateProperty.all(
                            Color(0xFFB6B6B6),
                          ),
                          trackColor: WidgetStateProperty.all(
                            Colors.grey.shade800,
                          ),
                        ),
                        child: Scrollbar(
                          controller: gridScrollController,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            child: SingleChildScrollView(
                              controller: horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                controller: verticalScrollController,
                                scrollDirection: Axis.vertical,
                                child: Transform.scale(
                                  scale: _scale,
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    child: GridView.builder(
                                      controller: gridScrollController,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: displayedTables.length,
                                      padding: const EdgeInsets.all(10),
                                      gridDelegate: _currentViewMode == ViewMode.gridShapeBased
                                          ? SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 10,
                                        crossAxisSpacing: 20,
                                        mainAxisSpacing: 20,
                                        childAspectRatio: 0.9,
                                      )
                                          : SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 12,
                                        crossAxisSpacing: 15,
                                        mainAxisSpacing: 15,
                                        childAspectRatio: 1.0,
                                      ),
                                      itemBuilder: (context, index) {
                                        if (_currentViewMode == ViewMode.gridShapeBased) {
                                          return _buildShapeBasedGridItem(displayedTables[index], index);
                                        } else {
                                          return _buildCommonGridItem(displayedTables[index], index);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Zoom Controls at Bottom Left
          ZoomControlsWidget(
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onScaleToFit: _scaleToFit,
          ),

          // Legend
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
                    TableHelpers.buildLegendDot(Colors.green, "Available"),
                    SizedBox(width: 20),
                    TableHelpers.buildLegendDot(Colors.red, "Dine In"),
                    SizedBox(width: 20),
                    TableHelpers.buildLegendDot(Colors.orange, "Reserve"),
                    SizedBox(width: 20),
                    TableHelpers.buildLegendDot(Colors.blue, "Ready to Pay"),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation Bar
          CaptionBottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),

          // Mode Switch Buttons - Move to bottom for higher z-index
          Positioned(
            top: 120,
            left: 35,
            child: ViewLayoutDropdown1(
              onModeSelected: (mode) {
                setState(() {
                  _currentViewMode = mode;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ViewLayoutDropdown1 extends StatefulWidget {
  final Function(ViewMode) onModeSelected;

  const ViewLayoutDropdown1({Key? key, required this.onModeSelected}) : super(key: key);

  @override
  _ViewLayoutDropdown1State createState() => _ViewLayoutDropdown1State();
}
class _ViewLayoutDropdown1State extends State<ViewLayoutDropdown1> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ViewMode>(
      onSelected: (ViewMode mode) {
        setState(() {
          _currentViewMode = mode;
        });
        widget.onModeSelected(mode);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: Offset(0, 40),
      color: Colors.white, // Set dropdown background color to white
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ViewMode>>[
        _buildMenuItem(ViewMode.gridCommonImage, 'Basic layout',Icons.grid_view),
        _buildMenuItem(ViewMode.gridShapeBased, 'Standard layout', Icons.grid_on),
        _buildMenuItem(ViewMode.normal, 'Advanced layout', Icons.center_focus_strong),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 52, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View layout',
              style: TextStyle(
                color: const Color(0xFF5D5A5A),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width:10),
            Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<ViewMode> _buildMenuItem(ViewMode mode, String title, IconData icon) {
    bool isSelected = _currentViewMode == mode;

    return PopupMenuItem<ViewMode>(
      value: mode,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade300 : Colors.white,
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            if (isSelected)
              Icon(Icons.circle, color: Colors.orange, size: 10)
            else
              SizedBox(width: 10),
            SizedBox(width: 10),
            Icon(icon, size: 24, color: Colors.black),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF5D5A5A),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


