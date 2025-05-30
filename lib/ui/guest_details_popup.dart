import 'package:flutter/material.dart';

import 'MainScreen.dart';

class GuestDetailsPopup extends StatefulWidget {
  final int index;
  final Map<String, dynamic> tableData;
  final Function({
  required int index,
  required int guestCount,
  required String customerName,
  required String captain,
  }) updateTableGuestData;
  final List<Map<String, dynamic>> placedTables;

  const GuestDetailsPopup({
    super.key,
    required this.index,
    required this.tableData,
    required this.updateTableGuestData,
    required this.placedTables,
  });

  @override
  State<GuestDetailsPopup> createState() => _GuestDetailsPopupState();
}

class _GuestDetailsPopupState extends State<GuestDetailsPopup> {
  List<int> selectedGuests = [];
  String selectedCaptain = '';
  TextEditingController customerController = TextEditingController();

  final List<Map<String, String>> captains = [
    {'name': 'A Raghav kumar', 'image': 'assets/loginname.png'},
    {'name': 'Anand vijay', 'image': 'assets/loginname.png'},
    {'name': 'mohan krishna', 'image': 'assets/loginname.png'},
    {'name': 'shak khalil', 'image': 'assets/loginname.png'},
    {'name': 'jagadeesh', 'image': 'assets/loginname.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 840,
          height: 500,
          padding: const EdgeInsets.all(45),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Select Guest Numbers",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(18, (index) {
                    int guest = index + 1;
                    bool isSelected = selectedGuests.contains(guest);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGuests = List.generate(guest, (i) => i + 1);
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE4E4E7)
                              : const Color(0xFFF6F6F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$guest',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.black
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Text("Customer Name",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Container(
                  width: 650,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: customerController,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "enter the customer name",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text("Choose Captain",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: captains.map((captain) {
                      bool isSelected = selectedCaptain == captain['name'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            selectedCaptain = captain['name']!;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF4D20)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF4D20)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                  AssetImage(captain['image']!),
                                  radius: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  captain['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Back",
                        style:
                        TextStyle(color: Color(0xFF4C5F7D), fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      onPressed: () {
                        final guestCount = selectedGuests.length;
                        final customerName = customerController.text.trim();

                        if (guestCount > 0 &&
                            customerName.isNotEmpty &&
                            selectedCaptain.isNotEmpty) {
                          widget.updateTableGuestData(
                            index: widget.index,
                            guestCount: guestCount,
                            customerName: customerName,
                            captain: selectedCaptain,
                          );
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Mainscreen(
                                  tableData:
                                  widget.placedTables[widget.index],
                                ),
                              ),
                            );
                          });
                        } else {
                          // Show error
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4D20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "SELECT AND CONTINUE",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
