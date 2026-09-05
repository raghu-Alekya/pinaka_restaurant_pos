import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

enum CaptainMqttConnectionState { disconnected, connecting, connected }

class CaptainMqttService {
  CaptainMqttService({
    required this.brokerHost,
    required this.brokerPort,
    required this.restaurantId, this.storeId,
  });

  final String brokerHost;
  final int brokerPort;
  final String restaurantId;

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;
  Timer? _reconnectTimer;
  bool _listenerAttached = false;
  bool _intentionalDisconnect = false;
  // final String restaurantId;

  final String? storeId;   // pass the same storeId that KDS uses

  String get kitchenOrdersTopic => 'store/$restaurantId/kitchen/orders';
  String get statusTopic => 'store/$restaurantId/captain/status';
  final _incomingController =
  StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController =
  StreamController<CaptainMqttConnectionState>.broadcast();

  Stream<Map<String, dynamic>> get messages => _incomingController.stream;
  Stream<CaptainMqttConnectionState> get connectionState =>
      _connectionController.stream;

  CaptainMqttConnectionState _state = CaptainMqttConnectionState.disconnected;
  CaptainMqttConnectionState get state => _state;

  String? lastError;
  int messagesReceived = 0;

  String get ordersTopic => 'store/$restaurantId/captain/orders';
  // String get statusTopic => 'store/$restaurantId/captain/status';

  Future<void> connect() async {
    if (_state == CaptainMqttConnectionState.connecting) {
      print('⚠️ Captain MQTT: already connecting, skip');
      return;
    }

    _reconnectTimer?.cancel();
    _setState(CaptainMqttConnectionState.connecting);
    lastError = null;

    try {
      _subscription?.cancel();
      _subscription = null;
      _listenerAttached = false;

      _intentionalDisconnect = true;
      _client?.disconnect();
      _intentionalDisconnect = false;

      // 🔥 SHORT unique client ID (prevents identifierRejected)
      final clientId =
          'cap_${DateTime.now().millisecondsSinceEpoch % 1000000}';

      print('🔌 Captain MQTT connecting → $brokerHost:$brokerPort as $clientId');
      print('   RestaurantId: $restaurantId');
      print('   Topic will be: $ordersTopic');

      _client = MqttServerClient.withPort(brokerHost, clientId, brokerPort);
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = false;
      _client!.logging(on: false);
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = (topic) {
        print(' Captain MQTT Subscribed OK → $topic');
      };
      _client!.onSubscribeFail = (topic) {
        print('Captain MQTT Subscribe FAILED → $topic');
      };
      _client!.connectionMessage =
          MqttConnectMessage().withClientIdentifier(clientId).startClean();

      final status = await _client!.connect();

      if (status?.state != MqttConnectionState.connected) {
        lastError = 'Connect failed: ${status?.returnCode}';
        print('❌ $lastError');
        _setState(CaptainMqttConnectionState.disconnected);
        _scheduleReconnect();
        return;
      }

      print('✅ Captain MQTT connect() returned connected');
      _subscribeAndListen();
    } catch (e, stack) {
      lastError = e.toString();
      print('❌ Captain MQTT connect exception: $e');
      print(stack);
      _setState(CaptainMqttConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _onConnected() {
    print('🟢 Captain MQTT onConnected callback');
    _subscribeAndListen();
    _setState(CaptainMqttConnectionState.connected);
  }

  void _onDisconnected() {
    if (_intentionalDisconnect) {
      print('ℹ️ Captain MQTT onDisconnected ignored (intentional)');
      return;
    }
    print('🔴 Captain MQTT onDisconnected');
    if (_state == CaptainMqttConnectionState.connecting) return;
    _setState(CaptainMqttConnectionState.disconnected);
    _scheduleReconnect();
  }

  // void _subscribeAndListen() {
  //   if (_client == null) {
  //     print('❌ Captain MQTT: client is null');
  //     return;
  //   }
  //
  //   print('📡 Subscribing to Captain orders topic: $ordersTopic');
  //   _client!.subscribe(ordersTopic, MqttQos.atLeastOnce);
  //
  //   if (_listenerAttached) return;
  //
  //   if (_client!.updates == null) {
  //     print('❌ Captain MQTT: updates stream is NULL');
  //     return;
  //   }
  //
  //   _subscription = _client!.updates!.listen(
  //     _onMessages,
  //     onError: (e) {
  //       print('❌ Captain MQTT updates stream error: $e');
  //     },
  //   );
  //
  //   _listenerAttached = true;
  //   print('👂 Captain MQTT message listener attached');
  // }

  void _subscribeAndListen() {
    if (_client == null) {
      print('❌ Captain MQTT: client is null');
      return;
    }

    // POS → Captain
    print('📡 Subscribing to Captain orders topic: $ordersTopic');
    _client!.subscribe(ordersTopic, MqttQos.atLeastOnce);

    // Captain → Captain (and POS status mirror)
    print('📡 Subscribing to Captain status topic: $statusTopic');
    _client!.subscribe(statusTopic, MqttQos.atLeastOnce);

    if (_listenerAttached) return;

    if (_client!.updates == null) {
      print('❌ Captain MQTT: updates stream is NULL');
      return;
    }

    _subscription = _client!.updates!.listen(
      _onMessages,
      onError: (e) {
        print('❌ Captain MQTT updates stream error: $e');
      },
    );

    _listenerAttached = true;
    print('👂 Captain MQTT message listener attached (orders + status)');
  }

  // void _onMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
  //   print('📨 Captain MQTT received ${messages.length} packet(s)');
  //
  //   for (final message in messages) {
  //     final topic = message.topic;
  //     print('   Topic: $topic');
  //
  //     if (topic != ordersTopic) {
  //       print('   ⚠️ Topic mismatch – ignoring');
  //       continue;
  //     }
  //
  //     final payload = message.payload;
  //     if (payload is! MqttPublishMessage) continue;
  //
  //     final body = MqttPublishPayload.bytesToStringAsString(
  //       payload.payload.message,
  //     );
  //
  //     print('   Raw payload: $body');
  //
  //     try {
  //       final decoded = jsonDecode(body);
  //       if (decoded is! Map) continue;
  //
  //       final map = Map<String, dynamic>.from(decoded);
  //       messagesReceived++;
  //
  //       final event = map['event']?.toString() ?? '';
  //
  //       print('========== CAPTAIN RECEIVED EVENT ==========');
  //       print('Event          : $event');
  //       print('Order ID       : ${map['parent_order_id']}');
  //       print('Table ID       : ${map['table_id']}');
  //       print('Table Name     : ${map['table_name']}');
  //       print('Status         : ${map['status']}');
  //       print('Table Status   : ${map['table_status']}');
  //       print('Paid Amount    : ${map['paid_amount']}');
  //       print('Payment Method : ${map['payment_method']}');
  //       print('Order Type     : ${map['order_type']}');
  //       print('Total messages : $messagesReceived');
  //       print('===========================================');
  //
  //       if (event == 'payment_completed') {
  //         print('🎉 PAYMENT COMPLETED from POS → free table ${map['table_name']}');
  //       }
  //
  //       _incomingController.add(map);
  //     } catch (e) {
  //       print('❌ Captain MQTT JSON parse error: $e');
  //     }
  //   }
  // }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    print('📨 Captain MQTT received ${messages.length} packet(s)');

    for (final message in messages) {
      final topic = message.topic;
      print('   Topic: $topic');

      // Accept BOTH topics (multi-captain + POS)
      if (topic != ordersTopic && topic != statusTopic) {
        print('   ⚠️ Topic mismatch – ignoring');
        continue;
      }

      final payload = message.payload;
      if (payload is! MqttPublishMessage) continue;

      final body = MqttPublishPayload.bytesToStringAsString(
        payload.payload.message,
      );

      print('   Raw payload: $body');

      try {
        final decoded = jsonDecode(body);
        if (decoded is! Map) continue;

        final map = Map<String, dynamic>.from(decoded);
        messagesReceived++;

        final event = map['event']?.toString() ?? '';

        print('========== CAPTAIN RECEIVED EVENT ==========');
        print('Event          : $event');
        print('Order ID       : ${map['parent_order_id']}');
        print('Table ID       : ${map['table_id']}');
        print('Table Name     : ${map['table_name']}');
        print('Status         : ${map['status']}');
        print('Table Status   : ${map['table_status']}');
        print('Paid Amount    : ${map['paid_amount']}');
        print('Payment Method : ${map['payment_method']}');
        print('Order Type     : ${map['order_type']}');
        print('Total messages : $messagesReceived');
        print('===========================================');

        if (event == 'payment_completed') {
          print('🎉 PAYMENT COMPLETED → free table ${map['table_name']}');
        }

        _incomingController.add(map);
      } catch (e) {
        print('❌ Captain MQTT JSON parse error: $e');
      }
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_state != CaptainMqttConnectionState.connected &&
          _state != CaptainMqttConnectionState.connecting) {
        print('🔄 Captain MQTT auto-reconnecting...');
        connect();
      }
    });
  }

  void _setState(CaptainMqttConnectionState next) {
    if (_state != next) {
      print('Captain MQTT state: $_state → $next');
    }
    _state = next;
    if (!_connectionController.isClosed) {
      _connectionController.add(next);
    }
  }

  void dispose() {
    print('🧹 CaptainMqttService disposed');
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _client?.disconnect();
    _incomingController.close();
    _connectionController.close();
  }

  /////=====

// Inside CaptainMqttService class

  // Future<void> publishOrderCreated({
  //   required int orderId,
  //   required String orderType,
  //   required int tableId,
  //   required String tableName,
  //   required int zoneId,
  //   required String zoneName,
  //   int? guestCount,
  // }) async {
  //   if (_client == null ||
  //       _client!.connectionStatus?.state != MqttConnectionState.connected) {
  //     print('⚠️ Captain MQTT not connected – cannot publish order_created');
  //     // try connect first
  //     await connect();
  //     if (_client == null ||
  //         _client!.connectionStatus?.state != MqttConnectionState.connected) {
  //       return;
  //     }
  //   }
  //
  //   final payload = {
  //     'event': 'order_created',
  //     'restaurant_id': restaurantId,
  //     'parent_order_id': orderId,
  //     'order_type': orderType,
  //     'table_id': tableId.toString(),
  //     'table_name': tableName,
  //     'zone_id': zoneId,
  //     'zone_name': zoneName,
  //     'guest_count': guestCount,
  //     'status': 'occupied',
  //     'table_status': 'Occupied',
  //     'timestamp': DateTime.now().toIso8601String(),
  //   };
  //
  //   print('========== CAPTAIN PUBLISH ORDER CREATED → POS ==========');
  //   print('Topic  : $statusTopic'); // store/{id}/captain/status
  //   print('Payload: ${jsonEncode(payload)}');
  //   print('=======================================================');
  //
  //   final builder = MqttClientPayloadBuilder()
  //     ..addString(jsonEncode(payload));
  //
  //   _client!.publishMessage(
  //     statusTopic, // ← POS will listen on this
  //     MqttQos.atLeastOnce,
  //     builder.payload!,
  //   );
  //
  //   print('✅ order_created published by Captain');
  // }

  Future<void> publishOrderCreated({
    required int orderId,
    required String orderType,
    required int tableId,
    required String tableName,
    required int zoneId,
    required String zoneName,
    int? guestCount,
    // Optional – pass real KOT data when available
    int? kotId,
    String? kotNumber,
    List<Map<String, dynamic>>? items,
    String status = 'Pending',
  }) async {
    // 1. Ensure MQTT is connected
    if (_client == null ||
        _client!.connectionStatus?.state != MqttConnectionState.connected) {
      print('⚠️ Captain MQTT not connected – trying reconnect...');
      await connect();
      if (_client == null ||
          _client!.connectionStatus?.state != MqttConnectionState.connected) {
        print('❌ Still not connected – cannot publish order_created');
        return;
      }
    }

    // 2. Use the same storeId that KDS expects
    final effectiveStoreId = storeId ?? restaurantId;

    // 3. Build the payload that KDS understands
    final payload = <String, dynamic>{
      'event': 'kot_created',
      'restaurant_id': restaurantId,
      'store_id': effectiveStoreId,
      'parent_order_id': orderId,
      'order_type': orderType,
      'table_id': tableId.toString(),
      'table_name': tableName,
      'zone_id': zoneId,
      'zone_name': zoneName,
      'guest_count': guestCount,
      'status': status,
      'table_status': 'Occupied',
      'kot_order_status': 'new',
      'kot_id': kotId,
      'kot_number': kotNumber ?? 'KOT-$orderId',
      'kotTime': DateTime.now().toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 4. Attach items if available (strongly recommended for Instant display)
    if (items != null && items.isNotEmpty) {
      payload['kot_items'] = items;
      payload['items'] = items;
    }

    // 5. Also send nested kot object (some providers expect it)
    payload['kot'] = {
      'id': kotId,
      'kot_number': kotNumber ?? 'KOT-$orderId',
      'kot_id': kotId,
      'status': status,
      'kot_order_status': 'new',
      'items': items ?? [],
      'kot_items': items ?? [],
    };

    print('========== CAPTAIN PUBLISH kot_created → KDS ==========');
    print('Topic  : $kitchenOrdersTopic');
    print('Payload: ${jsonEncode(payload)}');
    print('=======================================================');

    final builder = MqttClientPayloadBuilder()
      ..addString(jsonEncode(payload));

    // 6. Publish to kitchen/orders → KDS receives INSTANTLY
    _client!.publishMessage(
      kitchenOrdersTopic,          // store/{restaurantId}/kitchen/orders
      MqttQos.atLeastOnce,
      builder.payload!,
    );

    // 7. Optional: also notify POS / other captains
    _client!.publishMessage(
      statusTopic,                 // store/{restaurantId}/captain/status
      MqttQos.atLeastOnce,
      builder.payload!,
    );

    print('✅ kot_created published to kitchen/orders (KDS) + captain/status');
  }

}