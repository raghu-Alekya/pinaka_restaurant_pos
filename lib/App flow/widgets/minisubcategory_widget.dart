// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../blocs/Bloc Event/order_event.dart';
// import '../../blocs/Bloc Logic/order_bloc.dart';
// import '../../constants/constants.dart';
// import '../../models/category/items_model.dart';
// import '../../models/category/minisubcategory_model.dart';
// import '../../models/order/modifier_model.dart';
// import '../../models/order/order_items.dart';
// import '../../models/sidebar/category_model_.dart';
// import '../../repositories/minisubcategory_repository.dart';
// import '../../repositories/modifier_repository.dart';
// import '../../repositories/order_repository.dart';
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
//   final void Function(MiniSubCategory folder)? onFolderSelected;
//   final void Function(Product item)? onItemSelected;
//   final String token;
//   final String restaurantId;
//   final bool isTakeAway;
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
//     required this.token,
//     required this.restaurantId,
//     required this.isTakeAway,
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
//   // ✅ Caches modifiers & variants per productId so the 2nd+ tap on the
//   // same item is instant instead of re-hitting the repository every time.
//   static final Map<int, List<Modifier>> _modifierCache = {};
//   static final Map<int, List<Variant>> _variantCache = {};
//   late OrderRepository orderRepository;
//   bool _isCreatingTakeAwayOrder = false;
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
//     orderRepository = OrderRepository(
//       baseUrl: AppConstants.baseDomain,
//     );
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
//   Future<void> _initializeTakeAwayOrder() async {
//     debugPrint("========== TAKEAWAY ORDER ==========");
//
//     if (!widget.isTakeAway) {
//       debugPrint("❌ Not a takeaway order. Skipping order creation.");
//       return;
//     }
//
//     // Prevent duplicate API calls
//     if (_isCreatingTakeAwayOrder) {
//       debugPrint("⏳ Takeaway order creation already in progress");
//       return;
//     }
//
//     final orderBloc = context.read<OrderBloc>();
//
//     // Already created
//     if ((orderBloc.state.orderId ?? 0) != 0) {
//       debugPrint("✅ Takeaway order already exists.");
//       return;
//     }
//
//     _isCreatingTakeAwayOrder = true;
//
//     try {
//       final response = await orderRepository.createTakeAwayOrder(
//         restaurantId: widget.restaurantId,
//         token: widget.token,
//       );
//
//       orderBloc.add(
//         SetTakeAwayOrder(
//           orderId: response.orderId,
//           restaurantId: response.restaurantId.toString(),
//         ),
//       );
//
//       await Future.delayed(const Duration(milliseconds: 100));
//
//       debugPrint("✅ Takeaway order created: ${response.orderId}");
//     } catch (e, stackTrace) {
//       debugPrint("❌ TakeAway Order Creation Failed");
//       debugPrint("Error: $e");
//       debugPrint(stackTrace.toString());
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Failed to create takeaway order"),
//           duration: Duration(seconds: 1),
//         ),
//       );
//     } finally {
//       // Always release the lock
//       _isCreatingTakeAwayOrder = false;
//     }
//   }
//   bool isComboItem(Product item) {
//     return item.isCombo;
//   }
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
//       final comboProduct = await comboRepo.fetchComboDetails(product.id);
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
//             height: 170,
//             width: 100,
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
//       );
//     } catch (e) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//           duration: const Duration(seconds: 1),
//         ),
//       );
//     }
//   }
//
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
//     if (directItems.isEmpty || directItems.every((e) => e.products.isEmpty)) {
//       await _fetchDirectProducts(widget.tappedSubCategoryId);
//     }
//   }
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
//   Future<void> _onItemTap(BuildContext context, Product item) async {
//     if (_isCreatingTakeAwayOrder) return;
//
//     if (widget.isTakeAway) {
//       await _initializeTakeAwayOrder();
//     }
//     // ✅ Don't allow out-of-stock items
//     if (!item.inStock) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("${item.name} is out of stock"),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 1),
//         ),
//       );
//       return;
//     }
//     final orderBloc = context.read<OrderBloc>();
//
//     debugPrint("modifierRepository = ${widget.modifierRepository}");
//
//     // ✅ Modifiers: use cache if we already fetched them for this product
//     List<Modifier> modifiers;
//     if (_modifierCache.containsKey(item.id)) {
//       modifiers = _modifierCache[item.id]!;
//       debugPrint("Modifiers (cached) for ${item.name}: ${modifiers.length}");
//     } else {
//       modifiers = await widget.modifierRepository!
//           .fetchModifiersByProductId(item.id);
//       _modifierCache[item.id] = modifiers;
//       debugPrint("Modifiers (fetched) for ${item.name}: ${modifiers.length}");
//     }
//
//     final hasOptions = modifiers.isNotEmpty;
//
//     debugPrint("Product: ${item.name}");
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
//       hasOptions: hasOptions,
//     );
//
//     try {
//       // ✅ Variants: use cache if we already fetched them for this product
//       List<Variant> variants;
//       if (_variantCache.containsKey(item.id)) {
//         variants = _variantCache[item.id]!;
//         debugPrint("Variants (cached) for ${item.name}: ${variants.length}");
//       } else {
//         variants =
//         await widget.variantRepository.fetchVariantsByProduct(item.id);
//         _variantCache[item.id] = variants;
//         debugPrint("Variants (fetched) for ${item.name}: ${variants.length}");
//       }
//
//       if (variants.isNotEmpty) {
//         final updatedProduct = item.copyWith(variants: variants);
//
//         _showVariantPopup(
//           context,
//           updatedProduct,
//           orderBloc,
//           widget.section,
//           hasOptions,
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
//       Category section,
//       bool hasOptions,
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
//           print(
//               "[VariantPopup] Added to order: ${orderItem.name} x${orderItem.quantity}");
//         },
//         section: section,
//         orderBloc: orderBloc,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final folders = currentSubCategories.where((e) => e.isFolder).toList();
//     final directItems =
//     currentSubCategories.where((e) => !e.isFolder).toList();
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
//         color: const Color(0XFFDEE8FF),
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
//           ],
//           if (folders.isEmpty && directItems.isNotEmpty)
//             _buildItemsGrid(
//                 directItems.expand<Product>((e) => e.products).toList()),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFolderGrid(List<MiniSubCategory> folders) {
//     return SizedBox(
//       height: 40,
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
//               padding:
//               const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: isSelected ? const Color(0xFFFCDFDC) : Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey.shade300, width: 1),
//                 boxShadow: const [
//                   BoxShadow(color: Colors.black12, blurRadius: 3)
//                 ],
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
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
//                             ? FontWeight.w600
//                             : FontWeight.w400,
//                       ),
//                     ),
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
//         mainAxisSpacing: 0,
//         crossAxisSpacing: 8,
//         childAspectRatio: 1.4,
//       ),
//       itemBuilder: (context, index) {
//         final item = items[index];
//         final backgroundColor = tileColors[index % tileColors.length];
//
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // 🔹 PRODUCT CARD
//             GestureDetector(
//               onTap: () => _onItemTap(context, item),
//               child: Container(
//                 height: 72,
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
//                           color:
//                           item.isVeg! ? Colors.green : Colors.red,
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
// }


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../constants/constants.dart';
import '../../models/category/items_model.dart';
import '../../models/category/minisubcategory_model.dart';
import '../../models/order/modifier_model.dart';
import '../../models/order/order_items.dart';
import '../../models/sidebar/category_model_.dart';
import '../../repositories/minisubcategory_repository.dart';
import '../../repositories/modifier_repository.dart';
import '../../repositories/order_repository.dart';
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
  final String token;
  final String restaurantId;
  final bool isTakeAway;

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
    required this.token,
    required this.restaurantId,
    required this.isTakeAway,
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

  // ✅ NEW: Caches products per folder/subCategory id so switching between
  // tabs/folders does NOT re-fetch every time. This is `static` on purpose
  // (same reason as the modifier/variant caches above) — it needs to
  // survive `didUpdateWidget` resets and widget rebuilds where
  // `currentSubCategories` gets reassigned from fresh `widget.subCategories`
  // objects that don't carry the previously-fetched products with them.
  static final Map<int, List<Product>> _productCache = {};

  late OrderRepository orderRepository;
  bool _isCreatingTakeAwayOrder = false;
  final List<Color> tileColors = [
    const Color(0xFFF0FBFF),
    const Color(0xFFFEE8C2),
    const Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    currentSubCategories = widget.subCategories;
    orderRepository = OrderRepository(
      baseUrl: AppConstants.baseDomain,
    );
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

  Future<void> _initializeTakeAwayOrder() async {
    debugPrint("========== TAKEAWAY ORDER ==========");

    if (!widget.isTakeAway) {
      debugPrint("❌ Not a takeaway order. Skipping order creation.");
      return;
    }

    // Prevent duplicate API calls
    if (_isCreatingTakeAwayOrder) {
      debugPrint("⏳ Takeaway order creation already in progress");
      return;
    }

    final orderBloc = context.read<OrderBloc>();

    // Already created
    if ((orderBloc.state.orderId ?? 0) != 0) {
      debugPrint("✅ Takeaway order already exists.");
      return;
    }

    _isCreatingTakeAwayOrder = true;

    try {
      final response = await orderRepository.createTakeAwayOrder(
        restaurantId: widget.restaurantId,
        token: widget.token,
        orderDateTime: DateTime.now().toIso8601String(),
      );

      orderBloc.add(
        SetTakeAwayOrder(
          orderId: response.orderId,
          restaurantId: response.restaurantId.toString(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint("✅ Takeaway order created: ${response.orderId}");
    } catch (e, stackTrace) {
      debugPrint("❌ TakeAway Order Creation Failed");
      debugPrint("Error: $e");
      debugPrint(stackTrace.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to create takeaway order"),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Always release the lock
      _isCreatingTakeAwayOrder = false;
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
          backgroundColor: Colors.red,
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

  // ✅ Helper: apply veg/non-veg tagging based on folder name.
  List<Product> _applyVegTagging(String folderName, List<Product> products) {
    final name = folderName.toLowerCase();
    return products.map((p) {
      if (name.contains('non veg')) {
        return p.copyWith(isVeg: false);
      } else if (name.contains('veg')) {
        return p.copyWith(isVeg: true);
      }
      return p;
    }).toList();
  }

  Future<void> _autoSelectAndLoad() async {
    final folders = currentSubCategories.where((e) => e.isFolder).toList();

    if (folders.isNotEmpty) {
      selectedFolder = folders.first;
      widget.onFolderSelected?.call(selectedFolder!);

      // Products already attached to the folder object
      if (selectedFolder!.products.isNotEmpty) {
        // Keep cache in sync in case it wasn't populated yet
        _productCache[selectedFolder!.id] = selectedFolder!.products;
        if (mounted) {
          setState(() {}); // only one rebuild
        }
        return;
      }

      // ✅ Check the static cache before hitting the network
      final cached = _productCache[selectedFolder!.id];
      if (cached != null) {
        final newFolder = selectedFolder!.copyWith(
          products: cached,
          count: cached.length,
        );

        if (mounted) {
          setState(() {
            selectedFolder = newFolder;
            currentSubCategories = currentSubCategories.map((e) {
              return e.id == newFolder.id ? newFolder : e;
            }).toList();
          });
        }
        return;
      }

      // Only fetch if products are missing from both the folder and cache
      final products = await widget.fetchProducts(selectedFolder!.id);

      if (!mounted) return;

      final updatedProducts =
      _applyVegTagging(selectedFolder!.name, products);

      // ✅ Store in the static cache
      _productCache[selectedFolder!.id] = updatedProducts;

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

    // ✅ Check the static cache first
    final cached = _productCache[subCategoryId];
    if (cached != null) {
      setState(() {
        currentSubCategories = [
          MiniSubCategory(
            id: subCategoryId,
            name: "Direct Items",
            isFolder: false,
            products: cached,
            count: cached.length,
          )
        ];
      });
      return;
    }

    setState(() => isLoadingDirectProducts = true);

    try {
      final products = await widget.fetchProducts(subCategoryId);

      if (!mounted) return;

      // ✅ Store in the static cache
      _productCache[subCategoryId] = products;

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

    // ✅ If we already have cached products for this folder, use them
    // immediately — no loading state, no network call.
    final cached = _productCache[folder.id];
    if (cached != null && cached.isNotEmpty) {
      final newFolder = folder.copyWith(
        products: cached,
        count: cached.length,
      );

      setState(() {
        selectedFolder = newFolder;
        currentSubCategories = currentSubCategories.map((e) {
          return e.id == newFolder.id ? newFolder : e;
        }).toList();
      });

      widget.onFolderSelected?.call(newFolder);
      return;
    }

    // select the new folder
    setState(() {
      selectedFolder = folder;
    });

    widget.onFolderSelected?.call(folder);

    // if products already loaded on the folder object, no need to fetch again
    if (folder.products.isNotEmpty) {
      _productCache[folder.id] = folder.products;
      return;
    }

    try {
      final products = await widget.fetchProducts(folder.id);

      final updatedProducts = _applyVegTagging(folder.name, products);

      // ✅ Store in the static cache so next tap on this folder is instant
      _productCache[folder.id] = updatedProducts;

      final newFolder = folder.copyWith(
        products: updatedProducts,
        count: updatedProducts.length,
      );

      if (!mounted) return;

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
    if (_isCreatingTakeAwayOrder) return;

    if (widget.isTakeAway) {
      await _initializeTakeAwayOrder();
    }
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
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.only(
        left: 3,
        top: 3,
        right: 3,
        bottom: 4.5,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E0E0), width: 1), // Grid border
        borderRadius: BorderRadius.circular(12),
        color: const Color(0XFFFFFFFF),
        boxShadow: const [
          BoxShadow(color: Colors.white, blurRadius: 3, offset: Offset(0, 0)),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(6),
        children: [
          if (folders.isNotEmpty) ...[
            _buildFolderGrid(folders),
            const SizedBox(height: 10),
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
      height: 35,
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
              const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: isSelected
                  ? BoxDecoration(
                color: const Color(0xFFFF364C),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 10,
                    offset: Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
              )
                  : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFC4C7D1),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4F2B4D82),
                    blurRadius: 8,
                    offset: Offset(1, 1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // const Icon(Icons.folder, size: 20, color: Colors.black),
                  // const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      folder.name,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        color: selectedFolder?.id == folder.id
                            ? Colors.white
                            : const Color(0xFF4C5F7D),
                        height: 1.5,
                        letterSpacing: 0.6,
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

  // Widget _buildItemsGrid(List<Product> items) {
  //   const double stripWidth = 0;
  //   const double stripGap = 1;
  //
  //   return GridView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     itemCount: items.length,
  //     padding: const EdgeInsets.fromLTRB(1, 6, 2, 0),
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 4,
  //       mainAxisSpacing: 0,
  //       crossAxisSpacing: 8,
  //       childAspectRatio: 1.4,
  //     ),
  //     itemBuilder: (context, index) {
  //       final item = items[index];
  //       final backgroundColor = tileColors[index % tileColors.length];
  //
  //       return Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           // 🔹 PRODUCT CARD
  //           GestureDetector(
  //             onTap: () => _onItemTap(context, item),
  //             child: Container(
  //               height: 72,
  //               padding: const EdgeInsets.fromLTRB(
  //                 stripWidth + stripGap,
  //                 0,
  //                 0,
  //                 0,
  //               ),
  //               decoration: BoxDecoration(
  //                 color: backgroundColor,
  //                 borderRadius: BorderRadius.circular(10),
  //                 border: Border.all(color: Colors.grey.shade300, width: 2),
  //                 boxShadow: const [
  //                   BoxShadow(color: Colors.black12, blurRadius: 2),
  //                 ],
  //               ),
  //               child: Stack(
  //                 children: [
  //                   // CONTENT
  //                   Row(
  //                     children: [
  //                       const SizedBox(width: 8),
  //                       if (item.image.isNotEmpty)
  //                         ClipRRect(
  //                           borderRadius: BorderRadius.circular(8),
  //                           child: Image.network(
  //                             item.image,
  //                             width: 50,
  //                             height: 48,
  //                             fit: BoxFit.cover,
  //                             errorBuilder: (_, __, ___) =>
  //                             const Icon(Icons.fastfood, size: 40),
  //                           ),
  //                         )
  //                       else
  //                         const Icon(Icons.fastfood, size: 40),
  //
  //                       const SizedBox(width: 8),
  //
  //                       Expanded(
  //                         child: Column(
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(
  //                               item.name,
  //                               overflow: TextOverflow.ellipsis,
  //                               style: const TextStyle(
  //                                 fontSize: 12,
  //                                 fontWeight: FontWeight.w600,
  //                               ),
  //                             ),
  //                             const SizedBox(height: 4),
  //                             Text(
  //                               '₹${item.price.toStringAsFixed(0)}',
  //                               style: const TextStyle(
  //                                 fontSize: 12,
  //                                 fontWeight: FontWeight.w600,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //
  //                   // 🌱 VEG / NON-VEG STRIP
  //                   Positioned(
  //                     left: 0,
  //                     top: 0,
  //                     bottom: 0,
  //                     child: item.isVeg == null
  //                         ? const SizedBox.shrink()
  //                         : Container(
  //                       width: 3,
  //                       decoration: BoxDecoration(
  //                         color:
  //                         item.isVeg! ? Colors.green : Colors.red,
  //                         borderRadius: const BorderRadius.only(
  //                           topLeft: Radius.circular(10),
  //                           bottomLeft: Radius.circular(10),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //
  //                   // 🔹 VARIANT ICON
  //                   if (item.isVariantProduct)
  //                     Positioned(
  //                       top: 45,
  //                       right: 6,
  //                       child: Image.asset(
  //                         'assets/variant_icon.png',
  //                         width: 10,
  //                         height: 10,
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //
  //           // 🔥 VIEW MORE (ONLY FOR COMBO)
  //           if (isComboItem(item))
  //             Padding(
  //               padding: const EdgeInsets.only(top: 4),
  //               child: InkWell(
  //                 onTap: () => _openComboDetails(context, item),
  //                 child: const Text(
  //                   "View more",
  //                   style: TextStyle(
  //                     fontSize: 10,
  //                     fontWeight: FontWeight.w600,
  //                     decoration: TextDecoration.underline,
  //                     color: Color(0xFF191919),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //         ],
  //       );
  //     },
  //   );
  // }
  Widget _buildItemsGrid(List<Product> items) {
    const double stripWidth = 0;
    const double stripGap = 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      padding: const EdgeInsets.fromLTRB(1, 6, 5, 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 0,
        crossAxisSpacing: 8,
        childAspectRatio: 1.59,
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
                height: 105,
                padding: const EdgeInsets.fromLTRB(
                  stripWidth + stripGap,
                  0,
                  0,
                  0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0x7FC4C7D1),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 14,
                      offset: Offset(0, 1),
                    ),
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
                              width: 80,
                              height: 80,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${item.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 🌱 VEG / NON-VEG STRIP
                    Positioned(
                      top: 6,
                      right: 8,
                      child: item.isVeg == null
                          ? const SizedBox.shrink()
                          : Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 5,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: item.isVeg!
                                      ? const Color(0xFF34C759) // Veg
                                      : const Color(0xFFFF0404), // Non-Veg
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 🔹 VARIANT ICON
                    if (item.isVariantProduct)
                      Positioned(
                        top: 65,
                        right: 12,
                        child: Image.asset(
                          'assets/variant_icon.png',
                          width: 14,
                          height: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 🔥 VIEW MORE (ONLY FOR COMBO)
            if (isComboItem(item))
              Padding(
                padding: const EdgeInsets.only(top: 0),
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