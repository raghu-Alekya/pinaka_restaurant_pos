import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../models/order/order_items.dart';
import 'modifier_popup.dart';

class OrderPanelList extends StatelessWidget {
  final String currency;
  final List<OrderItems> orderItems;
  final Map<String, double> addonPrices; // addon name -> price
  final Function(int index) onIncreaseQuantity;
  final Function(int index) onDecreaseQuantity;
  final Function(
    int index,
    List<String> modifiers,
    Map<String, Map<String, dynamic>> addOns,
    String note,
  )
  onModifiersChanged;
  final Function(int index) onRemoveItem;
  final String token;

  const OrderPanelList({
    Key? key,
    required this.currency, // <-- Add this
    required this.orderItems,
    required this.addonPrices,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
    required this.onModifiersChanged,
    required this.onRemoveItem,
    required this.token,
  }) : super(key: key);

  void _showModifierPopup(BuildContext context, int index) async {
    final item = orderItems[index];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => ModifierAddOnPopup(
            item: item,
            productId: item.productId,
            token: token,
          ),
    );

    if (result != null) {
      final modifiers = List<String>.from(result['modifiers'] ?? []);
      final addOns = Map<String, Map<String, dynamic>>.from(
        result['addOns'] ?? {},
      );
      final note = result['note'] as String? ?? '';

      // Callback to parent
      onModifiersChanged(index, modifiers, addOns, note);

      // Update Bloc
      context.read<OrderBloc>().add(
        UpdateOrderItemDetails(
          index: index,
          modifiers: modifiers,
          addOns: addOns, // ✅ keep structured data
          note: note,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      shrinkWrap: true,
      itemCount: orderItems.length,
      separatorBuilder:
          (_, __) => Divider(height: 0, color: Theme.of(context).dividerColor),
      itemBuilder: (context, index) {
        final item = orderItems[index];
        print("Item Name: ${item.name}");
        // print("Variation Name: ${item.variationName}");
        // print("Product Name: ${item.productName}");
        return Dismissible(
          key: ValueKey('${item.name}-$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => onRemoveItem(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ), // final isDark = Theme.of(context).brightness == Brightness.dark;

              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius:
                    index == orderItems.length - 1
                        ? const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        )
                        : BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                    blurRadius: 1,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 7),

                  // Serial #
                  SizedBox(
                    width: 40, // fixed is OK
                    child: Text(
                      '${item.variationId ?? item.productId}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // ✅ Item name + modifiers → TAKE AVAILABLE SPACE
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (item.modifiers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _formatModifierList(
                                item.modifiers.cast<String>(),
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        if (item.addOns.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _formatAddOnsList(item.addOns),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        if (item.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Note: ${item.note}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Modifier Button
                  GestureDetector(
                    onTap:
                        item.hasOptions
                            ? () => _showModifierPopup(context, index)
                            : null,
                    child: Container(
                      width: 61,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color:
                            isDark
                                ? const Color(0xFF2B3042)
                                : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color:
                                item.hasOptions
                                    ? const Color(0xFFFFB820)
                                    : (isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        shadows: [
                          BoxShadow(
                            color:
                                isDark
                                    ? Colors.black26
                                    : (item.hasOptions
                                        ? const Color(0xFFFFFFFF)
                                        : Colors.black12),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        "Modifier",
                        style: TextStyle(
                          color:
                              item.hasOptions
                                  ? const Color(0xFFFFB820)
                                  : (isDark ? Colors.white54 : Colors.grey),
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Unit Price (fixed)
                  SizedBox(
                    width: 70,
                    child: Text(
                      // '₹${item.price.toStringAsFixed(2)}',
                      '$currency${item.price.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(width: 30),

                  // Quantity Controls (fixed)
                  Row(
                    children: [
                      _quantityButton(
                        context,
                        Icons.remove,
                        () => onDecreaseQuantity(index),
                      ),

                      const SizedBox(width: 3), // ✅ space between - and qty

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(width: 3), // ✅ space between qty and +

                      _quantityButton(
                        context,
                        Icons.add,
                        () => onIncreaseQuantity(index),
                      ),
                    ],
                  ),

                  const SizedBox(width: 5),

                  // Amount (fixed)
                  SizedBox(
                    width: 70,
                    child: Text(
                      // '₹${item.totalWithAddons.toStringAsFixed(2)}',
                      '$currency${item.totalWithAddons.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _quantityButton(
    BuildContext context,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFFFF6B5F) : Color(0xFFFCDFDC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onPressed,
        child: Center(
          child: Icon(
            icon,
            size: 15,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  String _formatModifierList(List<String> modifiers) {
    const limit = 2;
    if (modifiers.length <= limit) return modifiers.join(', ');
    final visible = modifiers.take(limit).join(', ');
    return '$visible +${modifiers.length - limit} More';
  }

  String _formatAddOnsList(Map<String, Map<String, dynamic>> addOns) {
    const limit = 2;
    final entries = addOns.entries.toList();

    String formatEntry(MapEntry<String, Map<String, dynamic>> e) {
      final qty = e.value['quantity'] as int? ?? 0;
      final price = (e.value['price'] as num?)?.toDouble() ?? 0.0;
      // return '${e.key} x$qty (₹${(qty * price).toStringAsFixed(2)})';
      return '${e.key} x$qty ($currency${(qty * price).toStringAsFixed(2)})';
    }

    if (entries.length <= limit) {
      return entries.map(formatEntry).join(', ');
    }

    final visible = entries.take(limit).map(formatEntry).join(', ');
    return '$visible +${entries.length - limit} More';
  }
}
