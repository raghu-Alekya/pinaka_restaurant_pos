import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/reservation_list_screen.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/ReservationRepository.dart';
import '../../repositories/table_repository.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import 'package:flutter/services.dart';

class CreateReservationScreen extends StatefulWidget {
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final bool isEditMode;
  final Map<String, dynamic>? reservationData;

  const CreateReservationScreen({
    Key? key,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    this.isEditMode = false,
    this.reservationData,
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
  final ScrollController _areaScrollController = ScrollController();
  UserPermissions? _userPermissions;
  final ReservationRepository _reservationRepository = ReservationRepository();


  String selectedSlot = '';
  String selectedMeal = '';
  String selectedArea = '';
  Set<String> selectedTables = {};
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> allTables = [];
  List<Map<String, dynamic>> allZones = [];
  bool _isLoadingTables = true;
  List<String> availableMeals = [];
  Map<String, List<Map<String, dynamic>>> mealSlots = {};
  bool _isLoadingSlots = true;
  bool _isLoading = false;
  String? _originalSelectedTable;
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
  bool _isCalendarLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();

    if (widget.isEditMode && widget.reservationData != null) {
      final data = widget.reservationData!;
      _peopleController.text = data['people'] ?? '';
      _nameController.text = data['name'] ?? '';
      _contactController.text = data['phone'] ?? '';
      _priorityController.text = data['priority'] ?? '';
      selectedSlot = data['time'] ?? '';

      try {
        selectedDate = DateFormat('yyyy-MM-dd').parse(data['date'] ?? '');
      } catch (_) {
        selectedDate = DateTime.now();
      }

      selectedTables = {data['table'] ?? ''};
      _originalSelectedTable = data['table'];
      selectedArea = data['area'] ?? selectedArea;
    }

    _priorityFocusNode.addListener(() {
      if (_priorityFocusNode.hasFocus) {
        _showOverlay(context);
      } else {
        _removeOverlay();
      }
    });

    _loadZones();
    _fetchSlotsAndMeals();
  }

  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
      });
    }
  }
  Future<void> _fetchSlotsAndMeals() async {
    try {
      final data = await _tableRepository.getAllSlots(widget.token, selectedDate);
      final meals = List<String>.from(data['Meal'] ?? []);
      final restaurantData = data['data'][widget.restaurantId];
      final slotsMap = restaurantData['slots'] as Map<String, dynamic>;

      Map<String, List<Map<String, dynamic>>> parsedSlots = {};
      for (final meal in meals) {
        final List<dynamic> slotList = slotsMap[meal] ?? [];
        parsedSlots[meal] = slotList.cast<Map<String, dynamic>>();
      }
      String selectedMealTemp = '';
      String selectedSlotTemp = '';

      if (meals.isNotEmpty) {
        if (widget.isEditMode && widget.reservationData != null) {
          final reservationSlot = widget.reservationData!['time'];
          selectedMealTemp = meals.firstWhere(
                (meal) => parsedSlots[meal]?.any((slot) => slot['Time Slot'] == reservationSlot) ?? false,
            orElse: () => meals.first,
          );
          selectedSlotTemp = reservationSlot;
        } else {
          selectedMealTemp = meals.first;
          selectedSlotTemp = '';
        }
      }

      setState(() {
        availableMeals = meals;
        mealSlots = parsedSlots;
        _isLoadingSlots = false;
        selectedMeal = selectedMealTemp;
        selectedSlot = selectedSlotTemp;
      });
      if (selectedMealTemp.isNotEmpty && selectedDate != null) {
        await _fetchTables();
      }

    } catch (e) {
      debugPrint("Error fetching slots: $e");
      setState(() => _isLoadingSlots = false);
    }
  }

  void _loadZones() async {
    final zones = await _zoneRepository.getAllZones(widget.token);
    setState(() {
      allZones = zones;
      areas = zones.map((z) => z['zone_name'].toString()).toSet().toList();

      if (widget.isEditMode && widget.reservationData != null) {
        selectedArea = widget.reservationData!['area'] ?? selectedArea;
      }

      if (!areas.contains(selectedArea) && areas.isNotEmpty) {
        selectedArea = areas.first;
      }

      _isLoadingAreas = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedArea();
    });
  }

  Future<void> _fetchTables() async {
    if (selectedMeal.isEmpty || selectedDate == null) return;

    setState(() => _isLoadingTables = true);

    try {
      final fetched = await _tableRepository.getTablesBySlot(
        token: widget.token,
        meal: selectedMeal,
        date: DateFormat('yyyy-MM-dd').format(selectedDate),
      );

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

    setState(() => _isLoading = true);
    _saveReservation().whenComplete(() => setState(() => _isLoading = false));
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

  Future<void> _saveReservation() async {
    final response = widget.isEditMode
        ? await _reservationRepository.updateReservation(
      context: context,
      token: widget.token,
      reservationId: widget.reservationData?['reservation_id'] ?? 0,
      people: int.tryParse(_peopleController.text.trim()) ?? 1,
      name: _nameController.text.trim(),
      phone: _contactController.text.trim(),
      date: selectedDate,
      time: selectedSlot,
      tableNo: selectedTables.join(', '),
      slotType: selectedMeal,
      zoneName: selectedArea,
      restaurantName: widget.restaurantName,
      restaurantId: int.tryParse(widget.restaurantId) ?? 1,
      priority: _priorityController.text.trim(),
    )
        : await _reservationRepository.createReservation(
      context: context,
      token: widget.token,
      people: int.tryParse(_peopleController.text.trim()) ?? 1,
      name: _nameController.text.trim(),
      phone: _contactController.text.trim(),
      date: selectedDate,
      time: selectedSlot,
      tableNo: selectedTables.join(', '),
      slotType: selectedMeal,
      zoneName: selectedArea,
      restaurantName: widget.restaurantName,
      restaurantId: int.tryParse(widget.restaurantId) ?? 1,
      priority: _priorityController.text.trim(),
    );

    if (response == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: 500,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(50, 24, 70, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/success_mark.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isEditMode ? "Reservation Updated" : "Reservation Confirmed",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isEditMode
                          ? "Your reservation has been successfully updated."
                          : "Your reservation has been successfully confirmed.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFFA19A9A)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Reservation ID", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C5F7D))),
                        const SizedBox(width: 8),
                        const Text(":", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text("${response['reservation_id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow("Name", response['customer_name'] ?? ''),
                            _buildDetailRow("Mobile Number", response['customer_phone'] ?? ''),
                            _buildDetailRow("Guest Count", response['people_count'].toString()),
                            _buildDetailRow("Priority", response['priority_category'] ?? ''),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow("Area", response['zone_name'] ?? ''),
                            _buildDetailRow("Table Number", response['table_no'] ?? ''),
                            _buildDetailRow("Date", response['reservation_date'] ?? ''),
                            _buildDetailRow("Time", response['reservation_time'] ?? ''),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          // Optional: Handle SMS
                        },
                        child: Text(
                          widget.isEditMode ? "Resend SMS" : "Send via SMS",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservationListScreen(
                        pin: widget.pin,
                        token: widget.token,
                        restaurantId: widget.restaurantId,
                        restaurantName: widget.restaurantName,
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold,color: Color(0xFF4C5F7D))),
          Text(value,style: const TextStyle(fontWeight: FontWeight.w400,color: Colors.black)),
        ],
      ),
    );
  }

  void _scrollToSelectedArea() {
    final index = areas.indexOf(selectedArea);
    if (index != -1) {
      final buttonWidth = 100.0;
      _areaScrollController.animateTo(
        index * buttonWidth,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
        userPermissions: _userPermissions,
        onPermissionsReceived: (permissions) {
          setState(() {
            _userPermissions = permissions;
          });
        },
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
                            Expanded(flex: 3, child: _buildBookingDetailsCard()),
                            const SizedBox(width: 10),
                            Expanded(flex: 4, child: _buildSlotAvailabilityCard()),
                            const SizedBox(width: 10),
                            Expanded(flex: 6, child: _buildTableSelectionCard()),
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
            child: SizedBox(
              height: kBottomNavigationBarHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BottomNavBar(
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
                ],
              ),
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
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ReservationListScreen(
                    pin: widget.pin,
                    token: widget.token,
                    restaurantId: widget.restaurantId,
                    restaurantName: widget.restaurantName,
                  ),
                ),
              ),
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
                setState(() {
                  _isCalendarLoading = true;
                });

                final dateRange = await _reservationRepository.getReservationDateRange(widget.token);

                setState(() {
                  _isCalendarLoading = false;
                });

                if (dateRange != null) {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate.isBefore(dateRange.start) || selectedDate.isAfter(dateRange.end)
                        ? dateRange.start
                        : selectedDate,
                    firstDate: dateRange.start,
                    lastDate: dateRange.end,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      selectedSlot = '';
                      _isLoadingSlots = true;
                    });

                    await _fetchSlotsAndMeals();
                    await _fetchTables();
                  }
                } else {
                  _showError("Failed to load reservation date range.");
                }
              },
              child: Row(
                children: _isCalendarLoading
                    ? [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ]
                    : [
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
              controller: _areaScrollController,
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
              child: _isLoadingSlots
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : Scrollbar(
                thumbVisibility: true,
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: mealSlots[selectedMeal] == null
                      ? []
                      : mealSlots[selectedMeal]!.map((slot) {
                    final time = slot['Time Slot']?.trim();
                    final isActive = slot['is_active'] == true;
                    final isSelected = selectedSlot.trim() == time;
                    final parts = time.split(' ');
                    final formattedSlot = parts.length == 2
                        ? '${parts[0]}\n${parts[1]}'
                        : time;

                    return GestureDetector(
                      onTap: isActive
                          ? () {
                        setState(() {
                          selectedSlot = (selectedSlot == time)
                              ? ''
                              : time;
                        });
                      }
                          : null,
                      child: Stack(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE7FAEF)
                                  : isActive
                                  ? Colors.white
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : isActive
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              formattedSlot,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.black
                                    : Colors.grey,
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
              child: tablesToShow.isEmpty
                  ? const Center(
                child: Text(
                  "No Tables Available",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0A1B4D),
                  ),
                ),
              )
                  : GridView.builder(
                itemCount: tablesToShow.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.4,
                ),
                itemBuilder: (context, index) {
                  final table = tablesToShow[index];
                  final tableName = table['table_name'] ?? '';
                  final capacity = table['capacity'] ?? '';
                  final shape = table['shape']?.toLowerCase() ?? '';
                  final status = (table['status'] ?? '').toLowerCase();
                  final isSelected = selectedTables.contains(tableName);
                  final isOriginalTable = widget.isEditMode && tableName == _originalSelectedTable;

                  // Shape image path
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

                  // Colors
                  Color cardColor = Colors.white;
                  Color borderColor = Colors.grey.shade300;
                  Color textColor = Colors.black;
                  Color iconColor = Colors.green;
                  bool isClickable = true;

                  if (status == 'available') {
                    cardColor = isSelected ? const Color(0xFFE7FAEF) : Colors.white;
                    borderColor = isSelected ? Colors.green : Colors.grey.shade300;
                  } else if (status == 'reserve') {
                    cardColor = const Color(0xFFE0E0E0);
                    textColor = Colors.grey;
                    iconColor = Colors.grey;
                    if (!isOriginalTable) isClickable = false;
                  } else if (status == 'dine in' || status == 'ready to pay') {
                    cardColor = const Color(0xFFF7DDDB);
                    textColor = const Color(0xFFF44336);
                    iconColor = const Color(0xFFF44336);
                    if (!isOriginalTable) isClickable = false;
                  }

                  return GestureDetector(
                    onTap: isClickable
                        ? () {
                      setState(() {
                        selectedTables.clear();
                        selectedTables.add(tableName);
                      });
                    }
                        : null,
                    child: Stack(
                      children: [
                        Container(
                          decoration: isOriginalTable
                              ? BoxDecoration(
                            gradient: SweepGradient(
                              colors: [
                                Colors.blue,
                                Colors.green,
                                Colors.pink,
                                Colors.blue,
                              ],
                              stops: const [0.0, 0.33, 0.66, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          )
                              : BoxDecoration(
                            color: cardColor,
                            border: Border.all(
                              color: isSelected ? Colors.green : borderColor,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [BoxShadow(color: Colors.black12)],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(1.5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12.5),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          tableName,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Icon(Icons.group, size: 22, color: iconColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$capacity',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 17,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Image.asset(
                                        shapeAsset,
                                        width: 26,
                                        height: 26,
                                        fit: BoxFit.contain,
                                        color: iconColor,
                                        colorBlendMode: BlendMode.srcIn,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
            onPressed: _isLoading ? null : _validateAndSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: SizedBox(
              height: 20,
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
                    : Text(
                  widget.isEditMode
                      ? "Update Reservation"
                      : "Confirm Reservation",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  final Map<String, IconData> mealIcons = {
    'breakfast': Icons.wb_twilight,
    'lunch': Icons.wb_sunny_outlined,
    'dinner': Icons.nightlight_round,
  };

  Widget _mealTabs() {
    return Row(
      children: availableMeals.map((meal) {
        final isSelected = selectedMeal == meal;
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
                onTap: () async {
                  setState(() {
                    selectedMeal = meal;
                    selectedSlot = '';
                    _isLoadingTables = true;
                  });

                  await _fetchTables();
                },
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      mealIcons[meal.toLowerCase()] ?? Icons.fastfood,
                      size: 14,
                      color: isSelected ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      meal[0].toUpperCase() + meal.substring(1),
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
