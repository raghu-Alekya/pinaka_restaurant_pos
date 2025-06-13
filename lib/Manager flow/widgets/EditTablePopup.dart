import 'package:flutter/material.dart';

/// A popup widget that allows editing details of a table such as
/// name, seating capacity, shape, and area.
///
/// It validates for duplicate table names and ensures the shape
/// matches the seating capacity constraints.
///
/// On successful update, it triggers [onUpdate] callback with updated table data.
/// The popup can be closed by calling the [onClose] callback.
class EditTablePopup extends StatefulWidget {
  /// Initial data of the table to edit.
  final Map<String, dynamic> tableData;

  /// Set of all used table names to validate duplicates.
  final Set<String> usedTableNames;

  /// Set of all area names available for selection.
  final Set<String> usedAreaNames;

  /// Callback to call when the table is updated with new data.
  final Function(Map<String, dynamic>) onUpdate;

  /// Callback to call when the popup should be closed.
  final VoidCallback onClose;

  const EditTablePopup({
    Key? key,
    required this.tableData,
    required this.usedTableNames,
    required this.usedAreaNames,
    required this.onUpdate,
    required this.onClose,
  }) : super(key: key);

  @override
  _EditTablePopupState createState() => _EditTablePopupState();
}

class _EditTablePopupState extends State<EditTablePopup> {
  late TextEditingController _nameController;
  late int _capacity;
  late String _selectedArea;
  late String _selectedShape;
  bool _isDuplicateName = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and variables with current table data
    _nameController = TextEditingController(text: widget.tableData['tableName']);
    _capacity = widget.tableData['capacity'];
    _selectedArea = widget.tableData['areaName'];
    _selectedShape = widget.tableData['shape'];

    // Validate if the shape is valid for the given capacity, else fallback
    if (!_isShapeValidForCapacity(_selectedShape, _capacity)) {
      _selectedShape = 'circle'; // default fallback shape
    }
  }

  /// Checks if a given shape is valid for the seating capacity.
  ///
  /// - 'square': capacity must be between 1-4 or a multiple of 4.
  /// - 'rectangle': capacity must be between 1-4 or even.
  /// - 'circle': always valid.
  bool _isShapeValidForCapacity(String shape, int capacity) {
    if (shape == 'square') {
      return (capacity >= 1 && capacity <= 4) || capacity % 4 == 0;
    } else if (shape == 'rectangle') {
      return (capacity >= 1 && capacity <= 4) || capacity % 2 == 0;
    }
    return true; // circle always valid
  }

  /// Validates the input fields:
  /// - Table name should not be empty.
  /// - Capacity should be positive.
  /// - Table name should not be duplicate (except if same as current).
  bool _validate() {
    final name = _nameController.text.trim();
    bool duplicate = widget.usedTableNames.contains(name.toLowerCase()) &&
        name.toLowerCase() != widget.tableData['tableName'].toString().toLowerCase();

    setState(() {
      _isDuplicateName = duplicate;
    });

    return name.isNotEmpty && _capacity > 0 && !duplicate;
  }

  /// Handles the update button press.
  /// Validates input and triggers the [onUpdate] callback with updated data.
  void _onUpdatePressed() {
    if (_validate()) {
      final updatedData = Map<String, dynamic>.from(widget.tableData);
      updatedData['tableName'] = _nameController.text.trim();
      updatedData['capacity'] = _capacity;
      updatedData['areaName'] = _selectedArea;
      updatedData['shape'] = _selectedShape;
      widget.onUpdate(updatedData);
    }
  }

  /// Adjusts the selected shape if it becomes invalid due to capacity change.
  void _adjustShapeIfNeeded() {
    if (!_isShapeValidForCapacity(_selectedShape, _capacity)) {
      setState(() {
        _selectedShape = 'circle';
      });
    }
  }

  /// Increments seating capacity and adjusts shape if needed.
  void _incrementCapacity() {
    setState(() {
      _capacity++;
      _adjustShapeIfNeeded();
    });
  }

  /// Decrements seating capacity and adjusts shape if needed.
  /// Minimum capacity is 1.
  void _decrementCapacity() {
    if (_capacity > 1) {
      setState(() {
        _capacity--;
        _adjustShapeIfNeeded();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter shape options based on current capacity and validity
    final shapeOptions = ['rectangle', 'circle', 'square'].where((shape) {
      if (shape == _selectedShape) return true;
      if (shape == 'square') {
        return (_capacity >= 1 && _capacity <= 4) || _capacity % 4 == 0;
      } else if (shape == 'rectangle') {
        return (_capacity >= 1 && _capacity <= 4) || _capacity % 2 == 0;
      }
      return true;
    }).map((shape) => DropdownMenuItem(
      value: shape,
      child: Row(
        children: [
          CustomPaint(
            size: const Size(24, 24),
            painter: ShapePainter(shape),
          ),
          const SizedBox(width: 8),
          Text(
            shape[0].toUpperCase() + shape.substring(1),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    )).toList();

    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 10,
        color: Colors.white,
        child: Container(
          width: 400,
          height: 520,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Title and Close button
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Table',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Display current table name
              Text(widget.tableData['tableName'],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
              const SizedBox(height: 16),

              // Table Name Input
              const Text('Table name/ No.', style: TextStyle(color: Color(0xFF4C5F7D), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  errorText: _isDuplicateName ? 'Duplicate table name' : null,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => _validate(),
              ),
              const SizedBox(height: 13),

              // Seating Capacity Input with increment/decrement buttons
              const Text('Seating capacity', style: TextStyle(color: Color(0xFF4C5F7D), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text('$_capacity', style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                    Container(
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.grey)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.deepOrange, size: 20),
                            onPressed: _decrementCapacity,
                            padding: EdgeInsets.zero,
                          ),
                          const VerticalDivider(width: 1),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.deepOrange, size: 20),
                            onPressed: _incrementCapacity,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // Shape selection dropdown
              Row(
                children: const [
                  Text('Shape', style: TextStyle(color: Color(0xFF4C5F7D), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 6),
              Theme(
                data: Theme.of(context).copyWith(canvasColor: Colors.white),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedShape,
                  items: shapeOptions,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedShape = val);
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 13),

              // Area selection dropdown
              const Text('Area', style: TextStyle(color: Color(0xFF4C5F7D), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedArea,
                  items: widget.usedAreaNames.map((area) {
                    return DropdownMenuItem(
                      value: area,
                      child: Text(area, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedArea = val);
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 13),

              // Update button aligned to the right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade900,
                      foregroundColor: Colors.white,
                      fixedSize: const Size(140, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _validate() ? _onUpdatePressed : null,
                    child: const Text('Update Table'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter to draw table shape preview icons in the dropdown.
class ShapePainter extends CustomPainter {
  final String shape;
  ShapePainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (shape == 'circle') {
      double radius = size.shortestSide * 0.3;
      final center = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(center, radius, border);
    } else if (shape == 'rectangle') {
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.8,
        height: size.height * 0.5,
      );
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, border);
    } else if (shape == 'square') {
      final side = size.shortestSide * 0.5;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: side,
        height: side,
      );
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, border);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
