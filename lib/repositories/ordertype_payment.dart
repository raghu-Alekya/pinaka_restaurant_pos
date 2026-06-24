import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';
import '../models/ordertypes_model.dart';

// import '../models/OrderTypes_InPayment_Screen_Model.dart';

class OrderTypesInPaymentScreenRepository {
  Future<OrderTypesInPaymentScreenModel?> getOrderTypes({
    required String token,
  }) async {
    try {
      debugPrint("🔵 Calling Order Types API");
      debugPrint("🔵 Token: $token");

      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseApiPath}/kot/get-order-types',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("🟢 Status Code: ${response.statusCode}");
      debugPrint("🟢 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        debugPrint("🟢 Decoded JSON: $jsonData");

        final model = OrderTypesInPaymentScreenModel.fromJson(jsonData);

        debugPrint("🟢 Parsed Order Types: ${model.orderTypes}");

        return model;
      }

      debugPrint("🔴 API Failed: ${response.statusCode}");
      return null;
    } catch (e, stackTrace) {
      debugPrint("🔴 Repository Error: $e");
      debugPrint("$stackTrace");
      throw Exception('Failed to fetch order types: $e');
    }
  }
  Future<OrderTypesInPaymentScreenUpdateModel?> updateOrderType({
    required String token,
    required int orderId,
    required String orderType,
  }) async {
    try {
      final url =
          '${AppConstants.baseApiPath}/kot/update-order-type'
          '?order_id=$orderId'
          '&order_type=${Uri.encodeComponent(orderType)}';
      debugPrint("🔵 Updating Order Type");
      debugPrint("🔵 URL: $url");
      debugPrint("🔵 Order ID: $orderId");
      debugPrint("🔵 Order Type: $orderType");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("🟢 Update Status Code: ${response.statusCode}");
      debugPrint("🟢 Update Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return OrderTypesInPaymentScreenUpdateModel.fromJson(jsonData);
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint("🔴 Update Order Type Error: $e");
      debugPrint("$stackTrace");
      return null;
    }
  }

}