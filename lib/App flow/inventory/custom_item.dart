import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/inventory/category_sublist_model.dart';
import '../../models/inventory/bev_model.dart';
import '../../models/inventory/tax_inventory_model.dart';
import '../../repositories/inventory_repository/Category_Sublist_Repository.dart';
import '../../repositories/inventory_repository/add_item_repository.dart';
import '../../repositories/inventory_repository/beverage_iventory_repository.dart';

import '../../repositories/inventory_repository/tax_inventory_repository.dart';
import 'dashboard.dart';

class AddItemDialog extends StatefulWidget {
  final String token;
  final Function(Products product) onItemAdded;

  const AddItemDialog({super.key, required this.onItemAdded,   required this.token,});

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
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  OverlayEntry? _taxOverlay;
  final LayerLink _taxLayerLink = LayerLink();

  String? _selectedImagePath;

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

  //
  // final String token =
  //     'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NjgyMDMwNjQsIm5iZiI6MTc2ODIwMzA2NCwiZXhwIjoxNzcwNzk1MDY0LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.vBVcnan6C9hN-ZDGN1vgpN_MkuT4twI-_WqXGOTgAio';

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchTaxes();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
        _selectedImagePath = image.path; // 🔥 THIS WAS MISSING
      });

      print("🖼 Image selected → ${image.path}");
    } else {
      print("⚠️ Image picking cancelled");
    }
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
      final repo =TaxinventoryRepository(widget.token);
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
        token: widget.token,
      );
      final beverages = await repo.fetchCategorySublist(
        categoryId: 228,
        token: widget.token,
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
      final repo = ProductRepository( token: widget.token,);
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
      backgroundColor: Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Center(
        child: Text("Add New Stock", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      content: SizedBox(
        width: 500,
        height:300,
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

              Row(
                children: [

                  Expanded(
                    child: Row(
                      children: [
                        // === DASHED RECTANGLE BOX ===
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(8),
                          child: DottedBorder(
                            color: const Color(0xFFCAD5E2),
                            strokeWidth: 1,
                            dashPattern: const [6, 4],
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // IMAGE / PLACEHOLDER
                                    Center(
                                      child: _pickedImage == null
                                          ? Container(
                                        width: 48,
                                        height: 48,
                                        decoration: ShapeDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment(0.0, 0.0),
                                            end: Alignment(1.0, 1.0),
                                            colors: [
                                              Color(0xFFEEF5FE),
                                              Color(0xFFDAEAFE),
                                            ],
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.asset(
                                            'assets/uploadimage.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      )
                                          : Image.file(
                                        _pickedImage!,
                                        fit: BoxFit.cover, // ✅ fills & clips perfectly
                                      ),
                                    ),

                                    /// DELETE OVERLAY
                                    if (_pickedImage != null)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _pickedImage = null;
                                            });
                                          },
                                          child: Container(
                                            height: 18,
                                            color: const Color(0xFFFFF7F7),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Icons.delete_outline,
                                                  size: 12,
                                                  color: Color(0xFFEF4444),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Color(0xFFEF4444),
                                                    fontSize: 10,
                                                    fontFamily: 'Kumbh Sans',
                                                    fontWeight: FontWeight.w500,
                                                    height: 0.94,
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
                            ),

                          ),
                        ),


                        const SizedBox(width: 12),

                        // === TEXT OUTSIDE ===
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Upload Image',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Kumbh Sans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '(PNG/JPG, max 2 MB)',
                              style: TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontSize: 12,
                                fontFamily: 'Kumbh Sans',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ===== RIGHT INPUT FIELD =====
                  Expanded(
                    child: _buildLabeledField(
                      label: "Product Name",
                      controller: _nameController,
                      hint: "Enter Product Name",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              // ===== SECOND ROW: Category + SubCategory =====
              Row(
                children: [
                  // ===== CATEGORY DROPDOWN =====
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Category",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),

                        SizedBox(
                          height: 40, // ✅ exact height
                          child: DropdownButtonFormField<CategorySublistResponse>(
                            isExpanded: true,
                            value: selectedParentCategory,
                            hint: Text(
                              "Select Category",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),


                            items: parentCategories.map((parent) {
                              return DropdownMenuItem(
                                value: parent,
                                child: Text(
                                  parent.parentName,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),

                            onChanged: (value) {
                              setState(() {
                                selectedParentCategory = value;
                                _categoryController.text = value?.parentName ?? '';

                                selectedCategory = null;
                                selectedMiniCategory = null;
                                _subCategoryController.clear();
                                _miniCategoryController.clear();
                              });
                            },

                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 11), // 🔥 perfect center
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
                            ),

                            dropdownColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

// ===== SUBCATEGORY DROPDOWN WITH INLINE MINI CATEGORIES =====
                  SizedBox(
                    width: 245,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sub Category",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),

                        // Dropdown-like container
                        GestureDetector(
                            onTap: () async {
                              if (selectedParentCategory == null) return;

                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  return Align(
                                    alignment: const Alignment(0.6, 0.6),
                                    child: Container(
                                      width: 250,
                                      margin: const EdgeInsets.only(bottom: 19),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: DraggableScrollableSheet(
                                        expand: false,
                                        initialChildSize: 0.45,
                                        minChildSize: 0.3,
                                        maxChildSize: 0.7,
                                        builder: (context, scrollController) {
                                          return ListView(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                            children: selectedParentCategory!.categories.map((sub) {
                                              if (sub.children.isEmpty) {
                                                // No mini categories: select subcategory directly
                                                return ListTile(
                                                  dense: true,
                                                  visualDensity: VisualDensity.compact,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                                  title: Text(sub.name, style: const TextStyle(fontSize: 13)),
                                                  selected: selectedCategory?.id == sub.id,
                                                  selectedTileColor: Colors.blue.withOpacity(0.1),
                                                  onTap: () {
                                                    setState(() {
                                                      selectedCategory = sub;
                                                      selectedMiniCategory = null;

                                                      _subCategoryController.text = sub.name;
                                                      _miniCategoryController.text = "";
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                );
                                              } else {
                                                // Has mini categories: show ExpansionTile
                                                return Theme(
                                                  data: Theme.of(context).copyWith(
                                                    dividerColor: Colors.transparent,
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  child: ExpansionTile(
                                                    tilePadding: const EdgeInsets.symmetric(horizontal: 6),
                                                    dense: true,
                                                    title: Text(sub.name, style: const TextStyle(fontSize: 13)),
                                                    children: sub.children.map((mini) {
                                                      return ListTile(
                                                        dense: true,
                                                        visualDensity: VisualDensity.compact,
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                                        title: Text(mini.name, style: const TextStyle(fontSize: 12)),
                                                        selected: selectedMiniCategory?.id == mini.id,
                                                        selectedTileColor: Colors.blue.withOpacity(0.1),
                                                        onTap: () {
                                                          setState(() {
                                                            selectedCategory = sub;
                                                            selectedMiniCategory = mini;

                                                            _subCategoryController.text = sub.name;
                                                            _miniCategoryController.text = mini.name;
                                                          });
                                                          Navigator.pop(context);
                                                        },
                                                      );
                                                    }).toList(),
                                                  ),
                                                );
                                              }
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              height: 39,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedMiniCategory != null
                                          ? "${selectedCategory?.name} → ${selectedMiniCategory?.name}"
                                          : (selectedCategory != null
                                          ? selectedCategory!.name
                                          : "Select Sub Category"),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: selectedCategory != null
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                ],
                              ),
                            )

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
                  // Expanded(
                  //   child: _buildLabeledField(
                  //     label: "Stock Quantity",
                  //     controller: _unitsController,
                  //     hint: "Enter quantity",
                  //     isNumber: true,
                  //   ),
                  // ),
                  Expanded(
                    child: _buildLabeledField(
                      label: "SKU Code",
                      controller: _skuController,
                      hint: "Enter SKU code",
                      suffix: Padding(
                        padding: const EdgeInsets.all(6), // space from field edge
                        child: GestureDetector(
                          onTap: () {
                            _skuController.text =
                            "SKU-${DateTime.now().millisecondsSinceEpoch}";
                          },
                          child: Container(
                            width: 100,
                            height: 35, // fixed height
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFE6464),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            alignment: Alignment.center,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tax",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),

                        SizedBox(
                          height: 40,
                          child: DropdownButtonFormField<TaxInventoryModel>(
                            isExpanded: true,
                            value: selectedTax,
                            hint: const Text("Select Tax", style: TextStyle(fontSize: 12,   color: Color(0xFF949494),)),

                            items: taxes.map((tax) {
                              return DropdownMenuItem(
                                value: tax,
                                child: Text(tax.name, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),

                            onChanged: (tax) {
                              setState(() {
                                selectedTax = tax;
                                _taxController.text = tax?.name ?? '';
                              });
                            },

                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            ),

                            dropdownColor: Colors.white,
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

                  // const SizedBox(width: 12),

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
        const SizedBox(height: 6), // consistent vertical spacing
        SizedBox(
          height: 38.0 * (maxLines > 1 ? maxLines : 1),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13), // smaller font inside
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // reduced padding
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
        const SizedBox(height: 6), // consistent spacing
        SizedBox(
          height: 38,
          child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: controller,
                readOnly: true,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Select $label",
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  suffixIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
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
        width:180,
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
      width: 180,
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

          print("🧪 Selected image path = $_selectedImagePath");

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
          int? imageId;

          try {
            // 🔼 STEP 1: Upload image if selected
            if (_selectedImagePath != null &&
                _selectedImagePath!.isNotEmpty) {
              imageId = await _repository.uploadImageToMedia(
                token: widget.token,
                imagePath: _selectedImagePath!,
              );
              print("🖼️ Image uploaded. Media ID: $imageId");
            }

            // 🔼 STEP 2: Create / Update Item
            final response = await _repository.addOrUpdateItem(
              token: widget.token,
              itemName: _nameController.text.trim(),
              categoryId: selectedCategory?.id ?? 0,
              miniCategoryId: selectedMiniCategory?.id,
              taxClass: selectedTax?.taxClass,
              itemQty: int.tryParse(_unitsController.text.trim()) ?? 0,
              itemPrice:
              int.tryParse(_thresholdController.text.trim()) ?? 0,
              itemNote: _notesController.text.trim(),
              itemSku: _skuController.text.trim(),
              imageId: imageId, // ✅ NOW SENT
            );

            if (!mounted) return;

            if (response.isCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Item added successfully")),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("❌ Error: $e")),
            );


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