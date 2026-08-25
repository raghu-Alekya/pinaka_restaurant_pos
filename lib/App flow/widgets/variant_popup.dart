import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/category/items_model.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../models/sidebar/category_model_.dart';
import '../../models/order/order_items.dart';

/// Function to show the variant popup
// void _showVariantPopup(
//     BuildContext context,
//     Product product,
//     OrderBloc orderBloc,
//     Category?section,
//     ) {
//   showDialog(
//     context: context,
//     builder: (context) => VariantPopupContent(
//       key: UniqueKey(),
//       product: product,
//       section: section,
//       orderBloc: orderBloc, itemName: '', variants: [], onVariantSelected: (variant) {  }, onSelected: (variant) {  },
//     ),
//   );
// }

/// The popup widget itself
class VariantPopupContent extends StatefulWidget {
  final Product product;
  final Category section;
  final OrderBloc orderBloc;

  const VariantPopupContent({
    super.key,
    required this.product,
    required this.section,
    required this.orderBloc,
    required String itemName,
    required List<Variant> variants,
    required Null Function(dynamic variant) onVariantSelected,
    required Null Function(dynamic variant) onSelected,
  });

  @override
  State<VariantPopupContent> createState() => _VariantPopupContentState();
}

class _VariantPopupContentState extends State<VariantPopupContent> {
  /// ✅ variationId → quantity
  final Map<int, int> _quantityMap = {};
  bool get _hasSelectedVariants {
    return _quantityMap.values.any((qty) => qty > 0);
  }

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
      print("=========== VARIANT DEBUG ===========");
      print("Parent Product ID : ${widget.product.id}");
      print("Parent Product Name : ${widget.product.name}");
      print("Variation ID : ${variant.variationId}");
      print("Variation Name : ${variant.name}");
      print("Variation Price : ${variant.price}");
      print("Quantity : ${entry.value}");
      print("Combined Name : ${widget.product.name} - ${variant.name}");
      print("=====================================");
      final orderItem = OrderItems(
        // name: '${widget.product.name} - ${variant.name}',
        name: variant.name,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Dialog(
      backgroundColor:
      isDark ? const Color(0xFF252837) : const Color(0xFFF0F4FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Variants',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.name.length > 25
                          ? '${widget.product.name.substring(0, 25)}...'
                          : widget.product.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black45 : Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 16),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161513) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black38 : const Color(0x1A000000),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.white,
                  width: 1,
                ),
              ),
              child: SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.product.variants.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final variant = widget.product.variants[index];
                    final quantity = _quantityMap[variant.variationId] ?? 0;
                    final displayVariantName =
                    variant.name
                        .replaceFirst(widget.product.name, '')
                        .replaceFirst('-', '')
                        .trim();

                    return Container(
                      width: 170,
                      padding: const EdgeInsets.only(top: 10),
                      decoration: ShapeDecoration(
                        color: isDark ? const Color(0xFF2F3347) : Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color:
                            isDark
                                ? Colors.white24
                                : const Color(0xFFE1E1E1),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              variant.image.isNotEmpty
                                  ? variant.image
                                  : 'https://via.placeholder.com/100',
                              width: 150,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Text(widget.product.name,
                          //     textAlign: TextAlign.center),
                          Text(
                            displayVariantName.length > 12
                                ? '${displayVariantName.substring(0, 12)}...'
                                : displayVariantName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Rs.${variant.price.toStringAsFixed(0)}/-',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),

                          quantity == 0
                              ? ElevatedButton(
                            onPressed: () => _increment(variant),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              isDark
                                  ? const Color(0xFF05132A)
                                  : const Color(0xFF4C5F7D),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(152, 49),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('+ ADD'),
                          )
                              : Container(
                            height: 40,
                            width: 150,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4C5F7D),
                              borderRadius: BorderRadius.circular(8),
                              // border: Border.all(
                              // color: const Color(0xFF386EDA),
                              // ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _qtyButton(
                                  context: context,
                                  icon: Icons.remove,
                                  onTap: () => _decrement(variant),
                                ),
                                Text(
                                  '$quantity',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                    isDark
                                        ? const Color(0xFF3B4259)
                                        : const Color(0xFFFFFFFF),
                                  ),
                                ),
                                _qtyButton(
                                  context: context,
                                  icon: Icons.add,
                                  onTap: () => _increment(variant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// DONE BUTTON
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _hasSelectedVariants
                      ? const Color(0xFF386EDA)
                      : (isDark
                      ? const Color(0xFF161513)
                      : Colors.grey.shade400),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  isDark ? const Color(0xFF161513) : Colors.grey.shade400,
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _hasSelectedVariants ? _addVariantsToOrder : null,
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 50,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2F3D) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDark ? Colors.white24 : Colors.transparent),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : const Color(0xFF4C5F7D),
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onTap,
      ),
    );
  }
}
