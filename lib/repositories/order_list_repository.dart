import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../models/order_list/order_list_model.dart';
import '../utils/logger.dart';

class OrderstatusRepository {
  /// Fetch all orders with detailed KOT and line item info
  Future<List<OrderlistModel>> fetchOrders(String token) async {
    final uri = Uri.parse(AppConstants.getAllOrdersList);

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
}