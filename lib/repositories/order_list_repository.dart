import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../models/order_list/edit_order_list_model.dart';
import '../models/order_list/order_list_model.dart';
import '../utils/logger.dart';

class OrderstatusRepository {
  /// Fetch all orders with detailed KOT and line item info
  Future<List<OrderlistModel>> fetchOrders(String token, {String? date}) async {
    var urlStr = AppConstants.getAllOrdersList;
    if (date != null) {
      urlStr += '?date=$date';
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
      AppLogger.info('Order API Response: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);

        List<OrderlistModel> orders = [];

        List<dynamic> dataList = [];

        if (jsonResponse is List) {
          dataList = jsonResponse;
        } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
          dataList = jsonResponse['data'] as List;
        } else {
          AppLogger.error('Unexpected JSON format');
        }

        orders = dataList.map((orderJson) {
          final order = OrderlistModel.fromJson(orderJson);

          // Log each KOT and line item
          if (order.kotOrders != null && order.kotOrders!.isNotEmpty) {
            for (var kot in order.kotOrders!) {
              AppLogger.info('📌 KOT ID: ${kot.kotOrderId}');
              if (kot.lineItems != null && kot.lineItems!.isNotEmpty) {
                for (var item in kot.lineItems!) {
                  AppLogger.info(
                      '   Line Item ID: ${item.lineItemId}, Product ID: ${item.itemId}, Name: ${item.name}, Qty: ${item.quantity}, Price: ${item.itemPrice}, Modifiers: ${item.modifiers}');
                }
              } else {
                AppLogger.info('   No line items in this KOT');
              }
            }
          } else {
            AppLogger.info('No KOTs for Order ID: ${order.orderId}');
          }

          return order;
        }).toList();

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

    return [];
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