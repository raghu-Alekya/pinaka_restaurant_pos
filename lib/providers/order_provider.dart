import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/kitchen_order.dart';
import '../services/api_services.dart';
import '../services/kds_localstorage.dart';
import '../services/kds_mqtt_service.dart';
import '../utils/kds_logger.dart';

class OrderProvider extends ChangeNotifier {

  Timer? _servedCleanupTimer;

  OrderProvider(this._mqttService, this._apiService) {
    KdsDebugLog.info('OrderProvider created');
    // _init();

    _servedCleanupTimer =
        Timer.periodic(const Duration(seconds: 30), (_) {
          _clearServedOrders();
        });
  }
  Future<void> initialize() async {
    await _init();
  }

  final KdsMqttService _mqttService;
  final OrderApiService _apiService;
  final OrderLocalStorage _storage = OrderLocalStorage();
  final List<KitchenOrder> _orders = [];
  bool _loaded = false;

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
      .where((o) => o.status == 'Served')
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

  void _handleMessage(Map<String, dynamic> message) {
    if (message['event'] != 'kot_created') return;

    try {
      final order = KitchenOrder.fromMqttPayload(message);
      _addOrder(order);
    } catch (e, stack) {
      KdsDebugLog.error('Failed to parse order: $e\n$stack');
    }
  }

  void _addOrder(KitchenOrder order) {
    final index = _orders.indexWhere((item) => item.id == order.id);
    if (index >= 0) {
      _orders[index] = order;
    } else {
      _orders.insert(0, order);
    }
    _persist();
    notifyListeners();
  }

  KitchenOrder? _findOrder(String orderId) {
    for (final order in _orders) {
      if (order.id == orderId) return order;
    }
    return null;
  }



  void _notifyPos(KitchenOrder order, String status,
      {bool isCancelled = false}) {
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
    );

    KdsDebugLog.info(
      'POS notified: ${order.id} → $posStatus (cancelled=$isCancelled)',
    );
  }
  void _clearServedOrders() {
    _orders.removeWhere(
          (o) => o.status.toLowerCase() == 'served',
    );

    notifyListeners();
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

        // Keep only unchecked items
        order.items.removeWhere((item) {
          return !remainingItems.any(
                (r) => r['name'] == item.name,
          );
        });

        order.status = 'Preparing';
        order.isCancelled = false;

        _notifyPos(order, 'Preparing');
      });

      await _apiService.startOrder(order);

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

        // Remove from pending list if present
        pendingOrders.removeWhere(
              (o) => o['id'].toString() == orderId,
        );

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
      _updateAndSave(() {
        order.items.removeWhere((item) {
          return selectedItems.any(
                (selected) =>
            selected['name'] == item.name,
          );
        });
      });

      notifyListeners();
      return true;
    } catch (e) {
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
        _notifyPos(order, "Preparing");
      });

      return true;
    } catch (e, stack) {
      KdsDebugLog.error("recallOrder failed: $e\n$stack");
      return false;
    }
  }
  Future<void> loadExistingOrders() async {
    try {
      final apiOrders = await _apiService.getKitchenDisplayOrders();

      _orders.clear();

      for (final json in apiOrders) {
        print("=======================================");
        print("KOT Number  : ${json['kot_number']}");
        print("Order ID    : ${json['order_id']}");
        print("Order Type  : ${json['order_type']}");
        print("Status      : ${json['status']}");
        print("KOT Status  : ${json['kot_status']}");
        print("Table       : ${json['table_name']}");
        print("Full JSON   : $json");
        print("=======================================");

        final kotStatus =
            json['kot_status']?.toString().trim().toLowerCase() ?? '';

        // Skip On Hold KOTs
        // if (kotStatus == 'on hold') {
        //   print("Skipping On Hold KOT : ${json['kot_number']}");
        //   continue;
        // }

        final order = KitchenOrder.fromJson(
          Map<String, dynamic>.from(json),
        );

        _orders.add(order);

        KdsDebugLog.info(
          'Loaded ${order.id} status=${order.status}',
        );
      }

      print('Total Orders Loaded 1: ${_orders.length}');
      print('Pending Count 2: ${pendingOrders.length}');
      print('Preparing Count 3: ${preparingOrders.length}');
      print('Served Count 4: ${servedOrders.length}');

      await _persist();
      notifyListeners();
    } catch (e, stack) {
      KdsDebugLog.error(
        'Failed to load existing orders: $e\n$stack',
      );
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    final order = _findOrder(orderId);
    if (order == null) return false;

    final oldStatus = order.status;

    // Update UI immediately
    _updateAndSave(() {
      order.status = status;
      _notifyPos(order, status);
    });

    try {
      await _apiService.updateOrderStatus(order, status);
      return true;
    } catch (e, stack) {
      // Roll back if API fails
      _updateAndSave(() {
        order.status = oldStatus;
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
