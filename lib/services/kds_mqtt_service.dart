import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../utils/kds_logger.dart';

enum KdsConnectionState { disconnected, connecting, connected }

class KdsMqttService {
  KdsMqttService({
    required this.brokerHost,
    required this.brokerPort,
    required this.restaurantId,
  }) {
    KdsDebugLog.info(
      'MqttService created → broker=$brokerHost:$brokerPort restaurantId=$restaurantId',
    );
  }

  final String brokerHost;
  final int brokerPort;
  final String restaurantId;

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;
  Timer? _reconnectTimer;
  bool _listenerAttached = false;
  bool _intentionalDisconnect = false;

  final _incomingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController =
      StreamController<KdsConnectionState>.broadcast();

  Stream<Map<String, dynamic>> get messages => _incomingController.stream;
  Stream<KdsConnectionState> get connectionState =>
      _connectionController.stream;

  KdsConnectionState _state = KdsConnectionState.disconnected;
  KdsConnectionState get state => _state;

  String? lastError;
  int messagesReceived = 0;

  String get ordersTopic => 'store/$restaurantId/kitchen/orders';
  String get statusTopic => 'store/$restaurantId/kitchen/status';

  Future<void> connect() async {
    if (_state == KdsConnectionState.connecting) {
      KdsDebugLog.warn('connect() skipped — already connecting');
      return;
    }

    _reconnectTimer?.cancel();
    _setState(KdsConnectionState.connecting);
    lastError = null;

    try {
      _subscription?.cancel();
      _subscription = null;
      _listenerAttached = false;

      _intentionalDisconnect = true;
      _client?.disconnect();
      _intentionalDisconnect = false;

      final clientId = 'kds_${DateTime.now().millisecondsSinceEpoch}';
      KdsDebugLog.info('Connecting to $brokerHost:$brokerPort as $clientId');

      _client = MqttServerClient.withPort(brokerHost, clientId, brokerPort);
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = false;
      _client!.logging(on: kDebugMode);
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = (topic) {
        KdsDebugLog.info('Subscribed OK → $topic');
      };
      _client!.onSubscribeFail = (topic) {
        KdsDebugLog.error('Subscribe FAILED → $topic');
      };
      _client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();

      final status = await _client!.connect();

      if (status?.state != MqttConnectionState.connected) {
        lastError = 'Connect failed: ${status?.returnCode}';
        KdsDebugLog.error(lastError!);
        _setState(KdsConnectionState.disconnected);
        _scheduleReconnect();
        return;
      }

      KdsDebugLog.info('connect() returned connected');
      _subscribeAndListen();
    } catch (e, stack) {
      lastError = e.toString();
      KdsDebugLog.error('connect exception: $e');
      KdsDebugLog.error('stack: $stack');
      _setState(KdsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _onConnected() {
    KdsDebugLog.info('onConnected callback fired');
    _subscribeAndListen();
    _setState(KdsConnectionState.connected);
  }

  void _onDisconnected() {
    if (_intentionalDisconnect) {
      KdsDebugLog.info('onDisconnected ignored (intentional)');
      return;
    }
    KdsDebugLog.warn('onDisconnected callback fired');
    if (_state == KdsConnectionState.connecting) {
      KdsDebugLog.warn('onDisconnected ignored (connect in progress)');
      return;
    }
    _setState(KdsConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _subscribeAndListen() {
    if (_client == null) {
      KdsDebugLog.error('_subscribeAndListen: client is null');
      return;
    }

    KdsDebugLog.info('Subscribing to topic: $ordersTopic');
    _client!.subscribe(ordersTopic, MqttQos.atLeastOnce);

    if (_listenerAttached) return;

    if (_client!.updates == null) {
      KdsDebugLog.error('client.updates stream is NULL!');
      return;
    }

    _subscription = _client!.updates!.listen(
      _onMessages,
      onError: (e) => KdsDebugLog.error('updates stream error: $e'),
    );
    _listenerAttached = true;
    KdsDebugLog.info('Message listener attached');
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    KdsDebugLog.info('Received ${messages.length} MQTT packet(s)');

    for (final message in messages) {
      final topic = message.topic;
      KdsDebugLog.info('Raw topic="$topic" (expected="$ordersTopic")');

      if (topic != ordersTopic) {
        KdsDebugLog.warn('Topic mismatch — ignoring');
        continue;
      }

      final payload = message.payload;
      if (payload is! MqttPublishMessage) {
        KdsDebugLog.warn('Payload is not MqttPublishMessage: ${payload.runtimeType}');
        continue;
      }

      final body = MqttPublishPayload.bytesToStringAsString(
        payload.payload.message,
      );
      KdsDebugLog.info('Payload (${body.length} chars): ${body.length > 200 ? '${body.substring(0, 200)}...' : body}');

      try {
        final decoded = jsonDecode(body);
        if (decoded is! Map) {
          KdsDebugLog.warn('Decoded JSON is not a Map: ${decoded.runtimeType}');
          continue;
        }

        final map = Map<String, dynamic>.from(decoded);
        messagesReceived++;
        KdsDebugLog.info(
          'Parsed event="${map['event']}" kot=${map['kot']?['kot_number']} total=$messagesReceived',
        );
        _incomingController.add(map);
      } catch (e) {
        KdsDebugLog.error('JSON parse error: $e');
      }
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_state != KdsConnectionState.connected &&
          _state != KdsConnectionState.connecting) {
        KdsDebugLog.info('Auto-reconnecting...');
        connect();
      }
    });
  }

  void sendStatusUpdate({
    required int? kotId,
    required int? parentOrderId,
    required int? zoneId,
    required String kotNumber,
    required String status,
    String? zoneName,
    String? orderType,
    String? tableName,
    bool isCancelled = false,
  }) {
    if (_state != KdsConnectionState.connected || _client == null) {
      KdsDebugLog.warn('Cannot send status to POS — not connected');
      return;
    }

    final payload = {
      'event': 'kot_status_updated',
      'restaurant_id': restaurantId,
      'parent_order_id': parentOrderId,
      'zone_id': zoneId,
      'zone_name': zoneName ?? '',
      'order_type': orderType ?? '',
      'table_name': tableName ?? '',
      'kot_id': kotId,
      'kot_number': kotNumber,
      'status': status,
      'is_cancelled': isCancelled,
    };
    KdsDebugLog.info(
        'MQTT STATUS PAYLOAD => ${jsonEncode(payload)}'
    );

    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(payload));

    _client!.publishMessage(
      statusTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );

    KdsDebugLog.info('Sent status=$status for $kotNumber → $statusTopic');
  }

  void _setState(KdsConnectionState next) {
    if (_state != next) {
      KdsDebugLog.info('Connection state: $_state → $next');
    }
    _state = next;
    if (!_connectionController.isClosed) {
      _connectionController.add(next);
    }
  }

  void dispose() {
    KdsDebugLog.info('MqttService disposed');
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _client?.disconnect();
    _incomingController.close();
    _connectionController.close();
  }
}
