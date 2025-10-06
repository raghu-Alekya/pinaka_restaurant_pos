import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../models/category/items_model.dart';
import '../../models/category/minisubcategory_model.dart';
import '../../models/order/modifier_model.dart';
import '../../models/order/order_items.dart';
import '../../models/sidebar/category_model_.dart';
import '../../repositories/minisubcategory_repository.dart';
import '../../repositories/modifier_repository.dart';
import '../../repositories/variant_repository.dart';
import '../widgets/variant_popup.dart';

class MiniSubCategoryWidget extends StatefulWidget {
  final List<MiniSubCategory> subCategories;
  final Category section;
  final MiniSubCategoryRepository repository;
  final VariantRepository variantRepository;
  final int tappedSubCategoryId;
  final Future<List<Product>> Function(int subCategoryId) fetchProducts;
  final ModifierRepository? modifierRepository; // nullable

  // final String baseUrl;
  // final String token;
  // final int section;


  final void Function(MiniSubCategory folder)? onFolderSelected;
  final void Function(Product item)? onItemSelected;

  const MiniSubCategoryWidget({
    super.key,
    required this.subCategories,
    required this.section,
    required this.repository,
    required this.variantRepository,
    required this.tappedSubCategoryId,
    required this.fetchProducts,
    this.onFolderSelected,
    this.onItemSelected,
    this.modifierRepository,
    // required this.baseUrl,
    // required this.token,
    // required this.section,
  });

  @override
  State<MiniSubCategoryWidget> createState() => _MiniSubCategoryWidgetState();
}

class _MiniSubCategoryWidgetState extends State<MiniSubCategoryWidget> {
  MiniSubCategory? selectedFolder;
  List<MiniSubCategory> currentSubCategories = [];
  bool isLoadingDirectProducts = false;

  final List<Color> tileColors = [
    const Color(0xFFF0FBFF),
    const Color(0xFFFEE8C2),
    const Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    currentSubCategories = widget.subCategories;

    // Auto-select folder or fetch direct products after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectAndLoad();
    });
  }

  Future<void> _autoSelectAndLoad() async {
    final folders = currentSubCategories.where((e) => e.isFolder).toList();
    if (folders.isNotEmpty) {
      selectedFolder = folders[0];
      widget.onFolderSelected?.call(selectedFolder!);
      setState(() {});

      if (selectedFolder!.products.isEmpty) {
        try {
          // 1️⃣ Fetch products
          final products = await widget.fetchProducts(selectedFolder!.id);

          // 2️⃣ Map veg/non-veg based on folder name
          final folderName = selectedFolder!.name.toLowerCase();
          final updatedProducts = products.map((p) {
            if (folderName.contains('veg')) return p.copyWith(isVeg: true);
            if (folderName.contains('non veg')) return p.copyWith(isVeg: false);
            return p;
          }).toList();

          // 3️⃣ Update folder object
          final newFolder = selectedFolder!.copyWith(
            products: updatedProducts,
            count: updatedProducts.length,
          );

          setState(() {
            // IMPORTANT: replace selectedFolder and also update it in the list
            selectedFolder = newFolder;
            currentSubCategories = currentSubCategories.map((e) {
              return e.id == newFolder.id ? newFolder : e;
            }).toList();
          });
        } catch (e) {
          print("[MiniSubCategoryWidget] Error fetching products for folder: $e");
        }
      }
      return;
    }

    // No folders → fetch direct items
    final hasDirectItems = currentSubCategories.any((e) => !e.isFolder);
    if (!hasDirectItems) {
      await _fetchDirectProducts(widget.tappedSubCategoryId);
    }
  }



  Future<void> _fetchDirectProducts(int subCategoryId) async {
    setState(() => isLoadingDirectProducts = true);
    try {
      final products = await widget.fetchProducts(subCategoryId);
      setState(() {
        currentSubCategories = [
          MiniSubCategory(
            id: subCategoryId,
            name: "Direct Items",
            isFolder: false,
            products: products,
            count: products.length,
          )
        ];
      });
    } catch (e) {
      print("[MiniSubCategoryWidget] Error fetching direct products: $e");
    } finally {
      setState(() => isLoadingDirectProducts = false);
    }
  }

  void _onFolderTap(MiniSubCategory folder) async {
    setState(() {
      selectedFolder = selectedFolder == folder ? null : folder;
    });
    widget.onFolderSelected?.call(folder);

    if (selectedFolder != null && selectedFolder!.products.isEmpty) {
      try {
        final products = await widget.fetchProducts(selectedFolder!.id);

        final folderName = selectedFolder!.name.toLowerCase();
        final updatedProducts = products.map((p) {
          if (folderName.contains('veg')) return p.copyWith(isVeg: true);
          if (folderName.contains('non veg')) return p.copyWith(isVeg: false);
          return p;
        }).toList();

        final newFolder = selectedFolder!.copyWith(
          products: updatedProducts,
          count: updatedProducts.length,
        );

        setState(() {
          selectedFolder = newFolder;
          currentSubCategories = currentSubCategories.map((e) {
            return e.id == newFolder.id ? newFolder : e;
          }).toList();
        });
      } catch (e) {
        print("[MiniSubCategoryWidget] Error fetching folder products: $e");
      }
    }
  }



  Future<void> _onItemTap(BuildContext context, Product item) async {
    final orderBloc = context.read<OrderBloc>();

    // Fetch modifiers for this product
    final modifiers = await widget.modifierRepository?.fetchModifiersByProductId(item.id) ?? [];

    // Determine if product has options
    final hasOptions = (modifiers.isNotEmpty || (item.addOns?.isNotEmpty ?? false));

    // Create OrderItem
    final orderItem = OrderItems(
      name: item.name,
      price: item.price,
      quantity: 1,
      modifiers: [],
      addOns: {},
      section: widget.section,
      productId: item.id,
      hasOptions: hasOptions,
      variationId: null,
      variantId: null, // 🔹 now accurate
    );

    try {
      // Check for variants
      final variants = await widget.variantRepository.fetchVariantsByProduct(item.id);
      if (variants.isNotEmpty) {
        final updatedProduct = item.copyWith(variants: variants);
        _showVariantPopup(context, updatedProduct, orderBloc, widget.section);
      } else {
        orderBloc.add(AddOrderItem(orderItem));
        print("[Dashboard] Added to order: ${orderItem.name} with hasOptions=$hasOptions");
      }
    } catch (e) {
      print("[Dashboard] Error fetching variants: $e");
      orderBloc.add(AddOrderItem(orderItem));
    }
  }

  void _showVariantPopup(
      BuildContext context,
      Product product,
      OrderBloc orderBloc,
      Category section,
      ) {
    showDialog(
      context: context,
      builder: (context) => VariantPopupContent(
        product: product,
        itemName: product.name,
        variants: product.variants,
        onVariantSelected: (variant) {
          print("[VariantPopup] Variant selected: ${variant.name}");
        },
        onSelected: (variant) {
          final orderItem = OrderItems(
            name: '${product.name} - ${variant.name}',
            price: variant.price,
            quantity: 1,
            modifiers: [],
            section: section,
            productId: product.id, variantId: null,
          );
          orderBloc.add(AddOrderItem(orderItem));
          print("[VariantPopup] Added to order: ${orderItem.name} x${orderItem.quantity}");
        },
        section: section,
        orderBloc: orderBloc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folders = currentSubCategories.where((e) => e.isFolder).toList();
    final directItems = currentSubCategories.where((e) => !e.isFolder).toList();
    final folderItems = selectedFolder?.products ?? [];

    if (isLoadingDirectProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.2), // Grid border
        borderRadius: BorderRadius.circular(12),
        color: Color(0XFFDEE8FF),
        boxShadow: const [
          BoxShadow(color: Colors.white, blurRadius: 3, offset: Offset(0, 0)),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(6),
        children: [
          if (folders.isNotEmpty) ...[
            _buildFolderGrid(folders),
            const SizedBox(height: 6),
            if (selectedFolder != null && folderItems.isNotEmpty)
              _buildItemsGrid(folderItems),
          ],
          if (folders.isEmpty && directItems.isNotEmpty)
            _buildItemsGrid(directItems.expand<Product>((e) => e.products).toList()),
        ],
      ),
    );
  }

  Widget _buildFolderGrid(List<MiniSubCategory> folders) {
    return SizedBox(
      height: 40, // adjust height for row layout
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: folders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final folder = folders[index];
          final isSelected = selectedFolder == folder;

          return GestureDetector(
            onTap: () => _onFolderTap(folder),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFCDFDC) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // hug content
                children: [
                  const Icon(Icons.folder, size: 20, color: Colors.black),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      folder.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsGrid(List<Product> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      padding: const EdgeInsets.all(6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final backgroundColor = tileColors[index % tileColors.length];

        return GestureDetector(
          onTap: () => _onItemTap(context, item),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    if (item.image.isNotEmpty)
                      Image.network(
                        item.image,
                        width: 60,
                        height: 65,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.fastfood, size: 40),
                      )
                    else
                      const Icon(Icons.fastfood, size: 40, color: Colors.black),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Veg/Non-Veg icon at top-right
                Positioned(
                  top: 2,
                  right: 2,
                  child: Builder(
                    builder: (_) {
                      final sectionName = widget.section.name.toLowerCase();
                      if (sectionName.contains('alcohol') ||
                          sectionName.contains('bewerages') ||
                          sectionName.contains('dessert')) {
                        return const SizedBox.shrink();
                      }
                      return Image.asset(
                        item.isVeg
                            ? 'assets/icon/veg_icon.png'
                            : 'assets/icon/nonveg_icon.png',
                        width: 15,
                        height: 15,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
