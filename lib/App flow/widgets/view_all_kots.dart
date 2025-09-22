import 'package:flutter/material.dart';
import '../../models/order/KOT_model.dart';

class ViewAllKOTDropdown extends StatefulWidget {
  final List<KotModel> kotList;

  const ViewAllKOTDropdown({super.key, required this.kotList});

  @override
  State<ViewAllKOTDropdown> createState() => _ViewAllKOTDropdownState();
}

class _ViewAllKOTDropdownState extends State<ViewAllKOTDropdown> {
  bool _expanded = false;
  final Map<String, bool> _kotExpanded = {}; // track each KOT's expansion

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main "View All KOTs" toggle
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
                      fontWeight: FontWeight.w600),
                ),
                Transform.rotate(
                  angle: _expanded ? 3.14 : 0,
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Expanded KOT list
        if (_expanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.kotList.isEmpty
                ? const Center(
              child: Text(
                "No KOTs Available",
                style: TextStyle(
                    color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            )
                : Column(
              children: widget.kotList.map((kot) {
                final kotKey = kot.kotId.toString(); // ✅ convert to String
                _kotExpanded.putIfAbsent(kotKey, () => false);

                return Column(
                  children: [
                    // KOT header row
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
                        color: const Color(0xFFEFEFEF),
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
                                      fontWeight: FontWeight.bold),
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

                    // Items inside KOT
                    if (_kotExpanded[kotKey]!)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12),
                        child: Column(
                          children: kot.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(item.name,
                                        style: const TextStyle(
                                            fontSize: 12)),
                                  ),
                                  Text(
                                    "Qty: ${item.quantity}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "₹${item.price.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
