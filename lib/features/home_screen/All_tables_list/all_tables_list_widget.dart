import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../../../constants/color_constants.dart';
import '../../bill_summary/bill_summary_domain/bill_summary_usecase.dart';
import '../../mqtt_servers/captain_mqtt_publisher.dart';
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
  final String statusFilter;

  const AllTablesListWidget({
    Key? key,
    required this.scrollController,
    required this.sectionKeyBuilder,
    this.onZoneVisible,
    required this.statusFilter,
  }) : super(key: key);

  @override
  State<AllTablesListWidget> createState() => _AllTablesListWidgetState();
}

class _AllTablesListWidgetState extends State<AllTablesListWidget> {
  final GlobalKey _viewportKey = GlobalKey();
  List<dynamic> _orderedZones = [];
  List<dynamic> _cachedTables = [];
  bool _isSilentRefresh = false;
  String _currencySymbol = '';

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
    widget.scrollController.addListener(_handleScroll);
  }

  Future<void> _loadCurrencySymbol() async {
    try {
      final symbol = await context.read<CaptainLocalStorage>().getCurrencySymbol();
      if (symbol != null && mounted) {
        setState(() {
          _currencySymbol = symbol;
        });
        print('🪙 KotsListWidget currency symbol: $symbol');
      }
    } catch (_) {}
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
            final allTables = (tableState is AllTablesLoaded)
                ? tableState.tables
                : _cachedTables;

            // ─── Apply status filter ──────────────────────────────────────
            final filteredTables = widget.statusFilter == 'All'
                ? allTables
                : allTables.where((table) {
              final status = (table.status ?? '').toLowerCase();
              final filter = widget.statusFilter.toLowerCase();
              if (filter == 'available') return status == 'available';
              if (filter == 'occupied') return status == 'occupied';
              if (filter == 'running') return status == 'dine in' || status == 'running';
              if (filter == 'ready to pay') return status == 'ready to pay' || status == 'ready to settle';
              return true;
            }).toList();

            // ─── If no tables after filter, show empty state ────────────
            if (filteredTables.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_off, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tables match the selected filter.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // ─── Group filtered tables by zone ───────────────────────────
            if (allTables.isNotEmpty && zones.isNotEmpty) {
              final Map<String, List<dynamic>> tablesByZone = {};
              for (final table in filteredTables) { // 👈 now uses filteredTables
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
                              final orderStartedAt = _tryDynamic<DateTime>(
                                    () => table.orderStartedAt as DateTime,
                              );

                              double? orderAmountDouble;
                              if (table.orderAmount != null &&
                                  table.orderAmount.toString().isNotEmpty) {
                                orderAmountDouble = double.tryParse(
                                  table.orderAmount.toString().replaceAll(',', ''),
                                );
                              }

                              return _TableCard(
                                tableId: table.tableId ?? 0,
                                tableName: table.tableName ?? 'Unnamed',
                                zoneId: table.zoneId ?? 0,
                                zoneName: zone.zoneName ?? 'Unnamed',
                                restaurantId: table.restaurantId ?? 1,
                                status: status,
                                orderId: table.orderId,
                                guestCount: guestCount,
                                orderTotal: orderAmountDouble,
                                orderStartedAt: orderStartedAt,
                                onOrderAction: _refreshSilently,
                                currencySymbol: _currencySymbol,

                                // ─── ADD THESE ──────────────────────────────────────
                                isMerged: table.isMerged ?? false,
                                mergeRole: table.mergeRole,
                                childTableIds: table.childTableIds,
                                parentTableId: table.parentTableId,
                                mergedTables: table.mergedTables,
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

            // ─── Loading / error states ──────────────────────────────────
            if (tableState is AllTablesLoading && !_isSilentRefresh) {
              return const Center(
                child: CupertinoActivityIndicator(radius: 14),
              );
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

// ─── Status handling (unchanged) ──────────────────────────────────────
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
      return 'Ready to pay';
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

// ─── Dashed border painter (unchanged) ──────────────────────────────
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
  final String currencySymbol;

  // ─── NEW ────────────────────────────────────────────────
  final bool isMerged;
  final String? mergeRole;          // "parent" | "child"
  final List<String>? childTableIds;
  final int? parentTableId;
  final String? mergedTables;

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
    required this.currencySymbol,
    // ─── NEW ──────────────────────────────────────────────
    this.isMerged = false,
    this.mergeRole,
    this.childTableIds,
    this.parentTableId,
    this.mergedTables,
  });

  bool get _isAvailable =>
      _statusKind(status) == _TableStatusKind.available;

  String get _displayTableName {
    if (isMerged && mergedTables != null && mergedTables!.isNotEmpty) {
      return mergedTables!;
    }
    return tableName;
  }

// 👈 NEW: same "update generate bill status" API that BillSummaryScreen
// calls, added here so Print Bill (long-press sheet) also notifies the
// server / POS that this order's bill was generated.
  Future<void> _updateGenerateBillStatus(BuildContext context, int activeOrderId) async {
    try {
      final merchantStorage = context.read<MerchantLocalStorage>();
      final captainStorage = context.read<CaptainLocalStorage>();

      final baseUrl = await merchantStorage.getStoreBaseUrl();
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception('Failed to update bill status.');
      }

      final captainData = await captainStorage.getCaptainData();
      final token = captainData?.data?.token;
      if (token == null || token.isEmpty) {
        throw Exception('Captain token not found.');
      }

      final role = captainData?.data?.role ?? '';
      final captainId = captainData?.data?.id ?? 0;

      final url =
          '$baseUrl/wp-json/pinaka-restaurant-pos/v1/kot/update-generate-bill-status';

      final requestBody = {
        'order_id': activeOrderId,
        'restaurant_id': restaurantId,
        'role': role,
        'zone_id': zoneId,
        'captain_id': captainId,
      };

      debugPrint('===== [TableCard] UPDATE GENERATE BILL STATUS REQUEST =====');
      debugPrint('URL: $url');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('===== [TableCard] UPDATE GENERATE BILL STATUS RESPONSE =====');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[TableCard] Failed to update bill status: ${response.body}');
        return;
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        debugPrint('[TableCard] Bill status API returned success=false: ${data['message']}');
      }
    } catch (e) {
      // 👈 Fail silently — this must never block the actual bill printing flow.
      debugPrint('[TableCard] Error updating generate bill status: $e');
    }
  }
  @override
  Widget build(BuildContext context) {

//     final kind = _statusKind(status);
//     final isAvailable = kind == _TableStatusKind.available;
//     // final color = _statusColor(kind);
//
//     // ─── Child merged tables → force black color (any status) ────
//     Color color = _statusColor(kind);
//     if (isMerged && mergeRole?.toLowerCase() == 'child') {
//       color = Colors.black;   // ← always black for child tables
//     }
// // ────────────────────────────────────────────────────────────
//
//     final label = _statusLabel(kind);

    final kind = _statusKind(status);
    final isAvailable = kind == _TableStatusKind.available;

    Color color = _statusColor(kind);
    if (isMerged) {
      final role = mergeRole?.toLowerCase();
      if (role == 'child') {
        color = isAvailable ? Colors.grey : Colors.black;
      }
    }
    /////// ──────────────

    final label = _statusLabel(kind);

    final elapsed =
    orderStartedAt != null ? _formatElapsed(orderStartedAt!) : null;
    final hasOrderAmount = orderTotal != null && orderTotal! > 0;

    return GestureDetector(
      onTap: () => _handleTap(context),
      onLongPress: isAvailable
          ? null
          : () {
        HapticFeedback.mediumImpact();
        _showTableActionsSheet(context);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive image size based on actual card width.
          final cardWidth = constraints.maxWidth;

          final imageSize = (cardWidth * 0.25).clamp(
            28.0,
            42.0,
          );

          final smallImageSize = (cardWidth * 0.20).clamp(
            24.0,
            34.0,
          );

          return Container(
            // decoration: BoxDecoration(
            //   color: Colors.white,
            //   borderRadius: BorderRadius.circular(14),
            //   border: isAvailable
            //       ? Border.all(
            //     color: color.withOpacity(0.5),
            //   )
            //       : null,
            // ),
            // child: CustomPaint(
            //   painter: isAvailable
            //       ? null
            //       : _DashedBorderPainter(
            //     color: color,
            //   ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              // Merged tables always show a dashed border, even when
              // Available — solid border stays only for normal tables.
              border: (isAvailable && !isMerged)
                  ? Border.all(
                color: color.withOpacity(0.5),
              )
                  : null,
            ),
            child: CustomPaint(
              painter: (isAvailable && !isMerged)
                  ? null
                  : _DashedBorderPainter(
                color: color,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // Row(
                    //   mainAxisAlignment: isAvailable
                    //       ? MainAxisAlignment.end
                    //       : MainAxisAlignment.start,
                    //   children: [
                    //     if (!isAvailable) ...[
                    //       Icon(
                    //         Icons.person_outline,
                    //         size: 13,
                    //         color: color,
                    //       ),
                    //       const SizedBox(width: 2),
                    //     ],
                    //     Flexible(
                    //       child: Text(
                    //         tableName,
                    //         maxLines: 1,
                    //         overflow: TextOverflow.ellipsis,
                    //         style: TextStyle(
                    //           color: color,
                    //           fontWeight: FontWeight.bold,
                    //           fontSize: 14,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _displayTableName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // ─────────────────────────────────────
                    // Table image / Order total
                    // ─────────────────────────────────────
                    if (hasOrderAmount)
                      Text(
                        '$currencySymbol${orderTotal!.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    else if (isAvailable)
                      Image.asset(
                        'assets/images/Table_img.png',
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.contain,
                        color: color,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            Icons.table_restaurant_outlined,
                            color: color,
                            size: imageSize,
                          );
                        },
                      )
                    else
                      Image.asset(
                        'assets/images/Table_img.png',
                        width: smallImageSize,
                        height: smallImageSize,
                        fit: BoxFit.contain,
                        color: color,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            Icons.table_restaurant,
                            color: color,
                            size: smallImageSize,
                          );
                        },
                      ),

                    // ─────────────────────────────────────
                    // Elapsed time
                    // ─────────────────────────────────────
                    if (!isAvailable && elapsed != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        elapsed,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: color.withOpacity(0.85),
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),

                    // ─────────────────────────────────────
                    // Status
                    // ─────────────────────────────────────
                    // Text(
                    //   label,
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: TextStyle(
                    //     color: color,
                    //     fontSize: 12,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    // ─────────────────────────────────────
                    // Status (+ link icon for merged tables)
                    // ─────────────────────────────────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isMerged) ...[
                          const SizedBox(width: 3),
                          Icon(
                            Icons.link,
                            size: 12,
                            color: color,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Navigate to Cart / View KOT's
  // ─────────────────────────────────────────────────────────────

  Future<void> _navigateToCart(BuildContext context) async {
    int? activeOrderId = orderId;

    // If orderId already exists, navigate immediately.
    if (activeOrderId != null && activeOrderId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CartScreen(
            key: ValueKey('cart_${tableId}_$activeOrderId'), // 👈 added

            cartItems: [],
            orderId: activeOrderId!,
            tableName: tableName,
            orderType: 'Dine In',
            restaurantId: restaurantId,
            zoneId: zoneId,
            onIncrement: (_) {},
            onDecrement: (_) {},
            onClearCart: () {},
            onAddItems: (items) {},

          ),
        ),
      );
      return;
    }

    // Otherwise fetch order ID.
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fetching order details...'),
          duration: Duration(seconds: 1),
        ),
      );

      final orderUseCase =
      context.read<GetOrderByTableUseCase>();

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
              key: ValueKey('cart_${tableId}_$activeOrderId'),

              cartItems: [],
              orderId: activeOrderId!,
              tableName: tableName,
              orderType: 'Dine In',
              restaurantId: restaurantId,
              zoneId: zoneId,
              onIncrement: (_) {},
              onDecrement: (_) {},
              onClearCart: () {},
              onAddItems: (items) {

              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No active order found for this table.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to fetch order details: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Tap Handler
  // ─────────────────────────────────────────────────────────────

  Future<void> _handleTap(BuildContext context) async {
    // Available table
    // if (_isAvailable) {
    //   final captainStorage =
    //   context.read<CaptainLocalStorage>();
    //
    //   captainStorage.getCaptainData().then(
    //         (captainData) async {
    //       final restaurantName =
    //           captainData?.data?.restaurantName ??
    //               'My Restaurant';
    //
    //       if (!context.mounted) return;
    //
    //       await _showGuestBottomSheet(
    //         context,
    //         tableId: tableId,
    //         tableName: tableName,
    //         zoneId: zoneId,
    //         zoneName: zoneName,
    //         restaurantId: restaurantId,
    //         restaurantName: restaurantName,
    //       );
    //
    //       // Refresh tables after creating the order.
    //       if (context.mounted) {
    //         onOrderAction.call();
    //       }
    //     },
    //   );
    //
    //   return;
    // }
// Available table
//     if (_isAvailable) {
//       final captainStorage = context.read<CaptainLocalStorage>();
//
//       captainStorage.getCaptainData().then((captainData) async {
//         final restaurantName =
//             captainData?.data?.restaurantName ?? 'My Restaurant';
//
//         if (!context.mounted) return;
//
//         final didCreateOrder = await _showGuestBottomSheet(
//           context,
//           tableId: tableId,
//           tableName: tableName,
//           zoneId: zoneId,
//           zoneName: zoneName,
//           restaurantId: restaurantId,
//           restaurantName: restaurantName,
//         );
//
//         // Only refresh when an order was actually created
//         if (context.mounted && didCreateOrder) {
//           onOrderAction.call();
//         }
//       });
//
//       return;
//     }

    if (_isAvailable) {
      // ─── BLOCK child tables of a merge ────────────────────
      if (isMerged && mergeRole?.toLowerCase() == 'child') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mergedTables != null && mergedTables!.isNotEmpty
                  ? 'This table is part of merged group "$mergedTables". Please use the parent table to create an order.'
                  : 'This is a child table of a merged group. Please select the parent table to create an order.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      // ──────────────────────────────────────────────────────

      final captainStorage = context.read<CaptainLocalStorage>();

      captainStorage.getCaptainData().then((captainData) async {
        final restaurantName =
            captainData?.data?.restaurantName ?? 'My Restaurant';

        if (!context.mounted) return;

        final didCreateOrder = await _showGuestBottomSheet(
          context,
          tableId: tableId,
          tableName: tableName,
          zoneId: zoneId,
          zoneName: zoneName,
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        );

        // Only refresh when an order was actually created
        if (context.mounted && didCreateOrder) {
          onOrderAction.call();
        }
      });

      return;
    }

    // Occupied / other status
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fetching order details...'),
          duration: Duration(seconds: 1),
        ),
      );

      final useCase =
      context.read<GetOrderByTableUseCase>();

      final orderData = await useCase(
        restaurantId: restaurantId,
        tableId: tableId,
        zoneId: zoneId,
      );

      if (!context.mounted) return;

      // Navigate to OrderMenuScreen.
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

      // Refresh only when order was modified.
      if (context.mounted && result == true) {
        onOrderAction.call();
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load order: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Long Press Bottom Sheet
  // ─────────────────────────────────────────────────────────────

  void _showTableActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─────────────────────────────────
              // Header
              // ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Table No $tableName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE64545),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────────
              // View KOT + Transfer KOT
              // ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _sheetActionTile(
                      icon: Icons.receipt_long_outlined,
                      label: "View KOT's",
                      color: const Color(0xFF2E7D42),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _navigateToCart(context);
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

              // ─────────────────────────────────
              // Print Bill
              // ─────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────
  // Print Bill
  // ─────────────────────────────────────────────────────────────

  // Future<void> _printBill(BuildContext context) async {
  //   int? activeOrderId = orderId;
  //
  //   // Fetch order ID if necessary.
  //   if (activeOrderId == null || activeOrderId == 0) {
  //     try {
  //       final orderUseCase =
  //       context.read<GetOrderByTableUseCase>();
  //
  //       final orderData = await orderUseCase(
  //         restaurantId: restaurantId,
  //         tableId: tableId,
  //         zoneId: zoneId,
  //       );
  //
  //       activeOrderId = orderData.orderId;
  //     } catch (e) {
  //       if (!context.mounted) return;
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             'Failed to fetch order details: ${e.toString()}',
  //           ),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //
  //       return;
  //     }
  //   }
  //
  //   if (activeOrderId == null || activeOrderId == 0) {
  //     if (!context.mounted) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text(
  //           'No active order found for this table.',
  //         ),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //
  //     return;
  //   }
  //
  //   try {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Generating bill...'),
  //         duration: Duration(seconds: 1),
  //       ),
  //     );
  //
  //     final useCase =
  //     context.read<BillSummaryUseCase>();
  //
  //     final billData = await useCase(
  //       orderId: activeOrderId,
  //       restaurantId: restaurantId,
  //       orderType: 'Dine In',
  //       zoneId: zoneId,
  //     );
  //
  //     if (!context.mounted) return;
  //
  //     final items = billData.lineItems.map((item) {
  //       return {
  //         'name': item.name,
  //         'qty': item.qty,
  //         'price': item.price,
  //         'amount': item.total,
  //         'modifiers': item.modifiers
  //             .map((m) => m.toString())
  //             .toList(),
  //       };
  //     }).toList();
  //
  //     await Printer.printBill(
  //       orderId: billData.orderId.toString(),
  //       tableName: billData.tableName,
  //       cashierName: 'Captain',
  //       items: items,
  //       grossTotal: billData.grossTotal,
  //       couponDiscount: billData.couponTotal,
  //       merchantDiscount: billData.merchantDiscount,
  //       tipAmount: billData.tip,
  //       taxAmount: billData.tax,
  //       serviceCharge: billData.serviceChargeValue,
  //       netPayable: billData.netTotal,
  //       context: context,
  //     );
  //
  //     if (!context.mounted) return;
  //   } catch (e) {
  //     if (!context.mounted) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           'Failed to print bill: ${e.toString()}',
  //         ),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  Future<void> _printBill(BuildContext context) async {
    int? activeOrderId = orderId;

    // ─── 1. Resolve order ID ───────────────────────────────────────────────
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active order found for this table.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ─── 2. Show “Generating bill…” ────────────────────────────────────────
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verifying items… Generating bill…'),
        duration: Duration(seconds: 3),
      ),
    );

    // ─── 3. Fetch bill summary ─────────────────────────────────────────────
    try {
      final useCase = context.read<BillSummaryUseCase>();
      final billData = await useCase(
        orderId: activeOrderId,
        restaurantId: restaurantId,
        orderType: 'Dine In',
        zoneId: zoneId,
      );

      if (!context.mounted) return;

      // ─── 4. No items → hide previous snack + show only this one ──────────
      if (billData.lineItems.isEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // ← removes "Generating bill..."
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No order items found for this table. Cannot print bill.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // ─── 5. Has items → print ────────────────────────────────────────────
      final items = billData.lineItems.map((item) {
        return {
          'name': item.name,
          'qty': item.qty,
          'price': item.price,
          'amount': item.total,
          'modifiers': item.modifiers.map((m) => m.toString()).toList(),
        };
      }).toList();
      await _updateGenerateBillStatus(context, activeOrderId);
      // 🔥 Notify POS + other Captains → Ready to Pay
      unawaited(
        CaptainMqttPublisher.notifyBillGenerated(
          restaurantId: restaurantId.toString(),
          orderId: activeOrderId,
          orderType: 'Dine In',
          zoneId: zoneId,
          zoneName: zoneName,
          tableName: tableName,
          tableId: tableId.toString(),
          netTotal: orderTotal,
        ),
      );
      if (context.mounted) {
        onOrderAction.call();
      }
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
    } catch (e) {
      if (!context.mounted) return;
      debugPrint('════════════ PRINT BILL ERROR ═════════════');
      debugPrint('Error: $e');
      debugPrint('Error toString: ${e.toString()}');
      debugPrint('═══════════════════════════════════════════');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final errorMsg = e.toString().toLowerCase();
      final isNoPrinter = errorMsg.contains('no printer') ||
          errorMsg.contains('printer not') ||
          errorMsg.contains('not connected') ||
          errorMsg.contains('disconnected') ||
          errorMsg.contains('no device') ||
          errorMsg.contains('bluetooth') && errorMsg.contains('connect') ||
          errorMsg.contains('unable to connect') ||
          errorMsg.contains('connection failed');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNoPrinter
                ? 'No printer connected. Please connect a printer and try again.'
                : 'Failed to print bill Try it again',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Sheet Action Tile
  // ─────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.4),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Guest Count Bottom Sheet
  // ─────────────────────────────────────────────────────────────

  // Future<void> _showGuestBottomSheet(
  //     BuildContext context, {
  //       required int tableId,
  //       required String tableName,
  //       required int zoneId,
  //       required String zoneName,
  //       required int restaurantId,
  //       required String restaurantName,
  //     }) async {
  //   await showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(
  //         top: Radius.circular(20),
  //       ),
  //     ),
  //     builder: (context) => GuestCountBottomSheet(
  //       tableId: tableId,
  //       tableName: tableName,
  //       zoneId: zoneId,
  //       zoneName: zoneName,
  //       restaurantId: restaurantId,
  //       restaurantName: restaurantName,
  //     ),
  //   );
  // }

  Future<bool> _showGuestBottomSheet(
      BuildContext context, {
        required int tableId,
        required String tableName,
        required int zoneId,
        required String zoneName,
        required int restaurantId,
        required String restaurantName,
      }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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

    return result == true;
  }

  // ─────────────────────────────────────────────────────────────
  // Transfer KOT
  // ─────────────────────────────────────────────────────────────

  Future<void> _showTransferKotSheet(
      BuildContext context,
      ) async {
    int? activeOrderId = orderId;

    // Fetch order ID if not already available.
    if (activeOrderId == null || activeOrderId == 0) {
      try {
        final orderUseCase =
        context.read<GetOrderByTableUseCase>();

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
            content: Text(
              'Failed to fetch order details: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }
    }

    if (activeOrderId == null || activeOrderId == 0) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active order found for this table.',
          ),
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
