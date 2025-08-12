import 'package:flutter/material.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/NavigationHelper.dart';
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
  final List<Map<String, String>> _tables = List.generate(8, (index) {
    return {'tableNo': '${index + 1}', 'orderId': '#1234', 'time': '9:30 PM'};
  });
  List<Map<String, dynamic>> _zones = [];
  final zoneRepo = ZoneRepository();

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

  List<Map<String, String>> get filteredTables {
    if (searchQuery.isEmpty) return _tables;
    return _tables.where((table) {
      return table['tableNo']!.toLowerCase().contains(searchQuery) ||
          table['orderId']!.toLowerCase().contains(searchQuery) ||
          table['time']!.toLowerCase().contains(searchQuery);
    }).toList();
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
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFE5EDFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BottomNavBar(
            selectedIndex: 2,
            onItemTapped: (index) {
              NavigationHelper.handleNavigation(
                context,
                2,
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
    bool isSelected = title == selectedOrderType;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOrderType = title;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.red : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          // Underline
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: 3,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: Colors.red,
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
    final List<Map<String, dynamic>> tables = [
      {
        "tableNo": "1",
        "orderId": "#3287",
        "time": "9:37 PM",
        "kots": ["#110", "#111", "#112"],
      },
      {
        "tableNo": "5",
        "orderId": "#3287",
        "time": "9:37 PM",
        "kots": ["#110"],
      },
      {
        "tableNo": "8",
        "orderId": "#3290",
        "time": "9:40 PM",
        "kots": ["#200", "#201"],
      },
      {
        "tableNo": "3",
        "orderId": "#3295",
        "time": "9:45 PM",
        "kots": ["#300"],
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final kotCount = table["kots"].length;
        final bool isSelected = index.isEven;

        return Container(
          padding: const EdgeInsets.all(12),
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
                      color: isSelected ? Colors.white : Colors.black54,
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
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (kotCount == 1)
                    _buildKotCircle(
                      kotText: "KOT",
                      color: isSelected ? const Color(0xFF0C6FDB) : Colors.blue,
                      textColor: Colors.white,
                    )
                  else
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 15,
                              child: _buildKotCircle(
                                kotText: "",
                                color: isSelected ? Colors.white.withOpacity(0.5) : Colors.grey.shade200,
                                textColor: Colors.black,
                              ),
                            ),
                            _buildKotCircle(
                              kotText: "KOT",
                              color: isSelected ? Colors.white : Colors.grey.shade300,
                              textColor: Colors.black,
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "+${kotCount - 1}",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKotCircle({
    required String kotText,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: color == Colors.white || color == Colors.white.withOpacity(0.5)
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ]
            : null,
      ),
      alignment: Alignment.center,
      child: kotText.isNotEmpty
          ? Text(
        kotText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 8,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      )
          : null,
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Table No: ---', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Order ID: ----'),
          Text('KOT: -----'),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {},
                child: Text('Print KOT'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {},
                child: Text('Void Items'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {},
                child: Text('Transfer KOT'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Text(
                'Order details will appear here',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
