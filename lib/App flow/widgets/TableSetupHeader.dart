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
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 15,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.white,
                          child: Container(
                            width: 440,
                            padding: EdgeInsets.all(20),
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
                                SizedBox(height: 18),
                                Text(
                                  'Finish Table Setup?',
                                  style: TextStyle(
                                    color: const Color(0xFF373535),
                                    fontSize: 25,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w900,
                                    height: 1.56,
                                  ),
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Your table arrangement has been saved successfully. \nYou can revisit and edit it anytime from the table management section.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFFA19999),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.38,
                                  ),
                                ),
                                SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      height: 40,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey.shade200,
                                          foregroundColor: Color(0xFF4C5F7D),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text('Stay Here', style: TextStyle(fontSize: 15)),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    SizedBox(
                                      width: 110,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          onResetData(() {});
                                          Navigator.of(context).pop();
                                          onClose();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFD93535),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text('Yes, Exit', style: TextStyle(fontSize: 15)),
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
              SizedBox(width: 10),
              Text(
                "Table Setup",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15315E),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4C5F7D),
              ),
            ),
          ),
          SizedBox(height: 4),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: name == currentAreaName ? Color(0xFFFFE1E1) : Color(0xFFF2F2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: name == currentAreaName ? Color(0xFFFF4D20) : Color(0xFFAFACAC),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(width: name == currentAreaName ? 8 : 0),
                                    if (name == currentAreaName)
                                      GestureDetector(
                                        onTap: () => onShowAreaOptions(name),
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          padding: EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFEE796A),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Image.asset('assets/edit.png'),
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
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: togglePopup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xF2E76757),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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