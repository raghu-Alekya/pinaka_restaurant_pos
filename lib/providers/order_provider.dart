import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/kitchen_order.dart';
import '../services/api_services.dart';
import '../services/kds_localstorage.dart';
import '../services/kds_mqtt_service.dart';
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

        _optimisticStatuses[orderId] = _OptimisticStatus('Cancelled', DateTime.now());

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
  Future<void> loadExistingOrders() async {
    try {
      final apiOrders = await _apiService.getKitchenDisplayOrders();

      // Keep locally served orders so they don't disappear prematurely
      final servedLocal = _orders.where((o) => o.status.toLowerCase() == 'served').toList();

      final List<KitchenOrder> loadedOrders = [];

      for (final json in apiOrders) {
        try {
          final order = KitchenOrder.fromJson(
            Map<String, dynamic>.from(json),
          );

          // Restore locally cancelled items status
          KitchenOrder? existingOrder;
          for (final o in _orders) {
            if (o.id == order.id) {
              existingOrder = o;
              break;
            }
          }
          if (existingOrder != null) {
            for (final parsedItem in order.items) {
              for (final existingItem in existingOrder.items) {
                if (existingItem.name == parsedItem.name) {
                  if (existingItem.status.toLowerCase() == 'cancelled') {
                    parsedItem.status = 'cancelled';
                  }
                  break;
                }
              }
            }
          }

          // Apply optimistic status if it's recent (e.g. within 15 seconds)
          final optimistic = _optimisticStatuses[order.id];
          if (optimistic != null) {
            if (DateTime.now().difference(optimistic.timestamp).inSeconds < 15) {
              order.status = optimistic.status;
            } else {
              _optimisticStatuses.remove(order.id);
            }
          }

          // If it was cancelled optimistically, skip loading it
          if (order.status == 'Cancelled' || order.status.toLowerCase() == 'cancelled') {
            continue;
          }

          // If this order is already marked as served locally, do not overwrite it with old status from API
          if (servedLocal.any((o) => o.id == order.id)) {
            continue;
          }

          loadedOrders.add(order);

          KdsDebugLog.info(
            'Loaded ${order.id} status=${order.status}',
          );
        } catch (e, stack) {
          KdsDebugLog.error('Failed to parse order JSON in loadExistingOrders: $e\n$stack');
        }
      }

      _orders.clear();
      _orders.addAll(loadedOrders);
      _orders.addAll(servedLocal);

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
