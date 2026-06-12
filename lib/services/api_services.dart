import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/kitchen_order.dart';
import '../utils/kds_logger.dart';

class OrderApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;

  const OrderApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  @override
  String toString() =>
      'OrderApiException($statusCode): $message${body != null ? ' | $body' : ''}';
}

class KotApiStatus {
  static const preparing = 'preparing';
  static const ready = 'ready';
  static const served = 'served';
  static const cancelled = 'cancelled';
  static const kotProcessed = 'Yet To Prepare';

  static String fromLocal(String localStatus) {
    switch (localStatus.trim().toLowerCase()) {
      case 'cancel':
      case 'cancelled':
        return cancelled;

      case 'recall':
      case 'kot-processed':
        return kotProcessed;

      case 'preparing':
        return preparing;

      case 'ready':
        return ready;

      case 'served':
        return served;

      default:
        return localStatus.trim().toLowerCase();
    }
  }
}

class OrderApiService {
  OrderApiService({
    required this.getToken,
    this.restaurantId = 1,
    this.baseUrl =
    'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final Future<String?> Function() getToken;
  final int restaurantId;
  final String baseUrl;
  final http.Client _client;

  static const _flagUpdateKotStatus = 'update_kot_order_status';

  //─────────────────────────────────────────────
  // Status Actions
  //─────────────────────────────────────────────

  Future<Map<String, dynamic>> startOrder(KitchenOrder order) {
    return _updateStatus(order, KotApiStatus.preparing);
  }

  Future<Map<String, dynamic>> cancelOrder(KitchenOrder order) {
    return _updateStatus(order, KotApiStatus.cancelled);
  }

  Future<Map<String, dynamic>> recallOrder(KitchenOrder order) {
    return _updateStatus(order, KotApiStatus.kotProcessed);
  }

  Future<Map<String, dynamic>> markReady(KitchenOrder order) {
    return _updateStatus(order, KotApiStatus.ready);
  }

  Future<Map<String, dynamic>> markServed(KitchenOrder order) {
    return _updateStatus(order, KotApiStatus.served);
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      KitchenOrder order,
      String localStatus,
      ) {
    return _updateStatus(
      order,
      KotApiStatus.fromLocal(localStatus),
    );
  }

  //─────────────────────────────────────────────
  // Main API Call
  //─────────────────────────────────────────────

  Future<Map<String, dynamic>> updateKotOrderStatus({
    required int orderId,
    required int parentId,
    required int zoneId,
    required int restaurantId,
    required String status,
  }) async {
    final token = await _requireToken();

    final url = Uri.parse('$baseUrl/orders/$orderId');

    final payload = {
      'flag_type': _flagUpdateKotStatus,
      'restaurant_id': restaurantId,
      'zone_id': zoneId,
      'parent_id': parentId,
      'status': KotApiStatus.fromLocal(status),
    };

    KdsDebugLog.info('PUT $url');
    KdsDebugLog.info('Payload => $payload');

    final response = await _client.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    return _parseResponse(response);
  }

  void dispose() {
    _client.close();
  }

  //─────────────────────────────────────────────
  // Helpers
  //─────────────────────────────────────────────

  Future<Map<String, dynamic>> _updateStatus(
      KitchenOrder order,
      String apiStatus,
      ) {
    return updateKotOrderStatus(
      orderId: _requireKotId(order),
      parentId: _requireParentOrderId(order),
      zoneId: _requireZoneId(order),
      restaurantId: restaurantId,
      status: apiStatus,
    );
  }

  Future<String> _requireToken() async {
    final token = await getToken();

    KdsDebugLog.info('Retrieved token: $token');

    if (token == null || token.trim().isEmpty) {
      throw const OrderApiException(
        statusCode: 401,
        message: 'Missing auth token',
      );
    }

    return token.trim();
  }

  int _requireKotId(KitchenOrder order) {
    final kotId = order.kotId;

    if (kotId == null || kotId <= 0) {
      throw OrderApiException(
        statusCode: 0,
        message: 'Missing kotId for order ${order.id}',
      );
    }

    return kotId;
  }

  int _requireParentOrderId(KitchenOrder order) {
    final parentId = order.parentOrderId;

    if (parentId == null || parentId <= 0) {
      throw OrderApiException(
        statusCode: 0,
        message: 'Missing parentOrderId for order ${order.id}',
      );
    }

    return parentId;
  }

  int _requireZoneId(KitchenOrder order) {
    final zoneId = order.zoneId;

    if (zoneId == null || zoneId <= 0) {
      throw OrderApiException(
        statusCode: 0,
        message: 'Missing zoneId for order ${order.id}',
      );
    }

    return zoneId;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final statusCode = response.statusCode;
    final rawBody = response.body.trim();

    Map<String, dynamic>? jsonBody;

    if (rawBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);

        if (decoded is Map<String, dynamic>) {
          jsonBody = decoded;
        }
      } catch (_) {}
    }

    if (statusCode < 200 || statusCode >= 300) {
      final message =
          jsonBody?['message']?.toString() ??
              jsonBody?['error']?.toString() ??
              'Request failed';

      KdsDebugLog.error('API failed: $statusCode');
      KdsDebugLog.error(rawBody);

      throw OrderApiException(
        statusCode: statusCode,
        message: message,
        body: rawBody.isEmpty ? null : rawBody,
      );
    }

    KdsDebugLog.info('API success: $statusCode');
    KdsDebugLog.info('Response Status Code: ${response.statusCode}');
    KdsDebugLog.info('Response Body: ${response.body}');
    return jsonBody ?? {'success': true};
  }
}