import 'package:flutter/material.dart';

class ModifierAddOnPopup extends StatefulWidget {
  const ModifierAddOnPopup({super.key});

  @override
  State<ModifierAddOnPopup> createState() => _ModifierAddOnPopupState();
}

class _ModifierAddOnPopupState extends State<ModifierAddOnPopup> {
  final List<String> modifiers = [
    'Extra Onions', 'Salt', 'Low salt', 'Oil', 'Spicy', 'Mushrooms', 'Butter'
  ];
  final Set<String> selectedModifiers = {};

  final Map<String, double> addOns = {
    'Extra Cheese': 10.0,
    'Mayo': 8.0,
    'Raita': 10.0,
    'Olives': 8.5,
    'Paneer': 12.0,
    'Papad': 10.0,
    'Chilli Flakes': 6.0,

  };
  final Map<String, int> selectedAddOns = {};
  final Map<String, double> selectedAddOnPrices = {};

  final TextEditingController noteController = TextEditingController();

  double get total => selectedAddOns.entries.fold(
    0.0,
        (sum, e) => sum + (addOns[e.key]! * e.value),
  );

  void toggleModifier(String value) {
    setState(() {
      if (selectedModifiers.contains(value)) {
        selectedModifiers.remove(value);
      } else {
        selectedModifiers.add(value);
      }
    });
  }

  void toggleAddOn(String name) {
    setState(() {
      if (selectedAddOns.containsKey(name)) {
        selectedAddOns.remove(name);
      } else {
        selectedAddOns[name] = 1;
      }
    });
  }

  void updateAddOnQuantity(String name, int delta) {
    setState(() {
      final current = selectedAddOns[name] ?? 1;
      final updated = current + delta;
      if (updated <= 0) {
        selectedAddOns.remove(name);
      } else {
        selectedAddOns[name] = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: SizedBox(
        width: 800,
        height: 550,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Close icon
              Stack(
                alignment: Alignment.topRight,
                children: [
                  // Your main content below...
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 2),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.white),
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),


              const Text(
                'Select Modifiers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              /// Modifier Section with red border and background
              /// Modifier Section with red border and background
              // Scrollable Modifiers Section
              Container(
                height: 100,
                width:800,// set scrollable height
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(6),
                  thickness: 4,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: modifiers.map((mod) {
                        final selected = selectedModifiers.contains(mod);
                        return GestureDetector(
                          onTap: () => toggleModifier(mod),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8F8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: selected,
                                  onChanged: (_) => toggleModifier(mod),
                                  activeColor: Colors.red,
                                ),
                                Text(
                                  mod,
                                  style: TextStyle(
                                    color: selected ? Colors.red : Colors.black,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.none,
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
              ),


              const SizedBox(height: 24),
              const Text(
                'Add Ons',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),

              /// Addons Section with blue border and background
              Container(
                height: 130, // set scrollable height
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(6),
                  thickness: 4,
                  child: SingleChildScrollView(
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 2.0,
                      children: addOns.entries.map((entry) {
                        final selected = selectedAddOns.containsKey(entry.key);
                        return Container(
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFF2F6FF) : const Color(0xFFF2F6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: selected,
                                    onChanged: (_) => toggleAddOn(entry.key),
                                    activeColor: const Color(0xFF125BCE),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${entry.key} +${entry.value.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              if (selected)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF125BCE),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: InkWell(
                                        onTap: () => updateAddOnQuantity(entry.key, -1),
                                        child: const Icon(Icons.remove, size: 14, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('${selectedAddOns[entry.key]}',
                                        style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF125BCE),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: InkWell(
                                        onTap: () => updateAddOnQuantity(entry.key, 1),
                                        child: const Icon(Icons.add, size: 14, color: Colors.white),
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
              ),

              const SizedBox(height: 24),
              const Text(
                'Write a note',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: 'Write down description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Total : ₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.none,),

                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Future.delayed(Duration.zero, () {
                        Navigator.pop(context, {
                          'modifiers': selectedModifiers.toList(),
                          'addons': selectedAddOns,
                          'addonPrices': Map.fromEntries(
                            selectedAddOns.keys.map((key) => MapEntry(key, addOns[key]!)),
                          ),
                          'note': noteController.text,
                        });
                      });
                    },


                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
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
