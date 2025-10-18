import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  const ViewAllKOTDropdown({
    super.key,
    required this.parentOrderId,
    required this.restaurantId,
    required this.zoneId,
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
                                      kot.kotNumber.isNotEmpty
                                          ? kot.kotNumber
                                          : "KOT #${kot.kotId}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
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
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            kot.time?.toString() ??
                                                "12:30 PM",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                FontWeight.bold),
                                          ),
                                        ],
                                      ),
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
                                                      "₹${item.price.toStringAsFixed(2)}",
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                          FontWeight.w500)),
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
}
