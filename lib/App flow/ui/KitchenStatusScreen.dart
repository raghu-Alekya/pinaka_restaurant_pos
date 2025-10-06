import 'package:flutter/material.dart';
import '../../models/UserPermissions.dart';
import '../../repositories/kitchen_repository.dart';
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
  List<Map<String, dynamic>> _orders = [];
  String? selectedArea;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _zones = [];
  final zoneRepo = ZoneRepository();
  int? _selectedTableIndex;
  Map<String, dynamic>? _selectedTable;
  String? _selectedKot;
  List<Map<String, dynamic>> _kotItems = [];
  int? _expandedKotIndex;
  Map<String, dynamic>? _selectedUser;
  List<String> _orderTypes = [];
  late KitchenRepository kitchenRepo;

  @override
  void initState() {
    super.initState();
    kitchenRepo = KitchenRepository(token: widget.token);
    _loadPermissions();
    _initializeData();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _fetchZones();
    await _fetchUsers();
    await _fetchOrderTypes();
    _fetchOrders();
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
  Future<void> _fetchOrders() async {
    final orders = await kitchenRepo.fetchOrders(
      selectedOrderType: selectedOrderType,
      restaurantId: widget.restaurantId,
      selectedArea: selectedArea,
      zones: _zones,
      selectedUser: _selectedUser,
    );

    if (mounted) setState(() => _orders = orders);
    for (var order in _orders) {
      await _fetchParentKotOrders(order);
    }
  }

  Future<void> _fetchParentKotOrders(Map<String, dynamic> order) async {
    if (selectedArea == null &&
        _normalizeOrderType(selectedOrderType) != "takeaways") return;

    final parentOrderId = (order['order_id'] ?? order['id']).toString();
    final zoneId = _normalizeOrderType(selectedOrderType) != "takeaways"
        ? (order['zone_id'] ?? order['zoneId'])?.toString()
        : null;

    try {
      final kotOrders = await kitchenRepo.fetchParentKotOrders(
        restaurantId: widget.restaurantId,
        parentOrderId: parentOrderId,
        orderType: selectedOrderType,
        zoneId: zoneId,
        selectedUser: _selectedUser,
      );

      if (mounted) {
        setState(() {
          _selectedTable?['kots'] =
              kotOrders.map((kot) => kot['kot_number']?.toString() ?? '').toList();
          _selectedTable?['kotOrders'] = kotOrders;

          if (_selectedTable?['kots'] != null &&
              _selectedTable!['kots'].isNotEmpty &&
              _normalizeOrderType(selectedOrderType) != "dinein") {
            _onKotSelected(_selectedTable!['kots'].first, 0);
          }
        });
      }
    } catch (e) {
      debugPrint("Error in _fetchParentKotOrders: $e");
    }
  }

  Future<void> _fetchOrderTypes() async {
    final types = await kitchenRepo.fetchOrderTypes();
    if (mounted) {
      setState(() {
        _orderTypes = types;
        if (_orderTypes.isNotEmpty) selectedOrderType = _orderTypes.first;
      });
    }
  }

  Future<void> _fetchUsers() async {
    final users = await kitchenRepo.fetchUsers();
    if (mounted) {
      setState(() {
        _users = users;
        if (_users.isNotEmpty) _selectedUser = _users.first;
      });
    }
  }

  String _normalizeOrderType(String type) {
    return type.toLowerCase().replaceAll(" ", "");
  }

  List<Map<String, dynamic>> get filteredTables {
    final query = searchQuery.toLowerCase();

    return _orders.where((order) {
      final matchesOrderType =
          normalizeOrderType(order['order_type'] ?? '') ==
              normalizeOrderType(selectedOrderType);

      final matchesArea =
      selectedOrderType == "Takeaways"
          ? true
          : (selectedArea == null || order['zone_name'] == selectedArea);

      final tableName = (order['table_name'] ?? '').toString().toLowerCase();
      final orderId = (order['order_id'] ?? '').toString().toLowerCase();

      final matchesSearch = query.isEmpty ||
          tableName.contains(query) ||
          orderId.contains(query);

      return matchesOrderType && matchesArea && matchesSearch;
    }).toList();
  }
  void _onKotSelected(String kot, int index) {
    setState(() {
      if (_selectedKot == kot && normalizeOrderType(selectedOrderType) != "takeaways") {
        _selectedKot = null;
        _expandedKotIndex = null;
        _kotItems.clear();
      } else {
        _selectedKot = kot;
        _expandedKotIndex = index;

        final allKotOrders = _selectedTable?['kotOrders'] ?? [];
        final selectedKotOrder = allKotOrders.firstWhere(
              (k) => k['kot_number'].toString() == kot,
          orElse: () => <String, dynamic>{},
        );

        _kotItems = List<Map<String, dynamic>>.from(
          selectedKotOrder['line_items'] ?? [],
        );
      }
    });
  }

  String normalizeOrderType(String type) {
    return type.toLowerCase().replaceAll("-", "").replaceAll(" ", "");
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
                                  children:
                                  _orderTypes.map((type) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: _buildOrderTypeButton(type),
                                    );
                                  }).toList(),
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
            _userPermissions,
          );
        },
        userPermissions: _userPermissions,
      ),
    );
  }

  Widget _buildAreaDropdown() {
    if (normalizeOrderType(selectedOrderType) != "dinein") {
      return const SizedBox.shrink();
    }

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
              _selectedTableIndex = null;
              _selectedTable = null;
              _selectedKot = null;
              _kotItems.clear();
            });
            _fetchOrders();
          },
          items: _zones.map((zone) {
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
    bool isEnabled = true;
    if (normalizeOrderType(title) == "takeaways" ||
        normalizeOrderType(title) == "onlineorders") {
      isEnabled = _userPermissions?.canViewOrderTypes ?? false;
    }

    bool isSelected =
        normalizeOrderType(title) == normalizeOrderType(selectedOrderType);

    return GestureDetector(
      onTap: () {
        if (isEnabled) {
          setState(() {
            selectedOrderType = title;
            _selectedTableIndex = null;
            _selectedTable = null;
            _selectedKot = null;
            _kotItems.clear();
          });
          _fetchOrders();
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
              color:
              isEnabled
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
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedUser,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.black,
            size: 18,
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          onChanged: (value) {
            setState(() {
              _selectedUser = value;
              _selectedTableIndex = null;
              _selectedTable = null;
              _selectedKot = null;
              _kotItems.clear();
            });
            _fetchOrders();
          },
          items: _users.isNotEmpty
              ? _users.map((user) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: user,
              child: Text(user['name'] ?? user['username']),
            );
          }).toList()
              : [
            const DropdownMenuItem<Map<String, dynamic>>(
              value: null,
              child: Text("No users available"),
            )
          ],
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
      return const Center(child: Text('No orders found'));
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
        final kotCount = table["remaining_count"] ?? 0;
        final bool isSelected = _selectedTableIndex == index;

        return GestureDetector(
          onTap: () async {
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
                if (normalizeOrderType(selectedOrderType) != "dinein") {
                  _onKotSelected(
                    (table['kots'] as List<dynamic>?)?.first ?? '',
                    0,
                  );
                }
              }
            });

            if (_selectedTable != null) {
              await _fetchParentKotOrders(_selectedTable!);
            }
          },
          child: normalizeOrderType(selectedOrderType) == "dinein"
              ? _buildDineInCard(table, kotCount, isSelected)
              : _buildTakeawayCard(table, kotCount, isSelected),
        );
      },
    );
  }

  Widget _buildTakeawayCard(Map<String, dynamic> order,
      int kotCount,
      bool isSelected,) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0C6FDB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              "Order ID: ${order['order_id']}",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order["order_time"] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor:
                isSelected ? Colors.white : const Color(0xFF0C6FDB),
                child: Text(
                  "KOT",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFF0C6FDB) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDineInCard(Map<String, dynamic> order,
      int kotCount,
      bool isSelected,) {
    return Container(
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
                "Table: ${order['table_name'] ?? '-'}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              Text(
                order["order_time"] ?? '',
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
                "Order ID: ${order['order_id']}",
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              Row(
                children: [
                  _buildKotCircleWithOverlap(
                    kotText: "KOT",
                    isSelected: isSelected,
                    kotCount: kotCount,
                  ),
                  if ((order['remaining_count'] ?? 0) > 0) ...[
                    const SizedBox(width: 5),
                    Text(
                      "+${order['remaining_count']}",
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
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
    final List<String> kots =
        (_selectedTable?['kots'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFC2DFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (selectedOrderType != "Takeaways") ...[
                  Text(
                    "Table No: ${hasTable
                        ? _selectedTable!['table_name']
                        : '---'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(width: 10),
                Text(
                  "Order ID: ${hasTable ? _selectedTable!['order_id'] : '---'}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                Text(
                  "${_selectedKot ?? '---'}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    minimumSize: const Size(36, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) =>
                      states.contains(WidgetState.disabled)
                          ? const Color(0xFFBDE5C0)
                          : Colors.green,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) =>
                      states.contains(WidgetState.disabled)
                          ? Colors.white70
                          : Colors.white,
                    ),
                  ),
                  icon: const Icon(Icons.print, size: 15),
                  label: const Text(
                    'Print KOT',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: _selectedKot != null ? () {} : null,
                ),
                if (normalizeOrderType(selectedOrderType) == "dinein") ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      minimumSize: const Size(36, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (states) =>
                        states.contains(WidgetState.disabled)
                            ? const Color(0xFFCBD9F0)
                            : Colors.blue,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                            (states) =>
                        states.contains(WidgetState.disabled)
                            ? Colors.white70
                            : Colors.white,
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 15),
                    label: const Text(
                      'Void Items',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: _selectedKot != null ? () {} : null,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      minimumSize: const Size(36, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                            (states) =>
                        states.contains(WidgetState.disabled)
                            ? const Color(0xFFFCECCB)
                            : Colors.amber,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                            (states) =>
                        states.contains(WidgetState.disabled)
                            ? Colors.black45
                            : Colors.black87,
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 15),
                    label: const Text(
                      'Transfer KOT',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: _selectedKot != null ? () {} : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD8E4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
              hasTable && kots.isNotEmpty
                  ? SingleChildScrollView(
                child: Column(
                  children:
                  kots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final kot = entry.value;
                    final kotOrders = (_selectedTable?['kotOrders'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
                    final kotOrder = kotOrders.firstWhere(
                          (k) => k['kot_number'] == kot,
                      orElse: () => {},
                    );
                    final bool isSelectedKot = kot == _selectedKot;
                    final kotTime = kotOrder['time'] ?? '';
                    final kotOrderBy = kotOrder['order_by'] ?? '';
                    String displayTime = '';
                    if (kotTime.isNotEmpty) {
                      final parts = kotTime.split(' ');
                      if (parts.length >= 3) {
                        displayTime = "${parts[1]} ${parts[2]}";
                      }
                    }
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () => _onKotSelected(kot, index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelectedKot ? const Color(0xFFEAF1FF) : const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelectedKot ? const Color(0xFF0C6FDB) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Kot number
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    kot,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (displayTime.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(displayTime),
                                  ),

                                const SizedBox(width: 10),
                                if (kotOrderBy.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3CD),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      kotOrderBy,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),

                                const Spacer(),

                                if (selectedOrderType != "Takeaways")
                                  Icon(
                                    isSelectedKot ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (isSelectedKot) _buildKotItemsOverlay(),
                      ],
                    );
                  }).toList(),
                ),
              )
                  : Center(
                child: Text(
                  'Order details will appear here',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
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
      width: 630,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 290, // cap at 290
          ),
          child: SingleChildScrollView(
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
              rows: _kotItems
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                final qty = (item['quantity'] ?? 0).toDouble();
                final price = (item['price'] ?? 0).toDouble();
                final total = qty * price;

                return DataRow(
                  cells: [
                    DataCell(Text(index.toString())),
                    DataCell(Text(item['item_name'] ?? '')),
                    DataCell(Text(qty.toStringAsFixed(0))),
                    DataCell(Text(price.toStringAsFixed(2))),
                    DataCell(Text(total.toStringAsFixed(2))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
