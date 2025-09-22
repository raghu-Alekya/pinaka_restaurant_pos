import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/models/order/order_items.dart';
import '../../models/order/modifier_model.dart';
import '../../repositories/modifier_repository.dart';
import '../../utils/logger.dart';

class ModifierAddOnPopup extends StatefulWidget {
  final int productId;
  final String token;

  const ModifierAddOnPopup({
    super.key,
    required this.productId,
    required this.token, required OrderItems item,
  });

  @override
  State<ModifierAddOnPopup> createState() => _ModifierAddOnPopupState();
}

class _ModifierAddOnPopupState extends State<ModifierAddOnPopup> {
  List<Modifier> allItems = [];
  final Set<String> selectedModifiers = {};
  final Map<String, Map<String, dynamic>> selectedAddOns = {};
  // Example: {'Cheese': {'quantity': 2, 'price': 20.0}}
  final TextEditingController noteController = TextEditingController();

  bool isLoading = true;

  double get total {
    double addonsTotal = selectedAddOns.entries.fold(
      0.0,
          (sum, e) {
        final qty = e.value['quantity'] ?? 0;
        final price = e.value['price'] ?? 0.0;
        return sum + (qty * price);
      },
    );

    double modifiersTotal = selectedModifiers.fold(
      0.0,
          (sum, name) {
        final price = allItems.firstWhere((m) => m.name == name).price;
        return sum + price;
      },
    );

    return addonsTotal + modifiersTotal;
  }

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final repo = ModifierRepository(
      baseUrl: 'https://merchantrestaurant.alektasolutions.com',
      token: widget.token,
    );

    try {
      final items = await repo.fetchModifiersByProductId(widget.productId);
      setState(() {
        allItems = items;
        isLoading = false;
      });
      AppLogger.info(
          'Fetched ${items.length} modifiers/add-ons for product ${widget.productId}');
    } catch (e) {
      AppLogger.error('Failed to fetch modifiers/add-ons: $e');
      setState(() => isLoading = false);
    }
  }

  void toggleModifier(String name) {
    setState(() {
      if (selectedModifiers.contains(name)) {
        selectedModifiers.remove(name);
      } else {
        selectedModifiers.add(name);
      }
    });
  }

  void toggleAddOn(String name, double price) {
    setState(() {
      if (selectedAddOns.containsKey(name)) {
        selectedAddOns.remove(name);
      } else {
        selectedAddOns[name] = {'quantity': 1, 'price': price};
      }
    });
  }

  void updateAddOnQuantity(String name, int delta) {
    setState(() {
      if (!selectedAddOns.containsKey(name)) return;
      final current = selectedAddOns[name]!['quantity'] as int;
      final updated = current + delta;
      if (updated <= 0) {
        selectedAddOns.remove(name);
      } else {
        selectedAddOns[name]!['quantity'] = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modifiers = allItems.where((m) => m.type == 'modifier').toList();
    final addOns = allItems.where((m) => m.type == 'add-on').toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 800,
        height: 550,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              const SizedBox(height: 8),
              const Text('Select Modifiers',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),

              // Modifiers
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: modifiers.map((mod) {
                  final selected = selectedModifiers.contains(mod.name);
                  return GestureDetector(
                    onTap: () => toggleModifier(mod.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFF0F0)
                            : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: selected,
                            onChanged: (_) => toggleModifier(mod.name),
                            activeColor: Colors.red,
                          ),
                          Text(mod.name,
                              style: TextStyle(
                                  color: selected
                                      ? Colors.red
                                      : Colors.black)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Text('Add Ons',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),

              // AddOns
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 2.0,
                children: addOns.map((addon) {
                  final selected = selectedAddOns.containsKey(addon.name);
                  return Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE0F0FF)
                          : const Color(0xFFF2F6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: selected,
                              onChanged: (_) =>
                                  toggleAddOn(addon.name, addon.price),
                              activeColor: Colors.blue,
                            ),
                            Expanded(
                                child: Text(
                                    '${addon.name} +₹${addon.price.toStringAsFixed(2)}')),
                          ],
                        ),
                        if (selected)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () =>
                                    updateAddOnQuantity(addon.name, -1),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius:
                                      BorderRadius.circular(4)),
                                  child: const Icon(Icons.remove,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                  '${selectedAddOns[addon.name]!['quantity']}',
                                  style:
                                  const TextStyle(fontSize: 12)),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () =>
                                    updateAddOnQuantity(addon.name, 1),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius:
                                      BorderRadius.circular(4)),
                                  child: const Icon(Icons.add,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Text('Write a note',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                      hintText: 'Add note',
                      border: OutlineInputBorder())),

              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Total: ₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'modifiers': selectedModifiers.toList(),
                        'addOns': selectedAddOns, // ✅ send both quantity & price
                        'note': noteController.text,
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Save & Continue'),
                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
