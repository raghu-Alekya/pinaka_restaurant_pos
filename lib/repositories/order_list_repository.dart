import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../models/order_list/order_list_model.dart';
// import '../models/orderslist/orders_list_model.dart';
import '../utils/logger.dart';

class OrderstatusRepository {

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

        if (jsonResponse is List) {
          orders = jsonResponse
              .map((e) => OrderlistModel.fromJson(e))
              .toList();
        } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
          orders = (jsonResponse['data'] as List)
              .map((e) => OrderlistModel.fromJson(e))
              .toList();
        } else {
          AppLogger.error('Unexpected JSON format');
        }

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