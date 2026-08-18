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
//       Navigator.pop(context);
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   const SnackBar(content: Text('KOT printed successfully'), backgroundColor: Colors.green),
//       // );
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
//               onPressed: cartItems.isEmpty ? null : () {},
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
  bool _isRepeatingKot = false; // loading state for Repeat KOT
  bool _hasPrintedKot = false;
  bool _hasAnyKots = false;
  late final StreamSubscription<KotsListState> _kotsSubscription;
  final ValueNotifier<String> _currencySymbolNotifier = ValueNotifier<String>('\$');

  @override
  void initState() {
    super.initState();
    cartItems = List.from(widget.cartItems);
    _loadCurrencySymbol();

    final kotsBloc = context.read<KotsListBloc>();

    if (kotsBloc.state is KotsListLoaded && (kotsBloc.state as KotsListLoaded).kots.isNotEmpty) {
      _hasAnyKots = true;
    }

    _kotsSubscription = kotsBloc.stream.listen((state) {
      if (state is KotsListLoaded && mounted) {
        setState(() {
          _hasAnyKots = state.kots.isNotEmpty;
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

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print KOT: $e'), backgroundColor: Colors.red),
      );
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
                // Warning icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0), // light orange background
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFFA000), // amber/orange
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'Repeat KOT?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),

                // Message
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

                // Buttons
                Row(
                  children: [
                    // Cancel button (outlined)
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

                    // Confirm button (filled)
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

      final response = await http.post(
        Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/repeat-kot-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': widget.orderId,
          'restaurant_id': widget.restaurantId,
          'zone_id': widget.zoneId,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Repeat KOT failed (${response.statusCode}): ${response.body}');
      }

      // Refresh the KOT list after successful repeat
      context.read<KotsListBloc>().add(
        FetchKotsList(
          parentOrderId: widget.orderId,
          restaurantId: widget.restaurantId,
          zoneId: widget.zoneId,
        ),
      );

      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('KOT repeated successfully'), backgroundColor: Colors.green),
      //   );
      // }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to repeat KOT: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRepeatingKot = false);
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
                      _itemsCard(currencySymbol),
                    ],
                  ),
                ),
              ),
              _bottomKotBar(currencySymbol),
              _buildCheckoutFooter(currencySymbol),
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
              itemBuilder: (context, index) => _itemRow(cartItems[index], currencySymbol),
            ),
        ],
      ),
    );
  }

  Widget _itemRow(CartItem item, String currencySymbol) {
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
              '$currencySymbol${item.totalPrice.toStringAsFixed(2)}',
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
          // ── Repeat KOT Button ──
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
          // ── KOT Print Button ──
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