import 'package:flutter/material.dart';
import '../../models/order/KOT_model.dart';
// import '../models/order/KOT_model.dart';

class ViewAllKOTDropdown extends StatefulWidget {
  final List<KotModel> kotList;

  const ViewAllKOTDropdown({super.key, required this.kotList});

  @override
  State<ViewAllKOTDropdown> createState() => _ViewAllKOTDropdownState();
}

class _ViewAllKOTDropdownState extends State<ViewAllKOTDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compact toggle button
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            height: 36, // Reduced height
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF152148), // Navy blue
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'View All KOTs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

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
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            )
                : Column(
              children: widget.kotList.map((kot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("KOT #${kot.kotId}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Time: ${kot.time}"),
                      Text(kot.status, style: TextStyle(color: kot.status == 'Pending' ? Colors.red : Colors.green)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
