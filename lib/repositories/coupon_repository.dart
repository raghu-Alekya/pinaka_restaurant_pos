import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../models/order/coupon_model.dart';

class CouponRepository {
  String get couponUrl =>
      '${AppConstants.baseDomain}/wp-json/wc/v3/coupons';

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

  // Future<List<CouponModel>> fetchCoupons() async {
  //   try {
  //     final token = await _getToken();
  //
  //     final url = "$baseUrl"; // <-- update endpoint if needed
  //
  //     if (kDebugMode) {
  //       print("📤 [COUPON API]");
  //       print("➡️ URL: $url");
  //     }
  //
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         "Authorization": "Bearer $token",
  //         "Content-Type": "application/json",
  //         "Accept": "application/json",
  //       },
  //     );
  //
  //     if (kDebugMode) {
  //       print("⬅️ STATUS CODE: ${response.statusCode}");
  //       print("⬅️ RESPONSE BODY: ${response.body}");
  //     }
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> jsonData =
  //       jsonDecode(response.body);
  //
  //       return jsonData
  //           .map((e) => CouponModel.fromJson(e))
  //           .toList();
  //     }
  //
  //     throw Exception(
  //       "Failed to load coupons (${response.statusCode})",
  //     );
  //   } catch (e) {
  //     debugPrint("❌ Error fetching coupons: $e");
  //     return [];
  //   }
  // }



  Future<CouponResponse> applyCoupon({
    required String token,
    required int orderId,
    required String couponCode,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseApiPath}/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "coupon_lines": [
            {
              "code": couponCode,
            }
          ]
        }),
      );

      debugPrint('Apply Coupon Status: ${response.statusCode}');
      debugPrint('Apply Coupon Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return CouponResponse(
          success: true,
          message: "Coupon applied successfully.",
          couponAmount: (data["coupon_amount"] as num?)?.toDouble() ?? 0.0,
        );
      } else {
        return CouponResponse(
          success: false,
          message: data["message"] ?? "Failed to apply coupon.",
          couponAmount: 0.0,
        );
      }
    } catch (e) {
      return CouponResponse(
        success: false,
        message: "Something went wrong. Please try again.",
        couponAmount: 0.0,
      );
    }
  }

  Future<bool> removeCoupon({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${AppConstants.baseApiPath}/orders/$orderId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "coupon_lines": [
            {
              "code": "",
              "remove": true,
            }
          ]
        }),
      );

      debugPrint("Remove Coupon Status: ${response.statusCode}");
      debugPrint("Remove Coupon Response: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Remove Coupon Error: $e");
      return false;
    }
  }
}