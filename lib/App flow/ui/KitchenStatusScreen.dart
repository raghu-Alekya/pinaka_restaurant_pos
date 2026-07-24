import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';
import '../../printer/printer_settings.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/transer_kot.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/void_items.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Logic/kot_bloc.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Logic/transfer_kot_bloc.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Logic/void_item_bloc.dart';
import 'package:pinaka_restaurant_pos/repositories/kot_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/table_repository.dart';
import 'package:pinaka_restaurant_pos/repositories/void_item_repository.dart';
import '../../constants/constants.dart';
import '../../models/UserPermissions.dart';
import '../../models/order/void_kot_items.dart';
import '../../repositories/kitchen_repository.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/area_movement_notifier.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_bar.dart';
import 'home_screen.dart';

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
  Timer? _timer;
  bool _isDialogOpen = false;
  @override
  void initState() {
    super.initState();
    kitchenRepo = KitchenRepository(token: widget.token);
    _loadPermissions();
    _initializeData();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        _refreshSelectedTable();
      },
    );
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
    _timer?.cancel();
    super.dispose();
  }
  Future<void> _showSingleDialog(Future<void> Function() dialogFunction) async {
    if (_isDialogOpen) return;

    _isDialogOpen = true;

    try {
      await dialogFunction();
    } finally {
      _isDialogOpen = false;
    }
  }
  Future<void> _refreshSelectedTable() async {
    if (_selectedTable == null) return;

    await _fetchParentKotOrders(_selectedTable!);

    if (mounted) {
      setState(() {});
    }
  }
  Future<void> _initializeData() async {
    await _loadPermissions();

    final cachedOrderTypes = kitchenRepo.cachedOrderTypes;
    final cachedOrders = kitchenRepo.cachedOrders;

    if (cachedOrders != null && cachedOrders.isNotEmpty && mounted) {
      setState(() {
        if (cachedOrderTypes != null && cachedOrderTypes.isNotEmpty) {
          _orderTypes = cachedOrderTypes;
          selectedOrderType = _orderTypes.first;
        }
        _orders = cachedOrders;
      });
    }

    await Future.wait([
      _fetchZones(),
      _fetchOrderTypes(),
    ]);
    await _fetchOrders();
  }

  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null && mounted) {
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

    if (!mounted) return;

    _orders = orders;
    _selectedTable = null;
    _selectedKot = null;
    _kotItems.clear();

    // Fetch all parent KOT orders in parallel instead of a serial for-loop
    await Future.wait(_orders.map((order) => _fetchParentKotOrders(order, updateState: false)));

    if (mounted) {
      setState(() {});
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

  Future<void> _fetchParentKotOrders(Map<String, dynamic> order, {bool updateState = true}) async {
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

      order['kots'] =
          kotOrders.map((kot) => kot['kot_number']?.toString() ?? '').toList();
      order['kotOrders'] = kotOrders;

      if (updateState && mounted) {
        setState(() {
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
  List<String> _wrapText(String text, int maxLength) {
    if (text.isEmpty) return [''];
    List<String> lines = [];
    List<String> words = text.split(' ');
    String currentLine = '';

    for (String word in words) {
      if (word.isEmpty) continue;

      if (word.length > maxLength) {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = '';
        }
        int start = 0;
        while (start < word.length) {
          int end = start + maxLength;
          if (end > word.length) {
            end = word.length;
          }
          lines.add(word.substring(start, end));
          start = end;
        }
        continue;
      }

      if (currentLine.isEmpty) {
        currentLine = word;
      } else if (currentLine.length + 1 + word.length <= maxLength) {
        currentLine += ' ' + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines.isEmpty ? [''] : lines;
  }

  Future<void> _printSelectedKot() async {
    if (_selectedKot == null || _selectedTable == null) {
      debugPrint("Print KOT: _selectedKot or _selectedTable is null");
      return;
    }

    final selectedKotOrder = _selectedKotOrder();
    if (selectedKotOrder == null) {
      debugPrint("Print KOT: selectedKotOrder is null");
      return;
    }

    try {
      final profile = await CapabilityProfile.load(name: 'XP-N160I');
      final generator = Generator(PaperSize.mm80, profile);

      List<int> bytes = [];
      bytes += [27, 32, 0]; // Reset character spacing to 0 right at the start
      final displayKotNo = _selectedKot!.replaceAll('KOT#', '');

      bytes += generator.text(
        "COPY OF KOT - $displayKotNo",
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size3,
          width: PosTextSize.size2,
        ),
      );

      final tableName = (_selectedTable?['table_name'] ?? '').toString();
      final dineInTitle =
      tableName.isNotEmpty ? "Dine In: $tableName" : "Dine In";

      bytes += generator.text(
        dineInTitle,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size3,
          width: PosTextSize.size2,
        ),
      );

      bytes += generator.hr();
      // table row

      final now = DateTime.now();
      final dateText = "Date: ${DateFormat('dd/MM/yyyy').format(now)}";
      final timeText = "Time: ${DateFormat('hh:mm a').format(now)}";

      bytes += generator.row([
        PosColumn(
          width: 6,
          text: dateText,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          width: 6,
          text: timeText,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      // add a row of space between date row and Order id row
      bytes += [27, 74, 16];

      // order /captain row
      final orderId = (_selectedTable?['order_id'] ?? '').toString();
      final captainName = (selectedKotOrder['order_by'] ?? _selectedTable?['captain_name'] ?? 'Admin').toString();
      final orderIdText = "Order Id: $orderId";
      final captainText = "Captain: $captainName";

      if ((orderIdText.length + captainText.length) < 45) {
        bytes += generator.row([
          PosColumn(
            width: 5,
            text: orderIdText,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            width: 7,
            text: captainText,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);
      } else {
        bytes += generator.text(
          orderIdText,
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
        bytes += generator.text(
          captainText,
          styles: const PosStyles(align: PosAlign.left, bold: true),
        );
      }

      bytes += generator.hr();
      //  header

      // Set character spacing to 3 dots for items and headers
      bytes += [27, 32, 3];

      bytes += generator.row([
        PosColumn(
          width: 2,
          text: "S.No",
          styles: const PosStyles(
            bold: true,
          ),
        ),
        PosColumn(
          width: 8,
          text: "Item Name",
          styles: const PosStyles(
            bold: true,
          ),
        ),
        PosColumn(
          width: 2,
          text: "Qty",
          styles: const PosStyles(
            bold: true,
            align: PosAlign.right,
          ),
        ),
      ]);

      bytes += [27, 32, 0]; // Temporarily reset character spacing to 0 for divider
      bytes += generator.hr();
      bytes += [27, 32, 3]; // Set character spacing back to 3 for items

      // items
      int index = 1;

      for (final item in _kotItems) {
        final itemName = (item['item_name'] ?? item['name'] ?? '').toString();
        final qty = (item['quantity'] ?? item['qty'] ?? 1).toString();
        final nameLines = _wrapText(itemName, 22);

        bytes += generator.row([
          PosColumn(
            width: 2,
            text: index.toString(),
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
          PosColumn(
            width: 8,
            text: nameLines.first,
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
          PosColumn(
            width: 2,
            text: "x $qty",
            styles: const PosStyles(
              align: PosAlign.right,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
        ]);

        for (int i = 1; i < nameLines.length; i++) {
          bytes += generator.row([
            PosColumn(
              width: 2,
              text: "",
              styles: const PosStyles(
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
            PosColumn(
              width: 8,
              text: nameLines[i],
              styles: const PosStyles(
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
            PosColumn(
              width: 2,
              text: "",
              styles: const PosStyles(
                align: PosAlign.right,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
          ]);
        }

        // Modifiers
        if (item['modifiers'] != null && (item['modifiers'] is List) && (item['modifiers'] as List).isNotEmpty) {
          bytes += generator.row([
            PosColumn(width: 2, text: ""),
            PosColumn(
              width: 10,
              text: " + ${(item['modifiers'] as List).join(', ')}",
              styles: const PosStyles(
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
          ]);
        }

        // Addons
        if (item['addons'] != null && (item['addons'] is Map) && (item['addons'] as Map).isNotEmpty) {
          final addons = item['addons'] as Map<String, dynamic>;

          addons.forEach((name, details) {
            bytes += generator.row([
              PosColumn(width: 2, text: ""),
              PosColumn(
                width: 10,
                text: "   * $name x${details['quantity']}",
                styles: const PosStyles(
                  bold: true,
                  height: PosTextSize.size2,
                  width: PosTextSize.size1,
                ),
              ),
            ]);
          });
        }

        // Item Note / Remarks
        final note = (item['note'] ?? item['remarks'] ?? '').toString();
        if (note.isNotEmpty) {
          bytes += generator.row([
            PosColumn(width: 2, text: ""),
            PosColumn(
              width: 10,
              text: " Note: $note",
              styles: const PosStyles(
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
          ]);
        }

        // Thin spacing between item rows (16 dots = 2mm)
        bytes += [27, 74, 16];

        index++;
      }
      //  footer

      // Restore standard character spacing (0 dots) for footer and hr dividers
      bytes += [27, 32, 0];

      bytes += generator.hr();

      bytes += generator.text(
        "Note :",
        styles: const PosStyles(align: PosAlign.left),
      );

      bytes += generator.feed(3);
      bytes += generator.cut();

      final printerSettings = PrinterSettings();
      await printerSettings.loadPrinter();

      if (printerSettings.selectedPrinter != null) {
        await printerSettings.printTicket(bytes, generator);
      } else {
        debugPrint("KOT print: No printer selected");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                  "No printer selected. Please set up a printer in settings.",
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 1)
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("KOT print error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("KOT print failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        const SnackBar(content: Text("Unable to open Void Items for selected KOT"),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await VoidItemRepository().getKotLineItems(
        kotId: kotId,
        restaurantId: restaurantId,
        zoneId: zoneId,
        token: widget.token,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<UpdatekotBloc>(
                create: (_) => UpdatekotBloc(
                  repository: UpdatekotRepository(),
                ),
              ),

              BlocProvider<KotBloc>(
                create: (_) => KotBloc(
                  KotRepository(
                    baseUrl: AppConstants.baseDomain,
                  ),
                ),
              ),

              BlocProvider<KotLineItemsBloc>(
                create: (_) => KotLineItemsBloc(
                  repository: VoidItemRepository(),
                ),
              ),
            ],
            child: VoidItemsDialog(
              items: response.items,
              tableNo:
              (_selectedTable?['table_name'] ?? '').toString(),
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
        SnackBar(
          content: Text(
            "Failed to load KOT items: $e",
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
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
        const SnackBar(content: Text("Unable to transfer selected KOT"),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
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
          const SnackBar(content: Text("Unable to transfer selected KOT"),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.red,
          ),
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
        SnackBar(content: Text("Transfer KOT failed: $e"),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  String normalizeOrderType(String type) {
    return type.toLowerCase().replaceAll("-", "").replaceAll(" ", "");
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark
          ? const Color(0xFF161A26)
          : const Color(0xFFF6F6F6),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        userPermissions: _userPermissions,
        isHomeScreen: false,
        onPermissionsReceived: (permissions) async {
          if (!mounted) return;

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
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF202433)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.45)
                    : const Color(0x26000000),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 5,
                    right: 5,
                    bottom: 12,
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
                              const SizedBox(height: 2),
                              _buildKotListHeader(),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: filteredTables.isNotEmpty
                                        ? (isDark
                                        ? const Color(0xFF202433)
                                        : Colors.white)
                                        : (isDark
                                        ? const Color(0xFF2B3042)
                                        : const Color(0xFFF3F3F3)),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isDark
                                            ? Colors.white24
                                            : const Color(0xFFD8D8D8),
                                      ),
                                      left: BorderSide(
                                        color: isDark
                                            ? Colors.white24
                                            : const Color(0xFFD8D8D8),
                                      ),
                                      right: BorderSide(
                                        color: isDark
                                            ? Colors.white24
                                            : const Color(0xFFD8D8D8),
                                      ),
                                    ),
                                  ),
                                  child: _buildTableList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0, bottom: 0),
                          child: _buildOrderDetails(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildKotListHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF34384F)
            : const Color(0xFFFFDFAC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white24
                : const Color(0xFFD8D8D8),
          ),
          left: BorderSide(
            color: isDark
                ? Colors.white24
                : const Color(0xFFD8D8D8),
          ),
          right: BorderSide(
            color: isDark
                ? Colors.white24
                : const Color(0xFFD8D8D8),
          ),
        ),
      ),
      child: Text(
        "KOT list",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }



  Widget _buildAreaDropdown() {
    if (normalizeOrderType(selectedOrderType) != "dinein") {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF34384F)
            : const Color(0xFF0C6FDB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white24
              : Colors.transparent,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedArea,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white,
            size: 18,
          ),
          dropdownColor: isDark
              ? const Color(0xFF34384F)
              : const Color(0xFF0C6FDB),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
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
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderTypeButton(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool isEnabled = true;

    if (normalizeOrderType(title) == "takeaways" ||
        normalizeOrderType(title) == "onlineorders") {
      isEnabled = _userPermissions?.canViewOrderTypes ?? false;
    }

    bool isSelected =
        normalizeOrderType(title) == normalizeOrderType(selectedOrderType);

    return InkWell(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2B3042)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          border: Border(
            bottom: BorderSide(
              color: isSelected && isEnabled
                  ? const Color(0xFFFF4D20)
                  : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: !isEnabled
                ? Colors.grey
                : isSelected
                ? const Color(0xFFFF4D20)
                : (isDark ? Colors.white : Colors.black),
            fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 8),

          /// Title
          Text(
            'Kitchen Status',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const Spacer(),

          /// Right Group
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Order Type Tabs
              Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2B3042)
                      : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Colors.white24
                        : const Color(0xFFD4EBFF),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.30)
                          : Colors.black.withOpacity(0.05),
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

              /// Area Dropdown
              _buildAreaDropdown(),

              const SizedBox(width: 14),

              /// Selected Table Owner
              if (_selectedTable != null) ...[
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2B3042)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white24
                          : Colors.grey.shade300,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${_selectedTable!['table_owner'] ?? '-'}",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],

              /// Search
              SizedBox(
                width: 260,
                child: _buildSearchBar(),
              ),

              const SizedBox(width: 12),

              /// Reset Button
              _buildResetButton(),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildResetButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isResetEnabled ? _onResetPressed : null,
      child: Opacity(
        opacity: isResetEnabled ? 1.0 : 0.5,
        child: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isResetEnabled
                ? (isDark
                ? const Color(0xFF2B3042)
                : const Color(0xFFFDF8F8))
                : (isDark
                ? const Color(0xFF3A3F52)
                : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isResetEnabled
                  ? Colors.red
                  : (isDark ? Colors.white24 : Colors.grey.shade400),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 18,
                color: isResetEnabled
                    ? Colors.red
                    : (isDark ? Colors.white54 : Colors.grey),
              ),
              const SizedBox(width: 6),
              Text(
                'Reset',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isResetEnabled
                      ? Colors.red
                      : (isDark ? Colors.white54 : Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }





  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 260,
      child: Container(
        height: 44,
        decoration: ShapeDecoration(
          color: isDark
              ? const Color(0xFF2B3042)
              : Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isDark
                  ? Colors.white24
                  : const Color(0xFFD4EBFF),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          shadows: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.30)
                  : const Color(0x4204347F),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          cursorColor: isDark ? Colors.white : Colors.black,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) =>
              setState(() => searchQuery = value.toLowerCase()),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 44,
            ),
            hintText: "Order ID or Table No",
            hintStyle: TextStyle(
              color: isDark
                  ? Colors.white54
                  : const Color(0xFFC3C2C2),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
  Widget _buildTableList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tables = filteredTables;
    final bool hasTableData = tables.isNotEmpty;

    if (tables.isEmpty) {
      return Center(
        child: Text(
          'No orders found',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
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
              color: isDark
                  ? const Color(0xFF2B3042)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white24
                    : const Color(0xFFD4EBFF),
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

  Widget _buildTakeawayCard(
      Map<String, dynamic> order,
      int kotCount,
      bool isSelected,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF0C6FDB)
            : (isDark ? const Color(0xFF2B3042) : Colors.white),
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
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
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
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: isSelected
                    ? Colors.white
                    : (isDark
                    ? const Color(0xFF4C81F1)
                    : const Color(0xFF0C6FDB)),
                child: Text(
                  "KOT",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0C6FDB)
                        : Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 100,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF0C6FDB)
            : (isDark ? const Color(0xFF2B3042) : Colors.white),
        borderRadius: BorderRadius.circular(6),
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
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
              Text(
                order["order_time"] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black),
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
              // LEFT SIDE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order ID: ${order['order_id']}",
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Zone: ${order['zone_name'] ?? '-'}",
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black),
                    ),
                  ),
                ],
              ),

              // RIGHT SIDE
              Row(
                children: [
                  _buildKotCircleWithOverlap(
                    kotText: "KOT",
                    isSelected: isSelected,
                    kotCount: kotCount,
                  ),
                  if ((order['remaining_count'] ?? 0) > 0) ...[
                    Text(
                      "+${order['remaining_count']}",
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isSelected
        ? const Color(0xFFA6C4E4)
        : (isDark
        ? const Color(0xFF4C81F1)
        : const Color(0xFF125BCE));

    final secondaryColor = isSelected
        ? const Color(0xFFD8E9FB)
        : (isDark
        ? const Color(0xFF6A96F5)
        : const Color(0xFF81ACEF));

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isSecondary ? secondaryColor : primaryColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: kotText.isNotEmpty
          ? Text(
        kotText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : Colors.white,
        ),
      )
          : null,
    );
  }
  Widget _buildOrderDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasTable = _selectedTable != null;
    final List<String> kots =
        (_selectedTable?['kots'] as List<dynamic>?)?.cast<String>() ?? [];
// ✅ Add it here
    final bool hasData = hasTable && kots.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(left: 0, right: 7,bottom: 0),
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.all(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF34384F)
                  : const Color(0xFFC2DFFF),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white24 : const Color(0xFFD8D8D8),
                ),
                left: BorderSide(
                  color: isDark ? Colors.white24 : const Color(0xFFD8D8D8),
                ),
                right: BorderSide(
                  color: isDark ? Colors.white24 : const Color(0xFFD8D8D8),
                ),
              ),
              borderRadius: BorderRadius.only(topRight: Radius.circular(8),topLeft: Radius.circular(8) ), // borderRadius: BorderRadius.circular(6)
            ),
            child: Row(
              children: [
                if (selectedOrderType != "Takeaways") ...[
                  Text(
                    "Table No: ${hasTable ? _selectedTable!['table_name'] : '---'}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  "Order ID: ${hasTable ? _selectedTable!['order_id'] : '---'}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${_selectedKot ?? '---'}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
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
                  onPressed: _selectedKot != null ? _printSelectedKot : null,
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
                    onPressed: _selectedKot != null
                        ? () => _showSingleDialog(_openVoidItemsDialog)
                        : null,
                    // onPressed: _selectedKot != null ? _openVoidItemsDialog : null,
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
                    onPressed: _selectedKot != null
                        ? () => _showSingleDialog(_openTransferKotDialog)
                        : null,
                    // onPressed: _selectedKot != null ? _openTransferKotDialog : null,
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
                color: hasData
                    ? (isDark
                    ? const Color(0xFF202433)
                    : Colors.white)
                    : (isDark
                    ? const Color(0xFF161A26)
                    : const Color(0xFFF3F3F3)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD8D8D8),
                  ),
                  left: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD8D8D8),
                  ),
                  right: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD8D8D8),
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: hasTable && kots.isNotEmpty
                  ? SingleChildScrollView(
                child: Column(
                  children: kots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final kot = entry.value;
                    final kotOrders =
                        (_selectedTable?['kotOrders'] as List<dynamic>?)
                            ?.cast<Map<String, dynamic>>() ??
                            [];

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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelectedKot
                                  ? (isDark
                                  ? const Color(0xFF0C6FDB)
                                  : const Color(0xFFEAF1FF))
                                  : (isDark
                                  ? const Color(0xFF2B3042)
                                  : const Color(0xFFF5F6FA)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelectedKot
                                    ? const Color(0xFF0C6FDB)
                                    : (isDark
                                    ? Colors.white24
                                    : const Color(0XFFECEEFB)),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Kot Number
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF34384F)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    kot,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                if (displayTime.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF34384F)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      displayTime,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),

                                const SizedBox(width: 10),

                                if (kotOrderBy.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF5A4B1A)
                                          : const Color(0xFFFFF3CD),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      kotOrderBy,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
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
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black,
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
                  style: TextStyle(
                    color: isDark
                        ? Colors.white54
                        : Colors.grey,
                    fontSize: 16,
                  ),
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
        return const Color(0xFFFF9800);

      case 'ready':
        return const Color(0xFF4CAF50);

      case 'served':
        return const Color(0xFFF44336);

      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Widget _buildKotItemsOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 630,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF202433)
            : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? Colors.white24
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 290,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: isDark
                  ? Colors.white24
                  : Colors.grey.shade300,
              dataTableTheme: DataTableThemeData(
                headingRowColor: WidgetStateProperty.all(
                  isDark
                      ? const Color(0xFF34384F)
                      : const Color(0xFFE0E0E0),
                ),
                dataRowColor: WidgetStateProperty.all(
                  isDark
                      ? const Color(0xFF202433)
                      : Colors.white,
                ),
              ),
            ),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark
                      ? const Color(0xFF34384F)
                      : const Color(0xFFE0E0E0),
                ),
                columnSpacing: 16,
                horizontalMargin: 20,
                columns: [
                  DataColumn(
                    label: Text(
                      'S.No',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Item Name',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Qty',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Price',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total Price',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                      DataCell(
                        Text(
                          index.toString(),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item['item_name'] ?? '',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          qty.toStringAsFixed(0),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          price.toStringAsFixed(2),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          total.toStringAsFixed(2),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}