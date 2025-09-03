import 'package:flutter/material.dart';
import '../../models/order/order_items.dart';
import 'modifier_popup.dart';

class OrderPanelList extends StatelessWidget {
  final List<OrderItems> orderItems;
  final Map<String, double> addonPrices; // addon name -> price
  final Function(int index) onIncreaseQuantity;
  final Function(int index) onDecreaseQuantity;
  final Function(int index, List<String> modifiers, Map<String, int> addOns, String note) onModifiersChanged;
  final Function(int index) onRemoveItem;

  const OrderPanelList({
    Key? key,
    required this.orderItems,
    required this.addonPrices,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
    required this.onModifiersChanged,
    required this.onRemoveItem,
  }) : super(key: key);

  void _showModifierPopup(BuildContext context, int index) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ModifierAddOnPopup(item: orderItems[index]),
    );

    if (result != null) {
      final List<String> modifiers = List<String>.from(result['modifiers'] ?? []);
      final Map<String, int> addOns = Map<String, int>.from(result['addOns'] ?? {});
      final String note = result['note'] ?? '';

      onModifiersChanged(index, modifiers, addOns, note);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: orderItems.length,
      separatorBuilder: (_, __) => const Divider(height: 0.5),
      itemBuilder: (context, index) {
        final item = orderItems[index];

        return Dismissible(
          key: ValueKey('${item.name}-$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => onRemoveItem(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Serial #
                SizedBox(
                  width: 30,
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                ),

                // Item Name + Modifiers + AddOns + Note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),

                      if (item.modifiers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _formatModifierList(item.modifiers),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
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
                          ),
                        ),

                      if (item.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Note: ${item.note}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Modifier Button
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.red, size: 20),
                  onPressed: () => _showModifierPopup(context, index),
                ),

                // Quantity Controls
                Row(
                  children: [
                    _quantityButton(Icons.remove, () => onDecreaseQuantity(index)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('${item.quantity}', style: const TextStyle(fontSize: 14)),
                    ),
                    _quantityButton(Icons.add, () => onIncreaseQuantity(index)),
                  ],
                ),

                // Amount
                SizedBox(
                  width: 80,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '₹${_calculateTotal(item).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback? onPressed) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: const Color(0xFFFCDFDC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onPressed,
        child: Center(child: Icon(icon, size: 15, color: Colors.black)),
      ),
    );
  }

  String _formatModifierList(List<String> modifiers) {
    const limit = 2;
    if (modifiers.length <= limit) return modifiers.join(', ');
    final visible = modifiers.take(limit).join(', ');
    return '$visible +${modifiers.length - limit} More';
  }

  String _formatAddOnsList(Map<String, int> addOns) {
    const limit = 2;
    final entries = addOns.entries.toList();
    if (entries.length <= limit) {
      return entries.map((e) => '${e.key} x${e.value} ₹${(addonPrices[e.key] ?? 0) * e.value}').join(', ');
    }
    final visible = entries.take(limit).map((e) => '${e.key} x${e.value} ₹${(addonPrices[e.key] ?? 0) * e.value}').join(', ');
    return '$visible +${entries.length - limit} More';
  }

  double _calculateTotal(OrderItems item) {
    double addonsTotal = 0;
    item.addOns.forEach((key, qty) {
      addonsTotal += (addonPrices[key] ?? 0) * qty;
    });
    return item.price * item.quantity + addonsTotal;
  }
}
