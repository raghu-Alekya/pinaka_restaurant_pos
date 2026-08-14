import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../utils/api_exception_handler.dart';
import 'order_by_table_model.dart';

abstract class OrderByTableRemoteDataSource {
  Future<OrderByTableResponse> getOrderByTable({
    required String baseUrl,
    required String token,
    required int restaurantId,
    required int tableId,
    required int zoneId,
  });
}

class OrderByTableRemoteDataSourceImpl implements OrderByTableRemoteDataSource {
  @override
  Future<OrderByTableResponse> getOrderByTable({
    required String baseUrl,
    required String token,
    required int restaurantId,
    required int tableId,
    required int zoneId,
  }) async {
    try {
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/kot/get-order-by-table'
          '?restaurant_id=$restaurantId&table_id=$tableId&zone_id=$zoneId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return OrderByTableResponse.fromJson(jsonData);
      } else {
        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage: 'Failed to get order for this table.',
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}