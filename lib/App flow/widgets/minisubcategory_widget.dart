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
// import '../../utils/SessionManager.dart';
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
//
//   // ✅ NEW: Caches products per folder/subCategory id so switching between
//   // tabs/folders does NOT re-fetch every time. This is `static` on purpose
//   // (same reason as the modifier/variant caches above) — it needs to
//   // survive `didUpdateWidget` resets and widget rebuilds where
//   // `currentSubCategories` gets reassigned from fresh `widget.subCategories`
//   // objects that don't carry the previously-fetched products with them.
//   static final Map<int, List<Product>> _productCache = {};
//
//   late OrderRepository orderRepository;
//   bool _isCreatingTakeAwayOrder = false;
//   final List<Color> tileColors = [
//     const Color(0xFFF0FBFF),
//     const Color(0xFFFEE8C2),
//     const Color(0xFFFFFFFF),
//   ];
//   String _currency = "₹";
//   @override
//   void initState() {
//     super.initState();
//     currentSubCategories = widget.subCategories;
//     orderRepository = OrderRepository(
//       baseUrl: AppConstants.baseDomain,
//     );
//     _loadCurrency();   // <-- Add this
//     // Auto-select folder or fetch direct products after first frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _autoSelectAndLoad();
//     });
//   }
//   Future<void> _loadCurrency() async {
//     final currency = await SessionManager.getCurrencySymbol();
//
//     if (mounted) {
//       setState(() {
//         _currency = currency ?? "₹";
//       });
//     }
//   }
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
//
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
//         orderDateTime: DateTime.now().toIso8601String(),
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
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       // Always release the lock
//       _isCreatingTakeAwayOrder = false;
//     }
//   }
//
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
//           backgroundColor: Colors.red,
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
//   // ✅ Helper: apply veg/non-veg tagging based on folder name.
//   List<Product> _applyVegTagging(String folderName, List<Product> products) {
//     final name = folderName.toLowerCase();
//     return products.map((p) {
//       if (name.contains('non veg')) {
//         return p.copyWith(isVeg: false);
//       } else if (name.contains('veg')) {
//         return p.copyWith(isVeg: true);
//       }
//       return p;
//     }).toList();
//   }
//
//   Future<void> _autoSelectAndLoad() async {
//     final folders = currentSubCategories.where((e) => e.isFolder).toList();
//
//     if (folders.isNotEmpty) {
//       selectedFolder = folders.first;
//       widget.onFolderSelected?.call(selectedFolder!);
//
//       // Products already attached to the folder object
//       if (selectedFolder!.products.isNotEmpty) {
//         // Keep cache in sync in case it wasn't populated yet
//         _productCache[selectedFolder!.id] = selectedFolder!.products;
//         if (mounted) {
//           setState(() {}); // only one rebuild
//         }
//         return;
//       }
//
//       // ✅ Check the static cache before hitting the network
//       final cached = _productCache[selectedFolder!.id];
//       if (cached != null) {
//         final newFolder = selectedFolder!.copyWith(
//           products: cached,
//           count: cached.length,
//         );
//
//         if (mounted) {
//           setState(() {
//             selectedFolder = newFolder;
//             currentSubCategories = currentSubCategories.map((e) {
//               return e.id == newFolder.id ? newFolder : e;
//             }).toList();
//           });
//         }
//         return;
//       }
//
//       // Only fetch if products are missing from both the folder and cache
//       final products = await widget.fetchProducts(selectedFolder!.id);
//
//       if (!mounted) return;
//
//       final updatedProducts =
//       _applyVegTagging(selectedFolder!.name, products);
//
//       // ✅ Store in the static cache
//       _productCache[selectedFolder!.id] = updatedProducts;
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
//     // ✅ Check the static cache first
//     final cached = _productCache[subCategoryId];
//     if (cached != null) {
//       setState(() {
//         currentSubCategories = [
//           MiniSubCategory(
//             id: subCategoryId,
//             name: "Direct Items",
//             isFolder: false,
//             products: cached,
//             count: cached.length,
//           )
//         ];
//       });
//       return;
//     }
//
//     setState(() => isLoadingDirectProducts = true);
//
//     try {
//       final products = await widget.fetchProducts(subCategoryId);
//
//       if (!mounted) return;
//
//       // ✅ Store in the static cache
//       _productCache[subCategoryId] = products;
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
//     // ✅ If we already have cached products for this folder, use them
//     // immediately — no loading state, no network call.
//     final cached = _productCache[folder.id];
//     if (cached != null && cached.isNotEmpty) {
//       final newFolder = folder.copyWith(
//         products: cached,
//         count: cached.length,
//       );
//
//       setState(() {
//         selectedFolder = newFolder;
//         currentSubCategories = currentSubCategories.map((e) {
//           return e.id == newFolder.id ? newFolder : e;
//         }).toList();
//       });
//
//       widget.onFolderSelected?.call(newFolder);
//       return;
//     }
//
//     // select the new folder
//     setState(() {
//       selectedFolder = folder;
//     });
//
//     widget.onFolderSelected?.call(folder);
//
//     // if products already loaded on the folder object, no need to fetch again
//     if (folder.products.isNotEmpty) {
//       _productCache[folder.id] = folder.products;
//       return;
//     }
//
//     try {
//       final products = await widget.fetchProducts(folder.id);
//
//       final updatedProducts = _applyVegTagging(folder.name, products);
//
//       // ✅ Store in the static cache so next tap on this folder is instant
//       _productCache[folder.id] = updatedProducts;
//
//       final newFolder = folder.copyWith(
//         products: updatedProducts,
//         count: updatedProducts.length,
//       );
//
//       if (!mounted) return;
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
//       padding: const EdgeInsets.all(5),
//       margin: const EdgeInsets.only(
//         left: 3,
//         top: 3,
//         right: 3,
//         bottom: 4.5,
//       ),
//       decoration: BoxDecoration(
//         border: Border.all(color: Color(0xFFE0E0E0), width: 1), // Grid border
//         borderRadius: BorderRadius.circular(12),
//         color: const Color(0XFFFFFFFF),
//         boxShadow: const [
//           BoxShadow(color: Colors.white, blurRadius: 3, offset: Offset(0, 0)),
//         ],
//       ),
//       child: ListView(
//         padding: const EdgeInsets.all(6),
//         children: [
//           if (folders.isNotEmpty) ...[
//             _buildFolderGrid(folders),
//             const SizedBox(height: 10),
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
//       height: 35,
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
//               const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
//               decoration: isSelected
//                   ? BoxDecoration(
//                 color: const Color(0xFFFF364C),
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Color(0x19000000),
//                     blurRadius: 10,
//                     offset: Offset(0, 1),
//                     spreadRadius: 0,
//                   ),
//                 ],
//               )
//                   : BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: const Color(0xFFC4C7D1),
//                   width: 1,
//                 ),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Color(0x4F2B4D82),
//                     blurRadius: 8,
//                     offset: Offset(1, 1),
//                     spreadRadius: 0,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // const Icon(Icons.folder, size: 20, color: Colors.black),
//                   // const SizedBox(width: 6),
//                   Flexible(
//                     child: Text(
//                       folder.name,
//                       overflow: TextOverflow.ellipsis,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontFamily: 'Montserrat',
//                         fontWeight: FontWeight.w500,
//                         color: selectedFolder?.id == folder.id
//                             ? Colors.white
//                             : const Color(0xFF4C5F7D),
//                         height: 1.5,
//                         letterSpacing: 0.6,
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
//   // Widget _buildItemsGrid(List<Product> items) {
//   //   const double stripWidth = 0;
//   //   const double stripGap = 1;
//   //
//   //   return GridView.builder(
//   //     shrinkWrap: true,
//   //     physics: const NeverScrollableScrollPhysics(),
//   //     itemCount: items.length,
//   //     padding: const EdgeInsets.fromLTRB(1, 6, 2, 0),
//   //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//   //       crossAxisCount: 4,
//   //       mainAxisSpacing: 0,
//   //       crossAxisSpacing: 8,
//   //       childAspectRatio: 1.4,
//   //     ),
//   //     itemBuilder: (context, index) {
//   //       final item = items[index];
//   //       final backgroundColor = tileColors[index % tileColors.length];
//   //
//   //       return Column(
//   //         mainAxisSize: MainAxisSize.min,
//   //         children: [
//   //           // 🔹 PRODUCT CARD
//   //           GestureDetector(
//   //             onTap: () => _onItemTap(context, item),
//   //             child: Container(
//   //               height: 72,
//   //               padding: const EdgeInsets.fromLTRB(
//   //                 stripWidth + stripGap,
//   //                 0,
//   //                 0,
//   //                 0,
//   //               ),
//   //               decoration: BoxDecoration(
//   //                 color: backgroundColor,
//   //                 borderRadius: BorderRadius.circular(10),
//   //                 border: Border.all(color: Colors.grey.shade300, width: 2),
//   //                 boxShadow: const [
//   //                   BoxShadow(color: Colors.black12, blurRadius: 2),
//   //                 ],
//   //               ),
//   //               child: Stack(
//   //                 children: [
//   //                   // CONTENT
//   //                   Row(
//   //                     children: [
//   //                       const SizedBox(width: 8),
//   //                       if (item.image.isNotEmpty)
//   //                         ClipRRect(
//   //                           borderRadius: BorderRadius.circular(8),
//   //                           child: Image.network(
//   //                             item.image,
//   //                             width: 50,
//   //                             height: 48,
//   //                             fit: BoxFit.cover,
//   //                             errorBuilder: (_, __, ___) =>
//   //                             const Icon(Icons.fastfood, size: 40),
//   //                           ),
//   //                         )
//   //                       else
//   //                         const Icon(Icons.fastfood, size: 40),
//   //
//   //                       const SizedBox(width: 8),
//   //
//   //                       Expanded(
//   //                         child: Column(
//   //                           mainAxisAlignment: MainAxisAlignment.center,
//   //                           crossAxisAlignment: CrossAxisAlignment.start,
//   //                           children: [
//   //                             Text(
//   //                               item.name,
//   //                               overflow: TextOverflow.ellipsis,
//   //                               style: const TextStyle(
//   //                                 fontSize: 12,
//   //                                 fontWeight: FontWeight.w600,
//   //                               ),
//   //                             ),
//   //                             const SizedBox(height: 4),
//   //                             Text(
//   //                               '₹${item.price.toStringAsFixed(0)}',
//   //                               style: const TextStyle(
//   //                                 fontSize: 12,
//   //                                 fontWeight: FontWeight.w600,
//   //                               ),
//   //                             ),
//   //                           ],
//   //                         ),
//   //                       ),
//   //                     ],
//   //                   ),
//   //
//   //                   // 🌱 VEG / NON-VEG STRIP
//   //                   Positioned(
//   //                     left: 0,
//   //                     top: 0,
//   //                     bottom: 0,
//   //                     child: item.isVeg == null
//   //                         ? const SizedBox.shrink()
//   //                         : Container(
//   //                       width: 3,
//   //                       decoration: BoxDecoration(
//   //                         color:
//   //                         item.isVeg! ? Colors.green : Colors.red,
//   //                         borderRadius: const BorderRadius.only(
//   //                           topLeft: Radius.circular(10),
//   //                           bottomLeft: Radius.circular(10),
//   //                         ),
//   //                       ),
//   //                     ),
//   //                   ),
//   //
//   //                   // 🔹 VARIANT ICON
//   //                   if (item.isVariantProduct)
//   //                     Positioned(
//   //                       top: 45,
//   //                       right: 6,
//   //                       child: Image.asset(
//   //                         'assets/variant_icon.png',
//   //                         width: 10,
//   //                         height: 10,
//   //                       ),
//   //                     ),
//   //                 ],
//   //               ),
//   //             ),
//   //           ),
//   //
//   //           // 🔥 VIEW MORE (ONLY FOR COMBO)
//   //           if (isComboItem(item))
//   //             Padding(
//   //               padding: const EdgeInsets.only(top: 4),
//   //               child: InkWell(
//   //                 onTap: () => _openComboDetails(context, item),
//   //                 child: const Text(
//   //                   "View more",
//   //                   style: TextStyle(
//   //                     fontSize: 10,
//   //                     fontWeight: FontWeight.w600,
//   //                     decoration: TextDecoration.underline,
//   //                     color: Color(0xFF191919),
//   //                   ),
//   //                 ),
//   //               ),
//   //             ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }
//   Widget _buildItemsGrid(List<Product> items) {
//     const double stripWidth = 0;
//     const double stripGap = 1;
//
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: items.length,
//       padding: const EdgeInsets.fromLTRB(1, 6, 5, 0),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         mainAxisSpacing: 0,
//         crossAxisSpacing: 8,
//         childAspectRatio: 1.59,
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
//                 height: 105,
//                 padding: const EdgeInsets.fromLTRB(
//                   stripWidth + stripGap,
//                   0,
//                   0,
//                   0,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(
//                     color: const Color(0x7FC4C7D1),
//                   ),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Color(0x19000000),
//                       blurRadius: 14,
//                       offset: Offset(0, 1),
//                     ),
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
//                               width: 80,
//                               height: 80,
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
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                                 softWrap: true,
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 '$_currency${item.price.toStringAsFixed(2)}',
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w700,
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
//                       top: 6,
//                       right: 8,
//                       child: item.isVeg == null
//                           ? const SizedBox.shrink()
//                           : Container(
//                         width: 16,
//                         height: 16,
//                         decoration: const BoxDecoration(
//                           boxShadow: [
//                             BoxShadow(
//                               color: Color(0x3F000000),
//                               blurRadius: 5,
//                               offset: Offset(0, 1),
//                             ),
//                           ],
//                         ),
//                         child: Stack(
//                           children: [
//                             Container(
//                               width: 20,
//                               height: 20,
//                               decoration: ShapeDecoration(
//                                 color: Colors.white,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(2),
//                                 ),
//                               ),
//                             ),
//                             Positioned(
//                               left: 4,
//                               top: 4,
//                               child: Container(
//                                 width: 8,
//                                 height: 8,
//                                 decoration: BoxDecoration(
//                                   color: item.isVeg!
//                                       ? const Color(0xFF34C759) // Veg
//                                       : const Color(0xFFFF0404), // Non-Veg
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     // 🔹 VARIANT ICON
//                     if (item.isVariantProduct)
//                       Positioned(
//                         top: 65,
//                         right: 12,
//                         child: Image.asset(
//                           'assets/variant_icon.png',
//                           width: 14,
//                           height: 14,
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
//                 padding: const EdgeInsets.only(top: 0),
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



import 'package:cached_network_image/cached_network_image.dart';
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
import '../../utils/SessionManager.dart';
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
  // What's actually rendered right now. These only ever change once new
  // data is ready (instantly from cache, or silently after a background
  // fetch) — never cleared to show a spinner or a blank screen first.
  List<MiniSubCategory> currentSubCategories = [];
  MiniSubCategory? selectedFolder;

  // Request-id guards: every subcategory switch / folder tap bumps its
  // counter. A background fetch only applies its result if its id still
  // matches — so a slow response for a tab/folder the user already left
  // can never clobber what's currently on screen.
  int _subCategoryReqId = 0;
  int _folderReqId = 0;

  static final Map<int, List<Modifier>> _modifierCache = {};
  static final Map<int, List<Variant>> _variantCache = {};
  static final Map<int, List<Product>> _productCache = {};

  late OrderRepository orderRepository;
  bool _isCreatingTakeAwayOrder = false;
  final List<Color> tileColors = [
    const Color(0xFFF0FBFF),
    const Color(0xFFFEE8C2),
    const Color(0xFFFFFFFF),
  ];
  String _currency = "₹";

  @override
  void initState() {
    super.initState();
    currentSubCategories = widget.subCategories;
    orderRepository = OrderRepository(
      baseUrl: AppConstants.baseDomain,
    );
    _loadCurrency();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _switchSubCategory(widget.subCategories, widget.tappedSubCategoryId);
      }
    });
  }

  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }

  @override
  void didUpdateWidget(covariant MiniSubCategoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Subcategory tab changed -> switch content. Never spinner: instant if
    // cached, otherwise keep the current screen until the fetch resolves.
    if (oldWidget.tappedSubCategoryId != widget.tappedSubCategoryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _switchSubCategory(widget.subCategories, widget.tappedSubCategoryId);
        }
      });
    }
  }

// Replace the _initializeTakeAwayOrder method with this:

  Future<bool> _initializeTakeAwayOrder() async {
    debugPrint("========== TAKEAWAY ORDER ==========");

    if (!widget.isTakeAway) {
      debugPrint("❌ Not a takeaway order. Skipping order creation.");
      return false;
    }

    // Prevent duplicate API calls
    if (_isCreatingTakeAwayOrder) {
      debugPrint("⏳ Takeaway order creation already in progress");
      // Wait for the ongoing creation to complete
      int attempts = 0;
      while (_isCreatingTakeAwayOrder && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
      if (_isCreatingTakeAwayOrder) {
        debugPrint("❌ Timeout waiting for order creation");
        return false;
      }
      // Check if order was created successfully
      final orderBloc = context.read<OrderBloc>();
      return (orderBloc.state.orderId ?? 0) != 0;
    }

    final orderBloc = context.read<OrderBloc>();

    // Check if order already exists
    if ((orderBloc.state.orderId ?? 0) != 0) {
      debugPrint("✅ Takeaway order already exists. Order ID: ${orderBloc.state.orderId}");
      return true;
    }

    _isCreatingTakeAwayOrder = true;

    try {
      debugPrint("🔄 Creating takeaway order...");

      final response = await orderRepository.createTakeAwayOrder(
        restaurantId: widget.restaurantId,
        token: widget.token,
        orderDateTime: DateTime.now().toIso8601String(),
      );

      debugPrint("📦 Takeaway order response: ${response.orderId}");

      // Add the order to the bloc
      orderBloc.add(
        SetTakeAwayOrder(
          orderId: response.orderId,
          restaurantId: response.restaurantId.toString(),
        ),
      );

      // Wait for the bloc to update
      await Future.delayed(const Duration(milliseconds: 300));

      // Verify the order was set correctly
      final updatedState = orderBloc.state;
      debugPrint("✅ OrderBloc updated - Order ID: ${updatedState.orderId}");

      if (updatedState.orderId == 0) {
        throw Exception("Order ID was not set correctly");
      }

      debugPrint("✅ Takeaway order created and set: ${response.orderId}");
      return true;

    } catch (e, stackTrace) {
      debugPrint("❌ TakeAway Order Creation Failed");
      debugPrint("Error: $e");
      debugPrint(stackTrace.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to create takeaway order. Please try again."),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
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
                  comboItemsList(comboProduct),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  bool _sameProductIds(List<Product> a, List<Product> b) {
    final idsA = a.map((e) => e.id).toSet();
    final idsB = b.map((e) => e.id).toSet();
    return idsA.length == idsB.length && idsA.containsAll(idsB);
  }

  /// Warms the image disk-cache so tiles render instantly (and stay
  /// available offline) — same approach as the Home screen carousel/logo.
  void _precacheProductImages(List<Product> products) {
    if (!mounted) return;
    for (final p in products) {
      final img = p.image;
      if (img.isNotEmpty &&
          (img.startsWith('http://') || img.startsWith('https://'))) {
        precacheImage(CachedNetworkImageProvider(img), context);
      }
    }
  }

  /// Fire-and-forget: warms modifier/variant caches as soon as a folder's
  /// products are known, so tapping an item later is instant (cache hit)
  /// instead of waiting on two network calls.
  void _prefetchModifiersAndVariants(List<Product> products) {
    for (final item in products) {
      if (!_modifierCache.containsKey(item.id) &&
          widget.modifierRepository != null) {
        widget.modifierRepository!
            .fetchModifiersByProductId(item.id)
            .then((mods) => _modifierCache[item.id] = mods)
            .catchError((_) {});
      }
      if (!_variantCache.containsKey(item.id)) {
        widget.variantRepository
            .fetchVariantsByProduct(item.id)
            .then((vars) => _variantCache[item.id] = vars)
            .catchError((_) {});
      }
    }
  }

  // ---------------------------------------------------------------------
  // SUBCATEGORY TAB SWITCHING — no spinner, ever.
  // ---------------------------------------------------------------------

  /// Central entry point whenever the active subcategory tab changes.
  /// - If we already have data (attached to the folder object, or cached)
  ///   -> swap instantly, same frame, no spinner.
  /// - If not -> leave the current screen exactly as-is and fetch quietly;
  ///   the screen updates itself the moment data arrives.
  void _switchSubCategory(
      List<MiniSubCategory> newSubCategories, int subCategoryId) {
    final myReqId = ++_subCategoryReqId;

    final folders = newSubCategories.where((e) => e.isFolder).toList();

    if (folders.isNotEmpty) {
      final first = folders.first;
      final resolved =
      first.products.isNotEmpty ? first.products : _productCache[first.id];

      if (resolved != null) {
        // Instant — nothing to wait for.
        _productCache[first.id] = resolved;
        final resolvedFolder =
        first.copyWith(products: resolved, count: resolved.length);

        setState(() {
          currentSubCategories = newSubCategories
              .map((e) => e.id == resolvedFolder.id ? resolvedFolder : e)
              .toList();
          selectedFolder = resolvedFolder;
        });

        widget.onFolderSelected?.call(resolvedFolder);
        _precacheProductImages(resolved);
        _prefetchModifiersAndVariants(resolved);

        if (first.products.isEmpty) {
          // Served from cache — refresh quietly to pick up any changes.
          unawaited(_refreshFolderSilently(first, myReqId));
        }
      } else {
        // Nothing to show yet — keep current screen, swap in when ready.
        unawaited(_loadFolderForNewSubCategory(first, newSubCategories, myReqId));
      }
      return;
    }

    // No folders -> flat product list for this subcategory.
    final directItems = newSubCategories.where((e) => !e.isFolder).toList();
    final attached = directItems.expand((e) => e.products).toList();
    final cached = _productCache[subCategoryId];

    if (attached.isNotEmpty) {
      _productCache[subCategoryId] = attached;
      setState(() {
        currentSubCategories = newSubCategories;
        selectedFolder = null;
      });
      _precacheProductImages(attached);
      _prefetchModifiersAndVariants(attached);
      return;
    }

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
        selectedFolder = null;
      });
      _precacheProductImages(cached);
      _prefetchModifiersAndVariants(cached);
      unawaited(_refreshDirectProductsSilently(subCategoryId, myReqId));
      return;
    }

    // Nothing cached — keep current screen, fetch quietly, swap when ready.
    unawaited(_loadDirectProductsForNewSubCategory(subCategoryId, myReqId));
  }

  Future<void> _loadFolderForNewSubCategory(
      MiniSubCategory folder,
      List<MiniSubCategory> parentSubCategories,
      int reqId,
      ) async {
    try {
      final products = await widget.fetchProducts(folder.id);
      if (!mounted || reqId != _subCategoryReqId) return; // stale — user moved on

      final updated = _applyVegTagging(folder.name, products);
      _productCache[folder.id] = updated;
      final newFolder =
      folder.copyWith(products: updated, count: updated.length);

      setState(() {
        currentSubCategories = parentSubCategories
            .map((e) => e.id == newFolder.id ? newFolder : e)
            .toList();
        selectedFolder = newFolder;
      });

      widget.onFolderSelected?.call(newFolder);
      _precacheProductImages(updated);
      _prefetchModifiersAndVariants(updated);
    } catch (e) {
      debugPrint("[MiniSubCategoryWidget] Silent folder load failed: $e");
      // Offline/error — current screen stays exactly as it was.
    }
  }

  Future<void> _refreshFolderSilently(MiniSubCategory folder, int reqId) async {
    try {
      final products = await widget.fetchProducts(folder.id);
      if (!mounted || reqId != _subCategoryReqId) return;

      final updated = _applyVegTagging(folder.name, products);
      final cached = _productCache[folder.id];
      final changed = cached == null ||
          cached.length != updated.length ||
          !_sameProductIds(cached, updated);

      _productCache[folder.id] = updated;
      _precacheProductImages(updated);
      _prefetchModifiersAndVariants(updated);

      if (changed && selectedFolder?.id == folder.id) {
        final newFolder =
        folder.copyWith(products: updated, count: updated.length);
        setState(() {
          selectedFolder = newFolder;
          currentSubCategories = currentSubCategories
              .map((e) => e.id == newFolder.id ? newFolder : e)
              .toList();
        });
      }
    } catch (e) {
      debugPrint(
          "[MiniSubCategoryWidget] Silent folder refresh failed, keeping cache: $e");
    }
  }

  Future<void> _loadDirectProductsForNewSubCategory(
      int subCategoryId, int reqId) async {
    try {
      final products = await widget.fetchProducts(subCategoryId);
      if (!mounted || reqId != _subCategoryReqId) return;

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
        selectedFolder = null;
      });
      _precacheProductImages(products);
      _prefetchModifiersAndVariants(products);
    } catch (e) {
      debugPrint("[MiniSubCategoryWidget] Silent direct load failed: $e");
    }
  }

  Future<void> _refreshDirectProductsSilently(
      int subCategoryId, int reqId) async {
    try {
      final products = await widget.fetchProducts(subCategoryId);
      if (!mounted || reqId != _subCategoryReqId) return;

      final cached = _productCache[subCategoryId];
      final changed = cached == null ||
          cached.length != products.length ||
          !_sameProductIds(cached, products);

      _productCache[subCategoryId] = products;
      _precacheProductImages(products);
      _prefetchModifiersAndVariants(products);

      if (changed) {
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
      }
    } catch (e) {
      debugPrint(
          "[MiniSubCategoryWidget] Silent direct refresh failed, keeping cache: $e");
    }
  }

  // ---------------------------------------------------------------------
  // FOLDER CHIP SWITCHING (within the same subcategory) — no spinner.
  // ---------------------------------------------------------------------

  void _onFolderTap(MiniSubCategory folder) {
    // Same folder tapped again -> keep it selected, do nothing.
    if (selectedFolder?.id == folder.id) return;
    if (!mounted) return;

    final myReqId = ++_folderReqId;
    final resolved =
    folder.products.isNotEmpty ? folder.products : _productCache[folder.id];

    if (resolved != null) {
      // Instant swap — no spinner, no flicker.
      _productCache[folder.id] = resolved;
      final resolvedFolder =
      folder.copyWith(products: resolved, count: resolved.length);

      setState(() {
        selectedFolder = resolvedFolder;
        currentSubCategories = currentSubCategories
            .map((e) => e.id == resolvedFolder.id ? resolvedFolder : e)
            .toList();
      });

      widget.onFolderSelected?.call(resolvedFolder);
      _precacheProductImages(resolved);
      _prefetchModifiersAndVariants(resolved);

      if (folder.products.isEmpty) {
        unawaited(_refreshFolderTapSilently(folder, myReqId));
      }
      return;
    }

    // No cache yet — keep the current grid exactly as it is, no spinner;
    // swap in the moment this folder's products are fetched.
    widget.onFolderSelected?.call(folder);
    unawaited(_loadFolderTapSilently(folder, myReqId));
  }

  Future<void> _loadFolderTapSilently(MiniSubCategory folder, int reqId) async {
    try {
      final products = await widget.fetchProducts(folder.id);
      if (!mounted || reqId != _folderReqId) return; // user tapped elsewhere

      final updated = _applyVegTagging(folder.name, products);
      _productCache[folder.id] = updated;
      final newFolder =
      folder.copyWith(products: updated, count: updated.length);

      setState(() {
        selectedFolder = newFolder;
        currentSubCategories = currentSubCategories
            .map((e) => e.id == newFolder.id ? newFolder : e)
            .toList();
      });
      _precacheProductImages(updated);
      _prefetchModifiersAndVariants(updated);
    } catch (e) {
      debugPrint("[MiniSubCategoryWidget] Folder tap load failed: $e");
    }
  }

  Future<void> _refreshFolderTapSilently(
      MiniSubCategory folder, int reqId) async {
    try {
      final products = await widget.fetchProducts(folder.id);
      if (!mounted || reqId != _folderReqId) return;

      final updated = _applyVegTagging(folder.name, products);
      final cached = _productCache[folder.id];
      final changed = cached == null ||
          cached.length != updated.length ||
          !_sameProductIds(cached, updated);

      _productCache[folder.id] = updated;
      _precacheProductImages(updated);
      _prefetchModifiersAndVariants(updated);

      if (changed && selectedFolder?.id == folder.id) {
        final newFolder =
        folder.copyWith(products: updated, count: updated.length);
        setState(() {
          selectedFolder = newFolder;
          currentSubCategories = currentSubCategories
              .map((e) => e.id == newFolder.id ? newFolder : e)
              .toList();
        });
      }
    } catch (e) {
      debugPrint(
          "[MiniSubCategoryWidget] Folder tap refresh failed, keeping cache: $e");
    }
  }

  // ---------------------------------------------------------------------
  // ADD TO ORDER
  // ---------------------------------------------------------------------

  Future<List<Modifier>> _getModifiers(int productId) async {
    if (_modifierCache.containsKey(productId)) {
      return _modifierCache[productId]!;
    }
    if (widget.modifierRepository == null) return [];
    try {
      final mods =
      await widget.modifierRepository!.fetchModifiersByProductId(productId);
      _modifierCache[productId] = mods;
      return mods;
    } catch (_) {
      return [];
    }
  }

  Future<List<Variant>> _getVariants(int productId) async {
    if (_variantCache.containsKey(productId)) {
      return _variantCache[productId]!;
    }
    try {
      final vars =
      await widget.variantRepository.fetchVariantsByProduct(productId);
      _variantCache[productId] = vars;
      return vars;
    } catch (_) {
      return [];
    }
  }

  Future<void> _onItemTap(BuildContext context, Product item) async {
    if (_isCreatingTakeAwayOrder) return;

    // ✅ Wait for order creation to complete before proceeding
    if (widget.isTakeAway) {
      final orderCreated = await _initializeTakeAwayOrder();
      if (!orderCreated) {
        // Order creation failed, don't add item
        return;
      }
    }

    // ✅ Get the orderBloc after initialization
    final orderBloc = context.read<OrderBloc>();

    // ✅ Verify order ID exists for takeaway
    if (widget.isTakeAway && orderBloc.state.orderId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order not initialized. Please try again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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

    // ✅ Fetch modifiers + variants
    final results = await Future.wait([
      _getModifiers(item.id),
      _getVariants(item.id),
    ]);
    final modifiers = results[0] as List<Modifier>;
    final variants = results[1] as List<Variant>;

    final hasOptions = modifiers.isNotEmpty;

    debugPrint("Product: ${item.name}, Has Options: $hasOptions, "
        "Variants: ${variants.length}");

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
      // ✅ No orderId field - just remove it
    );

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
          debugPrint("[VariantPopup] Variant selected: ${variant.name}");
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
            hasOptions: hasOptions,
          );

          orderBloc.add(AddOrderItem(orderItem));

          debugPrint(
              "[VariantPopup] Added to order: ${orderItem.name} x${orderItem.quantity}");
        },
        section: section,
        orderBloc: orderBloc,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final folders = currentSubCategories.where((e) => e.isFolder).toList();
    final directItems =
    currentSubCategories.where((e) => !e.isFolder).toList();
    final folderItems = selectedFolder?.products ?? [];

    // NOTE: intentionally no loading/spinner branch here. Whatever is in
    // `currentSubCategories` / `selectedFolder` right now is exactly what
    // gets rendered — it only ever changes via the silent swap-in methods
    // above, never via a blocking spinner state.

    return Container(
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.only(
        left: 3,
        top: 3,
        right: 3,
        bottom: 4.5,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
          final isSelected = selectedFolder?.id == folder.id;

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
                  Flexible(
                    child: Text(
                      folder.name,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        color: isSelected
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
                            // ✅ CachedNetworkImage: disk-cached like the
                            // Home screen promo/logo images, so repeat
                            // loads are instant and survive offline.
                            child: CachedNetworkImage(
                              imageUrl: item.image,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 120),
                              memCacheWidth: 160,
                              placeholder: (_, __) => Container(
                                width: 80,
                                height: 80,
                                color: const Color(0xFFF2F2F2),
                              ),
                              errorWidget: (_, __, ___) =>
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
                                '$_currency${item.price.toStringAsFixed(2)}',
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
                                      ? const Color(0xFF34C759)
                                      : const Color(0xFFFF0404),
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

/// Small helper so background futures are clearly "fire and forget"
/// without triggering "unhandled future" lints.
void unawaited(Future<void> future) {}