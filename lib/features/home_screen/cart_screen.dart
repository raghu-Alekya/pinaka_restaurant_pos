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
// // ─── NEW imports for table refresh ──────────────────────────────────
// import '../home_screen/All_tables_list/All_tables_list_bloc/all_tables_list_bloc.dart';
// import '../home_screen/All_tables_list/All_tables_list_bloc/all_tables_list_event.dart';
// import '../home_screen/Zones/Zones_bloc/zone_event.dart';
// import '../home_screen/Zones/Zones_bloc/zones_bloc.dart';
//
// class CartScreen extends StatefulWidget {
//   final List<CartItem> cartItems;
//   final int orderId;
//   final String tableName;
//   final String orderType;
//   final int restaurantId;
//   final int zoneId;
//   final void Function(CartItem item) onIncrement;
//   final void Function(CartItem item) onDecrement;
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
//   bool _isRepeatingKot = false;
//   bool _hasPrintedKot = false;
//   bool _hasAnyKots = false;
//   late final StreamSubscription<KotsListState> _kotsSubscription;
//   final ValueNotifier<String> _currencySymbolNotifier = ValueNotifier<String>('\$');
//
//   @override
//   void initState() {
//     super.initState();
//     cartItems = List.from(widget.cartItems);
//     _loadCurrencySymbol();
//
//     final kotsBloc = context.read<KotsListBloc>();
//
//     if (kotsBloc.state is KotsListLoaded && (kotsBloc.state as KotsListLoaded).kots.isNotEmpty) {
//       _hasAnyKots = true;
//     }
//
//     _kotsSubscription = kotsBloc.stream.listen((state) {
//       if (state is KotsListLoaded && mounted) {
//         setState(() {
//           _hasAnyKots = state.kots.isNotEmpty;
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
//         _currencySymbolNotifier.value = symbol;
//         print('🪙 Cart currency symbol: $symbol');
//       }
//     } catch (_) {}
//   }
//
//   @override
//   void dispose() {
//     _kotsSubscription.cancel();
//     _currencySymbolNotifier.dispose();
//     super.dispose();
//   }
//
//   double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.totalPrice);
//   int get totalItems => cartItems.fold(0, (sum, item) => sum + item.quantity);
//
//   void _increment(CartItem item) {
//     widget.onIncrement(item);
//     setState(() {});
//   }
//
//   void _decrement(CartItem item) {
//     final willBeRemoved = item.quantity <= 1;
//     widget.onDecrement(item);
//     setState(() {
//       if (willBeRemoved) cartItems.remove(item);
//     });
//   }
//
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
//         final extraModifierAmount = item.addOns.fold<double>(0, (sum, a) => sum + (a['price'] as double));
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
//   // ─── KOT Print ────────────────────────────────────────────────────────────
//   Future<void> _printKot() async {
//     if (cartItems.isEmpty || _isPrintingKot) return;
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
//       final printItems = cartItems.map((item) {
//         final addOnNames = item.addOns.map((a) => a['name'].toString()).toList();
//         return {
//           'name': item.product.name,
//           'qty': item.quantity,
//           'price': item.unitPrice,
//           'amount': item.totalPrice,
//           'modifiers': addOnNames,
//         };
//       }).toList();
//
//       await Printer.printKot(
//         orderId: widget.orderId.toString(),
//         tableName: widget.tableName,
//         cashierName: captainName,
//         items: printItems,
//         context: context,
//       );
//
//       setState(() {
//         _hasPrintedKot = true;
//         _hasAnyKots = true;
//         cartItems.clear();
//       });
//       widget.onClearCart();
//
//       context.read<KotsListBloc>().add(
//         FetchKotsList(
//           parentOrderId: widget.orderId,
//           restaurantId: widget.restaurantId,
//           zoneId: widget.zoneId,
//         ),
//       );
//
//       // ─── ✅ Refresh tables instantly ──────────────────────────
//       context.read<AllTablesBloc>().add(FetchAllTables());
//       context.read<ZoneBloc>().add(FetchZones());
//
//       Navigator.pop(context);
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
//   void _showRepeatKotDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           elevation: 8,
//           backgroundColor: Colors.white,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFFFF3E0),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.warning_amber_rounded,
//                     color: Color(0xFFFFA000),
//                     size: 28,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Repeat KOT?',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1A1A1A),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   'A new KOT will be generated with the same items and sent to the kitchen.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 14,
//                     height: 1.4,
//                     color: Color(0xFF666666),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: ColorConstants.primaryColor,
//                           side: BorderSide(
//                             color: ColorConstants.primaryColor,
//                             width: 1.5,
//                           ),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: const Text(
//                           'Cancel',
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           _repeatKot();
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: ColorConstants.primaryColor,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: const Text(
//                           'Confirm',
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> _repeatKot() async {
//     if (_isRepeatingKot || !_hasAnyKots) return;
//     setState(() => _isRepeatingKot = true);
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
//       final response = await http.post(
//         Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/repeat-kot-order'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'order_id': widget.orderId,
//           'restaurant_id': widget.restaurantId,
//           'zone_id': widget.zoneId,
//         }),
//       );
//
//       if (response.statusCode < 200 || response.statusCode >= 300) {
//         throw Exception('Repeat KOT failed (${response.statusCode}): ${response.body}');
//       }
//
//       context.read<KotsListBloc>().add(
//         FetchKotsList(
//           parentOrderId: widget.orderId,
//           restaurantId: widget.restaurantId,
//           zoneId: widget.zoneId,
//         ),
//       );
//
//       // ─── ✅ Refresh tables instantly ──────────────────────────
//       context.read<AllTablesBloc>().add(FetchAllTables());
//       context.read<ZoneBloc>().add(FetchZones());
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('KOT repeated successfully'), backgroundColor: Colors.green),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to repeat KOT: $e'), backgroundColor: Colors.red),
//       );
//     } finally {
//       if (mounted) setState(() => _isRepeatingKot = false);
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
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Cart',
//           style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
//         ),
//       ),
//       body: ValueListenableBuilder<String>(
//         valueListenable: _currencySymbolNotifier,
//         builder: (context, currencySymbol, _) {
//           return Column(
//             children: [
//               _buildOrderInfoRow(),
//               const SizedBox(height: 12),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                   child: Column(
//                     children: [
//                       _buildKotListSection(),
//                       _itemsCard(currencySymbol),
//                     ],
//                   ),
//                 ),
//               ),
//               _bottomKotBar(currencySymbol),
//               _buildCheckoutFooter(currencySymbol),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildKotListSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "KOT's List",
//           style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//         ),
//         const SizedBox(height: 8),
//         _viewAllKotsButton(),
//         if (_showAllKots) ...[
//           const SizedBox(height: 8),
//           KotsListWidget(
//             parentOrderId: widget.orderId,
//             restaurantId: widget.restaurantId,
//             zoneId: widget.zoneId,
//             onHasKotsChanged: (hasKots) {
//               if (mounted && _hasAnyKots != hasKots) {
//                 setState(() => _hasAnyKots = hasKots);
//               }
//             },
//           ),
//         ],
//         const SizedBox(height: 14),
//       ],
//     );
//   }
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
//               style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
//             ),
//             Container(
//               height: 14,
//               width: 1,
//               margin: const EdgeInsets.symmetric(horizontal: 10),
//               color: const Color(0xFFB9D9FF),
//             ),
//             Text(
//               'Table No ${widget.tableName}',
//               style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
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
//             style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             softWrap: false,
//           ),
//         ],
//       ),
//     );
//   }
//
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
//   Widget _itemsCard(String currencySymbol) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.white),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFBE3D8),
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
//             ),
//             child: const Row(
//               children: [
//                 Expanded(flex: 4, child: Text('Items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
//                 Expanded(flex: 3, child: Text('Quantity', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
//                 Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
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
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: cartItems.length,
//               separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
//               itemBuilder: (context, index) => _itemRow(cartItems[index], currencySymbol),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _itemRow(CartItem item, String currencySymbol) {
//     final subtitle = item.addOns.isNotEmpty ? item.addOns.map((a) => a['name'].toString()).join(', ') : 'Customize';
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
//                       Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
//                       const SizedBox(height: 2),
//                       Row(
//                         children: [
//                           Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
//                           const SizedBox(width: 4),
//                           Container(
//                             padding: const EdgeInsets.all(2),
//                             decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
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
//                 _qtyButton(icon: Icons.remove, bgColor: const Color(0xFFD8F0DE), iconColor: const Color(0xFF2E7D42), onTap: () => _decrement(item)),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//                 ),
//                 _qtyButton(icon: Icons.add, bgColor: const Color(0xFF2E7D42), iconColor: Colors.white, onTap: () => _increment(item)),
//               ],
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Text(
//               '$currencySymbol${item.totalPrice.toStringAsFixed(2)}',
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
//     return Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
//       child: Icon(Icons.restaurant, size: 18, color: Colors.grey.shade400),
//     );
//   }
//
//   Widget _qtyButton({required IconData icon, required Color bgColor, required Color iconColor, required VoidCallback onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 22,
//         height: 22,
//         decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(5)),
//         child: Icon(icon, size: 14, color: iconColor),
//       ),
//     );
//   }
//
//   // ─── Bottom Bar with Repeat KOT ──────────────────────────────────────────
//   Widget _bottomKotBar(String currencySymbol) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: OutlinedButton(
//               onPressed: (!_hasAnyKots || _isRepeatingKot) ? null : _showRepeatKotDialog,
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: ColorConstants.primaryColor,
//                 side: BorderSide(color: ColorConstants.primaryColor),
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: _isRepeatingKot
//                   ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: ColorConstants.primaryColor))
//                   : const Text('Repeat KOT', style: TextStyle(fontWeight: FontWeight.w600)),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: ElevatedButton(
//               onPressed: (cartItems.isEmpty || _showAllKots || _isPrintingKot) ? null : _printKot,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: ColorConstants.primaryColor,
//                 foregroundColor: Colors.white,
//                 disabledBackgroundColor: Colors.grey.shade300,
//                 disabledForegroundColor: Colors.grey.shade600,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: _isPrintingKot
//                   ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//                   : const Text('KOT Print', style: TextStyle(fontWeight: FontWeight.w600)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCheckoutFooter(String currencySymbol) {
//     final bool canCheckout = _hasAnyKots || _hasPrintedKot;
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
//               Text('$totalItems Items', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
//               Text(
//                 '$currencySymbol${totalPrice.toStringAsFixed(2)}',
//                 style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
//               ),
//             ],
//           ),
//           TextButton(
//             onPressed: canCheckout ? _goToCheckout : null,
//             style: TextButton.styleFrom(
//               foregroundColor: ColorConstants.primaryColor,
//               disabledForegroundColor: Colors.grey.shade400,
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

////====

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:restaurant_captain_app/constants/color_constants.dart';

import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../addons/addons_domin/addon_entity.dart';
import '../addons/addons_domin/fetch_addons_usecase.dart';
import '../bill_summary/bill_summary_screen.dart';
import '../kots_list/kots_list_bloc/kots_list_bloc.dart';
import '../kots_list/kots_list_bloc/kots_list_event.dart';
import '../kots_list/kots_list_bloc/kots_list_state.dart';
import '../kots_list/kots_list_domin/kots_list_entity.dart';
import '../kots_list/kots_list_widget.dart';
import '../printer/printer_service.dart';
import '../kots_list/kots_list_bloc/kds_seivices.dart';
import 'order_menu/entities/product_entity.dart';
import 'order_menu/order_menu_screen.dart';

// ─── Table refresh and navigation imports ────────────────────────────
import '../home_screen/All_tables_list/All_tables_list_bloc/all_tables_list_bloc.dart';
import '../home_screen/All_tables_list/All_tables_list_bloc/all_tables_list_event.dart';
import '../home_screen/Zones/Zones_bloc/zone_event.dart';
import '../home_screen/Zones/Zones_bloc/zones_bloc.dart';
import '../home_screen/TableManagement_Screen.dart';

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
  final void Function(List<CartItem> items) onAddItems;
  final void Function(CartItem oldItem, CartItem newItem)? onEditItem; // 👈 new

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
    required this.onAddItems,
    this.onEditItem,

  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> cartItems;
  bool _showAllKots = false;
  bool _isPrintingKot = false;
  bool _isRepeatingKot = false;
  bool _hasPrintedKot = false;
  bool _hasAnyKots = false;
  bool _initialAutoExpandDone = false;
  late final StreamSubscription<KotsListState> _kotsSubscription;
  final ValueNotifier<String> _currencySymbolNotifier = ValueNotifier<String>('\$');
  bool _isEditSheetOpen = false;

  @override
  void initState() {
    super.initState();
    cartItems = List.from(widget.cartItems);
    _loadCurrencySymbol();

    final kotsBloc = context.read<KotsListBloc>();

    if (kotsBloc.state is KotsListLoaded && (kotsBloc.state as KotsListLoaded).kots.isNotEmpty) {
      _hasAnyKots = true;
      if (cartItems.isEmpty) {
        _showAllKots = true;
        _initialAutoExpandDone = true;
      }
    }

    _kotsSubscription = kotsBloc.stream.listen((state) {
      if (state is KotsListLoaded && mounted) {
        setState(() {
          _hasAnyKots = state.kots.isNotEmpty;
          if (_hasAnyKots && cartItems.isEmpty && !_initialAutoExpandDone) {
            _showAllKots = true;
            _initialAutoExpandDone = true;
          }
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
        _currencySymbolNotifier.value = symbol;
        print('🪙 Cart currency symbol: $symbol');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _kotsSubscription.cancel();
    _currencySymbolNotifier.dispose();
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

  Future<void> _showEditAddOnsSheet(CartItem oldItem) async {
    // 👇 Prevent multiple sheets from opening
    if (_isEditSheetOpen) return;
    // 👇 Only show if the item actually has add-ons to edit
    if (oldItem.addOns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No add-ons to edit.')),
      );
      return;
    }

    setState(() => _isEditSheetOpen = true);

    try {
      final addOns = await context.read<FetchAddOnsUseCase>()(oldItem.product.id);

      // If the API returns no add-ons, inform the user and unlock
      if (addOns.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No add-ons available for this item.')),
        );
        if (mounted) setState(() => _isEditSheetOpen = false);
        return;
      }

      // ─── Pre-select the item's current add-ons ──────────────────────
      final selectedAddOns = <AddOnEntity>{};
      for (final currentAddOn in oldItem.addOns) {
        final name = currentAddOn['name'] as String;
        final price = currentAddOn['price'] as double;
        final matching = addOns.firstWhere(
              (a) => a.name == name && a.price == price,
          orElse: () => AddOnEntity(
            name: name,
            price: price,
            id: 0,
            restaurantId: 0,
            type: '',
          ),
        );
        // If we found a matching add-on (i.e., it's not the dummy), select it.
        if (matching.id != 0 || matching.name == name) {
          selectedAddOns.add(matching);
        }
      }

      final currencySymbol = _currencySymbolNotifier.value;

      // ─── Show the bottom sheet ──────────────────────────────────────
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
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
                    // ── Header ──
                    Row(
                      children: [
                        const Text(
                          'Edit Add-ons',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
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

                    // ── Add‑on list ──
                    ...addOns.map((addOn) {
                      final isChecked = selectedAddOns.contains(addOn);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: isChecked,
                        title: Text(addOn.name),
                        secondary: Text(
                          '+ $currencySymbol${addOn.price.toStringAsFixed(2)}',
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
                    const SizedBox(height: 16),

                    // ── Save button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final newAddOns = selectedAddOns.map((a) {
                            return {'name': a.name, 'price': a.price};
                          }).toList();
                          final newItem = CartItem(
                            product: oldItem.product,
                            addOns: newAddOns,
                            quantity: oldItem.quantity,
                          );
                          // Notify parent and update local list
                          widget.onEditItem?.call(oldItem, newItem);
                          setState(() {
                            final index = cartItems.indexOf(oldItem);
                            if (index != -1) {
                              cartItems[index] = newItem;
                            }
                          });
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add-ons updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ).whenComplete(() {
        // 👇 Unlock when the sheet is dismissed
        if (mounted) setState(() => _isEditSheetOpen = false);
      });
    } catch (e) {
      // ─── Error handling ──────────────────────────────────────────────
      if (mounted) setState(() => _isEditSheetOpen = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load add-ons: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── KOT Print ────────────────────────────────────────────────────────────
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
      final captainRole = captainData?.data?.role ?? 'Captain';

      final lineItems = _buildLineItems();
      if (lineItems.isEmpty) {
        throw Exception('No items available to print.');
      }

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

      // ─── Parse response for real KOT data ──────────────────────────────
      final responseData = jsonDecode(response.body);
      final int kotId = responseData['kot_id'] ?? 0;
      final String kotNumber = responseData['kot_number'] ?? 'KOT-${widget.orderId}';
      final double kotTotal = (responseData['kot_total'] as num?)?.toDouble() ?? totalPrice;
      final List<dynamic> itemsJson = responseData['items'] ?? [];

      // Build line items from the API response
      final List<LineItem> kotLineItems = itemsJson.map((item) {
        return LineItem(
          id: item['id'] ?? 0,
          productId: item['product_id'] ?? 0,
          itemName: item['product_name'] ?? '',
          quantity: item['quantity'] ?? 0,
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
          modifiers: item['modifiers'] ?? [],
          combos: [],
          isCancelled: 'no',
        );
      }).toList();

      // Get zone name if available (fallback to empty string)
      final String zoneName = responseData['zone_name'] ?? '';

      // ─── Notify KDS via MQTT with real data ──────────────────────────
      try {
        final kotOrder = KotOrder(
          id: kotId,
          time: DateTime.now().toIso8601String(),
          status: 'pending',
          total: kotTotal,
          kotNumber: kotNumber,
          orderBy: captainName,
          lineItems: kotLineItems,
        );

        await KdsMqttPublisher.notifyKotCreated(
          restaurantId: widget.restaurantId.toString(),
          parentOrderId: widget.orderId,
          zoneId: widget.zoneId,
          zoneName: zoneName,
          orderType: widget.orderType,
          kot: kotOrder,
          tableName: widget.tableName,
          tableId: widget.tableName,
        );
      } catch (mqttError) {
        // Non-blocking – printing already succeeded
        print('MQTT notify failed (non-blocking): $mqttError');
      }

      // ─── Print KOT (unchanged) ──────────────────────────────────────────
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

      await Printer.printKot(
        orderId: widget.orderId.toString(),
        tableName: widget.tableName,
        cashierName: captainName,
        items: printItems,
        context: context,
      );

      setState(() {
        _hasPrintedKot = true;
        _hasAnyKots = true;
        cartItems.clear();
      });
      widget.onClearCart();

      context.read<KotsListBloc>().add(
        FetchKotsList(
          parentOrderId: widget.orderId,
          restaurantId: widget.restaurantId,
          zoneId: widget.zoneId,
        ),
      );

      // ─── Refresh tables & zones instantly ──────────────────────────
      context.read<AllTablesBloc>().add(FetchAllTables());
      context.read<ZoneBloc>().add(FetchZones());

      // ─── Return to the existing TableManagementScreen ───────────────
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print KOT: $e'), backgroundColor: Colors.red),
      );
      // Still navigate back on error
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isPrintingKot = false);
    }
  }

  void _showRepeatKotDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFFA000),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Repeat KOT?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'A new KOT will be generated with the same items and sent to the kitchen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConstants.primaryColor,
                          side: BorderSide(
                            color: ColorConstants.primaryColor,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _repeatKot();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
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
        );
      },
    );
  }

  Future<void> _repeatKot() async {
    if (_isRepeatingKot || !_hasAnyKots) return;
    setState(() => _isRepeatingKot = true);

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

      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/repeat-kot-order';

      final requestBody = {
        'order_id': widget.orderId,
        'restaurant_id': widget.restaurantId,
        'zone_id': widget.zoneId,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Repeat KOT failed (${response.statusCode}): ${response.body}',
        );
      }

      // ─── Parse response and add items to cart via callback ──────────
      final responseData = jsonDecode(response.body);
      final List<dynamic> lineItems = responseData['line_items'] ?? [];

      // Build CartItem list from the response
      final List<CartItem> newItems = [];
      for (final itemJson in lineItems) {
        final productId = itemJson['product_id'] ?? 0;
        final productName = itemJson['product_name'] ?? 'Unknown Product';
        final String priceStr = itemJson['product_price']?.toString() ?? '0';
        final int quantity = itemJson['quantity'] ?? 1;

        if (productId > 0) {
          final product = ProductEntity(
            id: productId,
            name: productName,
            price: priceStr,
            inStock: true,
            isVariant: 'No',
          );
          newItems.add(CartItem(product: product, quantity: quantity));
        }
      }

      if (newItems.isNotEmpty) {
        // Add items to the parent cart via callback
        widget.onAddItems(newItems);
        // Update local cartItems list so the UI reflects changes
        setState(() {
          // Merge new items with existing ones
          for (final newItem in newItems) {
            final existingIndex = cartItems.indexWhere(
                  (item) => item.product.id == newItem.product.id,
            );
            if (existingIndex != -1) {
              cartItems[existingIndex].quantity += newItem.quantity;
            } else {
              cartItems.add(newItem);
            }
          }
          // 👇 Collapse KOT list so items are visible
          _showAllKots = false;
        });
      }

      // ─── Refresh KOT list and tables ────────────────────────────────────
      context.read<KotsListBloc>().add(
        FetchKotsList(
          parentOrderId: widget.orderId,
          restaurantId: widget.restaurantId,
          zoneId: widget.zoneId,
        ),
      );

      context.read<AllTablesBloc>().add(FetchAllTables());
      context.read<ZoneBloc>().add(FetchZones());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KOT repeated successfully. Items added to cart.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('════════════ REPEAT KOT ERROR ═════════════');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('════════════════════════════════════════════');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to repeat KOT: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRepeatingKot = false);
      }
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
        toolbarHeight: 28,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cart',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: _currencySymbolNotifier,
        builder: (context, currencySymbol, _) {
          return Column(
            children: [
              _buildOrderInfoRow(),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      _buildKotListSection(),
                      if (!_showAllKots)
                        _itemsCard(currencySymbol),
                    ],
                  ),
                ),
              ),
              // _bottomKotBar(currencySymbol),
              // _buildCheckoutFooter(currencySymbol),
              SafeArea(
                top: false,          // only protect the bottom
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _bottomKotBar(currencySymbol),
                    _buildCheckoutFooter(currencySymbol),
                  ],
                ),
              ),
            ],
          );
        },
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

  Widget _itemsCard(String currencySymbol) {
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
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Dismissible(
                  key: ValueKey(item.key),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red.shade600,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Remove item?',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF171717),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Are you sure you want to remove\n'
                                      '${item.product.name} from your cart?',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Color(0xFF737373),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 58,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF404040),
                                            side: const BorderSide(
                                              color: Color(0xFFE5E5E5),
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: SizedBox(
                                        height: 58,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE53935),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text(
                                            'Remove',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  onDismissed: (_) {
                    _decrement(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.product.name} removed'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: _itemRow(item, currencySymbol),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _itemRow(CartItem item, String currencySymbol) {
    final subtitle = item.addOns.isNotEmpty
        ? item.addOns.map((a) => a['name'].toString()).join(', ')
        : 'Customize';

    final bool hasAddOns = item.addOns.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: GestureDetector(
        onTap: () => _showEditAddOnsSheet(item),
        behavior: HitTestBehavior.opaque,
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
                        Text(
                          item.product.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              subtitle,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 4),
                            if (hasAddOns)
                              GestureDetector(
                                onTap: () => _showEditAddOnsSheet(item),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, size: 8, color: Colors.white),
                                ),
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
                  _qtyButton(
                    icon: Icons.remove,
                    bgColor: const Color(0xFFD8F0DE),
                    iconColor: const Color(0xFF2E7D42),
                    onTap: () => _decrement(item),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  _qtyButton(
                    icon: Icons.add,
                    bgColor: const Color(0xFF2E7D42),
                    iconColor: Colors.white,
                    onTap: () => _increment(item),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '$currencySymbol${item.totalPrice.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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

  // ─── Bottom Bar with Repeat KOT ──────────────────────────────────────────
  Widget _bottomKotBar(String currencySymbol) {
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
              onPressed: (!_hasAnyKots || _isRepeatingKot) ? null : _showRepeatKotDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primaryColor,
                side: BorderSide(color: ColorConstants.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isRepeatingKot
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: ColorConstants.primaryColor))
                  : const Text('Repeat KOT', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildCheckoutFooter(String currencySymbol) {
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
              Text(
                '$currencySymbol${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
              ),
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
                Text('Check Out', style: TextStyle(fontWeight: FontWeight.w600,fontSize:18)),
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