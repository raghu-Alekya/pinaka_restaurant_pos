import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/transer_kot.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/void_items.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Logic/kot_bloc.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Logic/transfer_kot_bloc.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Logic/void_item_bloc.dart';
import 'package:pinaka_restaurant_pos/repositories/kot_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/table_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/void_item_repository.dart';
import '../../models/UserPermissions.dart';
import '../../models/order/void_kot_items.dart';
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
  bool isResetEnabled = false;
  static const String _apiBaseUrl = "https://merchantrestaurant.alektasolutions.com";


  @override
  void initState() {
    super.initState();
    kitchenRepo = KitchenRepository(token: widget.token);
    _loadPermissions();
    _initializeData();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
        isResetEnabled = searchQuery.isNotEmpty;

      });
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadPermissions();
    await _fetchZones();
    await _fetchOrderTypes();
    _fetchOrders();
  }

  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
        _selectedUser = {
          "id": savedPermissions.userId,
          "name": savedPermissions.displayName,
          "role": savedPermissions.role,
        };
        _selectedTableIndex = null;
        _selectedTable = null;
        _selectedKot = null;
        _kotItems.clear();
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

    if (mounted) {
      setState(() {
        _orders = orders;
        _selectedTable = null;
        _selectedKot = null;
        _kotItems.clear();
      });
    }

    for (var order in _orders) {
      await _fetchParentKotOrders(order);
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
          order['kots'] =
              kotOrders.map((kot) => kot['kot_number']?.toString() ?? '').toList();
          order['kotOrders'] = kotOrders;
          if (_selectedTable != null &&
              _selectedTable!['order_id'] == order['order_id'] &&
              order['kots'].isNotEmpty &&
              _normalizeOrderType(selectedOrderType) != "dinein") {
            _onKotSelected(order['kots'].first, 0);
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
        if (_orderTypes.isNotEmpty) {
          selectedOrderType = _orderTypes.first;
          _selectedTableIndex = null;
          _selectedTable = null;
          _selectedKot = null;
          _kotItems.clear();
        }
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
  void _onResetPressed() {
    setState(() {
      // 🔍 Search reset
      _searchController.clear();
      searchQuery = '';

      // // 🔄 Order type reset
      // selectedOrderType =
      // // _orderTypes.isNotEmpty ? _orderTypes.first : null;

      // 📍 Area / Zone reset
      selectedArea =
      _zones.isNotEmpty ? _zones.first['zone_name'] : null;

      // 🪑 Table / KOT reset
      _selectedTableIndex = null;
      _selectedTable = null;
      _selectedKot = null;

      // 📦 Clear KOT items
      _kotItems.clear();

      // 🔒 Disable reset button again
      isResetEnabled = false;
    });

    // 🔁 Reload orders with default filters
    _fetchOrders();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  int _pickInt(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return 0;
    for (final key in keys) {
      final value = _asInt(source[key]);
      if (value != 0) return value;
    }
    return 0;
  }

  Map<String, dynamic>? _selectedKotOrder() {
    if (_selectedTable == null || _selectedKot == null) return null;
    final allKotOrders =
        (_selectedTable!['kotOrders'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];
    for (final kotOrder in allKotOrders) {
      if (kotOrder['kot_number']?.toString() == _selectedKot) {
        return kotOrder;
      }
    }
    return null;
  }

  Future<void> _openVoidItemsDialog() async {
    final kotOrder = _selectedKotOrder();
    if (kotOrder == null) return;

    final kotId = _pickInt(kotOrder, ['kot_id', 'id']);
    final restaurantId = _asInt(widget.restaurantId);
    final zoneId = _pickInt(_selectedTable, ['zone_id', 'zoneId']) != 0
        ? _pickInt(_selectedTable, ['zone_id', 'zoneId'])
        : _pickInt(kotOrder, ['zone_id', 'zoneId']);
    final parentOrderId = _pickInt(
      _selectedTable,
      ['order_id', 'id', 'parent_order_id', 'parentOrderId'],
    );

    if (kotId == 0 || restaurantId == 0 || zoneId == 0 || parentOrderId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open Void Items for selected KOT")),
      );
      return;
    }

    try {
      final response = await VoidItemRepository(baseUrl: _apiBaseUrl).getKotLineItems(
        kotId: kotId,
        restaurantId: restaurantId,
        zoneId: zoneId,
        token: widget.token,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<UpdatekotBloc>(
                create: (_) => UpdatekotBloc(
                  repository: UpdatekotRepository(baseUrl: _apiBaseUrl),
                ),
              ),
              BlocProvider<KotBloc>(
                create: (_) => KotBloc(
                  KotRepository(baseUrl: _apiBaseUrl),
                ),
              ),
              BlocProvider<KotLineItemsBloc>(
                create: (_) => KotLineItemsBloc(
                  repository: VoidItemRepository(baseUrl: _apiBaseUrl),
                ),
              ),
            ],
            child: VoidItemsDialog(
              items: response.items,
              tableNo: (_selectedTable?['table_name'] ?? '').toString(),
              kotNo: response.kotNumber,
              kotId: response.kotId,
              restaurantId: response.restaurantId,
              zoneId: response.zoneId,
              token: widget.token,
              parentOrderId: parentOrderId,
              item: kotOrder,
              onRemark: (_) {},
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load KOT items: $e")),
      );
    }
  }

  Future<void> _openTransferKotDialog() async {
    final kotOrder = _selectedKotOrder();
    if (kotOrder == null) return;

    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) return;

    final kotId = _pickInt(kotOrder, ['kot_id', 'id']);
    final orderId = _pickInt(
      _selectedTable,
      ['order_id', 'id', 'parent_order_id', 'parentOrderId'],
    ) !=
            0
        ? _pickInt(
            _selectedTable,
            ['order_id', 'id', 'parent_order_id', 'parentOrderId'],
          )
        : _pickInt(kotOrder, ['parent_order_id', 'parentOrderId', 'order_id']);
    final fromTableId = _pickInt(_selectedTable, ['table_id', 'tableId']);
    final restaurantId = _asInt(widget.restaurantId);
    final tableName = ((_selectedTable?['table_name'] ??
                _selectedTable?['tableName'] ??
                _selectedTable?['table_no']) ??
            '')
        .toString();
    if (kotId == 0 || orderId == 0 || restaurantId == 0 || tableName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to transfer selected KOT")),
      );
      return;
    }

    try {
      final rawItems = (kotOrder['line_items'] as List<dynamic>?) ?? const [];
      final transferItems = rawItems.map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        final modifiers = (data['modifiers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
        return TransferKotItem(
          name: (data['product_name'] ?? data['item_name'] ?? '').toString(),
          note: modifiers.isNotEmpty ? modifiers.join(", ") : null,
          qty: _asInt(data['quantity']) == 0 ? 1 : _asInt(data['quantity']),
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      final zoneResponse = await ZoneRepository().getAllZones(token);
      final tableResponse = await TableRepository().getAllTables(token);

      final Map<String, String> zoneNames = {};
      for (final zone in zoneResponse) {
        final id = zone['zone_id']?.toString();
        final name = zone['zone_name']?.toString();
        if (id != null && name != null) zoneNames[id] = name;
      }

      final Map<String, List<String>> zoneTables = {};
      final Map<String, int> tableIds = {};
      final Map<String, int> zoneIds = {};
      final Map<String, String> tableStatus = {};
      for (final row in tableResponse) {
        final table = Map<String, dynamic>.from(row);
        final zoneId = table['zone_id']?.toString();
        final tableNameVal = table['table_name']?.toString();
        final tableIdVal = _asInt(table['table_id']);
        final statusVal = table['status']?.toString();
        if (zoneId != null && tableNameVal != null) {
          zoneTables.putIfAbsent(zoneId, () => <String>[]);
          zoneTables[zoneId]!.add(tableNameVal);
        }
        if (tableNameVal != null && tableIdVal != 0) {
          tableIds[tableNameVal] = tableIdVal;
        }
        if (zoneId != null) {
          zoneIds[zoneId] = _asInt(zoneId);
        }
        if (tableNameVal != null && statusVal != null) {
          tableStatus[tableNameVal] = statusVal;
        }
      }

      final resolvedFromTableId =
          fromTableId != 0 ? fromTableId : (tableIds[tableName] ?? 0);
      if (resolvedFromTableId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to transfer selected KOT")),
        );
        return;
      }

      String kotZone = '';
      for (final entry in zoneTables.entries) {
        if (entry.value.contains(tableName)) {
          kotZone = entry.key;
          break;
        }
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return BlocProvider(
            create: (_) => TransferKotBloc(
              repository: KotTransferRepository(),
            ),
            child: TransferKOTDialog(
              tableName: tableName,
              kotNo: (_selectedKot ?? 'KOT'),
              dateTime: DateTime.now(),
              items: transferItems,
              zoneTables: zoneTables,
              orderId: orderId,
              kotId: kotId,
              fromTableId: resolvedFromTableId,
              restaurantId: restaurantId,
              authToken: widget.token,
              zoneIds: zoneIds,
              tableIds: tableIds,
              tableStatus: tableStatus,
              kotZone: kotZone,
              zoneNames: zoneNames,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transfer KOT failed: $e")),
      );
    }
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
        onPermissionsReceived: (permissions) async {
          setState(() {
            _userPermissions = permissions;
            _selectedUser = {
              "id": permissions.userId,
              "name": permissions.displayName,
              "role": permissions.role,
            };
            _selectedTableIndex = null;
            _selectedTable = null;
            _selectedKot = null;
            _kotItems.clear();
          });
          await _fetchOrders();
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

                          // ✅ KOT LIST HEADER (Beige)
                          _buildKotListHeader(),

                          // const SizedBox(height: 8),

                          // ✅ WHITE CONTAINER BELOW HEADER
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,               // 🔥 White like image
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: _buildTableList(),             // 🔥 Grid inside
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),


                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
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
  Widget _buildKotListHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        "KOT list",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 🔹 LEFT: Title
          const Text(
            'Kitchen Status',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          /// 🔥 Push everything else to the right
          const Spacer(),

          /// 🔹 RIGHT GROUP
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 🔥 Order Type Tabs
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _orderTypes.map((type) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildOrderTypeButton(type),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(width: 14),

              /// 🔹 Area dropdown (only Dine-In)
              _buildAreaDropdown(),

              const SizedBox(width: 14),

              /// 🔹 Selected table owner
              if (_selectedTable != null) ...[
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${_selectedTable!['table_owner'] ?? '-'}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 14),
              ],

              /// 🔹 Search
              SizedBox(
                width: 260,
                child: _buildSearchBar(),
              ),
              const SizedBox(width: 12),

              /// 🔥 RESET BUTTON
              _buildResetButton(),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildResetButton() {
    return GestureDetector(
      onTap: isResetEnabled ? _onResetPressed : null,
      child: Opacity(
        opacity: isResetEnabled ? 1.0 : 0.5, // 🔒 visual disabled effect
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isResetEnabled ? Colors.red : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isResetEnabled ? Colors.red : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 18,
                color: isResetEnabled ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                'Reset',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isResetEnabled ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
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
        childAspectRatio: 1.7,
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD4EBFF), // ✅ #D4EBFF
                  width: 1.2,
                ),
              ),
          child: normalizeOrderType(selectedOrderType) == "dinein"
              ? _buildDineInCard(table, kotCount, isSelected)
              : _buildTakeawayCard(table, kotCount, isSelected),
        ),
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

  Widget _buildDineInCard(
      Map<String, dynamic> order,
      int kotCount,
      bool isSelected,
      ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 160, // 🔼 increase height here
      ),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0C6FDB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),

          // ───────── Table + Time ─────────
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

          // ───────── Order ID + KOT ─────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT SIDE (Order ID + Zone)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order ID: ${order['order_id']}",
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ✅ Zone Name (NEW)
                  Text(
                    "Zone: ${order['zone_name'] ?? '-'}",
                    style: TextStyle(
                      fontSize: 14,
                      // fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),

              // RIGHT SIDE (KOT + Remaining)
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
                        color:
                        isSelected ? Colors.white : Colors.black87,
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
        // color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.all(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFC2DFFF),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                if (selectedOrderType != "Takeaways") ...[
                  Text(
                    "Table No: ${hasTable ? _selectedTable!['table_name'] : '---'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  "Order ID: ${hasTable ? _selectedTable!['order_id'] : '---'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${_selectedKot ?? '---'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),

                // 🟢 PRINT KOT
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6, // ⬇ reduced
                    ),
                    minimumSize: const Size(32, 32), // ⬇ reduced
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  icon: const Icon(Icons.print, size: 14), // ⬇ reduced
                  label: const Text(
                    'Print KOT',
                    style: TextStyle(fontSize: 11), // ⬇ reduced
                  ),
                  onPressed: _selectedKot != null ? () {} : null,
                ),

                if (normalizeOrderType(selectedOrderType) == "dinein") ...[
                  const SizedBox(width: 6),

                  // 🔵 VOID ITEMS
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text(
                      'Void Items',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: _selectedKot != null ? _openVoidItemsDialog : null,
                  ),

                  const SizedBox(width: 6),

                  // 🟡 TRANSFER KOT
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text(
                      'Transfer KOT',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: _selectedKot != null ? _openTransferKotDialog : null,
                  ),
                ],
              ],
            ),

          ),
          // const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
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
                    final String status =
                    (kotOrder['status'] ?? 'Pending').toString();
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
                                color: isSelectedKot ? const Color(0xFF0C6FDB) : Color(0XFFECEEFB),
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

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                if (selectedOrderType != "Takeaways")
                                  Icon(
                                    isSelectedKot
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
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
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return Colors.orange;

      case 'ready':
        return Colors.green;

      case 'served':
        return Colors.red;

      // case 'cancelled':
      //   return Colors.red;
      //
      // case 'kot-processed':
      //   return Colors.purple;

      default:
        return Colors.grey;
    }
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
