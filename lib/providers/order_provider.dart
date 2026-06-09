import 'package:flutter/foundation.dart';

import '../models/kitchen_order.dart';
import '../services/kds_localstorage.dart';
import '../services/kds_mqtt_service.dart';
// import '../services/order_local_storage.dart';
import '../utils/kds_logger.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._mqttService) {
    KdsDebugLog.info('OrderProvider created');
    _init();
  }

  final KdsMqttService _mqttService;
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
      .where((o) => o.status == 'Pending' && !o.isCancelled)
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
    // Load saved orders on startup
    final saved = await _storage.loadOrders();
    _orders.addAll(saved);
    _loaded = true;
    KdsDebugLog.info('Loaded ${saved.length} orders from local storage');
    notifyListeners();

    // Then connect MQTT for new orders
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

  void _publishStatus(KitchenOrder order, String status,
      {bool isCancelled = false}) {
    _mqttService.sendStatusUpdate(
      kotId: order.kotId,
      parentOrderId: order.parentOrderId,
      kotNumber: order.id,
      status: status,
      isCancelled: isCancelled,
    );
  }

  void _updateAndSave(void Function() update) {
    update();
    _persist();
    notifyListeners();
  }

  void startOrder(String orderId) {
    final order = _findOrder(orderId);
    if (order == null) return;
    _updateAndSave(() {
      order.status = 'Preparing';
      order.isCancelled = false;
      _publishStatus(order, 'Preparing');
    });
  }

  void cancelOrder(String orderId) {
    final order = _findOrder(orderId);
    if (order == null) return;
    _updateAndSave(() {
      order.isCancelled = true;
      _publishStatus(order, 'Cancelled', isCancelled: true);
    });
  }

  void recallOrder(String orderId) {
    final order = _findOrder(orderId);
    if (order == null) return;
    _updateAndSave(() {
      order.isCancelled = false;
      order.status = 'Pending';
      _publishStatus(order, 'Pending');
    });
  }

  void updateOrderStatus(String orderId, String status) {
    final order = _findOrder(orderId);
    if (order == null) return;
    _updateAndSave(() {
      order.status = status;
      _publishStatus(order, status);
    });
  }

  Future<void> reconnect() => _mqttService.connect();

  @override
  void dispose() {
    _mqttService.dispose();
    super.dispose();
  }
}