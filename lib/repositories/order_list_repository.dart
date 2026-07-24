import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../models/order_list/edit_order_list_model.dart';
import '../models/order_list/order_list_model.dart';
import '../utils/logger.dart';

List<OrderlistModel> _parseOrdersJson(String responseBody) {
  final dynamic jsonResponse = jsonDecode(responseBody);
  List<dynamic> dataList = [];

  if (jsonResponse is List) {
    dataList = jsonResponse;
  } else if (jsonResponse is Map<String, dynamic>) {
    if (jsonResponse.containsKey('orders')) {
      dataList = jsonResponse['orders'] as List<dynamic>;
    } else if (jsonResponse.containsKey('data')) {
      dataList = jsonResponse['data'] as List<dynamic>;
    } else {
      return [];
    }
  }
  return dataList.map((orderJson) => OrderlistModel.fromJson(orderJson)).toList();
}

class OrderstatusRepository {
  static final Map<String, List<OrderlistModel>> _cache = {};

  List<OrderlistModel>? getCachedOrders(String cacheKey) {
    return _cache[cacheKey];
  }

  /// Fetch all orders with detailed KOT and line item info
  Future<List<OrderlistModel>> fetchOrders(String token, {String? date, String? restaurantId}) async {
    final cacheKey = "${restaurantId ?? ''}_${date ?? ''}";
    var urlStr = AppConstants.getAllOrdersList;
    List<String> queryParams = [];
    if (restaurantId != null && restaurantId.isNotEmpty) {
      queryParams.add('restaurant_id=$restaurantId');
    }
    if (date != null && date.isNotEmpty) {
      queryParams.add('date=$date');
    }
    if (queryParams.isNotEmpty) {
      urlStr += '?${queryParams.join('&')}';
    }
    final uri = Uri.parse(urlStr);

    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      AppLogger.info('Order API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final orders = await compute(_parseOrdersJson, response.body);
        _cache[cacheKey] = orders;
        AppLogger.info('Fetched ${orders.length} orders successfully');
        return orders;
      } else {
        AppLogger.error(
          'Failed to fetch orders. Status: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in fetchOrders: $e\n$stackTrace',
      );
    }

    return _cache[cacheKey] ?? [];
  }
  Future<VoidedItemsResponse> fetchVoidedItems({
    required int kotOrderId,
    required String token,
  }) async {
    try {
      final url =
          'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/orders/voided-items?order_id=$kotOrderId';

      AppLogger.info('[FETCH VOIDED ITEMS] URL => $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      AppLogger.info('[FETCH VOIDED ITEMS] STATUS => ${response.statusCode}');
      AppLogger.info('[FETCH VOIDED ITEMS] RESPONSE => ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('items')) {
          for (var item in data['items']) {
            AppLogger.info(
              'LogID: ${item['log_id']}, '
                  'ItemID: ${item['item_id']}, '
                  'Product: ${item['product']}, '
                  'OrigQty: ${item['orig_qty']} → NewQty: ${item['new_qty']}, '
                  'Total: ${item['item_total']}',
            );
          }
        }

        return VoidedItemsResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to fetch voided items (status: ${response.statusCode})',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Fetch voided items error: $e\n$stackTrace',
      );
      rethrow;
    }
  }
}