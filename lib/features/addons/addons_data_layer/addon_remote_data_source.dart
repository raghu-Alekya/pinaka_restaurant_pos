import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/api_exception_handler.dart';
import 'addon_model.dart';

abstract class AddOnRemoteDataSource {
  Future<AddOnsResponse> getAddOnsByProduct({
    required String baseUrl,
    required String token,
    required int productId,
  });
}

class AddOnRemoteDataSourceImpl implements AddOnRemoteDataSource {
  @override
  Future<AddOnsResponse> getAddOnsByProduct({
    required String baseUrl,
    required String token,
    required int productId,
  }) async {
    try {
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/modifiers-addons/get-modifiers-by-product-id?product_id=$productId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AddOnsResponse.fromJson(jsonData);
      } else {
        throw Exception(
          ApiExceptionHandler.parseError(
            response,
            defaultMessage: 'Failed to load add-ons.',
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}