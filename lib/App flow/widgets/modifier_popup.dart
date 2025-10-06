import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/models/order/order_items.dart';
import '../../models/order/modifier_model.dart';
import '../../repositories/modifier_repository.dart';
import '../../utils/logger.dart';

class ModifierAddOnPopup extends StatefulWidget {
  final int productId;
  final String token;
  final OrderItems item; // ✅ keep the item

  const ModifierAddOnPopup({
    super.key,
    required this.productId,
    required this.token,
    required this.item,
  });

  @override
  State<ModifierAddOnPopup> createState() => _ModifierAddOnPopupState();
}

class _ModifierAddOnPopupState extends State<ModifierAddOnPopup> {
  List<Modifier> allItems = [];
  final Set<String> selectedModifiers = {};
  final Map<String, Map<String, dynamic>> selectedAddOns = {};
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

  bool get hasAnyOptions {
    return allItems.any((m) => m.type == 'modifier' || m.type == 'add-on');
  }

  @override
  void initState() {
    super.initState();

    // ✅ Pre-fill modifiers if item already has them
    if (widget.item.modifiers.isNotEmpty) {
      selectedModifiers.addAll(widget.item.modifiers);
    }

    // ✅ Pre-fill addons if item already has them
    if (widget.item.addOns.isNotEmpty) {
      widget.item.addOns.forEach((key, value) {
        selectedAddOns[key] = {
          'quantity': value['quantity'],
          'price': value['price'],
        };
      });
    }

    // ✅ Pre-fill note
    if (widget.item.note != null && widget.item.note!.isNotEmpty) {
      noteController.text = widget.item.note!;
    }

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
        height: 600,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : !hasAnyOptions
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.grey, size: 40),
              const SizedBox(height: 12),
              const Text(
                "No Modifiers or Add-ons available",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text("Close"),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Modifiers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      icon: const Icon(Icons.close,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Modifiers section
              if (modifiers.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: const Color(0xFFF06161), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: 900,
                  height: 150,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: modifiers.map((mod) {
                        final selected =
                        selectedModifiers.contains(mod.name);
                        return GestureDetector(
                          onTap: () => toggleModifier(mod.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8F8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    unselectedWidgetColor:
                                    const Color(0xFFF06161),
                                  ),
                                  child: Checkbox(
                                    value: selected,
                                    onChanged: (_) =>
                                        toggleModifier(mod.name),
                                    side: const BorderSide(
                                        color: Color(0xFFF06161),
                                        width: 1.5),
                                    activeColor:
                                    const Color(0xFFF06161),
                                    checkColor: Colors.white,
                                  ),
                                ),
                                Text(
                                  mod.name,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (addOns.isNotEmpty) ...[
                const Text(
                  'Add Ons',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: const Color(0xFF3C51DA), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  height: 200,
                  child: SingleChildScrollView(
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 2.0,
                      children: addOns.map((addon) {
                        final selected = selectedAddOns
                            .containsKey(addon.name);
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      unselectedWidgetColor:
                                      const Color(0xFF3C51DA),
                                    ),
                                    child: Checkbox(
                                      value: selected,
                                      onChanged: (_) =>
                                          toggleAddOn(addon.name,
                                              addon.price),
                                      side: const BorderSide(
                                          color: Color(0xFF3C51DA),
                                          width: 1.5),
                                      activeColor:
                                      const Color(0xFF3C51DA),
                                      checkColor: Colors.white,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${addon.name} +₹${addon.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              if (selected)
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          updateAddOnQuantity(
                                              addon.name, -1),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                              0xFF3C51DA),
                                          borderRadius:
                                          BorderRadius.circular(
                                              4),
                                        ),
                                        child: const Icon(
                                            Icons.remove,
                                            size: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${selectedAddOns[addon.name]!['quantity']}',
                                      style: const TextStyle(
                                          fontSize: 12),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () =>
                                          updateAddOnQuantity(
                                              addon.name, 1),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                              0xFF3C51DA),
                                          borderRadius:
                                          BorderRadius.circular(
                                              4),
                                        ),
                                        child: const Icon(Icons.add,
                                            size: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              const Text('Write a note',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              SizedBox(
                width: 900,
                height: 40,
                child: TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    hintText: 'Add note',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Total: ₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'modifiers': selectedModifiers.toList(),
                        'addOns': selectedAddOns,
                        'note': noteController.text,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF4D20)),
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
