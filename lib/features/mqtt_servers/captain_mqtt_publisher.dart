import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class CaptainMqttPublisher {
  static MqttServerClient? _client;
  static bool _connected = false;

  static const String _brokerHost = '178.16.140.169';
  static const int _brokerPort = 1883;

  static String _statusTopic(String restaurantId) =>
      'store/$restaurantId/captain/status';

  static Future<void> _ensureConnected() async {
    if (_connected &&
        _client?.connectionStatus?.state == MqttConnectionState.connected) {
      return;
    }

    final clientId =
        'cap_pub_${DateTime.now().millisecondsSinceEpoch % 1000000}';

    print('🔌 CaptainMqttPublisher connecting as $clientId');

    _client = MqttServerClient.withPort(_brokerHost, clientId, _brokerPort)
      ..keepAlivePeriod = 60
      ..autoReconnect = true;

    try {
      await _client!.connect();
      _connected =
          _client!.connectionStatus?.state == MqttConnectionState.connected;
      print(_connected
          ? '✅ CaptainMqttPublisher connected'
          : '❌ CaptainMqttPublisher connect failed');
    } catch (e) {
      print('❌ CaptainMqttPublisher connect error: $e');
      _connected = false;
    }
  }

  static Future<void> notifyOrderCreated({
    required String restaurantId,
    required int orderId,
    required String orderType,
    required int tableId,
    required String tableName,
    required int zoneId,
    required String zoneName,
    int? guestCount,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) {
        print('⚠️ Cannot publish: MQTT not connected');
        return;
      }

      final payload = {
        'event': 'order_created',
        'restaurant_id': restaurantId,
        'parent_order_id': orderId,
        'order_type': orderType,
        'table_id': tableId.toString(),
        'table_name': tableName,
        'zone_id': zoneId,
        'zone_name': zoneName,
        'guest_count': guestCount,
        'status': 'occupied',
        'table_status': 'Occupied',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== CAPTAIN → POS order_created ==========');
      print('Topic  : ${_statusTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _statusTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('✅ Captain published order_created to POS');
    } catch (e, stack) {
      print('❌ Captain publish order_created failed: $e');
      print(stack);
    }
  }

  static Future<void> notifyKotPrinted({
    required String restaurantId,
    required int orderId,
    required String orderType,
    required int zoneId,
    String? zoneName,
    String? tableName,
    String? tableId,
    String? kotNumber,
    int? kotId,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) {
        print('⚠️ Cannot publish kot_printed: MQTT not connected');
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
        'table_status': 'Running',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== CAPTAIN → POS kot_printed ==========');
      print('Topic  : ${_statusTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('==============================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _statusTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('✅ Captain published kot_printed to POS');
    } catch (e, stack) {
      print('❌ Captain publish kot_printed failed: $e');
      print(stack);
    }
  }

  static Future<void> notifyBillGenerated({
    required String restaurantId,
    required int orderId,
    required String orderType,
    required int zoneId,
    String? zoneName,
    String? tableName,
    String? tableId,
    double? netTotal,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) {
        print('⚠️ Cannot publish bill_generated: MQTT not connected');
        return;
      }

      final payload = {
        'event': 'bill_generated',
        'restaurant_id': restaurantId,
        'parent_order_id': orderId,
        'order_type': orderType,
        'zone_id': zoneId,
        'zone_name': zoneName ?? '',
        'table_name': tableName ?? '',
        'table_id': tableId ?? '',
        'net_total': netTotal,
        'status': 'ready_to_pay',
        'table_status': 'Ready to Pay',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== CAPTAIN → POS bill_generated ==========');
      print('Topic  : ${_statusTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('=================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _statusTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('✅ Captain published bill_generated to POS');
    } catch (e, stack) {
      print('❌ Captain publish bill_generated failed: $e');
      print(stack);
    }
  }
  static Future<void> notifyMenuStockUpdated({
    required String restaurantId,
    required List<Map<String, dynamic>> products,
    // each item: { 'product_id': int, 'old_status': 'instock'|'outofstock', 'new_status': 'instock'|'outofstock' }
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) {
        print('⚠️ Cannot publish menu_stock_updated: MQTT not connected');
        return;
      }

      final payload = {
        'event': 'menu_stock_updated',
        'restaurant_id': restaurantId,
        'products': products,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== CAPTAIN → POS menu_stock_updated ==========');
      print('Topic  : ${_statusTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('======================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _statusTopic(restaurantId),
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('✅ Captain published menu_stock_updated to POS');
    } catch (e, stack) {
      print('❌ Captain publish menu_stock_updated failed: $e');
      print(stack);
    }
  }

  static Future<void> notifyOrderCancelled({
    required String restaurantId,
    required int orderId,
    required String orderType,
    int? zoneId,
    String? zoneName,
    String? tableName,
    String? tableId,
  }) async {
    try {
      await _ensureConnected();
      if (!_connected || _client == null) {
        print('⚠️ Cannot publish order_cancelled: MQTT not connected');
        return;
      }

      final payload = {
        'event': 'order_cancelled',
        'restaurant_id': restaurantId,
        'parent_order_id': orderId,
        'order_type': orderType,
        'zone_id': zoneId,
        'zone_name': zoneName ?? '',
        'table_name': tableName ?? '',
        'table_id': tableId ?? '',
        'status': 'cancelled',
        'table_status': 'Available',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('========== CAPTAIN → POS order_cancelled ==========');
      print('Topic  : ${_statusTopic(restaurantId)}');
      print('Payload: ${jsonEncode(payload)}');
      print('==================================================');

      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));

      _client!.publishMessage(
        _statusTopic(restaurantId), // store/{id}/captain/status
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('✅ Captain published order_cancelled to POS');
    } catch (e, stack) {
      print('❌ Captain order_cancelled publish failed: $e');
      print(stack);
    }
  }

}