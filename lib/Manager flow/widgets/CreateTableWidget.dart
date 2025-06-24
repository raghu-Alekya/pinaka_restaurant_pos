import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Logic/zone_bloc.dart';
import '../../helpers/DatabaseHelper.dart';
import '../../repositories/zone_repository.dart';
import 'AreaPopup.dart';
import 'DeleteConfirmationPopup.dart';
import 'DraggableTable.dart';
import 'EmptyAreaPlaceholder.dart';
import 'TableSetupHeader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



/// A widget that allows creating areas (zones) and tables within those areas.
/// Supports adding/deleting areas, entering table names and seating capacities,
/// and selecting table models with validation and duplicate checks.
class CreateTableWidget extends StatefulWidget {
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) getTableData;
  final Set<String> usedTableNames;
  final Set<String> usedAreaNames;
  final Function(String) onAreaSelected;
  final Function(String) onAreaDeleted;
  final Function(String oldName, String newName) onAreaNameUpdated; // ✅ Add this
  final String pin;
  final String token;


  const CreateTableWidget({
    Key? key,
    required this.onClose,
    required this.getTableData,
    required this.usedTableNames,
    required this.usedAreaNames,
    required this.onAreaSelected,
    required this.onAreaDeleted,
    required this.onAreaNameUpdated, // ✅ Add this
    required this.pin,
    required this.token,
  }) : super(key: key);


  @override
  _CreateTableWidgetState createState() => _CreateTableWidgetState();
}


class _CreateTableWidgetState extends State<CreateTableWidget> {
  // Controls visibility of the area creation popup.
  bool _isPopupVisible = false;

  // Controls visibility of the delete confirmation popup.
  bool _isDeleteConfirmationVisible = false;

  // Flags duplicate area name error state.
  bool _isDuplicateName = false;

  // Error message for area name input.
  String _errorMessage = '';
  String? _selectedAreaForOptions;
  String? _selectedAreaForEdit;
  bool _showOptionsPopup = false;
  bool _showEditPopup = false;


  // Text controllers for area name, table name, and seating capacity inputs.
  final TextEditingController _areaNameController = TextEditingController();
  final TextEditingController _tableNameController = TextEditingController();
  final TextEditingController _seatingCapacityController = TextEditingController();

  // List of area names created in this widget instance.
  List<String> _createdAreaNames = [];

  // Currently selected area name.
  String? _currentAreaName;

  // Flags invalid seating capacity input.
  bool _isSeatingCapacityInvalid = false;

  // Error message for seating capacity input.
  String _seatingCapacityErrorMessage = '';

  // Maps area names to lists of tables created under each area.
  Map<String, List<Map<String, dynamic>>> _areaTables = {};

  // Local list of used table names within this widget instance to check duplicates.
  List<String> _usedTableNames = [];

  // Flags duplicate table name error state.
  bool _isDuplicateTableName = false;

  // Error message for table name input.
  String _tableErrorMessage = '';

  /// Checks if the given table name already exists either globally or locally.
  bool _isTableNameDuplicate(String name) {
    return widget.usedTableNames.contains(name.trim().toLowerCase()) ||
        _usedTableNames.contains(name.trim().toLowerCase());
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  void _loadAreasFromDatabase() async {
    final areas = await _dbHelper.getAreasByPin(widget.pin);
    setState(() {
      _createdAreaNames = areas;
      if (_createdAreaNames.isNotEmpty && _currentAreaName == null) {
        _currentAreaName = _createdAreaNames.first;
        widget.onAreaSelected(_currentAreaName!);
      }
    });
  }

  /// Toggles the area creation popup visibility.
  void _togglePopup() {
    setState(() {
      _isPopupVisible = !_isPopupVisible;
      if (!_isPopupVisible) {
        // Clear area name input and error states when popup closes.
        _areaNameController.clear();
        _isDuplicateName = false;
        _errorMessage = '';
      }
    });
  }

  void _showAreaOptions(String name) {
    setState(() {
      _selectedAreaForOptions = name;
      _showOptionsPopup = true;
    });
  }

  final TextEditingController _editController = TextEditingController();

  void _showEditArea(String name) {
    setState(() {
      _selectedAreaForEdit = name;
      _editController.text = name;
      _showEditPopup = true;
    });
  }


  @override
  void initState() {
    super.initState();

    _loadAreasFromDatabase();
    // Listen to changes in table name input to check duplicates in real-time.
    _tableNameController.addListener(() {
      final name = _tableNameController.text.trim().toLowerCase();
      final isDuplicate = widget.usedTableNames.contains(name);
      setState(() {
        _isDuplicateTableName = isDuplicate;
        _tableErrorMessage =
        isDuplicate ? 'This table name already exists.' : '';
      });
    });

    // Listen to seating capacity input changes to validate numeric input.
    _seatingCapacityController.addListener(() {
      final seating = _seatingCapacityController.text.trim();

      if (seating.isEmpty || RegExp(r'^\d+$').hasMatch(seating)) {
        setState(() {
          _isSeatingCapacityInvalid = false;
          _seatingCapacityErrorMessage = '';
        });
      } else {
        setState(() {
          _isSeatingCapacityInvalid = true;
          _seatingCapacityErrorMessage = 'Please enter a valid number';
        });
      }
    });

    // Clear area name error states on input change.
    _areaNameController.addListener(() {
      setState(() {
        _isDuplicateName = false;
        _errorMessage = '';
      });
    });
  }

  /// Deletes the currently selected area.
  void _deleteArea() {
    if (_currentAreaName == null) return;

    final areaName = _currentAreaName!;
    setState(() {
      _createdAreaNames.remove(areaName);
      _areaTables.remove(areaName);

      if (_createdAreaNames.isNotEmpty) {
        _currentAreaName = _createdAreaNames.first;
        widget.onAreaSelected(_currentAreaName!);
      } else {
        _currentAreaName = null;
      }
      _isDeleteConfirmationVisible = false;
    });

    widget.onAreaDeleted(areaName);

    _dbHelper.deleteArea(areaName);
  }


  /// Validates the table input fields before enabling table creation.
  bool _isInputValid() {
    final name = _tableNameController.text.trim();

    if (name.isEmpty || _isTableNameDuplicate(name)) {
      setState(() {
        _isDuplicateTableName = _isTableNameDuplicate(name);
        _tableErrorMessage =
        _isDuplicateTableName ? 'This table name already exists.' : '';
      });
      return false;
    }
    if (_isSeatingCapacityInvalid ||
        _seatingCapacityController.text
            .trim()
            .isEmpty) {
      return false;
    }

    return true;
  }
  void _handleUpdateAreaName(String oldAreaName, String newAreaName) async {
    final zoneRepository = ZoneRepository();

    bool isUpdated = await zoneRepository.updateZoneName(
      token: widget.token,
      pin: widget.pin,
      oldAreaName: oldAreaName,
      newAreaName: newAreaName,
    );

    if (isUpdated) {
      // Call your UI update function
      widget.onAreaNameUpdated(oldAreaName, newAreaName);

      setState(() {
        int index = _createdAreaNames.indexOf(oldAreaName);
        if (index != -1) {
          _createdAreaNames[index] = newAreaName;
        }

        if (_currentAreaName == oldAreaName) {
          _currentAreaName = newAreaName;
        }

        if (_areaTables.containsKey(oldAreaName)) {
          _areaTables[newAreaName] = _areaTables[oldAreaName]!;
          _areaTables.remove(oldAreaName);
        }
      });
    } else {
      // You can show an error message here
      print('❌ Failed to update area name.');
    }
  }



  @override
  Widget build(BuildContext context) {
    // Seating capacity as int or zero if invalid.
    final int seatingCapacity =
        int.tryParse(_seatingCapacityController.text.trim()) ?? 0;

    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                /// Header widget for managing area and overall controls.
                TableSetupHeader(
                  areaNameController: _areaNameController,
                  tableNameController: _tableNameController,
                  seatingCapacityController: _seatingCapacityController,
                  createdAreaNames: _createdAreaNames,
                  currentAreaName: _currentAreaName,
                  onClose: widget.onClose,
                  onAreaSelected: (area) {
                    setState(() {
                      _currentAreaName = area;
                    });
                    widget.onAreaSelected(area);
                  },
                  togglePopup: _togglePopup,
                  isDeleteConfirmationVisible: _isDeleteConfirmationVisible,
                  onDeleteAreaConfirmed: () {
                    setState(() {
                      _isDeleteConfirmationVisible = true;
                    });
                  },
                  onResetData: (cb) {
                    // Reset all local states and inputs.
                    setState(() {
                      _areaNameController.clear();
                      _tableNameController.clear();
                      _seatingCapacityController.clear();
                      _areaTables.clear();
                      _usedTableNames.clear();
                      _currentAreaName = null;
                      _isDuplicateTableName = false;
                      _tableErrorMessage = '';
                      _isSeatingCapacityInvalid = false;
                      _seatingCapacityErrorMessage = '';
                      _isDuplicateName = false;
                      _errorMessage = '';
                      _isDeleteConfirmationVisible = false;
                      _isPopupVisible = false;
                    });
                  },
                  onUpdateAreaName: _handleUpdateAreaName,
                  onShowAreaOptions: _showAreaOptions,
                  onShowEditPopup: _showEditArea,
                ),

                // Show placeholder if no area is selected/created.
                _currentAreaName == null
                    ? const EmptyAreaPlaceholder()
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title for creating table section.
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Create a Table",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 8),

                    // Table name input with validation error display.
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Table name/ No.",
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4C5F7D),
                            ),
                          ),
                          SizedBox(height: 8),

                          SizedBox(
                            width: 450,
                            height: 38,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x19000000),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _tableNameController,
                                decoration: InputDecoration(
                                  hintText:
                                  'Type here name or number or combinations',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFAFACAC),
                                    fontSize: 10,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.fromLTRB(
                                    16,
                                    -5,
                                    16,
                                    8,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Display error if duplicate table name.
                          if (_isDuplicateTableName)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4.0,
                                top: 6,
                              ),
                              child: Text(
                                _tableErrorMessage,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFDA4A38),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10),

                    // Seating capacity input with validation error display.
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Seating capacity",
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4C5F7D),
                            ),
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: 450,
                            height: 38,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x19000000),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _seatingCapacityController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter the number',
                                  hintStyle: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFAFACAC),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.fromLTRB(
                                    16,
                                    -5,
                                    16,
                                    8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_isSeatingCapacityInvalid)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                                left: 4,
                              ),
                              child: Text(
                                _seatingCapacityErrorMessage,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFDA4A38),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Table Model selection section.
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Table Model",
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4C5F7D),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    // Dotted border container displaying draggable table models.
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AbsorbPointer(
                        absorbing: !_isInputValid(),
                        child: Opacity(
                          opacity: _isInputValid() ? 1.0 : 0.4,
                          child: DottedBorder(
                            dashPattern: [8, 4],
                            strokeWidth: 1,
                            color: _isInputValid()
                                ? Color(0xFF2874F0)
                                : Colors.black45,
                            borderType: BorderType.RRect,
                            radius: Radius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(20),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 40,
                                runSpacing: 20,

                                // Map shapes to draggable table widgets.
                                children: ["square", "circle", "rectangle"]
                                    .map(
                                      (shape) {
                                    bool isEnabled = _isInputValid();

                                    // Enable or disable shapes based on seating capacity rules.
                                    if (shape == "square") {
                                      isEnabled = isEnabled &&
                                          ((seatingCapacity >= 1 &&
                                              seatingCapacity <= 4) ||
                                              seatingCapacity % 4 == 0);
                                    } else if (shape == "rectangle") {
                                      isEnabled = isEnabled &&
                                          ((seatingCapacity >= 1 &&
                                              seatingCapacity <= 4) ||
                                              seatingCapacity % 2 == 0);
                                    }

                                    return DraggableTable(
                                      capacity: seatingCapacity,
                                      shape: shape,
                                      isEnabled: isEnabled,
                                      tableName:
                                      _tableNameController.text
                                          .trim(),
                                      areaName: _currentAreaName ?? '',
                                      onDragCompleted: () {
                                        // Clear inputs after drag completes.
                                        _tableNameController.clear();
                                        _seatingCapacityController.clear();
                                      },
                                      onDoubleTap: (data) =>
                                          widget.getTableData(data),
                                    );
                                  },
                                )
                                    .toList(),
                              ),
                            ),
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

        // Show area creation popup when visible.
        if (_isPopupVisible)
          BlocConsumer<ZoneBloc, ZoneState>(
            listener: (context, state) {
              if (state is ZoneSuccess) {
                setState(() {
                  _createdAreaNames.add(state.areaName);
                  _areaTables[state.areaName] = [];
                  _currentAreaName = state.areaName;

                  widget.onAreaSelected(state.areaName);

                  _areaNameController.clear();
                  _tableNameController.clear();
                  _seatingCapacityController.clear();
                  _isDeleteConfirmationVisible = false;
                  _isDuplicateName = false;
                  _errorMessage = '';

                  _togglePopup();
                });

                print('✅ Zone successfully created: ${state.areaName}');
              } else if (state is ZoneFailure) {
                setState(() {
                  _isDuplicateName = true;
                  _errorMessage = state.message;
                });
              }
            },
            builder: (context, state) {
              return AreaPopup(
                areaNameController: _areaNameController,
                isDuplicateName: _isDuplicateName,
                errorMessage: _errorMessage,
                togglePopup: _togglePopup,
                createArea: () {
                  BlocProvider.of<ZoneBloc>(context).add(
                    CreateZoneEvent(
                      token: widget.token,
                      pin: widget.pin,
                      areaName: _areaNameController.text.trim(),
                      usedAreaNames: widget.usedAreaNames.union(
                          _createdAreaNames.toSet()),
                    ),
                  );
                },
                isLoading: state is ZoneLoading, // Pass loading state
              );
            },
          ),


        // Show delete confirmation popup when visible.
        DeleteConfirmationPopup(
          isVisible: _isDeleteConfirmationVisible,
          currentAreaName: _currentAreaName,
          onCancel: () {
            setState(() {
              _isDeleteConfirmationVisible = false;
              _areaNameController.clear();
              _isDuplicateName = false;
              _errorMessage = '';
            });
          },
          onDelete: _deleteArea,
        ),
        if (_showOptionsPopup && _selectedAreaForOptions != null)
          Center(
            child: Material(
              color: Colors.transparent,
              child: _buildAreaOptionsPopup(_selectedAreaForOptions!),
            ),
          ),

        if (_showEditPopup && _selectedAreaForEdit != null)
          Center(
            child: Material(
              color: Colors.transparent,
              child: _buildEditAreaPopup(_selectedAreaForEdit!),
            ),
          ),
      ],
    );
  }

  Widget _buildAreaOptionsPopup(String areaName) {
    return GestureDetector(
      onTap: () => setState(() => _showOptionsPopup = false),
      child: Container(
        color: Colors.black.withAlpha(80),
        child: Center(
          child: Container(
            width: 300,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Action',
                      style: TextStyle(
                        color: Color(0xFF373535),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showOptionsPopup = false),
                      child: Container(
                        margin: EdgeInsets.only(top: 4, right: 4),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(0xFFF86157),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 11,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showOptionsPopup = false;
                      _showEditPopup = true;
                      _selectedAreaForEdit = areaName;
                      _editController.text = areaName;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: Color(0xFF4C5F7D),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showOptionsPopup = false;
                      _isDeleteConfirmationVisible = true;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Color(0xFFFD6464),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildEditAreaPopup(String oldName) {
    return GestureDetector(
      onTap: () => setState(() => _showEditPopup = false),
      child: Container(
        color: Colors.black.withAlpha(80),
        child: Center(
          child: Container(
            width: 300,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Area Name',
                  style: TextStyle(
                    color: Color(0xFF373535),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _editController,
                  decoration: InputDecoration(
                    labelText: 'Area Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showEditPopup = false),
                      child: Container(
                        width: 80,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x19000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF4C5F7D),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 25),
                    GestureDetector(
                      onTap: () {
                        final newName = _editController.text.trim();
                        if (newName.isNotEmpty && newName != oldName) {
                          _handleUpdateAreaName(oldName, newName);
                          widget.onAreaSelected(newName);
                        }
                        setState(() => _showEditPopup = false);
                      },
                      child: Container(
                        width: 80,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(0xFFFD6464),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x19000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Update',
                          style: TextStyle(
                            color: Color(0xFFF9F6F6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}