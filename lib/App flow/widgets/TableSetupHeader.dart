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
  final VoidCallback onExitTableSetup;

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
    required this.onExitTableSetup,
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
                  color: isDark ? const Color(0xFF2B3042) : Colors.white,
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
                  backgroundColor:
                      isDark ? const Color(0xFF2B3042) : Colors.white,
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
                        barrierColor: Colors.black.withOpacity(0.72),
                        builder: (dialogContext) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 30,
                            ),
                            child: Container(
                              width: 556,
                              height: 263,
                              constraints: const BoxConstraints(maxWidth: 556),
                              padding: const EdgeInsets.fromLTRB(
                                30,
                                30,
                                30,
                                30,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors:
                                      isDark
                                          ? const [
                                            Color(0xFF46333A),
                                            Color(0xFF202433),
                                          ]
                                          : const [
                                            Color(0xFFF5D0D0),
                                            Color(0xFFFFF8F8),
                                            Colors.white,
                                          ],
                                  stops:
                                      isDark
                                          ? const [0.0, 1.0]
                                          : const [0.0, 0.45, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border(
                                  top: BorderSide(
                                    color: const Color(0xFFFF3B30),
                                    width: 6,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.45 : 0.22,
                                    ),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // --------------------------------------------------
                                  // ICON + TITLE + MESSAGE
                                  // --------------------------------------------------
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color:
                                              isDark
                                                  ? const Color(0xFF2A2F3D)
                                                  : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
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
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Finish Table Setup?',
                                                style: TextStyle(
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : const Color(
                                                            0xFF373535,
                                                          ),
                                                  fontSize: 28,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.2,
                                                ),
                                              ),

                                              const SizedBox(height: 10),

                                              Text(
                                                'Your table arrangement has been saved successfully.\n'
                                                'You can revisit and edit it anytime from the table management section.',
                                                style: TextStyle(
                                                  color:
                                                      isDark
                                                          ? Colors.white70
                                                          : const Color(
                                                            0xFF656161,
                                                          ),
                                                  fontSize: 16,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.45,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 28),

                                  // --------------------------------------------------
                                  // BUTTONS
                                  // --------------------------------------------------
                                  Padding(
                                    padding: const EdgeInsets.only(left: 100),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop();
                                              },
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    isDark
                                                        ? const Color(
                                                          0xFF2A2F3D,
                                                        )
                                                        : const Color(
                                                          0xFFF7F7F7,
                                                        ),
                                                foregroundColor:
                                                    isDark
                                                        ? Colors.white
                                                        : const Color(
                                                          0xFF373535,
                                                        ),
                                                side: BorderSide(
                                                  color:
                                                      isDark
                                                          ? Colors.white24
                                                          : const Color(
                                                            0xFFD8D8D8,
                                                          ),
                                                  width: 1.5,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: Text(
                                                'Stay Here',
                                                style: TextStyle(
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : const Color(
                                                            0xFF373535,
                                                          ),
                                                  fontSize: 16,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 20),

                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                onResetData(() {});
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop();
                                                onClose();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                elevation: 0,
                                                backgroundColor: const Color(
                                                  0xFFFF3B30,
                                                ),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: const Text(
                                                'Yes, Exit',
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
                        },
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
                  color: isDark ? Colors.white : const Color(0xFF15315E),
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
                color: isDark ? Colors.white70 : const Color(0xFF4C5F7D),
              ),
            ),
          ),
          SizedBox(height: 4),
          Card(
            elevation: isDark ? 0 : 2,
            color: isDark ? const Color(0xFF202433) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isDark ? Colors.white24 : Colors.transparent,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6,
              ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      name == currentAreaName
                                          ? (isDark
                                              ? const Color(0xFF4C81F1)
                                              : const Color(0xFFFFE1E1))
                                          : (isDark
                                              ? const Color(0xFF34384F)
                                              : const Color(0xFFF2F2F2)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        name == currentAreaName
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
                                        color:
                                            isDark
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
                                            color:
                                                isDark
                                                    ? const Color(0xFF4C81F1)
                                                    : const Color(0xFFEE796A),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: ColorFiltered(
                                            colorFilter:
                                                isDark
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
                      backgroundColor:
                          isDark
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
                          color: isDark ? Colors.white24 : Colors.transparent,
                        ),
                      ),
                    ),
                    child: const Text(
                      "+ Add Area",
                      style: TextStyle(color: Colors.white, fontSize: 13),
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
