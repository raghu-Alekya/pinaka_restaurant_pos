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
              if (_expanded)
                Container(
                  width: double.infinity,
                  height: 300,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0XFFF1F1F3),
                    borderRadius: BorderRadius.circular(8),
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
                      children: kotList.map<Widget>((kot) {
                        final kotKey = kot.kotId.toString();
                        return Column(
                          children: [
                            // KOT header
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _kotExpanded[kotKey] =
                                  !_kotExpanded[kotKey]!;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                color: const Color(0xFFECEEFB),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      (kot.kotNumber?.isNotEmpty ?? false)
                                          ? kot.kotNumber!
                                          : "KOT #${kot.kotId}",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),

                                    Row(
                                      children: [
                                        Text(
                                          kot.status,
                                          style: TextStyle(
                                            color: kot.status == 'Pending'
                                                ? Colors.red
                                                : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          _kotExpanded[kotKey]!
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // KOT items
                            if (_kotExpanded[kotKey]!)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    // Time + action buttons
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 6),
                                      color: const Color(0xFFECEEFB),
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


                                          // ✅ Void Items Button (Blue)
                                          _kotActionButton(
                                            text: "Void Items",
                                            bgColor: const Color(0xFF1E63FF), // same blue like image
                                            textColor: Colors.white,
                                            iconColor: Colors.white,
                                            onTap: () async {
                                              final List<Item> voidDialogItems = kot.items.map((o) {
                                                return Item(
                                                  name: o.name ?? "",
                                                  pricePerItem: (o.price ?? 0).toDouble(),
                                                  // quantity: o.qty ?? 1,
                                                  // notes: o.modifier ?? "",
                                                );
                                              }).toList();

                                              final result = await showDialog(
                                                context: context,
                                                barrierDismissible: true,
                                                builder: (context) => VoidItemsDialog(
                                                  items: voidDialogItems,
                                                  tableNo: widget.tableNo.toString(),
                                                  kotNo: kot.kotId.toString(),
                                                  onRemark: (value) {
                                                    print("Remark: $value");
                                                  },
                                                  item: kot,
                                                ),
                                              );

                                              if (result != null) {
                                                print("Selected Items: ${result['items']}");
                                                print("Remark: ${result['remark']}");
                                              }
                                            },

                                          ),

                                          const SizedBox(width: 10),

                                          // ✅ Transfer KOT Button (Yellow)
                                          _kotActionButton(
                                            text: "Transfer KOT",
                                            bgColor: const Color(0xFFFFC107),
                                            textColor: Colors.black,
                                            iconColor: Colors.black,
                                            onTap: () async {

                                              // ✅ Convert your KOT items into TransferKotItem list dynamically
                                              final transferItems = kot.items.map((e) {
                                                return TransferKotItem(
                                                  name: e.itemName ?? "",
                                                  note: e.note.isNotEmpty
                                                      ? e.note
                                                      : (e.modifiers.isNotEmpty ? e.modifiers.join(", ") : ""),
                                                  qty: e.quantity ?? 1,
                                                  amount: e.totalWithAddons,

                                                  // amount: (e.amount ?? 0).toDouble(),
                                                );
                                              }).toList();

                                              // ✅ Dynamic tables list (from API or static)
                                              final tableList = List.generate(24, (i) => "Table-${i + 1}");

                                              final result = await showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (_) => TransferKOTDialog(
                                                  tableNo: widget.tableNo.toString(),   // dynamic
                                                  kotNo: kot.kotId.toString(),          // dynamic
                                                  dateTime: kot.time ?? DateTime.now(), // dynamic
                                                  items: transferItems,                 // dynamic
                                                  tables: tableList,                    // dynamic
                                                ),
                                              );

                                              if (result != null) {
                                                final selectedTable = result["selectedTable"];
                                                final selectedItems = result["selectedItems"];

                                                debugPrint("✅ Selected Table: $selectedTable");
                                                debugPrint("✅ Selected Items: $selectedItems");

                                                // TODO: Call API / Bloc Event here for transfer KOT
                                              }
                                            },
                                          ),

                                        ],
                                      )


                                    ),
                                    const SizedBox(height: 6),
                                    // Items list
                                    Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        children: kot.items
                                            .asMap()
                                            .entries
                                            .map<Widget>((entry) {
                                          final index = entry.key;
                                          final item = entry.value;
                                          return Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                                crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                                children: [
                                                  Text("${index + 1}.",
                                                      style: const TextStyle(
                                                          fontSize: 12)),
                                                  Expanded(
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8.0),
                                                      child: Text(
                                                        item.name,
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                        overflow:
                                                        TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  Text("${item.quantity}",
                                                      style: const TextStyle(
                                                          fontSize: 12)),
                                                  const SizedBox(width: 120),
                                                  Text(
                                                    "₹${(item.quantity * (item.price ?? 0)).toStringAsFixed(2)}",
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                  )

                                                ],
                                              ),
                                              const Divider(
                                                  thickness: 1,
                                                  color: Color(0XFFD9D9D9)),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
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