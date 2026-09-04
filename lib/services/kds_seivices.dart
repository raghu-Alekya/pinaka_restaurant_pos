import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/order/KOT_model.dart';

class KdsMqttPublisher {
  static MqttServerClient? _client;
  static bool _connected = false;

  static StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
  _statusSubscription;
  static final _statusController =
  StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of KDS → POS status updates (`kot_status_updated`).
  static Stream<Map<String, dynamic>> get statusUpdates =>
      _statusController.stream;

  static const String _brokerHost = String.fromEnvironment(
    'MQTT_BROKER_HOST',
    defaultValue: '178.16.140.169',
  );
  static const int _brokerPort = int.fromEnvironment(
    'MQTT_BROKER_PORT',
    defaultValue: 1883,
  );

  // ─── Topics ───────────────────────────────────────────────────
  static String _topic(String restaurantId) =>
      'store/$restaurantId/kitchen/orders';

  static String _statusTopic(String restaurantId) =>
      'store/$restaurantId/kitchen/status';

  static String _captainOrdersTopic(String restaurantId) =>
      'store/$restaurantId/captain/orders';

  // ─── Connect (safe short client ID) ───────────────────────────
  static Future<void> _ensureConnected() async {
    if (_connected &&
        _client?.connectionStatus?.state == MqttConnectionState.connected) {
      return;
    }

    // Short unique client ID → prevents identifierRejected
    final clientId =
        'pos_${DateTime.now().millisecondsSinceEpoch % 1000000}';

    print('🔌 Connecting MQTT with clientId: $clientId');

    _client = MqttServerClient.withPort(
      _brokerHost,
      clientId,
      _brokerPort,
    )
      ..keepAlivePeriod = 60
      ..autoReconnect = true
      ..onConnected = () {
        print(' MQTT connected ($clientId)');
        _connected = true;
      }
      ..onDisconnected = () {
        print(' MQTT disconnected');
        _connected = false;
      };

    try {
      await _client!.connect();
      _connected =
          _client!.connectionStatus?.state == MqttConnectionState.connected;

      if (_connected) {
        print(' MQTT connected successfully to $_brokerHost:$_brokerPort');
      } else {
        print('MQTT connection failed: ${_client!.connectionStatus}');
      }
    } catch (e) {
      print(' MQTT connection exception: $e');
      _connected = false;
    }
  }

  // ─── Subscribe to KDS status updates ──────────────────────────
  static Future<void> listenForKdsStatusUpdates({
    required String restaurantId,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) return;

      final topic = _statusTopic(restaurantId);
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      print('Subscribed to KDS status → $topic');

      await _statusSubscription?.cancel();
      if (_client!.updates == null) return;

      _statusSubscription = _client!.updates!.listen((messages) {
        for (final message in messages) {
          if (message.topic != topic) continue;

          final payload = message.payload;
          if (payload is! MqttPublishMessage) continue;

          final body = MqttPublishPayload.bytesToStringAsString(
            payload.payload.message,
          );

          try {
            final decoded = jsonDecode(body);
            if (decoded is! Map) continue;

            final map = Map<String, dynamic>.from(decoded);
            if (map['event'] != 'kot_status_updated') continue;

            print(
              ' KDS status update: kot=${map['kot_number']} status=${map['status']}',
            );
            _statusController.add(map);
          } catch (e) {
            print(' KDS status parse error: $e');
          }
        }
      });
    } catch (e) {
      print(' KDS status subscribe failed: $e');
    }
  }

  // ─── Publish KOT created ──────────────────────────────────────
  static Future<void> notifyKotCreated({
    required String restaurantId,
    required String storeId,
    required int parentOrderId,
    required int zoneId,
    required String zoneName,
    required String orderType,
    required KotModel kot,
    String? tableName,
    String? tableId,
  }) async {
    try {
      await _ensureConnected();

      if (!_connected || _client == null) return;

      final payload = {
        'event': 'kot_created',
        'restaurant_id': restaurantId,
        'store_id': storeId,
        'parent_order_id': parentOrderId,
        'zone_id': zoneId,
        'zone_name': zoneName,
        'order_type': orderType,
        'table_name': tableName ?? '',
        'table_id': tableId ?? '',
        'kot': kot.toJson(),
      };

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _topic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print(
        '✅ KOT ${kot.kotNumber} published '
            'for storeId=$storeId',
      );
    } catch (e) {
      print('MQTT publish failed: $e');
    }
  }
  // ─── Publish Takeaway Completed ───────────────────────────────
  static Future<void> notifyTakeawayCompleted({
    required String restaurantId,
    required int parentOrderId,
    int? kotId,
    String? kotNumber,
    int? zoneId,
    String? zoneName,
  }) async {
    try {
      await _ensureConnected();

      if (!_connected || _client == null) {
        print('MQTT not connected - cannot send takeaway completed');
        return;
      }

      final payload = {
        'event': 'takeaway_completed',
        'restaurant_id': restaurantId,
        'parent_order_id': parentOrderId,
        'kot_id': kotId,
        'kot_number': kotNumber,
        'zone_id': zoneId,
        'zone_name': zoneName,
        'order_type': 'takeaway',
        'status': 'completed',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== PUBLISH TAKEAWAY COMPLETED ==========');
      print('Topic: ${_topic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _topic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('Takeaway completed event published successfully');
    } catch (e, stack) {
      print('Takeaway MQTT publish failed: $e');
      print(stack);
    }
  }

  // ─── Publish KOT Quantity Updated ─────────────────────────────
  static Future<void> notifyKotItemQuantityUpdated({
    required String restaurantId,
    required int kotId,
    required String kotNumber,
    required int itemId,
    required int quantity,
    int? parentOrderId,
  }) async {
    try {
      await _ensureConnected();

      if (!_connected || _client == null) {
        print('MQTT not connected - cannot send quantity update');
        return;
      }

      final payload = {
        'event': 'kot_quantity_updated',
        'restaurant_id': restaurantId,
        'kot_id': kotId,
        'kot_number': kotNumber,
        'item_id': itemId,
        'quantity': quantity,
        'parent_order_id': parentOrderId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== PUBLISH KOT QUANTITY UPDATED ==========');
      print('Topic: ${_topic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('==================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _topic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('KOT quantity update published successfully');
    } catch (e, stack) {
      print('Quantity MQTT publish failed: $e');
      print(stack);
    }
  }

  // ─── Publish KOT Status ───────────────────────────────────────
  static Future<void> publishKotStatus({
    required String restaurantId,
    required int? kotId,
    required String kotNumber,
    required String status,
    int? parentOrderId,
    int? zoneId,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) return;

      final payload = {
        'event': 'kot_status_updated',
        'restaurant_id': restaurantId,
        'kot_id': kotId,
        'kot_number': kotNumber,
        'parent_order_id': parentOrderId,
        'zone_id': zoneId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Publishing KOT Status: ${jsonEncode(payload)}');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _statusTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } catch (e) {
      print(' Status publish failed: $e');
    }
  }

  // ─── NEW: Notify Captain – Payment Completed ──────────────────
  static Future<void> notifyPaymentCompleted({
    required String restaurantId,
    required int orderId,
    required String orderType, // "Dine In" / "Take Away"
    int? zoneId,
    String? zoneName,
    String? tableName,
    String? tableId,
    List<Map<String, dynamic>>? tables,
    double? paidAmount,
    String? paymentMethod,
  }) async {
    try {
      await _ensureConnected();

      if (!_connected || _client == null) {
        print('MQTT not connected - cannot notify Captain');
        return;
      }

      final payload = {
        'event': 'payment_completed',
        'restaurant_id': restaurantId,
        'parent_order_id': orderId,
        'order_type': orderType,
        'zone_id': zoneId,
        'zone_name': zoneName ?? '',
        'table_name': tableName ?? '',
        'table_id': tableId ?? '',
        'tables': tables ?? [],
        'status': 'completed',
        'table_status': 'available', // Captain should free the table
        'paid_amount': paidAmount,
        'payment_method': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== PUBLISH PAYMENT COMPLETED → CAPTAIN ==========');
      print('Topic  : ${_captainOrdersTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('=======================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _captainOrdersTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('✅ Payment completed event sent to Captain successfully');
    } catch (e, stack) {
      print('❌ Captain MQTT publish failed: $e');
      print(stack);
    }
  }

  // ─── NEW: Notify Captain – Order Created ──────────────────────
  static Future<void> notifyOrderCreated({
    required String restaurantId,
    required int orderId,
    required String orderType, // "Dine In" / "Take Away"
    int? zoneId,
    String? zoneName,
    String? tableName,
    String? tableId,
    int? guestCount,
  }) async {
    try {
      await _ensureConnected();

      if (!_connected || _client == null) {
        print('MQTT not connected - cannot notify Captain (order created)');
        return;
      }

      final payload = {
        'event': 'order_created',
        'restaurant_id': restaurantId,
        'parent_order_id': orderId,
        'order_type': orderType,
        'zone_id': zoneId,
        'zone_name': zoneName ?? '',
        'table_name': tableName ?? '',
        'table_id': tableId ?? '',
        'guest_count': guestCount,
        'status': 'occupied',
        'table_status': 'Occupied', // Captain should mark table Occupied
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== PUBLISH ORDER CREATED → CAPTAIN ==========');
      print('Topic  : ${_captainOrdersTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('====================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _captainOrdersTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('Order created event sent to Captain successfully');
    } catch (e, stack) {
      print(' Captain MQTT publish (order created) failed: $e');
      print(stack);
    }
  }
  static Future<void> notifyKotTableUpdated({
    required String restaurantId,
    required String storeId,
    required int kotId,
    required String kotNumber,
    required int parentOrderId,
    int? newParentOrderId,
    int? oldTableId,
    String? oldTableName,
    int? tableId,
    required String tableName,
    int? zoneId,
    String? zoneName,
  }) async {
    try {
      await _ensureConnected();

      if (!_connected || _client == null) {
        print(
          '❌ MQTT not connected - cannot send table update',
        );
        return;
      }

      final payload = {
        'event': 'kot_table_updated',

        'restaurant_id': restaurantId,
        'store_id': storeId,

        'kot_id': kotId,
        'kot_number': kotNumber,

        'parent_order_id': parentOrderId,
        'new_parent_order_id': newParentOrderId,

        'old_table_id': oldTableId,
        'old_table_name': oldTableName,

        'table_id': tableId,
        'table_name': tableName,

        'zone_id': zoneId,
        'zone_name': zoneName ?? '',

        'timestamp': DateTime.now().toIso8601String(),
      };

      print(
        '========== PUBLISH KOT TABLE UPDATED ==========',
      );

      print(
        'Topic: ${_topic(restaurantId)}',
      );

      print(
        'Payload: ${jsonEncode(payload)}',
      );

      print(
        '================================================',
      );

      final builder = MqttClientPayloadBuilder()
        ..addString(
          jsonEncode(payload),
        );

      _client!.publishMessage(
        _topic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print(
        '✅ KOT table update published successfully',
      );
    } catch (e, stack) {
      print(
        '❌ Table transfer MQTT publish failed: $e',
      );
      print(stack);
    }
  }


  // ─── NEW: Notify Captain – KOT Printed / Order Running ──────────
  static Future<void> notifyKotPrinted({
    required String restaurantId,
    required int orderId,
    required String orderType, // "Dine In" / "Take Away"
    int? zoneId,
    String? zoneName,
    String? tableName,
    String? tableId,
    String? kotNumber,
    int? kotId,
  }) async {
    try {
      await _ensureConnected();

      if (!_connected || _client == null) {
        print('MQTT not connected - cannot notify Captain (KOT printed)');
        return;
      }

      final payload = {
        'event': 'kot_printed',
        'restaurant_id': restaurantId,
        'parent_order_id': orderId,
        'order_type': orderType,
        'zone_id': zoneId,
        'zone_name': zoneName ?? '',
        'table_name': tableName ?? '',
        'table_id': tableId ?? '',
        'kot_number': kotNumber ?? '',
        'kot_id': kotId,
        'status': 'running',
        'table_status': 'Running', // Captain should mark table Running
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== PUBLISH KOT PRINTED → CAPTAIN ==========');
      print('Topic  : ${_captainOrdersTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('==================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _captainOrdersTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('✅ KOT printed event sent to Captain successfully');
    } catch (e, stack) {
      print('Captain MQTT publish (KOT printed) failed: $e');
      print(stack);
    }
  }

  // ─── NEW: Notify Captain – Bill Printed / Ready to Pay ────────────
  static Future<void> notifyBillPrinted({
    required String restaurantId,
    required int orderId,
    String? tableId,
    String? tableName,
    String? orderType,
  }) async {
    try {
      await _ensureConnected();

      if (!_connected || _client == null) {
        print('MQTT not connected - cannot notify Captain (Bill printed)');
        return;
      }

      final payload = {
        'event': 'bill_printed',
        'restaurant_id': restaurantId,
        'parent_order_id': orderId,
        'order_type': orderType ?? 'Dine In',
        'table_id': tableId ?? '',
        'table_name': tableName ?? '',
        'status': 'ready to pay',
        'table_status': 'ready to pay',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== PUBLISH BILL PRINTED (READY TO PAY) → CAPTAIN ==========');
      print('Topic  : ${_captainOrdersTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('===================================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _captainOrdersTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('✅ Bill printed (ready to pay) event sent successfully');
    } catch (e, stack) {
      print('Captain MQTT publish (Bill printed) failed: $e');
      print(stack);
    }
  }

  // ─── NEW: Notify Captain – Tables Merged ────────────────────────
  static Future<void> notifyTablesMerged({
    required String restaurantId,
    required int parentTableId,
    required String parentTableName,
    required List<int> childTableIds,
    List<String>? childTableNames,
    int? zoneId,
    String? zoneName,
    bool isUpdate = false,
  }) async {
    try {
      await _ensureConnected();

      if (!_connected || _client == null) {
        print('MQTT not connected - cannot notify Captain (tables merged)');
        return;
      }

      final payload = {
        'event': isUpdate ? 'tables_merge_updated' : 'tables_merged',
        'restaurant_id': restaurantId,
        'parent_table_id': parentTableId,
        'parent_table_name': parentTableName,
        'child_table_ids': childTableIds,
        'child_table_names': childTableNames ?? [],
        'zone_id': zoneId,
        'zone_name': zoneName ?? '',
        'status': 'merged',
        'table_status': 'Occupied', // or keep as-is; Captain can refresh
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== PUBLISH TABLES MERGED → CAPTAIN ==========');
      print('Topic  : ${_captainOrdersTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('====================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _captainOrdersTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('✅ Tables merged event sent to Captain successfully');
    } catch (e, stack) {
      print(' Captain MQTT publish (tables merged) failed: $e');
      print(stack);
    }
  }

  // ─── NEW: Notify Captain – Tables Unmerged ──────────────────────
  static Future<void> notifyTablesUnmerged({
    required String restaurantId,
    required int parentTableId,
    String? parentTableName,
    int? zoneId,
    String? zoneName,
    String? mergedTables, // e.g. "T1-T2-T3"
  }) async {
    try {
      await _ensureConnected();

      if (!_connected || _client == null) {
        print('MQTT not connected - cannot notify Captain (tables unmerged)');
        return;
      }

      final payload = {
        'event': 'tables_unmerged',
        'restaurant_id': restaurantId,
        'parent_table_id': parentTableId,
        'parent_table_name': parentTableName ?? '',
        'merged_tables': mergedTables ?? '',
        'zone_id': zoneId,
        'zone_name': zoneName ?? '',
        'status': 'unmerged',
        'table_status': 'Available', // tables become free again
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== PUBLISH TABLES UNMERGED → CAPTAIN ==========');
      print('Topic  : ${_captainOrdersTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('======================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _captainOrdersTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('Tables unmerged event sent to Captain successfully');
    } catch (e, stack) {
      print('Captain MQTT publish (tables unmerged) failed: $e');
      print(stack);
    }
  }

  // ─── Captain → POS stream ───────────────────────────────────────

  static StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
  _captainSubscription;
  static final _captainController =
  StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get captainUpdates =>
      _captainController.stream;

  static String _captainStatusTopic(String restaurantId) =>
      'store/$restaurantId/captain/status';

  /// Call once when TablesScreen / app starts
  static Future<void> listenForCaptainUpdates({
    required String restaurantId,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) return;

      final topic = _captainStatusTopic(restaurantId);
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      print('📡 POS subscribed to Captain status → $topic');

      await _captainSubscription?.cancel();
      if (_client!.updates == null) return;

      _captainSubscription = _client!.updates!.listen((messages) {
        for (final message in messages) {
          if (message.topic != topic) continue;

          final payload = message.payload;
          if (payload is! MqttPublishMessage) continue;

          final body = MqttPublishPayload.bytesToStringAsString(
            payload.payload.message,
          );

          try {
            final decoded = jsonDecode(body);
            if (decoded is! Map) continue;

            final map = Map<String, dynamic>.from(decoded);
            final event = map['event']?.toString() ?? '';

            print('========== POS RECEIVED FROM CAPTAIN ==========');
            print('Event      : $event');
            print('Table      : ${map['table_name']} (${map['table_id']})');
            print('Status     : ${map['table_status']}');
            print('================================================');

            _captainController.add(map);
          } catch (e) {
            print(' POS Captain parse error: $e');
          }
        }
      });
    } catch (e) {
      print('POS listenForCaptainUpdates failed: $e');
    }
  }

}