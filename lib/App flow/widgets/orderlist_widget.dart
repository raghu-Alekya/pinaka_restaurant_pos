import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../models/order/order_items.dart';
import 'modifier_popup.dart';

class OrderPanelList extends StatelessWidget {
  final List<OrderItems> orderItems;
  final Map<String, double> addonPrices; // addon name -> price
  final Function(int index) onIncreaseQuantity;
  final Function(int index) onDecreaseQuantity;
  final Function(
      int index,
      List<String> modifiers,
      Map<String, Map<String, dynamic>> addOns,
      String note,
      ) onModifiersChanged;
  final Function(int index) onRemoveItem;
  final String token;

  const OrderPanelList({
    Key? key,
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
      builder: (_) => ModifierAddOnPopup(
        item: item,
        productId: item.productId,
        token: token,
      ),
    );

    if (result != null) {
      final modifiers = List<String>.from(result['modifiers'] ?? []);
      final addOns = Map<String, Map<String, dynamic>>.from(result['addOns'] ?? {});
      final note = result['note'] as String? ?? '';

      // Callback to parent
      onModifiersChanged(index, modifiers, addOns, note);

      // Update Bloc
      context.read<OrderBloc>().add(
        UpdateOrderItemDetails(
          index: index,
          modifiers: modifiers,
          addOns: addOns,  // ✅ keep structured data
          note: note,
        ),
      );
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => onRemoveItem(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Container(
              padding: const EdgeInsets.all(2), // inner padding
              decoration: BoxDecoration(
                color: Colors.white, // white background
                borderRadius: BorderRadius.circular(6), // rounded corners
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 1,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width:7),
                  // Serial #
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${item.productId}', // ✅ use productId instead of id
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),



                  // Item Name + Modifiers + AddOns + Note
                  SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        if (item.modifiers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _formatModifierList(item.modifiers.cast<String>()),
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
                  SizedBox(
                    width: 60,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, color: Colors.red, size: 20),
                      onPressed: () => _showModifierPopup(context, index),
                    ),
                  ),
                  // Modifier Button
                  // SizedBox(
                  //   width: 60,
                  //   child: IconButton(
                  //     padding: EdgeInsets.zero,
                  //     icon: Icon(
                  //       Icons.add,
                  //       color: item.hasOptions ? Colors.red : Colors.grey, // 🔹 greyed if no options
                  //       size: 20,
                  //     ),
                  //     onPressed: item.hasOptions
                  //         ? () => _showModifierPopup(context, index)
                  //         : null, // 🔹 disabled if no modifiers/add-ons
                  //   ),
                  // ),

                  const SizedBox(width: 25),

                  // Quantity Controls
                  Row(
                    children: [
                      _quantityButton(Icons.remove, () => onDecreaseQuantity(index)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('${item.quantity}',
                            style: const TextStyle(fontSize: 14)),
                      ),
                      _quantityButton(Icons.add, () => onIncreaseQuantity(index)),
                    ],
                  ),
                  const SizedBox(width:10),

                  // Amount
                  SizedBox(
                    width: 62,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '₹${item.totalWithAddons.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
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

  Widget _quantityButton(IconData icon, VoidCallback? onPressed) {
    return Container(
      width: 30,
      height: 30,
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

  String _formatAddOnsList(Map<String, Map<String, dynamic>> addOns) {
    const limit = 2;
    final entries = addOns.entries.toList();

    String formatEntry(MapEntry<String, Map<String, dynamic>> e) {
      final qty = e.value['quantity'] as int? ?? 0;
      final price = (e.value['price'] as num?)?.toDouble() ?? 0.0;
      return '${e.key} x$qty (₹${(qty * price).toStringAsFixed(2)})';
    }

    if (entries.length <= limit) {
      return entries.map(formatEntry).join(', ');
    }

    final visible = entries.take(limit).map(formatEntry).join(', ');
    return '$visible +${entries.length - limit} More';
  }
}
