import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/models/order/order_items.dart';
import '../../models/order/modifier_model.dart';
import '../../repositories/modifier_repository.dart';
import '../../utils/SessionManager.dart';
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
  String _currency = "₹";
  bool isLoading = true;

  double get total {
    double addonsTotal = selectedAddOns.entries.fold(0.0, (sum, e) {
      final qty = e.value['quantity'] ?? 0;
      final price = e.value['price'] ?? 0.0;
      return sum + (qty * price);
    });

    double modifiersTotal = selectedModifiers.fold(0.0, (sum, name) {
      final price = allItems.firstWhere((m) => m.name == name).price;
      return sum + price;
    });

    return addonsTotal + modifiersTotal;
  }

  bool get hasAnyOptions {
    return allItems.any((m) => m.type == 'modifier' || m.type == 'add-on');
  }

  @override
  void initState() {
    super.initState();
    _loadCurrency();
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

  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }

  Future<void> _fetchItems() async {
    final repo = ModifierRepository(token: widget.token);

    try {
      final items = await repo.fetchModifiersByProductId(widget.productId);
      setState(() {
        allItems = items;
        isLoading = false;
      });
      AppLogger.info(
        'Fetched ${items.length} modifiers/add-ons for product ${widget.productId}',
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF202433) : Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
      ),

      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : !hasAnyOptions
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 40,
                      ),
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Modifiers',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4B4B),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
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
                            color:
                                isDark
                                    ? const Color(0xFF34384F)
                                    : const Color(0xFFFFF8F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: 900,
                          height: 150,
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children:
                                  modifiers.map((mod) {
                                    final selected = selectedModifiers.contains(
                                      mod.name,
                                    );

                                    return GestureDetector(
                                      onTap: () => toggleModifier(mod.name),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isDark
                                                  ? const Color(0xFF34384F)
                                                  : const Color(0xFFFFF8F8),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                isDark
                                                    ? Colors.white24
                                                    : Colors.transparent,
                                          ),
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
                                                onChanged:
                                                    (_) => toggleModifier(
                                                      mod.name,
                                                    ),
                                                side: const BorderSide(
                                                  color: Color(0xFFF06161),
                                                  width: 1.5,
                                                ),
                                                activeColor: const Color(
                                                  0xFFF06161,
                                                ),
                                                checkColor: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              mod.name,
                                              style: TextStyle(
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : Colors.black,
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
                        Text(
                          'Add Ons',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF2B3042) : Colors.white,
                            border: Border.all(
                              color: const Color(0xFF3C51DA),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          height: 215,
                          child: SingleChildScrollView(
                            child: GridView.count(
                              crossAxisCount: 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                              childAspectRatio: 2.0,
                              children:
                                  addOns.map((addon) {
                                    final selected = selectedAddOns.containsKey(
                                      addon.name,
                                    );
                                    return Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isDark
                                                ? const Color(0xFF34384F)
                                                : const Color(0xFFF2F6FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              isDark
                                                  ? Colors.white24
                                                  : Colors.transparent,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Theme(
                                                data: Theme.of(
                                                  context,
                                                ).copyWith(
                                                  checkboxTheme: CheckboxThemeData(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ), // curve radius
                                                    ),
                                                    side: const BorderSide(
                                                      color: Color(0xFF3C51DA),
                                                      width: 1.5,
                                                    ),
                                                    fillColor:
                                                        MaterialStateProperty.resolveWith((
                                                          states,
                                                        ) {
                                                          if (states.contains(
                                                            MaterialState
                                                                .selected,
                                                          )) {
                                                            return const Color(
                                                              0xFF3C51DA,
                                                            );
                                                          }
                                                          return Colors
                                                              .transparent;
                                                        }),
                                                    checkColor:
                                                        MaterialStateProperty.all(
                                                          Colors.white,
                                                        ),
                                                  ),
                                                ),
                                                child: Checkbox(
                                                  value: selected,
                                                  onChanged:
                                                      (_) => toggleAddOn(
                                                        addon.name,
                                                        addon.price,
                                                      ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                              ),

                                              const SizedBox(width: 4),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      addon.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            isDark
                                                                ? Colors.white
                                                                : Colors.black,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 8),

                                                    Text(
                                                      '+ $_currency${addon.price.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            isDark
                                                                ? Colors.white70
                                                                : Colors
                                                                    .grey
                                                                    .shade600,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (selected)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap:
                                                      () => updateAddOnQuantity(
                                                        addon.name,
                                                        -1,
                                                      ),
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF3C51DA,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.remove,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${selectedAddOns[addon.name]!['quantity']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        isDark
                                                            ? Colors.white
                                                            : Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                InkWell(
                                                  onTap:
                                                      () => updateAddOnQuantity(
                                                        addon.name,
                                                        1,
                                                      ),
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF3C51DA,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.add,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
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

                      Text(
                        'Write a note',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        width: 900,
                        height: 40,
                        child: TextField(
                          controller: noteController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add note',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                            filled: true,
                            fillColor:
                                isDark ? const Color(0xFF34384F) : Colors.white,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF4D20)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Total: $_currency${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
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
                              backgroundColor: Color(0xFFFF4D20),
                            ),
                            child: const Text(
                              'Save & Continue',
                              style: TextStyle(
                                color: Colors.white, // text color
                                fontSize: 16, // optional font size
                                fontWeight: FontWeight.bold, // optional
                              ),
                            ),
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
