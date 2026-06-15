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
    _init();

    _servedCleanupTimer =
        Timer.periodic(const Duration(seconds: 30), (_) {
          _clearServedOrders();
        });
  }

  final KdsMqttService _mqttService;
  final OrderApiService _apiService;
  final OrderLocalStorage _storage = OrderLocalStorage();
  final List<KitchenOrder> _orders = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<KitchenOrder> get orders => List.unmodifiable(_orders);
  KdsConnectionState get connectionState => _mqttService.state;
  String? get connectionError => _mqttService.lastError;
  String get subscribedTopic => _mqttService.ordersTopic;
  String get brokerHost => _mqttService.brokerHost;
  int get brokerPort => _mqttService.brokerPort;
  int get mqttMessagesReceived => _mqttService.messagesReceived;

  List<Map<String, dynamic>> get pendingOrders => _orders
      .where((o) => o.status == 'Pending')
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
    _orders.addAll(saved);
    _loaded = true;
    KdsDebugLog.info('Loaded ${saved.length} orders from local storage');
    notifyListeners();

    _mqttService.messages.listen(_handleMessage);
    _mqttService.connectionState.listen((_) => notifyListeners());
    _mqttService.connect();
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

  Future<bool> startOrder(String orderId) async {
    final order = _findOrder(orderId);
    if (order == null) return false;

    try {
      await _apiService.startOrder(order);

      _updateAndSave(() {
        order.status = 'Preparing';
        order.isCancelled = false;
        _notifyPos(order, 'Preparing');
      });

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

        pendingOrders.removeWhere(
              (o) => o['id'].toString() == orderId,
        );

        _notifyPos(
          order,
          'Cancelled',
          isCancelled: true,
        );
      });

      return true;
    } catch (e) {
      return false;
    }
  }
  Future<bool> recallOrder(String orderId) async {
    final order = _findOrder(orderId);
    if (order == null) return false;

    try {
      await _apiService.recallOrder(order);

      _updateAndSave(() {
        order.isCancelled = false;
        order.status = 'Pending';
        _notifyPos(order, 'yet to prepare');
      });

      return true;
    } catch (e, stack) {
      KdsDebugLog.error('recallOrder failed: $e\n$stack');
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    final order = _findOrder(orderId);
    if (order == null) return false;

    try {
      await _apiService.updateOrderStatus(order, status);

      _updateAndSave(() {
        order.status = status;
        _notifyPos(order, status);
      });
      for (final o in _orders) {
        print(
          'ID=${o.id} Status=${o.status} Items=${o.items.length}',
        );
      }

      if (status.toLowerCase() == 'served') {
        print('Entered served block');

        final currentOrderId = orderId;

        Future.delayed(const Duration(seconds: 30), () {
          print('Timer fired');

          final order = _findOrder(currentOrderId);

          print('Order found = ${order?.id}');

          if (order != null &&
              order.status.toLowerCase() == 'served') {

            print(
              'Before clear: ${order.id} -> ${order.items.length}',
            );

            order.items.clear();

            notifyListeners();

            print(
              'After clear: ${order.id} -> ${order.items.length}',
            );
          }
        });
      }
      return true;
    } catch (e, stack) {
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
