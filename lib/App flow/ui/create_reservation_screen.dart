import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/reservation_list_screen.dart';
import 'package:provider/provider.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/ReservationRepository.dart';
import '../../repositories/table_repository.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/PermissionHandler.dart';
import '../../utils/SessionManager.dart';
import '../../utils/theme_provider.dart';
import '../widgets/ReservationMergePopup.dart';
import '../widgets/ReservationUnmergePopup.dart';
import '../widgets/area_movement_notifier.dart';
import '../widgets/confirmation_pop_up.dart';
import '../widgets/top_bar.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';

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
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
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
  // final ScrollController _areaScrollController = ScrollController();

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
  final ZoneRepository _zoneRepository = ZoneRepository();
  Map<String, String> selectedSlotPerMeal = {};
  List<String> areas = [];
  bool _isLoadingAreas = true;
  final List<Map<String, dynamic>> tables = List.generate(15, (index) {
    return {'name': 'T${index + 2}', 'capacity': index % 3 == 0 ? 8 : 4};
  });
  final FocusNode _priorityFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  bool _isCalendarLoading = false;
  late String _originalSelectedTable;
  late String _originalSelectedSlot;
  bool _hasUnsavedChanges = false;
  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _peopleController.addListener(_markDirty);
    _nameController.addListener(_markDirty);
    _contactController.addListener(_markDirty);
    _priorityController.addListener(_markDirty);
    print("initState called");
    if (widget.isEditMode && widget.reservationData != null) {
      final data = widget.reservationData!;
      _peopleController.text = data['people'] ?? '';
      _nameController.text = data['name'] ?? '';
      _contactController.text = data['phone'] ?? '';
      _priorityController.text = data['priority'] ?? '';

      selectedSlot = data['time'] ?? '';
      _originalSelectedSlot = selectedSlot;
      _originalSelectedTable = data['table'] ?? '';

      try {
        selectedDate = DateFormat('yyyy-MM-dd').parse(data['date'] ?? '');
      } catch (_) {
        selectedDate = DateTime.now();
      }

      selectedTables = {_originalSelectedTable};
      selectedArea = data['area'] ?? selectedArea;
    } else {
      _originalSelectedSlot = '';
      _originalSelectedTable = '';
    }

    _priorityFocusNode.addListener(() {
      if (_priorityFocusNode.hasFocus) {
        _showOverlay(context);
      } else {
        _removeOverlay();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.addListener(() {
        if (!_priorityFocusNode.hasFocus) {
          _removeOverlay();
        }
      });
    });
    _loadZones();
    _fetchSlotsAndMeals().then((_) {
      _fetchTables();
    });
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
    if (widget.isEditMode && widget.reservationData != null) {
      final data = widget.reservationData!;
      _peopleController.text = data['people'] ?? '';
      _nameController.text = data['name'] ?? '';
      _contactController.text = data['phone'] ?? '';
      _priorityController.text = data['priority'] ?? '';

      selectedSlot = data['time'] ?? '';
      _originalSelectedSlot = selectedSlot;
      _originalSelectedTable = data['table'] ?? '';

      try {
        selectedDate = DateFormat('yyyy-MM-dd').parse(data['date'] ?? '');
      } catch (_) {
        selectedDate = DateTime.now();
      }

      selectedTables = {_originalSelectedTable};
      selectedArea = data['area'] ?? selectedArea;
    } else {
      _originalSelectedSlot = '';
      _originalSelectedTable = '';
    }

    _priorityFocusNode.addListener(() {
      if (_priorityFocusNode.hasFocus) {
        _showOverlay(context);
      } else {
        _removeOverlay();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.addListener(() {
        if (!_priorityFocusNode.hasFocus) {
          _removeOverlay();
        }
      });
    });
    _loadZones();
    _fetchSlotsAndMeals().then((_) {
      _fetchTables();
    });
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
      final data = await _tableRepository.getAllSlots(
        widget.token,
        selectedDate,
      );
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

      if (widget.isEditMode && widget.reservationData != null) {
        final reservationSlot = widget.reservationData!['time'];
        selectedMealTemp = meals.firstWhere(
              (meal) =>
          parsedSlots[meal]?.any(
                (slot) => slot['Time Slot'] == reservationSlot,
          ) ??
              false,
          orElse: () => meals.first,
        );
        selectedSlotTemp = reservationSlot;
      } else if (meals.isNotEmpty) {
        outerLoop:
        for (var meal in meals) {
          final slots = parsedSlots[meal] ?? [];
          for (var slot in slots) {
            if (slot['is_active'] == true) {
              selectedMealTemp = meal;
              selectedSlotTemp = slot['Time Slot']?.trim() ?? '';
              break outerLoop;
            }
          }
        }
        if (selectedSlotTemp.isEmpty && meals.isNotEmpty) {
          final firstMealSlots = parsedSlots[meals.first] ?? [];
          if (firstMealSlots.isNotEmpty) {
            selectedMealTemp = meals.first;
            selectedSlotTemp = firstMealSlots.first['Time Slot']?.trim() ?? '';
          }
        }

        if (selectedSlotTemp.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchTables();
          });
        }
      }
      setState(() {
        availableMeals = meals;
        mealSlots = parsedSlots;
        _isLoadingSlots = false;
        selectedMeal = selectedMealTemp;
        selectedSlot = selectedSlotTemp;
      });
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
    if (selectedSlot.isEmpty || selectedDate == null) return;

    setState(() => _isLoadingTables = true);

    try {
      final fetched = await _tableRepository.getTablesByTime(
        token: widget.token,
        reservationTime: selectedSlot,
        reservationDate: DateFormat('yyyy-MM-dd').format(selectedDate),
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

    final filtered =
    allTables.where((table) {
      return table['zone_id'].toString() == selectedZoneId.toString();
    }).toList();
    filtered.sort((a, b) {
      final nameA = a['table_name']?.toString() ?? '';
      final nameB = b['table_name']?.toString() ?? '';
      final numA = int.tryParse(RegExp(r'\d+').stringMatch(nameA) ?? '') ?? 0;
      final numB = int.tryParse(RegExp(r'\d+').stringMatch(nameB) ?? '') ?? 0;

      if (numA != numB) return numA.compareTo(numB);
      return nameA.compareTo(nameB);
    });

    return filtered;
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
    if (contact.length != 10) {
      _showError("Please enter a valid 10-digit mobile number.");
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
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _saveReservation() async {
    final response =
    widget.isEditMode
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
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    if (response == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark
            ? const Color(0xFF1F2937)
            : Colors.white,
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
                      widget.isEditMode
                          ? "Reservation Updated"
                          : "Reservation Confirmed",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isEditMode
                          ? "Your reservation has been successfully updated."
                          : "Your reservation has been successfully confirmed.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFFA19A9A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Reservation ID",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF4C5F7D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ":",
                          style: TextStyle(fontWeight: FontWeight.bold,   color: isDark ? Colors.white : Colors.black,),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${response['reservation_id']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
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
                            _buildDetailRow(
                              "Name",
                              response['customer_name'] ?? '',
                              isDark,
                            ),
                            _buildDetailRow(
                              "Mobile Number",
                              response['customer_phone'] ?? '',
                              isDark,
                            ),
                            _buildDetailRow(
                              "Guest Count",
                              response['people_count'].toString(),
                              isDark,
                            ),
                            _buildDetailRow(
                              "Priority",
                              response['priority_category'] ?? '',
                              isDark,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              "Area",
                              response['zone_name'] ?? '',  isDark,

                            ),
                            _buildDetailRow(
                              "Table Number",
                              response['table_no'] ?? '',
                              isDark,
                            ),
                            _buildDetailRow(
                              "Date",
                              response['reservation_date'] ?? '',
                              isDark,
                            ),
                            _buildDetailRow(
                              "Time",
                              response['reservation_time'] ?? '',
                              isDark,
                            ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                      builder:
                          (context) => ReservationListScreen(
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

  Widget _buildDetailRow(
      String label,
      String value,
      bool isDark,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Colors.white
                  : const Color(0xFF4C5F7D),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.grey.shade300
                  : Colors.black,
            ),
          ),
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
      builder:
          (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
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
              builder:
                  (_, value, __) => Text(
                value.text.isEmpty
                    ? "Specify your reservation (VIP, Birthday, Dinner)"
                    : value.text,
                style: TextStyle(
                  fontSize: 13,
                  color:
                  value.text.isEmpty ? Colors.grey : Colors.black,
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
    _areaScrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _areaScrollController.animateTo(
      (_areaScrollController.offset - 120).clamp(
        0.0,
        _areaScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _areaScrollController.animateTo(
      (_areaScrollController.offset + 120).clamp(
        0.0,
        _areaScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _scrollButton({required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        shape: const CircleBorder(),
        side: BorderSide(color: Colors.grey.shade300),
        elevation: 2,
        minimumSize: const Size(30, 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor:
      isDark ? const Color(0xFF111827) : const Color(0xFFF6F6F6),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        userPermissions: _userPermissions,
        onHomePressed: () async {
          if (!_hasUnsavedChanges) return true;

          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder:
                (_) => ConfirmationPopup(
              title: "Discard Reservation?",
              message:
              "You have unsaved reservation details. Do you want to leave this page?",
              imagePath: "assets/warning_icon.png",
              isLoading: false,
              cancelButtonText: "Stay",
              confirmButtonText: "Leave",
              onCancel: () => Navigator.pop(context, false),
              onConfirm: () => Navigator.pop(context, true),
            ),
          );

          return result ?? false;
        },
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(context, isDark),
                const SizedBox(height: 5),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildBookingDetailsCard(isDark),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 5,
                              child: _buildSlotAvailabilityCard(isDark),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 7,
                              child: _buildTableSelectionCard(isDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _summaryBox(
                            title: "Date:",
                            value: DateFormat(
                              'dd/MM/yyyy',
                            ).format(selectedDate),
                            bgColor: const Color(0xFFFFEDEC),
                            borderColor: const Color(0xFFFFA69E),
                            titleColor: const Color(0xFFFF354D),
                          ),

                          const SizedBox(width: 12),

                          _summaryBox(
                            title: "Meal:",
                            value: selectedMeal.isEmpty ? "--" : selectedMeal,
                            bgColor: const Color(0xFFECFDF5),
                            borderColor: const Color(0xFFA7F3D0),
                            titleColor: const Color(0xFF059669),
                          ),

                          const SizedBox(width: 12),

                          _summaryBox(
                            title: "Tables:",
                            value:
                            selectedTables.isEmpty
                                ? "--"
                                : selectedTables.join(", "),
                            bgColor: const Color(0xFFECF2FF),
                            borderColor: const Color(0xFFA0BFFF),
                            titleColor: const Color(0xFF386EDA),
                          ),

                          const Spacer(),

                          _buildActionButtons(isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryBox({
    required String title,
    required String value,
    required Color bgColor,
    required Color borderColor,
    required Color titleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12171E) : bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Table Reservation",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                "Select a time and choose your table",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF12171E) // same dark background as your cards
                  : Colors.white,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF374151) // dark border
                    : Colors.grey.shade300,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isDark
                  ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : [
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () async {
                setState(() {
                  _isCalendarLoading = true;
                });

                final dateRange = await _reservationRepository
                    .getReservationDateRange(widget.token);

                setState(() {
                  _isCalendarLoading = false;
                });

                if (dateRange != null) {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate:
                    selectedDate.isBefore(dateRange.start) ||
                        selectedDate.isAfter(dateRange.end)
                        ? dateRange.start
                        : selectedDate,
                    firstDate: dateRange.start,
                    lastDate: dateRange.end,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark
                              ? const ColorScheme.dark(
                            primary: Color(0xFFFFFFFF), // Selected date background
                            onPrimary: Colors.black,    // Selected date text
                            surface: Color(0xFF1F2937), // Calendar background
                            onSurface: Colors.white,    // Calendar text
                          )
                              : Theme.of(context).colorScheme,
                          dialogTheme: DialogThemeData(
                            backgroundColor:
                            isDark ? const Color(0xFF1F2937) : Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      selectedSlot = '';
                      _isLoadingSlots = true;
                      _hasUnsavedChanges = true;
                    });

                    await _fetchSlotsAndMeals();
                    await _fetchTables();
                  }
                } else {
                  _showError("Failed to load reservation date range.");
                }
              },
              child: Row(
                children:
                _isCalendarLoading
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
                    style: TextStyle(
                      fontSize: 14,
                      color:
                      isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color:
                    isDark
                        ? Colors.white70
                        : const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),

          // const SizedBox(width: 70),
          // Container(
          //   height: 40,
          //   padding: const EdgeInsets.symmetric(horizontal: 12),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     border: Border.all(color: Colors.grey.shade300),
          //     borderRadius: BorderRadius.circular(10),
          //   ),
          //   child: InkWell(
          //     onTap: () async {
          //       setState(() {
          //         _isCalendarLoading = true;
          //       });
          //
          //       final dateRange = await _reservationRepository
          //           .getReservationDateRange(widget.token);
          //
          //       setState(() {
          //         _isCalendarLoading = false;
          //       });
          //
          //       if (dateRange != null) {
          //         final DateTime? picked = await showDatePicker(
          //           context: context,
          //           initialDate:
          //           selectedDate.isBefore(dateRange.start) ||
          //               selectedDate.isAfter(dateRange.end)
          //               ? dateRange.start
          //               : selectedDate,
          //           firstDate: dateRange.start,
          //           lastDate: dateRange.end,
          //         );
          //         if (picked != null) {
          //           setState(() {
          //             selectedDate = picked;
          //             selectedSlot = '';
          //             _isLoadingSlots = true;
          //             _hasUnsavedChanges = true;
          //           });
          //
          //           await _fetchSlotsAndMeals();
          //           await _fetchTables();
          //         }
          //       } else {
          //         _showError("Failed to load reservation date range.");
          //       }
          //     },
          //     child: Row(
          //       children:
          //       _isCalendarLoading
          //           ? [
          //         const SizedBox(
          //           height: 20,
          //           width: 20,
          //           child: CircularProgressIndicator(strokeWidth: 2),
          //         ),
          //       ]
          //           : [
          //         Text(
          //           DateFormat('dd/MM/yyyy').format(selectedDate),
          //           style: const TextStyle(fontSize: 14),
          //         ),
          //         const SizedBox(width: 10),
          //         const Icon(Icons.calendar_today, size: 18),
          //       ],
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 290),
          // _isLoadingAreas
          //     ? const Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 12),
          //   child: SizedBox(
          //     height: 20,
          //     width: 20,
          //     child: CircularProgressIndicator(strokeWidth: 2),
          //   ),
          // )
          //     : Container(
          //   height: 44,
          //   width: 350,
          //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.circular(10),
          //     border: Border.all(color: Colors.grey.shade300),
          //   ),
          //   child: areas.isEmpty
          //       ? const Center(
          //     child: Text(
          //       "No areas available",
          //       style: TextStyle(fontSize: 13),
          //     ),
          //   )
          //       : Row(
          //     children: [
          //       _scrollButton(
          //         icon: Icons.keyboard_arrow_left,
          //         onTap: _scrollLeft,
          //       ),
          //
          //       // const SizedBox(width: 6),
          //
          //       // Expanded(
          //       //   child: ClipRect(
          //       //     child: SingleChildScrollView(
          //       //       controller: _areaScrollController,
          //       //       scrollDirection: Axis.horizontal,
          //       //       physics: const NeverScrollableScrollPhysics(), // Scroll only with arrows
          //       //       child: Row(
          //       //         children: areas.map((area) {
          //       //           final isSelected = selectedArea == area;
          //       //
          //       //           return Padding(
          //       //             padding: const EdgeInsets.symmetric(horizontal: 3),
          //       //             child: TextButton(
          //       //               onPressed: () {
          //       //                 setState(() {
          //       //                   selectedArea = area;
          //       //                   _hasUnsavedChanges = true;
          //       //                 });
          //       //               },
          //       //               style: TextButton.styleFrom(
          //       //                 backgroundColor: isSelected
          //       //                     ? const Color(0xFFFD6464)
          //       //                     : Colors.transparent,
          //       //                 foregroundColor: isSelected
          //       //                     ? Colors.white
          //       //                     : Colors.black87,
          //       //                 padding: const EdgeInsets.symmetric(
          //       //                   horizontal: 16,
          //       //                   vertical: 10,
          //       //                 ),
          //       //                 shape: RoundedRectangleBorder(
          //       //                   borderRadius: BorderRadius.circular(6),
          //       //                 ),
          //       //                 minimumSize: const Size(0, 32),
          //       //                 tapTargetSize:
          //       //                 MaterialTapTargetSize.shrinkWrap,
          //       //               ),
          //       //               child: Text(
          //       //                 area,
          //       //                 style: const TextStyle(
          //       //                   fontSize: 13,
          //       //                   fontWeight: FontWeight.w500,
          //       //                 ),
          //       //               ),
          //       //             ),
          //       //           );
          //       //         }).toList(),
          //       //       ),
          //       //     ),
          //       //   ),
          //       // ),
          //
          //       // const SizedBox(width: 6),
          //       //
          //       // _scrollButton(
          //       //   icon: Icons.keyboard_arrow_right,
          //       //   onTap: _scrollRight,
          //       // ),
          //     ],
          //   ),
          // ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard(bool isDark) {
    return _styledCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Booking Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Enter guest information and reservation preferences.",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.grey.shade400
                      : const Color(0xFF888888),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _buildLabeledField(
              "No. of People:",
              _peopleController,
              hint: "Enter No. of People",
              isDark: isDark,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _buildLabeledField(
              "Name:",
              _nameController,
              hint: "Enter name here",
              isDark: isDark,
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _buildLabeledField(
              "Contact Details:",
              _contactController,
              hint: "Enter your mobile number",
              isDark: isDark,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _buildLabeledField(
              "Priority/Category:",
              _priorityController,
              hint: "Specify your reservation",
              isDark: isDark,
              focusNode: _priorityFocusNode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField(
      String label,
      TextEditingController controller, {
        String? hint,
        required bool isDark,
        FocusNode? focusNode,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
        ValueChanged<String>? onChanged,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 6),

        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: (_) {
              setState(() {
                _hasUnsavedChanges = true;
              });
            },
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
            cursorColor: isDark ? Colors.white : Colors.black,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
              filled: true,
              fillColor:
              isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                  isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                  isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                  isDark ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                ),
              ),
            ),
          ),
        )],
    );
  }

  Widget _buildSlotAvailabilityCard(bool isDark) {
    return _styledCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Slot Availability",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                "Choose your preferred dining time.",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _mealTabs(),
          const SizedBox(height: 15),
          Expanded(
            child: Container(
              // decoration: BoxDecoration(
              //   color: Colors.white,
              //   borderRadius: BorderRadius.circular(8),
              //   boxShadow: [
              //     BoxShadow(
              //       color: Colors.black12,
              //       blurRadius: 4,
              //       offset: Offset(0, 2),
              //     ),
              //   ],
              // ),
              padding: const EdgeInsets.all(0),
              child:
              _isLoadingSlots
                  ? const Center(child: CircularProgressIndicator())
                  : Scrollbar(
                thumbVisibility: true,
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children:
                  mealSlots[selectedMeal] == null
                      ? []
                      : mealSlots[selectedMeal]!.map((slot) {
                    final time =
                        slot['Time Slot']?.trim() ?? '';
                    final isActive = slot['is_active'] == true;
                    final isSelected =
                        selectedSlot.trim() == time;
                    final parts = time.split(' ');
                    final formattedSlot =
                    parts.length == 2
                        ? '${parts[0]}\n${parts[1]}'
                        : time;

                    final isOriginalSlot =
                        widget.isEditMode &&
                            time == _originalSelectedSlot;

                    return GestureDetector(
                      onTap:
                      isActive
                          ? () async {
                        setState(() {
                          selectedSlot =
                          (selectedSlot == time)
                              ? ''
                              : time;
                          _isLoadingTables = true;
                          selectedTables.clear();
                        });

                        if (selectedSlot.isNotEmpty) {
                          await _fetchTables();
                        } else {
                          setState(() {
                            _isLoadingTables = false;
                          });
                        }
                      }
                          : null,
                      child: Stack(
                        children: [
                          Container(
                            decoration:
                            isOriginalSlot
                                ? BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(
                                10,
                              ),
                              gradient: SweepGradient(
                                colors: [
                                  Colors.blue,
                                  Colors.green,
                                  Colors.pink,
                                  Colors.blue,
                                ],
                                stops: [
                                  0.0,
                                  0.33,
                                  0.66,
                                  1.0,
                                ],
                              ),
                            )
                                : null,
                            padding:
                            isOriginalSlot
                                ? const EdgeInsets.all(1.5)
                                : EdgeInsets.zero,
                            child: Container(
                              alignment: Alignment.center,
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                    ? const Color(0xFF1F4D37)
                                    : const Color(0xFFE7FAEF))
                                    : isActive
                                    ? (isDark
                                    ? const Color(0xFF111827)//0xFF111827
                                    : Colors.white)
                                    : (isDark
                                    ? const Color(0xFF12171E)//0xFF374151
                                    : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.green
                                      : isDark
                                      ? const Color(0xFF4B5563)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                formattedSlot,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.green
                                      : isActive
                                      ? (isDark ? Colors.grey.shade300 : Colors.black)
                                      : (isDark ? Colors.grey.shade800 : Colors.grey),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          // if (isSelected)
                          //   const Positioned(
                          //     top: 6,
                          //     right: 6,
                          //     child: CircleAvatar(
                          //       radius: 3,
                          //       backgroundColor: Colors.green,
                          //     ),
                          //   ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            "Tip: Select a time, then choose a table.",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelectionCard(bool isDark) {
    if (_isLoadingTables) {
      return const Center(child: CircularProgressIndicator());
    }

    final int peopleCount = int.tryParse(_peopleController.text) ?? 0;

    final tablesToShow =
    _filteredTablesByArea.where((table) {
      final capacity = int.tryParse(table['capacity'].toString()) ?? 0;

      // Show only tables that can accommodate the entered people
      return peopleCount == 0 || capacity >= peopleCount;
    }).toList();

    return  Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Table Selection Area",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Choose your preferred table.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: () {
                    // Merge tables action
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEF2FF),
                    side: const BorderSide(
                      color: Color(0xFFE0E7FF),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(
                    Icons.link,
                    size: 18,
                    color: Color(0xFF4338CA),
                  ),
                  label: const Text(
                    "Merge Tables",
                    style: TextStyle(
                      color: Color(0xFF4338CA),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isLoadingAreas
                ? const SizedBox(
              height: 44,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: areas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final area = areas[index];
                  final isSelected = selectedArea == area;

                  return OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedArea = area;
                        _hasUnsavedChanges = true;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                      isSelected
                          ? const Color(0xFFFF4D20)
                          : (isDark
                          ? const Color(0xFF374151)
                          : Colors.white),
                      foregroundColor:
                      isSelected
                          ? Colors.white
                          : (isDark
                          ? Colors.white
                          : const Color(0xFF374151)),
                      side: BorderSide(
                        color:
                        isSelected
                            ? const Color(0xFFFF4D20)
                            : (isDark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFE5E7EB)),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      area,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
              tablesToShow.isEmpty
                  ? Center(
                child: Text(
                  "No Tables Available",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                    isDark ? Colors.white : const Color(0xFF0A1B4D),
                  ),
                ),
              )
                  : GridView.builder(
                itemCount: tablesToShow.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
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
                  final isMerged = table['is_merged'] == true;
                  final displayName =
                  isMerged
                      ? table['merged_tables'] ?? tableName
                      : tableName;

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
                  Color cardColor = isDark
                      ? const Color(0xFF12171E)
                      : Colors.white;
                  Color borderColor = Colors.grey.shade300;
                  Color textColor = isDark
                      ? Colors.white70
                      : Colors.black;
                  Color iconColor = Colors.green;

                  if (status == 'available') {
                    cardColor = isSelected
                        ? (isDark
                        ? const Color(0xFF1E3A2A)
                        : const Color(0xFFE7FAEF))
                        : (isDark
                        ? const Color(0xFF12171E)
                        : Colors.white);
                    borderColor = isSelected
                        ? Colors.green
                        : (isDark
                        ? const Color(0xFF4B5563) // Better visible in dark mode
                        : Colors.grey.shade300);
                  } else if (status == 'reserve') {
                    cardColor = const Color(0xFFE0E0E0);
                    textColor = Colors.grey;
                    iconColor = Colors.grey;
                  } else if (status == 'dine in' ||
                      status == 'ready to pay') {
                    cardColor = const Color(0xFFF7DDDB);
                    textColor = const Color(0xFFF44336);
                    iconColor = const Color(0xFFF44336);
                  }

                  return GestureDetector(
                    onTap: () {
                      if (status == 'reserve' &&
                          tableName != _originalSelectedTable) {
                        return;
                      }
                      final int tableCapacity =
                          int.tryParse('$capacity') ?? 0;
                      if (tableCapacity == 0) {
                        AreaMovementNotifier.showPopup(
                          context: context,
                          fromArea: table['areaName'] ?? '',
                          toArea: '',
                          tableName: tableName,
                          customMessage:
                          'Unable to reserve: Table has 0 capacity',
                        );
                        return;
                      }

                      setState(() {
                        if (isSelected) {
                          selectedTables.remove(tableName);
                        } else {
                          selectedTables.clear();
                          selectedTables.add(tableName);
                        }
                        _hasUnsavedChanges =
                        true; // <-- Mark form as modified
                      });
                    },
                    onLongPress: () {
                      final int tableCapacity =
                          int.tryParse('${table['capacity']}') ?? 0;
                      if (tableCapacity == 0) {
                        AreaMovementNotifier.showPopup(
                          context: context,
                          fromArea: table['areaName'] ?? '',
                          toArea: '',
                          tableName: table['table_name'] ?? '',
                          customMessage:
                          'Unable to Edit Merge: This is a child table. Please Edit from parent table',
                        );
                        return;
                      }

                      final enrichedTable = {
                        ...table,
                        'areaName': selectedArea,
                      };
                      _showTableActionPopup(
                        context,
                        index,
                        enrichedTable,
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration:
                          (widget.isEditMode &&
                              tableName ==
                                  _originalSelectedTable)
                              ? BoxDecoration(
                            gradient: const SweepGradient(
                              colors: [
                                Colors.blue,
                                Colors.green,
                                Colors.pink,
                                Colors.blue,
                              ],
                              stops: [0.0, 0.33, 0.66, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withAlpha(
                                  153,
                                ),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          )
                              : BoxDecoration(
                            color: cardColor,
                            border: Border.all(
                              color:
                              isSelected
                                  ? Colors.green
                                  : borderColor,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                26,
                                10,
                                0,
                                10,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            color:
                                            isSelected
                                                ? const Color(
                                              0xFF4CAF50,
                                            )
                                                : textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.group,
                                        size: 20,
                                        color: iconColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '$capacity',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                          color:
                                          isSelected
                                              ? const Color(
                                            0xFF4CAF50,
                                          )
                                              : textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Image.asset(
                                        shapeAsset,
                                        width: 25,
                                        height: 25,
                                        fit: BoxFit.contain,
                                        color: iconColor,
                                        colorBlendMode: BlendMode.srcIn,
                                      ),
                                      if (isMerged) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.link,
                                          size: 18,
                                          color:
                                          (capacity == 0)
                                              ? Colors.blue
                                              : Colors.black,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          top: 0,
                          bottom: 0, // Centers vertically
                          child: Center(
                            child: Icon(
                              isSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 18,
                              color:
                              isSelected
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        // if (isSelected)
                        //   const Positioned(
                        //     top: 10,
                        //     right: 10,
                        //     child: CircleAvatar(
                        //       radius: 4,
                        //       backgroundColor: Colors.green,
                        //     ),
                        //   ),
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

  Future<void> _showTableActionPopup(
      BuildContext context,
      int index,
      Map<String, dynamic> tableData,
      ) async {
    final bool isMerged = tableData['is_merged'] ?? false;
    final String mergedTables =
        tableData['merged_tables'] ?? tableData['tableName'] ?? '';
    final String areaName = tableData['areaName'] ?? '';
    final String status = (tableData['status'] ?? '').toLowerCase();

    if (status == "reserve") {
      AreaMovementNotifier.showPopup(
        context: context,
        fromArea: tableData['areaName'] ?? '',
        toArea: '',
        tableName: tableData['table_name'] ?? '',
        customMessage: 'You cannot merge a reserved table',
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFF9F6F6),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          contentPadding: const EdgeInsets.all(25),
          content: IntrinsicHeight(
            child: SizedBox(
              width: 450,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 28),
                      const Expanded(
                        child: Text(
                          "Merge/Modify Tables",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5A5A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children:
                      isMerged
                          ? [
                        const TextSpan(
                          text:
                          "This table is already merged with the following tables in ",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                        TextSpan(
                          text: areaName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text:
                          ". Modify this merge or unmerge to restore individual tables.\n\n",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                        TextSpan(
                          text: mergedTables,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ]
                          : [
                        const TextSpan(
                          text:
                          "Select the tables you want to merge in this ",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                        TextSpan(
                          text: areaName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const TextSpan(
                          text:
                          ". Merging will combine them into a single reservation under the same guest.",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        height: 150,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor:
                            isMerged
                                ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF4A2A2A) // dark red tint when merged
                                : const Color(0xFFFFE6E6))
                                : (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFE0E0E0) // light grey in dark mode
                                : Colors.black12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                          isMerged
                              ? () {
                            Navigator.of(ctx).pop();
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (_) => ReservationUnmergePopup(
                                index: index,
                                tableData: tableData,
                                onUnmerge: (i, updatedTable) async {
                                  setState(() {
                                    _filteredTablesByArea[i]['isMerged'] =
                                    false;
                                  });

                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Table ${updatedTable['table_name']} unmerged',
                                      ),
                                      duration: Duration(
                                        seconds: 1,
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                              : null,
                          child: Text(
                            "Unmerge Table",
                            style: TextStyle(
                              color: isMerged
                                  ? Colors.red
                                  : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade600
                                  : Colors.black26),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 30),
                      SizedBox(
                        width: 170,
                        height: 150,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A5A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (_) => ReservationMergePopup(
                                index: index,
                                tableData: tableData,
                                token: widget.token,
                                onMergeEdit: (i, updatedTable) async {
                                  setState(() {
                                    _filteredTablesByArea[i]['isMerged'] =
                                    true;
                                  });
                                  print(
                                    "Merged Table Data: ${_filteredTablesByArea[i]}",
                                  );
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Table ${updatedTable['table_name']} merged',
                                      ),
                                      duration: Duration(seconds: 1),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                                people:
                                int.tryParse(
                                  _peopleController.text.trim(),
                                ) ??
                                    1,
                                name: _nameController.text.trim(),
                                phone: _contactController.text.trim(),
                                date: selectedDate,
                                time: selectedSlot,
                                slotType: selectedMeal,
                                zoneName: selectedArea,
                                restaurantName: widget.restaurantName,
                                restaurantId:
                                int.tryParse(widget.restaurantId) ?? 1,
                                priority: _priorityController.text.trim(),
                              ),
                            );
                          },
                          child: const Text(
                            "Merge/Edit\nTable",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // OutlinedButton(
          //   onPressed: () async {
          //     if (_hasUnsavedChanges) {
          //       final result = await showDialog<bool>(
          //         context: context,
          //         barrierDismissible: false,
          //         builder:
          //             (_) => ConfirmationPopup(
          //           title: "Discard Reservation?",
          //           message:
          //           "You have unsaved reservation details.\nDo you want to leave this page?",
          //           imagePath: "assets/warning_icon.png",
          //           isLoading: false,
          //           cancelButtonText: "Stay",
          //           confirmButtonText: "Leave",
          //           onCancel: () => Navigator.pop(context, false),
          //           onConfirm: () => Navigator.pop(context, true),
          //         ),
          //       );
          //
          //       if (result == true) {
          //         Navigator.pop(context);
          //       }
          //     } else {
          //       Navigator.pop(context);
          //     }
          //   },
          //   style: OutlinedButton.styleFrom(
          //     backgroundColor: isDark ? const Color(0xFF374151) : Colors.white,
          //     side: const BorderSide(color: Color(0xFFFF4D20), width: 1),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          //   ),
          //   child: const Text(
          //     "Cancel",
          //     style: TextStyle(
          //       color: Color(0xFFFF4D20),
          //       fontSize: 16,
          //       fontWeight: FontWeight.w500,
          //     ),
          //   ),
          // ),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: () async {
                if (_hasUnsavedChanges) {
                  final result = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (_) => ConfirmationPopup(
                      title: "Discard Reservation?",
                      message:
                      "You have unsaved reservation details.\n"
                          "Do you want to leave this page?",
                      imagePath: "assets/warning_icon.png",
                      isLoading: false,
                      cancelButtonText: "Stay",
                      confirmButtonText: "Leave",
                      onCancel: () => Navigator.pop(context, false),
                      onConfirm: () => Navigator.pop(context, true),
                    ),
                  );

                  if (result == true) {
                    Navigator.pop(context);
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(110, 40),
                maximumSize: const Size(double.infinity, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                backgroundColor:
                isDark ? const Color(0xFF374151) : Colors.white,
                side: const BorderSide(
                  color: Color(0xFFFF4D20),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Color(0xFFFF4D20),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ElevatedButton(
          //   onPressed: _isLoading ? null : _validateAndSubmit,
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: const Color(0xFFFF4D20),
          //     foregroundColor: Colors.white,
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          //   ),
          //   child: SizedBox(
          //     height: 20,
          //     child: Center(
          //       child:
          //       _isLoading
          //           ? const SizedBox(
          //         height: 18,
          //         width: 18,
          //         child: CircularProgressIndicator(
          //           color: Colors.white,
          //           strokeWidth: 2.2,
          //         ),
          //       )
          //           : Text(
          //         widget.isEditMode
          //             ? "Update Reservation"
          //             : "Confirm Reservation",
          //         style: const TextStyle(
          //           fontSize: 14,
          //           color: Colors.white,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _validateAndSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 40),
                maximumSize: const Size(double.infinity, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                backgroundColor: const Color(0xFFFF4D20),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                widget.isEditMode
                    ? "Update Reservation"
                    : "Confirm Reservation",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: availableMeals.map((meal) {
        final isSelected = selectedMeal == meal;

        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                  ? const Color(0xFF371111)
                  : Color(0xFFFAE8E8))
                  : (isDark
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFF5F7FF)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (isDark
                    ? const Color(0xFFEF4444)
                    : Colors.red)
                    : (isDark
                    ? const Color(0xFF374151)
                    : Colors.transparent),
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black45
                      : const Color(0x3F000000),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ]
                  : [],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final slots = mealSlots[meal] ?? [];
                final hasActiveSlot =
                slots.any((slot) => slot['is_active'] == true);

                if (!hasActiveSlot) {
                  AreaMovementNotifier.showPopup(
                    context: context,
                    fromArea: '',
                    toArea: '',
                    tableName: meal,
                    customMessage:
                    'There are no active slots available for ${meal[0].toUpperCase()}${meal.substring(1)}.',
                  );
                  return;
                }

                setState(() {
                  selectedMeal = meal;
                  selectedTables.clear();
                  _isLoadingTables = false;

                  final firstActiveSlot = slots.firstWhere(
                        (slot) => slot['is_active'] == true,
                    orElse: () => slots.isNotEmpty ? slots.first : {},
                  );

                  selectedSlot =
                      firstActiveSlot['Time Slot']?.trim() ?? '';

                  if (selectedSlot.isNotEmpty) {
                    _fetchTables();
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      mealIcons[meal.toLowerCase()] ?? Icons.fastfood,
                      size: 14,
                      color: isSelected
                          ? Colors.red
                          : (isDark
                          ? Colors.white70
                          : Colors.grey[600]),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      meal[0].toUpperCase() + meal.substring(1),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.red
                            : (isDark
                            ? Colors.white
                            : Colors.grey[600]),
                        fontWeight: FontWeight.w600,
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
  Widget _styledCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
