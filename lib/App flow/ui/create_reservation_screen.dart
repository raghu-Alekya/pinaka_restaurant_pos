import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/table_repository.dart';
import '../../repositories/zone_repository.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import 'package:flutter/services.dart';

class CreateReservationScreen extends StatefulWidget {
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final UserPermissions? userPermissions;

  const CreateReservationScreen({
    Key? key,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    this.userPermissions,
  }) : super(key: key);

  @override
  State<CreateReservationScreen> createState() => _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final _peopleController = TextEditingController();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _priorityController = TextEditingController();
  final TableRepository _tableRepository = TableRepository();


  final List<String> timeSlots = [
    '09:00 AM', '09:15 AM', '09:30 AM', '09:45 AM', '10:00 AM',
    '10:15 AM', '10:30 AM', '10:45 AM', '11:00 AM', '11:15 AM',
    '11:30 AM', '11:45 AM', '12:00 PM', '12:15 PM'
  ];

  String selectedSlot = '';
  String selectedMeal = 'Breakfast';
  String selectedArea = 'Main Dining';
  Set<String> selectedTables = {};
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> allTables = [];
  List<Map<String, dynamic>> allZones = [];
  bool _isLoadingTables = true;

  final ZoneRepository _zoneRepository = ZoneRepository();
  List<String> areas = [];
  bool _isLoadingAreas = true;
  final List<Map<String, dynamic>> tables = List.generate(15, (index) {
    return {
      'name': 'T${index + 2}',
      'capacity': index % 3 == 0 ? 8 : 4,
    };
  });
  final FocusNode _priorityFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;


  @override
  void initState() {
    super.initState();

    _priorityFocusNode.addListener(() {
      if (_priorityFocusNode.hasFocus) {
        _showOverlay(context);
      } else {
        _removeOverlay();
      }
    });

    _loadZones();
    _fetchTables();
  }

  void _loadZones() async {
    final zones = await _zoneRepository.getAllZones(widget.token);
    setState(() {
      allZones = zones;
      areas = zones.map((z) => z['zone_name'].toString()).toSet().toList();
      if (!areas.contains(selectedArea) && areas.isNotEmpty) {
        selectedArea = areas.first;
      }
      _isLoadingAreas = false;
    });
  }

  Future<void> _fetchTables() async {
    try {
      final fetched = await _tableRepository.getAllTables(widget.token);

      setState(() {
        allTables = fetched;
        _isLoadingTables = false;
      });
    } catch (e) {
      setState(() => _isLoadingTables = false);
      debugPrint("Failed to load tables: $e");
    }
  }
  List<Map<String, dynamic>> get _filteredTablesByArea {
    final selectedZone = allZones.firstWhere(
          (zone) => zone['zone_name'] == selectedArea,
      orElse: () => <String, dynamic>{},
    );

    if (selectedZone.isEmpty) {
      print('No matching zone for: $selectedArea');
      return [];
    }

    final selectedZoneId = selectedZone['zone_id'];
    print('Selected Zone ID: $selectedZoneId');
    print('Filtering tables for zone_id: $selectedZoneId');

    return allTables.where((table) {
      return table['zone_id'].toString() == selectedZoneId.toString();
    }).toList();
  }
  void _validateAndSubmit() {
    final people = _peopleController.text.trim();
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();

    if (people.isEmpty) {
      _showError("Please enter the number of people.");
      return;
    }

    if (name.isEmpty) {
      _showError("Please enter the name.");
      return;
    }

    if (contact.isEmpty) {
      _showError("Please enter the contact details.");
      return;
    }

    if (selectedSlot.isEmpty) {
      _showError("Please select a time slot.");
      return;
    }

    if (selectedTables.isEmpty) {
      _showError("Please select at least one table.");
      return;
    }
    _saveReservation();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveReservation() {
    print("Reservation confirmed!");
  }


  void _showOverlay(BuildContext context) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _priorityController,
              builder: (_, value, __) => Text(
                value.text.isEmpty
                    ? "Specify your reservation (VIP, Birthday, Dinner)"
                    : value.text,
                style: TextStyle(
                  fontSize: 13,
                  color: value.text.isEmpty ? Colors.grey : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _priorityController.dispose();
    _priorityFocusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF1F1F3),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        userPermissions: widget.userPermissions,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10,0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(context),
                const SizedBox(height: 5),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildBookingDetailsCard()),
                            const SizedBox(width: 15),
                            Expanded(flex: 2, child: _buildSlotAvailabilityCard()),
                            const SizedBox(width: 15),
                            Expanded(flex: 3, child: _buildTableSelectionCard()),
                          ],
                        ),
                      ),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BottomNavBar(
            selectedIndex: 3,
            onItemTapped: (index) {
              NavigationHelper.handleNavigation(
                context,
                3,
                index,
                widget.pin,
                widget.token,
                widget.restaurantId,
                widget.restaurantName,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Back Button
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Back',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          const Text(
            "Table Reservation",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(width: 140),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: () async {
                final DateTime today = DateTime.now();
                final DateTime lastSelectableDate = today.add(const Duration(days: 7));

                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate.isBefore(today) || selectedDate.isAfter(lastSelectableDate)
                      ? today
                      : selectedDate,
                  firstDate: today,
                  lastDate: lastSelectableDate,
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(width: 260),
          _isLoadingAreas
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : Container(
            height: 40,
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: areas.isEmpty
                ? const Center(child: Text("No areas available"))
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: areas.map((area) {
                  final bool isSelected = selectedArea == area;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: TextButton(
                      onPressed: () => setState(() => selectedArea = area),
                      style: TextButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFFFD6464)
                            : Colors.transparent,
                        foregroundColor:
                        isSelected ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 13.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12.5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(area),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(width: 140),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return _styledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Booking Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          _buildLabeledField(
            "No. of People * :",
            _peopleController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 5),

          _buildLabeledField("Name *:", _nameController),
          const SizedBox(height: 5),

          _buildLabeledField(
            "Mobile Number *:",
            _contactController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 5),

          _buildLabeledField(
            "Priority/Category:",
            _priorityController,
            hint: "Specify your reservation (VIP, Birthday, Dinner)",
            focusNode: _priorityFocusNode,
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField(
      String label,
      TextEditingController controller, {
        String? hint,
        FocusNode? focusNode,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSlotAvailabilityCard() {
    return _styledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Slot Availability",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _mealTabs(),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Scrollbar(
                thumbVisibility: true,
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: timeSlots.map((slot) {
                    final isSelected = selectedSlot == slot;
                    final parts = slot.split(' ');
                    final formattedSlot =
                    parts.length == 2 ? '${parts[0]}\n${parts[1]}' : slot;

                    return GestureDetector(
                      onTap: () => setState(() => selectedSlot = slot),
                      child: Stack(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE7FAEF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              formattedSlot,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
                              top: 6,
                              right: 6,
                              child: CircleAvatar(
                                radius: 3,
                                backgroundColor: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelectionCard() {
    if (_isLoadingTables) {
      return const Center(child: CircularProgressIndicator());
    }

    final tablesToShow = _filteredTablesByArea;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xCCDEE8FF),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Table Selection Area",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: tablesToShow.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemBuilder: (context, index) {
                  final table = tablesToShow[index];
                  final tableName = table['table_name']?.toUpperCase() ?? '';
                  final capacity = table['capacity'] ?? '';
                  final shape = table['shape']?.toLowerCase() ?? '';
                  final isSelected = selectedTables.contains(tableName);

                  // Asset based shape icon
                  String shapeAsset;
                  switch (shape) {
                    case 'circle':
                      shapeAsset = 'assets/circle1.png';
                      break;
                    case 'square':
                      shapeAsset = 'assets/square1.png';
                      break;
                    case 'rectangle':
                      shapeAsset = 'assets/rectangle1.png';
                      break;
                    default:
                      shapeAsset = 'assets/square1.png';
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTables.clear();
                        selectedTables.add(tableName);
                      });
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE7FAEF) : Colors.white,
                            border: Border.all(
                              color: isSelected ? Colors.green : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) {
                                      setState(() {
                                        selectedTables.clear();
                                        selectedTables.add(tableName);
                                      });
                                    },
                                    activeColor: Colors.green,
                                    checkColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      tableName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const SizedBox(width: 4),
                                  const Icon(Icons.group, size: 22, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$capacity',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Image.asset(
                                    shapeAsset,
                                    width: 26,
                                    height: 26,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 10,
                            right: 10,
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _validateAndSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Confirm Reservation"),
          ),

        ],
      ),
    );
  }

  Widget _mealTabs() {
    final meals = [
      {'label': 'Breakfast', 'icon': Icons.wb_twilight},
      {'label': 'Lunch', 'icon': Icons.wb_sunny_outlined},
      {'label': 'Dinner', 'icon': Icons.nightlight_round},
    ];

    return Row(
      children: meals.map((meal) {
        final isSelected = selectedMeal == meal['label'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFFF5F7FF),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                const BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
                  : [],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => selectedMeal = meal['label'] as String),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      meal['icon'] as IconData,
                      size: 14,
                      color: isSelected ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      meal['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.red : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _styledCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xCCDEE8FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
