import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/ReservationRepository.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/GlobalReservationMonitor.dart';
import '../../utils/SessionManager.dart';
import '../widgets/DeleteReservationDialog.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/area_movement_notifier.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import 'create_reservation_screen.dart';
import 'home_screen.dart';

class ReservationListScreen extends StatefulWidget {
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;

  const ReservationListScreen({
    Key? key,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  _ReservationListScreenState createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  int currentPage = 1;
  final int entriesPerPage = 9;

  String searchQuery = '';
  String? selectedArea = 'All';
  DateTime? selectedDate;
  final ReservationRepository _reservationRepository = ReservationRepository();
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();


  UserPermissions? _userPermissions;
  final ZoneRepository _zoneRepository = ZoneRepository();

  List<String> _areaNames = ['All'];

  late VoidCallback _reservationListener;

  @override
  void initState() {
    super.initState();

    selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate!);
    _loadPermissions();
    _loadZones();
    _fetchReservations();
    _reservationListener = () {
      if (!mounted) return;
      setState(() {
        _reservations = GlobalReservationMonitor().reservationsNotifier.value;
        _isLoading = false;
      });
    };
    GlobalReservationMonitor().reservationsNotifier.addListener(_reservationListener);
  }

  @override
  void dispose() {
    GlobalReservationMonitor().reservationsNotifier.removeListener(_reservationListener);
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isZonesLoading = true;
  Future<void> _loadZones() async {
    setState(() {
      _isZonesLoading = true;
    });
    try {
      final zones = await _zoneRepository.getAllZones(widget.token);
      final names = zones.map((zone) => zone['zone_name'] as String).toList();

      setState(() {
        _areaNames = ['All', ...names];
      });
    } catch (e) {
      setState(() {
        _areaNames = ['All'];
      });
    } finally {
      setState(() {
        _isZonesLoading = false;
      });
    }
  }
  Future<void> _fetchReservations() async {
    final data = await _reservationRepository.fetchAllReservations(widget.token);
    print("Fetched Reservations at ${DateTime.now()}:");
    for (var reservation in data) {
      print(reservation);
    }

    setState(() {
      _reservations = data;
      _isLoading = false;
    });
  }
  bool _isBeforeCutoff(String reservationDate, String cutoffTime) {
    try {
      final fullCutoffDateTimeString = '$reservationDate $cutoffTime';
      final cutoff = DateFormat('yyyy-MM-dd hh:mm a').parse(fullCutoffDateTimeString);
      return DateTime.now().isBefore(cutoff);
    } catch (e) {
      print("Date parsing error: $e");
      return false;
    }
  }


  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
      });
    }
  }

  bool get isResetEnabled {
    return searchQuery.isNotEmpty || selectedArea != 'All' || selectedDate != null;
  }

  List<Widget> _buildPaginationButtons(int totalPages) {
    const maxVisiblePages = 5;
    List<Widget> buttons = [];

    int startPage = 1;
    int endPage = totalPages;

    if (totalPages > maxVisiblePages) {
      if (currentPage <= 3) {
        startPage = 1;
        endPage = 5;
      } else if (currentPage >= totalPages - 2) {
        startPage = totalPages - 4;
        endPage = totalPages;
      } else {
        startPage = currentPage - 2;
        endPage = currentPage + 2;
      }
    }

    if (startPage > 1) {
      buttons.add(_buildPageButton(1));
      if (startPage > 2) {
        buttons.add(_buildEllipsis());
      }
    }

    for (int i = startPage; i <= endPage; i++) {
      buttons.add(_buildPageButton(i));
    }

    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        buttons.add(_buildEllipsis());
      }
      buttons.add(_buildPageButton(totalPages));
    }

    return buttons;
  }

  Widget _buildPageButton(int pageNum) {
    final isActive = pageNum == currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 40,
        height: 40,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: isActive ? Colors.red : Colors.white,
            side: BorderSide(color: isActive ? Colors.red : Colors.grey),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: EdgeInsets.zero,
          ),
          onPressed: () => setState(() => currentPage = pageNum),
          child: Text(
            '$pageNum',
            style: TextStyle(color: isActive ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return const SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Text("-", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReservations = _reservations.where((data) {
      final query = searchQuery.toLowerCase();
      final name = data['customer_name']?.toLowerCase() ?? '';
      final phone = data['customer_phone'] ?? '';
      final table = data['table_no']?.toLowerCase() ?? '';
      final zone = data['zone_name'] ?? '';
      final date = data['reservation_date'] ?? '';

      final nameMatch = name.contains(query) || phone.contains(query) || table.contains(query);
      final areaMatch = selectedArea == 'All' || zone == selectedArea;
      final dateMatch = selectedDate == null ||
          date == DateFormat('yyyy-MM-dd').format(selectedDate!);

      return nameMatch && areaMatch && dateMatch;
    }).toList();

    final totalPages = (filteredReservations.length / entriesPerPage).ceil();
    final startIndex = (currentPage - 1) * entriesPerPage;
    final currentData = filteredReservations.skip(startIndex).take(entriesPerPage).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        userPermissions: _userPermissions,
        isHomeScreen: false,
        onPermissionsReceived: (permissions) {
          setState(() {
            _userPermissions = permissions;
          });
        },
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 25,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filters Row
                      Row(
                        children: [
                          /// 🔙 BACK BUTTON
                          // InkWell(
                          //   onTap: () {
                          //     Navigator.pushAndRemoveUntil(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => HomeScreen(
                          //           token: widget.token,
                          //           pin: widget.pin,
                          //           restaurantId: widget.restaurantId,
                          //           restaurantName: widget.restaurantName,
                          //         ),
                          //       ),
                          //           (route) => false,
                          //     );
                          //   },
                          //   child: Container(
                          //     width: 40,
                          //     height: 40,
                          //     decoration: BoxDecoration(
                          //       color: Colors.white,
                          //       borderRadius: BorderRadius.circular(8),
                          //       boxShadow: const [
                          //         BoxShadow(
                          //           color: Colors.black12,
                          //           blurRadius: 4,
                          //         ),
                          //       ],
                          //     ),
                          //     child: const Icon(
                          //       Icons.arrow_back,
                          //       color: Color(0xFF0A1B4D),
                          //     ),
                          //   ),
                          // ),

                          const SizedBox(width: 8),

                          const Expanded(
                            child: Text(
                              "Reservation List",
                              style: TextStyle(
                                color: Color(0xFF3D3D3D),
                                fontSize: 24,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          Container(
                            width: 220,
                            height: 40,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x4204347F),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              cursorColor: Colors.black,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value.toLowerCase();
                                  currentPage = 1; // Reset to first page while searching
                                });
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 11,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 20,
                                  color: Color(0xFF7A7A7A),
                                ),
                                hintText: "Search by name, phone or table",
                                hintStyle: TextStyle(
                                  color: Color(0xFFC3C2C2),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 200,
                            height: 40,
                            child: Container(
                              decoration: ShapeDecoration(
                                color: const Color(0xFFF0F0F0),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1,
                                    color: Color(0xFFA5A5A5),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x19000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _dateController,
                                readOnly: true,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(
                                  color: Color(0xFF7E7E7E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );

                                  if (picked != null) {
                                    setState(() {
                                      selectedDate = picked;
                                      _dateController.text =
                                      "${picked.day.toString().padLeft(2, '0')}/"
                                          "${picked.month.toString().padLeft(2, '0')}/"
                                          "${picked.year}";
                                    });
                                  }
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.calendar_month,
                                    size: 20,
                                    color: Color(0xFF6D6D6D),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 40,
                            width: 120,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _isZonesLoading
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text("Loading areas...", style: TextStyle(fontSize: 14)),
                              ],
                            )
                                : DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedArea,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Colors.black, fontSize: 14),
                                onChanged: (value) => setState(() => selectedArea = value),
                                items: _areaNames.map((area) => DropdownMenuItem(
                                  value: area,
                                  child: Text(area),
                                )).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Reset button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isResetEnabled
                                  ? const Color(0xFFFDF8F8)
                                  : Colors.grey.shade300,
                              foregroundColor: isResetEnabled ? Colors.red : Colors.grey,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isResetEnabled ? Colors.red : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            onPressed: isResetEnabled
                                ? () {
                              setState(() {
                                searchQuery = '';
                                selectedArea = 'All';
                                selectedDate = null;
                                _searchController.clear();
                                _dateController.clear();
                                currentPage = 1;
                              });
                            }
                                : null,
                            icon: Icon(
                              Icons.refresh,
                              size: 16,
                              color: isResetEnabled ? Colors.red : Colors.grey,
                            ),
                            label: Text(
                              "Reset",
                              style: TextStyle(
                                color: isResetEnabled ? Colors.red : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: _userPermissions?.canCreateReservation ?? false
                                  ? const LinearGradient(
                                begin: Alignment(0.51, 1.00),
                                end: Alignment(0.04, -0.20),
                                colors: [
                                  Color(0xFFFF3849),
                                  Color(0xFFFF5362),
                                ],
                              )
                                  : LinearGradient(
                                colors: [
                                  Colors.grey.shade400,
                                  Colors.grey.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                if (_userPermissions?.canCreateReservation ?? false) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateReservationScreen(
                                        pin: widget.pin,
                                        token: widget.token,
                                        restaurantId: widget.restaurantId,
                                        restaurantName: widget.restaurantName,
                                      ),
                                    ),
                                  );
                                } else {
                                  AreaMovementNotifier.showPopup(
                                    context: context,
                                    fromArea: '',
                                    toArea: '',
                                    tableName: 'Reservation',
                                    customMessage: "No permission to create reservation",
                                  );
                                }
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Create Reservation",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Table Container
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2A3558),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  _TableHeaderCell("Reservation ID"),
                                  SizedBox(width: 15),
                                  _TableHeaderCell("Date"),
                                  SizedBox(width: 10),
                                  _TableHeaderCell("Time"),
                                  _TableHeaderCell("Customer Name"),
                                  SizedBox(width: 35),
                                  _TableHeaderCell("Customer Phone"),
                                  SizedBox(width: 18),
                                  _TableHeaderCell("No. of People"),
                                  SizedBox(width: 15),
                                  _TableHeaderCell("Table No"),
                                  _TableHeaderCell("Area"),
                                  _TableHeaderCell("Status"),
                                  SizedBox(width: 26),
                                  _TableHeaderCell("Action"),
                                ],
                              ),

                            ),
                            SizedBox(
                              height: 330,
                              child: filteredReservations.isEmpty
                                  ? Center(
                                child: Text(
                                  "There are no reservations",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              )
                                  : ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: currentData.length,
                                itemBuilder: (context, index) {
                                  final data = currentData[index];
                                  final canEdit = _isBeforeCutoff(data['reservation_date'], data['cutoff_time']);
                                  final status = data['reservation_status']?.toLowerCase() ?? '';
                                  final isRowDisabled = status.toLowerCase() == 'expired' || status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'seated';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFCFCFF), // Data row background color
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFE0E0E0),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _TableCell('${data['reservation_id']}'),
                                        _TableCell(DateFormat('dd/MM/yy').format(DateTime.parse(data['reservation_date']))),
                                        _TableCell(data['reservation_time'] ?? ''),
                                        _TableCell(data['customer_name'] ?? ''),
                                        const SizedBox(width: 20),
                                        _TableCell(data['customer_phone'] ?? ''),
                                        const SizedBox(width: 10),
                                        _TableCell('${data['people_count']}'),
                                        _TableCell(data['table_no'] ?? ''),
                                        _TableCell(data['zone_name'] ?? ''),
                                        Container(
                                          alignment: Alignment.center,
                                          child: _buildStatusBadge(data['reservation_status'] ?? ''),
                                        ),
                                        const SizedBox(width: 24),
                                        _TableCell(
                                          '',
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (!isRowDisabled && canEdit)
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => CreateReservationScreen(
                                                            pin: widget.pin,
                                                            token: widget.token,
                                                            restaurantId: widget.restaurantId,
                                                            restaurantName: widget.restaurantName,
                                                            isEditMode: true,
                                                            reservationData: {
                                                              'reservation_id': data['reservation_id'],
                                                              'people': data['people_count']?.toString(),
                                                              'name': data['customer_name'],
                                                              'phone': data['customer_phone'],
                                                              'date': data['reservation_date'],
                                                              'time': data['reservation_time'],
                                                              'table': data['table_no'],
                                                              'priority': data['priority_category'],
                                                              'area': data['zone_name'],
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                                  )
                                                else
                                                  Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
                                                const SizedBox(width: 30),
                                                if (!isRowDisabled)
                                                  InkWell(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        barrierDismissible: false,
                                                        builder: (_) => DeleteReservationDialog(
                                                          onDelete: () async {
                                                            final success = await _reservationRepository.cancelReservation(
                                                              context: context,
                                                              token: widget.token,
                                                              reservationId: data['reservation_id'],
                                                              restaurantId: int.parse(widget.restaurantId),
                                                            );

                                                            if (success) {
                                                              _fetchReservations();
                                                            } else {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(content: Text('Failed to cancel reservation.'),
                                                                  duration: Duration(seconds: 1),
                                                                  backgroundColor: Colors.red,),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      );
                                                    },
                                                    child: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                  )
                                                else
                                                  Icon(Icons.delete, size: 18, color: Colors.grey.shade400),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 4),
                            Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: const BoxDecoration(
                                // color: Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    filteredReservations.length == _reservations.length
                                        ? "Total Reservations: ${_reservations.length}"
                                        : "Showing ${filteredReservations.length} of ${_reservations.length} Reservations",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFFEFEFEF),
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: currentPage > 1
                                              ? () => setState(() => currentPage--)
                                              : null,
                                          child: _paginationTextButton("Previous"),
                                        ),

                                        GestureDetector(
                                          onTap: () => setState(() => currentPage = 1),
                                          child: _pageButton(
                                            1,
                                            selected: currentPage == 1,
                                          ),
                                        ),

                                        if (totalPages >= 2)
                                          GestureDetector(
                                            onTap: () => setState(() => currentPage = 2),
                                            child: _pageButton(
                                              2,
                                              selected: currentPage == 2,
                                            ),
                                          ),

                                        if (totalPages >= 3)
                                          GestureDetector(
                                            onTap: () => setState(() => currentPage = 3),
                                            child: _pageButton(
                                              3,
                                              selected: currentPage == 3,
                                            ),
                                          ),

                                        if (totalPages > 4)
                                          _paginationTextButton("..."),

                                        if (totalPages > 4)
                                          GestureDetector(
                                            onTap: () => setState(() => currentPage = totalPages),
                                            child: _pageButton(
                                              totalPages,
                                              selected: currentPage == totalPages,
                                            ),
                                          ),

                                        GestureDetector(
                                          onTap: currentPage < totalPages
                                              ? () => setState(() => currentPage++)
                                              : null,
                                          child: _paginationTextButton("Next"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))],
      ),
    );
  }
}
Widget _paginationTextButton(String text) {
  return Container(
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      border: Border(
        right: BorderSide(
          color: Color(0xFFEFEFEF),
        ),
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF727272),
        fontSize: 11,
      ),
    ),
  );
}

Widget _pageButton(
    int page, {
      bool selected = false,
    }) {
  return Container(
    width: 28,
    height: 32,
    decoration: BoxDecoration(
      color: selected
          ? const Color(0xFFFF4D20)
          : Colors.white,
      border: const Border(
        right: BorderSide(
          color: Color(0xFFEFEFEF),
        ),
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      '$page',
      style: TextStyle(
        color: selected
            ? Colors.white
            : const Color(0xFF727272),
        fontSize: 11,
        fontWeight:
        selected ? FontWeight.w600 : FontWeight.w400,
      ),
    ),
  );
}

Color? _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'seated':
      return Colors.green;
    case 'expired':
      return Colors.orange;
    case 'cancelled':
      return Colors.red;
    default:
      return null;
  }
}

Widget _buildStatusBadge(String status) {
  final color = _getStatusColor(status);

  if (color == null) {
    return const SizedBox(
      width: 100,
      child: Center(
        child: Text(
          '-',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  return Container(
    width: 100,
    padding: const EdgeInsets.symmetric(vertical: 3),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withAlpha(51),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      _capitalize(status),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}

String _capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1).toLowerCase();
}

class _TableHeaderCell extends StatelessWidget {
  final String label;
  final int flex;

  const _TableHeaderCell(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String content;
  final int flex;
  final Widget? child;

  const _TableCell(this.content, {this.flex = 1, this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: child ??
            Text(
              content,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
      ),
    );
  }
}