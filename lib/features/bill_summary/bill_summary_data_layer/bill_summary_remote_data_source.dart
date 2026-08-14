import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../utils/api_exception_handler.dart';
import 'bill_summary_model.dart';

abstract class BillSummaryRemoteDataSource {
  Future<BillSummaryResponse> getBillSummary({
    required String baseUrl,
    required String token,
    required int orderId,
    required int restaurantId,
    required String orderType,
    required int zoneId,
  });
}

class BillSummaryRemoteDataSourceImpl implements BillSummaryRemoteDataSource {
  @override
  Future<BillSummaryResponse> getBillSummary({
    required String baseUrl,
    required String token,
    required int orderId,
    required int restaurantId,
    required String orderType,
    required int zoneId,
  }) async {
    try {
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/orders/get-order-items'
          '?order_id=$orderId&restaurant_id=$restaurantId&order_type=$orderType&zone_id=$zoneId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return BillSummaryResponse.fromJson(jsonData);
      } else {
        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage: 'Failed to load bill summary.',
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}