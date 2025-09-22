import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/Bloc Event/TableEvent.dart';
import '../../blocs/Bloc Event/ZoneEvent.dart';
import '../../blocs/Bloc Event/attendance_event.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/attendance_bloc.dart';
import '../../blocs/Bloc Logic/checkin_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/table_bloc.dart';
import '../../blocs/Bloc Logic/zone_bloc.dart';
import '../../blocs/Bloc State/ZoneState.dart';
import '../../blocs/Bloc State/attendance_state.dart';
import '../../blocs/Bloc State/table_state.dart';
import '../../local database/area_dao.dart';
import '../../local database/login_dao.dart';
import '../../local database/table_dao.dart';
import '../../models/UserPermissions.dart';
import '../../models/view_mode.dart';
import '../../repositories/checkin_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/table_merge_repository.dart';
import '../../repositories/table_repository.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/GlobalReservationMonitor.dart';
import '../../utils/SessionManager.dart';
import '../../utils/logger.dart';
import '../widgets/CreateTableWidget.dart';
import '../widgets/DeleteConfirmationDialog.dart';
import '../widgets/EditTablePopup.dart';
import '../widgets/MergeEditTablePopup.dart';
import '../widgets/ModeChangeDialog.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/ReservationInfoDialog.dart';
import '../widgets/TablePlacementWidget.dart';
import '../widgets/UnmergeTablePopup.dart';
import '../widgets/ViewLayout.dart';
import '../widgets/ZoomControlsWidget.dart';
import '../widgets/area_movement_notifier.dart';
import '../widgets/placed_table_widget.dart';
import '../widgets/table_grid_item.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/table_helpers.dart';
import 'CheckinPopup.dart';
import 'DailyAttendanceScreen.dart';
import 'dashboard screen.dart';
import 'guest_details_popup.dart';

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
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;

  const TablesScreen({
    Key? key,
    required this.loadedTables,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  _TablesScreenState createState() => _TablesScreenState();
}

ViewMode _currentViewMode = ViewMode.gridCommonImage;

class _TablesScreenState extends State<TablesScreen> {
  /// Current zoom scale applied to the floor plan canvas.
  double _scale = 1.0;

  /// Index of the currently selected bottom navigation tab.
  int _selectedIndex = 1;

  bool _isAddingTable = false;
  final tableRepository = TableRepository();
  bool _isDeletingTable = false;
  bool _showModeChangeDialog = false;
  bool _hasLoadedOnce = false;

  void _onNavItemTapped(int index) {
    NavigationHelper.handleNavigation(
      context,
      _selectedIndex,
      index,
      widget.pin,
      widget.token,
      widget.restaurantId,
      widget.restaurantName,
      _userPermissions,
    );
    setState(() {
      _selectedIndex = index;
    });
  }

  final GlobalKey _canvasKey = GlobalKey();
  bool _popupsHandled = false;
  bool _isCheckInDone = false;
  bool _isShiftCreating = false;

  /// Whether the add table/area popup is visible.
  bool _showPopup = false;

  final areaDao = AreaDao();
  final tableDao = TableDao();
  final loginDao = LoginDao();
  bool _isUpdating = false;

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

  bool _isDeletingArea = false;
  UserPermissions? _userPermissions;

  /// Data of the table currently being edited.
  Map<String, dynamic>? _editingTableData;

  final ScrollController gridScrollController = ScrollController();

  /// Index of the table currently being edited.
  int? _editingTableIndex;
  bool _isRotating = false;

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
  bool _isLoadingTables = true;
  final Map<String, GlobalKey> _areaKeys = {};

  List<Map<String, dynamic>> get _filteredTables {
    if (selectedArea == null || selectedArea!.isEmpty) return placedTables;
    return placedTables
        .where((table) => table['areaName'] == selectedArea)
        .toList();
  }

  List<Map<String, dynamic>> get _sortedFilteredTables {
    final sorted = List<Map<String, dynamic>>.from(_filteredTables);

    sorted.sort((a, b) {
      final nameA = a['tableName']?.toString() ?? '';
      final nameB = b['tableName']?.toString() ?? '';
      final numA = int.tryParse(RegExp(r'\d+').stringMatch(nameA) ?? '') ?? 0;
      final numB = int.tryParse(RegExp(r'\d+').stringMatch(nameB) ?? '') ?? 0;
      if (numA != numB) return numA.compareTo(numB);
      return nameA.compareTo(nameB);
    });

    return sorted;
  }

  List<String> get areaNames => _usedAreaNames.toList();

  void _selectArea(String area) {
    setState(() {
      selectedArea = area;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _areaKeys[area];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadZones();
    context.read<TableBloc>().add(LoadTablesEvent(widget.token));
    GlobalReservationMonitor().start(widget.token);
    GlobalReservationMonitor().reservationsNotifier.addListener(() {
      context.read<TableBloc>().add(LoadTablesEvent(widget.token));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_popupsHandled) return;
      _popupsHandled = true;

      final savedPermissions = await SessionManager.loadPermissions();
      if (savedPermissions != null) {
        setState(() {
          _userPermissions = savedPermissions;
          _currentViewMode =
              _userPermissions!.canDefaultLayout == 'gridCommonImage'
                  ? ViewMode.gridCommonImage
                  : ViewMode.normal;
        });
      }

      try {
        final currentShift = await EmployeeRepository().getCurrentShift(
          widget.token,
        );
        final shiftStatus = currentShift?['shift_status']?.toLowerCase();
        final shiftId = currentShift?['shift_id'];

        AppLogger.info("Shift Status: $shiftStatus, Shift ID: $shiftId");

        if (shiftStatus == 'closed' && shiftId != null) {
          setState(() => _isCheckInDone = false);
          context.read<AttendanceBloc>().add(
            InitializeAttendanceFlow(token: widget.token, pin: widget.pin),
          );
        } else if (shiftStatus == 'open' &&
            shiftId != null &&
            savedPermissions == null) {
          setState(() => _isCheckInDone = false);
          _showCheckInPopupDirectly();
        } else if (shiftStatus == 'open' && shiftId == null) {
          AppLogger.error(
            "Shift is open but shift_id is null. Cannot proceed reliably.",
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Shift data error. Please contact admin."),
            ),
          );
        } else {
          setState(() => _isCheckInDone = true);
        }
      } catch (e) {
        AppLogger.error("Shift check failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to verify shift status")),
        );
      }
    });
  }

  Future<void> _loadZones() async {
    try {
      final zoneRepository = ZoneRepository();
      final zones = await zoneRepository.getAllZones(widget.token);

      final zoneNames = zones.map((z) => z['zone_name'].toString()).toSet();

      setState(() {
        _usedAreaNames = zoneNames;
        if (selectedArea == null && _usedAreaNames.isNotEmpty) {
          selectedArea = _usedAreaNames.first;
        }
      });
    } catch (e) {
      AppLogger.error('Failed to load zones: $e');
    }
  }

  void _showCheckInPopupDirectly() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => BlocProvider(
            create: (_) => CheckInBloc(CheckInRepository()),
            child: Checkinpopup(
              token: widget.token,
              onCheckIn: () {
                Navigator.of(context).pop();
                setState(() => _isCheckInDone = true);
              },
              onCancel: () {
                Navigator.of(context).pop();
              },
              onPermissionsReceived: (permissions) {
                setState(() {
                  _userPermissions = permissions;
                  _currentViewMode =
                      _userPermissions!.canDefaultLayout == 'gridCommonImage'
                          ? ViewMode.gridCommonImage
                          : ViewMode.normal;
                });
              },
            ),
          ),
    );
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

    if (!_showPopup && selectedArea != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _areaKeys[selectedArea];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      });
    }
  }

  void _handleAreaNameUpdated(String oldName, String newName) {
    setState(() {
      _usedAreaNames.remove(oldName);
      _usedAreaNames.add(newName);

      for (var table in placedTables) {
        if (table['areaName'] == oldName) {
          table['areaName'] = newName;
        }
      }

      if (selectedArea == oldName) {
        selectedArea = newName;
      }
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

  void _rotateTable(int index) async {
    setState(() {
      _isRotating = true;
    });

    try {
      final table = placedTables[index];
      final currentRotation = table['rotation'] ?? 0.0;
      final newRotation = currentRotation == 0.0 ? 90.0 : 0.0;

      final shape = table['shape'];
      final capacity = table['capacity'];
      final areaName = table['areaName'];
      final tableName = table['tableName'];

      Size newSize = TableHelpers.getPlacedTableSize(capacity, shape);
      if (shape == 'rectangle' && newRotation == 90.0) {
        newSize = Size(newSize.height, newSize.width);
      }

      final currentPos = table['position'] as Offset;
      Offset newPos = currentPos;

      final willOverlap = _isOverlapping(
        currentPos,
        newSize,
        skipIndex: index,
        areaName: areaName,
      );

      if (willOverlap) {
        newPos = _findNonOverlappingPosition(
          currentPos,
          newSize,
          skipIndex: index,
          areaName: areaName,
        );
      }

      newPos = _clampPositionToCanvas(newPos, newSize);

      final updatedData = Map<String, dynamic>.from(table);
      updatedData['rotation'] = newRotation;
      updatedData['position'] = newPos;

      await tableRepository.updateTableOnServerAndLocal(
        tableData: updatedData,
        token: widget.token,
        pin: widget.pin,
        tableDao: tableDao,
      );

      setState(() {
        placedTables[index]['rotation'] = newRotation;
        placedTables[index]['position'] = newPos;
        placedTables[index]['posX'] = newPos.dx;
        placedTables[index]['posY'] = newPos.dy;
        _selectedTableIndex = null;
        _showActionMenu = false;
      });
      AreaMovementNotifier.showPopup(
        context: context,
        fromArea: '',
        toArea: '',
        tableName: tableName,
        oldRotation: currentRotation,
        newRotation: newRotation,
        oldPos: currentPos,
        newPos: newPos,
      );
    } catch (e) {
      AppLogger.error('Rotation failed: $e');
    } finally {
      setState(() {
        _isRotating = false;
      });
    }
  }

  void _handleTapOutside() {
    setState(() {
      _selectedTableIndex = -1;
      _showActionMenu = false;
    });
  }

  bool isReservationTimePassed(String dateStr, String timeStr) {
    try {
      final now = DateTime.now();
      final combinedStr = '$dateStr $timeStr';
      final format = DateFormat('yyyy-MM-dd hh:mm a');
      final reservationDateTime = format.parse(combinedStr);

      return now.isAfter(reservationDateTime);
    } catch (e) {
      return false;
    }
  }

  Future<void> _showTableActionPopup(
      BuildContext context,
      int index,
      Map<String, dynamic> tableData,
      ) async {
    final bool isMerged = tableData['is_merged'] ?? false;
    final String mergedTables = tableData['merged_tables'] ?? tableData['tableName'] ?? '';

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFF9F6F6),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          contentPadding: const EdgeInsets.all(25),
          content: IntrinsicHeight(
            child: SizedBox(
              width: 450,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Title + Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 28),
                      const Expanded(
                        child: Text(
                          "Merge/Modify Tables",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5A5A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: isMerged
                          ? [
                        const TextSpan(
                          text: "This table is already merged with the following tables in ",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                        TextSpan(
                          text: "${tableData['areaName']}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text: ". Modify this merge or unmerge to restore individual tables.\n\n",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                        TextSpan(
                          text: mergedTables,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ]
                          : [
                        const TextSpan(
                          text: "Select the tables you want to merge in this ",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                        TextSpan(
                          text: "${tableData['areaName']}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text: ". Merging will combine them into a single reservation under the same guest.",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  /// Buttons row (Unmerge / Merge/Edit)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Unmerge Button
                      SizedBox(
                        width: 170,
                        height: 150,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: isMerged
                                ? const Color(0xFFFFE6E6)
                                : Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isMerged
                              ? () {
                            Navigator.of(ctx).pop();
                            showDialog(
                              context: context,
                              builder: (_) => UnmergeTablePopup(
                                index: index,
                                tableData: tableData,
                                token: widget.token,
                                repository: TableMergeRepository(),
                                onUnmerge: (i, data) async {
                                  setState(() {
                                    placedTables[i]['is_merged'] = false;
                                  });

                                  AreaMovementNotifier.showPopup(
                                    context: context,
                                    fromArea: data['areaName'] ?? '',
                                    toArea: '',
                                    tableName: data['tableName'] ?? '',
                                    customMessage: 'Table unmerged successfully',
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Table ${data['tableName']} unmerged'),
                                    ),
                                  );

                                  context.read<TableBloc>().add(LoadTablesEvent(widget.token));
                                },
                              ),
                            );
                          }
                              : null,
                          child: Text(
                            "Unmerge Table",
                            style: TextStyle(
                              color: isMerged ? Colors.red : Colors.black26,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 30),

                      /// Merge/Edit Button
                      SizedBox(
                        width: 170,
                        height: 150,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A5A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            showDialog(
                              context: context,
                              builder: (_) => MergeEditTablePopup(
                                index: index,
                                tableData: tableData,
                                token: widget.token,
                                onMergeEdit: (i, data) async {
                                  setState(() {
                                    placedTables[i]['is_merged'] = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Table ${data['table_name']} merged/edited'),
                                    ),
                                  );

                                  context
                                      .read<TableBloc>()
                                      .add(LoadTablesEvent(widget.token));
                                },
                              ),
                            );
                          },
                          child: const Text(
                            "Merge/Edit\nTable",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
    final capacity = int.tryParse(tableData['capacity']?.toString() ?? '0') ?? 0;
    final mergedTables = tableData['merged_tables'] ?? tableData['tableName'] ?? '';
    final area = tableData['areaName'];
    final shape = tableData['shape'];
    final Offset position = tableData['position'];
    final double rotation = double.tryParse(tableData['rotation']?.toString() ?? '0') ?? 0.0;
    final bool isMerged = tableData['is_merged'] ?? false;

    final size = TableHelpers.getPlacedTableSize(capacity, shape);

    final String status = tableData['status'] ?? 'Available';
    Widget tableContent = PlacedTableBuilder.buildPlacedTableWidget(
      name: mergedTables,
      capacity: capacity,
      area: area,
      shape: shape,
      size: size,
      rotation: rotation,
      status: status,
      isMerged: isMerged,
    );

    Widget paddedTable = Padding(
      padding: const EdgeInsets.all(8.0),
      child: tableContent,
    );

    Widget borderedTable = Stack(
      clipBehavior: Clip.none,
      children: [
        DottedBorder(
          color: _selectedTableIndex == index && _showActionMenu
              ? Colors.red
              : Colors.transparent,
          strokeWidth: 2,
          dashPattern: [4, 3],
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          child: paddedTable,
        ),
      ],
    );

    int quarterTurns = (rotation ~/ 90) % 4;

    Widget gestureTable = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final statusLower = status.toLowerCase();
        final reservationDateStr = tableData['reservationDate'];
        final reservationTimeStr = tableData['reservationTime'];

        if (capacity == 0) {
          AreaMovementNotifier.showPopup(
            context: context,
            fromArea: area ?? '',
            toArea: '',
            tableName: mergedTables,
            customMessage: 'Unable to order: This is a child table. Please order from parent table',
          );
          return;
        }

        if (statusLower == 'reserve' &&
            reservationDateStr != null &&
            reservationTimeStr != null &&
            !isReservationTimePassed(reservationDateStr, reservationTimeStr)) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => ReservationInfoDialog(
              reservationDate: reservationDateStr,
              reservationTime: reservationTimeStr,
              onOk: () {
                Navigator.of(context).pop();
                if (!_showPopup) {
                  _showGuestDetailsPopup(context, index, tableData);
                }
              },
            ),
          );
          return;
        }

        if (!_showPopup) {
          _showGuestDetailsPopup(context, index, tableData);
        }
      },
      onDoubleTap: (_userPermissions == null ||
          !_userPermissions!.canDoubleTap ||
          status.toLowerCase() != 'available')
          ? null
          : () {
        if (!_showPopup) {
          if (isMerged) {
            AreaMovementNotifier.showPopup(
              context: context,
              fromArea: area ?? '',
              toArea: '',
              tableName: mergedTables,
              customMessage:
              'You are unable to edit or delete this table because it is merged. Please unmerge the table first.',
            );
            return;
          }
          setState(() {
            _selectedTableIndex = index;
            _showActionMenu = true;
          });
        }
      },
      onLongPress: () {
        if (capacity == 0) {
          AreaMovementNotifier.showPopup(
            context: context,
            fromArea: tableData['areaName'] ?? '',
            toArea: '',
            tableName: tableData['tableName'] ?? '',
            customMessage: 'Unable to Edit Merge: This is a child table. Please Edit from parent table',
          );
          return;
        }
        if (status.toLowerCase() == 'reserve') {
          AreaMovementNotifier.showPopup(
            context: context,
            fromArea: area ?? '',
            toArea: '',
            tableName: mergedTables,
            customMessage: 'You cannot merge a reserved table',
          );
          return;
        }
        _showTableActionPopup(context, index, tableData);
      },
      child: RotatedBox(quarterTurns: quarterTurns, child: borderedTable),
    );

    Widget actionButtons =
    (_showPopup || (_selectedTableIndex == index && _showActionMenu))
        ? Positioned(
      top: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 4.0,
        ),
        child: Column(
          children: [
            if (!_showPopup)
              _buildActionButton("edit", () {
                setState(() {
                  _editingTableIndex = index;
                  _editingTableData =
                  Map<String, dynamic>.from(tableData);
                  _showEditPopup = true;
                  _showActionMenu = false;
                });
              }),
            if (status.toLowerCase() == 'available')
              _buildActionButton("delete", () {
                _showDeleteConfirmationDialog(index);
              }),
            if (!_showPopup) const SizedBox(height: 6),
            if (shape == 'rectangle' &&
                status.toLowerCase() == 'available')
              _buildActionButton("rotate", () {
                _rotateTable(index);
              }),
          ],
        ),
      ),
    )
        : const SizedBox.shrink();

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
              if (_canvasKey.currentContext == null) return;
              final RenderBox box =
              _canvasKey.currentContext!.findRenderObject() as RenderBox;
              final Offset localOffset =
              box.globalToLocal(details.offset);
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
  Widget _buildShapeBasedGridItem(
    Map<String, dynamic> tableData,
    int filteredIndex,
  ) {
    final actualIndex = placedTables.indexOf(tableData);
    final int capacity = int.tryParse(tableData['capacity']?.toString() ?? '0') ?? 0;

    return ShapeBasedGridItem(
      tableData: tableData,
      onTap: () {
        final status = tableData['status']?.toLowerCase() ?? 'available';
        final reservationDateStr = tableData['reservationDate'];
        final reservationTimeStr = tableData['reservationTime'];

        if (capacity == 0) {
          AreaMovementNotifier.showPopup(
            context: context,
            fromArea: tableData['areaName'] ?? '',
            toArea: '',
            tableName: tableData['tableName'] ?? '',
            customMessage: 'Unable to order: This is a child table. Please order from parent table',
          );
          return;
        }

        if (status == 'reserve' &&
            reservationDateStr != null &&
            reservationTimeStr != null &&
            !isReservationTimePassed(reservationDateStr, reservationTimeStr)) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => ReservationInfoDialog(
              reservationDate: reservationDateStr,
              reservationTime: reservationTimeStr,
              onOk: () {
                Navigator.of(context).pop();
                if (!_showPopup) {
                  _showGuestDetailsPopup(context, actualIndex, tableData);
                }
              },
            ),
          );
          return;
        }

        if (!_showPopup) {
          _showGuestDetailsPopup(context, actualIndex, tableData);
        }
      },
      onLongPress: () {
        if (capacity == 0) {
          AreaMovementNotifier.showPopup(
            context: context,
            fromArea: tableData['areaName'] ?? '',
            toArea: '',
            tableName: tableData['tableName'] ?? '',
            customMessage: 'Unable to Edit Merge: This is a child table. Please Edit from parent table',
          );
          return;
        }
        final status = tableData['status']?.toLowerCase() ?? 'available';
        if (status == 'reserve') {
          AreaMovementNotifier.showPopup(
            context: context,
            fromArea: tableData['areaName'] ?? '',
            toArea: '',
            tableName: tableData['tableName'] ?? '',
            customMessage: 'You cannot merge a reserved table',
          );
          return;
        }
        _showTableActionPopup(context, actualIndex, tableData);
      },
    );
  }

  Widget _buildCommonGridItem(
    Map<String, dynamic> tableData,
    int filteredIndex,
  ) {
    final actualIndex = placedTables.indexOf(tableData);
    final int capacity = int.tryParse(tableData['capacity']?.toString() ?? '0') ?? 0;

    return CommonGridItem(
      tableData: tableData,
      onTap: () {
        final status = tableData['status']?.toLowerCase() ?? 'available';
        final reservationDateStr = tableData['reservationDate'];
        final reservationTimeStr = tableData['reservationTime'];

        if (capacity == 0) {
          AreaMovementNotifier.showPopup(
            context: context,
            fromArea: tableData['areaName'] ?? '',
            toArea: '',
            tableName: tableData['tableName'] ?? '',
            customMessage: 'Unable to order: This is a child table. Please order from parent table',
          );
          return;
        }

        if (status == 'reserve' &&
            reservationDateStr != null &&
            reservationTimeStr != null &&
            !isReservationTimePassed(reservationDateStr, reservationTimeStr)) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => ReservationInfoDialog(
              reservationDate: reservationDateStr,
              reservationTime: reservationTimeStr,
              onOk: () {
                Navigator.of(context).pop();
                if (!_showPopup) {
                  _showGuestDetailsPopup(context, actualIndex, tableData);
                }
              },
            ),
          );
          return;
        }

        if (!_showPopup) {
          _showGuestDetailsPopup(context, actualIndex, tableData);
        }
      },
      onLongPress: () {
        if (capacity == 0) {
          AreaMovementNotifier.showPopup(
            context: context,
            fromArea: tableData['areaName'] ?? '',
            toArea: '',
            tableName: tableData['tableName'] ?? '',
            customMessage: 'Unable to Edit Merge: This is a child table. Please Edit from parent table',
          );
          return;
        }
        final status = tableData['status']?.toLowerCase() ?? 'available';
        if (status == 'reserve') {
          AreaMovementNotifier.showPopup(
            context: context,
            fromArea: tableData['areaName'] ?? '',
            toArea: '',
            tableName: tableData['tableName'] ?? '',
            customMessage: 'You cannot merge a reserved table',
          );
          return;
        }
        _showTableActionPopup(context, actualIndex, tableData);
      },
    );
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
  /// Updates the position of an existing table at [index] to [newPosition].
  ///
  /// Clamps and adjusts the position to avoid overlap with other tables in the same area.
  /// If the new position causes overlap with other tables, tries to adjust those tables' positions as well.
  void _updateTablePosition(int index, Offset newPosition) async {
    final tableRepository = TableRepository();
    final table = placedTables[index];
    final shape = table['shape'];
    final capacity = table['capacity'];
    final areaName = table['areaName'];
    final rotation = table['rotation'] ?? 0.0;
    final tableName = table['tableName'];

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
      placedTables[index]['posX'] = adjustedPos.dx;
      placedTables[index]['posY'] = adjustedPos.dy;
      _selectedTableIndex = -1;
      _showActionMenu = false;
    });

    for (int i = 0; i < placedTables.length; i++) {
      if (i == index) continue;
      final other = placedTables[i];
      if (other['areaName'] != areaName) continue;

      final otherPos = other['position'] as Offset;
      final otherShape = other['shape'];
      final otherCapacity = other['capacity'];
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

        final otherTableIdRaw = other['table_id'];
        final otherTableId = int.tryParse(otherTableIdRaw?.toString() ?? '');
        if (otherTableId != null) {
          await tableDao.updateTable(otherTableId, {
            'posX': newOtherPos.dx,
            'posY': newOtherPos.dy,
          });
        } else {
          AppLogger.error(
            'Invalid other table_id at index $i: $otherTableIdRaw',
          );
        }
      }
    }

    final updatedData = Map<String, dynamic>.from(table);
    updatedData['position'] = adjustedPos;
    updatedData['rotation'] = rotation;
    updatedData['tableName'] = tableName;

    await tableRepository.updateTableOnServerAndLocal(
      tableData: updatedData,
      token: widget.token,
      pin: widget.pin,
      tableDao: tableDao,
    );
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
      icon = Icons.rotate_right;
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
            onGuestSaved: (guestDetails) async {
              final tableId = tableData['id'];
              final zoneId = tableData['zone_id'];
              final tableName = tableData['name'] ?? 'Table';
              final zoneName = tableData['zone_name'] ?? 'Main Zone';


              AppLogger.info("Guest details saved");
              AppLogger.info("Guest Count: ${guestDetails.guestCount}");
              AppLogger.info("Table ID: $tableId, Zone ID: $zoneId");

              try {
                final orderRepo = OrderRepository(
                    baseUrl: 'https://merchantrestaurant.alektasolutions.com');

                final orderModel = await orderRepo.createOrder(
                  restaurantId: '1',
                  tableId: tableId,
                  zoneId: zoneId,
                  guests: [guestDetails],
                  guestCount: guestDetails.guestCount,
                  token: 'YOUR_VALID_TOKEN_HERE',
                  zoneName: zoneName,
                  restaurantName: 'My Restaurant',
                  tableName: tableName, // ✅ pass correct table name
                );

                AppLogger.info("✅ Order created via API with Order ID: ${orderModel.orderId}");

                context.read<OrderBloc>().add(CreateOrderSuccess(orderId: orderModel.orderId));



                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<OrderBloc>(),
                      child: DashboardScreen(
                        guestDetails: guestDetails,
                        token: "YOUR_VALID_TOKEN_HERE",
                        restaurantId: '1',
                        orderId: orderModel.orderId,
                        tableId: tableId,
                        zoneId: zoneId,
                        zoneName: tableData['zone_name'] ?? 'Main Zone',
                        tableName: tableData['name'] ?? 'Table',
                      ),
                    ),
                  ),
                );

                AppLogger.info("Navigated to DashboardScreen with Order ID: ${orderModel.orderId}");
              } catch (e) {
                AppLogger.error(" Failed to create order: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to create order, please try again.")),
                );
              }
            },
            token: '',
            restaurantId: '1',
          ),
        );
      },
    );
  }


  Widget _buildSharedAreaFilter() {
    if (areaNames.isEmpty) return SizedBox.shrink();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 370),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: gridScrollController,
          child: Row(
            children:
                areaNames.map((area) {
                  _areaKeys.putIfAbsent(area, () => GlobalKey());

                  final bool isSelected = selectedArea == area;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Container(
                      key: _areaKeys[area],
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
                    ),
                  );
                }).toList(),
          ),
        ),
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
    final table = placedTables[index];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteConfirmationDialog(
          tableName: table['tableName'],
          areaName: table['areaName'],
          onConfirm: () {
            context.read<TableBloc>().add(
              DeleteTableEvent(table: table, token: widget.token),
            );
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

    return MultiBlocListener(
      listeners: [
        /// Listener for TableBloc
        BlocListener<TableBloc, TableState>(
          listener: (context, state) {
            if (state is TableLoadingState) {
              if (!_hasLoadedOnce) {
                setState(() => _isLoadingTables = true);
              }
            } else if (state is TableLoadedState) {
              setState(() {
                placedTables = state.tables;
                _usedTableNames = state.usedTableNames;
                _isLoadingTables = false;
                _hasLoadedOnce = true;
              });
            } else if (state is TableLoadErrorState) {
              setState(() {
                _isLoadingTables = false;
                _hasLoadedOnce = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load tables: ${state.error}'),
                ),
              );
            } else if (state is TableAddingState) {
              setState(() => _isAddingTable = true);
            } else if (state is TableAddedState) {
              setState(() {
                placedTables.add(state.tableData);
                _usedTableNames.add(
                  state.tableData['tableName'].toString().toLowerCase(),
                );
                _usedAreaNames.add(state.tableData['areaName']);
                selectedArea = state.tableData['areaName'];
                _isAddingTable = false;
              });
            } else if (state is TableDeletingState) {
              setState(() => _isDeletingTable = true);
            } else if (state is TableDeletedState) {
              final deletedName = state.tableName.toLowerCase();
              final index = placedTables.indexWhere(
                (table) =>
                    table['tableName'].toString().toLowerCase() == deletedName,
              );
              if (index != -1) {
                final removed = placedTables[index];
                setState(() {
                  placedTables.removeAt(index);
                  _usedTableNames.remove(
                    removed['tableName'].toString().toLowerCase(),
                  );
                  _selectedTableIndex = null;
                  _showActionMenu = false;
                  _isDeletingTable = false;
                });
              }
            }
          },
        ),

        /// Listener for ZoneBloc (Area management)
        BlocListener<ZoneBloc, ZoneState>(
          listener: (context, state) async {
            if (state is ZoneDeleteSuccess) {
              final areaName = state.areaName;

              AreaMovementNotifier.showPopup(
                context: context,
                fromArea: areaName,
                toArea: '',
                tableName: 'Area',
              );

              setState(() {
                final tablesToRemove =
                    placedTables
                        .where((t) => t['areaName'] == areaName)
                        .map((t) => t['tableName'].toString().toLowerCase())
                        .toList();

                placedTables.removeWhere((t) => t['areaName'] == areaName);
                _usedAreaNames.remove(areaName);
                _usedTableNames.removeAll(tablesToRemove);
                if (selectedArea == areaName) {
                  selectedArea =
                      _usedAreaNames.isNotEmpty ? _usedAreaNames.first : '';
                }

                _isDeletingArea = false;
              });
              final zoneRepository = RepositoryProvider.of<ZoneRepository>(
                context,
              );
              final updatedZones = await zoneRepository.getAllZones(
                widget.token,
              );
              final updatedAreaNames =
                  updatedZones
                      .map((z) => z['zone_name'].toString())
                      .toSet()
                      .cast<String>();

              setState(() {
                _usedAreaNames = updatedAreaNames;
              });
            }
          },
        ),
        BlocListener<AttendanceBloc, AttendanceState>(
          listener: (context, state) async {
            if (state is AttendancePopupReady) {
              final currentShift = await EmployeeRepository().getCurrentShift(
                widget.token,
              );

              final isValidShift =
                  currentShift != null &&
                  currentShift['shift_status']?.toLowerCase() == 'open' &&
                  currentShift['shift_id'] != null &&
                  currentShift['user_id'] != 0 &&
                  currentShift['start_time'] != false;

              if (isValidShift) {
                if (!_isCheckInDone) _showCheckInPopupDirectly();
                return;
              }

              if (_isCheckInDone) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (_) => AttendancePopup(
                      employees: state.employees,
                      token: widget.token,
                      onComplete: (String extractedStartTime) async {
                        _showCheckInPopupDirectly();
                      },
                    ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F3FC),
        resizeToAvoidBottomInset: false,
        appBar: TopBar(
          token: widget.token,
          pin: widget.pin,
          userPermissions: _userPermissions,
          onPermissionsReceived: (permissions) {
            setState(() {
              _userPermissions = permissions;
              if (_userPermissions!.canDefaultLayout == 'gridCommonImage') {
                _currentViewMode = ViewMode.gridCommonImage;
              } else {
                _currentViewMode = ViewMode.normal;
              }
            });
          }, restaurantId: 'widget.restaurantId',
        ),
        body: Stack(
          children: [
            if (_currentViewMode == ViewMode.normal)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 30,
                left: 0,
                right: _showPopup ? popupWidth : 0,
                bottom: 0,
                child:
                    _isLoadingTables
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0A1B4D),
                          ),
                        )
                        : Stack(
                          children: [
                            TablePlacementWidget(
                              placedTables: placedTables,
                              scale: _scale,
                              showPopup: _showPopup,
                              addTable: (data, position) {
                                context.read<TableBloc>().add(
                                  AddTableEvent(
                                    tableData: data,
                                    position: position,
                                    token: widget.token,
                                    pin: int.parse(widget.pin),
                                  ),
                                );
                              },
                              updateTablePosition: _updateTablePosition,
                              buildAddContentPrompt:
                                  () => const SizedBox.shrink(),
                              buildPlacedTable: _buildPlacedTable,
                              selectedArea: selectedArea ?? '',
                              onTapOutside: _handleTapOutside,
                              isLoading: _isLoadingTables,
                            ),
                            if (_filteredTables.isEmpty &&
                                areaNames.isNotEmpty &&
                                !_showPopup)
                              Positioned(
                                top: MediaQuery.of(context).size.height * 0.32,
                                left: 20,
                                right: 20,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF0A1B4D),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            'No tables have been added in this area yet.\n Click the',
                                        style: TextStyle(height: 1.4),
                                      ),
                                      TextSpan(
                                        text: ' "Table Setup"',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          height: 1.4,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            ' button to create and arrange your tables.',
                                        style: TextStyle(height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
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
                  child:
                      _isLoadingTables
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0A1B4D),
                            ),
                          )
                          : (_filteredTables.isEmpty &&
                              areaNames.isNotEmpty &&
                              !_showPopup)
                          ? Stack(
                            children: [
                              Positioned(
                                top: MediaQuery.of(context).size.height * 0.25,
                                left: 20,
                                right: 20,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF0A1B4D),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            'No tables have been added in this area yet.\n Click the',
                                        style: TextStyle(height: 1.4),
                                      ),
                                      TextSpan(
                                        text: ' "Table Setup"',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          height: 1.4,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            ' button to create and arrange your tables.',
                                        style: TextStyle(height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Scrollbar(
                            controller: gridScrollController,
                            thumbVisibility: true,
                            thickness: 10,
                            radius: const Radius.circular(8),
                            child: Transform.scale(
                              scale: _scale,
                              alignment: Alignment.topLeft,
                              child: GridView.builder(
                                controller: gridScrollController,
                                itemCount: _sortedFilteredTables.length,
                                padding: const EdgeInsets.all(10),
                                gridDelegate: _currentViewMode == ViewMode.gridShapeBased
                                    ? const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 0.9,
                                )
                                    : const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 11,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 1.0,
                                ),
                                itemBuilder: (context, index) {
                                  final table = _sortedFilteredTables[index];
                                  return _currentViewMode == ViewMode.gridShapeBased
                                      ? _buildShapeBasedGridItem(table, index)
                                      : _buildCommonGridItem(table, index);
                                },
                              ),
                            ),
                          ),
                ),
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
                userPermissions: _userPermissions,
              ),

            // 8. Legend at bottom
            if (!_showPopup)
              Positioned(
                left: 0,
                right: 0,
                bottom: 70,
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
                        TableHelpers.buildLegendDot(Colors.grey, "Reserve"),
                        SizedBox(width: 20),
                        TableHelpers.buildLegendDot(
                          Colors.blue,
                          "Ready to Pay",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_showEditPopup)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withAlpha((0.3 * 255).toInt()),
                  ),
                ),
              ),
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
                        child: PlacedTableBuilder.buildPlacedTableWidget(
                          name: placedTables[_selectedTableIndex!]['tableName'],
                          capacity:
                              placedTables[_selectedTableIndex!]['capacity'],
                          area: placedTables[_selectedTableIndex!]['areaName'],
                          shape: placedTables[_selectedTableIndex!]['shape'],
                          size:
                              TableHelpers.getPlacedTableSize(
                                placedTables[_selectedTableIndex!]['capacity'],
                                placedTables[_selectedTableIndex!]['shape'],
                              ) *
                              0.8,
                          rotation:
                              placedTables[_selectedTableIndex!]['rotation'] ??
                              0.0,
                          status:
                              placedTables[_selectedTableIndex!]['status'] ??
                              'Available',
                        ),
                      ),
                    ),
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

            if (placedTables.isEmpty &&
                areaNames.isEmpty &&
                !_showPopup &&
                !_isLoadingTables)
              Center(
                child: TableHelpers.buildAddContentPrompt(
                  scale: _scale,
                  onTap: _togglePopup,
                ),
              ),

            Positioned(
              top: 20,
              left: 30,
              right: 30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!_showPopup)
                    ViewLayoutToggle(
                      selectedMode: _currentViewMode,
                      onModeSelected: (mode) {
                        setState(() {
                          _currentViewMode = mode;
                        });
                      },
                    ),

                  if (!_showPopup) const SizedBox(width: 20),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: _buildSharedAreaFilter(),
                    ),
                  ),

                  if (!_showPopup) const SizedBox(width: 20),

                  Builder(
                    builder: (context) {
                      final hasPermission =
                          areaNames.isNotEmpty &&
                          !_showPopup &&
                          _userPermissions != null &&
                          _userPermissions!.canSetupTables;

                      return Container(
                        decoration: BoxDecoration(
                          color:
                              hasPermission
                                  ? const Color(0xFF15315E)
                                  : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(25, 0, 0, 0),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: InkWell(
                          onTap: () {
                            if (hasPermission) {
                              if (_currentViewMode != ViewMode.normal) {
                                setState(() => _showModeChangeDialog = true);
                              } else {
                                _togglePopup();
                              }
                            } else {
                              AreaMovementNotifier.showPopup(
                                context: context,
                                fromArea: '',
                                toArea: '',
                                tableName: 'Table Setup',
                                customMessage:
                                    "No permission to access Table Setup",
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Table Setup',
                                style: TextStyle(
                                  color:
                                      hasPermission
                                          ? Colors.white
                                          : Colors.grey.shade200,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                color:
                                    hasPermission
                                        ? Colors.white
                                        : Colors.grey.shade200,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            if (_showEditPopup)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 0,
                right: 0,
                bottom: 0,
                width: popupWidth,
                child: EditTablePopup(
                  token: widget.token,
                  tableData: _editingTableData!,
                  usedTableNames: _usedTableNames,
                  isUpdating: _isUpdating,
                  onUpdate: (updatedData) async {
                    setState(() => _isUpdating = true);

                    final index = _editingTableIndex!;
                    final originalData = placedTables[index];
                    final oldArea = originalData['areaName'];
                    final newArea = updatedData['areaName'];

                    final oldPos = originalData['position'] as Offset;
                    final newPos = updatedData['position'] as Offset? ?? oldPos;

                    final oldRotation = originalData['rotation'] ?? 0.0;
                    final newRotation =
                        double.tryParse(
                          updatedData['rotation']?.toString() ?? '',
                        ) ??
                        oldRotation;

                    final shape = updatedData['shape'];
                    final capacity = updatedData['capacity'];
                    final currentSize = TableHelpers.getPlacedTableSize(
                      capacity,
                      shape,
                    );

                    bool needsReposition =
                        newArea != oldArea ||
                        _isOverlapping(
                          newPos,
                          currentSize,
                          skipIndex: index,
                          areaName: newArea,
                        );

                    Offset finalPos = newPos;
                    if (needsReposition) {
                      finalPos = _findNonOverlappingPosition(
                        newPos,
                        currentSize,
                        skipIndex: index,
                        areaName: newArea,
                      );
                      updatedData['position'] = finalPos;
                    }

                    final serverTableId = originalData['table_id'];
                    final localTableId = originalData['id'];
                    final updateId = localTableId ?? serverTableId;

                    if (updateId == null) {
                      AppLogger.error('Missing table ID during edit update.');
                      setState(() => _isUpdating = false);
                      return;
                    }

                    updatedData['table_id'] = serverTableId;
                    updatedData['rotation'] = newRotation;

                    await TableRepository().updateTableOnServerAndLocal(
                      tableData: updatedData,
                      token: widget.token,
                      pin: widget.pin,
                      tableDao: tableDao,
                    );

                    AreaMovementNotifier.showPopup(
                      context: context,
                      fromArea: oldArea,
                      toArea: newArea,
                      tableName: updatedData['tableName'],
                      oldRotation: oldRotation.toDouble(),
                      newRotation: newRotation.toDouble(),
                    );

                    if (oldArea != newArea) {
                      setState(() => selectedArea = newArea);
                    }

                    setState(() {
                      _usedTableNames.remove(
                        _editingTableData!['tableName']
                            .toString()
                            .toLowerCase(),
                      );
                      _usedTableNames.add(
                        updatedData['tableName'].toString().toLowerCase(),
                      );
                      placedTables[index] = updatedData;
                      _showEditPopup = false;
                      _editingTableData = null;
                      _editingTableIndex = null;
                      _isUpdating = false;
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
            Stack(
              children: [
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
                        _usedAreaNames.add(areaName);
                        _areaKeys[areaName] = GlobalKey();
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final key = _areaKeys[areaName];
                        if (key != null && key.currentContext != null) {
                          Scrollable.ensureVisible(
                            key.currentContext!,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: 0.5,
                          );
                        }
                      });
                    },
                    onAreaDeleted: (areaName) {
                      setState(() => _isDeletingArea = true);
                      context.read<ZoneBloc>().add(
                        DeleteAreaEvent(
                          areaName: areaName,
                          token: widget.token,
                        ),
                      );
                    },
                    onAreaNameUpdated: _handleAreaNameUpdated,
                    onDeleteAreaStarted:
                        () => setState(() => _isDeletingArea = true),
                    pin: widget.pin,
                    token: widget.token,
                    restaurantId: widget.restaurantId,
                  ),
                ),

                if (_isDeletingArea)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                if (_isAddingTable)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x88000000),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0A1B4D),
                        ),
                      ),
                    ),
                  ),
                if (_isDeletingTable)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x88000000),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                if (_showModeChangeDialog)
                  ModeChangeDialog(
                    onCancel: () {
                      setState(() {
                        _showModeChangeDialog = false;
                      });
                    },
                    onContinue: () {
                      setState(() {
                        _currentViewMode = ViewMode.normal;
                        _showModeChangeDialog = false;
                      });
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _togglePopup();
                      });
                    },
                  ),

                if (_isRotating)
                  Positioned.fill(
                    child: Container(
                      color: Color(0x88000000),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0A1B4D),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
