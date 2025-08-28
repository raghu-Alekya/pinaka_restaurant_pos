import 'package:flutter/material.dart';
import '../../models/category/items_model.dart'; // Your Product & Variant models

void showVariantPopup(
    BuildContext context,
    Product product, {
      required void Function(Variant variant) onSelected,
    }) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: VariantPopupContent(
        product: product,
        itemName: product.name,
        variants: product.variants,
        onSelected: onSelected,
      ),
    ),
  );
}

class VariantPopupContent extends StatefulWidget {
  final Product product; // ✅ add this
  final String itemName;
  final List<Variant> variants;
  final void Function(Variant variant) onSelected;
  final void Function(Variant variant)? onVariantSelected;

  const VariantPopupContent({
    super.key,
    required this.product,  // ✅ now required
    required this.itemName,
    required this.variants,
    required this.onSelected,
    this.onVariantSelected,
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
        _quantityMap[index] = _quantityMap[index]! - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose Variants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Header Close Button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.white,
                  // Wrap with Container for red background
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Color(0XFFFE6464)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

              ],
            ),
            const SizedBox(height: 18),

            // Horizontal Scrollable Cards
            // Horizontal Scrollable Cards
            // Outer container wrapping all cards
            Container(
              width: 780,  // <-- increase outer container width
              height: 280, // <-- increase outer container height
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.variants.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final variant = widget.variants[index];
                    final quantity = _quantityMap[index] ?? 0;

                    // Individual card with fixed size
                    return Container(
                      width: 180, // <-- fixed width
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              variant.image.isNotEmpty
                                  ? variant.image
                                  : 'https://via.placeholder.com/100',
                              width: 140,
                              height: 90, // <-- fixed height
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(widget.product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(variant.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text("Rs.${variant.price.toStringAsFixed(0)}/-",
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 8),
                          quantity == 0
                              ? ElevatedButton(
                            onPressed: () => _increment(index),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0XFFFE6464),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(140, 36),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            child: const Text("+ ADD"),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0XFFFE6464),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.white),
                                  onPressed: () => _decrement(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                              Text('$quantity',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0XFFFE6464),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  onPressed: () => _increment(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Done Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0XFF4C81F1)),
                onPressed: () {
                  for (var entry in _quantityMap.entries) {
                    if (entry.value > 0) {
                      final variant = widget.variants[entry.key];
                      final selectedVariant = Variant(
                        productId: variant.productId,
                        variationId: variant.variationId,
                        name: variant.name,
                        image: variant.image,
                        quantity: entry.value,
                        price: variant.price,
                      );
                      widget.onSelected(selectedVariant);
                    }
                  }
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}