import 'package:flutter/material.dart';
import '../models/order/order_model.dart';
import 'modifier_popup.dart';

class OrderPanelList extends StatelessWidget {
  final List<OrderItems> orderItems;
  final Function(int index) onIncreaseQuantity;
  final Function(int index) onDecreaseQuantity;
  final Function(int index, List<String> modifiers) onModifiersChanged;

  const OrderPanelList({
    Key? key,
    required this.orderItems,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
    required this.onModifiersChanged,
  }) : super(key: key);

  void _showModifierPopup(BuildContext context, int index) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => const ModifierPopup(),
    );

    if (result != null) {
      onModifiersChanged(index, result);
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

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Serial #
              SizedBox(
                width: 40,
                child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
              ),

              // Item Name with Modifier Chips below
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 14)),
                    if (item.modifiers.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: item.modifiers.map((modifier) {
                          return Text(
                            modifier,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFF4D20),
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),

                  ],
                ),
              ),

              // Modifier Icon Button
              SizedBox(
                width: 100,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add, size: 20, color: Colors.red),
                  onPressed: () => _showModifierPopup(context, index),
                  tooltip: 'Add Modifier',
                ),
              ),

              // Quantity Controls
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _quantityButton(Icons.remove, () => onDecreaseQuantity(index)),
                    const SizedBox(width: 6),
                    Text('${item.quantity}', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    _quantityButton(Icons.add, () => onIncreaseQuantity(index)),
                  ],
                ),
              ),

              // Amount
              SizedBox(
                width: 75,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    (item.price * item.quantity).toStringAsFixed(2),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: const Color(0xFFFCDFDC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: 15,
              color: Colors.black, // optional color
            ),
          ),
        ),
      ),
    );
  }


}
