// ✅ TableSetupHeader.dart
import 'package:flutter/material.dart';

class TableSetupHeader extends StatelessWidget {
  final TextEditingController areaNameController;
  final TextEditingController tableNameController;
  final TextEditingController seatingCapacityController;
  final List<String> createdAreaNames;
  final String? currentAreaName;
  final VoidCallback onClose;
  final Function(String) onAreaSelected;
  final VoidCallback togglePopup;
  final Function(VoidCallback) onResetData;
  final VoidCallback onDeleteAreaConfirmed;
  final bool isDeleteConfirmationVisible;
  final Function(String, String) onUpdateAreaName;
  final Function(String) onShowAreaOptions;
  final Function(String) onShowEditPopup;

  const TableSetupHeader({
    super.key,
    required this.areaNameController,
    required this.tableNameController,
    required this.seatingCapacityController,
    required this.createdAreaNames,
    required this.currentAreaName,
    required this.onClose,
    required this.onAreaSelected,
    required this.togglePopup,
    required this.onResetData,
    required this.onDeleteAreaConfirmed,
    required this.isDeleteConfirmationVisible,
    required this.onUpdateAreaName,
    required this.onShowAreaOptions,
    required this.onShowEditPopup,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF2B3042)
                      : Colors.white,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black54 : Colors.black26,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: isDark
                      ? const Color(0xFF2B3042)
                      : Colors.white,
                  radius: 15,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          child: Container(
                            width: 440,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF202433)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Image.asset(
                                    'assets/check-broken.png',
                                    width: 80,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Finish Table Setup?',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF373535),
                                    fontSize: 24,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    height: 1.56,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Your table arrangement has been saved successfully.\n'
                                      'You can revisit and edit it anytime from the table management section.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFFA19999),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.38,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 180,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          backgroundColor: isDark
                                              ? const Color(0xFF34384F)
                                              : Colors.grey.shade200,
                                          foregroundColor: isDark
                                              ? Colors.white
                                              : const Color(0xFF4C5F7D),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            side: BorderSide(
                                              color: isDark
                                                  ? Colors.white24
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text(
                                          'Stay Here',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: isDark ? Colors.white : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 180,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          onResetData(() {});
                                          Navigator.of(context).pop();
                                          onClose();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          backgroundColor: const Color(0xFFD93535),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Text(
                                          'Yes, Exit',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                          ),
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
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Text(
              //   "Table Setup",
              //   style: TextStyle(
              //     fontSize: 17,
              //     fontWeight: FontWeight.w800,
              //     color: isDark
              //         ? Colors.white
              //         : const Color(0xFF15315E),
              //   ),
              // ),
              SizedBox(width: 10),
              Text(
                "Table Setup",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF15315E),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 7.0),
            child: Text(
              "Area/Zone:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white70
                    : const Color(0xFF4C5F7D),
              ),
            ),
          ),
          SizedBox(height: 4),
          Card(
            elevation: isDark ? 0 : 2,
            color: isDark
                ? const Color(0xFF202433)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isDark
                    ? Colors.white24
                    : Colors.transparent,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(createdAreaNames.length, (i) {
                          final name = createdAreaNames[i];

                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: GestureDetector(
                              onTap: () {
                                onAreaSelected(name);
                                tableNameController.clear();
                                seatingCapacityController.clear();
                              },
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: name == currentAreaName
                                      ? (isDark
                                      ? const Color(0xFF4C81F1)
                                      : const Color(0xFFFFE1E1))
                                      : (isDark
                                      ? const Color(0xFF34384F)
                                      : const Color(0xFFF2F2F2)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: name == currentAreaName
                                        ? (isDark
                                        ? const Color(0xFF4C81F1)
                                        : const Color(0xFFFF4D20))
                                        : (isDark
                                        ? Colors.white24
                                        : const Color(0xFFAFACAC)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(
                                      width: name == currentAreaName ? 8 : 0,
                                    ),
                                    if (name == currentAreaName)
                                      GestureDetector(
                                        onTap: () => onShowAreaOptions(name),
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF4C81F1)
                                                : const Color(0xFFEE796A),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: ColorFiltered(
                                            colorFilter: isDark
                                                ? const ColorFilter.mode(
                                              Colors.white,
                                              BlendMode.srcIn,
                                            )
                                                : const ColorFilter.mode(
                                              Colors.transparent,
                                              BlendMode.dst,
                                            ),
                                            child: Image.asset(
                                              'assets/edit.png',
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: togglePopup,
                    style: ElevatedButton.styleFrom(
                      elevation: isDark ? 0 : 2,
                      backgroundColor: isDark
                          ? const Color(0xFF4C81F1)
                          : const Color(0xF2E76757),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: const Text(
                      "+ Add Area",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}