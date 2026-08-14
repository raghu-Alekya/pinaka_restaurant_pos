import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../utils/api_exception_handler.dart';
import 'kots_list_model.dart';

abstract class KotsListRemoteDataSource {
  Future<KotsListResponse> getKotsList({
    required String baseUrl,
    required String token,
    required int parentOrderId,
    required int restaurantId,
    required int zoneId,
  });
}

class KotsListRemoteDataSourceImpl implements KotsListRemoteDataSource {
  @override
  Future<KotsListResponse> getKotsList({
    required String baseUrl,
    required String token,
    required int parentOrderId,
    required int restaurantId,
    required int zoneId,
  }) async {
    try {
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/kot/get-parent-kot-orders'
          '?parent_order_id=$parentOrderId&restaurant_id=$restaurantId&zone_id=$zoneId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return KotsListResponse.fromJson(jsonData);
      } else {
        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage: 'Failed to fetch KOTs list.',
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}