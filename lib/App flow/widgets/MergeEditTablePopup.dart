import 'package:flutter/material.dart';

class MergeEditTablePopup extends StatelessWidget {
  final int index;
  final Map<String, dynamic> tableData;
  final Function(int, Map<String, dynamic>) onMergeEdit;

  const MergeEditTablePopup({
    super.key,
    required this.index,
    required this.tableData,
    required this.onMergeEdit,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> availableParent = [
      "Table 1",
      "Table 2",
      "Table 3",
      "Table 4",
      "Table 5",
      "Table 6",
      "Table 7",
    ];
    final List<String> runningParent = [
      "Table 7",
      "Table 8",
      "Table 9",
      "Table 10",
    ];
    final List<String> childTables = [
      "Table 1",
      "Table 2",
      "Table 3",
      "Table 4",
      "Table 5",
      "Table 6",
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      contentPadding: const EdgeInsets.all(20),
      content: SizedBox(
        width: 800,
        height: 480,
        child: Column(
          children: [
            /// Title + Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 28),
                const Expanded(
                  child: Text(
                    "Merge/Edit Table",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5A5A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: "Choose a parent table and one or more child tables to merge within the ",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54),
                  ),
                  TextSpan(
                    text: "${tableData['areaName']}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const TextSpan(
                    text: " area. The parent table will act as the primary table, and all selected child tables will be combined under it.",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),

            /// Two panels side by side
            Expanded(
              child: Row(
                children: [
                  // Left Panel
                  Expanded(
                    child: _buildPanel(
                      title: "Choose Table to merge (Parent) Available :",
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: availableParent.map((t) {
                            return _buildTableButton(t, Color(0xFFBDECC7));
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Choose Table to merge (Parent) Running :",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: runningParent.map((t) {
                            return _buildTableButton(t, Color(0xFFF3C0C3));
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Right Panel
                  Expanded(
                    child: _buildPanel(
                      title: "Choose Table to merge With (Child) Available :",
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: childTables.map((t) {
                            return _buildTableButton(t,
                                t == "Table 2" ? Color(0xFFD9D9D9) : Color(0xFFBDECC7));
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Merge Button
            SizedBox(
              width: 220,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onMergeEdit(index, tableData);
                },
                child: const Text(
                  "Merge & Proceed",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTableButton(String label, Color color) {
    return Container(
      width: 150,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
      ),
    );
  }
}
