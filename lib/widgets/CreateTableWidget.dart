import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'DraggableTable.dart';

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

    final isAlreadyUsed = widget.usedAreaNames
        .map((e) => e.toLowerCase())
        .contains(areaName.toLowerCase()) ||
        _createdAreaNames
            .map((e) => e.toLowerCase())
            .contains(areaName.toLowerCase());

    if (areaName.isNotEmpty && !isAlreadyUsed) {
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (context) => Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          backgroundColor: Colors.white,
                                          child: Container(
                                            width: 440,
                                            padding: EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Alert Icon
                                                Container(
                                                  child: Center(
                                                    child: Image.asset(
                                                      'assets/check-broken.png',
                                                      width: 80,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 18),
                                                Text(
                                                  'Finish Table Setup?',
                                                  style: TextStyle(
                                                    color: const Color(0xFF373535),
                                                    fontSize: 25,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w900,
                                                    height: 1.56,
                                                  ),
                                                ),
                                                SizedBox(height: 14),
                                                Text(
                                                  'Your table arrangement has been saved successfully. \nYou can revisit and edit it anytime from the table management section.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: const Color(0xFFA19999),
                                                    fontSize: 14,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.38,
                                                  ),
                                                ),
                                                // Buttons
                                                SizedBox(height: 18),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 100,
                                                      height: 40,
                                                      child: ElevatedButton(
                                                        onPressed:
                                                            () =>
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .grey
                                                                  .shade200,
                                                          foregroundColor:
                                                              Color(0xFF4C5F7D),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          padding:
                                                              EdgeInsets.zero,
                                                        ),
                                                        child: Text('Stay Here',style: TextStyle(fontSize: 15)),
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    // Yes Button
                                                    SizedBox(
                                                      width: 100,
                                                      height: 40,
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            _areaNameController
                                                                .clear();
                                                            _tableNameController
                                                                .clear();
                                                            _seatingCapacityController
                                                                .clear();
                                                            _areaTables.clear();
                                                            _usedTableNames
                                                                .clear();
                                                            _currentAreaName =
                                                                null;
                                                            _isDuplicateTableName =
                                                                false;
                                                            _tableErrorMessage =
                                                                '';
                                                            _isSeatingCapacityInvalid =
                                                                false;
                                                            _seatingCapacityErrorMessage =
                                                                '';
                                                            _isDuplicateName =
                                                                false;
                                                            _errorMessage = '';
                                                            _isDeleteConfirmationVisible =
                                                                false;
                                                            _isPopupVisible =
                                                                false;
                                                          });
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          widget.onClose();
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Color(0xFFD93535),
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          padding:
                                                              EdgeInsets.zero,
                                                        ),
                                                        child: Text('Yes, Exit',style: TextStyle(fontSize: 15)),
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
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Table Setup",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF15315E),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(left: 7.0),
                        child: Text(
                          "Area/Zone:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4C5F7D),
                          ),
                        ),
                      ),

                      SizedBox(height: 4),
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 9,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(
                                      _createdAreaNames.length,
                                      (i) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 10.0,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _currentAreaName =
                                                    _createdAreaNames[i];
                                                widget.onAreaSelected(
                                                  _currentAreaName!,
                                                ); // Notify parent
                                                _tableNameController.clear();
                                                _seatingCapacityController
                                                    .clear();
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    _createdAreaNames[i] ==
                                                            _currentAreaName
                                                        ? Color(0xFFFFE1E1)
                                                        : Color(0xFFF2F2F2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color:
                                                      _createdAreaNames[i] ==
                                                              _currentAreaName
                                                          ? Color(0xFFFF4D20)
                                                          : Color(0xFFAFACAC),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _createdAreaNames[i],
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  if (_createdAreaNames[i] ==
                                                      _currentAreaName)
                                                    GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _isDeleteConfirmationVisible =
                                                              true;
                                                        });
                                                      },
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                          2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Color(
                                                            0xFFEE796A,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                        ),
                                                        child: Icon(
                                                          Icons.close,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _togglePopup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xF2E76757),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "+ Add Area",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _currentAreaName == null
                    ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Text(
                            "Let’s Set the Table!",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 14),
                          Text(
                            "Start by creating your first table setup to manage your restaurant floor with ease. Customize table size, shape, and seating capacity based on your layout.",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF4C5F7D),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
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
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Table name/ No.",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4C5F7D),
                                ),
                              ),
                              SizedBox(height: 8),

                              // TextField Container
                              SizedBox(
                                width: 450,
                                height: 40,
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
                                        fontSize: 11,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.fromLTRB(
                                        16,
                                        -6,
                                        16,
                                        0,
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
                                    top: 8,
                                  ),
                                  child: Text(
                                    _tableErrorMessage,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFDA4A38),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Seating capacity",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4C5F7D),
                                ),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                width: 450,
                                height: 40,
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
                                        fontSize: 11,
                                        color: Color(0xFFAFACAC),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.fromLTRB(
                                        16,
                                        -6,
                                        16,
                                        0,
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
                                      fontSize: 11,
                                      color: Color(0xFFDA4A38),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Table Model",
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4C5F7D),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
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
                                    children: ["square", "circle", "rectangle"].map((shape) {
                                      bool isEnabled = _isInputValid();

                                      if (shape == "square") {
                                        isEnabled = isEnabled && ((seatingCapacity >= 1 && seatingCapacity <= 4) || seatingCapacity % 4 == 0);
                                      } else if (shape == "rectangle") {
                                        isEnabled = isEnabled && ((seatingCapacity >= 1 && seatingCapacity <= 4) || seatingCapacity % 2 == 0);
                                      }

                                      return DraggableTable(
                                        capacity: seatingCapacity,
                                        shape: shape,
                                        isEnabled: isEnabled,
                                        tableName: _tableNameController.text.trim(),
                                        areaName: _currentAreaName ?? '',
                                        onDragCompleted: () {
                                          _tableNameController.clear();
                                          _seatingCapacityController.clear();
                                        },
                                        onDoubleTap: (data) => widget.getTableData(data),
                                      );
                                    }).toList(),
                                  )

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

        // Area popup
        if (_isPopupVisible)
          GestureDetector(
            onTap: _togglePopup,
            child: Container(
              color: Colors.black.withAlpha(100),
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 25,
                                  right: 25,
                                  bottom: 20,
                                ),
                                child: Text(
                                  "Let’s Create an Area/Zone",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: _togglePopup,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF86157),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x3F000000),
                                        blurRadius: 11,
                                        offset: Offset(2, 2),
                                        spreadRadius: 0,
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
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Area/Zone",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 45,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Color(0xFFECEBEB)),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Color(0x19000000))],
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _areaNameController,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type an Area/Zone name',
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 5),
                        if (_isDuplicateName)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 4.0,
                              bottom: 6,
                            ),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFDA4A38),
                              ),
                            ),
                          ),
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _areaNameController.clear();
                                  _isDuplicateName = false;
                                  _errorMessage = '';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                foregroundColor: Color(0xFF4C5F7D),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 26,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text("Clear"),
                            ),
                            SizedBox(width: 15),
                            ElevatedButton(
                              onPressed: _createArea,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFDA4A38),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text("Create"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_isDeleteConfirmationVisible)
          GestureDetector(
            onTap: () {
              setState(() {
                _isDeleteConfirmationVisible = false;
              });
            },
            child: Container(
              color: Colors.black.withAlpha(80),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: MediaQuery.of(context).size.height * 0.35,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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

                        const SizedBox(height: 10),
                        const Text(
                          'Are you sure ?',
                          style: TextStyle(
                            color: Color(0xFF373535),
                            fontSize: 20,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            height: 1.57,
                          ),
                        ),
                        const SizedBox(height: 13),
                        SizedBox(
                          width: 383,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text:
                                      'Do you want to really delete the records? This will delete ',
                                  style: TextStyle(
                                    color: Color(0xFFA19999),
                                    fontSize: 15,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.38,
                                  ),
                                ),
                                TextSpan(
                                  text: _currentAreaName ?? 'this area.',
                                  style: const TextStyle(
                                    color: Color(0xFF656161),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    height: 1.38,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isDeleteConfirmationVisible = false;
                                  _areaNameController.clear();
                                  _isDuplicateName = false;
                                  _errorMessage = '';
                                });
                              },
                              child: Container(
                                width: 95,
                                height: 42,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF6F6F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  shadows: const [
                                    BoxShadow(
                                      color: Color(0x19000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'No, Keep It.',
                                  style: TextStyle(
                                    color: Color(0xFF4C5F7D),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 30),
                            GestureDetector(
                              onTap: _deleteArea,
                              child: Container(
                                width: 95,
                                height: 42,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFD6464),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  shadows: const [
                                    BoxShadow(
                                      color: Color(0x19000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Yes, Delete!',
                                  style: TextStyle(
                                    color: Color(0xFFF9F6F6),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.10,
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
            ),
          ),
      ],
    );
  }

  Widget _buildDraggableTable(int capacity, {required String shape}) {
    bool isEnabled = _isInputValid();
    if (shape == "square") {
      if (!((capacity >= 1 && capacity <= 4) || capacity % 4 == 0)) {
        isEnabled = false;
      }
    }

    if (shape == "rectangle") {
      if (!((capacity >= 1 && capacity <= 4) || capacity % 2 == 0)) {
        isEnabled = false;
      }
    }

    final data = {
      'capacity': capacity,
      'tableName': _tableNameController.text.trim(),
      'areaName': _currentAreaName ?? '',
      'shape': shape,
    };

    return AbsorbPointer(
      absorbing: !isEnabled,
      child: Draggable<Map<String, dynamic>>(
        data: data,
        feedback: Opacity(
          opacity: 0.7,
          child: _buildTableWidget(capacity, isEnabled, shape),
        ),
        onDragCompleted: () {
          final name = _tableNameController.text.trim();

          setState(() {
            if (name.isNotEmpty && !_isTableNameDuplicate(name)) {
              _usedTableNames.add(name.toLowerCase());
            }
            _tableNameController.clear();
            _seatingCapacityController.clear();
            _isDuplicateTableName = false;
            _tableErrorMessage = '';
          });
        },

        child: GestureDetector(
          onDoubleTap: () {
            if (isEnabled) {
              widget.getTableData(data);
            }
          },
          child: _buildTableWidget(capacity, isEnabled, shape),
        ),
      ),
    );
  }

  Widget _buildTableWidget(int capacity, bool isHighlighted, String shape) {
    final borderColor = isHighlighted ? Color(0xFF2874F0) : Colors.black45;
    final textColor = isHighlighted ? Color(0xFF2874F0) : Colors.black45;

    double width = 90;
    double height = 90;
    BorderType borderType = BorderType.RRect;
    Radius radius = Radius.circular(16);

    if (shape == "rectangle") {
      width = 150;
      height = 80;
    } else if (shape == "circle") {
      borderType = BorderType.Circle;
      radius = Radius.circular(0);
    }

    return DottedBorder(
      color: borderColor,
      strokeWidth: 1.5,
      dashPattern: [6, 3],
      borderType: borderType,
      radius: radius,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child:
            shape == "circle"
                ? ClipOval(
                  child: Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: _buildTableText(textColor),
                  ),
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: _buildTableText(textColor),
                  ),
                ),
      ),
    );
  }
  Widget _buildTableText(Color textColor) {
    return Text(
      "Drag to\nFloor",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
