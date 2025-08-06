import 'package:flutter/material.dart';

class ModifierPopup extends StatefulWidget {
  final List<String> initialSelectedModifiers;

  const ModifierPopup({super.key, this.initialSelectedModifiers = const []});

  @override
  State<ModifierPopup> createState() => _ModifierPopupState();
}

class _ModifierPopupState extends State<ModifierPopup> {
  final List<String> modifier = [
    'Extra Onions', 'Salt', 'low salt', 'Oil', 'Spicy', 'Butter',
    'cheese', 'salads', 'ketchup', 'sauces', 'chuteny', ' extra sambar',
    'fries', 'Salt', 'Oil', 'Spicy', 'Spicy', 'low salt',
  ];

  Set<String> selectedModifiers = {};
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedModifiers = widget.initialSelectedModifiers.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // ✅ Rectangle shape
      ),

      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title + Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Modifiers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 16,
                    child: Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Grid of modifiers with radio-style UI
            SizedBox(
              height: 180,
              child: GridView.builder(
                padding: const EdgeInsets.only(right: 10),
                itemCount: modifier.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 4,
                ),
                itemBuilder: (context, index) {
                  final item = modifier[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedModifiers.contains(item)) {
                          selectedModifiers.remove(item);
                        } else {
                          selectedModifiers.add(item);
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                            color: selectedModifiers.contains(item)
                                ? Colors.orange
                                : Colors.transparent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Select Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF202FFF),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  child: const Text('Select', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFECEBEB)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                color: Colors.white,
              ),
              child: TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write down description',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Save & Continue Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D20),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, selectedModifiers.toList());
                  },
                  child: const Text(
                    'Save & Continue',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
