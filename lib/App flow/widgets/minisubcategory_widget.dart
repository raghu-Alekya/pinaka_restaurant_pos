// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../blocs/Bloc Event/order_event.dart';
// import '../../blocs/Bloc Logic/order_bloc.dart';
// import '../../models/category/items_model.dart';
// import '../../models/category/minisubcategory_model.dart';
// import '../../models/order/modifier_model.dart';
// import '../../models/order/order_items.dart';
// import '../../models/sidebar/category_model_.dart';
// import '../../repositories/minisubcategory_repository.dart';
// import '../../repositories/modifier_repository.dart';
// import '../../repositories/variant_repository.dart';
// import '../widgets/variant_popup.dart';
//
// class MiniSubCategoryWidget extends StatefulWidget {
//   final List<MiniSubCategory> subCategories;
//   final Category section;
//   final MiniSubCategoryRepository repository;
//   final VariantRepository variantRepository;
//   final int tappedSubCategoryId;
//   final Future<List<Product>> Function(int subCategoryId) fetchProducts;
//   final ModifierRepository? modifierRepository; // nullable
//
//   // final String baseUrl;
//   // final String token;
//   // final int section;
//
//
//   final void Function(MiniSubCategory folder)? onFolderSelected;
//   final void Function(Product item)? onItemSelected;
//
//   const MiniSubCategoryWidget({
//     super.key,
//     required this.subCategories,
//     required this.section,
//     required this.repository,
//     required this.variantRepository,
//     required this.tappedSubCategoryId,
//     required this.fetchProducts,
//     this.onFolderSelected,
//     this.onItemSelected,
//     this.modifierRepository,
//     // required this.baseUrl,
//     // required this.token,
//     // required this.section,
//   });
//
//   @override
//   State<MiniSubCategoryWidget> createState() => _MiniSubCategoryWidgetState();
// }
//
// class _MiniSubCategoryWidgetState extends State<MiniSubCategoryWidget> {
//   MiniSubCategory? selectedFolder;
//   List<MiniSubCategory> currentSubCategories = [];
//   bool isLoadingDirectProducts = false;
//
//   // same item is instant instead of re-hitting the repository every time.
//   // static final Map<int, List<ModifierModel>> _modifierCache = {};
//   static final Map<int, List<dynamic>> _variantCache = {};
//
//   final List<Color> tileColors = [
//     const Color(0xFFF0FBFF),
//     const Color(0xFFFEE8C2),
//     const Color(0xFFFFFFFF),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     currentSubCategories = widget.subCategories;
//
//     // Auto-select folder or fetch direct products after first frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _autoSelectAndLoad();
//     });
//   }
//
//   @override
//   void didUpdateWidget(covariant MiniSubCategoryWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//
//     // Reload when the selected subcategory changes
//     if (oldWidget.tappedSubCategoryId != widget.tappedSubCategoryId) {
//       currentSubCategories = widget.subCategories;
//
//       selectedFolder = widget.subCategories
//           .where((e) => e.isFolder)
//           .cast<MiniSubCategory?>()
//           .firstOrNull;
//
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           _autoSelectAndLoad();
//         }
//       });
//     }
//   }
//   bool isComboItem(Product item) {
//     return item.isCombo;
//   }
//
//
//   Future<void> _openComboDetails(
//       BuildContext context,
//       Product product,
//       ) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(child: CircularProgressIndicator()),
//     );
//
//     try {
//       final comboRepo = ComboRepository();
//
//       final comboProduct =
//       await comboRepo.fetchComboDetails(product.id);
//
//       if (!context.mounted) return;
//       Navigator.pop(context);
//
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: SizedBox(
//             height : 170,
//             width: 100, // 🔥 reduce width here (try 240–280)
//             child: Padding(
//               padding: const EdgeInsets.all(14),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // HEADER
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           comboProduct.name,
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                       InkWell(
//                         onTap: () => Navigator.pop(context),
//                         borderRadius: BorderRadius.circular(20),
//                         child: Container(
//                           width: 28,
//                           height: 28,
//                           decoration: const BoxDecoration(
//                             color: Colors.red,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.close,
//                             color: Colors.white,
//                             size: 16,
//                           ),
//                         ),
//                       ),
//
//                     ],
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   // SUB ITEMS
//                   comboItemsList(comboProduct),
//                 ],
//               ),
//             ),
//           ),
//         ),
//
//       );
//     } catch (e) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text(e.toString()),
//         duration: Duration(seconds: 1)));
//     }
//   }
//   Widget comboItemsList(ComboProduct comboProduct) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF6C6FF7),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: comboProduct.subItems.map((item) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 3),
//             child: Text(
//               "${item.quantity} × ${item.name}",
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//
//
//
//   Future<void> _autoSelectAndLoad() async {
//     final folders = currentSubCategories.where((e) => e.isFolder).toList();
//
//     if (folders.isNotEmpty) {
//       selectedFolder = folders.first;
//       widget.onFolderSelected?.call(selectedFolder!);
//
//       // Products already available from API
//       if (selectedFolder!.products.isNotEmpty) {
//         if (mounted) {
//           setState(() {}); // only one rebuild
//         }
//         return;
//       }
//
//       // Only fetch if products are missing
//       final products = await widget.fetchProducts(selectedFolder!.id);
//
//       if (!mounted) return;
//
//       final folderName = selectedFolder!.name.toLowerCase();
//
//       final updatedProducts = products.map((p) {
//         if (folderName.contains('non veg')) {
//           return p.copyWith(isVeg: false);
//         } else if (folderName.contains('veg')) {
//           return p.copyWith(isVeg: true);
//         }
//         return p;
//       }).toList();
//
//       final newFolder = selectedFolder!.copyWith(
//         products: updatedProducts,
//         count: updatedProducts.length,
//       );
//
//       setState(() {
//         selectedFolder = newFolder;
//         currentSubCategories = currentSubCategories.map((e) {
//           return e.id == newFolder.id ? newFolder : e;
//         }).toList();
//       });
//
//       return;
//     }
//
//     // No folders
//     final directItems = currentSubCategories.where((e) => !e.isFolder).toList();
//
//     if (directItems.isEmpty ||
//         directItems.every((e) => e.products.isEmpty)) {
//       await _fetchDirectProducts(widget.tappedSubCategoryId);
//     }
//   }
//
//
//
//   Future<void> _fetchDirectProducts(int subCategoryId) async {
//     if (!mounted) return;
//
//     setState(() => isLoadingDirectProducts = true);
//
//     try {
//       final products = await widget.fetchProducts(subCategoryId);
//
//       if (!mounted) return;
//
//       setState(() {
//         currentSubCategories = [
//           MiniSubCategory(
//             id: subCategoryId,
//             name: "Direct Items",
//             isFolder: false,
//             products: products,
//             count: products.length,
//           )
//         ];
//       });
//     } catch (e) {
//       print("[MiniSubCategoryWidget] Error fetching direct products: $e");
//     } finally {
//       if (!mounted) return;
//
//       setState(() => isLoadingDirectProducts = false);
//     }
//   }
//
//   void _onFolderTap(MiniSubCategory folder) async {
//     // if same folder tapped again → do nothing (keep it selected)
//     if (selectedFolder?.id == folder.id) {
//       return;
//     }
//     if (!mounted) return;
//
//     // select the new folder
//     setState(() {
//       selectedFolder = folder;
//     });
//
//     widget.onFolderSelected?.call(folder);
//
//     // if products already loaded, no need to fetch again
//     if (folder.products.isNotEmpty) return;
//
//     try {
//       final products = await widget.fetchProducts(folder.id);
//
//       final folderName = folder.name.toLowerCase();
//       final updatedProducts = products.map((p) {
//         if (folderName.contains('non veg')) {
//           return p.copyWith(isVeg: false);
//         } else if (folderName.contains('veg')) {
//           return p.copyWith(isVeg: true);
//         }
//         return p;
//       }).toList();
//
//       final newFolder = folder.copyWith(
//         products: updatedProducts,
//         count: updatedProducts.length,
//       );
//
//       setState(() {
//         // keep this folder selected and update its data
//         selectedFolder = newFolder;
//
//         // update it inside your list also
//         currentSubCategories = currentSubCategories.map((e) {
//           return e.id == newFolder.id ? newFolder : e;
//         }).toList();
//       });
//     } catch (e) {
//       print("[MiniSubCategoryWidget] Error fetching folder products: $e");
//     }
//   }
//
//
//
//
//
//   Future<void> _onItemTap(BuildContext context, Product item) async {
//     // ✅ Don't allow out-of-stock items
//     if (!item.inStock) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("${item.name} is out of stock"),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 1),
//         ),
//       );
//       return;
//     }
//     final orderBloc = context.read<OrderBloc>();
//
//     debugPrint("modifierRepository = ${widget.modifierRepository}");
//
//     // Fetch modifiers/add-ons
//     final modifiers = await widget.modifierRepository!
//         .fetchModifiersByProductId(item.id);
//
//     final hasOptions = modifiers.isNotEmpty;
//
//     debugPrint("Product: ${item.name}");
//     debugPrint("Modifiers fetched: ${modifiers.length}");
//     debugPrint("Has Options: $hasOptions");
//
//     final orderItem = OrderItems(
//       productId: item.id,
//       variationId: null,
//       name: item.name,
//       price: item.price,
//       quantity: 1,
//       modifiers: const [],
//       addOns: const {},
//       section: widget.section,
//       amount: item.price,
//       hasOptions: hasOptions, // ✅ Save this
//     );
//
//     try {
//       final variants =
//       await widget.variantRepository.fetchVariantsByProduct(item.id);
//
//       if (variants.isNotEmpty) {
//         final updatedProduct = item.copyWith(variants: variants);
//
//         _showVariantPopup(
//           context,
//           updatedProduct,
//           orderBloc,
//           widget.section,
//           hasOptions, // Pass it to the popup too
//         );
//       } else {
//         orderBloc.add(AddOrderItem(orderItem));
//       }
//     } catch (e) {
//       orderBloc.add(AddOrderItem(orderItem));
//     }
//   }
//
//   void _showVariantPopup(
//       BuildContext context,
//       Product product,
//       OrderBloc orderBloc,
//       Category section, bool hasOptions,
//       ) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => VariantPopupContent(
//         product: product,
//         itemName: product.name,
//         variants: product.variants,
//         onVariantSelected: (variant) {
//           print("[VariantPopup] Variant selected: ${variant.name}");
//         },
//         onSelected: (variant) {
//           final orderItem = OrderItems(
//             productId: product.id,
//             variationId: variant.id,
//             name: '${product.name} - ${variant.name}',
//             price: variant.price,
//             quantity: 1,
//             modifiers: const [],
//             addOns: const {},
//             section: section,
//             amount: variant.price,
//             hasOptions: hasOptions, // ✅ Important
//           );
//
//           orderBloc.add(AddOrderItem(orderItem));
//
//           print("[VariantPopup] Added to order: ${orderItem.name} x${orderItem.quantity}");
//         },
//
//         section: section,
//         orderBloc: orderBloc,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final folders = currentSubCategories.where((e) => e.isFolder).toList();
//     final directItems = currentSubCategories.where((e) => !e.isFolder).toList();
//     final folderItems = selectedFolder?.products ?? [];
//
//     if (isLoadingDirectProducts) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.white, width: 1.2), // Grid border
//         borderRadius: BorderRadius.circular(12),
//         color: Color(0XFFDEE8FF),
//         boxShadow: const [
//           BoxShadow(color: Colors.white, blurRadius: 3, offset: Offset(0, 0)),
//         ],
//       ),
//       child: ListView(
//         padding: const EdgeInsets.all(6),
//         children: [
//           if (folders.isNotEmpty) ...[
//             _buildFolderGrid(folders),
//             const SizedBox(height: 6),
//             if (selectedFolder != null && folderItems.isNotEmpty)
//               _buildItemsGrid(folderItems),
//
//           ],
//           if (folders.isEmpty && directItems.isNotEmpty)
//             _buildItemsGrid(directItems.expand<Product>((e) => e.products).toList()),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFolderGrid(List<MiniSubCategory> folders) {
//     return SizedBox(
//       height: 40, // adjust height for row layout
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 2),
//         itemCount: folders.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 10),
//         itemBuilder: (context, index) {
//           final folder = folders[index];
//           final isSelected = selectedFolder == folder;
//
//           return GestureDetector(
//             onTap: () => _onFolderTap(folder),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: isSelected ? const Color(0xFFFCDFDC) : Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey.shade300, width: 1),
//                 boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min, // hug content
//                 children: [
//                   const Icon(Icons.folder, size: 20, color: Colors.black),
//                   const SizedBox(width: 6),
//                   Flexible(
//                     child: Text(
//                       folder.name,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: selectedFolder?.id == folder.id
//                             ? FontWeight.w600   // ✅ selected
//                             : FontWeight.w400,  // ⬅ unselected
//                       ),
//                     ),
//
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildItemsGrid(List<Product> items) {
//     const double stripWidth = 0;
//     const double stripGap = 1;
//
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: items.length,
//       padding: const EdgeInsets.fromLTRB(1, 6, 2, 0),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4,
//         mainAxisSpacing: 0, // 🔼 space between rows
//         crossAxisSpacing: 8,
//         childAspectRatio: 1.4, // 🔼 taller to fit "View more"
//       ),
//       itemBuilder: (context, index) {
//         final item = items[index];
//         final backgroundColor = tileColors[index % tileColors.length];
//
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//
//             // 🔹 PRODUCT CARD
//             GestureDetector(
//               onTap: () => _onItemTap(context, item),
//               child: Container(
//                 height: 72, // fixed card height
//                 padding: const EdgeInsets.fromLTRB(
//                   stripWidth + stripGap,
//                   0,
//                   0,
//                   0,
//                 ),
//                 decoration: BoxDecoration(
//                   color: backgroundColor,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: Colors.grey.shade300, width: 2),
//                   boxShadow: const [
//                     BoxShadow(color: Colors.black12, blurRadius: 2),
//                   ],
//                 ),
//                 child: Stack(
//                   children: [
//
//                     // CONTENT
//                     Row(
//                       children: [
//                         const SizedBox(width: 8),
//                         if (item.image.isNotEmpty)
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.network(
//                               item.image,
//                               width: 50,
//                               height: 48,
//                               fit: BoxFit.cover,
//                               errorBuilder: (_, __, ___) =>
//                               const Icon(Icons.fastfood, size: 40),
//                             ),
//                           )
//                         else
//                           const Icon(Icons.fastfood, size: 40),
//
//                         const SizedBox(width: 8),
//
//                         Expanded(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 item.name,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 '₹${item.price.toStringAsFixed(0)}',
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     // 🌱 VEG / NON-VEG STRIP
//                     Positioned(
//                       left: 0,
//                       top: 0,
//                       bottom: 0,
//                       child: item.isVeg == null
//                           ? const SizedBox.shrink()
//                           : Container(
//                         width: 3,
//                         decoration: BoxDecoration(
//                           color: item.isVeg! ? Colors.green : Colors.red,
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(10),
//                             bottomLeft: Radius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     // 🔹 VARIANT ICON
//                     if (item.isVariantProduct)
//                       Positioned(
//                         top: 45,
//                         right: 6,
//                         child: Image.asset(
//                           'assets/variant_icon.png',
//                           width: 10,
//                           height: 10,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // 🔥 VIEW MORE (ONLY FOR COMBO)
//             if (isComboItem(item))
//               Padding(
//                 padding: const EdgeInsets.only(top: 4),
//                 child: InkWell(
//                   onTap: () => _openComboDetails(context, item),
//                   child: const Text(
//                     "View more",
//                     style: TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                       decoration: TextDecoration.underline,
//                       color: Color(0xFF191919),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }
//
// }



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
  });

  @override
  State<MiniSubCategoryWidget> createState() => _MiniSubCategoryWidgetState();
}

class _MiniSubCategoryWidgetState extends State<MiniSubCategoryWidget> {
  MiniSubCategory? selectedFolder;
  List<MiniSubCategory> currentSubCategories = [];
  bool isLoadingDirectProducts = false;

  // ✅ Caches modifiers & variants per productId so the 2nd+ tap on the
  // same item is instant instead of re-hitting the repository every time.
  static final Map<int, List<Modifier>> _modifierCache = {};
  static final Map<int, List<Variant>> _variantCache = {};

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

  @override
  void didUpdateWidget(covariant MiniSubCategoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload when the selected subcategory changes
    if (oldWidget.tappedSubCategoryId != widget.tappedSubCategoryId) {
      currentSubCategories = widget.subCategories;

      selectedFolder = widget.subCategories
          .where((e) => e.isFolder)
          .cast<MiniSubCategory?>()
          .firstOrNull;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _autoSelectAndLoad();
        }
      });
    }
  }

  bool isComboItem(Product item) {
    return item.isCombo;
  }

  Future<void> _openComboDetails(
      BuildContext context,
      Product product,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final comboRepo = ComboRepository();

      final comboProduct = await comboRepo.fetchComboDetails(product.id);

      if (!context.mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 170,
            width: 100,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          comboProduct.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // SUB ITEMS
                  comboItemsList(comboProduct),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget comboItemsList(ComboProduct comboProduct) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6C6FF7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: comboProduct.subItems.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              "${item.quantity} × ${item.name}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _autoSelectAndLoad() async {
    final folders = currentSubCategories.where((e) => e.isFolder).toList();

    if (folders.isNotEmpty) {
      selectedFolder = folders.first;
      widget.onFolderSelected?.call(selectedFolder!);

      // Products already available from API
      if (selectedFolder!.products.isNotEmpty) {
        if (mounted) {
          setState(() {}); // only one rebuild
        }
        return;
      }

      // Only fetch if products are missing
      final products = await widget.fetchProducts(selectedFolder!.id);

      if (!mounted) return;

      final folderName = selectedFolder!.name.toLowerCase();

      final updatedProducts = products.map((p) {
        if (folderName.contains('non veg')) {
          return p.copyWith(isVeg: false);
        } else if (folderName.contains('veg')) {
          return p.copyWith(isVeg: true);
        }
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

      return;
    }

    // No folders
    final directItems = currentSubCategories.where((e) => !e.isFolder).toList();

    if (directItems.isEmpty || directItems.every((e) => e.products.isEmpty)) {
      await _fetchDirectProducts(widget.tappedSubCategoryId);
    }
  }

  Future<void> _fetchDirectProducts(int subCategoryId) async {
    if (!mounted) return;

    setState(() => isLoadingDirectProducts = true);

    try {
      final products = await widget.fetchProducts(subCategoryId);

      if (!mounted) return;

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
      if (!mounted) return;

      setState(() => isLoadingDirectProducts = false);
    }
  }

  void _onFolderTap(MiniSubCategory folder) async {
    // if same folder tapped again → do nothing (keep it selected)
    if (selectedFolder?.id == folder.id) {
      return;
    }
    if (!mounted) return;

    // select the new folder
    setState(() {
      selectedFolder = folder;
    });

    widget.onFolderSelected?.call(folder);

    // if products already loaded, no need to fetch again
    if (folder.products.isNotEmpty) return;

    try {
      final products = await widget.fetchProducts(folder.id);

      final folderName = folder.name.toLowerCase();
      final updatedProducts = products.map((p) {
        if (folderName.contains('non veg')) {
          return p.copyWith(isVeg: false);
        } else if (folderName.contains('veg')) {
          return p.copyWith(isVeg: true);
        }
        return p;
      }).toList();

      final newFolder = folder.copyWith(
        products: updatedProducts,
        count: updatedProducts.length,
      );

      setState(() {
        // keep this folder selected and update its data
        selectedFolder = newFolder;

        // update it inside your list also
        currentSubCategories = currentSubCategories.map((e) {
          return e.id == newFolder.id ? newFolder : e;
        }).toList();
      });
    } catch (e) {
      print("[MiniSubCategoryWidget] Error fetching folder products: $e");
    }
  }

  Future<void> _onItemTap(BuildContext context, Product item) async {
    // ✅ Don't allow out-of-stock items
    if (!item.inStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${item.name} is out of stock"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }
    final orderBloc = context.read<OrderBloc>();

    debugPrint("modifierRepository = ${widget.modifierRepository}");

    // ✅ Modifiers: use cache if we already fetched them for this product
    List<Modifier> modifiers;
    if (_modifierCache.containsKey(item.id)) {
      modifiers = _modifierCache[item.id]!;
      debugPrint("Modifiers (cached) for ${item.name}: ${modifiers.length}");
    } else {
      modifiers = await widget.modifierRepository!
          .fetchModifiersByProductId(item.id);
      _modifierCache[item.id] = modifiers;
      debugPrint("Modifiers (fetched) for ${item.name}: ${modifiers.length}");
    }

    final hasOptions = modifiers.isNotEmpty;

    debugPrint("Product: ${item.name}");
    debugPrint("Has Options: $hasOptions");

    final orderItem = OrderItems(
      productId: item.id,
      variationId: null,
      name: item.name,
      price: item.price,
      quantity: 1,
      modifiers: const [],
      addOns: const {},
      section: widget.section,
      amount: item.price,
      hasOptions: hasOptions,
    );

    try {
      // ✅ Variants: use cache if we already fetched them for this product
      List<Variant> variants;
      if (_variantCache.containsKey(item.id)) {
        variants = _variantCache[item.id]!;
        debugPrint("Variants (cached) for ${item.name}: ${variants.length}");
      } else {
        variants =
        await widget.variantRepository.fetchVariantsByProduct(item.id);
        _variantCache[item.id] = variants;
        debugPrint("Variants (fetched) for ${item.name}: ${variants.length}");
      }

      if (variants.isNotEmpty) {
        final updatedProduct = item.copyWith(variants: variants);

        _showVariantPopup(
          context,
          updatedProduct,
          orderBloc,
          widget.section,
          hasOptions,
        );
      } else {
        orderBloc.add(AddOrderItem(orderItem));
      }
    } catch (e) {
      orderBloc.add(AddOrderItem(orderItem));
    }
  }

  void _showVariantPopup(
      BuildContext context,
      Product product,
      OrderBloc orderBloc,
      Category section,
      bool hasOptions,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VariantPopupContent(
        product: product,
        itemName: product.name,
        variants: product.variants,
        onVariantSelected: (variant) {
          print("[VariantPopup] Variant selected: ${variant.name}");
        },
        onSelected: (variant) {
          final orderItem = OrderItems(
            productId: product.id,
            variationId: variant.id,
            name: '${product.name} - ${variant.name}',
            price: variant.price,
            quantity: 1,
            modifiers: const [],
            addOns: const {},
            section: section,
            amount: variant.price,
            hasOptions: hasOptions, // ✅ Important
          );

          orderBloc.add(AddOrderItem(orderItem));

          print(
              "[VariantPopup] Added to order: ${orderItem.name} x${orderItem.quantity}");
        },
        section: section,
        orderBloc: orderBloc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folders = currentSubCategories.where((e) => e.isFolder).toList();
    final directItems =
    currentSubCategories.where((e) => !e.isFolder).toList();
    final folderItems = selectedFolder?.products ?? [];

    if (isLoadingDirectProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.2), // Grid border
        borderRadius: BorderRadius.circular(12),
        color: const Color(0XFFDEE8FF),
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
            _buildItemsGrid(
                directItems.expand<Product>((e) => e.products).toList()),
        ],
      ),
    );
  }

  Widget _buildFolderGrid(List<MiniSubCategory> folders) {
    return SizedBox(
      height: 40,
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
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFCDFDC) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 3)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder, size: 20, color: Colors.black),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      folder.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selectedFolder?.id == folder.id
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
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
    const double stripWidth = 0;
    const double stripGap = 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      padding: const EdgeInsets.fromLTRB(1, 6, 2, 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 0,
        crossAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final backgroundColor = tileColors[index % tileColors.length];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 PRODUCT CARD
            GestureDetector(
              onTap: () => _onItemTap(context, item),
              child: Container(
                height: 72,
                padding: const EdgeInsets.fromLTRB(
                  stripWidth + stripGap,
                  0,
                  0,
                  0,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 2),
                  ],
                ),
                child: Stack(
                  children: [
                    // CONTENT
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        if (item.image.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.image,
                              width: 50,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.fastfood, size: 40),
                            ),
                          )
                        else
                          const Icon(Icons.fastfood, size: 40),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 🌱 VEG / NON-VEG STRIP
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: item.isVeg == null
                          ? const SizedBox.shrink()
                          : Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color:
                          item.isVeg! ? Colors.green : Colors.red,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // 🔹 VARIANT ICON
                    if (item.isVariantProduct)
                      Positioned(
                        top: 45,
                        right: 6,
                        child: Image.asset(
                          'assets/variant_icon.png',
                          width: 10,
                          height: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 🔥 VIEW MORE (ONLY FOR COMBO)
            if (isComboItem(item))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: InkWell(
                  onTap: () => _openComboDetails(context, item),
                  child: const Text(
                    "View more",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      color: Color(0xFF191919),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}