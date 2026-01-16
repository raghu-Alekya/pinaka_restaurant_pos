import 'package:flutter/material.dart';

import '../../models/inventory/bev_model.dart';
// import '../../models/inventory/bevmodel.dart';
// import '../../repositories/add_item_inventory.dart';
import '../../repositories/inventory_repository/add_item_repository.dart';



class AddItemDialog extends StatefulWidget {
  final Function(Products product) onItemAdded;

  const AddItemDialog({super.key, required this.onItemAdded});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Add the imageUrl controller here
  final TextEditingController _imageUrlController = TextEditingController();
  final AddUpdateItemRepository _repository = AddUpdateItemRepository();
  final List<String> _categories = [
    'Beer',
    'Brandy',
    'Cocktails',
    'Coffee & Tea',
    'Energy Drinks',
    'Juices',
    'Liquers & Bitters',
    'Mocktails',
    'Milkshakes / Smoothies',
    'Soft Drinks',
    'Spirits',
    'Water',
    'Wine',
    'Custom',
    'Uncategorized',
  ];

  void _showCategoryPicker(BuildContext context) async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);

    final selected = await showMenu<String>(
      context: context,
      color: Colors.white,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 2,
        offset.dx + box.size.width,
        0,
      ),
      constraints: const BoxConstraints(
        maxHeight: 220,
        minWidth: 250,
      ),
      items: _categories
          .map(
            (item) => PopupMenuItem<String>(
          value: item,
          height: 36,
          child: Text(
            item,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      )
          .toList(),
    );

    if (selected != null) {
      setState(() {
        _categoryController.text = selected;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      title: const Center(
        child: Text(
          "Add Stock",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildLabeledField(
                      label: "Product Name",
                      controller: _nameController,
                      hint: "Enter Product Name",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            "Category", style: TextStyle(fontWeight: FontWeight
                            .bold)),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 40,
                          child: Builder(
                            builder: (context) => GestureDetector(
                              onTap: () => _showCategoryPicker(context),
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _categoryController,
                                  readOnly: true,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: "Select category",
                                    contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.black),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    suffixIcon: const Icon(Icons.keyboard_arrow_down),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            "SKU Code", style: TextStyle(fontWeight: FontWeight
                            .bold)),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _skuController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Enter SKU code",
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.black),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffix: GestureDetector(
                                onTap: () {
                                  _skuController.text = "SKU-${DateTime
                                      .now()
                                      .millisecondsSinceEpoch}";
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 0),
                                  padding: const EdgeInsets.fromLTRB(
                                      10, 6, 16, 4),
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFFE6464),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text(
                                    "Generate",
                                    style: TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLabeledField(
                      label: "Stock Quantity",
                      controller: _unitsController,
                      hint: "Enter quantity",
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildLabeledField(
                      label: "Unit Price",
                      controller: _thresholdController,
                      hint: "Enter price",
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            "Notes", style: TextStyle(fontWeight: FontWeight
                            .bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            hintText: "Add notes (optional)",
                            hintStyle: TextStyle(
                                color: Color(0xFF949494), fontSize: 14),
                            border: UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      actions: [
        _buildCancelButton(context),
        _buildAddButton(context),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        height: 40,
        width: 160,
        padding: const EdgeInsets.all(8),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFE44F29)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Center(
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Color(0xFFE44F29),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4C81F1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          if (_nameController.text.isEmpty ||
              _skuController.text.isEmpty ||
              _unitsController.text.isEmpty ||
              _thresholdController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("All required fields must be filled")),
            );
            return;
          }
          print("⏳ Sending item to backend: ${_nameController.text.trim()}");
          // ✅ Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          try {
            // Call API
            final response = await _repository.addOrUpdateItem(
              itemName: _nameController.text.trim(),
              categoryId: 1, // Replace with your actual category ID mapping
              itemQty: int.tryParse(_unitsController.text.trim()) ?? 0,
              itemPrice: int.tryParse(_thresholdController.text.trim()) ?? 0,
              itemNote: _notesController.text.trim(),
              itemSku: _skuController.text.trim(),
            );

            Navigator.pop(context); // close loader
            print("📤 Backend response: status=${response.status}, message=${response.message}, id=${response.itemId}");


            if (response.isCreated) {
              // ✅ Create local Products object from API response
              final product = Products(
                id: response.itemId,
                itemName: _nameController.text.trim(),
                threshold: response.itemPrice,
                remaining: _unitsController.text.trim(),
                soldTotal: 0,
                statusLabel: "Normal",
                statusColor: "#4CAF50",
                image: _imageUrlController.text.trim(), sku: '',
              );
              print("✅ Item created on backend: ${product.itemName}, ID: ${product.id}");
              widget.onItemAdded(product);
              Navigator.pop(context); // close dialog
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed: ${response.message}")),
              );
            }
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e")),
            );
          }
        },
        child: const Text(
          "Add Item",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(fontSize: 14, color: Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF949494), fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}