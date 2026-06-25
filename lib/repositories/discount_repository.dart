import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../models/payment/discount_model.dart';
import '../services/api_exception.dart';

class DiscountReasonRepository {
  String get baseUrl =>
      '${AppConstants.baseApiPath}/orders/discount-reasons';

  /// ✅ Single source of truth
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("JWT token missing");
    }

    return token.startsWith('Bearer ')
        ? token.substring(7)
        : token;
  }

  Future<DiscountReasonResponse> fetchDiscountReasons() async {
    if (kDebugMode) {
      print('📤 [DiscountReasonRepository] API CALL STARTED');
      print('➡️ URL: $baseUrl');
    }

    final token = await _getToken();

    if (kDebugMode) {
      print("🔐 CLEAN TOKEN => $token");
      print("🔐 HEADER     => Bearer $token");
    }

    final response = await ApiExceptionHandler.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return DiscountReasonResponse.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      ApiExceptionHandler.parseError(
        response,
        defaultMessage: "Unable to load discount reasons.",
      ),
    );
  }
}
// repositories/discount_repository.dart



class AddDiscountRepository {
  String get baseUrl =>
      AppConstants.baseApiPath;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("JWT token missing");
    }

    return token.startsWith('Bearer ')
        ? token.substring(7)
        : token;
  }

  Future<AddDiscountResponse> addDiscount({
    required AddDiscountRequest request,
  }) async {
    final token = await _getToken(); // ✅ SINGLE SOURCE

    final url = "$baseUrl/orders/add-discount";

    print('➡️ [ADD DISCOUNT API]');
    print('➡️ URL: $url');
    print('➡️ REQUEST BODY: ${jsonEncode(request.toJson())}');

    final response = await ApiExceptionHandler.post(
      Uri.parse("$baseUrl/orders/add-discount"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return AddDiscountResponse.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      ApiExceptionHandler.parseError(
        response,
        defaultMessage: "Unable to apply discount.",
      ),
    );
  }
}
class RemoveDiscountRepository {
  String get baseUrl =>
      AppConstants.baseApiPath;
  /// ✅ Single source of truth
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("JWT token missing");
    }

    return token.startsWith('Bearer ') ? token.substring(7) : token;
  }

  Future<RemoveDiscountResponseModel> removeDiscount({
    required int orderId,
    required String isNc, // "yes" or "no"
  }) async {
    final token = await _getToken();

    final url = Uri.parse("$baseUrl/orders/remove-discount");

    print("➡️ [REMOVE DISCOUNT API]");
    print("➡️ URL: $url");
    print("➡️ BODY: ${jsonEncode({"order_id": orderId, "is_nc": isNc})}");

    final response = await ApiExceptionHandler.post(
      Uri.parse("$baseUrl/orders/remove-discount"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "order_id": orderId,
        "is_nc": isNc,
      }),
    );

    if (response.statusCode == 200) {
      return RemoveDiscountResponseModel.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      ApiExceptionHandler.parseError(
        response,
        defaultMessage: "Unable to remove discount.",
      ),
    );
  }
}
