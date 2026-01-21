import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/transer_kot.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/void_items.dart';
import '../../blocs/Bloc Event/kot_event.dart';
import '../../blocs/Bloc Logic/kot_bloc.dart';
import '../../blocs/Bloc State/kot_state.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../models/order/KOT_model.dart';

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

  const ViewAllKOTDropdown({
    super.key,
    required this.parentOrderId,
    required this.restaurantId,
    required this.zoneId,
    required this.tableNo,
    required this.token, required List<KotModel> kots,
  });

  @override
  State<ViewAllKOTDropdown> createState() => _ViewAllKOTDropdownState();
}

class _ViewAllKOTDropdownState extends State<ViewAllKOTDropdown> {
  bool _expanded = false;
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
                                        Row(
                                          children: [
                                            Text(
                                              TimeOfDay.fromDateTime(kot.time)
                                                  .format(context),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const Spacer(),

                                            // Void Items Button (Blue)
                                            SizedBox(
                                              height: 32,
                                              child: ElevatedButton.icon(
                                                onPressed: () async {
                                                  final List<Item> voidDialogItems =
                                                  kot.items.map((o) {
                                                    return Item(
                                                      name: o.name ?? "",
                                                      pricePerItem:
                                                      (o.price ?? 0).toDouble(),
                                                    );
                                                  }).toList();

                                                  await showDialog(
                                                    context: context,
                                                    barrierDismissible: true,
                                                    builder: (context) => VoidItemsDialog(
                                                      items: voidDialogItems,
                                                      tableNo: widget.tableNo,
                                                      kotNo: kot.kotId.toString(),
                                                      onRemark: (value) {
                                                        debugPrint("Remark: $value");
                                                      },
                                                      item: kot,
                                                    ),
                                                  );
                                                },
                                                // ✅ Asset Icon
                                                icon: Image.asset(
                                                  "assets/icon/Void.png", // 🔥 your icon path
                                                  height: 16,
                                                  width: 16,
                                                  color: Colors.white, // remove if not changing color
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
                                                  backgroundColor:
                                                  const Color(0xFF1E63FF),
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            // Transfer KOT Button (Yellow)
                                            SizedBox(
                                              height: 32,
                                              child: ElevatedButton.icon(
                                                onPressed: () async {
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

                                                  final tableList = List.generate(
                                                      24, (i) => "Table-${i + 1}");

                                                  await showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (_) => TransferKOTDialog(
                                                      tableNo: widget.tableNo,
                                                      kotNo: kot.kotId.toString(),
                                                      dateTime:
                                                      kot.time ?? DateTime.now(),
                                                      items: transferItems,
                                                      tables: tableList,
                                                    ),
                                                  );
                                                },
                                                // ✅ Asset Icon
                                                icon: Image.asset(
                                                  "assets/icon/Void.png", // 🔥 your icon path
                                                  height: 16,
                                                  width: 16,
                                                  color: Colors.black, // remove if not changing color
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
                                                  backgroundColor:
                                                  const Color(0xFFFFC107),
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
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
                                                                Text(
                                                                  item.amount.toStringAsFixed(2),
                                                                  style: const TextStyle(
                                                                    fontSize: 11,
                                                                    color: Colors.grey,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
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