import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../CaptainFlow/ui/CaptainTablesScreen.dart';
import '../../helpers/DatabaseHelper.dart';
import '../widgets/CreateTableWidget.dart';
import '../widgets/DeleteConfirmationDialog.dart';
import '../widgets/EditTablePopup.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/TablePlacementWidget.dart';
import '../widgets/ViewLayoutDropdown.dart';
import '../widgets/ZoomControlsWidget.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/table_helpers.dart';
import 'guest_details_popup.dart';
import 'dart:math' as math;

/// Screen widget that manages the floor plan of tables in a restaurant POS system.
///
/// Users can add, move, edit, and delete tables, organized by areas. Tables have
/// shapes, capacities, guest data, and positions on a large scrollable canvas.
///
/// Also supports zoom controls and filtering tables by area.
///
/// This widget contains complex logic to prevent table overlapping, clamp table
/// positions within a large virtual canvas, and automatically adjust positions to
/// avoid collisions.
class TablesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> loadedTables;

  const TablesScreen({Key? key, required this.loadedTables}) : super(key: key);
  @override
  _TablesScreenState createState() => _TablesScreenState();
}

ViewMode _currentViewMode = ViewMode.normal;

class _TablesScreenState extends State<TablesScreen> {
  /// Current zoom scale applied to the floor plan canvas.
  double _scale = 1.0;

  /// Index of the currently selected bottom navigation tab.
  int _selectedIndex = 1;

  void _onNavItemTapped(int index) {
    NavigationHelper.handleNavigation(context, _selectedIndex, index);
    setState(() {
      _selectedIndex = index;
    });
  }

  final GlobalKey _canvasKey = GlobalKey();

  /// Whether the add table/area popup is visible.
  bool _showPopup = false;

  /// Set of all used table names (in lowercase) to avoid duplicates.
  Set<String> _usedTableNames = {};

  /// Set of all used area names (in lowercase).
  Set<String> _usedAreaNames = {};

  /// Name of the currently selected area filter. Only tables from this area are shown.
  String? selectedArea;

  /// Index of the currently selected table for action menu.
  int? _selectedTableIndex;

  /// Whether the action menu (edit/delete) is visible for the selected table.
  bool _showActionMenu = false;

  /// Whether the edit table popup is currently visible.
  bool _showEditPopup = false;

  /// Data of the table currently being edited.
  Map<String, dynamic>? _editingTableData;

  final ScrollController gridScrollController = ScrollController();

  /// Index of the table currently being edited.
  int? _editingTableIndex;

  /// List of all tables placed on the floor plan.
  ///
  /// Each table is a map containing keys like:
  /// - 'tableName': String,
  /// - 'areaName': String,
  /// - 'capacity': int,
  /// - 'shape': String,
  /// - 'position': Offset,
  /// - other guest or metadata fields.
  List<Map<String, dynamic>> placedTables = [];

  List<Map<String, dynamic>> get _filteredTables {
    if (selectedArea == null) return placedTables;
    return placedTables
        .where((table) => table['areaName'] == selectedArea)
        .toList();
  }

  List<String> get areaNames {
    return placedTables
        .map((e) => e['areaName'] as String?)
        .where((name) => name != null && name.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList();
  }

  void _selectArea(String area) {
    setState(() {
      selectedArea = area;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    final dbHelper = DatabaseHelper();
    final tables = await dbHelper.getAllTables();

    setState(() {
      placedTables =
          tables.map((table) {
            return {
              ...table,
              'position': Offset(table['posX'], table['posY']),
              'rotation': table['rotation'] ?? 0.0,
            };
          }).toList();

      _usedTableNames =
          placedTables
              .map((t) => t['tableName'].toString().toLowerCase())
              .toSet();

      _usedAreaNames =
          placedTables
              .map((t) => t['areaName'].toString().toLowerCase())
              .toSet();
    });
  }

  /// Increases the zoom scale by 0.1, max limited elsewhere.
  void _zoomIn() => setState(() => _scale += 0.1);

  /// Decreases the zoom scale by 0.1 but clamps between 0.5 and 3.0.
  void _zoomOut() => setState(() => _scale = (_scale - 0.1).clamp(0.5, 3.0));

  /// Resets the zoom scale back to default 1.0.
  void _scaleToFit() => setState(() => _scale = 1.0);

  /// Toggles the visibility of the add table/area popup.
  void _togglePopup() {
    setState(() {
      _showPopup = !_showPopup;
    });
  }

  /// Updates guest-related data for a placed table at [index].
  ///
  /// Parameters:
  /// - [guestCount]: number of guests at the table
  void updateTableGuestData(int index, {required int guestCount}) async {
    final dbHelper = DatabaseHelper();
    final tableId = placedTables[index]['id'];

    // Update in-memory table data
    setState(() {
      placedTables[index]['guestCount'] = guestCount;
    });

    // Update in database
    await dbHelper.updateTable(tableId, {
      'guestCount': guestCount,
      'posX': placedTables[index]['position'].dx,
      'posY': placedTables[index]['position'].dy,
      'tableName': placedTables[index]['tableName'],
      'capacity': placedTables[index]['capacity'],
      'shape': placedTables[index]['shape'],
      'areaName': placedTables[index]['areaName'],
    });
  }

  /// Checks if a proposed table rectangle overlaps with any existing table rectangles
  /// in the same [areaName], except the table at [skipIndex].
  ///
  /// Takes a position [newPos], size [newSize], optional [skipIndex], and optional [areaName].
  ///
  /// Returns `true` if overlapping, `false` otherwise.
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
      final existingSize = TableHelpers.getPlacedTableSize(capacity, shape);

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

  /// Attempts to find a non-overlapping position close to the requested [pos] and [size].
  ///
  /// If the initial [pos] causes overlap, searches nearby positions in a spiral pattern.
  /// Limits attempts to [maxAttempts].
  ///
  /// Optional parameters:
  /// - [skipIndex]: index of the table to ignore during overlap checks
  /// - [areaName]: only check overlaps within this area
  ///
  /// Returns a suitable non-overlapping position or the original position if none found.
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

  Widget _buildShapeBasedGridItem(
    Map<String, dynamic> tableData,
    int filteredIndex,
  ) {
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

    final actualIndex = placedTables.indexOf(tableData);

    return GestureDetector(
      onTap:
          guestCount > 0
              ? null
              : () {
                if (!_showPopup) {
                  _showGuestDetailsPopup(context, actualIndex, tableData);
                }
              },
      child: _buildGridItem(imagePath, name, guestCount),
    );
  }

  Widget _buildCommonGridItem(
    Map<String, dynamic> tableData,
    int filteredIndex,
  ) {
    final name = tableData['tableName'];
    final guestCount = tableData['guestCount'] ?? 0;

    final actualIndex = placedTables.indexOf(tableData);

    return GestureDetector(
      onTap:
          guestCount > 0
              ? null
              : () {
                if (!_showPopup) {
                  _showGuestDetailsPopup(context, actualIndex, tableData);
                }
              },
      child: _buildGridItem1(name, guestCount),
    );
  }

  Widget _buildGridItem1(String name, int guestCount) {
    final bool isOccupied = guestCount > 0;

    // Define color schemes
    final Color backgroundColor =
        isOccupied ? Colors.red[100]! : Colors.green[100]!;
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
                  fontSize: 15, // Increased font size
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
              Icon(
                Icons.group,
                size: 16,
                color: isOccupied ? Colors.red : Colors.green,
              ),
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
          Image.asset(imagePath, width: 45, height: 45, fit: BoxFit.contain),
        ],
      ),
    );
  }

  /// Deletes an area and all tables belonging to it.
  ///
  /// Removes the area from [_usedAreaNames] and all related table names from [_usedTableNames].
  /// Updates the selected area filter accordingly.
  void _handleAreaDeletion(String areaName) async {
    final dbHelper = DatabaseHelper();

    setState(() {
      final tablesToRemove =
          placedTables
              .where((t) => t['areaName'] == areaName)
              .map((t) => t['tableName'].toString().toLowerCase())
              .toList();

      // Remove from local state
      placedTables.removeWhere((table) => table['areaName'] == areaName);
      _usedAreaNames.remove(areaName);
      _usedTableNames.removeAll(tablesToRemove);

      // Update selected area if needed
      if (selectedArea == areaName) {
        selectedArea = _usedAreaNames.isNotEmpty ? _usedAreaNames.first : '';
      }
    });

    // Delete from database
    await dbHelper.deleteArea(areaName);
    await dbHelper.deleteTablesByArea(areaName);
  }

  /// Clamps a given [position] of a table so it stays within the canvas bounds.
  ///
  /// Uses fixed large canvas size to allow free placement.
  /// A [buffer] space is applied to avoid edges.
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

  /// Adds a new table with [data] at the requested [position].
  ///
  /// Clamps and adjusts position to prevent overlapping.
  /// Updates internal state with new table and tracks used names/areas.
  Future<void> _addTable(Map<String, dynamic> data, Offset position) async {
    final tableSize = TableHelpers.getPlacedTableSize(
      data['capacity'],
      data['shape'],
    );
    final clampedPos = _clampPositionToCanvas(position, tableSize);
    final adjustedPos = _findNonOverlappingPosition(
      clampedPos,
      tableSize,
      areaName: data['areaName'],
    );

    final tableData = {
      'tableName': data['tableName'],
      'capacity': data['capacity'],
      'shape': data['shape'],
      'areaName': data['areaName'],
      'posX': adjustedPos.dx,
      'posY': adjustedPos.dy,
      'guestCount': data['guestCount'] ?? 0,
      'rotation': 0.0,
    };

    final dbHelper = DatabaseHelper();
    final id = await dbHelper.insertTable(tableData);

    setState(() {
      placedTables.add({...tableData, 'id': id, 'position': adjustedPos});
      _usedTableNames.add(data['tableName'].toString().toLowerCase());
      _usedAreaNames.add(data['areaName'].toString().toLowerCase());
      selectedArea = data['areaName'];
    });
  }

  /// Updates the position of an existing table at [index] to [newPosition].
  ///
  /// Clamps and adjusts the position to avoid overlap with other tables in the same area.
  /// If the new position causes overlap with other tables, tries to adjust those tables' positions as well.
  void _updateTablePosition(int index, Offset newPosition) async {
    final shape = placedTables[index]['shape'];
    final capacity = placedTables[index]['capacity'];
    final areaName = placedTables[index]['areaName'];
    final tableSize = TableHelpers.getPlacedTableSize(capacity, shape);

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
        final otherSize = TableHelpers.getPlacedTableSize(
          otherCapacity,
          otherShape,
        );

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
          DatabaseHelper().updateTable(otherTable['id'], {
            'posX': newOtherPos.dx,
            'posY': newOtherPos.dy,
          });
        }
      }
    });

    final tableId = placedTables[index]['id'];
    await DatabaseHelper().updateTable(tableId, {
      'posX': adjustedPos.dx,
      'posY': adjustedPos.dy,
    });
  }

  /// Builds a positioned and optionally draggable table widget to be rendered
  /// on the canvas at its saved position.
  ///
  /// This method handles the visual appearance, interaction logic (tap, double tap),
  /// guest information popup, and optional edit/delete menu display based on state.
  ///
  /// Parameters:
  /// - [index]: The index of the table in the placedTables list.
  /// - [tableData]: The table data map including name, area, shape, position, etc.

  Widget _buildPlacedTable(int index, Map<String, dynamic> tableData) {
    final capacity = tableData['capacity'];
    final name = tableData['tableName'];
    final area = tableData['areaName'];
    final shape = tableData['shape'];
    final Offset position = tableData['position'];
    final int guestCount = tableData['guestCount'] ?? 0;
    final double rotation = tableData['rotation'] ?? 0.0;

    final size = TableHelpers.getPlacedTableSize(capacity, shape);

    // Build table content with rotation awareness
    Widget tableContent = _buildPlacedTableWidget(
      name,
      capacity,
      area,
      shape,
      size,
      guestCount,
      rotation,
    );

    Widget paddedTable = Padding(
      padding: const EdgeInsets.all(8.0),
      child: tableContent,
    );

    Widget borderedTable = Stack(
      clipBehavior: Clip.none,
      children: [
        DottedBorder(
          color: _selectedTableIndex == index && _showActionMenu ? Colors.red : Colors.transparent,
          strokeWidth: 2,
          dashPattern: [4, 3],
          borderType: BorderType.RRect,
          radius: Radius.circular(12),
          child: paddedTable,
        ),
      ],
    );

    int quarterTurns = (rotation ~/ 90) % 4;

    Widget gestureTable = GestureDetector(
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
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: borderedTable,
      ),
    );

    Widget actionButtons = (_showPopup || (_selectedTableIndex == index && _showActionMenu))
        ? Positioned(
      top: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          children: [
            if (!_showPopup)
              _buildActionButton("edit", () {
                setState(() {
                  _editingTableIndex = index;
                  _editingTableData = Map<String, dynamic>.from(tableData);
                  _showEditPopup = true;
                  _showActionMenu = false;
                });
              }),
            if (!_showPopup) SizedBox(height: 6),
            _buildActionButton("delete", () {
              _showDeleteConfirmationDialog(index);
            }),
            if (!_showPopup) SizedBox(height: 6),
            if (shape == 'rectangle')
              _buildActionButton("rotate", () {
                _rotateTable(index);
              }),
          ],
        ),
      ),
    )
        : SizedBox.shrink();

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _showPopup || (_selectedTableIndex == index && _showActionMenu)
              ? Draggable<int>(
            data: index,
            feedback: Material(
              color: Colors.transparent,
              child: Opacity(opacity: 0.7, child: gestureTable),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: gestureTable),
            onDragEnd: (details) {
              final RenderBox box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
              final Offset localOffset = box.globalToLocal(details.offset);
              _updateTablePosition(index, localOffset);
            },
            child: gestureTable,
          )
              : gestureTable,
          actionButtons,
        ],
      ),
    );
  }

  void _rotateTable(int index) async {
    final currentRotation = placedTables[index]['rotation'] ?? 0.0;
    final newRotation = currentRotation == 0.0 ? 90.0 : 0.0;

    final shape = placedTables[index]['shape'];
    final capacity = placedTables[index]['capacity'];
    final areaName = placedTables[index]['areaName'];

    Size newSize = TableHelpers.getPlacedTableSize(capacity, shape);
    if (shape == 'rectangle' && newRotation == 90.0) {
      newSize = Size(newSize.height, newSize.width);
    }

    Offset currentPos = placedTables[index]['position'];

    bool willOverlap = _isOverlapping(
      currentPos,
      newSize,
      skipIndex: index,
      areaName: areaName,
    );

    Offset newPos = currentPos;

    if (willOverlap) {
      newPos = _findNonOverlappingPosition(
        currentPos,
        newSize,
        skipIndex: index,
        areaName: areaName,
      );
    }

    newPos = _clampPositionToCanvas(newPos, newSize);

    setState(() {
      placedTables[index]['rotation'] = newRotation;
      placedTables[index]['position'] = newPos;
      placedTables[index]['posX'] = newPos.dx;
      placedTables[index]['posY'] = newPos.dy;

      // Hide action menu after rotation
      _selectedTableIndex = null;
      _showActionMenu = false;
    });

    final tableId = placedTables[index]['id'];
    await DatabaseHelper().updateTable(tableId, {
      'rotation': newRotation,
      'posX': newPos.dx,
      'posY': newPos.dy,
    });
  }


  void _handleTapOutside() {
    setState(() {
      _selectedTableIndex = -1;
      _showActionMenu = false;
    });
  }


  /// Constructs the visual appearance of a table widget with chairs, color coding,
  /// and labels inside a `SizedBox`. Shapes are rendered as either circles or rectangles
  /// based on user configuration.
  ///
  /// Parameters:
  /// - [name]: The name of the table (e.g. "T1").
  /// - [capacity]: Number of seats on the table.
  /// - [area]: The area name the table belongs to.
  /// - [shape]: The shape of the table ("circle", "square", etc.).
  /// - [size]: Calculated size of the table.
  /// - [guestCount]: Number of guests currently seated, used for styling.
  Widget _buildPlacedTableWidget(
      String name,
      int capacity,
      String area,
      String shape,
      Size size,
      int guestCount,
      double rotation, // Pass rotation here
      ) {
    const double chairSize = 20;
    const double offset = 10;
    final double extraSpace = chairSize + offset;

    final double stackWidth = size.width + extraSpace * 2;
    final double stackHeight = size.height + extraSpace * 2;

    final hasGuests = guestCount > 0;

    final tableColor = hasGuests
        ? Color(0xFFF44336).withAlpha((0.25 * 255).round()) // red-transparent
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
            child: Center(
              child: Transform.rotate(
                angle: -rotation * (math.pi / 180), // Keep text upright
                child: TableHelpers.buildTableContent(name, area, guestCount),
              ),
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
            child: Transform.rotate(
              angle: -rotation * (math.pi / 180), // Keep text upright
              child: TableHelpers.buildTableContent(name, area, guestCount),
            ),
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
            guestCount > 0 ? Color(0xFFF44336) : Color(0xFF4CAF50), // red or green chairs
          ),
        ],
      ),
    );
  }


  /// Builds a list of positioned chair widgets around the table based on capacity and shape.
  ///
  /// Chairs are arranged differently depending on whether the shape is circular,
  /// rectangular, or square. Chair colors change based on occupancy.
  ///
  /// - `capacity`: Total number of seats/chairs.
  /// - `tableSize`: The size of the table.
  /// - `margin`: Padding around the table used for spacing.
  /// - `shape`: Shape of the table (`circle`, `rectangle`, `square`).
  /// - `chairColor`: The color of the chairs (red if occupied, green if available).
  List<Widget> _buildChairs(
    int capacity,
    Size tableSize,
    double margin,
    String shape,
    Color chairColor,
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

  /// Builds a small icon button (edit/delete) used in the table overlay.
  ///
  /// Icon style and color changes based on type ("edit" or "delete").
  ///
  /// - `type`: Type of action ("edit" or "delete").
  /// - `onPressed`: Callback triggered when the button is tapped.
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
    } else if (type == "rotate") {
      icon = Icons.rotate_right; // Rotate icon
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue;
      iconColor = Colors.blue;
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

  /// Displays a popup dialog to enter guest details for the selected table.
  ///
  /// The dialog is dismissible and overlays the current screen.
  ///
  /// - `context`: The current BuildContext.
  /// - `index`: The index of the table being modified.
  /// - `tableData`: The table data for the selected table.
  void _showGuestDetailsPopup(
    BuildContext context,
    int index,
    Map<String, dynamic> tableData,
  ) {
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
            placedTables: placedTables,
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

  Widget _buildSharedAreaFilter() {
    if (areaNames.isEmpty) return SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            areaNames.map((area) {
              final bool isSelected = selectedArea == area;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: TextButton(
                  onPressed: () => _selectArea(area),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        isSelected
                            ? const Color(0xFFFD6464)
                            : Colors.transparent,
                    foregroundColor: isSelected ? Colors.white : Colors.black87,
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
    );
  }

  /// Displays a confirmation dialog before deleting a placed table.
  ///
  /// Retrieves the selected table's name and area, then presents a confirmation
  /// dialog to the user. If confirmed, the table is removed from the `placedTables`
  /// list, its name is removed from the `_usedTableNames` set, and any active
  /// table selection or action menu is cleared.
  ///
  /// - `index`: The index of the table to be deleted from the `placedTables` list.
  void _showDeleteConfirmationDialog(int index) {
    final dbHelper = DatabaseHelper();
    final table = placedTables[index];
    final tableName = table['tableName'];
    final areaName = table['areaName'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteConfirmationDialog(
          tableName: tableName,
          areaName: areaName,
          onConfirm: () async {
            // First delete from database
            await dbHelper.deleteTableByNameAndArea(tableName, areaName);

            // Then remove from local state
            setState(() {
              final removedTable = placedTables.removeAt(index);
              _usedTableNames.remove(removedTable['tableName']);

              _selectedTableIndex = null;
              _showActionMenu = false;
            });
          },
        );
      },
    );
  }

  /// Builds the main UI layout for the table management screen.
  ///
  /// This screen allows users to view, interact with, and manage tables within different
  /// areas of a restaurant. It includes features like zoom controls, table setup, editing,
  /// and legend indicators.
  ///
  /// The layout includes:
  /// - A `TopBar` as the app bar.
  /// - A `TablePlacementWidget` as the main canvas for placing and interacting with tables.
  /// - `ZoomControlsWidget` for scaling the view.
  /// - A bottom navigation bar (`BottomNavBar`) when the setup popup is not shown.
  /// - A legend showing table status colors.
  /// - A blurred background and overlay when the edit popup is active.
  /// - A preview of the selected table with red dotted border during editing.
  /// - A “Table Setup” button that opens the `CreateTableWidget` panel on the right.
  /// - A right-side popup (`EditTablePopup`) for editing existing tables with overlap check logic.
  /// - A right-side slide-in panel (`CreateTableWidget`) for creating new tables and areas.
  ///
  /// Returns a `Scaffold` widget that holds all the layered UI elements.

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
          if (_currentViewMode == ViewMode.normal)
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 30,
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
                onTapOutside: _handleTapOutside,
              ),
            )
          else
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  top:
                      _currentViewMode == ViewMode.gridShapeBased ||
                              _currentViewMode == ViewMode.gridCommonImage
                          ? 80
                          : 20,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: Scrollbar(
                  controller: gridScrollController,
                  thumbVisibility: true,
                  thickness: 10,
                  radius: Radius.circular(8),
                  child: Transform.scale(
                    scale: _scale,
                    alignment:
                        Alignment.topLeft,
                    child: GridView.builder(
                      controller: gridScrollController,
                      itemCount: _filteredTables.length,
                      padding: EdgeInsets.all(10),
                      gridDelegate:
                          _currentViewMode == ViewMode.gridShapeBased
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
                          return _buildShapeBasedGridItem(
                            _filteredTables[index],
                            index,
                          );
                        } else {
                          return _buildCommonGridItem(
                            _filteredTables[index],
                            index,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Top Mode Switch Buttons
          Positioned(
            top: 20,
            left: 20,
            child: ViewLayoutDropdown(
              onModeSelected: (mode) {
                setState(() {
                  _currentViewMode = mode;
                });
              },
            ),
          ),

          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(child: _buildSharedAreaFilter()),
          ),

          // Zoom Controls
          ZoomControlsWidget(
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onScaleToFit: _scaleToFit,
          ),

          if (!_showPopup)
            BottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onNavItemTapped,
            ),

          // 8. Legend at bottom
          if (!_showPopup)
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
                        TableHelpers.getPlacedTableSize(
                              placedTables[_selectedTableIndex!]['capacity'],
                              placedTables[_selectedTableIndex!]['shape'],
                            ) *
                            0.8,
                        placedTables[_selectedTableIndex!]['guestCount'] ?? 0,
                        placedTables[_selectedTableIndex!]['rotation'] ?? 0.0,
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
                          return Path()..addRRect(
                            RRect.fromRectAndRadius(
                              Offset.zero & size,
                              Radius.circular(16),
                            ),
                          );
                        },
                        child: Container(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (placedTables.isEmpty && !_showPopup)
            Center(
              child: TableHelpers.buildAddContentPrompt(
                scale: _scale,
                onTap: _togglePopup,
              ),
            ),

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
                onUpdate: (updatedData) async {
                  final index = _editingTableIndex!;
                  final originalData = placedTables[index];
                  final shape = updatedData['shape'];
                  final capacity = updatedData['capacity'];

                  final currentSize = TableHelpers.getPlacedTableSize(
                    capacity,
                    shape,
                  );

                  bool needsReposition =
                      updatedData['areaName'] != originalData['areaName'] ||
                      _isOverlapping(
                        updatedData['position'] ?? originalData['position'],
                        currentSize,
                        skipIndex: index,
                        areaName: updatedData['areaName'],
                      );

                  if (needsReposition) {
                    Offset originalPos =
                        updatedData['position'] ?? originalData['position'];
                    Offset newPos = _findNonOverlappingPosition(
                      originalPos,
                      currentSize,
                      skipIndex: index,
                      areaName: updatedData['areaName'],
                    );
                    updatedData['position'] = newPos;
                  }

                  // Keep the ID in the updated table
                  updatedData['id'] = originalData['id'];

                  final dbHelper = DatabaseHelper();
                  await dbHelper.updateTable(updatedData['id'], {
                    'tableName': updatedData['tableName'],
                    'capacity': updatedData['capacity'],
                    'shape': updatedData['shape'],
                    'areaName': updatedData['areaName'],
                    'posX': updatedData['position'].dx,
                    'posY': updatedData['position'].dy,
                    'guestCount': updatedData['guestCount'] ?? 0,
                  });

                  setState(() {
                    _usedTableNames.remove(
                      _editingTableData!['tableName'].toString().toLowerCase(),
                    );
                    _usedTableNames.add(
                      updatedData['tableName'].toString().toLowerCase(),
                    );
                    placedTables[index] = updatedData;
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
              onAreaSelected:
                  (areaName) => setState(() => selectedArea = areaName),
              onAreaDeleted: _handleAreaDeletion,
            ),
          ),
        ],
      ),
    );
  }
}
