import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../providers/order_provider.dart';

class CancelItemDialog extends StatefulWidget {
  final String kotId;
  final List<dynamic> items;
  final OrderProvider orderProvider;

  const CancelItemDialog({
    super.key,
    required this.kotId,
    required this.items,
    required this.orderProvider,
  });

  @override
  State<CancelItemDialog> createState() => _CancelItemDialogState();
}

class _CancelItemDialogState extends State<CancelItemDialog> {
  final List<bool> selected = [];

  @override
  void initState() {
    super.initState();
    selected.addAll(
      List.generate(widget.items.length, (_) => false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Cancel Items"),
      content: SizedBox(
        width: 350,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (_, index) {
            final item =
            widget.items[index] as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Checkbox(
                    value: selected[index],
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
                    onChanged: (value) {
                      setState(() {
                        selected[index] = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      "1 × ${item['name']}",
                      style: TextStyle(
                        fontSize: 14,
                        color: selected[index]
                            ? Colors.red
                            : Colors.black,
                        decoration: selected[index]
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        ElevatedButton(
          onPressed: () async {
            final selectedItems = <Map<String, dynamic>>[];

            for (int i = 0; i < widget.items.length; i++) {
              if (selected[i]) {
                selectedItems.add(
                  widget.items[i]
                  as Map<String, dynamic>,
                );
              }
            }

            // Call provider method
            await widget.orderProvider.cancelItems(
              widget.kotId,
              selectedItems,
            );

            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text("Cancel Selected"),
        ),
      ],
    );
  }
}