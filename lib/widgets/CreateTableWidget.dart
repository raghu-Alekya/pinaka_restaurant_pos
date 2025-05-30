import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'AreaPopup.dart';
import 'DeleteConfirmationPopup.dart';
import 'DraggableTable.dart';
import 'EmptyAreaPlaceholder.dart';
import 'TableSetupHeader.dart';

class CreateTableWidget extends StatefulWidget {
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) getTableData;
  final Set<String> usedTableNames;
  final Set<String> usedAreaNames;
  final Function(String) onAreaSelected;
  final Function(String) onAreaDeleted;

  const CreateTableWidget({
    Key? key,
    required this.onClose,
    required this.getTableData,
    required this.usedTableNames,
    required this.usedAreaNames,
    required this.onAreaSelected,
    required this.onAreaDeleted,
  }) : super(key: key);

  @override
  _CreateTableWidgetState createState() => _CreateTableWidgetState();
}

class _CreateTableWidgetState extends State<CreateTableWidget> {
  bool _isPopupVisible = false;
  bool _isDeleteConfirmationVisible = false;
  bool _isDuplicateName = false;
  String _errorMessage = '';

  // Controllers
  final TextEditingController _areaNameController = TextEditingController();
  final TextEditingController _tableNameController = TextEditingController();
  final TextEditingController _seatingCapacityController =
  TextEditingController();

  List<String> _createdAreaNames = [];
  String? _currentAreaName;
  bool _isSeatingCapacityInvalid = false;
  String _seatingCapacityErrorMessage = '';

  // Map to store table data per area
  Map<String, List<Map<String, dynamic>>> _areaTables = {};
  List<String> _usedTableNames = [];

  bool _isTableNameDuplicate(String name) {
    return widget.usedTableNames.contains(name.trim().toLowerCase()) ||
        _usedTableNames.contains(name.trim().toLowerCase());
  }

  bool _isDuplicateTableName = false;
  String _tableErrorMessage = '';

  // Toggle popup
  void _togglePopup() {
    setState(() {
      _isPopupVisible = !_isPopupVisible;
      if (!_isPopupVisible) {
        _areaNameController.clear();
        _isDuplicateName = false;
        _errorMessage = '';
      }
    });
  }

  void _createArea() {
    final areaName = _areaNameController.text.trim();

    if (areaName.isEmpty) {
      setState(() {
        _isDuplicateName = true;
        _errorMessage = 'Area name cannot be empty';
      });
      return;
    }

    final isAlreadyUsed =
        widget.usedAreaNames
            .map((e) => e.toLowerCase())
            .contains(areaName.toLowerCase()) ||
            _createdAreaNames
                .map((e) => e.toLowerCase())
                .contains(areaName.toLowerCase());

    if (!isAlreadyUsed) {
      setState(() {
        _createdAreaNames.add(areaName);
        _areaTables[areaName] = [];
        _currentAreaName = areaName;

        widget.onAreaSelected(areaName);

        _areaNameController.clear();
        _tableNameController.clear();
        _seatingCapacityController.clear();
        _isDeleteConfirmationVisible = false;
        _isDuplicateName = false;
        _errorMessage = '';
        _togglePopup();
      });
    } else {
      setState(() {
        _isDuplicateName = true;
        _errorMessage = 'This Area/Zone name already exists';
      });
    }
  }


  @override
  void initState() {
    super.initState();

    _tableNameController.addListener(() {
      final name = _tableNameController.text.trim().toLowerCase();
      final isDuplicate = widget.usedTableNames.contains(name);
      setState(() {
        _isDuplicateTableName = isDuplicate;
        _tableErrorMessage =
        isDuplicate ? 'This table name already exists.' : '';
      });
    });

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

    _areaNameController.addListener(() {
      setState(() {
        _isDuplicateName = false;
        _errorMessage = '';
      });
    });
  }

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
  }

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
        _seatingCapacityController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
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
                  },
                  togglePopup: _togglePopup,
                  isDeleteConfirmationVisible: _isDeleteConfirmationVisible,
                  onDeleteAreaConfirmed: () {
                    setState(() {
                      _isDeleteConfirmationVisible = true;
                    });
                  },
                  onResetData: (cb) {
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
                ),
                _currentAreaName == null
                    ? const EmptyAreaPlaceholder()
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Create a Table",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Table name/ No.",
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4C5F7D),
                            ),
                          ),
                          SizedBox(height: 7),

                          // TextField Container
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

                          // Error Message
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
                    SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Seating capacity",
                            style: TextStyle(
                              fontSize: 10,
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
                                // Removed red border logic
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
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Table Model",
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4C5F7D),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AbsorbPointer(
                        absorbing: !_isInputValid(),
                        child: Opacity(
                          opacity: _isInputValid() ? 1.0 : 0.4,
                          child: DottedBorder(
                            dashPattern: [8, 4],
                            strokeWidth: 1,
                            color:
                            _isInputValid()
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
                                children:
                                ["square", "circle", "rectangle"].map((
                                    shape,
                                    ) {
                                  bool isEnabled = _isInputValid();

                                  if (shape == "square") {
                                    isEnabled =
                                        isEnabled &&
                                            ((seatingCapacity >= 1 &&
                                                seatingCapacity <= 4) ||
                                                seatingCapacity % 4 == 0);
                                  } else if (shape == "rectangle") {
                                    isEnabled =
                                        isEnabled &&
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
                                      _tableNameController.clear();
                                      _seatingCapacityController
                                          .clear();
                                    },
                                    onDoubleTap:
                                        (data) =>
                                        widget.getTableData(data),
                                  );
                                }).toList(),
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
        if (_isPopupVisible)
          AreaPopup(
            areaNameController: _areaNameController,
            isDuplicateName: _isDuplicateName,
            errorMessage: _errorMessage,
            togglePopup: _togglePopup,
            createArea: _createArea,
          ),
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

      ],
    );
  }
}