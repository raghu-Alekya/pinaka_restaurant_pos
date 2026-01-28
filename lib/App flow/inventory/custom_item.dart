import 'package:flutter/material.dart';
import '../../models/inventory/category_sublist_model.dart';
import '../../models/inventory/bev_model.dart';
import '../../models/inventory/tax_inventory_model.dart';
import '../../repositories/inventory_repository/Category_Sublist_Repository.dart';
import '../../repositories/inventory_repository/add_item_repository.dart';
import '../../repositories/inventory_repository/beverage_iventory_repository.dart';

import '../../repositories/inventory_repository/tax_inventory_repository.dart';
import 'dashboard.dart';

class AddItemDialog extends StatefulWidget {

  final Function(Products product) onItemAdded;

  const AddItemDialog({super.key, required this.onItemAdded});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _miniCategoryController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();

  final AddUpdateItemRepository _repository = AddUpdateItemRepository();
  List<TaxInventoryModel> taxes = [];
  TaxInventoryModel? selectedTax;
  bool showTaxList = false;

  // Categories
  CategorySublistResponse? categoryResponse;
  CategoryItem? selectedCategory;
  CategoryItem? selectedSubCategory;
  MiniCategory? selectedMiniCategory;
  bool showCategoryList = false;
  bool showSubCategoryList = false;
  bool showParentCategoryList = false;
  bool showMiniCategoryList = false;

  CategoryItem? expandedSubCategory;
  List<CategorySublistResponse> parentCategories = [];
  CategorySublistResponse? selectedParentCategory;
  bool isSubmitting = false;

  bool isLoading = false;
  String? error;


  final String token =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NjgyMDMwNjQsIm5iZiI6MTc2ODIwMzA2NCwiZXhwIjoxNzcwNzk1MDY0LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.vBVcnan6C9hN-ZDGN1vgpN_MkuT4twI-_WqXGOTgAio';

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchTaxes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _unitsController.dispose();
    _thresholdController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _imageUrlController.dispose();
    _miniCategoryController.dispose();
    _taxController.dispose();
    super.dispose();
  }


  Future<void> fetchTaxes() async {
    try {
      final repo =TaxinventoryRepository(token);
      final data = await repo.fetchTaxes();
      setState(() => taxes = data);
    } catch (e) {
      debugPrint("❌ Tax error: $e");
    }
  }
  Future<void> fetchCategories() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final repo = CategorySublistRepository(
        baseUrl: 'https://merchantrestaurant.alektasolutions.com',
      );

      final alcohol = await repo.fetchCategorySublist(
        categoryId: 131,
        token: token,
      );
      final beverages = await repo.fetchCategorySublist(
        categoryId: 228,
        token: token,
      );

      setState(() {
        parentCategories = [alcohol, beverages];
      });

      print("📦 Parent categories fetched:");
      for (var p in parentCategories) {
        print(
          "Parent: ${p.parentName}, Categories count: ${p.categories.length}",
        );
        for (var c in p.categories) {
          print(
            "  → SubCategory: ${c.name}, Children count: ${c.children.length}",
          );
          for (var m in c.children) {
            print("      → MiniCategory: ${m.name}");
          }
        }
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Show category picker
  Future<void> _showCategoryPicker(BuildContext context) async {
    if (categoryResponse == null) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);

    final CategoryItem? selected = await showMenu<CategoryItem>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 2,
        offset.dx + box.size.width,
        0,
      ),
      items:
      categoryResponse!.categories
          .map<PopupMenuEntry<CategoryItem>>(
            (cat) => PopupMenuItem(value: cat, child: Text(cat.name)),
      )
          .toList(),
    );

    if (selected != null) {
      setState(() {
        selectedCategory = selected;
        selectedSubCategory = null;
        selectedMiniCategory = null;
        _categoryController.text = selected.name;
        _subCategoryController.text = '';
      });
    }
  }

  // Show subcategory picker
  Future<void> _showSubCategoryPicker(BuildContext context) async {
    if (selectedCategory == null || selectedCategory!.children.isEmpty) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);

    // Change type to MiniCategory
    final MiniCategory? selected = await showMenu<MiniCategory>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 2,
        offset.dx + box.size.width,
        0,
      ),
      items:
      selectedCategory!.children
          .map<PopupMenuEntry<MiniCategory>>(
            (mini) => PopupMenuItem(value: mini, child: Text(mini.name)),
      )
          .toList(),
    );

    if (selected != null) {
      setState(() {
        selectedMiniCategory = selected;
        _subCategoryController.text = selected.name;
      });
    }
  }

  // Product fetch
  Future<void> fetchProducts({required int categoryId}) async {
    try {
      setState(() => isLoading = true);
      final repo = ProductRepository();
      final model = await repo.getProducts(categoryId: categoryId);
      if (model.products.isNotEmpty) widget.onItemAdded(model.products.first);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Center(
        child: Text("Add Stock", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      content: SizedBox(
        width: 500,
        child:
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: Text(error!))
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              // ===== FIRST ROW: Product Name + SKU =====
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
                    child: _buildLabeledField(
                      label: "SKU Code",
                      controller: _skuController,
                      hint: "Enter SKU code",
                      suffix: GestureDetector(
                        onTap: () {
                          _skuController.text =
                          "SKU-${DateTime.now().millisecondsSinceEpoch}";
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFE6464),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Generate",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ===== SECOND ROW: Category + SubCategory =====
              Row(
                children: [
                  // ===== CATEGORY PICKER =====
                  // ===== CATEGORY DROPDOWN =====
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<CategorySublistResponse>(
                          isExpanded: true,
                          value: selectedParentCategory,
                          hint: const Text("Select Category"),
                          items: parentCategories.map((parent) {
                            return DropdownMenuItem(
                              value: parent,
                              child: Text(parent.parentName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedParentCategory = value;
                              _categoryController.text = value?.parentName ?? '';

                              // Reset sub & mini
                              selectedCategory = null;
                              selectedMiniCategory = null;
                              _subCategoryController.clear();
                              _miniCategoryController.clear();
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

// ===== SUBCATEGORY DROPDOWN WITH INLINE MINI CATEGORIES =====
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Sub Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<CategoryItem>(
                          isExpanded: true,
                          value: selectedCategory,
                          hint: const Text("Select Sub Category"),
                          items: selectedParentCategory?.categories.map((sub) {
                            return DropdownMenuItem(
                              value: sub,
                              child: Text(sub.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                              _subCategoryController.text = value?.name ?? '';

                              // Reset mini
                              selectedMiniCategory = null;
                              _miniCategoryController.clear();
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),

                        // ===== INLINE MINI CATEGORY BUTTONS (show only if sub category selected) =====
                        if (selectedCategory != null && selectedCategory!.children.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: selectedCategory!.children.map((mini) {
                                final isSelected = selectedMiniCategory == mini;
                                return ChoiceChip(
                                  label: Text(mini.name),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      selectedMiniCategory = mini;
                                      _miniCategoryController.text = mini.name;
                                    });
                                  },
                                  selectedColor: Colors.blueAccent,
                                  backgroundColor: Colors.grey[200],
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),


                ],
              ),

              const SizedBox(height: 10),
              // ===== THIRD ROW: Stock + Price + Notes =====
              Row(
                children: [
                  Expanded(
                    child: _buildLabeledField(
                      label: "Stock Quantity",
                      controller: _unitsController,
                      hint: "Enter quantity",
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLabeledField(
                      label: "Unit Price",
                      controller: _thresholdController,
                      hint: "Enter price",
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Tax dropdown
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPickerField(
                          label: "Tax",
                          controller: _taxController,
                          onTap: () {
                            setState(() => showTaxList = !showTaxList);
                          },
                        ),
                        if (showTaxList)
                          Container(
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            constraints: const BoxConstraints(maxHeight: 150),
                            child: ListView(
                              shrinkWrap: true,
                              children: taxes.map((tax) {
                                return ListTile(
                                  title: Text(tax.name),
                                  onTap: () {
                                    setState(() {
                                      selectedTax = tax;
                                      _taxController.text = tax.name;

                                      showTaxList = false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ===== NOTES =====
                  // Expanded(
                  //   flex: 2,
                  //   child: _buildLabeledField(
                  //     label: "Notes",
                  //     controller: _notesController,
                  //     hint: "Add notes (optional)",
                  //     maxLines: 1,
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [_buildCancelButton(context), _buildAddButton(context)],
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    int maxLines = 1,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 38.0 * (maxLines > 1 ? maxLines : 1),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
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
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: controller,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: "Select $label",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
        onPressed:
        isSubmitting
            ? null
            : () async {
          print("🟢 ADD BUTTON PRESSED");
          setState(() => isSubmitting = true);

          // Validation
          if (_nameController.text.isEmpty ||
              _skuController.text.isEmpty ||
              _unitsController.text.isEmpty ||
              _thresholdController.text.isEmpty||
              selectedTax == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("All required fields must be filled"),
              ),
            );
            setState(() => isSubmitting = false);
            return;
          }
          print(
            "🧪 Mini Category ID being sent: ${selectedMiniCategory?.id}",
          );
          print(
            "⏳ Sending item to backend: ${_nameController.text.trim()}",
          );
          print("📤 taxClass: '${selectedTax?.taxClass}'");


          print(" Name: ${_nameController.text.trim()}");
          print(" SKU: ${_skuController.text.trim()}");
          print(" Stock: ${_unitsController.text.trim()}");
          print(" Price: ${_thresholdController.text.trim()}");
          print(
            " Parent Category: ${selectedParentCategory?.parentName}",
          );
          print(" Sub Category: ${selectedCategory?.name}");
          print(" Mini Category: ${selectedMiniCategory?.name}");
          print(" Notes: ${_notesController.text.trim()}");
          print("📤 category_id (sub): ${selectedCategory?.id}");
          print("📤 mini_category_id: ${selectedMiniCategory?.id}");

          try {
            final response = await _repository.addOrUpdateItem(
              itemName: _nameController.text.trim(),
              categoryId: selectedCategory?.id ?? 0,
              miniCategoryId: selectedMiniCategory?.id,
              taxClass: selectedTax?.taxClass,
              itemQty: int.tryParse(_unitsController.text.trim()) ?? 0,
              itemPrice:
              int.tryParse(_thresholdController.text.trim()) ?? 0,
              itemNote: _notesController.text.trim(),
              itemSku: _skuController.text.trim(),
            );

            if (!mounted) return;

            if (response.isCreated) {
              // Create product object
              final product = Products(
                id: response.itemId,
                itemName: _nameController.text.trim(),
                threshold: response.itemPrice,
                remaining: _unitsController.text.trim(),
                soldTotal: 0,
                statusLabel: "Normal",
                statusColor: "#4CAF50",
                image: _imageUrlController.text.trim(),
                sku: '',
              );

              // Call parent callback
              widget.onItemAdded(product);

              // ✅ Pop dialog
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Dashboard(token: '', pin: '', restaurantId: '', restaurantName: '',)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed: ${response.message}")),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Error: $e")));
            }
          } finally {
            if (mounted) setState(() => isSubmitting = false);
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
}