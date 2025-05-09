import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class CreateTableWidget extends StatefulWidget {
  final VoidCallback onClose;

  const CreateTableWidget({Key? key, required this.onClose}) : super(key: key);

  @override
  _CreateTableWidgetState createState() => _CreateTableWidgetState();
}

class _CreateTableWidgetState extends State<CreateTableWidget> {
  bool _isPopupVisible = false;
  bool _isDeleteConfirmationVisible = false;

  // Controllers
  final TextEditingController _areaNameController = TextEditingController();
  final TextEditingController _tableNameController = TextEditingController();
  final TextEditingController _seatingCapacityController = TextEditingController();

  List<String> _createdAreaNames = [];
  String? _currentAreaName;

  // Map to store table data per area
  Map<String, List<Map<String, dynamic>>> _areaTables = {};

  // Toggle popup
  void _togglePopup() {
    setState(() {
      _isPopupVisible = !_isPopupVisible;
    });
  }

  // Create new area
  void _createArea() {
    final areaName = _areaNameController.text.trim();
    if (areaName.isNotEmpty && !_createdAreaNames.contains(areaName)) {
      setState(() {
        _createdAreaNames.add(areaName);
        _areaTables[areaName] = [];
        _currentAreaName = areaName;
        _areaNameController.clear();
        _tableNameController.clear();
        _seatingCapacityController.clear();
        _isDeleteConfirmationVisible = false;
        _togglePopup();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tableNameController.addListener(() => setState(() {}));
    _seatingCapacityController.addListener(() => setState(() {}));
  }


  void _deleteArea() {
    if (_currentAreaName != null) {
      setState(() {
        _createdAreaNames.remove(_currentAreaName);
        _areaTables.remove(_currentAreaName);
        _currentAreaName = _createdAreaNames.isNotEmpty ? _createdAreaNames.last : null;
        _isDeleteConfirmationVisible = false;
      });
    }
  }

  bool _isInputValid() {
    return _tableNameController.text.trim().isNotEmpty &&
        _seatingCapacityController.text.trim().isNotEmpty;
  }



  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10),
                  child: Row(
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
                            icon: Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: widget.onClose,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: List.generate(_createdAreaNames.length, (i) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 10.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _currentAreaName = _createdAreaNames[i];
                                                _tableNameController.clear();
                                                _seatingCapacityController.clear();
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _createdAreaNames[i] == _currentAreaName
                                                    ? Color(0xFFFFE1E1)
                                                    : Color(0xFFF2F2F2),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: _createdAreaNames[i] == _currentAreaName
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
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  if (_createdAreaNames[i] == _currentAreaName)
                                                    GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _isDeleteConfirmationVisible = true;
                                                        });
                                                      },
                                                      child: Container(
                                                        padding: EdgeInsets.all(2),
                                                        decoration: BoxDecoration(
                                                          color: Color(0xFFEE796A),
                                                          borderRadius: BorderRadius.circular(15),
                                                        ),
                                                        child: Icon(Icons.close, size: 16, color: Colors.white),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _togglePopup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDA4A38),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                _currentAreaName == null
                    ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Hi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
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
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4C5F7D),
                            ),
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: 450,
                            height: 45,
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
                                  hintText: 'Type here name or number or combinations',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFAFACAC),
                                    fontSize: 12,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
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
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4C5F7D),
                            ),
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: 450,
                            height: 45,
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
                                    fontSize: 12,
                                    color: Color(0xFFAFACAC),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                            color: _isInputValid() ? Color(0xFF2874F0) : Colors
                                .black45,
                            borderType: BorderType.RRect,
                            radius: Radius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(20),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 40,
                                runSpacing: 20,
                                children: [
                                  _buildDraggableTable(2),
                                  _buildDraggableTable(4),
                                  SizedBox(width: double.infinity),
                                  _buildDraggableTable(6),
                                ],
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
                                padding: const EdgeInsets.only(top: 25, right: 25, bottom: 20),
                                child: Text(
                                  "Let’s Create an Area/Zone",
                                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 18),
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
                                      )
                                    ],
                                  ),
                                  child: Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text("Area/Zone",
                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 15)),
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
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => _areaNameController.clear(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                foregroundColor: Color(0xFF4C5F7D),
                                padding: EdgeInsets.symmetric(horizontal: 26, vertical: 14),
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
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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


  Widget _buildDraggableTable(int capacity) {
    bool isEnabled = _isInputValid();

    return Draggable<Map<String, dynamic>>(
      data: {'capacity': capacity, 'type': 'table'},
      feedback: Opacity(
        opacity: 0.7,
        child: _buildTableWidget(capacity, isEnabled),
      ),
      child: _buildTableWidget(capacity, isEnabled),
    );
  }

  Widget _buildTableWidget(int capacity, bool isHighlighted) {
    double width = capacity == 2 ? 90 : (capacity == 4 ? 90 : 150);
    double height = capacity == 4 ? 90 : 90;
    bool isCircle = capacity == 4;

    final borderColor = isHighlighted ? const Color(0xFF2874F0) : Colors.black45;
    final textColor = isHighlighted ? const Color(0xFF2874F0) : Colors.black45;

    return DottedBorder(
      color: borderColor,
      strokeWidth: 1.5,
      dashPattern: [6, 3],
      borderType: isCircle ? BorderType.Circle : BorderType.RRect,
      radius: isCircle ? Radius.circular(0) : Radius.circular(16),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: isCircle
            ? ClipOval(
          child: Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: Text(
              "Drag to\nFloor",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: Text(
              "Drag to\nFloor",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
