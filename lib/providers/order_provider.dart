
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/complete_order_model.dart';
import '../models/kitchen_order.dart';
import '../models/void_kot.dart';
import '../services/api_services.dart';
import '../services/cancel_item_repository.dart';
import '../services/kds_localstorage.dart';
import '../services/kds_mqtt_service.dart';
import '../utils/AppConstant.dart';
import '../utils/kds_logger.dart';

class OrderProvider extends ChangeNotifier {

  Timer? _servedCleanupTimer;
  final Map<String, _OptimisticStatus> _optimisticStatuses = {};

  OrderProvider(this._mqttService, this._apiService) {
    KdsDebugLog.info('OrderProvider created');
    // _init();

    _servedCleanupTimer =
        Timer.periodic(const Duration(seconds: 5), (_) {
          _clearServedOrders();
        });
  }
  Future<void> initialize() async {
    await _init();
  }
  final Set<String> _completedTakeawayOrderIds = {};

  final KdsMqttService _mqttService;
  final OrderApiService _apiService;
  final OrderLocalStorage _storage = OrderLocalStorage();
  final List<KitchenOrder> _orders = [];

  // Product -> category maps are kept in the provider so they are available
  // to BOTH API-loaded KOTs and newly-created MQTT KOTs.
  final Map<String, String> _productCategoryMap = {};
  final Map<String, String> _productCategoryNameMap = {};

  bool _loaded = false;

  Map<String, String> get productCategoryMap =>
      Map.unmodifiable(_productCategoryMap);

  Map<String, String> get productCategoryNameMap =>
      Map.unmodifiable(_productCategoryNameMap);

  bool get isLoaded => _loaded;
  // final Set<int> selectedIndexes = {};

  List<KitchenOrder> get orders => List.unmodifiable(_orders);
  KdsConnectionState get connectionState => _mqttService.state;
  String? get connectionError => _mqttService.lastError;
  String get subscribedTopic => _mqttService.ordersTopic;
  String get brokerHost => _mqttService.brokerHost;
  int get brokerPort => _mqttService.brokerPort;
  int get mqttMessagesReceived => _mqttService.messagesReceived;

  List<Map<String, dynamic>> get pendingOrders => _orders
      .where((o) =>
  o.status == 'Pending' &&
      o.kotStatus.toLowerCase() != 'on hold')
      .map((o) => o.toUiMap())
      .toList();

  List<Map<String, dynamic>> get preparingOrders => _orders
      .where((o) => o.status == 'Preparing')
      .map((o) => o.toUiMap())
      .toList();

  List<Map<String, dynamic>> get readyOrders => _orders
      .where((o) => o.status == 'Ready')
      .map((o) => o.toUiMap())
      .toList();

  List<Map<String, dynamic>> get servedOrders => _orders
      .where((o) {
    if (o.status != 'Served') return false;
    if (o.servedAt == null) return false;
    return DateTime.now().difference(o.servedAt!).inSeconds < 15;
  })
      .map((o) => o.toUiMap())
      .toList();
  Future<void> _init() async {
    final saved = await _storage.loadOrders();

    _orders.clear();
    _orders.addAll(saved);

    await loadExistingOrders();

    _loaded = true;

    notifyListeners();

    _mqttService.messages.listen(_handleMessage);
    _mqttService.connectionState.listen((_) => notifyListeners());
    _mqttService.connect();

    print('Provider notifyListeners called');
  }

  Future<void> _persist() async {
    await _storage.saveOrders(_orders);
  }

  // void _handleMessage(Map<String, dynamic> message) {
  //   if (message['event'] != 'kot_created') return;
  //
  //   try {
  //     // IMPORTANT: MQTT payloads do not contain the category_products
  //     // section that the initial API response contains. Before parsing the
  //     // MQTT KOT, enrich its item maps using the category maps learned from
  //     // the API. This makes a newly-created KOT behave exactly like an
  //     // existing KOT without requiring a KDS restart.
  //     final enrichedMessage = _enrichMqttMessageWithCategories(message);
  //
  //     final order = KitchenOrder.fromMqttPayload(enrichedMessage);
  //
  //     debugPrint(
  //       'MQTT KOT RECEIVED: ${order.id} | '
  //           'items=${order.items.length}',
  //     );
  //
  //     _addOrder(order);
  //
  //     // The POS may need a short moment to persist the newly-created KOT
  //     // before the kitchen-display API can return it. Refresh once after
  //     // MQTT so category_products is applied immediately instead of waiting
  //     // for the dashboard's normal 5-second refresh cycle.
  //     unawaited(_refreshAfterMqtt());
  //   } catch (e, stack) {
  //     KdsDebugLog.error('Failed to parse order: $e\n$stack');
  //   }
  // }

  Future<void> _handleMessage(Map<String, dynamic> message) async {
    final event = message['event']?.toString();

    debugPrint('========== MQTT EVENT ==========');
    debugPrint('EVENT: $event');
    debugPrint('MESSAGE: $message');
    debugPrint('================================');

    // ==========================================================
    // NEW KOT CREATED
    // ==========================================================
    if (event == 'kot_created') {
      try {
        // --------------------------------------------------------
        // Enrich MQTT message with category information
        // --------------------------------------------------------
        final enrichedMessage =
        _enrichMqttMessageWithCategories(message);

        // --------------------------------------------------------
        // Convert MQTT payload to KitchenOrder
        // --------------------------------------------------------
        final order =
        KitchenOrder.fromMqttPayload(enrichedMessage);

        debugPrint(
          '========== KOT CREATED DEBUG ==========',
        );

        debugPrint(
          'KOT ID       : ${order.kotId}',
        );

        debugPrint(
          'KOT NUMBER   : ${order.kotNo}',
        );

        debugPrint(
          'ORDER ID     : ${order.id}',
        );

        debugPrint(
          'PARENT ID    : ${order.parentOrderId}',
        );

        debugPrint(
          'TYPE         : ${order.type}',
        );

        debugPrint(
          'STATUS       : ${order.status}',
        );

        debugPrint(
          'ITEMS        : ${order.items.length}',
        );

        debugPrint(
          '========================================',
        );

        // ========================================================
        // GET ORDER TYPE
        // ========================================================

        final orderType =
        order.type
            .toString()
            .trim()
            .toLowerCase();

        final normalizedOrderType =
        orderType
            .replaceAll('_', '')
            .replaceAll('-', '')
            .replaceAll(' ', '');

        final isTakeaway =
            normalizedOrderType == 'takeaway' ||
                normalizedOrderType == 'takeaways';

        final parentOrderId =
        order.parentOrderId.toString();

        // ========================================================
        // TAKEAWAY CHECK
        // ========================================================

        debugPrint(
          '========== TAKEAWAY CHECK ==========',
        );

        debugPrint(
          'Parent ID       : $parentOrderId',
        );

        debugPrint(
          'Original Type   : ${order.type}',
        );

        debugPrint(
          'Normalized Type : $normalizedOrderType',
        );

        debugPrint(
          'Is Takeaway     : $isTakeaway',
        );

        debugPrint(
          'Completed IDs   : $_completedTakeawayOrderIds',
        );

        debugPrint(
          '====================================',
        );

        // ========================================================
        // IMPORTANT:
        //
        // TAKEAWAY KOT MUST NOT BE DISPLAYED WHEN CHECKOUT
        // BUTTON IS PRESSED.
        //
        // POS creates the KOT before payment.
        //
        // Therefore:
        //
        // kot_created
        //       ↓
        // takeaway
        //       ↓
        // DO NOT ADD TO KDS
        //
        // After payment:
        //
        // takeaway_completed
        //       ↓
        // _handleTakeawayCompleted()
        //       ↓
        // ADD TO KDS
        // ========================================================

        if (isTakeaway) {
          debugPrint(
            '🚫 TAKEAWAY KOT CREATED',
          );

          debugPrint(
            '🚫 NOT ADDING TAKEAWAY KOT TO KDS YET',
          );

          debugPrint(
            'Waiting for takeaway_completed event...',
          );

          debugPrint(
            'KOT ID       : ${order.kotId}',
          );

          debugPrint(
            'KOT NUMBER   : ${order.kotNo}',
          );

          debugPrint(
            'PARENT ID    : ${order.parentOrderId}',
          );

          return;
        }

        // ========================================================
        // DINE-IN / OTHER KOT STATUS NORMALIZATION
        // ========================================================

        final mqttStatus =
        order.status
            .trim()
            .toLowerCase();

        if (mqttStatus == 'created' ||
            mqttStatus == 'new' ||
            mqttStatus == 'yet to prepare' ||
            mqttStatus == 'yet_to_prepare' ||
            mqttStatus == 'pending') {
          order.status = 'Pending';
        }

        // ========================================================
        // ADD DINE-IN / OTHER KOT TO PROVIDER
        // ========================================================

        debugPrint(
          '========== MQTT KOT CREATED ==========',
        );

        debugPrint(
          'KOT ID          : ${order.kotId}',
        );

        debugPrint(
          'KOT NUMBER      : ${order.kotNo}',
        );

        debugPrint(
          'PARENT ORDER ID : ${order.parentOrderId}',
        );

        debugPrint(
          'KOT TYPE        : ${order.type}',
        );

        debugPrint(
          'ORIGINAL STATUS : $mqttStatus',
        );

        debugPrint(
          'FINAL STATUS    : ${order.status}',
        );

        debugPrint(
          'KOT STATUS      : ${order.kotStatus}',
        );

        debugPrint(
          'KOT ITEMS       : ${order.items.length}',
        );

        // --------------------------------------------------------
        // Add normal KOT immediately
        // --------------------------------------------------------

        _addOrder(order);

        debugPrint(
          '✅ KOT ADDED TO PROVIDER',
        );

        debugPrint(
          'TOTAL ORDERS NOW: ${_orders.length}',
        );

        debugPrint(
          'PENDING ORDERS NOW: ${pendingOrders.length}',
        );

        debugPrint(
          '======================================',
        );
      } catch (e, stack) {
        KdsDebugLog.error(
          '❌ Failed to parse created KOT: $e\n$stack',
        );
      }

      return;
    }

    // ==========================================================
    // KOT STATUS UPDATED
    // ==========================================================
    if (event == 'kot_status_updated') {
      debugPrint(
        '========== KOT STATUS UPDATED ==========',
      );

      debugPrint(
        'Parent Order ID: ${message['parent_order_id']}',
      );

      debugPrint(
        'KOT ID: ${message['kot_id']}',
      );

      debugPrint(
        'KOT Number: ${message['kot_number']}',
      );

      debugPrint(
        'Status: ${message['status']}',
      );

      _handleKotStatusUpdate(message);

      return;
    }

    // ==========================================================
    // TAKEAWAY PAYMENT COMPLETED
    // ==========================================================
    if (event == 'takeaway_completed') {
      debugPrint(
        '========== TAKEAWAY PAYMENT COMPLETED ==========',
      );

      debugPrint(
        'Parent Order ID: ${message['parent_order_id']}',
      );

      debugPrint(
        'KOT ID: ${message['kot_id']}',
      );

      debugPrint(
        'KOT Number: ${message['kot_number']}',
      );

      debugPrint(
        'Status: ${message['status']}',
      );

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // _handleTakeawayCompleted() will:
      //
      // 1. Call KDS orders API
      // 2. Find the matching takeaway KOT
      // 3. Convert it to KitchenOrder
      // 4. Set status = Pending
      // 5. Add it to _orders
      //
      // So takeaway appears ONLY after payment.
      // --------------------------------------------------------

      await _handleTakeawayCompleted(message);

      debugPrint(
        '==============================================',
      );

      return;
    }

    // ==========================================================
    // UNKNOWN EVENT
    // ==========================================================

    debugPrint(
      'Ignoring MQTT event: $event',
    );
  }
  Future<void> _handleTakeawayCompleted(
      Map<String, dynamic> message,
      ) async {
    final parentOrderId =
        message['parent_order_id']?.toString() ?? '';

    final kotId =
        message['kot_id']?.toString() ?? '';

    final kotNumber =
        message['kot_number']?.toString() ?? '';

    debugPrint(
      '========== HANDLE TAKEAWAY COMPLETED ==========',
    );

    debugPrint('Parent Order ID: $parentOrderId');
    debugPrint('KOT ID: $kotId');
    debugPrint('KOT Number: $kotNumber');

    if (parentOrderId.isEmpty &&
        kotId.isEmpty &&
        kotNumber.isEmpty) {
      debugPrint('❌ No identifier received');
      return;
    }

    // ----------------------------------------------------------
    // IMPORTANT:
    // Do NOT add this order to completed set here.
    //
    // This event means PAYMENT COMPLETED.
    // We need to SHOW the takeaway KOT in KDS.
    // ----------------------------------------------------------

    try {
      debugPrint(
        '🔄 Fetching KDS orders after takeaway payment...',
      );

      final rawApiOrders =
      await _apiService.getKitchenDisplayOrders();

      final List<Map<String, dynamic>> apiOrders =
      rawApiOrders
          .whereType<Map>()
          .map(
            (order) =>
        Map<String, dynamic>.from(order),
      )
          .toList();

      debugPrint(
        'KDS API ORDERS COUNT: ${apiOrders.length}',
      );

      Map<String, dynamic>? matchingOrder;

      // ----------------------------------------------------------
      // FIND TAKEAWAY KOT
      // ----------------------------------------------------------

      for (final json in apiOrders) {
        final apiKotId =
            json['kot_id']?.toString() ??
                json['id']?.toString() ??
                '';

        final apiKotNumber =
            json['kot_number']?.toString() ?? '';

        final apiParentOrderId =
            json['parent_order_id']?.toString() ??
                json['order_id']?.toString() ??
                '';

        final apiOrderType =
            json['order_type']?.toString().trim().toLowerCase() ?? '';

        final isTakeaway =
            apiOrderType == 'takeaway' ||
                apiOrderType.contains('takeaway');

        debugPrint(
          'Checking API KOT: '
              'kotId=$apiKotId '
              'kotNumber=$apiKotNumber '
              'parentOrderId=$apiParentOrderId '
              'orderType=$apiOrderType '
              'isTakeaway=$isTakeaway',
        );

        if (!isTakeaway) {
          continue;
        }

        final matchesKotId =
            kotId.isNotEmpty && apiKotId == kotId;

        final matchesKotNumber =
            kotNumber.isNotEmpty && apiKotNumber == kotNumber;

        final matchesParentOrder =
            parentOrderId.isNotEmpty &&
                apiParentOrderId == parentOrderId;

        if (matchesKotId ||
            matchesKotNumber ||
            matchesParentOrder) {
          matchingOrder = json;

          debugPrint(
            '✅ MATCHED TAKEAWAY KOT '
                'KOT=$apiKotNumber '
                'KOT_ID=$apiKotId '
                'PARENT=$apiParentOrderId',
          );

          break;
        }
      }

      // ----------------------------------------------------------
      // KOT NOT FOUND
      // ----------------------------------------------------------

      if (matchingOrder == null) {
        debugPrint(
          '❌ Takeaway KOT NOT FOUND in KDS API',
        );

        debugPrint(
          'kotId=$kotId '
              'kotNumber=$kotNumber '
              'parentOrderId=$parentOrderId',
        );

        return;
      }

      debugPrint(
        '✅ TAKEAWAY KOT FOUND IN API',
      );

      debugPrint(
        'TAKEAWAY KOT JSON: $matchingOrder',
      );

      // ----------------------------------------------------------
      // CONVERT API RESPONSE
      // ----------------------------------------------------------

      final order = KitchenOrder.fromJson(
        matchingOrder,
      );

      // ----------------------------------------------------------
      // TAKEAWAY SHOULD ENTER KDS AS PENDING
      // ----------------------------------------------------------

      order.status = 'Pending';

      debugPrint(
        '========== TAKEAWAY KOT ADDING TO KDS ==========',
      );

      debugPrint('KOT ID       : ${order.kotId}');
      debugPrint('KOT NUMBER   : ${order.kotNo}');
      debugPrint('PARENT ID    : ${order.parentOrderId}');
      debugPrint('TYPE         : ${order.type}');
      debugPrint('STATUS       : ${order.status}');
      debugPrint('ITEM COUNT   : ${order.items.length}');

      // ----------------------------------------------------------
      // ADD TO KDS
      // ----------------------------------------------------------

      _addOrder(order);

      debugPrint(
        '✅ TAKEAWAY KOT ADDED TO KDS',
      );

      debugPrint(
        'TOTAL ORDERS: ${_orders.length}',
      );

      debugPrint(
        'PENDING ORDERS: ${pendingOrders.length}',
      );
    } catch (e, stack) {
      KdsDebugLog.error(
        '❌ Failed to load takeaway KOT: $e\n$stack',
      );
      debugPrint(stack.toString());
    }

    debugPrint(
      '==============================================',
    );
  }
  void _handleKotStatusUpdate(Map<String, dynamic> message) {
    final kotId = message['kot_id']?.toString();
    final kotNumber = message['kot_number']?.toString();
    final status = message['status']?.toString();

    debugPrint('========== KOT STATUS UPDATE ==========');
    debugPrint('KOT ID     : $kotId');
    debugPrint('KOT NUMBER : $kotNumber');
    debugPrint('STATUS     : $status');
    debugPrint('=======================================');

    if (status == null || status.isEmpty) {
      return;
    }

    KitchenOrder? order;

    // Find using kot_id first
    if (kotId != null && kotId.isNotEmpty) {
      order = _orders.cast<KitchenOrder?>().firstWhere(
            (o) => o?.kotId?.toString() == kotId,
        orElse: () => null,
      );
    }

    // Fallback to KOT number
    order ??= _orders.cast<KitchenOrder?>().firstWhere(
          (o) => o?.id.toString() == kotNumber,
      orElse: () => null,
    );

    if (order == null) {
      debugPrint(
        'KOT not found in local KDS list. '
            'kotId=$kotId kotNumber=$kotNumber',
      );
      return;
    }

    final normalizedStatus = status.toLowerCase();

    _updateAndSave(() {
      if (normalizedStatus == 'completed' ||
          normalizedStatus == 'served') {
        order!.status = 'Served';
        order.servedAt = DateTime.now();
      } else if (normalizedStatus == 'preparing' ||
          normalizedStatus == 'processing' ||
          normalizedStatus == 'running') {
        order!.status = 'Preparing';
        order.servedAt = null;
      } else if (normalizedStatus == 'ready') {
        order!.status = 'Ready';
        order.servedAt = null;
      } else if (normalizedStatus == 'pending' ||
          normalizedStatus == 'new') {
        order!.status = 'Pending';
        order.servedAt = null;
      }
    });

    debugPrint(
      'KDS LOCAL STATUS UPDATED → '
          '${order.id} = ${order.status}',
    );
  }
  // Future<void> _refreshAfterMqtt() async {
  //   try {
  //     await Future<void>.delayed(
  //       const Duration(milliseconds: 800),
  //     );
  //
  //     await loadExistingOrders();
  //   } catch (e, stack) {
  //     KdsDebugLog.error(
  //       'MQTT refresh failed: $e\n$stack',
  //     );
  //   }
  // }

  Map<String, dynamic> _enrichMqttMessageWithCategories(
      Map<String, dynamic> message) {
    final copy = _deepCopyMap(message);
    _enrichMapRecursively(copy);
    return copy;
  }

  void _enrichMapRecursively(Map<String, dynamic> map) {
    final productId =
        (map['product_id'] ?? map['productId'])
            ?.toString()
            .trim() ??
            '';

    final productName =
        (map['item_name'] ??
            map['itemName'] ??
            map['name'] ??
            map['product_name'])
            ?.toString()
            .trim() ??
            '';

    final looksLikeItem =
        productId.isNotEmpty ||
            (productName.isNotEmpty &&
                (map.containsKey('quantity') ||
                    map.containsKey('qty') ||
                    map.containsKey('lineItemId') ||
                    map.containsKey('line_item_id')));

    if (looksLikeItem) {
      String category = '';

      if (productId.isNotEmpty) {
        category = _productCategoryMap[productId] ?? '';
      }

      if (category.isEmpty && productName.isNotEmpty) {
        category =
            _productCategoryNameMap[
            _normalizeProductName(productName)
            ] ??
                _productCategoryNameMap[productName.toLowerCase()] ??
                '';
      }

      final existingCategory =
          (map['category_name'] ??
              map['categoryName'] ??
              map['category'])
              ?.toString()
              .trim() ??
              '';

      if (category.isEmpty &&
          existingCategory.isNotEmpty &&
          existingCategory.toUpperCase() != 'OTHER') {
        category = existingCategory;
      }

      if (category.isNotEmpty) {
        map['category_name'] = category;
        map['categoryName'] = category;

        // Some existing UI code reads `category` directly.
        if ((map['category']?.toString().trim() ?? '').isEmpty ||
            (map['category']?.toString().trim().toUpperCase() == 'OTHER')) {
          map['category'] = category;
        }

        debugPrint(
          'MQTT CATEGORY: productId=$productId | '
              'name=$productName | category=$category',
        );
      } else {
        debugPrint(
          'MQTT CATEGORY NOT FOUND: productId=$productId | '
              'name=$productName',
        );
      }
    }

    // Recursively walk the entire MQTT payload so this works regardless of
    // whether items are under `items`, `kot_items`, `order`, `data`, etc.
    for (final key in map.keys.toList()) {
      final value = map[key];

      if (value is Map) {
        final nested = Map<String, dynamic>.from(value);
        _enrichMapRecursively(nested);
        map[key] = nested;
      } else if (value is List) {
        final updatedList = <dynamic>[];

        for (final element in value) {
          if (element is Map) {
            final nested = Map<String, dynamic>.from(element);
            _enrichMapRecursively(nested);
            updatedList.add(nested);
          } else if (element is List) {
            updatedList.add(_enrichListRecursively(element));
          } else {
            updatedList.add(element);
          }
        }

        map[key] = updatedList;
      }
    }
  }

  List<dynamic> _enrichListRecursively(List<dynamic> list) {
    return list.map((element) {
      if (element is Map) {
        final nested = Map<String, dynamic>.from(element);
        _enrichMapRecursively(nested);
        return nested;
      }

      if (element is List) {
        return _enrichListRecursively(element);
      }

      return element;
    }).toList();
  }

  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
    final result = <String, dynamic>{};

    for (final entry in source.entries) {
      final value = entry.value;

      if (value is Map) {
        result[entry.key] =
            _deepCopyMap(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[entry.key] = value.map((element) {
          if (element is Map) {
            return _deepCopyMap(
              Map<String, dynamic>.from(element),
            );
          }

          if (element is List) {
            return _deepCopyList(element);
          }

          return element;
        }).toList();
      } else {
        result[entry.key] = value;
      }
    }

    return result;
  }

  List<dynamic> _deepCopyList(List<dynamic> source) {
    return source.map((element) {
      if (element is Map) {
        return _deepCopyMap(
          Map<String, dynamic>.from(element),
        );
      }

      if (element is List) {
        return _deepCopyList(element);
      }

      return element;
    }).toList();
  }

  String _normalizeProductName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[-_()]'), ' ')
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim();
  }

  void _buildCategoryMapsFromApiOrders(
      List<Map<String, dynamic>> apiOrders) {
    _productCategoryMap.clear();
    _productCategoryNameMap.clear();

    for (final order in apiOrders) {
      final rawItems = order['kot_items'] ?? order['items'];

      if (rawItems is! List) continue;

      for (final rawItem in rawItems) {
        if (rawItem is! Map) continue;

        final item = Map<String, dynamic>.from(rawItem);

        final productId =
            (item['product_id'] ?? item['productId'])
                ?.toString()
                .trim() ??
                '';

        final name =
            (item['item_name'] ??
                item['itemName'] ??
                item['name'] ??
                item['product_name'])
                ?.toString()
                .trim() ??
                '';

        final category =
            (item['category_name'] ??
                item['categoryName'] ??
                item['category'])
                ?.toString()
                .trim() ??
                '';

        if (category.isEmpty ||
            category.toUpperCase() == 'OTHER') {
          continue;
        }

        if (productId.isNotEmpty) {
          _productCategoryMap[productId] = category;
        }

        if (name.isNotEmpty) {
          _productCategoryNameMap[
          _normalizeProductName(name)
          ] = category;
          _productCategoryNameMap[
          name.toLowerCase()
          ] = category;
        }
      }
    }

    debugPrint(
      'CATEGORY MAP READY: ${_productCategoryMap.length} product IDs, '
          '${_productCategoryNameMap.length} product names',
    );
  }

  void _addOrder(KitchenOrder order) {
    debugPrint('========== ADD ORDER ==========');
    debugPrint('ID           : ${order.id}');
    debugPrint('KOT ID       : ${order.kotId}');
    debugPrint('KOT NO       : ${order.kotNo}');
    debugPrint('PARENT ID    : ${order.parentOrderId}');
    debugPrint('TYPE         : ${order.type}');
    debugPrint('STATUS       : ${order.status}');
    debugPrint('KOT STATUS   : ${order.kotStatus}');
    debugPrint('ITEM COUNT   : ${order.items.length}');
    debugPrint('===============================');

    final index = _orders.indexWhere(
          (item) =>
      item.id == order.id ||
          (order.kotId != null &&
              item.kotId == order.kotId),
    );

    if (index >= 0) {
      _orders[index] = order;

      debugPrint(
        'UPDATED EXISTING KOT at index=$index',
      );
    } else {
      _orders.insert(0, order);

      debugPrint(
        'INSERTED NEW KOT',
      );
    }

    _persist();

    notifyListeners();

    debugPrint(
      'TOTAL ORDERS AFTER ADD: ${_orders.length}',
    );

    debugPrint('================================');
  }
  KitchenOrder? _findOrder(String orderId) {
    for (final order in _orders) {
      if (order.id == orderId) return order;
    }
    return null;
  }



  void _notifyPos(
      KitchenOrder order,
      String status, {
        bool isCancelled = false,
      }) {
    final posStatus = KotApiStatus.fromLocal(status);

    _mqttService.sendStatusUpdate(
      kotId: order.kotId,
      parentOrderId: order.parentOrderId,
      zoneId: order.zoneId,
      zoneName: order.zoneName,
      orderType: order.type,
      tableName: order.tableName,
      kotNumber: order.id,
      status: posStatus,
      isCancelled: isCancelled,

      // ✅ Add this
      remainingItems: order.items.map((item) => item.toJson()).toList(),
    );

    KdsDebugLog.info(
      'POS notified: ${order.id} → $posStatus',
    );
  }
  void _clearServedOrders() {
    final beforeCount = _orders.length;
    _orders.removeWhere((o) {
      if (o.status.toLowerCase() == 'served') {
        if (o.servedAt == null) return true;
        return DateTime.now().difference(o.servedAt!).inSeconds >= 15;
      }
      return false;
    });
    if (_orders.length != beforeCount) {
      _persist();
      notifyListeners();
    }
  }

  void _updateAndSave(void Function() update) {
    update();
    _persist();
    notifyListeners();
  }
  // Future<bool> recallCompletedOrder({
  //   required int restaurantId,
  //   required int zoneId,
  //   required int parentOrderId,
  // }) async {
  //   try {
  //     await _apiService.updateCompletedOrderStatus(
  //       restaurantId: restaurantId,
  //       zoneId: zoneId,
  //       parentOrderId: parentOrderId,
  //       status: "preparing",
  //     );
  //
  //     return true;
  //   } catch (e) {
  //     KdsDebugLog.error("Recall failed: $e");
  //     return false;
  //   }
  // }

  Future<bool> startOrder(
      String orderId,
      List<Map<String, dynamic>> remainingItems,
      ) async {
    final order = _findOrder(orderId);
    if (order == null) return false;

    try {

      _updateAndSave(() {
        print("========== START ORDER ==========");

        // Set checked (cancelled) items status to 'cancelled'
        for (final item in order.items) {
          final isRemaining = remainingItems.any(
                (r) => r['name'] == item.name,
          );
          if (!isRemaining) {
            item.status = 'cancelled';
          }
        }

        order.status = 'Preparing';
        order.servedAt = null;
        _optimisticStatuses[orderId] = _OptimisticStatus('Preparing', DateTime.now());
        order.isCancelled = false;

        _notifyPos(order, 'Preparing');
      });
      // Get token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

// Find cancelled line item IDs from existing order items
      final cancelledItemIds = order.items
          .where((item) =>
      !remainingItems.any((e) => e['name'] == item.name))
          .map((item) => item.lineItemId)
          .whereType<int>() // removes null values
          .toList();

// Call cancel item API only if there are cancelled items
      if (cancelledItemIds.isNotEmpty) {
        await CancelItemRepository().updateCancelItemStatus(
          token: token,
          parentId: order.parentOrderId!,
          orderId: order.kotId!,
          restaurantId: 1,
          orderType: order.type,
          zoneId: order.zoneId,
          itemIds: cancelledItemIds,
        );
      }

// Update KOT status
      await _apiService.startOrder(order);

      print("Start API Success");

      return true;
    } catch (e, stack) {
      KdsDebugLog.error('startOrder failed: $e\n$stack');
      return false;
    }
  }
  Future<bool> cancelOrder(String orderId) async {
    final order = _findOrder(orderId);
    if (order == null) return false;

    try {
      await _apiService.cancelOrder(order);

      _updateAndSave(() {
        // Remove from master list
        _orders.removeWhere(
              (o) => o.id.toString() == orderId,
        );

        _optimisticStatuses[orderId] = _OptimisticStatus('Cancelled', DateTime.now());

        // The master _orders list is the source of truth.
        // pendingOrders/preparingOrders/readyOrders are derived getters,
        // so there is no separate list to mutate here.

        _notifyPos(
          order,
          'Cancelled',
          isCancelled: true,
        );
      });

      notifyListeners();

      return true;
    } catch (e, stack) {
      print('cancelOrder error: $e');
      print(stack);
      return false;
    }
  }
  Future<bool> cancelItems(
      String orderId,
      List<Map<String, dynamic>> selectedItems,
      ) async {
    final order = _findOrder(orderId);

    if (order == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Get selected line item ids
      final selectedItemIds = selectedItems
          .map((item) {
        final rawId = item['lineItemId'] ??
            item['line_item_id'] ??
            item['id'];

        if (rawId is int) return rawId;
        return int.tryParse(rawId?.toString() ?? '');
      })
          .whereType<int>()
          .toList();

      debugPrint("Selected Item IDs: $selectedItemIds");

      // Call backend
      if (selectedItemIds.isNotEmpty) {
        await CancelItemRepository().updateCancelItemStatus(
          token: token,
          parentId: order.parentOrderId!,
          orderId: order.kotId!,
          restaurantId: 1,
          orderType: order.type,
          zoneId: order.zoneId,
          itemIds: selectedItemIds,
        );
      }

      _updateAndSave(() {
        for (final item in order.items) {
          final itemId = int.tryParse(
            item.lineItemId?.toString() ?? '',
          );

          debugPrint(
            'Item: ${item.name}, '
                'lineItemId: ${item.lineItemId}, '
                'status before: ${item.status}',
          );

          if (itemId != null && selectedItemIds.contains(itemId)) {
            item.status = 'cancelled';

            debugPrint(
              'Item ${item.name} marked as CANCELLED',
            );
          }
        }
      });

      _mqttService.sendStatusUpdate(
        kotId: order.kotId,
        parentOrderId: order.parentOrderId,
        zoneId: order.zoneId,
        zoneName: order.zoneName,
        orderType: order.type,
        tableName: order.tableName,
        kotNumber: order.id,
        status: KotApiStatus.fromLocal(order.status),
        cancelledItems: selectedItems,
        remainingItems: order.items.map((item) => item.toJson()).toList(),
      );

      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint("cancelItems failed: $e");
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }
  Future<bool> recallOrder(String orderId) async {
    print("Recall called with: $orderId");

    final order = _findOrder(orderId);

    print("Found order: ${order?.id}");

    if (order == null) {
      print("Order not found");
      return false;
    }

    try {
      print("Calling updateOrderStatus API...");
      await _apiService.updateOrderStatus(order, "preparing");
      // Reload orders from API
      await loadExistingOrders();

      notifyListeners();

      _updateAndSave(() {
        order.isCancelled = false;
        order.status = "Preparing"; // UI value
        order.servedAt = null;
        _optimisticStatuses[orderId] = _OptimisticStatus('Preparing', DateTime.now());
        _notifyPos(order, "Preparing");
      });

      return true;
    } catch (e, stack) {
      KdsDebugLog.error("recallOrder failed: $e\n$stack");
      return false;
    }
  }

  Future<bool> recallOrderFromHistory({
    required CompletedOrderModel order,
    required String token,
  }) async {
    try {
      final orderIdStr = order.kotOrderId.toString();

      // Optimistically update existing order or add temporary representation in memory
      final existingIndex = _orders.indexWhere(
            (o) => o.kotId == order.kotOrderId || o.id == orderIdStr,
      );

      if (existingIndex != -1) {
        _orders[existingIndex].status = 'Preparing';
        _orders[existingIndex].servedAt = null;
        _orders[existingIndex].isCancelled = false;
        _optimisticStatuses[orderIdStr] =
            _OptimisticStatus('Preparing', DateTime.now());
      } else {
        final tempOrder = KitchenOrder(
          id: orderIdStr,
          kotId: order.kotOrderId,
          parentOrderId: order.orderId,
          zoneId: order.zoneId,
          type: order.orderType,
          tableName: order.tableName,
          status: 'Preparing',
          kotTime: order.kotDateTime ?? DateTime.now(),
          items: [],
          kotStatus: 'preparing',
        );
        _orders.add(tempOrder);
        _optimisticStatuses[orderIdStr] =
            _OptimisticStatus('Preparing', DateTime.now());
      }
      notifyListeners();

      // Send status update request to backend API
      await _apiService.updateKotOrderStatus(
        orderId: order.kotOrderId,
        parentId: order.orderId,
        zoneId: order.zoneId,
        restaurantId: order.restaurantId,
        status: "preparing",
      );

      // Reload full order details asynchronously without blocking UI navigation
      unawaited(loadExistingOrders());

      return true;
    } catch (e, stack) {
      KdsDebugLog.error("recallOrderFromHistory failed: $e\n$stack");
      unawaited(loadExistingOrders());
      return false;
    }
  }

  Future<void> loadExistingOrders() async {
    try {
      final rawApiOrders =
      await _apiService.getKitchenDisplayOrders();

      final List<Map<String, dynamic>> apiOrders =
      rawApiOrders
          .whereType<Map>()
          .map(
            (order) => Map<String, dynamic>.from(order),
      )
          .toList();

      debugPrint(
        'KDS API ORDERS COUNT: ${apiOrders.length}',
      );

      // ----------------------------------------------------------
      // BUILD CATEGORY MAPS
      // ----------------------------------------------------------

      _buildCategoryMapsFromApiOrders(apiOrders);

      // ----------------------------------------------------------
      // KEEP CURRENT LOCAL ORDERS
      // ----------------------------------------------------------

      final localOrders = List<KitchenOrder>.from(_orders);

      final List<KitchenOrder> loadedOrders = [];

      // ----------------------------------------------------------
      // PARSE API ORDERS
      // ----------------------------------------------------------

      for (final json in apiOrders) {
        try {
          final order = KitchenOrder.fromJson(
            Map<String, dynamic>.from(json),
          );

          loadedOrders.add(order);
        } catch (e, stack) {
          KdsDebugLog.error(
            'Failed to parse order JSON: $e\n$stack',
          );
        }
      }

      // ----------------------------------------------------------
      // MERGE API + LOCAL ITEM STATUS
      // ----------------------------------------------------------

      final Map<String, KitchenOrder> mergedOrders = {};

      for (final apiOrder in loadedOrders) {
        // Find same KOT locally
        final localOrderIndex = localOrders.indexWhere(
              (localOrder) =>
          localOrder.id == apiOrder.id ||
              (localOrder.kotId != null &&
                  apiOrder.kotId != null &&
                  localOrder.kotId == apiOrder.kotId),
        );

        if (localOrderIndex != -1) {
          final localOrder = localOrders[localOrderIndex];

          // ------------------------------------------------------
          // PRESERVE CANCELLED ITEM STATUS
          // ------------------------------------------------------

          for (final apiItem in apiOrder.items) {
            final localItemIndex = localOrder.items.indexWhere(
                  (localItem) =>
              localItem.lineItemId != null &&
                  apiItem.lineItemId != null &&
                  localItem.lineItemId ==
                      apiItem.lineItemId,
            );

            if (localItemIndex != -1) {
              final localItem =
              localOrder.items[localItemIndex];

              final localStatus =
              localItem.status
                  .toString()
                  .trim()
                  .toLowerCase();

              if (localStatus == 'cancelled') {
                apiItem.status = 'cancelled';

                debugPrint(
                  '🔴 PRESERVED CANCELLED ITEM: '
                      '${apiItem.name} '
                      'lineItemId=${apiItem.lineItemId}',
                );
              }
            }
          }
        }

        // Add API order after merging local item status
        mergedOrders[apiOrder.id] = apiOrder;
      }

      // ----------------------------------------------------------
      // PRESERVE LOCAL ORDERS NOT RETURNED BY API
      // ----------------------------------------------------------

      for (final localOrder in localOrders) {
        final status =
        localOrder.status.trim().toLowerCase();

        final shouldKeep =
            status == 'served' ||
                status == 'pending' ||
                status == 'preparing' ||
                status == 'ready';

        if (shouldKeep &&
            !mergedOrders.containsKey(localOrder.id)) {
          mergedOrders[localOrder.id] = localOrder;

          debugPrint(
            'Preserving local KOT: '
                'id=${localOrder.id}, '
                'type=${localOrder.type}, '
                'status=${localOrder.status}',
          );
        }
      }

      // ----------------------------------------------------------
      // UPDATE MASTER LIST
      // ----------------------------------------------------------

      _orders
        ..clear()
        ..addAll(mergedOrders.values);

      // ----------------------------------------------------------
      // SAVE
      // ----------------------------------------------------------

      await _persist();

      notifyListeners();

      debugPrint(
        'KDS ORDERS LOADED: ${_orders.length}',
      );

      // Debug cancelled items
      for (final order in _orders) {
        for (final item in order.items) {
          if (item.status
              .toString()
              .trim()
              .toLowerCase() ==
              'cancelled') {
            debugPrint(
              '🔴 CANCELLED ITEM STILL PRESENT: '
                  'KOT=${order.id}, '
                  'ITEM=${item.name}, '
                  'ID=${item.lineItemId}',
            );
          }
        }
      }
    } catch (e, stack) {
      KdsDebugLog.error(
        'loadExistingOrders failed: $e\n$stack',
      );
    }
  }

  Future<bool> updateAllKotItemStatus(String orderId) async {
    final order = _findOrder(orderId);

    if (order == null) {
      KdsDebugLog.error('Order not found: $orderId');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Get all item IDs
      final itemIds = order.items
          .map((item) => item.lineItemId)
          .whereType<int>()
          .toList();

      debugPrint('========== UPDATE ALL KOT ITEMS ==========');
      debugPrint('Parent ID: ${order.parentOrderId}');
      debugPrint('Order ID: ${order.kotId}');
      debugPrint('Restaurant ID: 1');
      debugPrint('Zone ID: ${order.zoneId}');
      debugPrint('Item IDs: $itemIds');

      if (itemIds.isEmpty) {
        KdsDebugLog.error(
          'No line item IDs found for KOT ${order.id}',
        );
        return false;
      }

      await CancelItemRepository().updateCancelItemStatus(
        token: token,
        parentId: order.parentOrderId!,
        orderId: order.kotId!,
        restaurantId: 1,
        orderType: order.type,
        zoneId: order.zoneId,
        itemIds: itemIds,
      );

      debugPrint('All KOT items API success');

      return true;
    } catch (e, stack) {
      KdsDebugLog.error(
        'updateAllKotItemStatus failed: $e\n$stack',
      );

      return false;
    }
  }


  Future<bool> updateKotItemStatus({
    required String token,
    required int parentId,
    required int orderId,
    required int restaurantId,
    required int zoneId,
    required List<int> items,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseDomain}'
            '/wp-json/pinaka-restaurant-pos/v1/kot/update-kot-item-status',
      );

      debugPrint('========== UPDATE KOT ITEM STATUS ==========');
      debugPrint('Parent ID: $parentId');
      debugPrint('Order ID: $orderId');
      debugPrint('Restaurant ID: $restaurantId');
      debugPrint('Zone ID: $zoneId');
      debugPrint('Items: $items');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'parent_id': parentId,
          'order_id': orderId,
          'restaurant_id': restaurantId,
          'zone_id': zoneId,
          'items': items,
        }),
      );

      debugPrint(
        'UPDATE ITEM STATUS RESPONSE: ${response.statusCode}',
      );

      debugPrint(
        'UPDATE ITEM STATUS BODY: ${response.body}',
      );

      // ==========================================================
      // API FAILED
      // ==========================================================

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        debugPrint(
          '❌ Update item status API failed',
        );

        return false;
      }

      debugPrint(
        '✅ Update item status API success',
      );

      // ==========================================================
      // FIND KOT
      // ==========================================================

      final orderIndex = _orders.indexWhere(
            (order) =>
        order.parentOrderId == parentId &&
            order.kotId == orderId,
      );

      if (orderIndex == -1) {
        debugPrint(
          '⚠️ Local KOT not found '
              'parentId=$parentId orderId=$orderId',
        );

        return true;
      }

      final order = _orders[orderIndex];

      // ==========================================================
      // SAVE COMPLETED ITEMS BEFORE REMOVING THEM
      // ==========================================================

      final completedItems = order.items
          .where(
            (item) =>
        item.lineItemId != null &&
            items.contains(item.lineItemId),
      )
          .map((item) => item.toJson())
          .toList();

      debugPrint(
        'Completed items: $completedItems',
      );

      // ==========================================================
      // MARK SELECTED ITEMS COMPLETED
      // ==========================================================

      for (final item in order.items) {
        final lineItemId = item.lineItemId;

        if (lineItemId != null &&
            items.contains(lineItemId)) {
          item.status = 'completed';

          debugPrint(
            '✅ Item completed → '
                '${item.name} '
                'lineItemId=$lineItemId',
          );
        }
      }

      // ==========================================================
      // REMOVE COMPLETED ITEMS
      // ==========================================================

      order.items.removeWhere(
            (item) =>
        item.lineItemId != null &&
            items.contains(item.lineItemId),
      );

      debugPrint(
        'Remaining items in KOT: ${order.items.length}',
      );

      // ==========================================================
      // LAST ITEM COMPLETED
      // ==========================================================

      if (order.items.isEmpty) {
        debugPrint(
          '============================================',
        );

        debugPrint(
          '✅ ALL ITEMS COMPLETED',
        );

        debugPrint(
          '➡️ Updating KOT status → SERVED',
        );

        // --------------------------------------------------------
        // LOCAL STATUS
        // --------------------------------------------------------

        order.status = 'Served';
        order.servedAt = DateTime.now();

        _optimisticStatuses[order.id] =
            _OptimisticStatus(
              'Served',
              DateTime.now(),
            );

        // --------------------------------------------------------
        // BACKEND STATUS UPDATE
        // --------------------------------------------------------

        try {
          await _apiService.updateOrderStatus(
            order,
            'served',
          );

          debugPrint(
            '✅ BACKEND KOT STATUS = SERVED',
          );
        } catch (e, stack) {
          debugPrint(
            '❌ Failed to update KOT status to SERVED: $e',
          );

          debugPrintStack(
            stackTrace: stack,
          );

          return false;
        }

        // --------------------------------------------------------
        // POS UPDATE
        // --------------------------------------------------------

        _notifyPos(
          order,
          'Served',
        );

        debugPrint(
          '✅ POS SHOULD NOW SHOW SERVED',
        );

        // --------------------------------------------------------
        // REMOVE FROM ACTIVE KDS
        // --------------------------------------------------------

        _orders.removeAt(orderIndex);

        debugPrint(
          '✅ KOT removed from active KDS',
        );

        await _persist();

        notifyListeners();

        debugPrint(
          '============================================',
        );

        return true;
      }

      // ==========================================================
      // SOME ITEMS STILL REMAIN
      // ==========================================================

      debugPrint(
        '⏳ Some items are still preparing',
      );

      debugPrint(
        '➡️ KOT remains PREPARING',
      );

      order.status = 'Preparing';
      order.servedAt = null;

      _optimisticStatuses[order.id] =
          _OptimisticStatus(
            'Preparing',
            DateTime.now(),
          );

      // ----------------------------------------------------------
      // UPDATE BACKEND
      // ----------------------------------------------------------

      try {
        await _apiService.updateOrderStatus(
          order,
          'preparing',
        );

        debugPrint(
          '✅ BACKEND KOT STATUS = PREPARING',
        );
      } catch (e, stack) {
        debugPrint(
          '❌ Failed to update KOT status to PREPARING: $e',
        );

        debugPrintStack(
          stackTrace: stack,
        );

        return false;
      }

      // ----------------------------------------------------------
      // NOTIFY POS
      // ----------------------------------------------------------

      _notifyPos(
        order,
        'Preparing',
      );

      debugPrint(
        '✅ POS SHOULD REMAIN PREPARING',
      );

      await _persist();

      notifyListeners();

      debugPrint(
        '✅ Item status update completed',
      );

      debugPrint(
        '============================================',
      );

      return true;
    } catch (e, stack) {
      debugPrint(
        '❌ updateKotItemStatus error: $e',
      );

      debugPrintStack(
        stackTrace: stack,
      );

      return false;
    }
  }
Future<bool> updateOrderStatus(String orderId, String status) async {
    final order = _findOrder(orderId);
    if (order == null) return false;

    final oldStatus = order.status;

    // Update UI immediately
    _updateAndSave(() {
      order.status = status;
      if (status.toLowerCase() == 'served') {
        order.servedAt = DateTime.now();
      } else {
        order.servedAt = null;
      }
      _optimisticStatuses[orderId] = _OptimisticStatus(status, DateTime.now());
      _notifyPos(order, status);
    });

    try {
      await _apiService.updateOrderStatus(order, status);
      return true;
    } catch (e, stack) {
      // Roll back if API fails
      _updateAndSave(() {
        order.status = oldStatus;
        if (oldStatus.toLowerCase() == 'served') {
          // Revert servedAt
        } else {
          order.servedAt = null;
        }
        _optimisticStatuses.remove(orderId);
      });

      KdsDebugLog.error('updateOrderStatus failed: $e\n$stack');
      return false;
    }
  }

  Future<void> reconnect() => _mqttService.connect();

  @override
  void dispose() {
    _servedCleanupTimer?.cancel();

    _apiService.dispose();
    _mqttService.dispose();

    super.dispose();
  }
}

class _OptimisticStatus {
  final String status;
  final DateTime timestamp;
  _OptimisticStatus(this.status, this.timestamp);
}

