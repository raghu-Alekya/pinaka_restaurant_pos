import 'package\:flutter/material.dart';
class EditTablePopup extends StatefulWidget {
  final Map<String, dynamic> tableData;
  final Set<String> usedTableNames;
  final Set<String> usedAreaNames;
  final Function(Map<String, dynamic>) onUpdate;
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
    _nameController = TextEditingController(text: widget.tableData['tableName']);
    _capacity = widget.tableData['capacity'];
    _selectedArea = widget.tableData['areaName'];
    _selectedShape = widget.tableData['shape'];

    // Ensure _selectedShape is valid for initial _capacity
    if (!_isShapeValidForCapacity(_selectedShape, _capacity)) {
      _selectedShape = 'circle'; // fallback valid shape
    }
  }

  bool _isShapeValidForCapacity(String shape, int capacity) {
    if (shape == 'square') {
      return (capacity >= 1 && capacity <= 4) || capacity % 4 == 0;
    } else if (shape == 'rectangle') {
      return (capacity >= 1 && capacity <= 4) || capacity % 2 == 0;
    }
    // circle always valid
    return true;
  }

  bool _validate() {
    final name = _nameController.text.trim();
    bool duplicate = widget.usedTableNames.contains(name.toLowerCase()) &&
        name.toLowerCase() != widget.tableData['tableName'].toString().toLowerCase();

    setState(() {
      _isDuplicateName = duplicate;
    });

    return name.isNotEmpty && _capacity > 0 && !duplicate;
  }

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

  void _adjustShapeIfNeeded() {
    if (!_isShapeValidForCapacity(_selectedShape, _capacity)) {
      setState(() {
        _selectedShape = 'circle'; // fallback valid shape
      });
    }
  }

  void _incrementCapacity() {
    setState(() {
      _capacity++;
      _adjustShapeIfNeeded();
    });
  }

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
    final shapeOptions = ['rectangle', 'circle', 'square']
        .where((shape) {
      if (shape == _selectedShape) return true;
      if (shape == 'square') {
        return (_capacity >= 1 && _capacity <= 4) || _capacity % 4 == 0;
      } else if (shape == 'rectangle') {
        return (_capacity >= 1 && _capacity <= 4) || _capacity % 2 == 0;
      }
      return true;
    })
        .map((shape) => DropdownMenuItem(
      value: shape,
      child: Text(
        shape[0].toUpperCase() + shape.substring(1),
        style: const TextStyle(fontSize: 14),
      ),
    ))
        .toList();

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
              // Title Row
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
              Text(widget.tableData['tableName'],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
              const SizedBox(height: 16),

              // Table Name
              const Text('Table name/ No.', style: TextStyle(color: const Color(0xFF4C5F7D),fontSize: 13,fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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

              // Shape
              const Text('Shape', style: TextStyle(color: const Color(0xFF4C5F7D),fontSize: 13,fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                ),
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
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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

              // Seating Capacity
              const Text('Seating capacity', style: TextStyle(color: const Color(0xFF4C5F7D),fontSize: 13,fontWeight: FontWeight.w500)),
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
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            icon: const Icon(Icons.remove,
                                color: Colors.deepOrange, size: 20),
                            onPressed: _decrementCapacity,
                            padding: EdgeInsets.zero,
                          ),
                          const VerticalDivider(width: 1),
                          IconButton(
                            icon: const Icon(Icons.add,
                                color: Colors.deepOrange, size: 20),
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

              // Area Dropdown
              const Text('Area', style: TextStyle(color: const Color(0xFF4C5F7D),fontSize: 13,fontWeight: FontWeight.w500)),
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
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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

              // Update Button
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
