import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import 'create_reservation_screen.dart';

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
  final int entriesPerPage = 8;

  String searchQuery = '';
  String? selectedArea = 'All';
  DateTime? selectedDate;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> reservations = List.generate(70, (index) {
    final List<String> sampleDates = [
      '04/06/23',
      '05/06/23',
      '06/06/23',
      '07/06/23',
      '08/06/23',
      '09/06/23'
    ];

    return {
      'orderId': '#2145$index',
      'date': sampleDates[index % sampleDates.length],
      'time': '06:00PM',
      'name': 'Guest $index',
      'phone': '+91123456789$index',
      'people': '${(index % 6) + 1}',
      'table': 'T${index + 1}',
      'area': ['Main dining', 'terrace', 'Outdoor', 'Garden'][index % 4],
    };
  });

  UserPermissions? _userPermissions;
  final ZoneRepository _zoneRepository = ZoneRepository();

  List<String> _areaNames = ['All'];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final zones = await _zoneRepository.getAllZones(widget.token);
      final names = zones.map((zone) => zone['zone_name'] as String).toList();

      setState(() {
        _areaNames = ['All', ...names];
      });
    } catch (e) {
      // Handle error or keep default 'All'
      setState(() {
        _areaNames = ['All'];
      });
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
    final filteredReservations = reservations.where((data) {
      final query = searchQuery.toLowerCase();
      final nameMatch = data['name']!.toLowerCase().contains(query) ||
          data['phone']!.contains(query) ||
          data['table']!.toLowerCase().contains(query);
      final areaMatch = selectedArea == 'All' || data['area'] == selectedArea;
      final dateMatch = selectedDate == null || data['date'] == DateFormat('dd/MM/yy').format(selectedDate!);
      return nameMatch && areaMatch && dateMatch;
    }).toList();

    final totalPages = (filteredReservations.length / entriesPerPage).ceil();
    final startIndex = (currentPage - 1) * entriesPerPage;
    final currentData = filteredReservations.skip(startIndex).take(entriesPerPage).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F3),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        userPermissions: _userPermissions,
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(35, 15, 35, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters Row
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Reservation List",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: "Name, Phone or Table No",
                          prefixIcon: Icon(Icons.search, size: 18),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _dateController,
                        readOnly: true,
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
                              _dateController.text = DateFormat('dd/MM/yy').format(picked);
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Select Date",
                          prefixIcon: Icon(Icons.calendar_today, size: 18),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
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
                        backgroundColor: isResetEnabled ? Colors.red : Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      icon: Icon(Icons.refresh, size: 16, color: Colors.white),
                      label: Text("Reset", style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),

                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1877F2),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateReservationScreen(
                              pin: widget.pin,
                              token: widget.token,
                              restaurantId: widget.restaurantId,
                              restaurantName: widget.restaurantName,
                              userPermissions: _userPermissions,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.add, size: 16, color: Colors.white),
                      label: Text("Create Reservation", style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Table Container
                Container(
                  height: 470,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(35, 20, 35, 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE7F5FD),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: const [
                            _TableHeaderCell("Order ID"),
                            _TableHeaderCell("Date"),
                            _TableHeaderCell("Time"),
                            _TableHeaderCell("Customer Name"),
                            _TableHeaderCell("Customer Phone", flex: 2),
                            _TableHeaderCell("No. of People"),
                            _TableHeaderCell("Table No"),
                            _TableHeaderCell("Area"),
                            _TableHeaderCell("Action"),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: 330,
                        child: ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: currentData.length,
                          itemBuilder: (context, index) {
                            final data = currentData[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Color(0xFFFAFDFF),
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: Row(
                                children: [
                                  _TableCell(data['orderId']!),
                                  _TableCell(data['date']!),
                                  _TableCell(data['time']!),
                                  _TableCell(data['name']!),
                                  _TableCell(data['phone']!, flex: 2),
                                  _TableCell(data['people']!),
                                  _TableCell(data['table']!),
                                  _TableCell(data['area']!),
                                  _TableCell(
                                    '',
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.edit, size: 18, color: Colors.blue),
                                          SizedBox(width: 20),
                                          Icon(Icons.delete, size: 18, color: Colors.red),
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

                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 40,
                            child: OutlinedButton(
                              onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text("Previous", style: TextStyle(color: Colors.black)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ..._buildPaginationButtons(totalPages),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 80,
                            height: 40,
                            child: OutlinedButton(
                              onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text("Next", style: TextStyle(color: Colors.black)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
    );
  }
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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
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
