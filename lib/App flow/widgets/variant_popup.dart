import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/category/items_model.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../models/sidebar/category_model_.dart';
import '../../models/order/order_items.dart';

/// Function to show the variant popup
void _showVariantPopup(
    BuildContext context,
    Product product,
    OrderBloc orderBloc,
    Category section,
    ) {
  showDialog(
    context: context,
    builder: (context) => VariantPopupContent(
      product: product,
      section: section,
      orderBloc: orderBloc, itemName: '', variants: [], onVariantSelected: (variant) {  }, onSelected: (variant) {  },
    ),
  );
}

/// The popup widget itself
class VariantPopupContent extends StatefulWidget {
  final Product product;
  final Category section;
  final OrderBloc orderBloc;

  const VariantPopupContent({
    super.key,
    required this.product,
    required this.section,
    required this.orderBloc, required String itemName, required List<Variant> variants, required Null Function(dynamic variant) onVariantSelected, required Null Function(dynamic variant) onSelected,
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

  void _addVariantsToOrder() {
    for (var entry in _quantityMap.entries) {
      if (entry.value > 0) {
        final variant = widget.product.variants[entry.key];
        final orderItem = OrderItems(
          name: '${widget.product.name} - ${variant.name}',
          price: variant.price,
          quantity: entry.value,
          modifiers: [],
          section: widget.section,
          productId: 0,
        );
        widget.orderBloc.add(AddOrderItem(orderItem));
        print("[VariantPopup] Added: ${orderItem.name} x${orderItem.quantity}");
      }
    }
    Navigator.pop(context);
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
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Horizontal scrollable variants
            Container(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.product.variants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final variant = widget.product.variants[index];
                  final quantity = _quantityMap[index] ?? 0;

                  return Container(
                    width: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
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
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(widget.product.name, textAlign: TextAlign.center),
                        Text(variant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Rs.${variant.price.toStringAsFixed(0)}/-", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        quantity == 0
                            ? ElevatedButton(
                          onPressed: () => _increment(index),
                          child: const Text("+ ADD"),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(icon: const Icon(Icons.remove), onPressed: () => _decrement(index)),
                            Text('$quantity'),
                            IconButton(icon: const Icon(Icons.add), onPressed: () => _increment(index)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            // Done button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF386EDA), // ✅ custom color
                  foregroundColor: Colors.white,            // ✅ text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // optional rounded corners
                  ),
                ),
                onPressed: _addVariantsToOrder,
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}
