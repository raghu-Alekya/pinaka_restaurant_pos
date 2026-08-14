import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:restaurant_captain_app/features/variations/variations_data_layer/variation_model.dart';
import '../../../utils/api_exception_handler.dart';

abstract class VariationRemoteDataSource {
  Future<VariationsResponse> getVariations({
    required String baseUrl,
    required String token,
    required int productId,
  });
}

class VariationRemoteDataSourceImpl implements VariationRemoteDataSource {
  @override
  Future<VariationsResponse> getVariations({
    required String baseUrl,
    required String token,
    required int productId,
  }) async {
    try {
      final url = '$baseUrl/wp-json/wc/v3/products/$productId/variations';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        return VariationsResponse.fromJson(jsonData);
      } else {
        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage: 'Failed to load variations.',
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}