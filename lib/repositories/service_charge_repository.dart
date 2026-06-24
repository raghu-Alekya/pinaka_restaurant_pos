import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../models/service_charge_model.dart';

class ServiceChargeRepository {
  static const String baseUrl =
      "{AppConstants.baseApiPath}/wp-json/pinaka-restaurant-pos/v1/orders";

  /// Apply Service Charge
  Future<ServiceChargeResponse?> applyServiceCharge({
    required String token,
    required int orderId,
    required int percentage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          "${AppConstants.baseApiPath}/orders/update-service-charge",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "order_id": orderId,
          "service_charge_percentage": percentage,
        }),
      );

      if (response.statusCode == 200) {
        return ServiceChargeResponse.fromJson(
          jsonDecode(response.body),
        );
      }
    } catch (e) {
      print("Apply Service Charge Error: $e");
    }

    return null;
  }

  /// Delete Service Charge
  Future<ServiceChargeResponse?> deleteServiceCharge({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          "${AppConstants.baseApiPath}/orders/delete-service-charge",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "order_id": orderId,
        }),
      );

      if (response.statusCode == 200) {
        return ServiceChargeResponse.fromJson(
          jsonDecode(response.body),
        );
      }
    } catch (e) {
      print("Delete Service Charge Error: $e");
    }

    return null;
  }
}