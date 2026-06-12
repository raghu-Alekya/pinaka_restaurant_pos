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

  static String _topic(String restaurantId) =>
      'store/$restaurantId/kitchen/orders';

  static String _statusTopic(String restaurantId) =>
      'store/$restaurantId/kitchen/status';

  static Future<void> _ensureConnected() async {
    if (_connected &&
        _client?.connectionStatus?.state == MqttConnectionState.connected) {
      return;
    }

    _client = MqttServerClient.withPort(
      _brokerHost,
      'pos_${DateTime.now().millisecondsSinceEpoch}',
      _brokerPort,
    )
      ..keepAlivePeriod = 60
      ..autoReconnect = true;

    await _client!.connect();
    _connected =
        _client!.connectionStatus?.state == MqttConnectionState.connected;
  }

  /// Subscribe to KDS status updates for this restaurant.
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
              'KDS status update: kot=${map['kot_number']} status=${map['status']}',
            );
            _statusController.add(map);
          } catch (e) {
            print('KDS status parse error: $e');
          }
        }
      });
    } catch (e) {
      print('KDS status subscribe failed: $e');
    }
  }

  static Future<void> notifyKotCreated({
    required String restaurantId,
    required int parentOrderId,
    required int zoneId,
    required String zoneName,      // add
    required String orderType,
    required KotModel kot,
    String? tableName,
    String? tableId,               // optional
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) return;

      final payload = {
        'event': 'kot_created',
        'restaurant_id': restaurantId,
        'parent_order_id': parentOrderId,
        'zone_id': zoneId,
        'zone_name': zoneName,           // add
        'order_type': orderType,
        'table_name': tableName ?? '',
        'table_id': tableId ?? '',       // optional
        'kot': kot.toJson(),
      };

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _topic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } catch (e) {
      print('MQTT publish failed: $e');
    }
  }
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

      print('Publishing Status: ${jsonEncode(payload)}');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _statusTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } catch (e) {
      print('Status publish failed: $e');
    }
  }
}