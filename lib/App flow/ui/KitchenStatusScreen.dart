import 'package:flutter/material.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/area_movement_notifier.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';

class KitchenStatusScreen extends StatefulWidget {
  final String pin;
  final String associatedManagerPin;
  final String token;
  final String restaurantId;
  final String restaurantName;

  const KitchenStatusScreen({
    Key? key,
    required this.pin,
    required this.associatedManagerPin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  _KitchenStatusScreenState createState() => _KitchenStatusScreenState();
}

class _KitchenStatusScreenState extends State<KitchenStatusScreen> {
  UserPermissions? _userPermissions;
  String selectedOrderType = "Dine-In";
  String? selectedArea;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  final List<String> _users = ['Raghav Kumar', 'Anita Sharma', 'John Doe'];
  List<Map<String, dynamic>> _zones = [];
  final zoneRepo = ZoneRepository();
  int? _selectedTableIndex;
  Map<String, dynamic>? _selectedTable;
  String? _selectedKot;
  List<Map<String, dynamic>> _kotItems = [];
  int? _expandedKotIndex;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _fetchZones();
  }

  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
      });
    }
  }

  Future<void> _fetchZones() async {
    final zones = await zoneRepo.getAllZones(widget.token);
    if (mounted) {
      setState(() {
        _zones = zones;
        if (zones.isNotEmpty) {
          selectedArea = zones.first['zone_name'];
        }
      });
    }
  }

  final List<Map<String, dynamic>> _allTables = [
    {
      "tableNo": "1",
      "orderId": "3287",
      "time": "9:37 PM",
      "zone": "second Floor",
      "orderType": "Dine-In",
      "kots": List.generate(23, (index) => "#KOT${index + 1}"),
    },
    {
      "tableNo": "5",
      "orderId": "3287",
      "time": "9:37 PM",
      "zone": "Garden",
      "orderType": "Dine-In",
      "kots": List.generate(18, (index) => "#KOT${index + 1}"),
    },
    {
      "tableNo": "8",
      "orderId": "3290",
      "time": "9:40 PM",
      "zone": "First Floor",
      "orderType": "Dine-In",
      "kots": ["#200", "#201"],
    },
    {
      "tableNo": "3",
      "orderId": "3295",
      "time": "9:45 PM",
      "zone": "Main dining",
      "orderType": "Dine-In",
      "kots": ["#300"],
    },
    {
      "tableNo": "9",
      "orderId": "3300",
      "time": "9:50 PM",
      "zone": "Garden",
      "orderType": "Dine-In",
      "kots": ["#400", "#401", "#402"],
    },
    {
      "tableNo": "10",
      "orderId": "3305",
      "time": "9:55 PM",
      "zone": "Garden",
      "orderType": "Dine-In",
      "kots": List.generate(5, (index) => "#KOT${500 + index}"),
    },
    {
      "tableNo": "11",
      "orderId": "3310",
      "time": "10:00 PM",
      "zone": "Main dining",
      "orderType": "Dine-In",
      "kots": ["#600", "#601"],
    },
    {
      "tableNo": "12",
      "orderId": "3315",
      "time": "10:05 PM",
      "zone": "First Floor",
      "orderType": "Dine-In",
      "kots": List.generate(3, (index) => "#KOT${700 + index}"),
    },
    {
      "tableNo": "13",
      "orderId": "3320",
      "time": "10:10 PM",
      "zone": "second Floor",
      "orderType": "Dine-In",
      "kots": ["#800"],
    },
    {
      "tableNo": "14",
      "orderId": "3325",
      "time": "10:15 PM",
      "zone": "Garden",
      "orderType": "Dine-In",
      "kots": ["#900", "#901", "#902", "#903"],
    },
    {
      "tableNo": "15",
      "orderId": "3330",
      "time": "10:20 PM",
      "zone": "second Floor",
      "orderType": "Dine-In",
      "kots": List.generate(7, (index) => "#KOT${1000 + index}"),
    },
    {
      "tableNo": "16",
      "orderId": "3335",
      "time": "10:25 PM",
      "zone": "Main dining",
      "orderType": "Dine-In",
      "kots": ["#1100"],
    },
    {
      "tableNo": "17",
      "orderId": "3340",
      "time": "10:30 PM",
      "zone": "First Floor",
      "orderType": "Dine-In",
      "kots": List.generate(4, (index) => "#KOT${1200 + index}"),
    },
    {
      "tableNo": "18",
      "orderId": "3345",
      "time": "10:35 PM",
      "zone": "second Floor",
      "orderType": "Dine-In",
      "kots": ["#1300", "#1301"],
    },
    {
      "tableNo": "19",
      "orderId": "3350",
      "time": "10:40 PM",
      "zone": "Garden",
      "orderType": "Dine-In",
      "kots": ["#1400"],
    },
  ];

  List<Map<String, dynamic>> get filteredTables {
    return _allTables.where((table) {
      final matchesArea = selectedArea == null || table['zone'] == selectedArea;
      final matchesSearch =
          searchQuery.isEmpty ||
              table['tableNo'].toString().toLowerCase().contains(searchQuery) ||
              table['orderId'].toString().toLowerCase().contains(searchQuery);
      final matchesOrderType = table['orderType'] == selectedOrderType;

      return matchesArea && matchesSearch && matchesOrderType;
    }).toList();
  }
  void _onKotSelected(String kot, int index) {
    setState(() {
      if (_selectedKot == kot) {
        _selectedKot = null;
        _expandedKotIndex = null;
        _kotItems.clear();
      } else {
        _selectedKot = kot;
        _expandedKotIndex = index;
        _kotItems = [
          {"itemName": "Panner Tikka", "qty": 1, "price": 190.0},
          {"itemName": "Panner Masala", "qty": 1, "price": 250.0},
          {"itemName": "Dal Makhni", "qty": 1, "price": 180.0},
          {"itemName": "Chicken 65", "qty": 3, "price": 225.0},
          {"itemName": "Cashew Paneer Curry", "qty": 1, "price": 220.0},
          {"itemName": "Chicken Dum Biryani", "qty": 5, "price": 320.0},
          {"itemName": "Veg Manchow Soup", "qty": 4, "price": 120.0},
        ];
      }
    });
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 4, right: 14),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFE5EDFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildOrderTypeButton("Dine-In"),
                                    const SizedBox(width: 25),
                                    _buildOrderTypeButton("Takeaways"),
                                    const SizedBox(width: 25),
                                    _buildOrderTypeButton("Online Orders"),
                                  ],
                                ),
                              ),
                              _buildAreaDropdown(),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Expanded(child: _buildTableList()),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: _buildOrderDetails(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onItemTapped: (index) {
          NavigationHelper.handleNavigation(
            context,
            1,
            index,
            widget.pin,
            widget.token,
            widget.restaurantId,
            widget.restaurantName,
          );
        },
      ),
    );
  }

  Widget _buildAreaDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C6FDB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedArea,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white,
            size: 18,
          ),
          dropdownColor: const Color(0xFF0C6FDB),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (newValue) {
            setState(() {
              selectedArea = newValue;
            });
          },
          items:
          _zones.map((zone) {
            return DropdownMenuItem<String>(
              value: zone['zone_name'],
              child: Text(
                zone['zone_name'],
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderTypeButton(String title) {
    // Permission checks
    bool isEnabled = true;
    if (title == "Takeaways") {
      isEnabled = _userPermissions?.canViewOrderTypes ?? false;
    } else if (title == "Online Orders") {
      isEnabled = _userPermissions?.canViewOrderTypes  ?? false;
    }

    bool isSelected = title == selectedOrderType;

    return GestureDetector(
      onTap: () {
        if (isEnabled) {
          setState(() {
            selectedOrderType = title;
          });
        } else {
          AreaMovementNotifier.showPopup(
            context: context,
            fromArea: '',
            toArea: '',
            tableName: title,
            customMessage: "No permission to view $title",
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isEnabled
                  ? (isSelected ? Colors.red : Colors.black)
                  : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: 3,
            width: isSelected && isEnabled ? 40 : 0,
            decoration: BoxDecoration(
              color: isEnabled ? Colors.red : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            'Kitchen Status',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          _buildUserDropdown(),
          const SizedBox(width: 10),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildUserDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _users.first,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.black,
            size: 18,
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          onChanged: (value) {
            // Handle user change
          },
          items:
          _users
              .map(
                (name) => DropdownMenuItem(value: name, child: Text(name)),
          )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 260,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: "Order ID or Table No",
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
    );
  }

  Widget _buildTableList() {
    final tables = filteredTables;

    if (tables.isEmpty) {
      return Center(child: Text('No orders found'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final kotCount = table["kots"].length;
        final bool isSelected = _selectedTableIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedTableIndex == index) {
                _selectedTableIndex = null;
                _selectedTable = null;
                _selectedKot = null;
                _kotItems.clear();
              } else {
                _selectedTableIndex = index;
                _selectedTable = table;
                _selectedKot = null;
                _kotItems.clear();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0C6FDB) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Table No: ${table['tableNo']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      table["time"],
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order ID: ${table['orderId']}",
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (kotCount == 1)
                      _buildKotCircleWithOverlap(
                        kotText: "KOT",
                        isSelected: isSelected,
                        kotCount: kotCount,
                      )
                    else
                      Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 14,
                                child: _buildKotCircleWithOverlap(
                                  kotText: "KOT",
                                  isSelected: isSelected,
                                  kotCount: kotCount,
                                  isSecondary: true,
                                ),
                              ),
                              _buildKotCircleWithOverlap(
                                kotText: "KOT",
                                isSelected: isSelected,
                                kotCount: kotCount,
                              ),
                            ],
                          ),
                          const SizedBox(width: 15),
                          Text(
                            "+${kotCount - 1}",
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKotCircleWithOverlap({
    required String kotText,
    required bool isSelected,
    required int kotCount,
    bool isSecondary = false,
  }) {
    final primaryColor =
    isSelected ? const Color(0xFFA6C4E4) : const Color(0xFF125BCE);
    final secondaryColor =
    isSelected ? const Color(0xFFD8E9FB) : const Color(0xFF81ACEF);

    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: isSecondary ? secondaryColor : primaryColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child:
      kotText.isNotEmpty
          ? Text(
        kotText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      )
          : null,
    );
  }

  Widget _buildOrderDetails() {
    final bool hasTable = _selectedTable != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFC2DFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  "Table No: ${hasTable ? _selectedTable!['tableNo'] : '---'}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Text(
                  "Order ID: ${hasTable ? _selectedTable!['orderId'] : '---'}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                Text(
                  "KOT: ${_selectedKot ?? '---'}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),

                // Void Items
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    minimumSize: const Size(36, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                        if (states.contains(WidgetState.disabled)) {
                          return const Color(0xFFBDE5C0);
                        }
                        return Colors.green;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.white70;
                        }
                        return Colors.white;
                      },
                    ),
                  ),
                  icon: const Icon(Icons.print, size: 15),
                  label: const Text('Print KOT', style: TextStyle(fontSize: 12)),
                  onPressed: _selectedKot != null ? () {} : null,
                ),

                const SizedBox(width: 8),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    minimumSize: const Size(36, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                        if (states.contains(WidgetState.disabled)) {
                          return const Color(0xFFCBD9F0);
                        }
                        return Colors.blue;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.white70;
                        }
                        return Colors.white;
                      },
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 15),
                  label: const Text('Void Items', style: TextStyle(fontSize: 12)),
                  onPressed: _selectedKot != null ? () {} : null,
                ),

                const SizedBox(width: 8),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    minimumSize: const Size(36, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                        if (states.contains(WidgetState.disabled)) {
                          return const Color(0xFFFCECCB);
                        }
                        return Colors.amber;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.black45;
                        }
                        return Colors.black87;
                      },
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 15),
                  label: const Text('Transfer KOT', style: TextStyle(fontSize: 12)),
                  onPressed: _selectedKot != null ? () {} : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // KOT List Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD8E4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
            hasTable
                ? SizedBox(
              height: 357,
              child: SingleChildScrollView(
                child: Column(
                  children:
                  (_selectedTable!['kots'] as List<String>)
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final kot = entry.value;
                    final bool isSelectedKot =
                        kot == _selectedKot;

                    return Column(
                      children: [
                        GestureDetector(
                          onTap:
                              () => _onKotSelected(kot, index),
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                              isSelectedKot
                                  ? const Color(0xFFEAF1FF)
                                  : const Color(0xFFF5F6FA),
                              borderRadius:
                              BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                isSelectedKot
                                    ? const Color(
                                  0xFF0C6FDB,
                                )
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                    BorderRadius.circular(
                                      4,
                                    ),
                                  ),
                                  child: Text(
                                    kot,
                                    style: const TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                    BorderRadius.circular(
                                      4,
                                    ),
                                  ),
                                  child: const Text("12:30 PM"),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFF3CD,
                                    ),
                                    borderRadius:
                                    BorderRadius.circular(
                                      4,
                                    ),
                                  ),
                                  child: const Text(
                                    "Anil Kumar",
                                    style: TextStyle(
                                      fontWeight:
                                      FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  isSelectedKot
                                      ? Icons.keyboard_arrow_up
                                      : Icons
                                      .keyboard_arrow_down,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isSelectedKot)
                          _buildKotItemsOverlay(),
                      ],
                    );
                  })
                      .toList(),
                ),
              ),
            )
                : const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Order details will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKotItemsOverlay() {
    return Container(
      width: 580,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFE0E0E0)),
            columnSpacing: 16,
            horizontalMargin: 20,
            columns: const [
              DataColumn(label: Text('S.No')),
              DataColumn(label: Text('Item Name')),
              DataColumn(label: Text('Qty')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Total Price')),
            ],
            rows:
            _kotItems.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;
              final total = item['qty'] * item['price'];
              return DataRow(
                cells: [
                  DataCell(Text(index.toString())),
                  DataCell(Text(item['itemName'])),
                  DataCell(Text(item['qty'].toString())),
                  DataCell(Text(item['price'].toStringAsFixed(2))),
                  DataCell(Text(total.toStringAsFixed(2))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
