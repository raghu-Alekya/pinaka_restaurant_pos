import 'package:flutter/material.dart';
import '../../repositories/table_merge_repository.dart';

class UnmergeTablePopup extends StatelessWidget {
  final int index;
  final Map<String, dynamic> tableData;
  final Function(int, Map<String, dynamic>) onUnmerge;
  final String token;
  final TableMergeRepository repository;

  const UnmergeTablePopup({
    super.key,
    required this.index,
    required this.tableData,
    required this.onUnmerge,
    required this.token,
    required this.repository,
  });

  Future<void> _unmergeTable(BuildContext context) async {
    final parentTableId = tableData['table_id'] ?? 0;
    final zoneId = tableData['zone_id'] ?? 0;
    final restaurantId = tableData['restaurant_id'] ?? 0;

    try {
      final resData = await repository.deleteMergeTable(
        token: token,
        parentTableId: parentTableId,
        zoneId: zoneId,
        restaurantId: restaurantId,
      );

      if (resData['success'] == true) {
        Navigator.of(context).pop();
        onUnmerge(index, tableData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Table ${tableData['tableName']} unmerged successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resData['message'] ?? 'Unmerge failed'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unmerging table: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mergedTables = tableData['merged_tables'] ?? tableData['tableName'] ?? '';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color(0xFFFDFDFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                'assets/check-broken.png',
                width: 70,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure ?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                children: [
                  const TextSpan(text: 'Do you want to really unmerge the table(s): '),
                  TextSpan(
                    text: mergedTables,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F4F8),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'No, Keep It.',
                    style: TextStyle(color: Color(0xFF4C5F7D)),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFE6464),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _unmergeTable(context),
                  child: const Text(
                    'Yes, Unmerge!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}