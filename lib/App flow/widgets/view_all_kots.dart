import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  const ViewAllKOTDropdown({
    super.key,
    required this.parentOrderId,
    required this.restaurantId,
    required this.zoneId,
    required this.tableNo,
    required this.token,
    required this.kots, // ✅ FIXED
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
    }
  }
  /// zoneId -> zoneName
  Map<String, String> buildZoneNameMap(
      List<Map<String, dynamic>> tables) {

    final Map<String, String> zoneNames = {};

    for (final table in tables) {
      final zoneId = table['zone_id']?.toString();
      final zoneName = table['zone_name']?.toString();

      if (zoneId == null || zoneName == null) continue;

      zoneNames[zoneId] = zoneName; // overwrite is fine
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
    return MultiBlocListener(
      listeners: [
        // Listen to OrderBloc to close dropdown when new item added
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            final currentItemCount = state.orderItems.length;
            if (currentItemCount > _previousOrderItemCount && _expanded) {
              setState(() => _expanded = false);
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
              _fetchKots();
            }
          },
        ),
      ],
      child: BlocBuilder<KotBloc, KotState>(
        builder: (context, state) {
          final kotList = state is KotLoaded ? state.kots : <KotModel>[];

          // Initialize expansion state for each KOT
          for (var kot in kotList) {
            _kotExpanded.putIfAbsent(kot.kotId.toString(), () => false);
          }

          return Column(
            children: [
              // Dropdown header
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  height: 36,
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
              const SizedBox(height: 6),

              // Expanded KOT content
              // if (_expanded)
                if (_expanded)
                  Container(
                    width: double.infinity,
                    height: 420,
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
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: kKotHeaderBg,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            (kot.kotNumber?.isNotEmpty ?? false)
                                                ? kot.kotNumber!
                                                : "KOT#${kot.kotId}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          isOpen
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          size: 18,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ─────────── KOT BODY ───────────
                                if (isOpen)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: kKotHeaderBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        // Time + Buttons Row
                                        MultiBlocListener(
                                        listeners: [
                                        // ✅ 1) Load KOT Line Items → open dialog
                                        BlocListener<KotLineItemsBloc, KotLineItemsState>(
                                    listener: (context, state) async {
                                      if (state is KotLineItemsLoaded) {
                                        final response = state.response;

                                        await showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (dialogContext) {
                                            return BlocProvider.value(
                                              value: context.read<UpdatekotBloc>(), // ✅ pass existing bloc
                                              child: VoidItemsDialog(
                                                items: response.items,
                                                tableNo: widget.tableNo,
                                                kotNo: response.kotNumber,
                                                kotId: response.kotId,
                                                restaurantId: response.restaurantId,
                                                zoneId: response.zoneId,
                                                token: widget.token,
                                                parentOrderId: context.read<KotBloc>().currentParentOrderId,
                                                item: kot,
                                                onRemark: (value) {
                                                  debugPrint("Remark: $value");
                                                },
                                              ),
                                            );
                                          },
                                        );

                                      }

                                      if (state is KotLineItemsError) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(state.message)),
                                        );
                                      }
                                    },
                                    ),

                                        // ✅ 2) After Update/Void success → Refresh KOT list automatically
                                          BlocListener<UpdatekotBloc, UpdatekotState>(
                                            listener: (context, state) {
                                              if (state is UpdatekotSuccess) {
                                                final kotBloc = context.read<KotBloc>();

                                                context.read<KotBloc>().add(
                                                  FetchKots(
                                                    parentOrderId: kotBloc.currentParentOrderId, // ✅ NOT NULL
                                                    restaurantId: widget.restaurantId,
                                                    zoneId: widget.zoneId,
                                                    token: widget.token,
                                                    // orderId: 0, // if required in event, pass dummy or correct
                                                  ),
                                                );

                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("KOT Updated Successfully")),
                                                );
                                              }

                                              if (state is UpdatekotFailure) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(state.message)),
                                                );
                                              }
                                            },
                                          ),

                                          ],
                                    child: Row(
                                    children: [
                                    Text(
                                        TimeOfDay.fromDateTime(kot.time).format(context),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                const Spacer(),

                                // ✅ Void Items Button
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (kot.kotId == null) {
                                        debugPrint("❌ kotId is null");
                                        return;
                                      }

                                      context.read<KotLineItemsBloc>().add(
                                        FetchKotLineItems(
                                          kotId: kot.kotId!,
                                          restaurantId: widget.restaurantId,
                                          zoneId: widget.zoneId,
                                          token: widget.token,
                                        ),
                                      );
                                    },
                                    icon: Image.asset(
                                      "assets/icon/Void.png",
                                      height: 16,
                                      width: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "Void Items",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E63FF),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // ✅ Transfer KOT Button
                          SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                          onPressed: () async {
                          debugPrint("🔥 STEP 0: Transfer KOT button tapped");

                          try {
                          // ✅ STEP 1: TOKEN
                          final token = await SessionManager.getToken();
                          if (token == null || token.isEmpty) return;

                          // ✅ STEP 2: ITEMS
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

                          // ✅ STEP 3: FETCH TABLES
                          final tableRepository = TableRepository();
                          final tableResponse =
                          await tableRepository.getAllTables(token);

                          // ✅ STEP 4: BUILD ZONE → TABLE MAP (String keys)
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
                          final key = zoneId.toString();
                          zoneTables.putIfAbsent(key, () => []);
                          zoneTables[key]!.add(tableName);
                          }

                          if (tableName != null && tableId != null) {
                          tableIds[tableName] = tableId;
                          }

                          if (zoneId != null) {
                          zoneIds[zoneId.toString()] = zoneId;
                          }
                          if (tableName != null && status != null) {
                            tableStatus[tableName] = status; // ✅ STORE STATUS
                          }
                          }

                          debugPrint("🟢 ZONE TABLES = $zoneTables");
                          debugPrint("🟢 TABLE IDS = $tableIds");
                          debugPrint("🟢 ZONE IDS = $zoneIds");
                          debugPrint("🧪 widget.tableNo = '${widget.tableNo}'");
                          debugPrint("🧪 tableIds keys = ${tableIds.keys.toList()}");
                          debugPrint("🟢 TABLE STATUS = $tableStatus");


                          // ✅ STEP 4.9: HARD GUARDS
                          if (!context.mounted) return;

                          if (widget.parentOrderId == null ||
                          widget.restaurantId == null ||
                          kot.kotId == null ||
                          !tableIds.containsKey(widget.tableNo)) {
                          debugPrint("❌ Missing required IDs");
                          return;
                          }

                          // ✅ STEP 5: OPEN DIALOG
                          final result = await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) {
                              return BlocProvider(
                                create: (_) => TransferKotBloc(
                                  repository: KotTransferRepository(),
                                ),
                                child: TransferKOTDialog(
                                  tableName: widget.tableNo,
                                  kotNo: kot.kotId.toString(),
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
                                ),
                              );
                            },
                          );
                          if (result != null && result is Map) {
                            final newParentId = result["newParentId"];

                            debugPrint("🔁 Transfer done → refreshing View All KOTs");

                            context.read<KotBloc>().add(
                              FetchKots(
                                parentOrderId: newParentId,
                                restaurantId: widget.restaurantId!,
                                zoneId: widget.zoneId,
                                token: widget.token,
                              ),
                            );
                          }



                          } catch (e, s) {
                          debugPrint("❌ Transfer KOT failed: $e");
                          debugPrintStack(stackTrace: s);
                          }
                          },
                          icon: Image.asset(
                          "assets/icon/Void.png",
                          height: 16,
                          width: 16,
                          color: Colors.black,
                          ),
                          label: const Text(
                          "Transfer KOT",
                          style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          ),
                          ),
                          style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          ),
                          ),
                          ),
                          ),


                          ],
                            ),
                          ),


                          const SizedBox(height: 10),

                                        // Items Table Container
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              ...kot.items.asMap().entries.map((entry) {
                                                final index = entry.key;
                                                final item = entry.value;

                                                return Column(
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          SizedBox(
                                                            width: 20,
                                                            child: Text(
                                                              "${index + 1}",
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                          ),

                                                          // ✅ Name + modifier + addons
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  item.name,
                                                                  style: const TextStyle(
                                                                    fontSize: 13,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),

                                                                if (item.modifiers.isNotEmpty)
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(top: 2),
                                                                    child: Text(
                                                                      item.modifiers.join(", "),
                                                                      style: const TextStyle(
                                                                        fontSize: 10,
                                                                        color: Colors.red,
                                                                        fontWeight: FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                  ),

                                                                if (item.addOns.isNotEmpty)
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(top: 2),
                                                                    child: Text(
                                                                      item.addOns.entries.map((e) {
                                                                        final qty = e.value['quantity'] ?? 0;
                                                                        return "${e.key} x$qty";
                                                                      }).join(", "),
                                                                      style: const TextStyle(
                                                                        fontSize: 10,
                                                                        color: Colors.blue,
                                                                        fontWeight: FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),

                                                          SizedBox(
                                                            width: 40,
                                                            child: Center(
                                                              child: Text(
                                                                "${item.quantity}",
                                                                style: const TextStyle(fontSize: 12),
                                                              ),
                                                            ),
                                                          ),

                                                          SizedBox(
                                                            width: 70,
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.end,
                                                              children: [
                                                                Text(
                                                                  item.amount.toStringAsFixed(2),
                                                                  style: const TextStyle(
                                                                    fontSize: 13,
                                                                    fontWeight: FontWeight.w700,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 2),
                                                                // Text(
                                                                //   item.amount.toStringAsFixed(2),
                                                                //   style: const TextStyle(
                                                                //     fontSize: 11,
                                                                //     color: Colors.grey,
                                                                //     fontWeight: FontWeight.w500,
                                                                //   ),
                                                                // ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Divider(height: 1, thickness: 1, color: kDivider),
                                                  ],
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        ),

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