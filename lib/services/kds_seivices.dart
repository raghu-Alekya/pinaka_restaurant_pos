import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/order/KOT_model.dart';

class KdsMqttPublisher {
  static MqttServerClient? _client;
  static bool _connected = false;

  static const String _brokerHost = String.fromEnvironment(
    'MQTT_BROKER_HOST',
    defaultValue: '172.18.7.80',
  );
  static const int _brokerPort = int.fromEnvironment(
    'MQTT_BROKER_PORT',
    defaultValue: 1883,
  );

  static String _topic(String restaurantId) =>
      'store/$restaurantId/kitchen/orders';

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
}