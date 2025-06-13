import 'package:flutter/material.dart';

/// A header widget for the table setup screen that manages area selection,
/// displays the back button with exit confirmation, and allows adding or deleting areas.
///
/// This widget displays:
/// - A back button that triggers a confirmation dialog before exiting the setup.
/// - The current title "Table Setup".
/// - A horizontal scrollable list of created area names as selectable chips.
/// - A button to add a new area.
///
/// The widget also manages clearing the input controllers when switching areas,
/// and shows a delete button for the currently selected area.
///
/// Callbacks and state controls are passed from the parent widget for full interaction.
class TableSetupHeader extends StatelessWidget {
  /// Controller for the area name input field.
  final TextEditingController areaNameController;

  /// Controller for the table name input field.
  final TextEditingController tableNameController;

  /// Controller for the seating capacity input field.
  final TextEditingController seatingCapacityController;

  /// List of all created area/zone names to display as selectable options.
  final List<String> createdAreaNames;

  /// Currently selected area/zone name. Used to highlight the selected chip.
  final String? currentAreaName;

  /// Callback triggered when the header's back button exit is confirmed.
  final VoidCallback onClose;

  /// Callback to notify the parent when a different area is selected from the chips.
  final Function(String) onAreaSelected;

  /// Callback to toggle the popup for adding a new area.
  final VoidCallback togglePopup;

  /// Callback to reset the data in the parent widget when exiting setup.
  final Function(VoidCallback) onResetData;

  /// Callback triggered when user confirms deletion of the currently selected area.
  final VoidCallback onDeleteAreaConfirmed;

  /// Flag to indicate whether the delete confirmation dialog is visible.
  final bool isDeleteConfirmationVisible;

  /// Creates a [TableSetupHeader] widget with the required controllers, state, and callbacks.
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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Back Button and Title
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
                      // Show confirmation dialog on back button press
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
                                        child: Text(
                                          'Stay Here',
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    SizedBox(
                                      width: 100,
                                      height: 40,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Reset data and close popup on confirmation
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
              // Title Text
              Text(
                "Table Setup",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15315E),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Area/Zone Selector Label
          Padding(
            padding: const EdgeInsets.only(left: 7.0),
            child: Text(
              "Area/Zone:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4C5F7D),
              ),
            ),
          ),
          SizedBox(height: 4),

          // Card containing horizontally scrollable list of area names and Add Area button
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
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
                                // Select this area and clear table name and seating capacity inputs
                                onAreaSelected(name);
                                tableNameController.clear();
                                seatingCapacityController.clear();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: name == currentAreaName ? Color(0xFFFFE1E1) : Color(0xFFF2F2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: name == currentAreaName ? Color(0xFFFF4D20) : Color(0xFFAFACAC),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    if (name == currentAreaName)
                                      GestureDetector(
                                        onTap: onDeleteAreaConfirmed,
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFEE796A),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Icon(Icons.close, size: 16, color: Colors.white),
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

                  // Button to open popup to add a new area
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
