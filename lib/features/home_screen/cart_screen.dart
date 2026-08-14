// import 'dart:async';
// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:http/http.dart' as http;
// import 'package:restaurant_captain_app/constants/color_constants.dart';
//
// import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
// import '../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
// import '../bill_summary/bill_summary_screen.dart';
// import '../kots_list/kots_list_bloc/kots_list_bloc.dart';
// import '../kots_list/kots_list_bloc/kots_list_event.dart';
// import '../kots_list/kots_list_bloc/kots_list_state.dart';
// import '../kots_list/kots_list_widget.dart';
// import '../printer/printer_service.dart';
// import 'order_menu/order_menu_screen.dart';
//
// class CartScreen extends StatefulWidget {
//   final List<CartItem> cartItems;
//
//   // Order context, used to render the top info chips and to pass along
//   // to the KOT screen when "KOT Print" is tapped.
//   final int orderId;
//   final String tableName;
//   final String orderType;
//   final int restaurantId;
//   final int zoneId;
//
//   // Called whenever the qty is bumped up/down here, so that the
//   // OrderMenuScreen (and its cart badge / total) update live, even
//   // while this screen is still open on top of it.
//   final void Function(CartItem item) onIncrement;
//   final void Function(CartItem item) onDecrement;
//   // Called after a KOT print succeeds, so OrderMenuScreen empties its cart
//   // map (resetting the item count / total shown on its bottom bar).
//   final VoidCallback onClearCart;
//
//   const CartScreen({
//     super.key,
//     required this.cartItems,
//     required this.orderId,
//     required this.tableName,
//     required this.orderType,
//     required this.restaurantId,
//     required this.zoneId,
//     required this.onIncrement,
//     required this.onDecrement,
//     required this.onClearCart,
//   });
//
//   @override
//   State<CartScreen> createState() => _CartScreenState();
// }
//
// class _CartScreenState extends State<CartScreen> {
//   late List<CartItem> cartItems;
//   bool _showAllKots = false;
//   bool _isPrintingKot = false;
//
//   // Both start as false → Checkout is disabled
//   bool _hasPrintedKot = false;
//   bool _hasAnyKots = false;
//   late final StreamSubscription<KotsListState> _kotsSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     cartItems = List.from(widget.cartItems);
//
//     // Listen to KotsListBloc to update _hasAnyKots
//     final kotsBloc = context.read<KotsListBloc>();
//     if (kotsBloc.state is KotsListLoaded && (kotsBloc.state as KotsListLoaded).kots.isNotEmpty) {
//       _hasAnyKots = true;
//     }
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
//   @override
//   void dispose() {
//     _kotsSubscription.cancel();
//     super.dispose();
//   }
//
//   double get totalPrice {
//     return cartItems.fold(0, (sum, item) => sum + item.totalPrice);
//   }
//
//   int get totalItems {
//     return cartItems.fold(0, (sum, item) => sum + item.quantity);
//   }
//
//   void _increment(CartItem item) {
//     // item is a shared reference with OrderMenuScreen's cart map, so the
//     // callback below is what actually mutates item.quantity. We only call
//     // setState here to repaint this screen with the already-updated value
//     // — mutating it a second time here would double the increment.
//     widget.onIncrement(item);
//     setState(() {});
//   }
//
//   void _decrement(CartItem item) {
//     final willBeRemoved = item.quantity <= 1;
//     widget.onDecrement(item);
//     setState(() {
//       if (willBeRemoved) {
//         cartItems.remove(item);
//       }
//     });
//   }
//
//   // Builds the `line_items` array for the KOT-print request body, one
//   // entry per cart row, carrying its add-ons through as `_addons` /
//   // `_extra_modifier_amount` meta_data — matching the API's expected shape.
//   List<Map<String, dynamic>> _buildLineItems() {
//     return cartItems.map((item) {
//       final metaData = <Map<String, dynamic>>[];
//       if (item.addOns.isNotEmpty) {
//         metaData.add({
//           'key': '_addons',
//           'value': item.addOns
//               .map((a) => {
//             'name': a['name'],
//             'quantity': 1,
//             'price': a['price'],
//           })
//               .toList(),
//         });
//         final extraModifierAmount = item.addOns
//             .fold<double>(0, (sum, a) => sum + (a['price'] as double));
//         metaData.add({
//           'key': '_extra_modifier_amount',
//           'value': extraModifierAmount.toString(),
//         });
//       }
//       return {
//         'product_id': item.product.id,
//         'quantity': item.quantity,
//         'meta_data': metaData,
//       };
//     }).toList();
//   }
//
//   // Future<void> _printKot() async {
//   //   if (cartItems.isEmpty || _isPrintingKot) return;
//   //
//   //   setState(() => _isPrintingKot = true);
//   //
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
//   //     final captainId = captainData?.data?.id;
//   //     final lineItems = _buildLineItems();
//   //     if (lineItems.isEmpty) {
//   //       throw Exception('No items available to print.');
//   //     }
//   //
//   //     debugPrint('KOT Items: $lineItems');
//   //
//   //     final response = await http.post(
//   //       Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders'),
//   //       headers: {
//   //         'Content-Type': 'application/json',
//   //         'Authorization': 'Bearer $token',
//   //       },
//   //       body: jsonEncode({
//   //         'flag_type': 'kot_order',
//   //         'parent_order_id': widget.orderId,
//   //         'restaurant_id': widget.restaurantId,
//   //         'zone_id': widget.zoneId,
//   //         'captain_id': captainId,
//   //         'line_items': lineItems,
//   //       }),
//   //     );
//   //
//   //     debugPrint('KOT Response: ${response.body}');
//   //
//   //     if (response.statusCode < 200 || response.statusCode >= 300) {
//   //       throw Exception(
//   //         'KOT print failed (${response.statusCode}): ${response.body}',
//   //       );
//   //     }
//   //
//   //     // ---------- SUCCESS ----------
//   //     if (!mounted) return;
//   //
//   //     // 1. Mark that we now have KOTs (enables Check Out)
//   //     setState(() {
//   //       _hasPrintedKot = true;
//   //       _hasAnyKots = true;
//   //       cartItems.clear();
//   //     });
//   //
//   //     // 2. Clear parent cart
//   //     widget.onClearCart();
//   //
//   //     // 3. FORCE the KOT list to pull the latest data from server
//   //     //    (even if the widget is about to be disposed)
//   //     context.read<KotsListBloc>().add(
//   //       FetchKotsList(
//   //         parentOrderId: widget.orderId,
//   //         restaurantId: widget.restaurantId,
//   //         zoneId: widget.zoneId,
//   //       ),
//   //     );
//   //
//   //     // 4. Go back
//   //     Navigator.pop(context);
//   //
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('KOT printed successfully'),
//   //         backgroundColor: Colors.green,
//   //       ),
//   //     );
//   //   } catch (e) {
//   //     if (!mounted) return;
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(
//   //         content: Text('Failed to print KOT: $e'),
//   //         backgroundColor: Colors.red,
//   //       ),
//   //     );
//   //   } finally {
//   //     if (mounted) {
//   //       setState(() => _isPrintingKot = false);
//   //     }
//   //   }
//   // }
//
//
//   Future<void> _printKot() async {
//     if (cartItems.isEmpty || _isPrintingKot) return;
//
//     setState(() => _isPrintingKot = true);
//
//     try {
//       final merchantStorage = context.read<MerchantLocalStorage>();
//       final captainStorage = context.read<CaptainLocalStorage>();
//
//       final baseUrl = await merchantStorage.getStoreBaseUrl();
//       if (baseUrl == null || baseUrl.isEmpty) {
//         throw Exception('Store base URL not found.');
//       }
//
//       final captainData = await captainStorage.getCaptainData();
//       final token = captainData?.data?.token;
//       if (token == null || token.isEmpty) {
//         throw Exception('Captain token not found.');
//       }
//
//       final captainId = captainData?.data?.id;
//       final captainName = captainData?.data?.displayName ?? 'Captain';
//       final lineItems = _buildLineItems();
//       if (lineItems.isEmpty) {
//         throw Exception('No items available to print.');
//       }
//
//       // 1. API call to create KOT
//       final response = await http.post(
//         Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'flag_type': 'kot_order',
//           'parent_order_id': widget.orderId,
//           'restaurant_id': widget.restaurantId,
//           'zone_id': widget.zoneId,
//           'captain_id': captainId,
//           'line_items': lineItems,
//         }),
//       );
//
//       if (response.statusCode < 200 || response.statusCode >= 300) {
//         throw Exception('KOT print failed (${response.statusCode}): ${response.body}');
//       }
//
//       // 2. Prepare data for physical print
//       final printItems = cartItems.map((item) {
//         final addOnNames = item.addOns.map((a) => a['name'].toString()).toList();
//         return {
//           'name': item.product.name,
//           'qty': item.quantity,
//           // unitPrice already includes add‑ons, so no subtraction needed
//           'price': item.unitPrice,          // ✅ double
//           'amount': item.totalPrice,        // ✅ double
//           'modifiers': addOnNames,
//         };
//       }).toList();
//
//       // 3. Print KOT
//       await Printer.printKot(
//         orderId: widget.orderId.toString(),
//         tableName: widget.tableName,
//         cashierName: captainName,
//         items: printItems,
//         context: context,
//       );
//
//       // 4. Update local state
//       setState(() {
//         _hasPrintedKot = true;
//         _hasAnyKots = true;
//         cartItems.clear();
//       });
//       widget.onClearCart();
//
//       // 5. Refresh KOT list
//       context.read<KotsListBloc>().add(
//         FetchKotsList(
//           parentOrderId: widget.orderId,
//           restaurantId: widget.restaurantId,
//           zoneId: widget.zoneId,
//         ),
//       );
//
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('KOT printed successfully'), backgroundColor: Colors.green),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to print KOT: $e'), backgroundColor: Colors.red),
//       );
//     } finally {
//       if (mounted) setState(() => _isPrintingKot = false);
//     }
//   }
//
//   void _goToCheckout() {
//     if (_hasAnyKots || _hasPrintedKot) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => BillSummaryScreen(
//             orderId: widget.orderId,
//             restaurantId: widget.restaurantId,
//             orderType: widget.orderType,
//             zoneId: widget.zoneId,
//           ),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0.5,
//         centerTitle: true,
//         title: const Text(
//           'Cart',
//           style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Always show order id / table / order type
//           _buildOrderInfoRow(),
//           const SizedBox(height: 12),
//           // Padding(
//           //   padding: const EdgeInsets.symmetric(horizontal: 16),
//           //   child: Column(
//           //     crossAxisAlignment: CrossAxisAlignment.start,
//           //     children: [
//           //       const Text(
//           //         "KOT's List",
//           //         style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//           //       ),
//           //       const SizedBox(height: 8),
//           //       // Always show View all KOT's
//           //       _viewAllKotsButton(),
//           //       if (_showAllKots) ...[
//           //         const SizedBox(height: 8),
//           //         Container(
//           //           width: double.infinity,
//           //           padding: const EdgeInsets.all(12),
//           //           decoration: BoxDecoration(
//           //             color: Colors.white,
//           //             borderRadius: BorderRadius.circular(8),
//           //             border: Border.all(color: Colors.grey.shade200),
//           //           ),
//           //           child: Text(
//           //             'Previous KOTs will appear here.',
//           //             style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//           //           ),
//           //         ),
//           //       ],
//           //       const SizedBox(height: 14),
//           //     ],
//           //   ),
//           // ),
//
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   "KOT's List",
//                   style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//                 ),
//                 const SizedBox(height: 8),
//                 _viewAllKotsButton(),
//                 if (_showAllKots) ...[
//                   const SizedBox(height: 8),
//                   KotsListWidget(
//                     parentOrderId: widget.orderId,
//                     restaurantId: widget.restaurantId,
//                     zoneId: widget.zoneId,
//                     onHasKotsChanged: (hasKots) {
//                       // Only update if the value actually changed
//                       if (mounted && _hasAnyKots != hasKots) {
//                         setState(() {
//                           _hasAnyKots = hasKots;
//                         });
//                       }
//                     },
//                   ),
//                 ],
//                 const SizedBox(height: 14),
//               ],
//             ),
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               child: _itemsCard(),
//             ),
//           ),
//           _bottomKotBar(),
//           _buildCheckoutFooter(),
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
//           Expanded(child: _orderInfoChip()),
//           const SizedBox(width: 8),
//           _dineInPill(),
//         ],
//       ),
//     );
//   }
//
//   Widget _orderInfoChip() {
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
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Color(0xFF2E6FCE),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             Container(
//               height: 14,
//               width: 1,
//               margin: const EdgeInsets.symmetric(horizontal: 10),
//               color: const Color(0xFFB9D9FF),
//             ),
//             Text(
//               'Table No ${widget.tableName}',
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Color(0xFF2E6FCE),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _dineInPill() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: const Color(0xFFB9D9FF)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.circle, size: 6, color: Color(0xFF2E6FCE)),
//           const SizedBox(width: 4),
//           Text(
//             widget.orderType,
//             style: const TextStyle(
//               fontSize: 12,
//               color: Color(0xFF2E6FCE),
//               fontWeight: FontWeight.w600,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             softWrap: false,
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------------
//   // "View all KOT's" button
//   // ---------------------------------------------------------------------
//   Widget _viewAllKotsButton() {
//     return GestureDetector(
//       onTap: () => setState(() => _showAllKots = !_showAllKots),
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: ColorConstants.primaryColor,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               "View all KOT's",
//               style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
//             ),
//             AnimatedRotation(
//               turns: _showAllKots ? 0.5 : 0,
//               duration: const Duration(milliseconds: 200),
//               child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------------
//   // Items table: header row + rows with qty +/- and price
//   // ---------------------------------------------------------------------
//   Widget _itemsCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.white),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFBE3D8),
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
//             ),
//             child: const Row(
//               children: [
//                 Expanded(
//                   flex: 4,
//                   child: Text('Items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
//                 ),
//                 Expanded(
//                   flex: 3,
//                   child: Text(
//                     'Quantity',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
//                   ),
//                 ),
//                 Expanded(
//                   flex: 2,
//                   child: Text(
//                     'Price',
//                     textAlign: TextAlign.right,
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (cartItems.isEmpty)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF5F5F5),
//                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
//               ),
//               child: Center(
//                 child: Text(
//                   'No item Selected\nPlease select item from Menu',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
//                 ),
//               ),
//             )
//           else
//             ListView.separated(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(), // Let outer scroll view handle scrolling
//               itemCount: cartItems.length,
//               separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
//               itemBuilder: (context, index) => _itemRow(cartItems[index]),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _itemRow(CartItem item) {
//     final subtitle = item.addOns.isNotEmpty
//         ? item.addOns.map((a) => a['name'].toString()).join(', ')
//         : 'Customize';
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Expanded(
//             flex: 4,
//             child: Row(
//               children: [
//                 _itemThumbnail(),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         item.product.name,
//                         style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 2),
//                       Row(
//                         children: [
//                           Text(
//                             subtitle,
//                             style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(width: 4),
//                           Container(
//                             padding: const EdgeInsets.all(2),
//                             decoration: const BoxDecoration(
//                               color: Colors.orange,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.edit, size: 8, color: Colors.white),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _qtyButton(
//                   icon: Icons.remove,
//                   bgColor: const Color(0xFFD8F0DE),
//                   iconColor: const Color(0xFF2E7D42),
//                   onTap: () => _decrement(item),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: Text(
//                     '${item.quantity}',
//                     style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//                 _qtyButton(
//                   icon: Icons.add,
//                   bgColor: const Color(0xFF2E7D42),
//                   iconColor: Colors.white,
//                   onTap: () => _increment(item),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Text(
//               '\$${item.totalPrice.toStringAsFixed(2)}',
//               textAlign: TextAlign.right,
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _itemThumbnail() {
//     // Placeholder thumbnail. If ProductEntity exposes an image/imageUrl
//     // field, swap this Icon for an Image.network(product.image!).
//     return Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Icon(Icons.restaurant, size: 18, color: Colors.grey.shade400),
//     );
//   }
//
//   Widget _qtyButton({
//     required IconData icon,
//     required Color bgColor,
//     required Color iconColor,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 22,
//         height: 22,
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.circular(5),
//         ),
//         child: Icon(icon, size: 14, color: iconColor),
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------------
//   // Bottom bar: Repeat KOT (outline) + KOT Print (filled)
//   // ---------------------------------------------------------------------
//   Widget _bottomKotBar() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: OutlinedButton(
//               onPressed: cartItems.isEmpty
//                   ? null
//                   : () {
//                 // TODO: hook up "repeat last KOT" behaviour.
//               },
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: ColorConstants.primaryColor,
//                 side: BorderSide(color: ColorConstants.primaryColor),
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Repeat KOT', style: TextStyle(fontWeight: FontWeight.w600)),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: ElevatedButton(
//               // Disabled whenever the cart's empty, a print is already in
//               // flight, or the "View all KOT's" list is expanded.
//               onPressed: (cartItems.isEmpty || _showAllKots || _isPrintingKot)
//                   ? null
//                   : _printKot,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: ColorConstants.primaryColor,
//                 foregroundColor: Colors.white,
//                 disabledBackgroundColor: Colors.grey.shade300,
//                 disabledForegroundColor: Colors.grey.shade600,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: _isPrintingKot
//                   ? const SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//               )
//                   : const Text('KOT Print', style: TextStyle(fontWeight: FontWeight.w600)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCheckoutFooter() {
//     // Checkout is enabled ONLY when we have at least one KOT
//     final bool canCheckout = _hasAnyKots || _hasPrintedKot;
//
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: Colors.grey.shade200)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 '$totalItems Items',
//                 style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
//               ),
//               Text(
//                 '\$${totalPrice.toStringAsFixed(2)}',
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.grey.shade700,
//                 ),
//               ),
//             ],
//           ),
//           TextButton(
//             onPressed: canCheckout ? _goToCheckout : null, // null = disabled
//             style: TextButton.styleFrom(
//               foregroundColor: ColorConstants.primaryColor,
//               disabledForegroundColor: Colors.grey.shade400, // grey when disabled
//             ),
//             child: const Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text('Check Out', style: TextStyle(fontWeight: FontWeight.w600)),
//                 SizedBox(width: 4),
//                 Icon(Icons.arrow_forward, size: 16),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


/////=====


import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:restaurant_captain_app/constants/color_constants.dart';

import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../bill_summary/bill_summary_screen.dart';
import '../kots_list/kots_list_bloc/kots_list_bloc.dart';
import '../kots_list/kots_list_bloc/kots_list_event.dart';
import '../kots_list/kots_list_bloc/kots_list_state.dart';
import '../kots_list/kots_list_widget.dart';
import '../printer/printer_service.dart';
import 'order_menu/order_menu_screen.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final int orderId;
  final String tableName;
  final String orderType;
  final int restaurantId;
  final int zoneId;
  final void Function(CartItem item) onIncrement;
  final void Function(CartItem item) onDecrement;
  final VoidCallback onClearCart;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.orderId,
    required this.tableName,
    required this.orderType,
    required this.restaurantId,
    required this.zoneId,
    required this.onIncrement,
    required this.onDecrement,
    required this.onClearCart,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> cartItems;
  bool _showAllKots = false;
  bool _isPrintingKot = false;
  bool _hasPrintedKot = false;
  bool _hasAnyKots = false;
  late final StreamSubscription<KotsListState> _kotsSubscription;

  @override
  void initState() {
    super.initState();
    cartItems = List.from(widget.cartItems);

    final kotsBloc = context.read<KotsListBloc>();

    // Check current state for KOTs
    if (kotsBloc.state is KotsListLoaded && (kotsBloc.state as KotsListLoaded).kots.isNotEmpty) {
      _hasAnyKots = true;
    }

    // Initialize the subscription BEFORE adding the event to avoid missing data
    _kotsSubscription = kotsBloc.stream.listen((state) {
      if (state is KotsListLoaded && mounted) {
        setState(() {
          _hasAnyKots = state.kots.isNotEmpty;
        });
      }
    });

    // Pre-fetch KOTs in the background
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

  @override
  void dispose() {
    _kotsSubscription.cancel();
    super.dispose();
  }

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => cartItems.fold(0, (sum, item) => sum + item.quantity);

  void _increment(CartItem item) {
    widget.onIncrement(item);
    setState(() {});
  }

  void _decrement(CartItem item) {
    final willBeRemoved = item.quantity <= 1;
    widget.onDecrement(item);
    setState(() {
      if (willBeRemoved) cartItems.remove(item);
    });
  }

  List<Map<String, dynamic>> _buildLineItems() {
    return cartItems.map((item) {
      final metaData = <Map<String, dynamic>>[];
      if (item.addOns.isNotEmpty) {
        metaData.add({
          'key': '_addons',
          'value': item.addOns
              .map((a) => {
            'name': a['name'],
            'quantity': 1,
            'price': a['price'],
          })
              .toList(),
        });
        final extraModifierAmount = item.addOns.fold<double>(0, (sum, a) => sum + (a['price'] as double));
        metaData.add({
          'key': '_extra_modifier_amount',
          'value': extraModifierAmount.toString(),
        });
      }
      return {
        'product_id': item.product.id,
        'quantity': item.quantity,
        'meta_data': metaData,
      };
    }).toList();
  }

  Future<void> _printKot() async {
    if (cartItems.isEmpty || _isPrintingKot) return;
    setState(() => _isPrintingKot = true);

    try {
      final merchantStorage = context.read<MerchantLocalStorage>();
      final captainStorage = context.read<CaptainLocalStorage>();

      final baseUrl = await merchantStorage.getStoreBaseUrl();
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception('Store base URL not found.');
      }

      final captainData = await captainStorage.getCaptainData();
      final token = captainData?.data?.token;
      if (token == null || token.isEmpty) {
        throw Exception('Captain token not found.');
      }

      final captainId = captainData?.data?.id;
      final captainName = captainData?.data?.displayName ?? 'Captain';
      final lineItems = _buildLineItems();
      if (lineItems.isEmpty) {
        throw Exception('No items available to print.');
      }

      // 1. API call to create KOT
      final response = await http.post(
        Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'flag_type': 'kot_order',
          'parent_order_id': widget.orderId,
          'restaurant_id': widget.restaurantId,
          'zone_id': widget.zoneId,
          'captain_id': captainId,
          'line_items': lineItems,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('KOT print failed (${response.statusCode}): ${response.body}');
      }

      // 2. Prepare data for physical print
      final printItems = cartItems.map((item) {
        final addOnNames = item.addOns.map((a) => a['name'].toString()).toList();
        return {
          'name': item.product.name,
          'qty': item.quantity,
          'price': item.unitPrice,
          'amount': item.totalPrice,
          'modifiers': addOnNames,
        };
      }).toList();

      // 3. Print KOT
      await Printer.printKot(
        orderId: widget.orderId.toString(),
        tableName: widget.tableName,
        cashierName: captainName,
        items: printItems,
        context: context,
      );

      // 4. Update state
      setState(() {
        _hasPrintedKot = true;
        _hasAnyKots = true;
        cartItems.clear();
      });
      widget.onClearCart();

      // 5. Refresh KOT list
      context.read<KotsListBloc>().add(
        FetchKotsList(
          parentOrderId: widget.orderId,
          restaurantId: widget.restaurantId,
          zoneId: widget.zoneId,
        ),
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KOT printed successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print KOT: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isPrintingKot = false);
    }
  }

  void _goToCheckout() {
    if (_hasAnyKots || _hasPrintedKot) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BillSummaryScreen(
            orderId: widget.orderId,
            restaurantId: widget.restaurantId,
            orderType: widget.orderType,
            zoneId: widget.zoneId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cart',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          _buildOrderInfoRow(),
          const SizedBox(height: 12),
          // KOT's List section (fixed height, scrollable if needed)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // KOT's List header + button
                  _buildKotListSection(),
                  // Items card
                  _itemsCard(),
                ],
              ),
            ),
          ),
          _bottomKotBar(),
          _buildCheckoutFooter(),
        ],
      ),
    );
  }

  Widget _buildKotListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "KOT's List",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _viewAllKotsButton(),
        if (_showAllKots) ...[
          const SizedBox(height: 8),
          KotsListWidget(
            parentOrderId: widget.orderId,
            restaurantId: widget.restaurantId,
            zoneId: widget.zoneId,
            onHasKotsChanged: (hasKots) {
              if (mounted && _hasAnyKots != hasKots) {
                setState(() => _hasAnyKots = hasKots);
              }
            },
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildOrderInfoRow() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(child: _orderInfoChip()),
          const SizedBox(width: 8),
          _dineInPill(),
        ],
      ),
    );
  }

  Widget _orderInfoChip() {
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
            Container(
              height: 14,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: const Color(0xFFB9D9FF),
            ),
            Text(
              'Table No ${widget.tableName}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dineInPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB9D9FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 6, color: Color(0xFF2E6FCE)),
          const SizedBox(width: 4),
          Text(
            widget.orderType,
            style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ],
      ),
    );
  }

  Widget _viewAllKotsButton() {
    return GestureDetector(
      onTap: () => setState(() => _showAllKots = !_showAllKots),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ColorConstants.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "View all KOT's",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            AnimatedRotation(
              turns: _showAllKots ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Items card with scrollable inner ListView ───
  Widget _itemsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBE3D8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(flex: 3, child: Text('Quantity', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
          ),
          if (cartItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Center(
                child: Text(
                  'No item Selected\nPlease select item from Menu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartItems.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) => _itemRow(cartItems[index]),
            ),
        ],
      ),
    );
  }

  Widget _itemRow(CartItem item) {
    final subtitle = item.addOns.isNotEmpty ? item.addOns.map((a) => a['name'].toString()).join(', ') : 'Customize';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _itemThumbnail(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                            child: const Icon(Icons.edit, size: 8, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _qtyButton(icon: Icons.remove, bgColor: const Color(0xFFD8F0DE), iconColor: const Color(0xFF2E7D42), onTap: () => _decrement(item)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                _qtyButton(icon: Icons.add, bgColor: const Color(0xFF2E7D42), iconColor: Colors.white, onTap: () => _increment(item)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '\$${item.totalPrice.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemThumbnail() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.restaurant, size: 18, color: Colors.grey.shade400),
    );
  }

  Widget _qtyButton({required IconData icon, required Color bgColor, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(5)),
        child: Icon(icon, size: 14, color: iconColor),
      ),
    );
  }

  Widget _bottomKotBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: cartItems.isEmpty ? null : () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primaryColor,
                side: BorderSide(color: ColorConstants.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Repeat KOT', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: (cartItems.isEmpty || _showAllKots || _isPrintingKot) ? null : _printKot,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isPrintingKot
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('KOT Print', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutFooter() {
    final bool canCheckout = _hasAnyKots || _hasPrintedKot;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$totalItems Items', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              Text('\$${totalPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
            ],
          ),
          TextButton(
            onPressed: canCheckout ? _goToCheckout : null,
            style: TextButton.styleFrom(
              foregroundColor: ColorConstants.primaryColor,
              disabledForegroundColor: Colors.grey.shade400,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Check Out', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}