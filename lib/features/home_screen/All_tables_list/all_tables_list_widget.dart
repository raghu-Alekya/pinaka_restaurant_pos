// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:provider/provider.dart';
// import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
// import '../../../constants/color_constants.dart';
// import '../../bill_summary/bill_summary_domain/bill_summary_usecase.dart';
// import '../../printer/printer_service.dart';
// import '../../transfer_kot/transfer_kot_bottom_sheet.dart';
// import '../Zones/Zones_bloc/zone_state.dart';
// import '../Zones/Zones_bloc/zones_bloc.dart';
// import '../create_order/guest_count_bottom_sheet.dart';
// import '../order_menu/order_menu_screen.dart';
// import 'All_tables_list_bloc/all_tables_list_bloc.dart';
// import 'All_tables_list_bloc/all_tables_list_event.dart';
// import 'All_tables_list_bloc/all_tables_list_state.dart';
// import 'All_tables_list_domain/get_order_by_table_usecase.dart';
//
// typedef ZoneSectionKeyBuilder = GlobalKey Function(String zoneId);
//
// class AllTablesListWidget extends StatefulWidget {
//   final ScrollController scrollController;
//   final ZoneSectionKeyBuilder sectionKeyBuilder;
//   final ValueChanged<String>? onZoneVisible;
//
//   const AllTablesListWidget({
//     Key? key,
//     required this.scrollController,
//     required this.sectionKeyBuilder,
//     this.onZoneVisible,
//   }) : super(key: key);
//
//   @override
//   State<AllTablesListWidget> createState() => _AllTablesListWidgetState();
// }
//
// class _AllTablesListWidgetState extends State<AllTablesListWidget> {
//   final GlobalKey _viewportKey = GlobalKey();
//   List<dynamic> _orderedZones = [];
//   List<dynamic> _cachedTables = [];
//   bool _isSilentRefresh = false;
//
//   @override
//   void initState() {
//     super.initState();
//     widget.scrollController.addListener(_handleScroll);
//   }
//
//   @override
//   void dispose() {
//     widget.scrollController.removeListener(_handleScroll);
//     super.dispose();
//   }
//
//   void _handleScroll() {
//     if (_orderedZones.isEmpty) return;
//     const threshold = 24.0;
//
//     final viewportBox =
//     _viewportKey.currentContext?.findRenderObject() as RenderBox?;
//     if (viewportBox == null || !viewportBox.attached) return;
//     final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
//
//     String? visibleZoneId;
//     for (final zone in _orderedZones) {
//       final id = (zone.zoneId ?? '').toString();
//       final key = widget.sectionKeyBuilder(id);
//       final ctx = key.currentContext;
//       if (ctx == null) continue;
//       final box = ctx.findRenderObject() as RenderBox?;
//       if (box == null || !box.attached) continue;
//
//       final top = box.localToGlobal(Offset.zero).dy - viewportTop;
//       if (top <= threshold) {
//         visibleZoneId = id;
//       } else {
//         break;
//       }
//     }
//
//     if (visibleZoneId != null) {
//       widget.onZoneVisible?.call(visibleZoneId);
//     }
//   }
//
//   // ─── Silent Refresh ───
//   void _refreshSilently() {
//     _isSilentRefresh = true;
//     context.read<AllTablesBloc>().add(FetchAllTables());
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ZoneBloc, ZoneState>(
//       builder: (context, zoneState) {
//         final zones = zoneState is ZoneLoaded ? zoneState.zones : <dynamic>[];
//         _orderedZones = zones;
//
//         return BlocConsumer<AllTablesBloc, AllTablesState>(
//           listener: (context, state) {
//             if (state is AllTablesError) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(state.message),
//                   backgroundColor: ColorConstants.errorColor,
//                 ),
//               );
//             }
//             if (state is AllTablesLoaded) {
//               _isSilentRefresh = false;
//               _cachedTables = state.tables;
//             }
//           },
//           builder: (context, tableState) {
//             // If silent refresh is in progress, use cached tables
//             final allTables = (tableState is AllTablesLoaded)
//                 ? tableState.tables
//                 : _cachedTables;
//
//             if (allTables.isNotEmpty && zones.isNotEmpty) {
//               final Map<String, List<dynamic>> tablesByZone = {};
//               for (final table in allTables) {
//                 final key = (table.zoneId ?? '').toString();
//                 tablesByZone.putIfAbsent(key, () => []).add(table);
//               }
//
//               final zonesWithTables = zones
//                   .where((z) =>
//               (tablesByZone[(z.zoneId ?? '').toString()] ?? []).isNotEmpty)
//                   .toList();
//
//               if (zonesWithTables.isEmpty) {
//                 return const Center(
//                   child: Text('No tables found.', style: TextStyle(color: Colors.grey)),
//                 );
//               }
//
//               return Container(
//                 key: _viewportKey,
//                 child: ListView.builder(
//                   controller: widget.scrollController,
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   itemCount: zonesWithTables.length,
//                   itemBuilder: (context, index) {
//                     final zone = zonesWithTables[index];
//                     final zoneId = (zone.zoneId ?? '').toString();
//                     final tables = tablesByZone[zoneId] ?? [];
//
//                     return Container(
//                       key: widget.sectionKeyBuilder(zoneId),
//                       padding: const EdgeInsets.only(bottom: 20),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '${zone.zoneName ?? 'Unnamed'} :',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           GridView.builder(
//                             shrinkWrap: true,
//                             physics: const NeverScrollableScrollPhysics(),
//                             gridDelegate:
//                             const SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 3,
//                               crossAxisSpacing: 12,
//                               mainAxisSpacing: 12,
//                               childAspectRatio: 0.95,
//                             ),
//                             itemCount: tables.length,
//                             itemBuilder: (context, i) {
//                               final table = tables[i];
//                               final status =
//                               (table.status ?? 'Available').toString();
//
//                               final guestCount = _tryDynamic<int>(
//                                     () => table.guestCount as int,
//                               );
//                               final orderTotal = _tryDynamic<double>(
//                                     () => (table.orderTotal as num).toDouble(),
//                               );
//                               final orderStartedAt = _tryDynamic<DateTime>(
//                                     () => table.orderStartedAt as DateTime,
//                               );
//
//                               return _TableCard(
//                                 tableId: table.tableId ?? 0,
//                                 tableName: table.tableName ?? 'Unnamed',
//                                 zoneId: table.zoneId ?? 0,
//                                 zoneName: zone.zoneName ?? 'Unnamed',
//                                 restaurantId: table.restaurantId ?? 1,
//                                 status: status,
//                                 orderId: table.orderId,
//                                 guestCount: guestCount,
//                                 orderTotal: orderTotal,
//                                 orderStartedAt: orderStartedAt,
//                                 onOrderAction: _refreshSilently, // 👈 Pass callback
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               );
//             }
//
//             // Show loading only if not silent refresh and no cached data
//             if (tableState is AllTablesLoading && !_isSilentRefresh) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.error_outline, size: 64, color: Colors.grey),
//                   const SizedBox(height: 16),
//                   const Text('Unable to load tables.'),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
//
// T? _tryDynamic<T>(T Function() getter) {
//   try {
//     return getter();
//   } catch (_) {
//     return null;
//   }
// }
//
// // ─── Status handling ───
// enum _TableStatusKind { available, running, readyToSettle, occupied }
//
// _TableStatusKind _statusKind(String rawStatus) {
//   final s = rawStatus.toLowerCase().trim();
//   if (s == 'dine in' || s == 'dine-in' || s == 'running') {
//     return _TableStatusKind.running;
//   }
//   if (s == 'ready to pay' || s == 'ready to settle') {
//     return _TableStatusKind.readyToSettle;
//   }
//   if (s == 'occupied') {
//     return _TableStatusKind.occupied;
//   }
//   return _TableStatusKind.available;
// }
//
// String _statusLabel(_TableStatusKind kind) {
//   switch (kind) {
//     case _TableStatusKind.running:
//       return 'Running';
//     case _TableStatusKind.readyToSettle:
//       return 'Ready to Settle';
//     case _TableStatusKind.occupied:
//       return 'Occupied';
//     case _TableStatusKind.available:
//       return 'Available';
//   }
// }
//
// Color _statusColor(_TableStatusKind kind) {
//   switch (kind) {
//     case _TableStatusKind.running:
//       return const Color(0xFFE64545);
//     case _TableStatusKind.readyToSettle:
//       return const Color(0xFF3B7DDB);
//     case _TableStatusKind.occupied:
//       return const Color(0xFFE8B93A);
//     case _TableStatusKind.available:
//       return const Color(0xFF34A853);
//   }
// }
//
// String _formatElapsed(DateTime start) {
//   final diff = DateTime.now().difference(start);
//   if (diff.inHours > 0) {
//     return '${diff.inHours}h ${diff.inMinutes % 60}m';
//   }
//   if (diff.inMinutes > 0) {
//     return '${diff.inMinutes}m';
//   }
//   return 'Just now';
// }
//
// // ─── Dashed border painter ───
// class _DashedBorderPainter extends CustomPainter {
//   final Color color;
//   final double radius;
//   final double strokeWidth;
//   final double dashWidth;
//   final double dashGap;
//
//   _DashedBorderPainter({
//     required this.color,
//     this.radius = 14,
//     this.strokeWidth = 1.4,
//     this.dashWidth = 4,
//     this.dashGap = 3,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = strokeWidth
//       ..style = PaintingStyle.stroke;
//
//     final rrect = RRect.fromRectAndRadius(
//       Rect.fromLTWH(
//         strokeWidth / 2,
//         strokeWidth / 2,
//         size.width - strokeWidth,
//         size.height - strokeWidth,
//       ),
//       Radius.circular(radius),
//     );
//
//     final path = Path()..addRRect(rrect);
//     canvas.drawPath(_dashPath(path), paint);
//   }
//
//   Path _dashPath(Path source) {
//     final dashedPath = Path();
//     for (final metric in source.computeMetrics()) {
//       double distance = 0;
//       bool draw = true;
//       while (distance < metric.length) {
//         final len = draw ? dashWidth : dashGap;
//         final end = (distance + len).clamp(0.0, metric.length);
//         if (draw) {
//           dashedPath.addPath(metric.extractPath(distance, end), Offset.zero);
//         }
//         distance += len;
//         draw = !draw;
//       }
//     }
//     return dashedPath;
//   }
//
//   @override
//   bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
//     return oldDelegate.color != color ||
//         oldDelegate.strokeWidth != strokeWidth ||
//         oldDelegate.radius != radius;
//   }
// }
//
// class _TableCard extends StatelessWidget {
//   final int tableId;
//   final String tableName;
//   final int zoneId;
//   final String zoneName;
//   final int restaurantId;
//   final String status;
//   final int? orderId;
//   final int? guestCount;
//   final double? orderTotal;
//   final DateTime? orderStartedAt;
//   final VoidCallback onOrderAction; // 👈 Callback to refresh after order action
//
//   const _TableCard({
//     required this.tableId,
//     required this.tableName,
//     required this.zoneId,
//     required this.zoneName,
//     required this.restaurantId,
//     required this.status,
//     this.orderId,
//     this.guestCount,
//     this.orderTotal,
//     this.orderStartedAt,
//     required this.onOrderAction,
//   });
//
//   bool get _isAvailable => _statusKind(status) == _TableStatusKind.available;
//
//   @override
//   Widget build(BuildContext context) {
//     final kind = _statusKind(status);
//     final isAvailable = kind == _TableStatusKind.available;
//     final color = _statusColor(kind);
//     final label = _statusLabel(kind);
//     final elapsed = orderStartedAt != null ? _formatElapsed(orderStartedAt!) : null;
//
//     return GestureDetector(
//       onTap: () => _handleTap(context),
//       onLongPress: isAvailable
//           ? null
//           : () {
//         HapticFeedback.mediumImpact();
//         _showTableActionsSheet(context);
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: isAvailable ? Border.all(color: color.withOpacity(0.5)) : null,
//         ),
//         child: CustomPaint(
//           painter: isAvailable ? null : _DashedBorderPainter(color: color),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Row(
//                   mainAxisAlignment:
//                   isAvailable ? MainAxisAlignment.end : MainAxisAlignment.start,
//                   children: [
//                     if (!isAvailable) ...[
//                       Icon(Icons.person_outline, size: 13, color: color),
//                       const SizedBox(width: 2),
//                     ],
//                     Text(
//                       tableName,
//                       style: TextStyle(
//                         color: color,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 if (isAvailable)
//                   Icon(Icons.table_restaurant_outlined, color: color, size: 34)
//                 else if (orderTotal != null)
//                   Text(
//                     '\$${orderTotal!.toStringAsFixed(2)}',
//                     style: TextStyle(
//                       color: color,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                     ),
//                   )
//                 else
//                   Icon(Icons.table_restaurant, color: color, size: 28),
//                 if (!isAvailable && elapsed != null) ...[
//                   const SizedBox(height: 2),
//                   Text(
//                     elapsed,
//                     style: TextStyle(fontSize: 10, color: color.withOpacity(0.85)),
//                   ),
//                 ],
//                 const SizedBox(height: 4),
//                 Text(
//                   label,
//                   style: TextStyle(
//                     color: color,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ─── Tap Handler (with refresh after navigation) ───
//   Future<void> _handleTap(BuildContext context) async {
//     if (_isAvailable) {
//       // Available → show guest count bottom sheet
//       final captainStorage = context.read<CaptainLocalStorage>();
//       captainStorage.getCaptainData().then((captainData) async {
//         final restaurantName =
//             captainData?.data?.restaurantName ?? 'My Restaurant';
//         if (!context.mounted) return;
//         // Show bottom sheet and wait for it to close
//         await _showGuestBottomSheet(
//           context,
//           tableId: tableId,
//           tableName: tableName,
//           zoneId: zoneId,
//           zoneName: zoneName,
//           restaurantId: restaurantId,
//           restaurantName: restaurantName,
//         );
//         // After bottom sheet closes, refresh tables silently
//         if (context.mounted) onOrderAction.call();
//       });
//       return;
//     }
//
//     // Occupied/Running/etc → fetch order and navigate to OrderMenuScreen
//     try {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Fetching order details...'),
//           duration: Duration(seconds: 1),
//         ),
//       );
//
//       final useCase = context.read<GetOrderByTableUseCase>();
//       final orderData = await useCase(
//         restaurantId: restaurantId,
//         tableId: tableId,
//         zoneId: zoneId,
//       );
//
//       if (!context.mounted) return;
//
//       // Navigate to OrderMenuScreen and wait for it to close
//       await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => OrderMenuScreen(
//             orderId: orderData.orderId,
//             tableName: tableName,
//             orderType: orderData.orderType,
//             restaurantId: restaurantId,
//             zoneId: zoneId,
//           ),
//         ),
//       );
//
//       // After returning, refresh tables silently
//       if (context.mounted) onOrderAction.call();
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to load order: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   // ─── Long-press bottom sheet ───
//   void _showTableActionsSheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (sheetContext) {
//         return Container(
//           padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Table No $tableName',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () => Navigator.of(sheetContext).pop(),
//                     child: Container(
//                       width: 26,
//                       height: 26,
//                       decoration: const BoxDecoration(
//                         color: Color(0xFFE64545),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(Icons.close, size: 16, color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _sheetActionTile(
//                       icon: Icons.receipt_long_outlined,
//                       label: "View KOT's",
//                       color: const Color(0xFF2E7D42),
//                       onTap: () {
//                         Navigator.of(sheetContext).pop();
//                         _handleTap(context);
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _sheetActionTile(
//                       icon: Icons.compare_arrows_rounded,
//                       label: 'Transfer KOT',
//                       color: const Color(0xFF3B7DDB),
//                       onTap: () {
//                         Navigator.of(sheetContext).pop();
//                         _showTransferKotSheet(context);
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               _sheetActionTile(
//                 icon: Icons.print_outlined,
//                 label: 'Print Bill',
//                 color: ColorConstants.primaryColor,
//                 fullWidth: true,
//                 onTap: () {
//                   Navigator.of(sheetContext).pop();
//                   _printBill(context);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   // ─── Print Bill ───
//   Future<void> _printBill(BuildContext context) async {
//     int? activeOrderId = orderId;
//
//     if (activeOrderId == null || activeOrderId == 0) {
//       try {
//         final orderUseCase = context.read<GetOrderByTableUseCase>();
//         final orderData = await orderUseCase(
//           restaurantId: restaurantId,
//           tableId: tableId,
//           zoneId: zoneId,
//         );
//         activeOrderId = orderData.orderId;
//       } catch (e) {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to fetch order details: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//     }
//
//     if (activeOrderId == null || activeOrderId == 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No active order found for this table.'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }
//
//     try {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Generating bill...'),
//           duration: Duration(seconds: 1),
//         ),
//       );
//
//       final useCase = context.read<BillSummaryUseCase>();
//       final billData = await useCase(
//         orderId: activeOrderId,
//         restaurantId: restaurantId,
//         orderType: 'Dine In',
//         zoneId: zoneId,
//       );
//
//       if (!context.mounted) return;
//
//       final items = billData.lineItems.map((item) {
//         return {
//           'name': item.name,
//           'qty': item.qty,
//           'price': item.price,
//           'amount': item.total,
//           'modifiers': item.modifiers.map((m) => m.toString()).toList(),
//         };
//       }).toList();
//
//       await Printer.printBill(
//         orderId: billData.orderId.toString(),
//         tableName: billData.tableName,
//         cashierName: 'Captain',
//         items: items,
//         grossTotal: billData.grossTotal,
//         couponDiscount: billData.couponTotal,
//         merchantDiscount: billData.merchantDiscount,
//         tipAmount: billData.tip,
//         taxAmount: billData.tax,
//         serviceCharge: billData.serviceChargeValue,
//         netPayable: billData.netTotal,
//         context: context,
//       );
//
//       if (!context.mounted) return;
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   const SnackBar(
//       //     content: Text('Bill printed successfully'),
//       //     backgroundColor: Colors.green,
//       //   ),
//       // );
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to print bill: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Widget _sheetActionTile({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//     bool fullWidth = false,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: fullWidth ? double.infinity : null,
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.06),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: color.withOpacity(0.4)),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: color, size: 22),
//             const SizedBox(height: 6),
//             Text(
//               label,
//               style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ─── Guest count bottom sheet (updated to be awaitable) ───
//   Future<void> _showGuestBottomSheet(
//       BuildContext context, {
//         required int tableId,
//         required String tableName,
//         required int zoneId,
//         required String zoneName,
//         required int restaurantId,
//         required String restaurantName,
//       }) async {
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => GuestCountBottomSheet(
//         tableId: tableId,
//         tableName: tableName,
//         zoneId: zoneId,
//         zoneName: zoneName,
//         restaurantId: restaurantId,
//         restaurantName: restaurantName,
//       ),
//     );
//   }
//
//   Future<void> _showTransferKotSheet(BuildContext context) async {
//     int? activeOrderId = orderId;
//
//     if (activeOrderId == null || activeOrderId == 0) {
//       try {
//         final orderUseCase = context.read<GetOrderByTableUseCase>();
//         final orderData = await orderUseCase(
//           restaurantId: restaurantId,
//           tableId: tableId,
//           zoneId: zoneId,
//         );
//         activeOrderId = orderData.orderId;
//       } catch (e) {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to fetch order details: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//     }
//
//     if (activeOrderId == null || activeOrderId == 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No active order found for this table.'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => TransferKotBottomSheet(
//         orderId: activeOrderId!,
//         fromTableId: tableId,
//         restaurantId: restaurantId,
//         zoneId: zoneId,
//         onSuccess: onOrderAction,
//       ),
//     );
//   }
// }

//////=====


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../../constants/color_constants.dart';
import '../../bill_summary/bill_summary_domain/bill_summary_usecase.dart';
import '../../printer/printer_service.dart';
import '../../transfer_kot/transfer_kot_bottom_sheet.dart';
import '../Zones/Zones_bloc/zone_state.dart';
import '../Zones/Zones_bloc/zones_bloc.dart';
import '../cart_screen.dart';
import '../create_order/guest_count_bottom_sheet.dart';
import '../order_menu/order_menu_screen.dart';
import 'All_tables_list_bloc/all_tables_list_bloc.dart';
import 'All_tables_list_bloc/all_tables_list_event.dart';
import 'All_tables_list_bloc/all_tables_list_state.dart';
import 'All_tables_list_domain/get_order_by_table_usecase.dart';

typedef ZoneSectionKeyBuilder = GlobalKey Function(String zoneId);

class AllTablesListWidget extends StatefulWidget {
  final ScrollController scrollController;
  final ZoneSectionKeyBuilder sectionKeyBuilder;
  final ValueChanged<String>? onZoneVisible;

  const AllTablesListWidget({
    Key? key,
    required this.scrollController,
    required this.sectionKeyBuilder,
    this.onZoneVisible,
  }) : super(key: key);

  @override
  State<AllTablesListWidget> createState() => _AllTablesListWidgetState();
}

class _AllTablesListWidgetState extends State<AllTablesListWidget> {
  final GlobalKey _viewportKey = GlobalKey();
  List<dynamic> _orderedZones = [];
  List<dynamic> _cachedTables = [];
  bool _isSilentRefresh = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (_orderedZones.isEmpty) return;
    const threshold = 24.0;

    final viewportBox =
    _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.attached) return;
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;

    String? visibleZoneId;
    for (final zone in _orderedZones) {
      final id = (zone.zoneId ?? '').toString();
      final key = widget.sectionKeyBuilder(id);
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      final top = box.localToGlobal(Offset.zero).dy - viewportTop;
      if (top <= threshold) {
        visibleZoneId = id;
      } else {
        break;
      }
    }

    if (visibleZoneId != null) {
      widget.onZoneVisible?.call(visibleZoneId);
    }
  }

  // ─── Silent Refresh ───
  void _refreshSilently() {
    _isSilentRefresh = true;
    context.read<AllTablesBloc>().add(FetchAllTables());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZoneBloc, ZoneState>(
      builder: (context, zoneState) {
        final zones = zoneState is ZoneLoaded ? zoneState.zones : <dynamic>[];
        _orderedZones = zones;

        return BlocConsumer<AllTablesBloc, AllTablesState>(
          listener: (context, state) {
            if (state is AllTablesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: ColorConstants.errorColor,
                ),
              );
            }
            if (state is AllTablesLoaded) {
              _isSilentRefresh = false;
              _cachedTables = state.tables;
            }
          },
          builder: (context, tableState) {
            // If silent refresh is in progress, use cached tables
            final allTables = (tableState is AllTablesLoaded)
                ? tableState.tables
                : _cachedTables;

            if (allTables.isNotEmpty && zones.isNotEmpty) {
              final Map<String, List<dynamic>> tablesByZone = {};
              for (final table in allTables) {
                final key = (table.zoneId ?? '').toString();
                tablesByZone.putIfAbsent(key, () => []).add(table);
              }

              final zonesWithTables = zones
                  .where((z) =>
              (tablesByZone[(z.zoneId ?? '').toString()] ?? []).isNotEmpty)
                  .toList();

              if (zonesWithTables.isEmpty) {
                return const Center(
                  child: Text('No tables found.', style: TextStyle(color: Colors.grey)),
                );
              }

              return Container(
                key: _viewportKey,
                child: ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: zonesWithTables.length,
                  itemBuilder: (context, index) {
                    final zone = zonesWithTables[index];
                    final zoneId = (zone.zoneId ?? '').toString();
                    final tables = tablesByZone[zoneId] ?? [];

                    return Container(
                      key: widget.sectionKeyBuilder(zoneId),
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${zone.zoneName ?? 'Unnamed'} :',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: tables.length,
                            itemBuilder: (context, i) {
                              final table = tables[i];
                              final status =
                              (table.status ?? 'Available').toString();

                              final guestCount = _tryDynamic<int>(
                                    () => table.guestCount as int,
                              );
                              final orderTotal = _tryDynamic<double>(
                                    () => (table.orderTotal as num).toDouble(),
                              );
                              final orderStartedAt = _tryDynamic<DateTime>(
                                    () => table.orderStartedAt as DateTime,
                              );

                              return _TableCard(
                                tableId: table.tableId ?? 0,
                                tableName: table.tableName ?? 'Unnamed',
                                zoneId: table.zoneId ?? 0,
                                zoneName: zone.zoneName ?? 'Unnamed',
                                restaurantId: table.restaurantId ?? 1,
                                status: status,
                                orderId: table.orderId,
                                guestCount: guestCount,
                                orderTotal: orderTotal,
                                orderStartedAt: orderStartedAt,
                                onOrderAction: _refreshSilently,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }

            // Show loading only if not silent refresh and no cached data
            if (tableState is AllTablesLoading && !_isSilentRefresh) {
              return const Center(child: CircularProgressIndicator());
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Unable to load tables.'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

T? _tryDynamic<T>(T Function() getter) {
  try {
    return getter();
  } catch (_) {
    return null;
  }
}

// ─── Status handling ───
enum _TableStatusKind { available, running, readyToSettle, occupied }

_TableStatusKind _statusKind(String rawStatus) {
  final s = rawStatus.toLowerCase().trim();
  if (s == 'dine in' || s == 'dine-in' || s == 'running') {
    return _TableStatusKind.running;
  }
  if (s == 'ready to pay' || s == 'ready to settle') {
    return _TableStatusKind.readyToSettle;
  }
  if (s == 'occupied') {
    return _TableStatusKind.occupied;
  }
  return _TableStatusKind.available;
}

String _statusLabel(_TableStatusKind kind) {
  switch (kind) {
    case _TableStatusKind.running:
      return 'Running';
    case _TableStatusKind.readyToSettle:
      return 'Ready to Settle';
    case _TableStatusKind.occupied:
      return 'Occupied';
    case _TableStatusKind.available:
      return 'Available';
  }
}

Color _statusColor(_TableStatusKind kind) {
  switch (kind) {
    case _TableStatusKind.running:
      return const Color(0xFFE64545);
    case _TableStatusKind.readyToSettle:
      return const Color(0xFF3B7DDB);
    case _TableStatusKind.occupied:
      return const Color(0xFFE8B93A);
    case _TableStatusKind.available:
      return const Color(0xFF34A853);
  }
}

String _formatElapsed(DateTime start) {
  final diff = DateTime.now().difference(start);
  if (diff.inHours > 0) {
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }
  if (diff.inMinutes > 0) {
    return '${diff.inMinutes}m';
  }
  return 'Just now';
}

// ─── Dashed border painter ───
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  _DashedBorderPainter({
    required this.color,
    this.radius = 14,
    this.strokeWidth = 1.4,
    this.dashWidth = 4,
    this.dashGap = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    canvas.drawPath(_dashPath(path), paint);
  }

  Path _dashPath(Path source) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashWidth : dashGap;
        final end = (distance + len).clamp(0.0, metric.length);
        if (draw) {
          dashedPath.addPath(metric.extractPath(distance, end), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

class _TableCard extends StatelessWidget {
  final int tableId;
  final String tableName;
  final int zoneId;
  final String zoneName;
  final int restaurantId;
  final String status;
  final int? orderId;
  final int? guestCount;
  final double? orderTotal;
  final DateTime? orderStartedAt;
  final VoidCallback onOrderAction;

  const _TableCard({
    required this.tableId,
    required this.tableName,
    required this.zoneId,
    required this.zoneName,
    required this.restaurantId,
    required this.status,
    this.orderId,
    this.guestCount,
    this.orderTotal,
    this.orderStartedAt,
    required this.onOrderAction,
  });

  bool get _isAvailable => _statusKind(status) == _TableStatusKind.available;

  @override
  Widget build(BuildContext context) {
    final kind = _statusKind(status);
    final isAvailable = kind == _TableStatusKind.available;
    final color = _statusColor(kind);
    final label = _statusLabel(kind);
    final elapsed = orderStartedAt != null ? _formatElapsed(orderStartedAt!) : null;

    return GestureDetector(
      onTap: () => _handleTap(context),
      onLongPress: isAvailable
          ? null
          : () {
        HapticFeedback.mediumImpact();
        _showTableActionsSheet(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isAvailable ? Border.all(color: color.withOpacity(0.5)) : null,
        ),
        child: CustomPaint(
          painter: isAvailable ? null : _DashedBorderPainter(color: color),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // children: [
              //   Row(
              //     mainAxisAlignment:
              //     isAvailable ? MainAxisAlignment.end : MainAxisAlignment.start,
              //     children: [
              //       if (!isAvailable) ...[
              //         Icon(Icons.person_outline, size: 13, color: color),
              //         const SizedBox(width: 2),
              //       ],
              //       Text(
              //         tableName,
              //         style: TextStyle(
              //           color: color,
              //           fontWeight: FontWeight.bold,
              //           fontSize: 14,
              //         ),
              //       ),
              //     ],
              //   ),
              //   const SizedBox(height: 4),
              //   if (isAvailable)
              //     Icon(Icons.table_restaurant_outlined, color: color, size: 34)
              //   else if (orderTotal != null)
              //     Text(
              //       '\$${orderTotal!.toStringAsFixed(2)}',
              //       style: TextStyle(
              //         color: color,
              //         fontWeight: FontWeight.bold,
              //         fontSize: 14,
              //       ),
              //     )
              //   else
              //     Icon(Icons.table_restaurant, color: color, size: 28),
              //   if (!isAvailable && elapsed != null) ...[
              //     const SizedBox(height: 2),
              //     Text(
              //       elapsed,
              //       style: TextStyle(fontSize: 10, color: color.withOpacity(0.85)),
              //     ),
              //   ],
              //   const SizedBox(height: 4),
              //   Text(
              //     label,
              //     style: TextStyle(
              //       color: color,
              //       fontSize: 12,
              //       fontWeight: FontWeight.w500,
              //     ),
              //   ),
              // ],

              // ─── Inside the Column of _TableCard ───
              children: [
                Row(
                  mainAxisAlignment:
                  isAvailable ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isAvailable) ...[
                      Icon(Icons.person_outline, size: 13, color: color),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      tableName,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // ─── Table image instead of icon ───
                if (isAvailable)
                  Image.asset(
                    'assets/images/Table_img.png',
                    width: 34,
                    height: 34,
                    color: color, // tints the image with status color
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.table_restaurant_outlined,
                      color: color,
                      size: 34,
                    ),
                  )
                else if (orderTotal != null)
                  Text(
                    '\$${orderTotal!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                else
                  Image.asset(
                    'assets/images/Table_img.png',
                    width: 28,
                    height: 28,
                    color: color,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.table_restaurant,
                      color: color,
                      size: 28,
                    ),
                  ),

                if (!isAvailable && elapsed != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    elapsed,
                    style: TextStyle(fontSize: 10, color: color.withOpacity(0.85)),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ─── Navigate to Cart (View KOT's) ──────────────────────────────────
  Future<void> _navigateToCart(BuildContext context) async {
    int? activeOrderId = orderId;

    // If we already have an orderId, navigate instantly
    if (activeOrderId != null && activeOrderId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CartScreen(
            cartItems: [],
            orderId: activeOrderId!,
            tableName: tableName,
            orderType: 'Dine In',
            restaurantId: restaurantId,
            zoneId: zoneId,
            onIncrement: (_) {},
            onDecrement: (_) {},
            onClearCart: () {},
          ),
        ),
      );
      return;
    }

    // If no orderId, fetch it (with loading indicator)
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fetching order details...'),
          duration: Duration(seconds: 1),
        ),
      );

      final orderUseCase = context.read<GetOrderByTableUseCase>();
      final orderData = await orderUseCase(
        restaurantId: restaurantId,
        tableId: tableId,
        zoneId: zoneId,
      );
      activeOrderId = orderData.orderId;

      if (!context.mounted) return;

      if (activeOrderId > 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CartScreen(
              cartItems: [],
              orderId: activeOrderId!,
              tableName: tableName,
              orderType: 'Dine In',
              restaurantId: restaurantId,
              zoneId: zoneId,
              onIncrement: (_) {},
              onDecrement: (_) {},
              onClearCart: () {},
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active order found for this table.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch order details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── Tap Handler ─────────────────────────────────────────────────────
  Future<void> _handleTap(BuildContext context) async {
    if (_isAvailable) {
      final captainStorage = context.read<CaptainLocalStorage>();
      captainStorage.getCaptainData().then((captainData) async {
        final restaurantName =
            captainData?.data?.restaurantName ?? 'My Restaurant';
        if (!context.mounted) return;
        await _showGuestBottomSheet(
          context,
          tableId: tableId,
          tableName: tableName,
          zoneId: zoneId,
          zoneName: zoneName,
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        );
        // After guest count bottom sheet (new order created), refresh tables
        if (context.mounted) onOrderAction.call();
      });
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fetching order details...'),
          duration: Duration(seconds: 1),
        ),
      );

      final useCase = context.read<GetOrderByTableUseCase>();
      final orderData = await useCase(
        restaurantId: restaurantId,
        tableId: tableId,
        zoneId: zoneId,
      );

      if (!context.mounted) return;

      // Navigate to OrderMenuScreen and wait for a result.
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OrderMenuScreen(
            orderId: orderData.orderId,
            tableName: tableName,
            orderType: orderData.orderType,
            restaurantId: restaurantId,
            zoneId: zoneId,
          ),
        ),
      );

      // Only refresh if the order was modified (result == true)
      if (context.mounted && result == true) {
        onOrderAction.call();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── Long-press bottom sheet ────────────────────────────────────────
  void _showTableActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Table No $tableName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE64545),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _sheetActionTile(
                      icon: Icons.receipt_long_outlined,
                      label: "View KOT's",
                      color: const Color(0xFF2E7D42),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _navigateToCart(context); // 👈 now goes to Cart
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sheetActionTile(
                      icon: Icons.compare_arrows_rounded,
                      label: 'Transfer KOT',
                      color: const Color(0xFF3B7DDB),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _showTransferKotSheet(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _sheetActionTile(
                icon: Icons.print_outlined,
                label: 'Print Bill',
                color: ColorConstants.primaryColor,
                fullWidth: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _printBill(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Print Bill ───
  Future<void> _printBill(BuildContext context) async {
    int? activeOrderId = orderId;

    if (activeOrderId == null || activeOrderId == 0) {
      try {
        final orderUseCase = context.read<GetOrderByTableUseCase>();
        final orderData = await orderUseCase(
          restaurantId: restaurantId,
          tableId: tableId,
          zoneId: zoneId,
        );
        activeOrderId = orderData.orderId;
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch order details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (activeOrderId == null || activeOrderId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active order found for this table.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating bill...'),
          duration: Duration(seconds: 1),
        ),
      );

      final useCase = context.read<BillSummaryUseCase>();
      final billData = await useCase(
        orderId: activeOrderId,
        restaurantId: restaurantId,
        orderType: 'Dine In',
        zoneId: zoneId,
      );

      if (!context.mounted) return;

      final items = billData.lineItems.map((item) {
        return {
          'name': item.name,
          'qty': item.qty,
          'price': item.price,
          'amount': item.total,
          'modifiers': item.modifiers.map((m) => m.toString()).toList(),
        };
      }).toList();

      await Printer.printBill(
        orderId: billData.orderId.toString(),
        tableName: billData.tableName,
        cashierName: 'Captain',
        items: items,
        grossTotal: billData.grossTotal,
        couponDiscount: billData.couponTotal,
        merchantDiscount: billData.merchantDiscount,
        tipAmount: billData.tip,
        taxAmount: billData.tax,
        serviceCharge: billData.serviceChargeValue,
        netPayable: billData.netTotal,
        context: context,
      );

      if (!context.mounted) return;
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to print bill: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _sheetActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Guest count bottom sheet ──────────────────────────────────────
  Future<void> _showGuestBottomSheet(
      BuildContext context, {
        required int tableId,
        required String tableName,
        required int zoneId,
        required String zoneName,
        required int restaurantId,
        required String restaurantName,
      }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GuestCountBottomSheet(
        tableId: tableId,
        tableName: tableName,
        zoneId: zoneId,
        zoneName: zoneName,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      ),
    );
  }

  // ─── Transfer KOT ───────────────────────────────────────────────────
  Future<void> _showTransferKotSheet(BuildContext context) async {
    int? activeOrderId = orderId;

    if (activeOrderId == null || activeOrderId == 0) {
      try {
        final orderUseCase = context.read<GetOrderByTableUseCase>();
        final orderData = await orderUseCase(
          restaurantId: restaurantId,
          tableId: tableId,
          zoneId: zoneId,
        );
        activeOrderId = orderData.orderId;
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch order details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (activeOrderId == null || activeOrderId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active order found for this table.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransferKotBottomSheet(
        orderId: activeOrderId!,
        fromTableId: tableId,
        restaurantId: restaurantId,
        zoneId: zoneId,
        onSuccess: onOrderAction,
      ),
    );
  }
}