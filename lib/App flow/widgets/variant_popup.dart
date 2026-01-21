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
      key: UniqueKey(),
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
  /// ✅ variationId → quantity
  final Map<int, int> _quantityMap = {};

  @override
  void initState() {
    super.initState();
    _quantityMap.clear(); // 🔥 reset popup state
  }

  void _increment(Variant variant) {
    setState(() {
      _quantityMap[variant.variationId] =
          (_quantityMap[variant.variationId] ?? 0) + 1;
    });
  }

  void _decrement(Variant variant) {
    setState(() {
      final current = _quantityMap[variant.variationId] ?? 0;
      if (current > 0) {
        _quantityMap[variant.variationId] = current - 1;
      }
    });
  }

  void _addVariantsToOrder() {
    for (final entry in _quantityMap.entries) {
      if (entry.value <= 0) continue;

      final variant = widget.product.variants.firstWhere(
            (v) => v.variationId == entry.key,
      );

      final orderItem = OrderItems(
        name: '${widget.product.name} - ${variant.name}',
        price: variant.price,
        quantity: entry.value,
        modifiers: [],
        section: widget.section,
        productId: widget.product.id,
        variationId: variant.variationId,
        // ✅ base amount = price * quantity
        amount: variant.price * entry.value,

      );

      widget.orderBloc.add(AddOrderItem(orderItem));
    }

    _quantityMap.clear();
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
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose Variants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _quantityMap.clear();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            /// VARIANTS LIST
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.product.variants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final variant = widget.product.variants[index];
                  final quantity =
                      _quantityMap[variant.variationId] ?? 0;

                  return Container(
                    width: 180,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            variant.image.isNotEmpty
                                ? variant.image
                                : 'https://via.placeholder.com/100',
                            width: 120,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(widget.product.name,
                            textAlign: TextAlign.center),
                        Text(
                          variant.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rs.${variant.price.toStringAsFixed(0)}/-',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),

                        quantity == 0
                            ? ElevatedButton(
                          onPressed: () => _increment(variant),
                          style: ElevatedButton.styleFrom(
                            minimumSize:
                            const Size(150, 40),
                          ),
                          child: const Text('+ ADD'),
                        )
                            : Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            _qtyButton(
                              icon: Icons.remove,
                              onTap: () => _decrement(variant),
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            _qtyButton(
                              icon: Icons.add,
                              onTap: () => _increment(variant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            /// DONE BUTTON
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF386EDA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _addVariantsToOrder,
                child: const Text(
                  'Done',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SMALL +/- BUTTON
  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: Colors.blue),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onTap,
      ),
    );
  }
}

