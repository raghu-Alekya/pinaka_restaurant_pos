import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/transer_kot.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/void_items.dart';
import '../../blocs/Bloc Event/kot_event.dart';
import '../../blocs/Bloc Event/void_item_evnts.dart';
import '../../blocs/Bloc Logic/auth_bloc.dart';
import '../../blocs/Bloc Logic/kot_bloc.dart';
import '../../blocs/Bloc Logic/transfer_kot_bloc.dart';
import '../../blocs/Bloc Logic/void_item_bloc.dart';
import '../../blocs/Bloc State/kot_state.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc State/order_list_state.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../blocs/Bloc State/void_item_state.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/void_kot_items.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/kot_repository.dart';
import '../../repositories/table_repository.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/SessionManager.dart';

const Color kHeaderBlue = Color(0xFF152148);
const Color kKotHeaderBg = Color(0xFFECEEFB);
const Color kCardBg = Color(0xFFF1F1F3);
const Color kDivider = Color(0xFFE6E6E6);
const Color kTotalBg = Color(0xFFFFE4B8);


class ViewAllKOTDropdown extends StatefulWidget {
  final int parentOrderId;
  final int restaurantId;
  final int zoneId;
  final String token;
  final String tableNo;
  final List<KotModel> kots; // ✅ ADD THIS
  // ✅ NEW: notifies the parent whenever this dropdown expands/collapses,
  // so the parent can hide/show its own order list accordingly.
  final ValueChanged<bool>? onToggle;

  const ViewAllKOTDropdown({
    super.key,
    required this.parentOrderId,
    required this.restaurantId,
    required this.zoneId,
    required this.tableNo,
    required this.token,
    required this.kots, // ✅ FIXED
    this.onToggle, // ✅ NEW
  });

  @override
  State<ViewAllKOTDropdown> createState() => _ViewAllKOTDropdownState();
}

class _ViewAllKOTDropdownState extends State<ViewAllKOTDropdown> {
  bool _expanded = true;
  final Map<String, bool> _kotExpanded = {};
  int _previousOrderItemCount = 0;


  @override
  void initState() {
    super.initState();
    _fetchKots();
    // ✅ NEW: report initial expansion state to the parent on first build
    // so the parent's _showKotList stays in sync from the start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onToggle?.call(_expanded);
    });
  }

  void _fetchKots() {
    context.read<KotBloc>().add(FetchKots(
      parentOrderId: widget.parentOrderId,
      restaurantId: widget.restaurantId,
      zoneId: widget.zoneId,
      token: widget.token,
    ));
  }

  @override
  void didUpdateWidget(covariant ViewAllKOTDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentOrderId != widget.parentOrderId) {
      _fetchKots();
      _kotExpanded.clear();
      _expanded = false;
      // ✅ NEW: keep parent in sync when we reset expansion on order change
      widget.onToggle?.call(_expanded);
    }
  }
  Map<String, String> extractZoneNames(dynamic zoneResponse) {
    // ✅ CASE 1: API already returns List<Map>
    if (zoneResponse is List) {
      return buildZoneNameMapFromZones(
        List<Map<String, dynamic>>.from(zoneResponse),
      );
    }

    // ✅ CASE 2: API returns Map with zone_details
    if (zoneResponse is Map<String, dynamic> &&
        zoneResponse['zone_details'] is List) {
      return buildZoneNameMapFromZones(
        List<Map<String, dynamic>>.from(zoneResponse['zone_details']),
      );
    }

    return {};
  }
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return Colors.orange;

      case 'ready':
        return Colors.green;

      case 'served':
        return Colors.red;

    // case 'cancelled':
    //   return Colors.red;

      default:
        return Colors.grey;
    }
  }

  /// zoneId -> zoneName
  Map<String, String> buildZoneNameMapFromZones(
      List<Map<String, dynamic>> zones) {

    final Map<String, String> zoneNames = {};

    for (final zone in zones) {
      final zoneId = zone['zone_id']?.toString();
      final zoneName = zone['zone_name']?.toString();

      if (zoneId == null || zoneName == null) continue;

      zoneNames[zoneId] = zoneName;
    }

    return zoneNames;
  }

  /// zoneId -> tableNames
  Map<String, List<String>> buildZoneTableMap(
      List<Map<String, dynamic>> tables) {

    final Map<String, List<String>> zoneMap = {};

    for (final table in tables) {
      final zoneId = table['zone_id']?.toString();
      final tableName = table['table_name']?.toString();

      if (zoneId == null || tableName == null) continue;

      zoneMap.putIfAbsent(zoneId, () => []);
      zoneMap[zoneId]!.add(tableName);
    }

    return zoneMap;
  }




  @override
  Widget build(BuildContext context) {
    if (widget.kots.isEmpty) {
      return const SizedBox.shrink();
    }
    return MultiBlocListener(
      listeners: [
        // Listen to OrderBloc to close dropdown when new item added
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            final currentItemCount = state.orderItems.length;
            if (currentItemCount > _previousOrderItemCount && _expanded) {
              setState(() => _expanded = false);
              // ✅ NEW: report the auto-collapse to the parent
              widget.onToggle?.call(_expanded);
            }
            _previousOrderItemCount = currentItemCount;
          },
        ),
        // ✅ NEW: Refresh KOT list when KOT created
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            // whenever kotList length changes, fetch again
            // (or you can check a success flag)
            if (state.kotList.length > 0) {
              // _fetchKots();
            }
          },
        ),
      ],
      child: BlocBuilder<KotBloc, KotState>(
        builder: (context, state) {
          final kotList = widget.kots;

          // Initialize expansion state for each KOT
          for (var kot in kotList) {
            _kotExpanded.putIfAbsent(kot.kotId.toString(), () => false);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown header
              GestureDetector(
                onTap: () {
                  setState(() => _expanded = !_expanded);
                  // ✅ NEW: notify parent every time the header is tapped
                  widget.onToggle?.call(_expanded);
                },
                child: Container(
                  height: 30,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF152148),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'View All KOTs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Transform.rotate(
                        angle: _expanded ? 3.14 : 0,
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded KOT content
              // ─────────────────────────────────────────────────────────
              // FIX: This used to be wrapped with Positioned (in the
              // parent) + a fixed maxHeight: 500 + an inner fixed
              // SizedBox(height: 450). That rigid 500px block is what
              // caused "BOTTOM OVERFLOWED BY n PIXELS": it doesn't fit
              // in the space actually available once the order list,
              // totals bar, and action buttons are laid out too.
              //
              // Now: no fixed height. We give it a *capped* height via
              // ConstrainedBox(maxHeight: 320) and let it shrink to fit
              // its content (mainAxisSize.min). Collapsed state stays
              // exactly as small as the header bar — no item rows are
              // ever shown unless that specific KOT row is tapped open.
              // ─────────────────────────────────────────────────────────
              if (_expanded) const SizedBox(height: 16),
              if (_expanded)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 368,
                    minHeight: 340,
                  ),
                  child: Material(
                    elevation: 8,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kCardBg,
                        borderRadius: BorderRadius.circular(10),
                        // ✅ Border
                        border: Border.all(
                          color: Colors.black.withOpacity(0.08),
                          width: 1,
                        ),

                        // ✅ Shadow
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: kotList.isEmpty
                          ? const Center(
                        child: Text(
                          "No KOTs Available",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                          : SingleChildScrollView(
                        child: Column(
                          children: kotList.map((kot) {
                            print(
                              'KOT => ${kot.kotNumber} kotStatus => ${kot.status}',
                            );
                            final kotKey = kot.kotId.toString();
                            final isOpen = _kotExpanded[kotKey] ?? false;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  // ─────────── KOT HEADER (Top Row) ───────────
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _kotExpanded[kotKey] = !isOpen;
                                      });
                                    },
                                    child: Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [

                                          /// KOT Number
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xffF2F2F2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              (kot.kotNumber?.isNotEmpty ?? false)
                                                  ? kot.kotNumber!
                                                  : "KOT#${kot.kotId}",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          /// Time
                                          Text(
                                            DateFormat('hh:mma').format(kot.time), // 12:35PM
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),

                                          const Spacer(),

                                          /// Status
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(kot.status),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child:Text(
                                              kot.status.toLowerCase() == 'kot processed'
                                                  ? 'YET TO PREPARE'
                                                  : kot.status.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 15),

                                          /// Void Button
                                          InkWell(
                                            onTap: () async {
                                              if (kot.kotId == null) {
                                                debugPrint("❌ kotId is null");
                                                return;
                                              }

                                              final bloc = context.read<KotLineItemsBloc>();

                                              bloc.add(
                                                FetchKotLineItems(
                                                  kotId: kot.kotId!,
                                                  restaurantId: widget.restaurantId,
                                                  zoneId: widget.zoneId,
                                                  token: widget.token,
                                                ),
                                              );

                                              final state = await bloc.stream.firstWhere(
                                                    (state) =>
                                                state is KotLineItemsLoaded ||
                                                    state is KotLineItemsError,
                                              );

                                              if (!context.mounted) return;

                                              if (state is KotLineItemsLoaded) {
                                                final response = state.response;

                                                await showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) {
                                                    return MultiBlocProvider(
                                                      providers: [
                                                        BlocProvider.value(
                                                          value: context.read<UpdatekotBloc>(),
                                                        ),
                                                        BlocProvider.value(
                                                          value: context.read<KotBloc>(),
                                                        ),
                                                      ],
                                                      child: VoidItemsDialog(
                                                        items: response.items,
                                                        tableNo: widget.tableNo,
                                                        kotNo: response.kotNumber,
                                                        kotId: response.kotId,
                                                        restaurantId: response.restaurantId,
                                                        zoneId: response.zoneId,
                                                        token: widget.token,
                                                        parentOrderId:
                                                        context.read<KotBloc>().currentParentOrderId,
                                                        item: kot,
                                                        onRemark: (value) {
                                                          debugPrint(value);
                                                        },
                                                      ),
                                                    );
                                                  },
                                                );
                                              } else if (state is KotLineItemsError) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(state.message),
                                                    duration: const Duration(seconds: 1),
                                                  ),
                                                );
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              height: 34,
                                              width: 34,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Image.asset(
                                                  "assets/icon/Void.png",
                                                  height: 18,
                                                  width: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 15),

                                          /// Transfer Button
                                          InkWell(
                                            onTap: () async {
                                              debugPrint("🔥 STEP 0: Transfer KOT button tapped");

                                              try {
                                                final token = await SessionManager.getToken();
                                                if (token == null || token.isEmpty) return;

                                                final transferItems = kot.items.map((e) {
                                                  return TransferKotItem(
                                                    name: e.itemName ?? "",
                                                    note: e.note.isNotEmpty
                                                        ? e.note
                                                        : (e.modifiers.isNotEmpty
                                                        ? e.modifiers.join(", ")
                                                        : ""),
                                                    qty: e.quantity ?? 1,
                                                    amount: e.totalWithAddons,
                                                  );
                                                }).toList();

                                                final zoneRepository = ZoneRepository();
                                                final zoneResponse = await zoneRepository.getAllZones(token);

                                                final Map<String, String> zoneNames =
                                                extractZoneNames(zoneResponse);

                                                final tableRepository = TableRepository();
                                                final tableResponse =
                                                await tableRepository.getAllTables(token);

                                                final Map<String, List<String>> zoneTables = {};
                                                final Map<String, int> tableIds = {};
                                                final Map<String, int> zoneIds = {};
                                                final Map<String, String> tableStatus = {};

                                                for (final table in tableResponse) {
                                                  final zoneId = table['zone_id'];
                                                  final tableName = table['table_name'];
                                                  final tableId = table['table_id'];
                                                  final status = table['status'];

                                                  if (zoneId != null && tableName != null) {
                                                    zoneTables.putIfAbsent(zoneId.toString(), () => []);
                                                    zoneTables[zoneId.toString()]!.add(tableName);
                                                  }

                                                  if (tableName != null && tableId != null) {
                                                    tableIds[tableName] = tableId;
                                                  }

                                                  if (zoneId != null) {
                                                    zoneIds[zoneId.toString()] = zoneId;
                                                  }

                                                  if (tableName != null && status != null) {
                                                    tableStatus[tableName] = status;
                                                  }
                                                }

                                                String getZoneFromTable(
                                                    String tableName,
                                                    Map<String, List<String>> zoneTables) {
                                                  for (final entry in zoneTables.entries) {
                                                    if (entry.value.contains(tableName)) {
                                                      return entry.key;
                                                    }
                                                  }
                                                  return '';
                                                }

                                                final kotZone =
                                                getZoneFromTable(widget.tableNo, zoneTables);

                                                final result = await showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) => BlocProvider(
                                                    create: (_) => TransferKotBloc(
                                                      repository: KotTransferRepository(),
                                                    ),
                                                    child: TransferKOTDialog(
                                                      tableName: widget.tableNo,
                                                      kotNo: (kot.kotNumber?.isNotEmpty ?? false)
                                                          ? kot.kotNumber!
                                                          : "KOT#${kot.kotId}",
                                                      dateTime: kot.time ?? DateTime.now(),
                                                      items: transferItems,
                                                      zoneTables: zoneTables,
                                                      orderId: widget.parentOrderId!,
                                                      kotId: kot.kotId!,
                                                      fromTableId: tableIds[widget.tableNo]!,
                                                      restaurantId: widget.restaurantId!,
                                                      authToken: widget.token,
                                                      zoneIds: zoneIds,
                                                      tableIds: tableIds,
                                                      tableStatus: tableStatus,
                                                      kotZone: kotZone,
                                                      zoneNames: zoneNames,
                                                    ),
                                                  ),
                                                );

                                                if (result != null) {
                                                  context.read<KotBloc>().add(
                                                    FetchKots(
                                                      parentOrderId: widget.parentOrderId,
                                                      restaurantId: widget.restaurantId!,
                                                      zoneId: widget.zoneId,
                                                      token: widget.token,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                debugPrint(e.toString());
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              height: 34,
                                              width: 34,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Image.asset(
                                                  "assets/transfer.png", // use your transfer asset
                                                  height: 18,
                                                  width: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          /// Expand Icon
                                          Icon(
                                            isOpen
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: Colors.black87,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // ─────────── KOT BODY ───────────
                                  if (isOpen)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: kKotHeaderBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 10),

                                          // Items Table Container
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: const BorderRadius.only(
                                                bottomLeft: Radius.circular(10),
                                                bottomRight: Radius.circular(10),
                                              ),
                                              border: Border.all(color: const Color(0xffE4E4E4)),
                                            ),
                                            child: Column(
                                              children: [
                                                ...kot.items.asMap().entries.map((entry) {
                                                  final index = entry.key;
                                                  final item = entry.value;

                                                  return Column(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 10,
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 30,
                                                              child: Text("${index + 1}"),
                                                            ),

                                                            Expanded(
                                                              child: Text(
                                                                item.name,
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ),

                                                            SizedBox(
                                                              width: 40,
                                                              child: Center(
                                                                child: Text("${item.quantity}"),
                                                              ),
                                                            ),

                                                            SizedBox(
                                                              width: 80,
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                                children: [
                                                                  Text(
                                                                    item.totalWithAddons.toStringAsFixed(2),
                                                                    style: const TextStyle(
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    item.amount.toStringAsFixed(2),
                                                                    style: const TextStyle(
                                                                      fontSize: 11,
                                                                      color: Colors.grey,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const Divider(height: 1),
                                                    ],
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            decoration: const BoxDecoration(
                                              color: Color(0xff0D4E94),
                                              borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(10),
                                                bottomRight: Radius.circular(10),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "Total Items: ${kot.items.length}",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  kot.items
                                                      .fold<double>(
                                                    0,
                                                        (sum, e) => sum + e.totalWithAddons,
                                                  )
                                                      .toStringAsFixed(2),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  Widget _kotActionButton({
    required String text,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 32, // ✅ same height like image
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Image.asset(
          "assets/icon/Void.png", // 🔥 your asset path
          height: 16,
          width: 16,
          color: iconColor, // optional (works only for single-color png/svg)
        ),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0, // ✅ flat like image
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // ✅ rounded like image
          ),
        ),
      ),
    );
  }

}