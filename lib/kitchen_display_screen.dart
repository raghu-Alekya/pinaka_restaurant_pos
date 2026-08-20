

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:kds_app/providers/order_provider.dart';
import 'package:kds_app/top_bar.dart';
import 'package:kds_app/widgets/completed_orders.dart';
import 'package:kds_app/widgets/login_screen.dart';
import 'package:kds_app/widgets/repeated_item.dart';
import 'package:kds_app/widgets/settings_screen.dart';
import 'package:kds_app/widgets/stock_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'active_orderscreen.dart';
import 'providers/order_provider.dart';
import 'services/kds_mqtt_service.dart';

class KitchenDashboardScreen extends StatefulWidget {
  final String token;
  final int restaurantId;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onMenuTap;

  const KitchenDashboardScreen({
    super.key,
    required this.token,
    required this.restaurantId,
    this.onOpenSettings,
    this.onMenuTap,

  });

  @override
  State<KitchenDashboardScreen> createState() => _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen> {
  String selectedOrderType = "All";
  OrderTypeFilter selectedFilter = OrderTypeFilter.all;
  String? selectedCancelKotId;
  String? selectedCancelItemKotId;
  final Set<String> selectedItems = {};
  // final VoidCallback? onMenuTap;
  bool _categoryMapLoaded = false;
  final GlobalKey<ScaffoldState> _scaffoldKey =
  GlobalKey<ScaffoldState>();

  // final Map<String, String> productCategoryMap = {};
  Map<String, String> productCategoryMap = {};
  Map<String, String> productCategoryNameMap = {};

  // Existing map - used only by the Ready/Running item switches.
  final Map<String, List<bool>> selectedItemsMap = {};

  // Separate map for item cancellation so existing switch state is untouched.
  final Map<String, List<bool>> cancelSelectionMap = {};

  // Keeps successfully cancelled item(s) visually struck through immediately.
  // The provider/API remains the source of truth; this only prevents the UI
  // from losing the visual state during the same rebuild.
  final Set<String> locallyCancelledItemKeys = {};

  KotView selectedView = KotView.pending;
  bool isZoomedOut = true;
  final Set<String> zoomedKotIds = {};
  final Set<String> expandedKotIds = {};
  Timer? _liveTimer;

  String _formatCountUpTimer(DateTime? kotTime) {
    if (kotTime == null) return '0.00';
    final elapsedSeconds = DateTime.now().difference(kotTime).inSeconds;
    if (elapsedSeconds < 0) return '0.00';
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '$minutes.${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final orderProvider = context.read<OrderProvider>();

      await orderProvider.loadExistingOrders();

      if (!mounted) return;

      setState(() {
        productCategoryMap =
        Map<String, String>.from(
          orderProvider.productCategoryMap,
        );

        productCategoryNameMap =
        Map<String, String>.from(
          orderProvider.productCategoryNameMap,
        );

        _categoryMapLoaded = true;
      });
    });
  }


  bool _isKotFullyServed(Map<String, dynamic> order) {
    final items = _getOrderItems(order);

    if (items.isEmpty) {
      return false;
    }

    final kotId = order['id']?.toString() ?? '';
    final kotNo = order['kotNo']?.toString() ?? '';
    final parentOrderId =
        (order['parentOrderId'] ??
            order['parent_order_id'])
            ?.toString() ??
            '';

    final switchKey = kotId.isNotEmpty
        ? kotId
        : '${kotNo}_$parentOrderId';

    final switchValues = selectedItemsMap[switchKey];

    if (switchValues == null) {
      return false;
    }

    // Make sure we have a toggle value for every item.
    if (switchValues.length < items.length) {
      return false;
    }

    // KOT is fully served only when ALL item toggles are ON.
    final allServed = switchValues
        .take(items.length)
        .every((value) => value);

    debugPrint(
      'KOT FULLY SERVED CHECK: '
          'KOT=$switchKey | '
          'ITEMS=${items.length} | '
          'TOGGLES=${switchValues.take(items.length).toList()} | '
          'ALL SERVED=$allServed',
    );

    return allServed;
  }
  bool itemStatusIsCancelled(dynamic rawItem) {
    if (rawItem is! Map) return false;

    final status =
        rawItem['status']?.toString().trim().toLowerCase() ?? '';

    return status == 'cancelled' || status == 'cancel';
  }

  void _clearCancelSelection(String kotId) {
    cancelSelectionMap.remove(kotId);

    if (selectedCancelItemKotId == kotId) {
      selectedCancelItemKotId = null;
    }
  }
  List<bool> _getCancelSelectionValues(
      String kotId,
      int itemCount,
      ) {
    final existing = cancelSelectionMap[kotId];

    if (existing != null) {
      while (existing.length < itemCount) {
        existing.add(false);
      }

      if (existing.length > itemCount) {
        return existing.sublist(0, itemCount);
      }

      return existing;
    }

    final values = List<bool>.filled(itemCount, false);
    cancelSelectionMap[kotId] = values;

    return values;
  }
  // ==========================================================
  // COMMON ORDER ITEM READER
  // Prefer kot_items because that is the KOT payload used by KDS.
  // Fall back to items for older/local payloads.
  // ==========================================================
  List<dynamic> _getOrderItems(Map<String, dynamic> order) {
    // The backend/KOT payload may contain both `kot_items` and `items`.
    // Some provider states keep `kot_items` as an empty list while the
    // actual active KOT items are present in `items`. In that case, using
    // `kot_items ?? items` incorrectly returns the empty list.
    final kotItems = order['kot_items'];

    if (kotItems is List && kotItems.isNotEmpty) {
      return kotItems;
    }

    // Support camelCase payloads as well.
    final kotItemsCamel = order['kotItems'];

    if (kotItemsCamel is List && kotItemsCamel.isNotEmpty) {
      return kotItemsCamel;
    }

    final items = order['items'];

    if (items is List && items.isNotEmpty) {
      return items;
    }

    // Return an existing empty list if the order has one; otherwise empty.
    if (kotItems is List) {
      return kotItems;
    }

    if (items is List) {
      return items;
    }

    return <dynamic>[];
  }

  // Stable key used to keep a cancelled item struck through immediately
  // even before the provider refreshes/rebuilds the KOT list.
  String _getCancelItemKey(dynamic rawItem, int index) {
    if (rawItem is Map) {
      final item = Map<String, dynamic>.from(rawItem);
      final lineItemId = item['lineItemId'] ??
          item['line_item_id'] ??
          item['id'];

      if (lineItemId != null && lineItemId.toString().trim().isNotEmpty) {
        return lineItemId.toString().trim();
      }
    }

    return 'index_$index';
  }

  String _normalizeProductName(String name) {
    String value = name
        .trim()
        .toLowerCase();

    // Remove common variation suffixes
    value = value.replaceAll(
      RegExp(
        r'\s*-\s*(jumbo|single|family|full|half|regular|small|medium|large)\s*$',
        caseSensitive: false,
      ),
      '',
    );

    return value.trim();
  }
  String formatAddOns(Map<String, dynamic> addOns) {
    final result = <String>[];

    addOns.forEach((name, value) {
      if (value is Map) {
        final quantity =
            value['quantity'] ??
                value['qty'] ??
                1;

        result.add('$name x$quantity');
      } else {
        result.add('$name x$value');
      }
    });

    return result.join(', ');
  }String _getItemNote(dynamic rawItem) {
    if (rawItem is! Map) {
      return '';
    }

    final item = Map<String, dynamic>.from(rawItem);

    // ==========================================================
    // 1. DIRECT NOTE
    // ==========================================================

    final directNote = item['note']?.toString().trim();

    if (directNote != null && directNote.isNotEmpty) {
      return directNote;
    }

    final notes = item['notes']?.toString().trim();

    if (notes != null && notes.isNotEmpty) {
      return notes;
    }

    // ==========================================================
    // 2. NOTE FROM meta_data
    // ==========================================================

    final metaData = item['meta_data'];

    if (metaData is List) {
      for (final meta in metaData) {
        if (meta is! Map) {
          continue;
        }

        final key = meta['key']?.toString().trim();

        if (key == '_modifier_notes') {
          final value = meta['value'];

          if (value == null) {
            continue;
          }

          // Normal String
          if (value is String) {
            final note = value.trim();

            if (note.isNotEmpty) {
              return note;
            }
          }

          // If backend sends something else
          final note = value.toString().trim();

          if (note.isNotEmpty) {
            return note;
          }
        }
      }
    }

    return '';
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    if (orderProvider.productCategoryMap.isNotEmpty) {
      productCategoryMap = Map<String, String>.from(orderProvider.productCategoryMap);
    }
    if (orderProvider.productCategoryNameMap.isNotEmpty) {
      productCategoryNameMap = Map<String, String>.from(orderProvider.productCategoryNameMap);
    }


    // Calculate repeatedCount (Summary items count) dynamically
    final summaryOrders = orderProvider.orders.where((o) {
      return o.status == 'Preparing';
    });
    final Set<String> summaryItemNames = {};
    for (final order in summaryOrders) {
      for (final item in order.items) {
        final itemStatus = item.status.toLowerCase();
        if (itemStatus != 'cancelled' && itemStatus != 'cancel') {
          summaryItemNames.add(item.name);
        }
      }
    }
    final summaryItemsCount = summaryItemNames.length;

    final orders = orderProvider.pendingOrders;

    final filteredOrders =
    orders.where((order) {
      final type = order['type']?.toString().toLowerCase() ?? '';

      switch (selectedFilter) {
        case OrderTypeFilter.all:
          return true;

        case OrderTypeFilter.dineIn:
          return type.contains('dine');

        case OrderTypeFilter.takeaway:
          return type.contains('take');

        case OrderTypeFilter.online:
          return type.contains('online');
      }
    }).toList();

    Widget bodyWidget;
    switch (selectedView) {
      case KotView.pending:
        bodyWidget = _buildPendingBody(filteredOrders, orderProvider);
        break;
      case KotView.active:
        bodyWidget = ActiveOrdersScreen(
          token: widget.token,
          restaurantId: widget.restaurantId,
          isEmbedded: true,
        );
        break;
      case KotView.repeated:
        bodyWidget = RepeatedItemsScreen(
          token: widget.token,
          restaurantId: widget.restaurantId,
          isEmbedded: true,
        );
        break;
      case KotView.history:
        bodyWidget = CompletedOrdersScreen(
          token: widget.token,
          restaurantId: widget.restaurantId,
          isEmbedded: true,
          onRecallSuccess: () {
            setState(() {
              selectedView = KotView.active;
            });
          },
        );
        break;
    }

    return Scaffold(
      key: _scaffoldKey,

      backgroundColor: const Color(0xffF4F4F4),

      // ==========================================================
      // LEFT MENU / DRAWER
      // ==========================================================

      drawer: _buildKdsDrawer(),

      body: SafeArea(
        child: Column(
          children: [

            // ======================================================
            // COMMON TOP BAR
            // ======================================================

            TopBarWidget(
              token: widget.token,
              restaurantId: widget.restaurantId,
              selectedView: selectedView,

              onViewChanged: (view) {
                setState(() {
                  selectedView = view;
                });
              },

              // This is for LOGOUT only
              onLogout: () {
                // Your logout logic
              },

              pendingCount: orderProvider.pendingOrders.length,

              activeCount:
              orderProvider.preparingOrders.length +
                  orderProvider.readyOrders.length,

              repeatedCount: summaryItemsCount,

              onMenuTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            // ======================================================
            // EXISTING KDS BODY
            // ======================================================

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: bodyWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildKdsDrawer() {
    return Drawer(
      width: 250,
      backgroundColor: Colors.white,

      child: SafeArea(
        child: Column(
          children: [

            // ====================================================
            // DRAWER HEADER
            // ====================================================

            Container(
              height: 65,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xffE4E7EC),
                    width: 1,
                  ),
                ),
              ),

              child: Row(
                children: [

                  // PINAKA LOGO
                  Expanded(
                    child: Image.asset(
                      'assets/pinaka.png',
                      height: 42,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (
                          context,
                          error,
                          stackTrace,
                          ) {
                        return const Text(
                          'PINAKA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff2F4376),
                          ),
                        );
                      },
                    ),
                  ),

                  // CLOSE BUTTON
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },

                    borderRadius:
                    BorderRadius.circular(20),

                    child: const Padding(
                      padding: EdgeInsets.all(5),

                      child: Icon(
                        Icons.chevron_left,
                        size: 26,
                        color: Color(0xff667085),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // MENU ITEMS
            // ====================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  10,
                  12,
                  10,
                  10,
                ),

                child: Column(
                  children: [

                    // ==================================================
                    // KDS DASHBOARD
                    // ==================================================

                    _buildDrawerMenuItem(
                      title: 'KDS Dashboard',
                      icon: Icons.grid_view_rounded,
                      isSelected: true,

                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),

                    const SizedBox(height: 7),

                    // ==================================================
                    // SELECT ITEM / CATEGORY
                    // ==================================================

                    _buildDrawerMenuItem(
                      title: 'Select Item / Category',
                      icon: Icons.format_list_bulleted,

                      onTap: () {
                        Navigator.of(context).pop();

                        // Add navigation here
                      },
                    ),

                    const SizedBox(height: 7),

                    // ==================================================
                    // STOCK
                    // ==================================================

                    _buildDrawerMenuItem(
                      title: 'Stock',
                      icon: Icons.inventory_2_outlined,

                      onTap: () {
                        // Close drawer first
                        Navigator.of(context).pop();

                        // Navigate to Stock Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StockScreen(
                              token: widget.token,
                              restaurantId: widget.restaurantId,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 7),

                    // ==================================================
                    // RECALL
                    // ==================================================

                    _buildDrawerMenuItem(
                      title: 'Recall',
                      icon: Icons.refresh,

                      onTap: () {
                        Navigator.of(context).pop();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CompletedOrdersScreen(
                                  token: widget.token,
                                  restaurantId:
                                  widget.restaurantId,
                                ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 7),

                    // ==================================================
                    // SETTINGS
                    // ==================================================
                    _buildDrawerMenuItem(
                      title: 'Settings',
                      icon: Icons.settings_outlined,
                      onTap: () {
                        // Close drawer
                        Navigator.of(context).pop();

                        // Open Settings Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const KitchenDisplaySettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ====================================================
            // LOGOUT
            // ====================================================

            _buildDrawerLogout(),
          ],
        ),
      ),
    );
  }
  Widget _buildDrawerLogout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        15,
      ),
      child: InkWell(
        onTap: () async {
          // ==================================================
          // CLOSE DRAWER
          // ==================================================

          Navigator.of(context).pop();

          // ==================================================
          // GET STORE DETAILS BEFORE LOGOUT
          // ==================================================

          final prefs =
          await SharedPreferences.getInstance();

          final storeBaseUrl =
              prefs.getString('store_base_url') ?? '';

          final storeName =
              prefs.getString('store_name') ?? '';

          final storeId =
              prefs.getString('store_id') ?? '';

          // ==================================================
          // REMOVE EMPLOYEE LOGIN SESSION
          // ==================================================

          await prefs.remove('token');
          await prefs.remove('auth_token');
          await prefs.remove('user_id');
          await prefs.remove('employee_name');
          await prefs.remove('display_name');
          await prefs.remove('role');
          await prefs.remove('emp_login_pin');
          await prefs.remove('emp_login_pin_str');

          if (!mounted) return;

          // ==================================================
          // GO TO EMPLOYEE LOGIN
          // ==================================================

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeLoginScreen(
                storeBaseUrl: storeBaseUrl,
                storeName: storeName,
                storeId: storeId,

                // ==================================================
                // AFTER SUCCESSFUL PIN LOGIN
                // ==================================================

                onLoginSuccess: (config) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          KitchenDashboardScreen(
                            token: config.apiToken,
                            restaurantId:
                            int.tryParse(
                              config.restaurantId,
                            ) ??
                                0,
                          ),
                    ),
                        (route) => false,
                  );
                },
              ),
            ),
                (route) => false,
          );
        },

        borderRadius: BorderRadius.circular(8),

        child: Container(
          height: 44,
          width: double.infinity,

          decoration: BoxDecoration(
            color: const Color(0xffffefec),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xffffa69b),
              width: 0.8,
            ),
          ),

          child: const Row(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [

              Icon(
                Icons.logout,
                size: 17,
                color: Color(0xffff4f3d),
              ),

              SizedBox(width: 7),

              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xffff4f3d),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDrawerMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
      BorderRadius.circular(8),

      child: Container(
        height: 44,
        width: double.infinity,

        padding:
        const EdgeInsets.symmetric(
          horizontal: 13,
        ),

        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xffff5b4f)
              : Colors.transparent,

          borderRadius:
          BorderRadius.circular(8),

          boxShadow: isSelected
              ? const [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ]
              : null,
        ),

        child: Row(
          children: [

            Icon(
              icon,
              size: 19,

              color: isSelected
                  ? Colors.white
                  : const Color(0xff64748B),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,

                maxLines: 1,

                overflow:
                TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 13,

                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,

                  color: isSelected
                      ? Colors.white
                      : const Color(
                    0xff1E293B,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // PENDING + ACTIVE KOT DASHBOARD
  // Matches the supplied reference image:
  //   LEFT  = ITEM QUEUE
  //   RIGHT = ACTIVE KOT'S
  // ---------------------------------------------------------------------------
  Widget _buildPendingBody(List<Map<String, dynamic>> filteredOrders,
      OrderProvider orderProvider,) {
    // Item Queue must aggregate every currently active KOT, not only Pending.
    // This keeps Pending + Preparing + Ready items visible in the queue.
    final itemQueueOrders = <Map<String, dynamic>>[
      ...orderProvider.pendingOrders,
      ...orderProvider.preparingOrders,
      ...orderProvider.readyOrders,
    ];

    debugPrint('========== ITEM QUEUE SOURCE ==========');
    debugPrint('Pending KOTs   : ${orderProvider.pendingOrders.length}');
    debugPrint('Preparing KOTs : ${orderProvider.preparingOrders.length}');
    debugPrint('Ready KOTs     : ${orderProvider.readyOrders.length}');
    debugPrint('Queue KOTs     : ${itemQueueOrders.length}');
    for (final order in itemQueueOrders) {
      final queueItems = _getOrderItems(order);
      debugPrint(
        'KOT ${order['kotNo'] ?? order['kot_number'] ?? order['kotNumber']}: '
            '${queueItems.length} items',
      );
    }
    debugPrint('========================================');

    // A freshly printed KOT is initially Pending. The old version only
    // displayed Preparing + Ready orders, so Pending KOTs were invisible.
    // Display Pending + Preparing + Ready and de-duplicate by KOT id.
    final displayOrders = <Map<String, dynamic>>[];
    final seenKotIds = <String>{};

    final allKots = <Map<String, dynamic>>[
      ...orderProvider.pendingOrders,
      ...orderProvider.preparingOrders,
      ...orderProvider.readyOrders,
    ];

    for (final order in allKots) {
      final kotId = order['id']?.toString() ?? '';
      final status =
          order['status']?.toString().toLowerCase() ?? '';

      // ==========================================================
      // REMOVE KOT WHEN ALL ITEMS ARE SERVED
      // ==========================================================

      if (_isKotFullyServed(order)) {
        debugPrint(
          'REMOVING KOT FROM ACTIVE: '
              'KOT=${kotId.isNotEmpty ? kotId : order['kotNo']} '
              'because all items are served',
        );

        continue;
      }

      // ==========================================================
      // REMOVE ALREADY COMPLETED / CANCELLED KOTS
      // ==========================================================

      if (status == 'cancelled' ||
          status == 'cancel' ||
          status == 'served' ||
          status == 'completed') {
        continue;
      }

      final uniqueKey = kotId.isNotEmpty
          ? kotId
          : '${order['kotNo']}_${order['parentOrderId']}';

      if (seenKotIds.add(uniqueKey)) {
        displayOrders.add(order);
      }
    }
    // ==========================================================
// SORT ACTIVE KOTS
// 1. RUNNING first
// 2. NEW second
// 3. Within same status -> oldest KOT first
// ==========================================================

    displayOrders.sort((a, b) {
      final aKotStatus =
          a['kot_order_status']?.toString().trim().toLowerCase() ?? '';

      final bKotStatus =
          b['kot_order_status']?.toString().trim().toLowerCase() ?? '';

      // Running gets higher priority
      int getStatusPriority(String status) {
        if (status == 'running') return 0;
        if (status == 'new') return 1;

        // Preparing can also be considered running
        if (status == 'preparing' || status == 'processing') {
          return 0;
        }

        return 2;
      }

      final aPriority = getStatusPriority(aKotStatus);
      final bPriority = getStatusPriority(bKotStatus);

      // First compare status priority
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      // Same status -> compare KOT creation time
      final aTime = _parseKotTime(a['kotTime']);
      final bTime = _parseKotTime(b['kotTime']);

      return aTime.compareTo(bTime);
    });

    final filteredActiveOrders = displayOrders.where((order) {
      final type = order['type']?.toString().toLowerCase() ?? '';

      switch (selectedFilter) {
        case OrderTypeFilter.all:
          return true;
        case OrderTypeFilter.dineIn:
          return type.contains('dine');
        case OrderTypeFilter.takeaway:
          return type.contains('take');
        case OrderTypeFilter.online:
          return type.contains('online');
      }
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xffE4E7EC),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ================================================================
          // LEFT PANEL - ITEM QUEUE
          // 40% WIDTH
          // ================================================================
          Expanded(
            flex: 4,
            child: _buildItemQueuePanel(
              itemQueueOrders,
              orderProvider,
            ),
          ),

          // ================================================================
          // CENTER DIVIDER
          // ================================================================
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(
              vertical: 14,
            ),
            color: const Color(0xffD0D5DD),
          ),

          // ================================================================
          // RIGHT PANEL - ACTIVE KOT'S
          // 60% WIDTH
          // ================================================================
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                8,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  // ----------------------------------------------------------
                  // ACTIVE HEADER
                  // ----------------------------------------------------------
                  _buildActiveHeader(
                    orderProvider,
                    displayOrders,
                  ),

                  const SizedBox(height: 8),

                  // ----------------------------------------------------------
                  // ACTIVE KOT GRID
                  // ----------------------------------------------------------
                  Expanded(
                    child: filteredActiveOrders.isEmpty
                        ? _buildNoActiveKots()
                        : () {
                            int maxItemsInView = 5;
                            for (final order in filteredActiveOrders) {
                              final kotId = order['id']?.toString() ?? '';
                              final kotNo = (order['kotNo'] ?? order['kot_no'] ?? order['kot_number'] ?? order['kotNumber'] ?? order['id'] ?? '').toString().replaceAll('KOT#', '').replaceAll('KOT', '').trim();
                              final parentOrderId = (order['parentOrderId'] ?? order['parent_order_id'] ?? order['order_id'] ?? order['orderId'] ?? '').toString().replaceAll('ORDER#', '').trim();
                              final switchKey = kotId.isNotEmpty ? kotId : '${kotNo}_$parentOrderId';

                              if (expandedKotIds.contains(switchKey)) {
                                final rawItems = _getOrderItems(order);
                                if (rawItems.length > maxItemsInView) {
                                  maxItemsInView = rawItems.length;
                                }
                              }
                            }
                            final double dynamicExtent = 330.0 + (maxItemsInView > 5 ? (maxItemsInView - 5) * 44.0 : 0.0);

                            return GridView.builder(
                              padding: const EdgeInsets.only(
                                left: 0,
                                right: 0,
                                bottom: 4,
                              ),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                mainAxisExtent: dynamicExtent,
                              ),
                              itemCount: filteredActiveOrders.length,
                              itemBuilder: (context, index) {
                                return _buildReferenceKotCard(
                                  filteredActiveOrders[index],
                                  orderProvider,
                                );
                              },
                            );
                          }(),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ITEM QUEUE
  // ---------------------------------------------------------------------------
  Widget _buildItemQueuePanel(
      List<Map<String, dynamic>> orders,
      OrderProvider orderProvider,
      ) {
    final totalItems = _getTotalItems(orders);

    final effectiveCategoryMap = orderProvider.productCategoryMap.isNotEmpty
        ? orderProvider.productCategoryMap
        : productCategoryMap;

    final effectiveCategoryNameMap = orderProvider.productCategoryNameMap.isNotEmpty
        ? orderProvider.productCategoryNameMap
        : productCategoryNameMap;

    final groups = _groupPendingItems(
      orders,
      effectiveCategoryMap,
      effectiveCategoryNameMap,
      selectedItemsMap,
    );


    final entries = groups.entries.toList();

    // ==========================================================
    // BUILD VEG / NON-VEG MAP
    //
    // true  = Veg
    // false = Non-Veg
    // null  = No icon
    // ==========================================================

    final Map<String, bool?> itemVegMap = {};

    for (final order in orders) {
      final rawItems = _getOrderItems(order);

      if (rawItems.isEmpty) {
        continue;
      }

      for (int index = 0; index < rawItems.length; index++) {
        final rawItem = rawItems[index];

        if (rawItem is! Map) {
          continue;
        }

        final item = Map<String, dynamic>.from(rawItem);
        // ==========================================================
// HIDE ITEM FROM QUEUE WHEN TOGGLE IS ON
// API status is the source of truth, selectedItemsMap
// provides immediate UI update until provider refreshes.
// ==========================================================

        final kotId = order['id']?.toString() ?? '';
        final kotNo = order['kotNo']?.toString() ?? '';
        final parentOrderId =
            order['parentOrderId']?.toString() ?? '';

        final switchKey = kotId.isNotEmpty
            ? kotId
            : '${kotNo}_$parentOrderId';

        final switchValues = selectedItemsMap[switchKey];

        if (switchValues != null &&
            index < switchValues.length &&
            switchValues[index] == true) {
          continue;
        }

        final name =
        item['item_name']?.toString().trim().isNotEmpty == true
            ? item['item_name'].toString().trim()
            : item['name']?.toString().trim() ?? '';

        if (name.isEmpty) {
          continue;
        }

        // ========================================================
        // DO NOT USE ?? false HERE
        //
        // Backend:
        // true  -> Veg
        // false -> Non-Veg
        // null  -> No icon
        // ========================================================
        final dynamic vegValue;

        if (item.containsKey('is_veg')) {
          // IMPORTANT:
          // If backend sends is_veg: null,
          // preserve null. Do NOT fallback.
          vegValue = item['is_veg'];
        } else if (item.containsKey('isVeg')) {
          vegValue = item['isVeg'];
        } else if (item.containsKey('is_vegetarian')) {
          vegValue = item['is_vegetarian'];
        } else if (item.containsKey('veg')) {
          vegValue = item['veg'];
        } else {
          vegValue = null;
        }

        bool? isVeg;

        if (vegValue == null) {
          // Backend explicitly says NULL
          // => no veg/non-veg icon
          isVeg = null;
        } else if (
        vegValue == true ||
            vegValue == 1 ||
            vegValue
                .toString()
                .trim()
                .toLowerCase() ==
                'true' ||
            vegValue.toString().trim() == '1') {
          // Veg
          isVeg = true;
        } else if (
        vegValue == false ||
            vegValue == 0 ||
            vegValue
                .toString()
                .trim()
                .toLowerCase() ==
                'false' ||
            vegValue.toString().trim() == '0') {
          // Non-Veg
          isVeg = false;
        } else {
          // Unknown backend value
          // => don't display icon
          isVeg = null;
        }

        itemVegMap[name] = isVeg;
      }
    }

    debugPrint('========== ITEM QUEUE ==========');
    debugPrint('TOTAL ITEMS: $totalItems');
    debugPrint('CATEGORIES: ${entries.length}');
    debugPrint('VEG MAP: $itemVegMap');
    debugPrint('================================');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        14,
        16,
        14,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ==========================================================
          // ITEM QUEUE TITLE
          // ==========================================================

          Text(
            'ITEM QUEUE',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xff172033),
            ),
          ),

          const SizedBox(height: 2),

          // ==========================================================
          // TOTAL ITEMS
          // ==========================================================

          Text(
            '$totalItems items pending across all KOTs',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: const Color(0xff667085),
            ),
          ),

          const SizedBox(height: 12),

          // ==========================================================
          // CATEGORY CARDS
          // ==========================================================

          Expanded(
            child: entries.isEmpty
                ? Center(
              child: Text(
                orderProvider.connectionState ==
                    KdsConnectionState.connected
                    ? 'No pending items'
                    : 'Connecting to POS...',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: const Color(0xff98A2B3),
                ),
              ),
            )
                : LayoutBuilder(
              builder: (context, constraints) {
                const double horizontalSpacing = 5;
                const double verticalSpacing = 5;

                // Split entries into two columns
                final leftEntries = <MapEntry<String, dynamic>>[];
                final rightEntries = <MapEntry<String, dynamic>>[];

                for (int i = 0; i < entries.length; i++) {
                  if (i.isEven) {
                    leftEntries.add(entries[i]);
                  } else {
                    rightEntries.add(entries[i]);
                  }
                }

                return SingleChildScrollView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =====================================================
                      // LEFT COLUMN
                      // =====================================================

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 0;
                            i < leftEntries.length;
                            i++) ...[
                              _buildQueueCategory(
                                leftEntries[i].key,
                                leftEntries[i].value,
                                i * 2,
                                itemVegMap,
                              ),

                              if (i < leftEntries.length - 1)
                                const SizedBox(
                                  height: verticalSpacing,
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(
                        width: horizontalSpacing,
                      ),

                      // =====================================================
                      // RIGHT COLUMN
                      // =====================================================

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 0;
                            i < rightEntries.length;
                            i++) ...[
                              _buildQueueCategory(
                                rightEntries[i].key,
                                rightEntries[i].value,
                                i * 2 + 1,
                                itemVegMap,
                              ),

                              if (i < rightEntries.length - 1)
                                const SizedBox(
                                  height: verticalSpacing,
                                ),
                            ],
                          ],
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
    );
  }

  Widget _buildQueueCategory(
      String category,
      Map<String, int> items,
      int index,
      Map<String, bool?> itemVegMap,
      ) {
    final categoryColor = _queueColor(index);

    // ==========================================================
    // CATEGORY TOTAL
    // ==========================================================

    final categoryTotal = items.values.fold<int>(
      0,
          (sum, quantity) => sum + quantity,
    );

    // ==========================================================
    // LIGHT CATEGORY BADGE COLOR
    // ==========================================================

    final badgeColor = categoryColor.withOpacity(0.10);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        9,
        10,
        9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xffE4E7EC),
          width: .7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          // ========================================================
          // CATEGORY HEADER
          // ========================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Expanded(
                child: Text(
                  category.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: categoryColor,
                  ),
                ),
              ),

              const SizedBox(width: 5),

              // ====================================================
              // CATEGORY TOTAL
              // ====================================================

              Container(
                constraints: const BoxConstraints(
                  minWidth: 26,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$categoryTotal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: categoryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // ========================================================
          // ITEMS
          // ========================================================

          ...items.entries.map(
                (entry) {
              final itemName = entry.key;
              final quantity = entry.value;

              // ==================================================
              // IMPORTANT
              //
              // true  = Veg
              // false = Non-Veg
              // null  = Don't show icon
              // ==================================================

              final bool? isVeg =
              itemVegMap[itemName];

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 6,
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,
                  children: [

                    // ==================================================
                    // VEG / NON-VEG ICON
                    //
                    // Only display when backend provided
                    // true or false.
                    //
                    // null = NO ICON
                    // ==================================================

                    if (isVeg != null)
                      vegNonVegIcon(isVeg),

                    // Add spacing only if icon exists
                    if (isVeg != null)
                      const SizedBox(width: 7),

                    // ==================================================
                    // ITEM NAME
                    // ==================================================

                    Expanded(
                      child: Text(
                        itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          height: 1.0,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff344054),
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    // ==================================================
                    // QUANTITY
                    // ==================================================

                    Text(
                      '$quantity',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff172033),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
// ============================================================================
// QUEUE CATEGORY COLORS
// ============================================================================

  Color _queueColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xffF04438); // STARTERS
      case 1:
        return const Color(0xff009688); // MAIN COURSE
      case 2:
        return const Color(0xff2E8B3C); // BREADS
      default:
        return const Color(0xff475467);
    }
  }
  // ==========================================================
// BUILD PRODUCT CATEGORY MAP
// ==========================================================

  void _buildProductCategoryMap(dynamic categoryProducts) {
    productCategoryMap.clear();
    productCategoryNameMap.clear();

    debugPrint('==========================================');
    debugPrint('BUILDING PRODUCT CATEGORY MAP');
    debugPrint('CATEGORY PRODUCTS: $categoryProducts');
    debugPrint('==========================================');

    if (categoryProducts is! List) {
      debugPrint(
        'category_products is not a List: $categoryProducts',
      );

      _categoryMapLoaded = false;

      if (mounted) {
        setState(() {});
      }

      return;
    }

    for (final categoryData in categoryProducts) {
      if (categoryData is! Map) {
        continue;
      }

      // ======================================================
      // CATEGORY NAME
      // ======================================================

      final category =
          categoryData['category_name']
              ?.toString()
              .trim() ??
              categoryData['categoryName']
                  ?.toString()
                  .trim() ??
              categoryData['name']
                  ?.toString()
                  .trim() ??
              '';

      if (category.isEmpty) {
        debugPrint(
          'SKIPPING CATEGORY: category name is empty',
        );
        continue;
      }

      // ======================================================
      // PRODUCTS
      // ======================================================

      final products = categoryData['products'];

      if (products is! List) {
        debugPrint(
          'NO PRODUCTS FOUND FOR CATEGORY: $category',
        );
        continue;
      }

      // ======================================================
      // LOOP PRODUCTS
      // ======================================================

      for (final product in products) {
        if (product is! Map) {
          continue;
        }

        // ====================================================
        // PRODUCT ID
        // ====================================================

        final productId =
            product['product_id'] ??
                product['productId'] ??
                product['id'];

        final productIdString =
            productId?.toString().trim() ?? '';

        // ====================================================
        // PRODUCT NAME
        // ====================================================

        final productName =
            product['item_name']
                ?.toString()
                .trim() ??
                product['name']
                    ?.toString()
                    .trim() ??
                product['product_name']
                    ?.toString()
                    .trim() ??
                product['itemName']
                    ?.toString()
                    .trim() ??
                '';

        // ====================================================
        // PRODUCT ID → CATEGORY
        // ====================================================

        if (productIdString.isNotEmpty) {
          productCategoryMap[productIdString] =
              category;
        }

        // ====================================================
        // PRODUCT NAME → CATEGORY
        // ====================================================

        if (productName.isNotEmpty) {
          final normalizedName =
          _normalizeProductName(productName);

          if (normalizedName.isNotEmpty) {
            productCategoryNameMap[
            normalizedName
            ] = category;
          }

          // Also store exact lowercase name.
          productCategoryNameMap[
          productName.toLowerCase()
          ] = category;
        }

        // ====================================================
        // DEBUG
        // ====================================================

        debugPrint(
          'CATEGORY MAP: '
              'ID=$productIdString | '
              'NAME=$productName | '
              'CATEGORY=$category',
        );
      }
    }

    // ==========================================================
    // CATEGORY MAP READY
    // ==========================================================

    _categoryMapLoaded = true;

    debugPrint('==========================================');
    debugPrint('CATEGORY MAP LOADED');
    debugPrint(
      'PRODUCT ID MAP COUNT: '
          '${productCategoryMap.length}',
    );
    debugPrint(
      'PRODUCT NAME MAP COUNT: '
          '${productCategoryNameMap.length}',
    );
    debugPrint('==========================================');

    // ==========================================================
    // REBUILD ITEM QUEUE
    // ==========================================================

    if (mounted) {
      setState(() {});
    }
  }

// ============================================================================
// GROUP KOT ITEMS BY CATEGORY
// ============================================================================

  Map<String, Map<String, int>> _groupPendingItems(
      List<Map<String, dynamic>> orders,
      Map<String, String> productCategoryMap,
      Map<String, String> productCategoryNameMap,
      Map<String, List<bool>> selectedItemsMap,
      ){
    final result = <String, Map<String, int>>{};

    for (final order in orders) {
      // ==========================================================
      // KOT ITEMS
      // ==========================================================

      final rawItems = _getOrderItems(order);

      if (rawItems.isEmpty) {
        debugPrint(
          'NO KOT ITEMS FOUND FOR ORDER: ${order['order_id']}',
        );
        continue;
      }

      for (int index = 0; index < rawItems.length; index++) {
        final rawItem = rawItems[index];

        if (rawItem is! Map) {
          continue;
        }

        final item = Map<String, dynamic>.from(rawItem);

        // ==========================================================
        // HIDE ITEM WHEN TOGGLE IS ON
        // ==========================================================

        final kotId = order['id']?.toString() ?? '';
        final kotNo = order['kotNo']?.toString() ?? '';
        final parentOrderId =
            (order['parentOrderId'] ??
                order['parent_order_id'])
                ?.toString() ??
                '';

        final switchKey = kotId.isNotEmpty
            ? kotId
            : '${kotNo}_$parentOrderId';

        final switchValues = selectedItemsMap[switchKey];

        if (switchValues != null &&
            index < switchValues.length &&
            switchValues[index] == true) {
          debugPrint(
            'ITEM QUEUE HIDDEN: '
                '${item['item_name'] ?? item['name']} '
                'KOT=$switchKey INDEX=$index',
          );

          continue;
        }

        // ==========================================================
        // STATUS
        // ==========================================================

        final status =
            item['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
                '';

        if (status == 'cancelled' ||
            status == 'cancel') {
          continue;
        }

        // ==========================================================
        // ITEM NAME
        // ==========================================================

        final itemName =
            item['item_name']
                ?.toString()
                .trim() ??
                '';

        final name =
        itemName.isNotEmpty
            ? itemName
            : (
            item['name']
                ?.toString()
                .trim()
                .isNotEmpty ==
                true
                ? item['name']
                .toString()
                .trim()
                : (
                item['itemName']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                    true
                    ? item['itemName']
                    .toString()
                    .trim()
                    : 'Item'
            )
        );

        // ==========================================================
        // PRODUCT ID
        // ==========================================================

        final productId =
            item['product_id']
                ?.toString()
                .trim() ??
                item['productId']
                    ?.toString()
                    .trim() ??
                '';

        // ==========================================================
// CATEGORY RESOLUTION
// ==========================================================
//
// PRIORITY:
//
// 1. category_name
// 2. categoryName
// 3. product ID → category map
// 4. exact product name → category map
// 5. normalized product name → category map
// 6. valid section name
// 7. valid category value
// 8. OTHER
//
// IMPORTANT:
//
// New MQTT KOT can contain:
//
// section: {
//   id: 0,
//   name: Unknown
// }
//
// "Unknown" must NEVER become the final category.
// ==========================================================

        String category = '';

// ==========================================================
// GET PRODUCT ID
// ==========================================================

        final resolvedProductId =
        item['productId']
            ?.toString()
            .trim()
            .isNotEmpty ==
            true
            ? item['productId']
            .toString()
            .trim()
            : item['product_id']
            ?.toString()
            .trim() ??
            '';

        debugPrint(
          'RESOLVED PRODUCT ID: $resolvedProductId',
        );

// ==========================================================
// GET PRODUCT NAME
// ==========================================================

        final resolvedName =
        item['name']
            ?.toString()
            .trim()
            .isNotEmpty ==
            true
            ? item['name']
            .toString()
            .trim()
            : item['item_name']
            ?.toString()
            .trim() ??
            '';

        debugPrint(
          'RESOLVED PRODUCT NAME: $resolvedName',
        );

// ==========================================================
// HELPER - VALID CATEGORY
// ==========================================================

        bool isValidCategory(String value) {
          final cleaned = value.trim();

          if (cleaned.isEmpty) {
            return false;
          }

          final upper = cleaned.toUpperCase();

          if (upper == 'OTHER' ||
              upper == 'UNKNOWN' ||
              upper == 'NULL' ||
              upper == 'UNDEFINED') {
            return false;
          }

          // Prevent this type of value from becoming a category:
          //
          // {id: 0, name: Unknown, imagepath: ...}
          //
          if (cleaned.startsWith('{') &&
              cleaned.endsWith('}')) {
            return false;
          }

          return true;
        }

// ==========================================================
// 1. API category_name
// ==========================================================

        final apiCategory =
            item['category_name']
                ?.toString()
                .trim() ??
                '';

        if (isValidCategory(apiCategory)) {
          category = apiCategory;

          debugPrint(
            'CATEGORY SOURCE: category_name',
          );
        }

// ==========================================================
// 2. categoryName
// ==========================================================

        if (category.isEmpty) {
          final categoryName =
              item['categoryName']
                  ?.toString()
                  .trim() ??
                  '';

          if (isValidCategory(categoryName)) {
            category = categoryName;

            debugPrint(
              'CATEGORY SOURCE: categoryName',
            );
          }
        }

// ==========================================================
// 3. PRODUCT ID → CATEGORY MAP
// ==========================================================
//
// THIS IS THE MOST IMPORTANT PART FOR NEW MQTT KOT.
//
// Example:
//
// productId = 14147
//
// productCategoryMap:
//
// 14147 → Starters
//
// ==========================================================

        if (category.isEmpty &&
            resolvedProductId.isNotEmpty) {
          final mappedCategory =
              productCategoryMap[
              resolvedProductId
              ]?.trim() ??
                  '';

          debugPrint(
            'PRODUCT ID LOOKUP: '
                '$resolvedProductId → $mappedCategory',
          );

          if (isValidCategory(mappedCategory)) {
            category = mappedCategory;

            debugPrint(
              'CATEGORY SOURCE: PRODUCT ID MAP',
            );
          }
        }

// ==========================================================
// 4. EXACT PRODUCT NAME → CATEGORY MAP
// ==========================================================

        if (category.isEmpty &&
            resolvedName.isNotEmpty) {
          final exactName =
          resolvedName.toLowerCase().trim();

          final mappedCategory =
              productCategoryNameMap[
              exactName
              ]?.trim() ??
                  '';

          debugPrint(
            'EXACT NAME LOOKUP: '
                '$exactName → $mappedCategory',
          );

          if (isValidCategory(mappedCategory)) {
            category = mappedCategory;

            debugPrint(
              'CATEGORY SOURCE: EXACT NAME MAP',
            );
          }
        }

// ==========================================================
// 5. NORMALIZED PRODUCT NAME → CATEGORY MAP
// ==========================================================
//
// Example:
//
// Fish Biryani - Single
// Fish Biryani - Family
// Fish Biryani - Jumbo
//
// → fish biryani
//
// → Main Course
//
// ==========================================================

        if (category.isEmpty &&
            resolvedName.isNotEmpty) {
          final normalizedName =
          _normalizeProductName(
            resolvedName,
          );

          final mappedCategory =
              productCategoryNameMap[
              normalizedName
              ]?.trim() ??
                  '';

          debugPrint(
            'NORMALIZED NAME: '
                '$normalizedName',
          );

          debugPrint(
            'NORMALIZED LOOKUP: '
                '$mappedCategory',
          );

          if (isValidCategory(mappedCategory)) {
            category = mappedCategory;

            debugPrint(
              'CATEGORY SOURCE: NORMALIZED NAME MAP',
            );
          }
        }

// ==========================================================
// 6. SECTION MAP
// ==========================================================
//
// Only use section if it contains a REAL category.
//
// Do NOT use:
//
// {id: 0, name: Unknown}
//
// ==========================================================

        if (category.isEmpty) {
          final rawSection =
          item['section'];

          String sectionName = '';

          if (rawSection is Map) {
            sectionName =
                rawSection['name']
                    ?.toString()
                    .trim() ??
                    '';

            if (!isValidCategory(sectionName)) {
              sectionName = '';

              final sectionCategory =
                  rawSection['category_name']
                      ?.toString()
                      .trim() ??
                      rawSection['categoryName']
                          ?.toString()
                          .trim() ??
                      '';

              if (isValidCategory(
                sectionCategory,
              )) {
                sectionName =
                    sectionCategory;
              }
            }
          } else if (rawSection is String) {
            sectionName =
                rawSection.trim();
          }

          if (isValidCategory(sectionName)) {
            category = sectionName;

            debugPrint(
              'CATEGORY SOURCE: SECTION',
            );
          }
        }

// ==========================================================
// 7. CATEGORY FIELD
// ==========================================================

        if (category.isEmpty) {
          final rawCategory =
          item['category'];

          String categoryValue = '';

          if (rawCategory is Map) {
            categoryValue =
                rawCategory['name']
                    ?.toString()
                    .trim() ??
                    rawCategory['category_name']
                        ?.toString()
                        .trim() ??
                    rawCategory['categoryName']
                        ?.toString()
                        .trim() ??
                    '';
          } else if (rawCategory is String) {
            categoryValue =
                rawCategory.trim();
          }

          if (isValidCategory(categoryValue)) {
            category = categoryValue;

            debugPrint(
              'CATEGORY SOURCE: CATEGORY FIELD',
            );
          }
        }

// ==========================================================
// 7.5. SMART HEURISTICS FOR ITEM NAME KEYWORDS
// ==========================================================

        if (!isValidCategory(category) && resolvedName.isNotEmpty) {
          final lowerName = resolvedName.toLowerCase();
          if (lowerName.contains('naan') ||
              lowerName.contains('kulcha') ||
              lowerName.contains('roti') ||
              lowerName.contains('paratha') ||
              lowerName.contains('phulka') ||
              lowerName.contains('bhatura') ||
              lowerName.contains('puri') ||
              lowerName.contains('bread')) {
            category = 'INDIAN BREADS';
          } else if (lowerName.contains('soup')) {
            category = 'SOUPS';
          } else if (lowerName.contains('kebab') ||
              lowerName.contains('kabab') ||
              lowerName.contains('tikka')) {
            category = 'KEBABS';
          } else if (lowerName.contains('biryani') ||
              lowerName.contains('pulao') ||
              lowerName.contains('fried rice')) {
            category = 'RICE & BIRYANI';
          }
        }

// ==========================================================
// 8. FINAL FALLBACK
// ==========================================================

        if (!isValidCategory(category)) {
          category = 'OTHER';

          debugPrint(
            'CATEGORY SOURCE: FALLBACK OTHER',
          );
        }


// ==========================================================
// FINAL DEBUG
// ==========================================================

        debugPrint(
          '==========================================',
        );

        debugPrint(
          'QUEUE CATEGORY DEBUG',
        );

        debugPrint(
          'ITEM: $resolvedName',
        );

        debugPrint(
          'PRODUCT ID: $resolvedProductId',
        );

        debugPrint(
          'API CATEGORY: '
              '${item['category_name']}',
        );

        debugPrint(
          'CATEGORY NAME: '
              '${item['categoryName']}',
        );

        debugPrint(
          'PRODUCT ID MAP: '
              '${productCategoryMap[resolvedProductId]}',
        );

        debugPrint(
          'EXACT NAME MAP: '
              '${productCategoryNameMap[resolvedName.toLowerCase()]}',
        );

        debugPrint(
          'NORMALIZED NAME MAP: '
              '${productCategoryNameMap[_normalizeProductName(resolvedName)]}',
        );

        debugPrint(
          'SECTION: '
              '${item['section']}',
        );

        debugPrint(
          'FINAL CATEGORY: $category',
        );

        debugPrint(
          '==========================================',
        );
        // ==========================================================
        // QUANTITY
        // ==========================================================

        final quantity = _toInt(
          item['quantity'] ??
              item['qty'] ??
              1,
        );

        if (quantity <= 0) {
          continue;
        }

        // ==========================================================
        // CREATE CATEGORY
        // ==========================================================

        result.putIfAbsent(
          category,
              () => <String, int>{},
        );

        // ==========================================================
        // ADD ITEM
        // ==========================================================

        result[category]![name] =
            (result[category]![name] ?? 0) +
                quantity;
      }
    }

    // ==========================================================
    // FINAL DEBUG
    // ==========================================================

    debugPrint(
        '========== GROUPED ITEM QUEUE =========='
    );

    result.forEach(
          (category, items) {
        debugPrint(
          '$category => $items',
        );
      },
    );

    debugPrint(
        '========================================'
    );

    return result;
  }
// ============================================================================
// TOTAL PENDING ITEMS
// ============================================================================

  int _getTotalItems(
      List<Map<String, dynamic>> orders,
      ) {
    var total = 0;

    for (final order in orders) {
      final rawItems = _getOrderItems(order);

      if (rawItems.isEmpty) {
        continue;
      }

      final kotId = order['id']?.toString() ?? '';
      final kotNo = order['kotNo']?.toString() ?? '';
      final parentOrderId =
          (order['parentOrderId'] ?? order['parent_order_id'])?.toString() ?? '';

      final switchKey = kotId.isNotEmpty ? kotId : '${kotNo}_$parentOrderId';
      final switchValues = selectedItemsMap[switchKey];

      for (int index = 0; index < rawItems.length; index++) {
        final rawItem = rawItems[index];

        if (rawItem is! Map) {
          continue;
        }

        // Skip item if toggled ON (ready/served) in UI
        if (switchValues != null &&
            index < switchValues.length &&
            switchValues[index] == true) {
          continue;
        }

        final item = Map<String, dynamic>.from(
          rawItem,
        );

        // ==========================================================
        // STATUS
        // ==========================================================
        final status = item['status']
            ?.toString()
            .trim()
            .toLowerCase() ??
            '';

        if (status == 'cancelled' ||
            status == 'cancel') {
          continue;
        }

        // ==========================================================
        // QUANTITY
        // ==========================================================
        final quantity = _toInt(
          item['quantity'] ??
              item['qty'] ??
              1,
        );

        if (quantity > 0) {
          total += quantity;
        }
      }
    }

    return total;
  }


// ============================================================================
// SAFE INT CONVERSION
// ============================================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    if (value is num) {
      return value.toInt();
    }

    final parsed = int.tryParse(
      value?.toString().trim() ?? '',
    );

    return parsed ?? 1;
  }

  // ---------------------------------------------------------------------------
  // ACTIVE HEADER
  // ---------------------------------------------------------------------------
  Widget _buildActiveHeader(OrderProvider provider,
      List<Map<String, dynamic>> activeOrders,) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ACTIVE KOT'S",
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xff172033),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              "Currently active KOT's",
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: const Color(0xff667085),
              ),
            ),
          ],
        ),
        const Spacer(),
        InkWell(
          onTap: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fetching latest KOTs...'),
                duration: Duration(milliseconds: 1000),
              ),
            );
            await provider.loadExistingOrders();

          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xffF2F4F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xffD0D5DD)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 16, color: Color(0xff344054)),
                SizedBox(width: 4),
                Text(
                  'Refresh',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff344054),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _buildReferenceFilter(
          'All',
          activeOrders.length,
          OrderTypeFilter.all,
          const Color(0xffF04438),
        ),

        const SizedBox(width: 4),
        _buildReferenceFilter(
          'Dine-In',
          _countActiveType(activeOrders, 'dine'),
          OrderTypeFilter.dineIn,
          const Color(0xffF79009),
        ),
        const SizedBox(width: 4),
        _buildReferenceFilter(
          'Takeaways',
          _countActiveType(activeOrders, 'take'),
          OrderTypeFilter.takeaway,
          const Color(0xff175CD3),
        ),
        const SizedBox(width: 4),
        _buildReferenceFilter(
          'Online Orders',
          _countActiveType(activeOrders, 'online'),
          OrderTypeFilter.online,
          const Color(0xff4D8F2F),
        ),
      ],
    );
  }

  int _countActiveType(List<Map<String, dynamic>> orders,
      String value,) {
    return orders.where((order) {
      return order['type']?.toString().toLowerCase().contains(value) ??
          false;
    }).length;
  }

  Widget _buildReferenceFilter(
      String title,
      int count,
      OrderTypeFilter filter,
      Color activeColor,
      ) {
    final selected = selectedFilter == filter;

    final Color countColor = selected
        ? activeColor
        : const Color(0xffE4E7EC);

    return InkWell(
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xffFFFDFB)
              : const Color(0xffF9FAFB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? const Color(0xffE4E7EC)
                : const Color(0xffEAECF0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xff475467),
              ),
            ),

            const SizedBox(width: 4),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: countColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? Colors.white
                      : const Color(0xff667085),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ---------------------------------------------------------------------------
  // KOT CARD
  // ---------------------------------------------------------------------------
  Widget _buildReferenceKotCard(Map<String, dynamic> order,
      OrderProvider provider,) {
    final kotId = order['id']?.toString() ?? '';
    final orderType = order['type']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'Pending';
    final normalizedStatus = status.toLowerCase();

// KOT ordered by
    final kotOrderBy = order['kot_order_by']?.toString().trim() ?? '';

    debugPrint('========== KOT ORDER BY DEBUG ==========');
    debugPrint('KOT       : ${order['kotNo']}');
    debugPrint('KOT ORDER BY: $kotOrderBy');
    debugPrint('FULL ORDER: $order');
    debugPrint('========================================');
// KOT order status from backend
    final kotOrderStatus =
        order['kot_order_status']?.toString().trim().toLowerCase() ?? '';
    debugPrint('================ KOT STATUS DEBUG ================');
    debugPrint('KOT       : ${order['kotNo']}');
    debugPrint('TABLE     : ${order['tableName']}');
    debugPrint('ORDER ID  : ${order['parentOrderId']}');
    debugPrint('STATUS    : ${order['status']}');
    debugPrint('KOT STATUS: ${order['kot_status']}');
    debugPrint('KOT ORDER : ${order['kot_order_status']}');
    debugPrint('FINAL     : $kotOrderStatus');
    debugPrint('====================================================');
    final type = orderType.toLowerCase();

    final isDineIn = type.contains('dine');
    final isTakeaway = type.contains('take');
    final isOnline = type.contains('online');

    final headerColor = isDineIn
        ? const Color(0xffFFBE8B)
        : isTakeaway
        ? const Color(0xffA6BBD6)
        : isOnline
        ? const Color(0xffA7C79B)
        : const Color(0xffA2B39B);

    final table = order['tableName']?.toString() ??
        order['tableNo']?.toString() ??
        '';
    final kotNo = (order['kotNo'] ??
            order['kot_no'] ??
            order['kot_number'] ??
            order['kotNumber'] ??
            order['id'] ??
            '')
        .toString()
        .replaceAll('KOT#', '')
        .replaceAll('KOT', '')
        .trim();

    final parentOrderId = (order['parentOrderId'] ??
            order['parent_order_id'] ??
            order['order_id'] ??
            order['orderId'] ??
            '')
        .toString()
        .replaceAll('ORDER#', '')
        .trim();


    final rawItems = _getOrderItems(order);
    final List items = rawItems;

    // Same key already used by the existing Ready/Running switches.
    final switchKey = kotId.isNotEmpty
        ? kotId
        : '${kotNo}_$parentOrderId';

    final bool isExpanded = expandedKotIds.contains(switchKey);
    final bool hasMoreThanFive = items.length > 5;
    final int visibleItemsCount = (hasMoreThanFive && !isExpanded) ? 5 : items.length;


    // Cancellation state is kept separately so the existing switch state
    // and status flow are not changed.
    final cancelSelections = _getCancelSelectionValues(
      switchKey,
      items.length,
    );

    final isCancelMode = selectedCancelItemKotId == switchKey;

    final cancellableIndexes = <int>[];

    for (int i = 0; i < items.length; i++) {
      final raw = items[i];

      if (raw is! Map) continue;

      final itemStatus =
          raw['status']?.toString().trim().toLowerCase() ?? '';

      // Already cancelled → don't show
      if (itemStatus == 'cancelled' || itemStatus == 'cancel') {
        continue;
      }

      // Check Ready/Running toggle state
      final switchValues = selectedItemsMap[switchKey];

      final isToggleOn =
          switchValues != null &&
              i < switchValues.length &&
              switchValues[i] == true;

      // Toggle ON → don't show in Cancel mode
      if (isToggleOn) {
        continue;
      }

      // Only non-cancelled + toggle OFF items can be cancelled
      cancellableIndexes.add(i);
    }

    final selectedCancelCount = cancellableIndexes
        .where((index) => index < cancelSelections.length && cancelSelections[index])
        .length;

    final allItemsSelectedForCancel =
        cancellableIndexes.isNotEmpty &&
            selectedCancelCount == cancellableIndexes.length;
    // ==========================================================
// KOT NOTE
// ==========================================================

    String kotNote = '';

    for (final rawItem in items) {
      final note = _getItemNote(rawItem);

      if (note.isNotEmpty) {
        kotNote = note;
        break;
      }
    }

    debugPrint('========== KOT NOTE ==========');
    debugPrint('KOT: $kotNo');
    debugPrint('NOTE: $kotNote');
    debugPrint('==============================');

    final kotTime = _parseKotTime(order['kotTime']);
    final time = DateFormat('HH:mm').format(kotTime);
    final date = DateFormat('hh:mm a').format(kotTime);

    final isNewKot = kotOrderStatus == 'new';
    final isRunningKot = kotOrderStatus == 'running';

    final switchValues = _getKotSwitchValues(
      switchKey,
      items,
    );

    while (switchValues.length < items.length) {
      switchValues.add(false);
    }

    final allItemsOn = items.isNotEmpty &&
        switchValues.length >= items.length &&
        switchValues.take(items.length).every((value) => value);

    final readyCount = switchValues
        .take(items.length)
        .where((value) => value)
        .length;

    final String buttonText;
    final Color buttonColor;

    if (allItemsOn || normalizedStatus == 'ready') {
      buttonText = 'Ready';
      buttonColor = const Color(0xff5B9638);
    } else if (normalizedStatus == 'served' ||
        normalizedStatus == 'completed') {
      buttonText = 'Served';
      buttonColor = const Color(0xff667085);
    } else if (isNewKot) {
      buttonText = 'New';
      buttonColor = const Color(0xff3B923F); // GREEN
    } else if (isRunningKot) {
      buttonText = 'Running';
      buttonColor = const Color(0xffC01F33); // RED
    } else {
      buttonText = 'New';
      buttonColor = const Color(0xff3B923F); // GREEN
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: headerColor.withOpacity(.70),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // =============================================================
          // 1. HEADER — reference: about 32 px
          // =============================================================
          SizedBox(
            height: 48,
            child: Container(
              color: headerColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ==========================================================
                  // TABLE
                  // ==========================================================
                  if (table.isNotEmpty)
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        table,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: headerColor,
                          fontSize: 14,
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  if (table.isNotEmpty)
                    const SizedBox(width: 5),

                  // ==========================================================
                  // LIVE COUNT-UP TIMER (AFTER TABLE NAME)
                  // ==========================================================
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 11,
                          color: headerColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatCountUpTimer(kotTime),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: headerColor,
                            fontSize: 13,
                            height: 1.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ==========================================================
                  // ORDER TYPE
                  // ==========================================================
                  Container(
                    height: 28,
                    constraints: const BoxConstraints(
                      maxWidth: 100,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      orderType.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: headerColor,
                        fontSize: 13,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // ==========================================================
                  // ZOOM IN / ZOOM OUT ICON (CROSS FORM ARROWS <->)
                  // ==========================================================
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          expandedKotIds.remove(switchKey);
                        } else {
                          expandedKotIds.add(switchKey);
                        }
                      });
                    },
                    child: Container(
                      height: 28,
                      width: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isExpanded
                            ? Icons.close_fullscreen
                            : Icons.open_in_full,
                        size: 16,
                        color: headerColor,
                      ),
                    ),
                  ),


                ],
              ),
            ),
          ),

          // =============================================================
          // 2. KOT INFO — reference: about 41 px
          // =============================================================
          // =============================================================
// 2. KOT INFO
// =============================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              10,
              6,
              10,
              5,
            ),
            child:Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ==========================================================
                // TOP ROW: KOT + ITEMS READY
                // ==========================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // KOT NUMBER
                    Expanded(
                      child: Text(
                        'KOT #$kotNo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xff344054),
                        ),
                      ),
                    ),

                    // ITEMS READY + COUNT
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Items Ready',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            height: 1.0,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff667085),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$readyCount/${items.length}',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                            color: allItemsOn
                                ? const Color(0xff5B9638)
                                : headerColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ==========================================================
                // SECOND ROW: ORDER ID + CAPTAIN + TIME
                // ==========================================================
                // ==========================================================
// SECOND ROW: ORDER ID + CAPTAIN + TIME
// ==========================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // ORDER ID - LEFT
                    Expanded(
                      child: Text(
                        'Order: #$parentOrderId',

                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          height: 1.0,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff667085),
                        ),
                      ),
                    ),

                    // CAPTAIN + TIME - RIGHT MOST
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        // Captain
                        Text(
                          order['kot_order_by']?.toString().trim() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            height: 1.0,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff667085),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Time icon
                        const Icon(
                          Icons.access_time_outlined,
                          size: 11,
                          color: Color(0xff98A2B3),
                        ),

                        const SizedBox(width: 3),

                        // Time
                        Text(
                          date,
                          maxLines: 1,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            height: 1.0,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff667085),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )
          ),

          const Divider(
            height: 1,
            thickness: .7,
            color: Color(0xffEAECF0),
          ),

// =============================================================
// KOT NOTE
// =============================================================

          if (kotNote.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(
                10,
                8,
                10,
                4,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xffF2F2F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 14,
                    color: Color(0xff667085),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      'Note: $kotNote',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff667085),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // =============================================================
          // 3. ITEMS — compact, evenly spaced like reference
          // =============================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                4,
                8,
                4,
              ),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(visibleItemsCount, (index) {

                        final raw = items[index];

                        if (raw is! Map) {
                          return const SizedBox.shrink();
                        }

                        final item = Map<String, dynamic>.from(raw);
                        final itemStatus =
                            item['status']?.toString().trim().toLowerCase() ?? '';

                        final cancelItemKey =
                        _getCancelItemKey(item, index);

                        final isCancelled =
                            itemStatus == 'cancelled' ||
                                itemStatus == 'cancel' ||
                                locallyCancelledItemKeys.contains(cancelItemKey);

                        final isSelectedForCancel =
                            index < cancelSelections.length &&
                                cancelSelections[index];

                        // ==========================================================
                        // ITEM NAME
                        // ==========================================================
                        final name = item['name']?.toString() ?? '';

                        // ==========================================================
                        // QUANTITY
                        // ==========================================================
                        final qty =
                            item['qty'] ??
                                item['quantity'] ??
                                1;

                        // ==========================================================
                        // VEG / NON-VEG
                        // ==========================================================
                        final dynamic vegValue =
                            item['is_veg'] ??
                                item['isVeg'] ??
                                item['is_vegetarian'] ??
                                item['veg'];

                        final bool isVeg =
                            vegValue == true ||
                                vegValue == 1 ||
                                vegValue?.toString().trim().toLowerCase() == 'true' ||
                                vegValue?.toString().trim() == '1';

                        // ==========================================================
                        // MODIFIERS
                        // ==========================================================
                        final List<String> modifiers =
                        item['modifiers'] is List
                            ? (item['modifiers'] as List)
                            .map((e) {
                          if (e is Map) {
                            return e['name']?.toString() ??
                                e['modifier_name']?.toString() ??
                                '';
                          }

                          return e.toString();
                        })
                            .where((e) => e.isNotEmpty)
                            .toList()
                            : [];

                        // ==========================================================
                        // ADD-ONS
                        // ==========================================================
                        final dynamic rawAddOns =
                            item['addOns'] ??
                                item['addons'] ??
                                item['add_ons'];

                        final Map<String, dynamic> addOns =
                        rawAddOns is Map
                            ? Map<String, dynamic>.from(rawAddOns)
                            : {};

                        // ==========================================================
                        // NOTE
                        // ==========================================================
                        final String note =
                            item['note']?.toString() ??
                                item['notes']?.toString() ??
                                '';

                        // ==========================================================
                        // DEBUG
                        // ==========================================================
                        debugPrint('========== KDS ITEM ==========');
                        debugPrint('NAME      : $name');
                        debugPrint('IS VEG    : $vegValue');
                        debugPrint('MODIFIERS : $modifiers');
                        debugPrint('ADDONS    : $addOns');
                        debugPrint('NOTE      : $note');
                        debugPrint('==============================');

                        // ==========================================================
                        // SWITCH VALUE
                        // ==========================================================
                        final currentValue =
                        index < switchValues.length
                            ? switchValues[index]
                            : false;

// HIDE TOGGLE-ON ITEM WHEN CANCEL MODE IS ACTIVE
// ==========================================================
                      if (isCancelMode && currentValue) {
                      return const SizedBox.shrink();
                      }

                        return InkWell(
                            onTap: isCancelMode && !isCancelled
                                ? () {
                              setState(() {
                                if (index < cancelSelections.length) {
                                  cancelSelections[index] =
                                  !cancelSelections[index];
                                }
                              });
                            }
                                : null,
                            child: Container(
                              color: isSelectedForCancel
                                  ? const Color(0x14F04438)
                                  : Colors.transparent,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),

                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    // ====================================================
                                    // VEG / NON-VEG ICON
                                    // ====================================================
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: vegNonVegIcon(isVeg),
                                    ),

                                    const SizedBox(width: 10),

                                    // ====================================================
                                    // ITEM DETAILS
                                    // ====================================================
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                        children: [

                                          // ==================================================
                                          // ITEM NAME + QUANTITY
                                          // ==================================================
                                          Row(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.center,

                                            children: [

                                              // ITEM NAME
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  maxLines: 1,
                                                  overflow:
                                                  TextOverflow.ellipsis,

                                                  style:
                                                  GoogleFonts.montserrat(
                                                    fontSize: 14,
                                                    height: 1.0,
                                                    fontWeight:
                                                    FontWeight.w500,
                                                    color: isCancelled
                                                        ? const Color(0xff98A2B3)
                                                        : const Color(0xff475467),
                                                    decoration: isCancelled
                                                        ? TextDecoration.lineThrough
                                                        : TextDecoration.none,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // QUANTITY
                                              SizedBox(
                                                width: 22,
                                                height: 22,

                                                child: Container(
                                                  alignment:
                                                  Alignment.center,

                                                  decoration:
                                                  const BoxDecoration(
                                                    color:
                                                    Color(0xffF2F4F7),
                                                    shape:
                                                    BoxShape.circle,
                                                  ),

                                                  child: Text(
                                                    '$qty',
                                                    textAlign:
                                                    TextAlign.center,

                                                    style:
                                                    GoogleFonts.montserrat(
                                                      fontSize: 11,
                                                      height: 1.0,
                                                      fontWeight:
                                                      FontWeight.w700,
                                                      color: isCancelled
                                                          ? const Color(0xff98A2B3)
                                                          : const Color(0xff667085),
                                                      decoration: isCancelled
                                                          ? TextDecoration.lineThrough
                                                          : TextDecoration.none,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // ==================================================
                                          // MODIFIERS
                                          // ==================================================
                                          if (modifiers.isNotEmpty)
                                            Padding(
                                              padding:
                                              const EdgeInsets.only(
                                                top: 4,
                                              ),

                                              child: Text(
                                                'Modifier: ${modifiers.join(', ')}',

                                                maxLines: 2,
                                                overflow:
                                                TextOverflow.ellipsis,

                                                style:
                                                GoogleFonts.montserrat(
                                                  fontSize: 10,
                                                  height: 1.2,
                                                  fontWeight:
                                                  FontWeight.w500,
                                                  color: isCancelled
                                                      ? const Color(0xff98A2B3)
                                                      : const Color(0xffF04438),
                                                  decoration: isCancelled
                                                      ? TextDecoration.lineThrough
                                                      : TextDecoration.none,
                                                ),
                                              ),
                                            ),

                                          // ==================================================
                                          // ADD-ONS
                                          // ==================================================
                                          if (addOns.isNotEmpty)
                                            Padding(
                                              padding:
                                              const EdgeInsets.only(
                                                top: 2,
                                              ),

                                              child: Text(
                                                'Add-on: ${formatAddOns(addOns)}',

                                                maxLines: 2,
                                                overflow:
                                                TextOverflow.ellipsis,

                                                style:
                                                GoogleFonts.montserrat(
                                                  fontSize: 10,
                                                  height: 1.2,
                                                  fontWeight:
                                                  FontWeight.w500,
                                                  color: isCancelled
                                                      ? const Color(0xff98A2B3)
                                                      : const Color(0xff667085),
                                                  decoration: isCancelled
                                                      ? TextDecoration.lineThrough
                                                      : TextDecoration.none,
                                                ),
                                              ),
                                            ),

                                          // ==================================================
                                          // NOTE
                                          // ==================================================
                                          // if (note.trim().isNotEmpty)
                                          //   Padding(
                                          //     padding:
                                          //     const EdgeInsets.only(
                                          //       top: 2,
                                          //     ),
                                          //
                                          //     child: Text(
                                          //       'Note: $note',
                                          //
                                          //       maxLines: 2,
                                          //       overflow:
                                          //       TextOverflow.ellipsis,
                                          //
                                          //       style:
                                          //       GoogleFonts.montserrat(
                                          //         fontSize: 10,
                                          //         height: 1.2,
                                          //         fontWeight:
                                          //         FontWeight.w600,
                                          //         color: isCancelled
                                          //             ? const Color(0xff98A2B3)
                                          //             : const Color(0xffF04438),
                                          //         decoration: isCancelled
                                          //             ? TextDecoration.lineThrough
                                          //             : TextDecoration.none,
                                          //       ),
                                          //     ),
                                          //   ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 18),


                                    // ====================================================
                                    // CANCEL CHECKBOX - only visible in Cancel mode
                                    // ====================================================
                                    if (isCancelMode)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(
                                          isSelectedForCancel
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: 18,
                                          color: isSelectedForCancel
                                              ? const Color(0xffF04438)
                                              : const Color(0xff98A2B3),
                                        ),
                                      ),

                                    if (isCancelMode) const SizedBox(width: 4),

                                    // ====================================================
                                    // TOGGLE - EXISTING READY/RUNNING FUNCTIONALITY
                                    // ====================================================
                                    if (!isCancelMode)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: _buildCompactItemToggle(
                                          value: currentValue,
                        activeColor: const Color(0xff3B923F),
                                          onChanged: isCancelled
                                              ? (_) {}
                                              : (value) async {
                                            // ==========================================================
                                            // 1. UPDATE LOCAL TOGGLE
                                            // ==========================================================
                                            setState(() {
                                              final values = _getKotSwitchValues(
                                                switchKey,
                                                items,
                                              );

                                              while (values.length < items.length) {
                                                values.add(false);
                                              }

                                              values[index] = value;

                                              selectedItemsMap[switchKey] = values;
                                            });

                                            // If toggle is turned OFF, don't call backend
                                            if (!value) {
                                              return;
                                            }

                                            // ==========================================================
                                            // 2. GET CURRENT ITEM
                                            // ==========================================================
                                            final item = items[index];

                                            final dynamic rawItemId =
                                                item['id'] ??
                                                    item['lineItemId'] ??
                                                    item['line_item_id'];

                                            final itemId = int.tryParse(
                                              rawItemId?.toString() ?? '',
                                            );

                                            if (itemId == null) {
                                              debugPrint(
                                                '❌ Item ID not found: $item',
                                              );
                                              return;
                                            }

                                            // ==========================================================
                                            // 3. GET ORDER INFORMATION
                                            // ==========================================================
                                            final parentId = int.tryParse(
                                              (order['parentOrderId'] ??
                                                  order['parent_order_id'] ??
                                                  '0')
                                                  .toString(),
                                            );

                                            final orderId = int.tryParse(
                                              (order['kotId'] ??
                                                  order['kot_id'] ??
                                                  order['orderId'] ??
                                                  order['order_id'] ??
                                                  '')
                                                  .toString(),
                                            );

                                            final zoneId = int.tryParse(
                                              (order['zoneId'] ??
                                                  order['zone_id'] ??
                                                  '0')
                                                  .toString(),
                                            ) ?? 0;

                                            final restaurantId = int.tryParse(
                                              widget.restaurantId.toString(),
                                            );

                                            if (parentId == null ||
                                                orderId == null ||
                                                restaurantId == null) {
                                              debugPrint(
                                                '❌ Missing order information: parentId=$parentId orderId=$orderId restaurantId=$restaurantId',
                                              );
                                              return;
                                            }

                                            // ==========================================================
                                            // 4. UPDATE INDIVIDUAL ITEM IN BACKEND
                                            // ==========================================================
                                            final success =
                                            await context
                                                .read<OrderProvider>()
                                                .updateKotItemStatus(
                                              token: widget.token,
                                              parentId: parentId,
                                              orderId: orderId,
                                              restaurantId: restaurantId,
                                              zoneId: zoneId,
                                              items: [itemId],
                                            );

                                            // ==========================================================
                                            // 5. IF ITEM UPDATE FAILED -> ROLLBACK TOGGLE
                                            // ==========================================================
                                            if (!success) {
                                              if (!mounted) return;

                                              setState(() {
                                                final values = _getKotSwitchValues(
                                                  switchKey,
                                                  items,
                                                );

                                                if (index < values.length) {
                                                  values[index] = false;
                                                }

                                                selectedItemsMap[switchKey] = values;
                                              });

                                              return;
                                            }

                                            // ==========================================================
                                            // 6. CHECK WHETHER ALL ITEMS ARE NOW COMPLETED
                                            // ==========================================================
                                            final values = _getKotSwitchValues(
                                              switchKey,
                                              items,
                                            );

                                            bool allItemsReady = items.isNotEmpty;
                                            for (int i = 0; i < items.length; i++) {
                                              final rawItem = items[i];
                                              final isCancelled = itemStatusIsCancelled(rawItem);
                                              final isToggled = i < values.length && values[i] == true;
                                              if (!isCancelled && !isToggled) {
                                                allItemsReady = false;
                                                break;
                                              }
                                            }

                                            debugPrint(
                                              '========== ITEM STATUS CHECK ==========',
                                            );
                                            debugPrint(
                                              'KOT: ${order['kot_number'] ?? order['id']}',
                                            );
                                            debugPrint(
                                              'Clicked Item ID: $itemId',
                                            );
                                            debugPrint(
                                              'Switch Values: $values',
                                            );
                                            debugPrint(
                                              'Total Items: ${items.length}',
                                            );
                                            debugPrint(
                                              'All Items Ready: $allItemsReady',
                                            );
                                            debugPrint(
                                              '=======================================',
                                            );

                                            // ==========================================================
                                            // 7. LAST ITEM COMPLETED
                                            // ==========================================================
                                            if (allItemsReady) {
                                              debugPrint(
                                                '✅ LAST ITEM COMPLETED -> SERVING KOT',
                                              );

                                              await provider.updateOrderStatus(
                                                kotId,
                                                'Served',
                                              );

                                              if (mounted) {
                                                setState(() {});
                                              }
                                            }
                                            else {
                                              debugPrint(
                                                '⏳ Some items are still preparing',
                                              );

                                              debugPrint(
                                                '➡️ KOT remains PREPARING',
                                              );
                                            }
                                          },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =============================================================
          // ITEM CANCEL CONFIRMATION
          // Existing KOT UI is unchanged when not in Cancel mode.
          // =============================================================
          if (isCancelMode && selectedCancelCount > 0 && !allItemsSelectedForCancel)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: SizedBox(
                width: double.infinity,
                height: 28,
                child: ElevatedButton(
                  onPressed: () async {
                    final selectedForApi = <Map<String, dynamic>>[];

                    for (final index in cancellableIndexes) {
                      if (index < cancelSelections.length &&
                          cancelSelections[index] &&
                          items[index] is Map) {
                        final selectedItem =
                        Map<String, dynamic>.from(items[index] as Map);

                        // cancelItems() uses lineItemId. Some KOT payloads
                        // provide the same value as id/line_item_id.
                        selectedItem['lineItemId'] ??=
                            selectedItem['line_item_id'] ??
                                selectedItem['id'];

                        selectedForApi.add(selectedItem);
                      }
                    }

                    if (selectedForApi.isEmpty) return;

                    final success = await provider.cancelItems(
                      kotId,
                      selectedForApi,
                    );

                    if (success && mounted) {
                      setState(() {
                        // Keep the cancelled items struck through immediately.
                        for (final index in cancellableIndexes) {
                          if (index < cancelSelections.length &&
                              cancelSelections[index] &&
                              index < items.length) {
                            locallyCancelledItemKeys.add(
                              _getCancelItemKey(items[index], index),
                            );
                          }
                        }

                        _clearCancelSelection(switchKey);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFA3633),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Confirm Item Cancel',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

          // =============================================================
          // 4. FOOTER — existing status flow preserved
          // =============================================================
          Container(
            height: 49,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xffEAECF0),
                  width: .7,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 28,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (isCancelMode) {
                            for (int i = 0; i < cancelSelections.length; i++) {
                              cancelSelections[i] = false;
                            }
                            _clearCancelSelection(switchKey);
                          } else {
                            if (selectedCancelItemKotId != null &&
                                selectedCancelItemKotId != switchKey) {
                              _clearCancelSelection(selectedCancelItemKotId!);
                            }

                            selectedCancelItemKotId = switchKey;

                            for (int i = 0; i < cancelSelections.length; i++) {
                              cancelSelections[i] = false;
                            }
                          }
                        });
                      },
                      icon: Icon(
                        isCancelMode
                            ? Icons.undo
                            : Icons.cancel_outlined,
                        size: 14,
                      ),
                      label: Text(
                        isCancelMode ? 'Undo' : 'Cancel',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isCancelMode
                            ? const Color(0xffF04438)
                            : const Color(0xff98A2B3),
                        side: BorderSide(
                          color: isCancelMode
                              ? const Color(0xffF04438)
                              : const Color(0xffD0D5DD),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (kotId.isEmpty) return;

                        if (isCancelMode) {
                          if (allItemsSelectedForCancel) {

                            // ======================================================
                            // CANCEL ENTIRE KOT USING ITEM-LEVEL CANCEL API
                            // ======================================================

                            final itemsToCancel = items
                                .where((item) {
                              if (item is! Map) return false;

                              final status =
                                  item['status']?.toString().toLowerCase() ?? '';

                              return status != 'cancelled' &&
                                  status != 'cancel';
                            })
                                .map<Map<String, dynamic>>(
                                  (item) => Map<String, dynamic>.from(item),
                            )
                                .toList();

                            final success = await provider.cancelItems(
                              kotId,
                              itemsToCancel,
                            );

                            if (success && mounted) {
                              setState(() {
                                _clearCancelSelection(switchKey);
                                selectedItemsMap.remove(switchKey);
                              });
                            }
                          }

                          return;
                        }

                        // ==========================================================
                        // NEW / RUNNING
                        // SERVE ALL ITEMS
                        // ==========================================================

                        if (buttonText == 'New' ||
                            buttonText == 'Running') {

                          // Turn ON all item toggles immediately
                          setState(() {
                            selectedItemsMap[switchKey] =
                            List<bool>.filled(
                              items.length,
                              true,
                            );
                          });

                          // Update complete KOT
                          await provider.updateOrderStatus(
                            kotId,
                            'Served',
                          );

                          if (mounted) {
                            setState(() {});
                          }

                          return;
                        }

                        // ==========================================================
                        // READY
                        // ==========================================================

                        if (buttonText == 'Ready') {
                          await provider.updateOrderStatus(
                            kotId,
                            'served',
                          );
                        }

                        // ==========================================================
                        // SERVED
                        // ==========================================================

                        else if (buttonText == 'Served') {
                          await provider.updateOrderStatus(
                            kotId,
                            'Served',
                          );
                        }

                        if (mounted) {
                          setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCancelMode && allItemsSelectedForCancel
                            ? const Color(0xffFA3633)
                            : buttonColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCancelMode && allItemsSelectedForCancel)
                            const Icon(
                              Icons.cancel_outlined,
                              size: 14,
                              color: Colors.white,
                            )
                          else
                            const SizedBox.shrink(),
                          if (isCancelMode && allItemsSelectedForCancel)
                            const SizedBox(width: 4),
                          Text(
                            isCancelMode && allItemsSelectedForCancel
                                ? 'Cancel KOT'
                                : buttonText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KOT FLOW HELPERS
  // ---------------------------------------------------------------------------
  // Determines whether this KOT belongs to a newly created table/order.
  // We first respect an explicit flag from the backend. If the backend does
  // not provide one, a Pending KOT is treated as a new KOT. Existing KOTs that
  // are already Preparing/Ready/Served continue to show Running/Ready/Served.
  bool _isNewTableKot(Map<String, dynamic> order,
      String normalizedStatus,) {
    final dynamic explicitValue =
        order['isNewTable'] ??
            order['is_new_table'] ??
            order['newTable'] ??
            order['new_table'];

    if (explicitValue != null) {
      if (explicitValue is bool) {
        return explicitValue;
      }

      final value = explicitValue.toString().toLowerCase().trim();
      if (value == 'true' || value == '1' || value == 'yes') {
        return true;
      }
      if (value == 'false' || value == '0' || value == 'no') {
        return false;
      }
    }

    // A freshly printed KOT normally enters KDS as Pending.
    // Once it has moved to Preparing, it is an existing/running KOT.
    return normalizedStatus == 'pending' ||
        normalizedStatus == 'processing';
  }

  // Returns the switch state for each item in a KOT.
  // The state is kept by KOT id so rebuilding the dashboard does not reset
  // switches that the kitchen has already turned on.
  List<bool> _getKotSwitchValues(String switchKey,
      List<dynamic> items,) {
    final existing = selectedItemsMap[switchKey];

    if (existing != null) {
      // Grow the list if a new item was added to the KOT.
      while (existing.length < items.length) {
        existing.add(false);
      }

      // If the API has fewer items than the cached list, keep the cached
      // values for future rebuilds but return only what the current KOT has.
      return existing;
    }

    final values = <bool>[];

    for (final rawItem in items) {
      if (rawItem is Map) {
        final itemStatus =
            rawItem['status']?.toString().toLowerCase() ?? '';

        values.add(
          itemStatus == 'ready' ||
              itemStatus == 'served' ||
              itemStatus == 'completed',
        );
      } else {
        values.add(false);
      }
    }

    selectedItemsMap[switchKey] = values;
    return values;
  }

  DateTime _parseKotTime(dynamic raw) {
    if (raw is DateTime) return raw;

    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;

      try {
        return DateFormat('yyyy-MM-dd hh:mm a').parse(raw);
      } catch (_) {}
    }

    return DateTime.now();
  }

  int _getReadyCount(List<dynamic> items,
      String orderStatus,) {
    final status = orderStatus.toLowerCase();

    if (status == 'ready' ||
        status == 'served' ||
        status == 'completed') {
      return items.length;
    }

    return items.where((raw) {
      if (raw is! Map) return false;

      final itemStatus =
          raw['status']?.toString().toLowerCase() ?? '';

      return itemStatus == 'ready' ||
          itemStatus == 'served' ||
          itemStatus == 'completed';
    }).length;
  }


  // ---------------------------------------------------------------------------
  // COMPACT ITEM TOGGLE
  // Uses an exact 29 x 18 visual size instead of Flutter's default Switch
  // minimum dimensions. This keeps name, quantity and toggle aligned exactly
  // like the reference KDS card.
  // ---------------------------------------------------------------------------
  Widget _buildCompactItemToggle({
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        width: 58,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xff3B923F)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? const Color(0xff3B923F)
                : const Color(0xffD0D5DD),
            width: 1.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          alignment:
          value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value
                  ? Colors.white
                  : const Color(0xff98A2B3),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }


  Widget vegNonVegIcon(bool isVeg) {
    final color = isVeg
        ? const Color(0xFF10B981) // Green
        : const Color(0xFFEF4444); // Red

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildNoActiveKots() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            'No active KOTs',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xff98A2B3),
            ),
          ),
        ],
      ),
    );
  }
}
