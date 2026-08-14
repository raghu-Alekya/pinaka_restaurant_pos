import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/api_exception_handler.dart';

abstract class TransferKotRemoteDataSource {
  Future<void> transferKot({
    required String baseUrl,
    required String token,
    required int orderId,
    required int kotId,
    required int fromTableId,
    required int toTableId,
    required int restaurantId,
    required int zoneId,
  });
}

class TransferKotRemoteDataSourceImpl implements TransferKotRemoteDataSource {
  @override
  Future<void> transferKot({
    required String baseUrl,
    required String token,
    required int orderId,
    required int kotId,
    required int fromTableId,
    required int toTableId,
    required int restaurantId,
    required int zoneId,
  }) async {
    try {
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/kot/kot-transfer';
      final body = {
        'order_id': orderId,
        'kot_id': kotId,
        'from_table_id': fromTableId,
        'to_table_id': toTableId,
        'restaurant_id': restaurantId,
        'zone_id': zoneId,
      };
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage: 'Failed to transfer KOT.',
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}