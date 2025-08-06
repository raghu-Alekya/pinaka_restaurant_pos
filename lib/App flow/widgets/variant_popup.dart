import 'package:flutter/material.dart';

class Variant {
  final String name;
  final String imageUrl;
  final double price;

  Variant({required this.name, required this.imageUrl, required this.price});
}

void showVariantPopup(
    BuildContext context,
    String itemName,
    List<Variant> variants, {
      required void Function(String variantName, double price, int quantity) onSelected,
    }) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: VariantPopupContent(
        itemName: itemName,
        variants: variants,
        onSelected: onSelected,
      ),
    ),
  );
}

class VariantPopupContent extends StatefulWidget {
  final String itemName;
  final List<Variant> variants;
  final void Function(String variantName, double price, int quantity) onSelected;

  const VariantPopupContent({
    super.key,
    required this.itemName,
    required this.variants,
    required this.onSelected,
  });

  @override
  State<VariantPopupContent> createState() => _VariantPopupContentState();
}

class _VariantPopupContentState extends State<VariantPopupContent> {
  final Map<int, int> _quantityMap = {};

  void _increment(int index) {
    setState(() {
      _quantityMap[index] = (_quantityMap[index] ?? 0) + 1;
    });
  }

  void _decrement(int index) {
    setState(() {
      if ((_quantityMap[index] ?? 0) > 0) {
        _quantityMap[index] = (_quantityMap[index]! - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Choose Variants',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.red,         // Light red background
                    shape: BoxShape.circle,             // Circular background
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

              ],
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.itemName, style: const TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 12),

            // Scrollable Variant Cards
            SizedBox(
              height: 160,
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(8),
                thickness: 4,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(widget.variants.length, (index) {
                      final variant = widget.variants[index];
                      final quantity = _quantityMap[index] ?? 0;

                      return Container(
                        width: 160,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                variant.imageUrl,
                                width: 70,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(variant.name,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text("Single × 1",
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text("₹${variant.price.toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 8),

                            quantity == 0
                                ? ElevatedButton(
                              onPressed: () => _increment(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF386EDA),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(100, 32),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("+ ADD"),
                            )
                                : Container(
                              height: 40,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFF386EDA), width: 2),
                                color: const Color(0xFF386EDA),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Minus button
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.remove,
                                          size: 16,
                                          color: Color(0xFF386EDA)),
                                      onPressed: () => _decrement(index),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Quantity
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Plus button
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.add,
                                          size: 16,
                                          color: Color(0xFF386EDA)),
                                      onPressed: () => _increment(index),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Done Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF386EDA)),
                onPressed: () {
                  for (var entry in _quantityMap.entries) {
                    if (entry.value > 0) {
                      final variant = widget.variants[entry.key];
                      widget.onSelected(variant.name, variant.price, entry.value);
                    }
                  }
                  Navigator.pop(context);
                },
                child: const Text('Done',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
