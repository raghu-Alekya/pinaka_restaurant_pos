import 'dart:async';

import 'package:flutter/material.dart';
import '../../repositories/table_merge_repository.dart';
import '../../services/kds_seivices.dart';

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

    final parentTableName =
        tableData['table_name']?.toString() ??
        tableData['tableName']?.toString() ??
        '';

    final mergedTables =
        tableData['merged_tables']?.toString() ?? parentTableName;

    final zoneName =
        tableData['areaName']?.toString() ??
        tableData['zone_name']?.toString() ??
        '';

    try {
      final resData = await repository.deleteMergeTable(
        token: token,
        parentTableId: parentTableId,
        zoneId: zoneId,
        restaurantId: restaurantId,
      );

      if (resData['success'] == true) {
        // Notify Captain – tables unmerged / free
        unawaited(
          KdsMqttPublisher.notifyTablesUnmerged(
            restaurantId: restaurantId.toString(),
            parentTableId:
                parentTableId is int
                    ? parentTableId
                    : int.tryParse(parentTableId.toString()) ?? 0,
            parentTableName: parentTableName,
            zoneId: zoneId is int ? zoneId : int.tryParse(zoneId.toString()),
            zoneName: zoneName,
            mergedTables: mergedTables,
          ),
        );

        Navigator.of(context).pop();
        onUnmerge(index, tableData);
      }
    } catch (e) {
      debugPrint('Error unmerging table: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mergedTables =
        tableData['merged_tables'] ?? tableData['tableName'] ?? '';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        width: 500,
        height: 224,
        constraints: const BoxConstraints(maxWidth: 556),
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
        decoration: BoxDecoration(
          // Same gradient style as TableSetupHeader
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? const [Color(0xFF46333A), Color(0xFF202433)]
                    : const [
                      Color(0xFFF5D0D0),
                      Color(0xFFFFF8F8),
                      Colors.white,
                    ],
            stops: isDark ? const [0.0, 1.0] : const [0.0, 0.45, 1.0],
          ),

          borderRadius: BorderRadius.circular(22),

          // Same red top border
          border: const Border(
            top: BorderSide(color: Color(0xFFFF3B30), width: 6),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.22),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ============================================================
            // ICON + TITLE + MESSAGE
            // ============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning icon container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2F3D) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFFF3B30),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFE53935),
                    size: 38,
                  ),
                ),

                const SizedBox(width: 28),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unmerge Table(s)?',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF373535),
                            fontSize: 28,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Do you want to really unmerge ',
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors.white70
                                          : const Color(0xFF656161),
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                              TextSpan(
                                text: mergedTables.toString(),
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors.white
                                          : const Color(0xFF373535),
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  height: 1.45,
                                ),
                              ),
                              TextSpan(
                                text: ' ?',
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors.white70
                                          : const Color(0xFF656161),
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ============================================================
            // BUTTONS
            // ============================================================
            Padding(
              padding: const EdgeInsets.only(left: 100),
              child: Row(
                children: [
                  // --------------------------------------------------------
                  // NO / KEEP
                  // --------------------------------------------------------
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              isDark
                                  ? const Color(0xFF2A2F3D)
                                  : const Color(0xFFF7F7F7),
                          foregroundColor:
                              isDark ? Colors.white : const Color(0xFF373535),
                          side: BorderSide(
                            color:
                                isDark
                                    ? Colors.white24
                                    : const Color(0xFFD8D8D8),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'No, Keep It',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF373535),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // --------------------------------------------------------
                  // YES / UNMERGE
                  // --------------------------------------------------------
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _unmergeTable(context),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Yes, Unmerge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
