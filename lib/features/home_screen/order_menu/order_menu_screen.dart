// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:restaurant_captain_app/features/home_screen/order_menu/widgets/category_tabs.dart';
// import 'package:restaurant_captain_app/features/home_screen/order_menu/widgets/product_list_view.dart';
// import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
// import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
// import '../../../constants/color_constants.dart';
// import '../../addons/addons_domin/addon_entity.dart';
// import '../../addons/addons_domin/fetch_addons_usecase.dart';
// import '../../kots_list/kots_list_bloc/kots_list_bloc.dart';
// import '../../kots_list/kots_list_bloc/kots_list_event.dart';
// import '../../kots_list/kots_list_bloc/kots_list_state.dart';
// import '../../search_products/search_screen.dart';
// import '../../variations/variations_domain/fetch_variations_usecase.dart';
// import '../../variations/variations_domain/variation_entity.dart';
// import '../All_tables_list/All_tables_list_bloc/all_tables_list_bloc.dart';
// import '../All_tables_list/All_tables_list_bloc/all_tables_list_event.dart';
// import '../Zones/Zones_bloc/zone_event.dart';
// import '../Zones/Zones_bloc/zones_bloc.dart';
// import '../cart_screen.dart';
// import '../create_order/create_order_data_layer/create_order_remote_data_source.dart';
// import 'bloc/category_bloc/category_bloc.dart';
// import 'bloc/category_bloc/category_event.dart';
// import 'bloc/category_bloc/category_state.dart';
// import 'entities/category_entity.dart';
// import 'entities/product_entity.dart';
// import 'widgets/product_card.dart' show isNonVegProduct;
//
// class CartItem {
//   final ProductEntity product;
//   final List<Map<String, dynamic>> addOns;
//   int quantity;
//
//   CartItem({required this.product, this.addOns = const [], this.quantity = 1});
//
//   String get key => '${product.id}_${addOns.map((a) => a['name']).join(',')}';
//
//   double get unitPrice =>
//       (double.tryParse(product.price ?? '0') ?? 0) +
//           addOns.fold<double>(0, (sum, a) => sum + (a['price'] as double));
//
//   double get totalPrice => unitPrice * quantity;
// }
//
// class OrderMenuScreen extends StatefulWidget {
//   final int orderId;
//   final String tableName;
//   final String orderType;
//   final int restaurantId;
//   final int zoneId;
//
//   const OrderMenuScreen({
//     Key? key,
//     required this.orderId,
//     required this.tableName,
//     required this.orderType,
//     required this.restaurantId,
//     required this.zoneId,
//   }) : super(key: key);
//
//   @override
//   State<OrderMenuScreen> createState() => _OrderMenuScreenState();
// }
//
// class _OrderMenuScreenState extends State<OrderMenuScreen> {
//   final Map<String, CartItem> _cartItems = {};
//   bool _isCancellingOrder = false;
//
//   final CreateOrderRemoteDataSource _orderDataSource =
//   CreateOrderRemoteDataSourceImpl();
//
//   bool _vegOnly = false;
//   bool _nonVegOnly = false;
//   String? _language;
//
//   int? _selectedSubcategoryId;
//   int? _lastCategoryIdForFilters;
//   bool _showAllSubcategories = false;
//   bool _hasKots = false;
//   late final StreamSubscription<KotsListState> _kotsSubscription;
//
//   final TextEditingController _searchController = TextEditingController();
//   String _currencySymbol = '';
//   final ValueNotifier<String> _currencySymbolNotifier = ValueNotifier<String>('');
//
//   @override
//   void initState() {
//     super.initState();
//     final bloc = context.read<CategoryBloc>();
//     if (bloc.state is CategoryInitial) {
//       bloc.add(LoadCategories());
//     }
//     _loadCurrencySymbol();
//
//     final kotsBloc = context.read<KotsListBloc>();
//     // initial check
//     if (kotsBloc.state is KotsListLoaded && (kotsBloc.state as KotsListLoaded).kots.isNotEmpty) {
//       _hasKots = true;
//     }
//     _kotsSubscription = kotsBloc.stream.listen((state) {
//       if (state is KotsListLoaded && mounted) {
//         setState(() {
//           _hasKots = state.kots.isNotEmpty;
//         });
//       }
//     });
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       kotsBloc.add(
//         FetchKotsList(
//           parentOrderId: widget.orderId,
//           restaurantId: widget.restaurantId,
//           zoneId: widget.zoneId,
//         ),
//       );
//     });
//   }
//
//   Future<void> _loadCurrencySymbol() async {
//     try {
//       final symbol = await context.read<CaptainLocalStorage>().getCurrencySymbol();
//       if (symbol != null && mounted) {
//         print('🪙 Currency symbol loaded: $symbol');
//         _currencySymbolNotifier.value = symbol;
//       } else {
//         print('🪙 Currency symbol not found, using default: ');
//       }
//     } catch (e) {
//       print('🪙 Error loading currency symbol: $e');
//     }
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//     _kotsSubscription.cancel(); // ← NEW
//   }
//
//   void _addToCartDirect(ProductEntity product) {
//     setState(() {
//       final key = '${product.id}_';
//       final existing = _cartItems[key];
//       if (existing != null) {
//         existing.quantity++;
//       } else {
//         _cartItems[key] = CartItem(product: product);
//       }
//     });
//   }
//
//   void _removeFromCart(ProductEntity product) {
//     setState(() {
//       final key = '${product.id}_';
//       final existing = _cartItems[key];
//       if (existing == null) return;
//       if (existing.quantity <= 1) {
//         _cartItems.remove(key);
//       } else {
//         existing.quantity--;
//       }
//     });
//   }
//
//   void _addVariantToCart(
//       ProductEntity product,
//       int quantity,
//       List<Map<String, dynamic>> selectedAddOns,
//       ) {
//     setState(() {
//       final item = CartItem(product: product, addOns: selectedAddOns, quantity: quantity);
//       final existing = _cartItems[item.key];
//       if (existing != null) {
//         existing.quantity += quantity;
//       } else {
//         _cartItems[item.key] = item;
//       }
//     });
//
//     if (selectedAddOns.isNotEmpty) {
//       debugPrint(
//         '[CART] Added "${product.name}" x$quantity with add-ons: '
//             '${selectedAddOns.map((a) => a['name']).join(', ')}',
//       );
//     } else {
//       debugPrint('[CART] Added "${product.name}" x$quantity (no add-ons)');
//     }
//   }
//
//
// //   Future<void> _showVariantAndAddOnSheet(ProductEntity product) async {
// //     try {
// //       final variationsFuture = context.read<FetchVariationsUseCase>()(product.id);
// //       final addOnsFuture = context.read<FetchAddOnsUseCase>()(product.id);
// //
// //       final results = await Future.wait([variationsFuture, addOnsFuture]);
// //       final variations = results[0] as List<VariationEntity>;
// //       final addOns = results[1] as List<AddOnEntity>;
// //
// //       if (variations.isEmpty) {
// //         if (addOns.isEmpty) {
// //           _addToCartDirect(product);
// //           return;
// //         } else {
// //           _showAddOnsOnlySheet(product, addOns);
// //           return;
// //         }
// //       }
// //
// //       int quantity = 1;
// //       VariationEntity? selectedVariation = variations.first;
// //       final selectedAddOns = <AddOnEntity>{};
// //       final nonVeg = isNonVegProduct(product);
// //
// //       showModalBottomSheet(
// //         context: context,
// //         isScrollControlled: true,
// //         shape: const RoundedRectangleBorder(
// //           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
// //         ),
// //         builder: (sheetContext) {
// //           return StatefulBuilder(
// //             builder: (context, setSheetState) {
// //               // ── Responsive scale (same reference size as ProductCard) ──
// //               final media = MediaQuery.of(context);
// //               const referenceWidth = 375.0;
// //               const referenceHeight = 812.0;
// //               final widthScale = media.size.width / referenceWidth;
// //               final heightScale = media.size.height / referenceHeight;
// //               final scale = widthScale < heightScale ? widthScale : heightScale;
// //               double s(double v) => v * scale;
// //
// //               final basePrice = double.tryParse(selectedVariation?.price ?? '0') ?? 0;
// //               final addOnsTotal = selectedAddOns.fold<double>(0, (sum, a) => sum + a.price);
// //               final total = (basePrice + addOnsTotal) * quantity;
// //
// //               return SingleChildScrollView(
// //                 padding: EdgeInsets.only(
// //                   left: s(20),
// //                   right: s(20),
// //                   top: s(16),
// //                   bottom: media.viewInsets.bottom + s(24),
// //                 ),
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     // ── Header: veg/non-veg dot + name + close ──
// //                     Row(
// //                       crossAxisAlignment: CrossAxisAlignment.center,
// //                       children: [
// //                         Container(
// //                           width: s(10),
// //                           height: s(10),
// //                           decoration: BoxDecoration(
// //                             shape: BoxShape.circle,
// //                             color: nonVeg ? Colors.red : Colors.green,
// //                           ),
// //                         ),
// //                         SizedBox(width: s(8)),
// //                         Expanded(
// //                           child: Text(
// //                             product.name,
// //                             style: TextStyle(fontSize: s(18), fontWeight: FontWeight.bold),
// //                             maxLines: 1,
// //                             overflow: TextOverflow.ellipsis,
// //                           ),
// //                         ),
// //                         GestureDetector(
// //                           onTap: () => Navigator.pop(sheetContext),
// //                           child: Container(
// //                             padding: EdgeInsets.all(s(4)),
// //                             decoration: const BoxDecoration(
// //                               shape: BoxShape.circle,
// //                               color: Color(0xFFFFEAEA),
// //                             ),
// //                             child: Icon(Icons.close, size: s(18), color: Colors.red),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                     SizedBox(height: s(16)),
// //
// //                     // ── Variations — 2-column card grid ──
// //                     GridView.builder(
// //                       shrinkWrap: true,
// //                       physics: const NeverScrollableScrollPhysics(),
// //                       itemCount: variations.length,
// //                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                         crossAxisCount: 2,
// //                         mainAxisSpacing: s(10),
// //                         crossAxisSpacing: s(10),
// //                         // Slightly taller on narrow screens so the price row
// //                         // and stepper never get squeezed/overflow.
// //                         childAspectRatio: media.size.width < 340 ? 1.8 : 2.2,
// //                       ),
// //                       itemBuilder: (context, index) {
// //                         final variant = variations[index];
// //                         final isSelected = selectedVariation?.variationId == variant.variationId;
// //
// //                         return GestureDetector(
// //                           onTap: () => setSheetState(() {
// //                             selectedVariation = variant;
// //                             if (!isSelected) quantity = 1;
// //                           }),
// //                           child: Container(
// //                             padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(10)),
// //                             decoration: BoxDecoration(
// //                               color: isSelected
// //                                   ? ColorConstants.primaryColor.withOpacity(0.06)
// //                                   : Colors.white,
// //                               borderRadius: BorderRadius.circular(s(10)),
// //                               border: Border.all(
// //                                 color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade300,
// //                                 width: isSelected ? s(1.4) : s(1),
// //                               ),
// //                             ),
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                               children: [
// //                                 Text(
// //                                   product.name,
// //                                   maxLines: 1,
// //                                   overflow: TextOverflow.ellipsis,
// //                                   style: TextStyle(fontSize: s(12), color: Colors.black87),
// //                                 ),
// //                                 Text(
// //                                   variant.name,
// //                                   maxLines: 1,
// //                                   overflow: TextOverflow.ellipsis,
// //                                   style: TextStyle(fontSize: s(13), fontWeight: FontWeight.w600),
// //                                 ),
// //                                 SizedBox(height: s(4)),
// //                                 Row(
// //                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                                   crossAxisAlignment: CrossAxisAlignment.center,
// //                                   children: [
// //                                     Flexible(
// //                                       child: Text(
// //                                         '\$${variant.price}',
// //                                         maxLines: 1,
// //                                         overflow: TextOverflow.ellipsis,
// //                                         style: TextStyle(
// //                                           color: ColorConstants.primaryColor,
// //                                           fontWeight: FontWeight.bold,
// //                                           fontSize: s(14),
// //                                         ),
// //                                       ),
// //                                     ),
// //                                     SizedBox(width: s(6)),
// //                                     isSelected
// //                                         ? _VariantStepper(
// //                                       quantity: quantity,
// //                                       scale: scale,
// //                                       onAdd: () => setSheetState(() => quantity++),
// //                                       onRemove: () => setSheetState(() {
// //                                         if (quantity > 1) quantity--;
// //                                       }),
// //                                     )
// //                                         : GestureDetector(
// //                                       behavior: HitTestBehavior.opaque,
// //                                       onTap: () => setSheetState(() {
// //                                         selectedVariation = variant;
// //                                         quantity = 1;
// //                                       }),
// //                                       child: Padding(
// //                                         // Extra invisible padding = bigger tap target
// //                                         // without visually enlarging the icon.
// //                                         padding: EdgeInsets.all(s(2)),
// //                                         child: Icon(
// //                                           Icons.add_circle,
// //                                           color: ColorConstants.primaryColor,
// //                                           size: s(22),
// //                                         ),
// //                                       ),
// //                                     ),
// //                                   ],
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //
// //                     // ── Modifiers ──
// //                     if (addOns.isNotEmpty) ...[
// //                       SizedBox(height: s(16)),
// //                       Row(
// //                         children: [
// //                           Text(
// //                             'Modifiers',
// //                             style: TextStyle(fontWeight: FontWeight.w600, fontSize: s(14)),
// //                           ),
// //                           SizedBox(width: s(8)),
// //                           const Expanded(child: Divider()),
// //                         ],
// //                       ),
// //                       ...addOns.map((addOn) {
// //                         final isChecked = selectedAddOns.contains(addOn);
// //                         return CheckboxListTile(
// //                           contentPadding: EdgeInsets.zero,
// //                           controlAffinity: ListTileControlAffinity.leading,
// //                           value: isChecked,
// //                           title: Text(addOn.name, style: TextStyle(fontSize: s(14))),
// //                           secondary: Text('+ \$${addOn.price.toStringAsFixed(2)}'),
// //                           onChanged: (checked) {
// //                             setSheetState(() {
// //                               if (checked == true) {
// //                                 selectedAddOns.add(addOn);
// //                               } else {
// //                                 selectedAddOns.remove(addOn);
// //                               }
// //                             });
// //                           },
// //                         );
// //                       }),
// //                     ],
// //
// //                     SizedBox(height: s(8)),
// //
// //                     // ── Add to Cart ──
// //                     SizedBox(
// //                       width: double.infinity,
// //                       child: ElevatedButton(
// //                         onPressed: () {
// //                           final selectedProduct = ProductEntity(
// //                             id: selectedVariation!.variationId,
// //                             name: '${product.name} - ${selectedVariation?.name}',
// //                             price: selectedVariation?.price,
// //                             inStock: selectedVariation?.inStock == 'Yes',
// //                           );
// //                           final selectedList = selectedAddOns
// //                               .map((a) => {'name': a.name, 'price': a.price})
// //                               .toList();
// //                           _addVariantToCart(selectedProduct, quantity, selectedList);
// //                           Navigator.pop(sheetContext);
// //                         },
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: ColorConstants.primaryColor,
// //                           foregroundColor: Colors.white,
// //                           padding: EdgeInsets.symmetric(vertical: s(14)),
// //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(s(8))),
// //                         ),
// //                         child: Row(
// //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                           children: [
// //                             Text(
// //                               'Add to Cart',
// //                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: s(15)),
// //                             ),
// //                             Text(
// //                               '\$${total.toStringAsFixed(2)}',
// //                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: s(15)),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             },
// //           );
// //         },
// //       );
// //     } catch (e) {
// //       _addToCartDirect(product);
// //     }
// //   }
// //
// // // Helper: show only add-ons sheet (when no variations)
// //   void _showAddOnsOnlySheet(ProductEntity product, List<AddOnEntity> addOns) {
// //     int quantity = 1;
// //     final selectedAddOns = <AddOnEntity>{};
// //     final basePrice = double.tryParse(product.price ?? '0') ?? 0;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
// //       ),
// //       builder: (sheetContext) {
// //         return StatefulBuilder(
// //           builder: (context, setSheetState) {
// //             final addOnsTotal = selectedAddOns.fold<double>(0, (sum, a) => sum + a.price);
// //             final total = (basePrice + addOnsTotal) * quantity;
// //
// //             return Padding(
// //               padding: EdgeInsets.only(
// //                 left: 20,
// //                 right: 20,
// //                 top: 20,
// //                 bottom: MediaQuery.of(context).viewInsets.bottom + 20,
// //               ),
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
// //                   const SizedBox(height: 8),
// //                   Text('\$${basePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
// //                   const SizedBox(height: 16),
// //                   const Text('Add Onssss', style: TextStyle(fontWeight: FontWeight.bold)),
// //                   const Divider(),
// //                   ...addOns.map((addOn) {
// //                     final isChecked = selectedAddOns.contains(addOn);
// //                     return CheckboxListTile(
// //                       contentPadding: EdgeInsets.zero,
// //                       controlAffinity: ListTileControlAffinity.leading,
// //                       value: isChecked,
// //                       title: Text(addOn.name),
// //                       secondary: Text('+ \$${addOn.price.toStringAsFixed(2)}'),
// //                       onChanged: (checked) {
// //                         setSheetState(() {
// //                           if (checked == true) {
// //                             selectedAddOns.add(addOn);
// //                           } else {
// //                             selectedAddOns.remove(addOn);
// //                           }
// //                         });
// //                       },
// //                     );
// //                   }),
// //                   const SizedBox(height: 8),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           const Text('Total Amount:', style: TextStyle(color: Colors.grey, fontSize: 12)),
// //                           Text(
// //                             '\$${total.toStringAsFixed(2)}',
// //                             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColorConstants.primaryColor),
// //                           ),
// //                         ],
// //                       ),
// //                       Row(
// //                         children: [
// //                           IconButton(
// //                             icon: const Icon(Icons.remove_circle_outline),
// //                             onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null,
// //                           ),
// //                           Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
// //                           IconButton(
// //                             icon: const Icon(Icons.add_circle, color: ColorConstants.primaryColor),
// //                             onPressed: () => setSheetState(() => quantity++),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 12),
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: ElevatedButton(
// //                       onPressed: () {
// //                         final selectedList = selectedAddOns.map((a) {
// //                           return {
// //                             'name': a.name,
// //                             'price': a.price,
// //                           };
// //                         }).toList();
// //                         _addVariantToCart(product, quantity, selectedList);
// //                         Navigator.pop(sheetContext);
// //                       },
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: ColorConstants.primaryColor,
// //                         foregroundColor: Colors.white,
// //                         padding: const EdgeInsets.symmetric(vertical: 14),
// //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// //                       ),
// //                       child: Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                         children: [
// //                           const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
// //                           Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// //   // ─── Unified add‑on sheet (called for both "+" and variant taps) ───
// //   Future<void> _showAddOnsSheet(ProductEntity product) async {
// //     final basePrice = double.tryParse(product.price ?? '0') ?? 0;
// //     final nonVeg = isNonVegProduct(product);
// //
// //     List<AddOnEntity> addOns = [];
// //     try {
// //       addOns = await context.read<FetchAddOnsUseCase>()(product.id);
// //     } catch (e) {
// //       _addToCartDirect(product);
// //       return;
// //     }
// //
// //     if (addOns.isEmpty) {
// //       _addToCartDirect(product);
// //       return;
// //     }
// //
// //     int quantity = 1;
// //     final selectedAddOns = <AddOnEntity>{};
// //
// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
// //       ),
// //       builder: (sheetContext) {
// //         return StatefulBuilder(
// //           builder: (context, setSheetState) {
// //             final addOnsTotal = selectedAddOns.fold<double>(0, (sum, a) => sum + a.price);
// //             final total = (basePrice + addOnsTotal) * quantity;
// //
// //             return SingleChildScrollView(
// //               padding: EdgeInsets.only(
// //                 left: 20,
// //                 right: 20,
// //                 top: 16,
// //                 bottom: MediaQuery.of(context).viewInsets.bottom + 24,
// //               ),
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   // ── Header ──
// //                   Row(
// //                     children: [
// //                       Container(
// //                         width: 10,
// //                         height: 10,
// //                         decoration: BoxDecoration(
// //                           shape: BoxShape.circle,
// //                           color: nonVeg ? Colors.red : Colors.green,
// //                         ),
// //                       ),
// //                       const SizedBox(width: 8),
// //                       Expanded(
// //                         child: Text(
// //                           product.name,
// //                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                           maxLines: 1,
// //                           overflow: TextOverflow.ellipsis,
// //                         ),
// //                       ),
// //                       GestureDetector(
// //                         onTap: () => Navigator.pop(sheetContext),
// //                         child: Container(
// //                           padding: const EdgeInsets.all(4),
// //                           decoration: const BoxDecoration(
// //                             shape: BoxShape.circle,
// //                             color: Color(0xFFFFEAEA),
// //                           ),
// //                           child: const Icon(Icons.close, size: 18, color: Colors.red),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 16),
// //
// //                   // ── Price & Stepper ──
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Text(
// //                         '\$${(basePrice + addOnsTotal).toStringAsFixed(2)}',
// //                         style: const TextStyle(
// //                           fontSize: 22,
// //                           fontWeight: FontWeight.bold,
// //                           color: ColorConstants.primaryColor,
// //                         ),
// //                       ),
// //                       _VariantStepper(
// //                         quantity: quantity,
// //                         onAdd: () => setSheetState(() => quantity++),
// //                         onRemove: () => setSheetState(() {
// //                           if (quantity > 1) quantity--;
// //                         }),
// //                       ),
// //                     ],
// //                   ),
// //
// //                   // ── Modifiers ──
// //                   if (addOns.isNotEmpty) ...[
// //                     const SizedBox(height: 16),
// //                     Row(
// //                       children: const [
// //                         Text('Modifiers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
// //                         SizedBox(width: 8),
// //                         Expanded(child: Divider()),
// //                       ],
// //                     ),
// //                     ...addOns.map((addOn) {
// //                       final isChecked = selectedAddOns.contains(addOn);
// //                       return CheckboxListTile(
// //                         contentPadding: EdgeInsets.zero,
// //                         controlAffinity: ListTileControlAffinity.leading,
// //                         dense: true,
// //                         value: isChecked,
// //                         title: Text(addOn.name, style: const TextStyle(fontSize: 14)),
// //                         secondary: Text('+ \$${addOn.price.toStringAsFixed(2)}'),
// //                         onChanged: (checked) {
// //                           setSheetState(() {
// //                             if (checked == true) {
// //                               selectedAddOns.add(addOn);
// //                             } else {
// //                               selectedAddOns.remove(addOn);
// //                             }
// //                           });
// //                         },
// //                       );
// //                     }),
// //                   ],
// //
// //                   const SizedBox(height: 8),
// //
// //                   // ── Add to Cart ──
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: ElevatedButton(
// //                       onPressed: () {
// //                         final selectedList = selectedAddOns
// //                             .map((a) => {'name': a.name, 'price': a.price})
// //                             .toList();
// //                         _addVariantToCart(product, quantity, selectedList);
// //                         Navigator.pop(sheetContext);
// //                       },
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: ColorConstants.primaryColor,
// //                         foregroundColor: Colors.white,
// //                         padding: const EdgeInsets.symmetric(vertical: 14),
// //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// //                       ),
// //                       child: Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                         children: [
// //                           const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
// //                           Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
//
//   Future<void> _showVariantAndAddOnSheet(ProductEntity product) async {
//     try {
//       final variationsFuture = context.read<FetchVariationsUseCase>()(product.id);
//       final addOnsFuture = context.read<FetchAddOnsUseCase>()(product.id);
//
//       final results = await Future.wait([variationsFuture, addOnsFuture]);
//       final variations = results[0] as List<VariationEntity>;
//       final addOns = results[1] as List<AddOnEntity>;
//
//       if (variations.isEmpty) {
//         if (addOns.isEmpty) {
//           _addToCartDirect(product);
//           return;
//         } else {
//           _showAddOnsOnlySheet(product, addOns);
//           return;
//         }
//       }
//
//       int quantity = 1;
//       VariationEntity? selectedVariation = variations.first;
//       final selectedAddOns = <AddOnEntity>{};
//       final nonVeg = isNonVegProduct(product);
//       final currencySymbol = _currencySymbolNotifier.value; // 👈 get symbol
//
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//         ),
//         builder: (sheetContext) {
//           return StatefulBuilder(
//             builder: (context, setSheetState) {
//               final media = MediaQuery.of(context);
//               const referenceWidth = 375.0;
//               const referenceHeight = 812.0;
//               final widthScale = media.size.width / referenceWidth;
//               final heightScale = media.size.height / referenceHeight;
//               final scale = widthScale < heightScale ? widthScale : heightScale;
//               double s(double v) => v * scale;
//
//               // Width of one grid cell, used so FittedBox knows how much
//               // horizontal room the card content actually has.
//               final gridHorizontalPadding = s(20) * 2;
//               final cellSpacing = s(10);
//               final cardOuterWidth =
//                   (media.size.width - gridHorizontalPadding - cellSpacing) / 2;
//               final cardContentWidth = cardOuterWidth - (s(12) * 2); // minus card's own horizontal padding
//
//               final basePrice = double.tryParse(selectedVariation?.price ?? '0') ?? 0;
//               final addOnsTotal = selectedAddOns.fold<double>(0, (sum, a) => sum + a.price);
//               final total = (basePrice + addOnsTotal) * quantity;
//
//               return SingleChildScrollView(
//                 padding: EdgeInsets.only(
//                   left: s(20),
//                   right: s(20),
//                   top: s(16),
//                   bottom: media.viewInsets.bottom + s(24),
//                 ),
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(
//                     minHeight: media.size.height * 0.55, // 👈 increased sheet height
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Container(
//                             width: s(10),
//                             height: s(10),
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: nonVeg ? Colors.red : Colors.green,
//                             ),
//                           ),
//                           SizedBox(width: s(8)),
//                           Expanded(
//                             child: Text(
//                               product.name,
//                               style: TextStyle(fontSize: s(18), fontWeight: FontWeight.bold),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           GestureDetector(
//                             onTap: () => Navigator.pop(sheetContext),
//                             child: Container(
//                               padding: EdgeInsets.all(s(4)),
//                               decoration: const BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: Color(0xFFFFEAEA),
//                               ),
//                               child: Icon(Icons.close, size: s(18), color: Colors.red),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: s(16)),
//
//                       // ── Variations ──
//                       GridView.builder(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         itemCount: variations.length,
//                         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 2,
//                           mainAxisSpacing: s(10),
//                           crossAxisSpacing: s(10),
//                           mainAxisExtent: s(118), // 👈 fixed card height — never overflows
//                         ),
//                         itemBuilder: (context, index) {
//                           final variant = variations[index];
//                           final isSelected = selectedVariation?.variationId == variant.variationId;
//
//                           return GestureDetector(
//                             onTap: () => setSheetState(() {
//                               selectedVariation = variant;
//                               if (!isSelected) quantity = 1;
//                             }),
//                             child: Container(
//                               padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(8)),
//                               decoration: BoxDecoration(
//                                 color: isSelected
//                                     ? ColorConstants.primaryColor.withOpacity(0.06)
//                                     : Colors.white,
//                                 borderRadius: BorderRadius.circular(s(10)),
//                                 border: Border.all(
//                                   color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade300,
//                                   width: isSelected ? s(1.4) : s(1),
//                                 ),
//                               ),
//                               // 👇 auto-shrinks content instead of overflowing,
//                               // no matter how large the device's font/text-scale is.
//                               child: FittedBox(
//                                 fit: BoxFit.scaleDown,
//                                 alignment: Alignment.topLeft,
//                                 child: SizedBox(
//                                   width: cardContentWidth,
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Text(
//                                         product.name,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: TextStyle(fontSize: s(11), color: Colors.grey.shade600),
//                                       ),
//                                       SizedBox(height: s(4)),
//                                       Row(
//                                         crossAxisAlignment: CrossAxisAlignment.center,
//                                         children: [
//                                           Expanded(
//                                             child: Text(
//                                               variant.name,
//                                               maxLines: 1,
//                                               overflow: TextOverflow.ellipsis,
//                                               style: TextStyle(fontSize: s(13), fontWeight: FontWeight.w600),
//                                             ),
//                                           ),
//                                           SizedBox(width: s(6)),
//                                           isSelected
//                                               ? _VariantStepper(
//                                             quantity: quantity,
//                                             scale: scale,
//                                             onAdd: () => setSheetState(() => quantity++),
//                                             onRemove: () => setSheetState(() {
//                                               if (quantity > 1) quantity--;
//                                             }),
//                                           )
//                                               : GestureDetector(
//                                             behavior: HitTestBehavior.opaque,
//                                             onTap: () => setSheetState(() {
//                                               selectedVariation = variant;
//                                               quantity = 1;
//                                             }),
//                                             child: Padding(
//                                               padding: EdgeInsets.all(s(2)),
//                                               child: Icon(
//                                                 Icons.add_circle,
//                                                 color: ColorConstants.primaryColor,
//                                                 size: s(22),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       SizedBox(height: s(6)),
//                                       Text(
//                                         '$currencySymbol${variant.price}', // 👈 dynamic symbol
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: TextStyle(
//                                           color: ColorConstants.primaryColor,
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: s(14),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//
//                       // ── Modifiers ──
//                       if (addOns.isNotEmpty) ...[
//                         SizedBox(height: s(16)),
//                         Row(
//                           children: [
//                             Text(
//                               'Modifiers',
//                               style: TextStyle(fontWeight: FontWeight.w600, fontSize: s(14)),
//                             ),
//                             SizedBox(width: s(8)),
//                             const Expanded(child: Divider()),
//                           ],
//                         ),
//                         ...addOns.map((addOn) {
//                           final isChecked = selectedAddOns.contains(addOn);
//                           return CheckboxListTile(
//                             contentPadding: EdgeInsets.zero,
//                             controlAffinity: ListTileControlAffinity.leading,
//                             value: isChecked,
//                             title: Text(addOn.name, style: TextStyle(fontSize: s(14))),
//                             secondary: Text(
//                               '+ $currencySymbol${addOn.price.toStringAsFixed(2)}', // 👈 dynamic
//                             ),
//                             onChanged: (checked) {
//                               setSheetState(() {
//                                 if (checked == true) {
//                                   selectedAddOns.add(addOn);
//                                 } else {
//                                   selectedAddOns.remove(addOn);
//                                 }
//                               });
//                             },
//                           );
//                         }),
//                       ],
//
//                       SizedBox(height: s(8)),
//
//                       // ── Add to Cart ──
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             final selectedProduct = ProductEntity(
//                               id: selectedVariation!.variationId,
//                               name: '${product.name} - ${selectedVariation?.name}',
//                               price: selectedVariation?.price,
//                               inStock: selectedVariation?.inStock == 'Yes',
//                             );
//                             final selectedList = selectedAddOns
//                                 .map((a) => {'name': a.name, 'price': a.price})
//                                 .toList();
//                             _addVariantToCart(selectedProduct, quantity, selectedList);
//                             Navigator.pop(sheetContext);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: ColorConstants.primaryColor,
//                             foregroundColor: Colors.white,
//                             padding: EdgeInsets.symmetric(vertical: s(14)),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(s(30))), // 👈 pill
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center, // 👈 centered
//                             children: [
//                               Text(
//                                 'Add to Cart',
//                                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: s(15)),
//                               ),
//                               SizedBox(width: s(12)),
//                               Container(width: s(1), height: s(18), color: Colors.white54), // 👈 divider
//                               SizedBox(width: s(12)),
//                               Text(
//                                 '$currencySymbol${total.toStringAsFixed(2)}', // 👈 dynamic
//                                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: s(15)),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       );
//     } catch (e) {
//       _addToCartDirect(product);
//     }
//   }
//
//   void _showAddOnsOnlySheet(ProductEntity product, List<AddOnEntity> addOns) {
//     int quantity = 1;
//     final selectedAddOns = <AddOnEntity>{};
//     final basePrice = double.tryParse(product.price ?? '0') ?? 0;
//     final currencySymbol = _currencySymbolNotifier.value;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (sheetContext) {
//         return StatefulBuilder(
//           builder: (context, setSheetState) {
//             final addOnsTotal = selectedAddOns.fold<double>(0, (sum, a) => sum + a.price);
//             final total = (basePrice + addOnsTotal) * quantity;
//
//             return Padding(
//               padding: EdgeInsets.only(
//                 left: 20,
//                 right: 20,
//                 top: 20,
//                 bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   Text(
//                     '$currencySymbol${basePrice.toStringAsFixed(2)}', // 👈 dynamic
//                     style: const TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text('Add Ons', style: TextStyle(fontWeight: FontWeight.bold)),
//                   const Divider(),
//                   ...addOns.map((addOn) {
//                     final isChecked = selectedAddOns.contains(addOn);
//                     return CheckboxListTile(
//                       contentPadding: EdgeInsets.zero,
//                       controlAffinity: ListTileControlAffinity.leading,
//                       value: isChecked,
//                       title: Text(addOn.name),
//                       secondary: Text(
//                         '+ $currencySymbol${addOn.price.toStringAsFixed(2)}', // 👈 dynamic
//                       ),
//                       onChanged: (checked) {
//                         setSheetState(() {
//                           if (checked == true) {
//                             selectedAddOns.add(addOn);
//                           } else {
//                             selectedAddOns.remove(addOn);
//                           }
//                         });
//                       },
//                     );
//                   }),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text('Total Amount:', style: TextStyle(color: Colors.grey, fontSize: 12)),
//                           Text(
//                             '$currencySymbol${total.toStringAsFixed(2)}', // 👈 dynamic
//                             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColorConstants.primaryColor),
//                           ),
//                         ],
//                       ),
//                       Row(
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.remove_circle_outline),
//                             onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null,
//                           ),
//                           Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                           IconButton(
//                             icon: const Icon(Icons.add_circle, color: ColorConstants.primaryColor),
//                             onPressed: () => setSheetState(() => quantity++),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         final selectedList = selectedAddOns.map((a) {
//                           return {
//                             'name': a.name,
//                             'price': a.price,
//                           };
//                         }).toList();
//                         _addVariantToCart(product, quantity, selectedList);
//                         Navigator.pop(sheetContext);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: ColorConstants.primaryColor,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // 👈 pill
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center, // 👈 centered
//                         children: [
//                           const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
//                           const SizedBox(width: 12),
//                           Container(width: 1, height: 18, color: Colors.white54), // 👈 divider
//                           const SizedBox(width: 12),
//                           Text(
//                             '$currencySymbol${total.toStringAsFixed(2)}', // 👈 dynamic
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> _showAddOnsSheet(ProductEntity product) async {
//     final basePrice = double.tryParse(product.price ?? '0') ?? 0;
//     final nonVeg = isNonVegProduct(product);
//     final currencySymbol = _currencySymbolNotifier.value;
//
//     List<AddOnEntity> addOns = [];
//     try {
//       addOns = await context.read<FetchAddOnsUseCase>()(product.id);
//     } catch (e) {
//       _addToCartDirect(product);
//       return;
//     }
//
//     if (addOns.isEmpty) {
//       _addToCartDirect(product);
//       return;
//     }
//
//     int quantity = 1;
//     final selectedAddOns = <AddOnEntity>{};
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (sheetContext) {
//         return StatefulBuilder(
//           builder: (context, setSheetState) {
//             final addOnsTotal = selectedAddOns.fold<double>(0, (sum, a) => sum + a.price);
//             final total = (basePrice + addOnsTotal) * quantity;
//
//             return SingleChildScrollView(
//               padding: EdgeInsets.only(
//                 left: 20,
//                 right: 20,
//                 top: 16,
//                 bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // ── Header ──
//                   Row(
//                     children: [
//                       Container(
//                         width: 10,
//                         height: 10,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: nonVeg ? Colors.red : Colors.green,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           product.name,
//                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () => Navigator.pop(sheetContext),
//                         child: Container(
//                           padding: const EdgeInsets.all(4),
//                           decoration: const BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Color(0xFFFFEAEA),
//                           ),
//                           child: const Icon(Icons.close, size: 18, color: Colors.red),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   // ── Price & Stepper ──
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '$currencySymbol${(basePrice + addOnsTotal).toStringAsFixed(2)}', // 👈 dynamic
//                         style: const TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: ColorConstants.primaryColor,
//                         ),
//                       ),
//                       _VariantStepper(
//                         quantity: quantity,
//                         onAdd: () => setSheetState(() => quantity++),
//                         onRemove: () => setSheetState(() {
//                           if (quantity > 1) quantity--;
//                         }),
//                       ),
//                     ],
//                   ),
//
//                   // ── Modifiers ──
//                   if (addOns.isNotEmpty) ...[
//                     const SizedBox(height: 16),
//                     Row(
//                       children: const [
//                         Text('Modifiers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
//                         SizedBox(width: 8),
//                         Expanded(child: Divider()),
//                       ],
//                     ),
//                     ...addOns.map((addOn) {
//                       final isChecked = selectedAddOns.contains(addOn);
//                       return CheckboxListTile(
//                         contentPadding: EdgeInsets.zero,
//                         controlAffinity: ListTileControlAffinity.leading,
//                         dense: true,
//                         value: isChecked,
//                         title: Text(addOn.name, style: const TextStyle(fontSize: 14)),
//                         secondary: Text(
//                           '+ $currencySymbol${addOn.price.toStringAsFixed(2)}', // 👈 dynamic
//                         ),
//                         onChanged: (checked) {
//                           setSheetState(() {
//                             if (checked == true) {
//                               selectedAddOns.add(addOn);
//                             } else {
//                               selectedAddOns.remove(addOn);
//                             }
//                           });
//                         },
//                       );
//                     }),
//                   ],
//
//                   const SizedBox(height: 8),
//
//                   // ── Add to Cart ──
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         final selectedList = selectedAddOns
//                             .map((a) => {'name': a.name, 'price': a.price})
//                             .toList();
//                         _addVariantToCart(product, quantity, selectedList);
//                         Navigator.pop(sheetContext);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: ColorConstants.primaryColor,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // 👈 pill
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center, // 👈 centered
//                         children: [
//                           const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
//                           const SizedBox(width: 12),
//                           Container(width: 1, height: 18, color: Colors.white54), // 👈 divider
//                           const SizedBox(width: 12),
//                           Text(
//                             '$currencySymbol${total.toStringAsFixed(2)}', // 👈 dynamic
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   void _incrementCartItem(CartItem item) {
//     setState(() => item.quantity++);
//   }
//
//   void _decrementCartItem(CartItem item) {
//     setState(() {
//       if (item.quantity <= 1) {
//         _cartItems.remove(item.key);
//       } else {
//         item.quantity--;
//       }
//     });
//   }
//
//   void _clearCart() {
//     setState(() => _cartItems.clear());
//   }
//
//   Map<int, int> get _cartQuantitiesByProductId {
//     final map = <int, int>{};
//     for (final item in _cartItems.values) {
//       map[item.product.id] = (map[item.product.id] ?? 0) + item.quantity;
//     }
//     return map;
//   }
//
//   int get _totalItems => _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
//   double get _totalPrice => _cartItems.values.fold(0.0, (sum, item) => sum + item.totalPrice);
//
//   // Future<void> _cancelOrder() async {
//   //   setState(() => _isCancellingOrder = true);
//   //   try {
//   //     final merchantStorage = context.read<MerchantLocalStorage>();
//   //     final captainStorage = context.read<CaptainLocalStorage>();
//   //
//   //     final baseUrl = await merchantStorage.getStoreBaseUrl();
//   //     if (baseUrl == null || baseUrl.isEmpty) {
//   //       throw Exception('Store base URL not found. Please login again.');
//   //     }
//   //
//   //     final captainData = await captainStorage.getCaptainData();
//   //     final token = captainData?.data?.token;
//   //     if (token == null || token.isEmpty) {
//   //       throw Exception('Captain token not found. Please login again.');
//   //     }
//   //
//   //     final result = await _orderDataSource.cancelOrder(
//   //       baseUrl: baseUrl,
//   //       token: token,
//   //       parentOrderId: widget.orderId,
//   //       restaurantId: widget.restaurantId,
//   //       zoneId: widget.zoneId,
//   //     );
//   //
//   //     if (!mounted) return;
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text('Order cancelled successfully')),
//   //     );
//   //     Navigator.of(context).popUntil((route) => route.isFirst);
//   //   } catch (e) {
//   //     if (!mounted) return;
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Failed to cancel order: ${e.toString()}')),
//   //     );
//   //   } finally {
//   //     if (mounted) setState(() => _isCancellingOrder = false);
//   //   }
//   // }
//
//   Future<void> _cancelOrder() async {
//     setState(() => _isCancellingOrder = true);
//     try {
//       final merchantStorage = context.read<MerchantLocalStorage>();
//       final captainStorage = context.read<CaptainLocalStorage>();
//
//       final baseUrl = await merchantStorage.getStoreBaseUrl();
//       if (baseUrl == null || baseUrl.isEmpty) {
//         throw Exception('Store base URL not found. Please login again.');
//       }
//
//       final captainData = await captainStorage.getCaptainData();
//       final token = captainData?.data?.token;
//       if (token == null || token.isEmpty) {
//         throw Exception('Captain token not found. Please login again.');
//       }
//
//       final result = await _orderDataSource.cancelOrder(
//         baseUrl: baseUrl,
//         token: token,
//         parentOrderId: widget.orderId,
//         restaurantId: widget.restaurantId,
//         zoneId: widget.zoneId,
//       );
//
//       if (!mounted) return;
//
//       // ─── ✅ Refresh tables & zones instantly ──────────────
//       context.read<AllTablesBloc>().add(FetchAllTables());
//       context.read<ZoneBloc>().add(FetchZones());
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Order cancelled successfully')),
//       );
//
//       // Go back to the table management screen
//       Navigator.of(context).popUntil((route) => route.isFirst);
//
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to cancel order: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) setState(() => _isCancellingOrder = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         elevation: 0.5,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Create Order', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
//       ),
//       body: Column(
//         children: [
//           _buildOrderInfoRow(),
//           _buildSearchBar(),
//           _buildCategoriesLabelRow(),
//           BlocBuilder<CategoryBloc, CategoryState>(
//             builder: (context, state) {
//               if (state is CategoryLoaded) {
//                 return CategoryTabs(
//                   categories: state.categories,
//                   selectedId: state.selectedCategoryId,
//                   onTabSelected: (id) {
//                     context.read<CategoryBloc>().add(SelectCategory(categoryId: id));
//                   },
//                 );
//               }
//               return const SizedBox.shrink();
//             },
//           ),
//           BlocBuilder<CategoryBloc, CategoryState>(
//             builder: (context, state) {
//               if (state is CategoryLoaded) {
//                 final selected = state.categories.where((c) => c.id == state.selectedCategoryId).toList();
//                 final title = selected.isNotEmpty ? selected.first.name : '';
//                 final languages = state.availableLanguages;
//
//                 if (_lastCategoryIdForFilters != state.selectedCategoryId) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     if (!mounted) return;
//                     setState(() {
//                       _lastCategoryIdForFilters = state.selectedCategoryId;
//                       _selectedSubcategoryId = null;
//                       _language = languages.isNotEmpty ? languages.first : null;
//                     });
//                   });
//                 } else if (languages.isNotEmpty &&
//                     (_language == null || !languages.contains(_language))) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     if (mounted) setState(() => _language = languages.first);
//                   });
//                 }
//
//                 return _buildCategoryHeaderBlock(title, state.subcategories, languages);
//               }
//               return const SizedBox.shrink();
//             },
//           ),
//           Expanded(
//             child: BlocBuilder<CategoryBloc, CategoryState>(
//               builder: (context, state) {
//                 if (state is CategoryLoading) {
//                   return const Center(child: CupertinoActivityIndicator(radius: 14));
//                 } else if (state is CategoryLoaded) {
//                   return ValueListenableBuilder<String>(
//                     valueListenable: _currencySymbolNotifier,
//                     builder: (context, symbol, _) {
//                       return ProductListView(
//                         subcategories: state.subcategories,
//                         directProducts: state.directProducts,
//                         subcategoryProducts: state.subcategoryProducts,
//                         miniSubcategoriesMap: state.miniSubcategoriesMap,
//                         cartQuantitiesByProductId: _cartQuantitiesByProductId,
//                         selectedLanguage: _language,
//                         selectedSubcategoryId: _selectedSubcategoryId,
//                         vegOnly: _vegOnly,
//                         nonVegOnly: _nonVegOnly,
//                         onAdd: _showAddOnsSheet,
//                         onRemove: _removeFromCart,
//                         onVariantTap: _showVariantAndAddOnSheet,
//                         onVisibleSubcategoryChanged: (subId) {
//                           if (_selectedSubcategoryId != subId) {
//                             setState(() => _selectedSubcategoryId = subId);
//                           }
//                         },
//                         currencySymbol: symbol, // 👈 use symbol from notifier
//                       );
//                     },
//                   );
//                 } else if (state is CategoryError) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(state.message),
//                         ElevatedButton(
//                           onPressed: () => context.read<CategoryBloc>().add(LoadCategories()),
//                           child: const Text('Retry'),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//           ),
//           _buildCartBar(),
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildOrderInfoRow() {
//     return Container(
//       width: double.infinity,
//       color: Colors.white,
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
//       child: Row(
//         children: [
//           Expanded(child: _orderInfoCard()),
//           const SizedBox(width: 8),
//           _cancelOrderChip(),
//         ],
//       ),
//     );
//   }
//
//   Widget _orderInfoCard() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFEAF3FF),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: const Color(0xFFB9D9FF)),
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             Text(
//               'Order Id #${widget.orderId}',
//               style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
//             ),
//             _infoDivider(),
//             Text(
//               'Table No ${widget.tableName}',
//               style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
//             ),
//             _infoDivider(),
//             Text(
//               widget.orderType,
//               style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _infoDivider() {
//     return Container(
//       height: 14,
//       width: 1,
//       margin: const EdgeInsets.symmetric(horizontal: 10),
//       color: const Color(0xFFB9D9FF),
//     );
//   }
//
//   Widget _cancelOrderChip() {
//
//     final bool canCancel = !_hasKots && !_isCancellingOrder;
//     return GestureDetector(
//       onTap: canCancel ? () => _showCancelDialog(context) : null,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: canCancel ? Colors.red : Colors.grey),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.delete_outline,
//               size: 14,
//               color: canCancel ? Colors.red : Colors.grey,
//             ),
//             const SizedBox(width: 4),
//             Text(
//               'Cancel Order',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: canCancel ? Colors.red : Colors.grey,
//                 fontWeight: FontWeight.w600,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               softWrap: false,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     final size = MediaQuery.of(context).size;
//
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => SearchScreen(
//               onAddToCart: _showAddOnsSheet,
//             ),
//           ),
//         );
//       },
//       child: Container(
//         color: Colors.white,
//         padding: EdgeInsets.fromLTRB(
//           size.width * 0.034,   // left
//           size.height * 0.001,  // top
//           size.width * 0.034,   // right
//           size.height * 0.008,  // bottom
//         ),
//         child: Container(
//           width: double.infinity,
//           height: size.height * 0.045,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF5F5F5),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: Colors.grey.shade300,
//               width: 1,
//             ),
//           ),
//           child: Row(
//             children: [
//               SizedBox(width: size.width * 0.035),
//               Icon(
//                 Icons.search,
//                 color: const Color(0xFF9E9E9E),
//                 size: size.width * 0.055,
//               ),
//               SizedBox(width: size.width * 0.025),
//               Text(
//                 'Search...',
//                 style: TextStyle(
//                   color: const Color(0xFF9E9E9E),
//                   fontSize: size.width * 0.038,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCategoriesLabelRow() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//           Row(
//             children: [
//               _dietChip(
//                 label: 'Veg',
//                 color: Colors.green,
//                 selected: _vegOnly,
//                 onTap: () => setState(() {
//                   _vegOnly = !_vegOnly;
//                   if (_vegOnly) _nonVegOnly = false;
//                 }),
//               ),
//               const SizedBox(width: 8),
//               _dietChip(
//                 label: 'Non Veg',
//                 color: Colors.red,
//                 selected: _nonVegOnly,
//                 onTap: () => setState(() {
//                   _nonVegOnly = !_nonVegOnly;
//                   if (_nonVegOnly) _vegOnly = false;
//                 }),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _dietChip({
//     required String label,
//     required Color color,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         decoration: BoxDecoration(
//           color: selected ? color.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: color),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.circle, size: 8, color: color),
//             const SizedBox(width: 4),
//             Text(label, style: TextStyle(fontSize: 11, color: color)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCategoryHeaderBlock(
//       String title,
//       List<SubcategoryEntity> subcategories,
//       List<String> languages,
//       ) {
//     return Container(
//       color: const Color(0xFFF5F5F5),
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//           if (subcategories.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             _buildSubcategoryChipsRow(subcategories),
//           ],
//           if (languages.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             // 👇 Make languages horizontally scrollable
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: languages.map(_languageOption).toList(),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   static const double _maxVisibleSubcategoryChips = 3.5;
//
//
//   Widget _buildSubcategoryChipsRow(List<SubcategoryEntity> subcategories) {
//     final validSubs = subcategories.where((s) => s.name.trim().isNotEmpty).toList();
//     final hasOverflow = validSubs.length > _maxVisibleSubcategoryChips;
//
//     final List<SubcategoryEntity> displayedSubs;
//     bool showMoreChip = false;
//     bool showLessChip = false;
//
//     if (_showAllSubcategories) {
//       displayedSubs = validSubs;
//       showLessChip = hasOverflow;
//     } else {
//       displayedSubs = hasOverflow ? validSubs.sublist(0, 4) : validSubs;
//       showMoreChip = hasOverflow;
//     }
//
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             for (int i = 0; i < displayedSubs.length; i++) ...[
//               if (i > 0) const SizedBox(width: 8), // 👈 no gap before the first chip
//               _subcategoryChip(
//                 label: displayedSubs[i].name,
//                 selected: _selectedSubcategoryId == displayedSubs[i].id,
//                 onTap: () => setState(() {
//                   _selectedSubcategoryId =
//                   (_selectedSubcategoryId == displayedSubs[i].id)
//                       ? null
//                       : displayedSubs[i].id;
//                 }),
//               ),
//             ],
//             if (showMoreChip) ...[
//               if (displayedSubs.isNotEmpty) const SizedBox(width: 8),
//               _toggleChip(
//                 label: 'More',
//                 isActive: false,
//                 onTap: () => setState(() => _showAllSubcategories = true),
//               ),
//             ],
//             if (showLessChip) ...[
//               if (displayedSubs.isNotEmpty) const SizedBox(width: 8),
//               _toggleChip(
//                 label: 'Less',
//                 isActive: true,
//                 onTap: () => setState(() => _showAllSubcategories = false),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _toggleChip({
//     required String label,
//     required bool isActive,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//         decoration: BoxDecoration(
//           color: isActive ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(
//             color: isActive ? ColorConstants.primaryColor : Colors.grey.shade300,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: isActive ? ColorConstants.primaryColor : Colors.black87,
//                 fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//             if (isActive) ...[
//               const SizedBox(width: 2),
//               Icon(
//                 Icons.keyboard_arrow_up,
//                 size: 14,
//                 color: ColorConstants.primaryColor,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _subcategoryChip({
//     required String label,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: selected ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(color: selected ? ColorConstants.primaryColor : Colors.grey.shade300),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: selected ? ColorConstants.primaryColor : Colors.black87,
//             fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
//           ),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           softWrap: false,
//         ),
//       ),
//     );
//   }
//
//   Widget _moreChip(List<SubcategoryEntity> overflow) {
//     final isOverflowSelected = _selectedSubcategoryId != null &&
//         overflow.any((s) => s.id == _selectedSubcategoryId);
//
//     return GestureDetector(
//       onTap: () => _showMoreSubcategoriesSheet(overflow),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//         decoration: BoxDecoration(
//           color: isOverflowSelected ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(
//             color: isOverflowSelected ? ColorConstants.primaryColor : Colors.grey.shade300,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'More',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: isOverflowSelected ? ColorConstants.primaryColor : Colors.black87,
//                 fontWeight: isOverflowSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//             Icon(
//               Icons.keyboard_arrow_down,
//               size: 14,
//               color: isOverflowSelected ? ColorConstants.primaryColor : Colors.black54,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showMoreSubcategoriesSheet(List<SubcategoryEntity> overflow) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (sheetContext) {
//         return SafeArea(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               maxHeight: MediaQuery.of(context).size.height * 0.5,
//             ),
//             child: ListView(
//               shrinkWrap: true,
//               children: overflow
//                   .map((sub) => ListTile(
//                 title: Text(sub.name),
//                 trailing: _selectedSubcategoryId == sub.id
//                     ? const Icon(Icons.check, color: ColorConstants.primaryColor)
//                     : null,
//                 onTap: () {
//                   setState(() => _selectedSubcategoryId = sub.id);
//                   Navigator.pop(sheetContext);
//                 },
//               ))
//                   .toList(),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
//   Widget _languageOption(String label) {
//     final selected = _language == label;
//     return Padding(
//       padding: const EdgeInsets.only(right: 8),
//       child: GestureDetector(
//         onTap: () => setState(() => _language = label),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//           decoration: BoxDecoration(
//             color: selected ? ColorConstants.primaryColor : Colors.white,
//             borderRadius: BorderRadius.all(Radius.circular(8)),
//             border: Border.all(
//               color: selected ? ColorConstants.primaryColor : ColorConstants.primaryColor,
//               width: 1.5,
//             ),
//           ),
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: selected ? Colors.white : ColorConstants.primaryColor,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCartBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 '$_totalItems Items',
//                 style: TextStyle(color: Colors.grey[600], fontSize: 12),
//               ),
//               Text(
//                 '${_currencySymbolNotifier.value}${_totalPrice.toStringAsFixed(2)}',
//                 style: const TextStyle(
//                   color: ColorConstants.primaryColor,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                 ),
//               ),
//             ],
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => CartScreen(
//                     cartItems: _cartItems.values.toList(),
//                     orderId: widget.orderId,
//                     tableName: widget.tableName,
//                     orderType: widget.orderType,
//                     restaurantId: widget.restaurantId,
//                     zoneId: widget.zoneId,
//                     onIncrement: _incrementCartItem,
//                     onDecrement: _decrementCartItem,
//                     onClearCart: _clearCart,
//                   ),
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: ColorConstants.primaryColor,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             icon: const Icon(Icons.shopping_cart, size: 18),
//             label: const Text('View Cart'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showCancelDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         elevation: 8,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Warning icon
//               Container(
//                 width: 56,
//                 height: 56,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFFE5E5), // light pink
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.warning_amber_rounded,
//                   color: Color(0xFFE53935), // red
//                   size: 32,
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // Title
//               const Text(
//                 'Cancel Order?',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 12),
//
//               // Message
//               const Text(
//                 'Are you sure you want to cancel this order? This action cannot be undone.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 15,
//                   color: Colors.black54,
//                   height: 1.4,
//                 ),
//               ),
//               const SizedBox(height: 28),
//
//               // Buttons
//               Row(
//                 children: [
//                   // Keep Order (outlined)
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: const Color(0xFFFF6B00), // orange
//                         side: const BorderSide(
//                           color: Color(0xFFFF6B00),
//                           width: 1.5,
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text(
//                         'Keep Order',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//
//                   // Cancel Order (filled)
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _cancelOrder();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFFF6B00), // orange
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text(
//                         'Cancel Order',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
// }
//
// class _VariantStepper extends StatelessWidget {
//   final int quantity;
//   final double scale; // default 1.0
//   final VoidCallback onAdd;
//   final VoidCallback onRemove;
//
//   const _VariantStepper({
//     required this.quantity,
//     this.scale = 1.0,
//     required this.onAdd,
//     required this.onRemove,
//   });
//
//   double s(double v) => v * scale;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: s(26),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(s(6)),
//         border: Border.all(color: ColorConstants.primaryColor, width: s(1)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: onRemove,
//             child: SizedBox(
//               width: s(22),
//               height: s(26),
//               child: Center(
//                 child: Icon(Icons.remove, size: s(14), color: ColorConstants.primaryColor),
//               ),
//             ),
//           ),
//           SizedBox(
//             width: s(18),
//             child: Text(
//               '$quantity',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: s(12),
//                 fontWeight: FontWeight.bold,
//                 color: ColorConstants.primaryColor,
//               ),
//             ),
//           ),
//           GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: onAdd,
//             child: SizedBox(
//               width: s(22),
//               height: s(26),
//               child: Center(
//                 child: Icon(Icons.add, size: s(14), color: ColorConstants.primaryColor),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

///////////////////===== impo


import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_captain_app/features/home_screen/order_menu/widgets/category_tabs.dart';
import 'package:restaurant_captain_app/features/home_screen/order_menu/widgets/product_list_view.dart';
import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../../../constants/color_constants.dart';
import '../../addons/addons_domin/addon_entity.dart';
import '../../addons/addons_domin/fetch_addons_usecase.dart';
import '../../kots_list/kots_list_bloc/kots_list_bloc.dart';
import '../../kots_list/kots_list_bloc/kots_list_event.dart';
import '../../kots_list/kots_list_bloc/kots_list_state.dart';
import '../../search_products/search_screen.dart';
import '../../variations/variations_domain/fetch_variations_usecase.dart';
import '../../variations/variations_domain/variation_entity.dart';
import '../All_tables_list/All_tables_list_bloc/all_tables_list_bloc.dart';
import '../All_tables_list/All_tables_list_bloc/all_tables_list_event.dart';
import '../Zones/Zones_bloc/zone_event.dart';
import '../Zones/Zones_bloc/zones_bloc.dart';
import '../cart_screen.dart';
import '../create_order/create_order_data_layer/create_order_remote_data_source.dart';
import 'bloc/category_bloc/category_bloc.dart';
import 'bloc/category_bloc/category_event.dart';
import 'bloc/category_bloc/category_state.dart';
import 'entities/category_entity.dart';
import 'entities/product_entity.dart';
import 'widgets/product_card.dart' show isNonVegProduct;

class CartItem {
  final ProductEntity product;
  final List<Map<String, dynamic>> addOns;
  int quantity;

  CartItem({required this.product, this.addOns = const [], this.quantity = 1});

  String get key => '${product.id}_${addOns.map((a) => a['name']).join(',')}';

  double get unitPrice =>
      (double.tryParse(product.price ?? '0') ?? 0) +
          addOns.fold<double>(0, (sum, a) => sum + (a['price'] as double));

  double get totalPrice => unitPrice * quantity;
}

class OrderMenuScreen extends StatefulWidget {
  final int orderId;
  final String tableName;
  final String orderType;
  final int restaurantId;
  final int zoneId;

  const OrderMenuScreen({
    Key? key,
    required this.orderId,
    required this.tableName,
    required this.orderType,
    required this.restaurantId,
    required this.zoneId,
  }) : super(key: key);

  @override
  State<OrderMenuScreen> createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {
  final Map<String, CartItem> _cartItems = {};
  bool _isCancellingOrder = false;

  final CreateOrderRemoteDataSource _orderDataSource =
  CreateOrderRemoteDataSourceImpl();

  bool _vegOnly = false;
  bool _nonVegOnly = false;
  String? _language;

  int? _selectedSubcategoryId;
  int? _lastCategoryIdForFilters;
  bool _showAllSubcategories = false;
  bool _hasKots = false;
  late final StreamSubscription<KotsListState> _kotsSubscription;

  final TextEditingController _searchController = TextEditingController();
  String _currencySymbol = '';
  final ValueNotifier<String> _currencySymbolNotifier = ValueNotifier<String>('');

  // ─── NEW: guards against multiple rapid taps opening several
  // variant/add-on sheets stacked on top of each other, and against
  // a single tap being registered twice (which felt like "add to
  // cart" was delayed because the second event queued behind the
  // first one's async work). These do NOT add any artificial delay
  // to a normal single tap — they only block a *second* concurrent
  // trigger while the first one is still being handled. ───────────
  bool _isCartActionBusy = false;
  final Set<int> _pendingQuantityChangeIds = {};

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CategoryBloc>();
    if (bloc.state is CategoryInitial) {
      bloc.add(LoadCategories());
    }
    _loadCurrencySymbol();

    final kotsBloc = context.read<KotsListBloc>();
    // initial check
    if (kotsBloc.state is KotsListLoaded && (kotsBloc.state as KotsListLoaded).kots.isNotEmpty) {
      _hasKots = true;
    }
    _kotsSubscription = kotsBloc.stream.listen((state) {
      if (state is KotsListLoaded && mounted) {
        setState(() {
          _hasKots = state.kots.isNotEmpty;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      kotsBloc.add(
        FetchKotsList(
          parentOrderId: widget.orderId,
          restaurantId: widget.restaurantId,
          zoneId: widget.zoneId,
        ),
      );
    });
  }

  Future<void> _loadCurrencySymbol() async {
    try {
      final symbol = await context.read<CaptainLocalStorage>().getCurrencySymbol();
      if (symbol != null && mounted) {
        print('🪙 Currency symbol loaded: $symbol');
        _currencySymbolNotifier.value = symbol;
      } else {
        print('🪙 Currency symbol not found, using default: ');
      }
    } catch (e) {
      print('🪙 Error loading currency symbol: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
    _kotsSubscription.cancel(); // ← NEW
  }

  void _addToCartDirect(ProductEntity product) {
    // 👈 NEW: per-product guard — ignores a duplicate tap on the same
    // product that arrives within 250ms of the first one, instead of
    // double-incrementing the cart.
    if (_pendingQuantityChangeIds.contains(product.id)) return;
    _pendingQuantityChangeIds.add(product.id);

    setState(() {
      final key = '${product.id}_';
      final existing = _cartItems[key];
      if (existing != null) {
        existing.quantity++;
      } else {
        _cartItems[key] = CartItem(product: product);
      }
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      _pendingQuantityChangeIds.remove(product.id);
    });
  }

  void _removeFromCart(ProductEntity product) {
    // 👈 NEW: same duplicate-tap guard as _addToCartDirect.
    if (_pendingQuantityChangeIds.contains(product.id)) return;
    _pendingQuantityChangeIds.add(product.id);

    setState(() {
      final key = '${product.id}_';
      final existing = _cartItems[key];
      if (existing == null) {
        _pendingQuantityChangeIds.remove(product.id);
        return;
      }
      if (existing.quantity <= 1) {
        _cartItems.remove(key);
      } else {
        existing.quantity--;
      }
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      _pendingQuantityChangeIds.remove(product.id);
    });
  }

  void _addVariantToCart(
      ProductEntity product,
      int quantity,
      List<Map<String, dynamic>> selectedAddOns,
      ) {
    setState(() {
      final item = CartItem(product: product, addOns: selectedAddOns, quantity: quantity);
      final existing = _cartItems[item.key];
      if (existing != null) {
        existing.quantity += quantity;
      } else {
        _cartItems[item.key] = item;
      }
    });

    if (selectedAddOns.isNotEmpty) {
      debugPrint(
        '[CART] Added "${product.name}" x$quantity with add-ons: '
            '${selectedAddOns.map((a) => a['name']).join(', ')}',
      );
    } else {
      debugPrint('[CART] Added "${product.name}" x$quantity (no add-ons)');
    }
  }


  Future<void> _showVariantAndAddOnSheet(ProductEntity product) async {
    // 👈 NEW: if a sheet is already opening/open for a previous tap,
    // ignore this call instead of stacking a second sheet on top.
    if (_isCartActionBusy) return;
    _isCartActionBusy = true;

    try {
      final variationsFuture = context.read<FetchVariationsUseCase>()(product.id);
      final addOnsFuture = context.read<FetchAddOnsUseCase>()(product.id);

      final results = await Future.wait([variationsFuture, addOnsFuture]);
      final variations = results[0] as List<VariationEntity>;
      final addOns = results[1] as List<AddOnEntity>;

      if (variations.isEmpty) {
        if (addOns.isEmpty) {
          _addToCartDirect(product);
          return;
        } else {
          await _showAddOnsOnlySheet(product, addOns);
          return;
        }
      }

      int quantity = 1;
      VariationEntity? selectedVariation = variations.first;
      final selectedAddOns = <AddOnEntity>{};
      final nonVeg = isNonVegProduct(product);
      final currencySymbol = _currencySymbolNotifier.value; // 👈 get symbol

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white, // 👈 add this

        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final media = MediaQuery.of(context);
              const referenceWidth = 375.0;
              const referenceHeight = 812.0;
              final widthScale = media.size.width / referenceWidth;
              final heightScale = media.size.height / referenceHeight;
              final scale = widthScale < heightScale ? widthScale : heightScale;
              double s(double v) => v * scale;

              // Width of one grid cell, used so FittedBox knows how much
              // horizontal room the card content actually has.
              final gridHorizontalPadding = s(20) * 2;
              final cellSpacing = s(10);
              final cardOuterWidth =
                  (media.size.width - gridHorizontalPadding - cellSpacing) / 2;
              final cardContentWidth = cardOuterWidth - (s(12) * 2); // minus card's own horizontal padding

              final basePrice = double.tryParse(selectedVariation?.price ?? '0') ?? 0;
              final addOnsTotal = selectedAddOns.fold<double>(0, (sum, a) => sum + a.price);
              final total = (basePrice + addOnsTotal) * quantity;

              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: s(20),
                  right: s(20),
                  top: s(16),
                  bottom: media.viewInsets.bottom + s(24),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: media.size.height * 0.55, // 👈 increased sheet height
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: s(10),
                            height: s(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: nonVeg ? Colors.red : Colors.green,
                            ),
                          ),
                          SizedBox(width: s(8)),
                          Expanded(
                            child: Text(
                              product.name,
                              style: TextStyle(fontSize: s(18), fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(sheetContext),
                            child: Container(
                              padding: EdgeInsets.all(s(4)),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFEAEA),
                              ),
                              child: Icon(Icons.close, size: s(18), color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: s(16)),

                      // ── Variations ──
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: variations.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: s(10),
                          crossAxisSpacing: s(10),
                          mainAxisExtent: s(118), // 👈 fixed card height — never overflows
                        ),
                        itemBuilder: (context, index) {
                          final variant = variations[index];
                          final isSelected = selectedVariation?.variationId == variant.variationId;

                          return GestureDetector(
                            onTap: () => setSheetState(() {
                              selectedVariation = variant;
                              if (!isSelected) quantity = 1;
                            }),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(8)),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorConstants.primaryColor.withOpacity(0.06)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(s(10)),
                                border: Border.all(
                                  color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade300,
                                  width: isSelected ? s(1.4) : s(1),
                                ),
                              ),
                              // 👇 auto-shrinks content instead of overflowing,
                              // no matter how large the device's font/text-scale is.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topLeft,
                                child: SizedBox(
                                  width: cardContentWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: s(11), color: Colors.grey.shade600),
                                      ),
                                      SizedBox(height: s(4)),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              variant.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: s(13), fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          SizedBox(width: s(6)),
                                          isSelected
                                              ? _VariantStepper(
                                            quantity: quantity,
                                            scale: scale,
                                            diameter: 22, // 👈 add this — compact size for the grid card
                                            onAdd: () => setSheetState(() => quantity++),
                                            onRemove: () => setSheetState(() {
                                              if (quantity > 1) quantity--;
                                            }),
                                          )
                                              : GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => setSheetState(() {
                                              selectedVariation = variant;
                                              quantity = 1;
                                            }),
                                            child: Padding(
                                              padding: EdgeInsets.all(s(2)),
                                              child: Icon(
                                                Icons.add_circle,
                                                color: ColorConstants.primaryColor,
                                                size: s(22),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: s(6)),
                                      Text(
                                        '$currencySymbol${variant.price}', // 👈 dynamic symbol
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: ColorConstants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: s(14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // ── Modifiers ──
                      if (addOns.isNotEmpty) ...[
                        SizedBox(height: s(16)),
                        Row(
                          children: [
                            Text(
                              'Modifiers',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: s(14)),
                            ),
                            SizedBox(width: s(8)),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        ...addOns.map((addOn) {
                          final isChecked = selectedAddOns.contains(addOn);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: isChecked,
                            title: Text(addOn.name, style: TextStyle(fontSize: s(14))),
                            secondary: Text(
                              '+ $currencySymbol${addOn.price.toStringAsFixed(2)}', // 👈 dynamic
                            ),
                            onChanged: (checked) {
                              setSheetState(() {
                                if (checked == true) {
                                  selectedAddOns.add(addOn);
                                } else {
                                  selectedAddOns.remove(addOn);
                                }
                              });
                            },
                          );
                        }),
                      ],

                      SizedBox(height: s(8)),

                      // ── Add to Cart ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final selectedProduct = ProductEntity(
                              id: selectedVariation!.variationId,
                              name: '${product.name} - ${selectedVariation?.name}',
                              price: selectedVariation?.price,
                              inStock: selectedVariation?.inStock == 'Yes',
                            );
                            final selectedList = selectedAddOns
                                .map((a) => {'name': a.name, 'price': a.price})
                                .toList();
                            _addVariantToCart(selectedProduct, quantity, selectedList);
                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: s(14)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(s(16)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, // 👈 centered
                            children: [
                              Text(
                                'Add to Cart',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: s(15)),
                              ),
                              SizedBox(width: s(12)),
                              Container(width: s(1), height: s(18), color: Colors.white54), // 👈 divider
                              SizedBox(width: s(12)),
                              Text(
                                '$currencySymbol${total.toStringAsFixed(2)}', // 👈 dynamic
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: s(15)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      _addToCartDirect(product);
    } finally {
      // 👈 NEW: only unlock once the sheet has actually been closed
      // (or we bailed out early), so a rapid double-tap can't queue
      // up a second sheet while this one is still on screen.
      _isCartActionBusy = false;
    }
  }

  Future<void> _showAddOnsOnlySheet(ProductEntity product, List<AddOnEntity> addOns) async {
    int quantity = 1;
    final selectedAddOns = <AddOnEntity>{};
    final basePrice = double.tryParse(product.price ?? '0') ?? 0;
    final currencySymbol = _currencySymbolNotifier.value;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white, // 👈 add this

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final addOnsTotal = selectedAddOns.fold<double>(0, (sum, a) => sum + a.price);
            final total = (basePrice + addOnsTotal) * quantity;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '$currencySymbol${basePrice.toStringAsFixed(2)}', // 👈 dynamic
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text('Add Ons', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...addOns.map((addOn) {
                    final isChecked = selectedAddOns.contains(addOn);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: isChecked,
                      title: Text(addOn.name),
                      secondary: Text(
                        '+ $currencySymbol${addOn.price.toStringAsFixed(2)}', // 👈 dynamic
                      ),
                      onChanged: (checked) {
                        setSheetState(() {
                          if (checked == true) {
                            selectedAddOns.add(addOn);
                          } else {
                            selectedAddOns.remove(addOn);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Amount:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            '$currencySymbol${total.toStringAsFixed(2)}', // 👈 dynamic
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColorConstants.primaryColor),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null,
                          ),
                          Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: ColorConstants.primaryColor),
                            onPressed: () => setSheetState(() => quantity++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedList = selectedAddOns.map((a) {
                          return {
                            'name': a.name,
                            'price': a.price,
                          };
                        }).toList();
                        _addVariantToCart(product, quantity, selectedList);
                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 👈 pill
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, // 👈 centered
                        children: [
                          const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 18, color: Colors.white54), // 👈 divider
                          const SizedBox(width: 12),
                          Text(
                            '$currencySymbol${total.toStringAsFixed(2)}', // 👈 dynamic
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddOnsSheet(ProductEntity product) async {
    // 👈 NEW: same duplicate-sheet guard as _showVariantAndAddOnSheet.
    if (_isCartActionBusy) return;
    _isCartActionBusy = true;

    try {
      final basePrice = double.tryParse(product.price ?? '0') ?? 0;
      final nonVeg = isNonVegProduct(product);
      final currencySymbol = _currencySymbolNotifier.value;

      List<AddOnEntity> addOns = [];
      try {
        addOns = await context.read<FetchAddOnsUseCase>()(product.id);
      } catch (e) {
        _addToCartDirect(product);
        return;
      }

      if (addOns.isEmpty) {
        _addToCartDirect(product);
        return;
      }

      int quantity = 1;
      final selectedAddOns = <AddOnEntity>{};

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white, // 👈 add this

        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final addOnsTotal = selectedAddOns.fold<double>(0, (sum, a) => sum + a.price);
              final total = (basePrice + addOnsTotal) * quantity;

              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: nonVeg ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFEAEA),
                            ),
                            child: const Icon(Icons.close, size: 18, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Price & Stepper ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$currencySymbol${(basePrice + addOnsTotal).toStringAsFixed(2)}', // 👈 dynamic
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryColor,
                          ),
                        ),
                        _VariantStepper(
                          quantity: quantity,
                          diameter: 32,
                          onAdd: () => setSheetState(() => quantity++),
                          onRemove: () => setSheetState(() {
                            if (quantity > 1) quantity--;
                          }),
                        ),
                      ],
                    ),

                    // ── Modifiers ──
                    if (addOns.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Text('Modifiers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          SizedBox(width: 8),
                          Expanded(child: Divider()),
                        ],
                      ),
                      ...addOns.map((addOn) {
                        final isChecked = selectedAddOns.contains(addOn);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          value: isChecked,
                          title: Text(addOn.name, style: const TextStyle(fontSize: 14)),
                          secondary: Text(
                            '+ $currencySymbol${addOn.price.toStringAsFixed(2)}', // 👈 dynamic
                          ),
                          onChanged: (checked) {
                            setSheetState(() {
                              if (checked == true) {
                                selectedAddOns.add(addOn);
                              } else {
                                selectedAddOns.remove(addOn);
                              }
                            });
                          },
                        );
                      }),
                    ],

                    const SizedBox(height: 8),

                    // ── Add to Cart ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final selectedList = selectedAddOns
                              .map((a) => {'name': a.name, 'price': a.price})
                              .toList();
                          _addVariantToCart(product, quantity, selectedList);
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // 👈 pill
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center, // 👈 centered
                          children: [
                            const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Container(width: 1, height: 18, color: Colors.white54), // 👈 divider
                            const SizedBox(width: 12),
                            Text(
                              '$currencySymbol${total.toStringAsFixed(2)}', // 👈 dynamic
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      // 👈 NEW: unlock once this whole add-ons flow (fetch + sheet) is done.
      _isCartActionBusy = false;
    }
  }

  void _incrementCartItem(CartItem item) {
    setState(() => item.quantity++);
  }

  void _decrementCartItem(CartItem item) {
    setState(() {
      if (item.quantity <= 1) {
        _cartItems.remove(item.key);
      } else {
        item.quantity--;
      }
    });
  }

  void _clearCart() {
    setState(() => _cartItems.clear());
  }

  Map<int, int> get _cartQuantitiesByProductId {
    final map = <int, int>{};
    for (final item in _cartItems.values) {
      map[item.product.id] = (map[item.product.id] ?? 0) + item.quantity;
    }
    return map;
  }

  int get _totalItems => _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
  double get _totalPrice => _cartItems.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> _cancelOrder() async {
    setState(() => _isCancellingOrder = true);
    try {
      final merchantStorage = context.read<MerchantLocalStorage>();
      final captainStorage = context.read<CaptainLocalStorage>();

      final baseUrl = await merchantStorage.getStoreBaseUrl();
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception('Store base URL not found. Please login again.');
      }

      final captainData = await captainStorage.getCaptainData();
      final token = captainData?.data?.token;
      if (token == null || token.isEmpty) {
        throw Exception('Captain token not found. Please login again.');
      }

      final result = await _orderDataSource.cancelOrder(
        baseUrl: baseUrl,
        token: token,
        parentOrderId: widget.orderId,
        restaurantId: widget.restaurantId,
        zoneId: widget.zoneId,
      );

      if (!mounted) return;

      // ─── ✅ Refresh tables & zones instantly ──────────────
      context.read<AllTablesBloc>().add(FetchAllTables());
      context.read<ZoneBloc>().add(FetchZones());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully')),
      );

      // Go back to the table management screen
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel order: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isCancellingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        // toolbarHeight: 32,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,

        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Create Order',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildOrderInfoRow(),
          _buildSearchBar(),
          _buildCategoriesLabelRow(),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              if (state is CategoryLoaded) {
                return CategoryTabs(
                  categories: state.categories,
                  selectedId: state.selectedCategoryId,
                  onTabSelected: (id) {
                    context.read<CategoryBloc>().add(SelectCategory(categoryId: id));
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              if (state is CategoryLoaded) {
                final selected = state.categories.where((c) => c.id == state.selectedCategoryId).toList();
                final title = selected.isNotEmpty ? selected.first.name : '';
                final languages = state.availableLanguages;

                if (_lastCategoryIdForFilters != state.selectedCategoryId) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _lastCategoryIdForFilters = state.selectedCategoryId;
                      _selectedSubcategoryId = null;
                      _language = languages.isNotEmpty ? languages.first : null;
                    });
                  });
                } else if (languages.isNotEmpty &&
                    (_language == null || !languages.contains(_language))) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _language = languages.first);
                  });
                }

                return _buildCategoryHeaderBlock(title, state.subcategories, languages);
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading) {
                  return const Center(child: CupertinoActivityIndicator(radius: 14));
                } else if (state is CategoryLoaded) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _currencySymbolNotifier,
                    builder: (context, symbol, _) {
                      return ProductListView(
                        subcategories: state.subcategories,
                        directProducts: state.directProducts,
                        subcategoryProducts: state.subcategoryProducts,
                        miniSubcategoriesMap: state.miniSubcategoriesMap,
                        cartQuantitiesByProductId: _cartQuantitiesByProductId,
                        selectedLanguage: _language,
                        selectedSubcategoryId: _selectedSubcategoryId,
                        vegOnly: _vegOnly,
                        nonVegOnly: _nonVegOnly,
                        onAdd: _showAddOnsSheet,
                        onRemove: _removeFromCart,
                        onVariantTap: _showVariantAndAddOnSheet,
                        // onVisibleSubcategoryChanged: (subId) {
                        //   if (_selectedSubcategoryId != subId) {
                        //     setState(() => _selectedSubcategoryId = subId);
                        //   }
                        // },
                        onVisibleSubcategoryChanged: (subId) {
                          // Only auto-update from scroll when no subcategory is selected.
                          // When user has selected a subcategory, keep that list locked.
                          if (_selectedSubcategoryId != null) return;

                          if (_selectedSubcategoryId != subId) {
                            setState(() => _selectedSubcategoryId = subId);
                          }
                        },
                        currencySymbol: symbol,
                      );
                    },
                  );
                } else if (state is CategoryError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        ElevatedButton(
                          onPressed: () => context.read<CategoryBloc>().add(LoadCategories()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // SafeArea(
          //   top: false,
          //   child: _buildCartBar(),
          // ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: _buildCartBar(),
          )
        ],
      ),
    );
  }


  Widget _buildOrderInfoRow() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(child: _orderInfoCard()),
          const SizedBox(width: 8),
          _cancelOrderChip(),
        ],
      ),
    );
  }

  Widget _orderInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB9D9FF)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Order Id #${widget.orderId}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
            ),
            _infoDivider(),
            Text(
              'Table No ${widget.tableName}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
            ),
            _infoDivider(),
            Text(
              widget.orderType,
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoDivider() {
    return Container(
      height: 14,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFB9D9FF),
    );
  }

  Widget _cancelOrderChip() {

    final bool canCancel = !_hasKots && !_isCancellingOrder;
    return GestureDetector(
      onTap: canCancel ? () => _showCancelDialog(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: canCancel ? Colors.red : Colors.grey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 14,
              color: canCancel ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              'Cancel Order',
              style: TextStyle(
                fontSize: 12,
                color: canCancel ? Colors.red : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSearchBar() {
  //   final size = MediaQuery.of(context).size;
  //
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => SearchScreen(
  //             onAddToCart: _showAddOnsSheet,
  //           ),
  //         ),
  //       );
  //     },
  //     child: Container(
  //       color: Colors.white,
  //       padding: EdgeInsets.fromLTRB(
  //         size.width * 0.034,   // left
  //         size.height * 0.001,  // top
  //         size.width * 0.034,   // right
  //         size.height * 0.008,  // bottom
  //       ),
  //       child: Container(
  //         width: double.infinity,
  //         height: size.height * 0.045,
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFF5F5F5),
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(
  //             color: Colors.grey.shade300,
  //             width: 1,
  //           ),
  //         ),
  //         child: Row(
  //           children: [
  //             SizedBox(width: size.width * 0.035),
  //             Icon(
  //               Icons.search,
  //               color: const Color(0xFF9E9E9E),
  //               size: size.width * 0.055,
  //             ),
  //             SizedBox(width: size.width * 0.025),
  //             Text(
  //               'Search...',
  //               style: TextStyle(
  //                 color: const Color(0xFF9E9E9E),
  //                 fontSize: size.width * 0.038,
  //                 fontWeight: FontWeight.w400,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchScreen(
              onAddToCart: _showAddOnsSheet,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
        child: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Icon(
                Icons.search,
                color: Color(0xFF9E9E9E),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Search...',
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildCategoriesLabelRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          // Row(
          //   children: [
          //     _dietChip(
          //       label: 'Veg',
          //       color: Colors.green,
          //       selected: _vegOnly,
          //       onTap: () => setState(() {
          //         _vegOnly = !_vegOnly;
          //         if (_vegOnly) _nonVegOnly = false;
          //       }),
          //     ),
          //     const SizedBox(width: 8),
          //     _dietChip(
          //       label: 'Non Veg',
          //       color: Colors.red,
          //       selected: _nonVegOnly,
          //       onTap: () => setState(() {
          //         _nonVegOnly = !_nonVegOnly;
          //         if (_nonVegOnly) _vegOnly = false;
          //       }),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _dietChip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeaderBlock(
      String title,
      List<SubcategoryEntity> subcategories,
      List<String> languages,
      ) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (subcategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSubcategoryChipsRow(subcategories),
          ],
          if (languages.isNotEmpty) ...[
            const SizedBox(height: 10),
            // 👇 Make languages horizontally scrollable
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: languages.map(_languageOption).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const double _maxVisibleSubcategoryChips = 3.5;


  Widget _buildSubcategoryChipsRow(List<SubcategoryEntity> subcategories) {
    final validSubs = subcategories.where((s) => s.name.trim().isNotEmpty).toList();
    final hasOverflow = validSubs.length > _maxVisibleSubcategoryChips;

    final List<SubcategoryEntity> displayedSubs;
    bool showMoreChip = false;
    bool showLessChip = false;

    if (_showAllSubcategories) {
      displayedSubs = validSubs;
      showLessChip = hasOverflow;
    } else {
      displayedSubs = hasOverflow ? validSubs.sublist(0, 4) : validSubs;
      showMoreChip = hasOverflow;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < displayedSubs.length; i++) ...[
              if (i > 0) const SizedBox(width: 8), // 👈 no gap before the first chip
              _subcategoryChip(
                label: displayedSubs[i].name,
                selected: _selectedSubcategoryId == displayedSubs[i].id,
                onTap: () => setState(() {
                  _selectedSubcategoryId =
                  (_selectedSubcategoryId == displayedSubs[i].id)
                      ? null
                      : displayedSubs[i].id;
                }),
              ),
            ],
            if (showMoreChip) ...[
              if (displayedSubs.isNotEmpty) const SizedBox(width: 8),
              _toggleChip(
                label: 'More',
                isActive: false,
                onTap: () => setState(() => _showAllSubcategories = true),
              ),
            ],
            if (showLessChip) ...[
              if (displayedSubs.isNotEmpty) const SizedBox(width: 8),
              _toggleChip(
                label: 'Less',
                isActive: true,
                onTap: () => setState(() => _showAllSubcategories = false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? ColorConstants.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? ColorConstants.primaryColor : Colors.black87,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_up,
                size: 14,
                color: ColorConstants.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _subcategoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? ColorConstants.primaryColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? ColorConstants.primaryColor : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
  }

  Widget _moreChip(List<SubcategoryEntity> overflow) {
    final isOverflowSelected = _selectedSubcategoryId != null &&
        overflow.any((s) => s.id == _selectedSubcategoryId);

    return GestureDetector(
      onTap: () => _showMoreSubcategoriesSheet(overflow),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOverflowSelected ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isOverflowSelected ? ColorConstants.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'More',
              style: TextStyle(
                fontSize: 12,
                color: isOverflowSelected ? ColorConstants.primaryColor : Colors.black87,
                fontWeight: isOverflowSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isOverflowSelected ? ColorConstants.primaryColor : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreSubcategoriesSheet(List<SubcategoryEntity> overflow) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView(
              shrinkWrap: true,
              children: overflow
                  .map((sub) => ListTile(
                title: Text(sub.name),
                trailing: _selectedSubcategoryId == sub.id
                    ? const Icon(Icons.check, color: ColorConstants.primaryColor)
                    : null,
                onTap: () {
                  setState(() => _selectedSubcategoryId = sub.id);
                  Navigator.pop(sheetContext);
                },
              ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }


  Widget _languageOption(String label) {
    final selected = _language == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _language = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? ColorConstants.primaryColor : Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            border: Border.all(
              color: selected ? ColorConstants.primaryColor : ColorConstants.primaryColor,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : ColorConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_totalItems Items',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                '${_currencySymbolNotifier.value}${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: ColorConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(
                    cartItems: _cartItems.values.toList(),
                    orderId: widget.orderId,
                    tableName: widget.tableName,
                    orderType: widget.orderType,
                    restaurantId: widget.restaurantId,
                    zoneId: widget.zoneId,
                    onIncrement: _incrementCartItem,
                    onDecrement: _decrementCartItem,
                    onClearCart: _clearCart,
                    onAddItems: (items) {
                      // Add items to the cart (merge with existing)
                      setState(() {
                        for (final item in items) {
                          final existing = _cartItems[item.key];
                          if (existing != null) {
                            existing.quantity += item.quantity;
                          } else {
                            _cartItems[item.key] = item;
                          }
                        }
                      });
                    },
                    onEditItem: (oldItem, newItem) {
                      setState(() {
                        _cartItems.remove(oldItem.key);
                        _cartItems[newItem.key] = newItem;
                      });
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: const Text('View Cart'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white, // ← added
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5), // light pink
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE53935), // red
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Cancel Order?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Message
              const Text(
                'Are you sure you want to cancel this order? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  // Keep Order (outlined)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B00), // orange
                        side: const BorderSide(
                          color: Color(0xFFFF6B00),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Keep Order',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Cancel Order (filled)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelOrder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00), // orange
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel Order',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _VariantStepper extends StatelessWidget {
  final int quantity;
  final double scale;
  final double diameter; // 👈 NEW: size of the circular buttons
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _VariantStepper({
    required this.quantity,
    this.scale = 1.0,
    this.diameter = 24,
    required this.onAdd,
    required this.onRemove,
  });

  double s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    final d = s(diameter);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRemove,
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: ColorConstants.primaryColor, width: s(1.2)),
            ),
            child: Icon(Icons.remove, size: d * 0.55, color: ColorConstants.primaryColor),
          ),
        ),
        SizedBox(
          width: s(30),
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: s(15),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onAdd,
          child: Container(
            width: d,
            height: d,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ColorConstants.primaryColor,
            ),
            child: Icon(Icons.add, size: d * 0.55, color: Colors.white),
          ),
        ),
      ],
    );
  }
}