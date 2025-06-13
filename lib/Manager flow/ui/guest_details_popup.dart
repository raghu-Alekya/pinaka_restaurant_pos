import 'package:flutter/material.dart';
import 'MainScreen.dart';

class GuestDetailsPopup extends StatefulWidget {
  final int index;
  final Map<String, dynamic> tableData;
  final Function({
  required int index,
  required int guestCount,
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

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: BoxConstraints(
              maxWidth: 600, // Set a reasonable max width for responsiveness
              minWidth: 300,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Makes height dynamic
              children: [
                Text(
                  "Select Guest Numbers",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(widget.tableData['capacity'], (index) {
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

                /// Action buttons
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

                        if (guestCount > 0) {
                          widget.updateTableGuestData(
                            index: widget.index,
                            guestCount: guestCount,
                          );
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Mainscreen(
                                  tableData: widget.placedTables[widget.index],
                                ),
                              ),
                            );
                          });
                        } else {
                          // Show validation message if needed
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
