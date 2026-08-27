import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../kots_list_domin/kots_list_entity.dart';

class KdsMqttPublisher {
  // ─── MQTT client ──────────────────────────────────────────────
  static MqttServerClient? _client;
  static bool _connected = false;

  // ─── KOT status stream (existing) ─────────────────────────────
  static StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
  _statusSubscription;
  static final _statusController =
  StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get statusUpdates =>
      _statusController.stream;

  // ─── Table‑status stream (new) ────────────────────────────────
  static final _tableStatusController =
  StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get tableStatusUpdates =>
      _tableStatusController.stream;
  static StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
  _tableStatusSubscription;

  // ─── Broker configuration ──────────────────────────────────────
  static const String _brokerHost = String.fromEnvironment(
    'MQTT_BROKER_HOST',
    defaultValue: '178.16.140.169',
  );
  static const int _brokerPort = int.fromEnvironment(
    'MQTT_BROKER_PORT',
    defaultValue: 1883,
  );

  // ─── Topic helpers ─────────────────────────────────────────────
  static String _kitchenTopic(String restaurantId) =>
      'store/$restaurantId/kitchen/orders';
  static String _statusTopic(String restaurantId) =>
      'store/$restaurantId/kitchen/status';
  static String _tableStatusTopic(String restaurantId) =>
      'store/$restaurantId/table/status';

  // ─── Connect / ensure connected ──────────────────────────────
  static Future<void> _ensureConnected() async {
    // If already connected, return
    if (_connected &&
        _client?.connectionStatus?.state == MqttConnectionState.connected) {
      return;
    }

    // Recreate client if null or disconnected
    _client = MqttServerClient.withPort(
      _brokerHost,
      'pos_${DateTime.now().millisecondsSinceEpoch}',
      _brokerPort,
    )
      ..keepAlivePeriod = 60
      ..autoReconnect = true
      ..onConnected = () {
        print('✅ MQTT connected');
        _connected = true;
      }
      ..onDisconnected = () {
        print('⚠️ MQTT disconnected');
        _connected = false;
      };

    try {
      await _client!.connect();
      _connected =
          _client!.connectionStatus?.state == MqttConnectionState.connected;
      if (_connected) print('✅ MQTT connected successfully');
    } catch (e) {
      print('❌ MQTT connection failed: $e');
      _connected = false;
    }
  }

  // ─── Subscribe to KOT status updates (existing) ──────────────
  static Future<void> listenForKdsStatusUpdates({
    required String restaurantId,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) return;

      final topic = _statusTopic(restaurantId);
      _client!.subscribe(topic, MqttQos.atLeastOnce);

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
              '📥 KDS status update: kot=${map['kot_number']} status=${map['status']}',
            );
            _statusController.add(map);
          } catch (e) {
            print('❌ KDS status parse error: $e');
          }
        }
      });
    } catch (e) {
      print('❌ KDS status subscribe failed: $e');
    }
  }

  // ─── Subscribe to table‑status updates (new) ──────────────────
  static Future<void> listenForTableStatusUpdates({
    required String restaurantId,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) return;

      final topic = _tableStatusTopic(restaurantId);
      _client!.subscribe(topic, MqttQos.atLeastOnce);

      await _tableStatusSubscription?.cancel();
      if (_client!.updates == null) return;

      _tableStatusSubscription = _client!.updates!.listen((messages) {
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
            // Optional: filter by event if present
            // if (map['event'] != 'table_status_updated') continue;

            print(
              '📥 Table status update: table=${map['table_id']} status=${map['status']}',
            );
            _tableStatusController.add(map);
          } catch (e) {
            print('❌ Table status parse error: $e');
          }
        }
      });
    } catch (e) {
      print('❌ Table status subscribe failed: $e');
    }
  }

  // ─── Publish KOT created (existing) ──────────────────────────
  static Future<void> notifyKotCreated({
    required String restaurantId,
    required int parentOrderId,
    required int zoneId,
    required String zoneName,
    required String orderType,
    required KotOrder kot,
    String? tableName,
    String? tableId,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) return;

      final payload = {
        'event': 'kot_created',
        'restaurant_id': restaurantId,
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
        _kitchenTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      print('📤 KOT created published: ${kot.kotNumber}');
    } catch (e) {
      print('❌ MQTT publish failed: $e');
    }
  }

  // ─── Publish KOT status update (existing) ─────────────────────
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

      print('📤 Publishing KOT Status: ${jsonEncode(payload)}');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _statusTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } catch (e) {
      print('❌ Status publish failed: $e');
    }
  }

  // ─── NEW: Publish table status update ──────────────────────────
  static Future<void> publishTableStatus({
    required String restaurantId,
    required int tableId,
    required String status, // e.g. "Available", "Dine in", "Ready to Pay"
    int? orderId,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) {
        print('⚠️ Cannot publish: MQTT not connected');
        return;
      }

      final payload = {
        'event': 'table_status_updated',
        'restaurant_id': restaurantId,
        'table_id': tableId,
        'status': status,
        'order_id': orderId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📤 Publishing Table Status: ${jsonEncode(payload)}');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _tableStatusTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } catch (e) {
      print('❌ Table status publish failed: $e');
    }
  }

  // ─── Clean up resources ────────────────────────────────────────
  static void dispose() {
    _statusSubscription?.cancel();
    _tableStatusSubscription?.cancel();
    _statusController.close();
    _tableStatusController.close();
    _client?.disconnect();
    _client = null;
    _connected = false;
  }
}