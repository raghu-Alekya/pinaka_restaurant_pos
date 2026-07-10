import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;


import '../models/void_kot.dart';
import '../utils/AppConstant.dart';

class VoidItemRepository {
  Future<KotLineItemsResponse> getKotLineItems({
    required int kotId,
    required int restaurantId,
    required int zoneId,
    required String token,
  }) async {
    final url = Uri.parse(
      "${AppConstants.baseApiPath}/orders/get-line-items"
          "?kot_id=$kotId&restaurant_id=$restaurantId&zone_id=$zoneId",
    );

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map && data.containsKey("data")) {
        return KotLineItemsResponse.fromJson(data["data"]);
      }

      return KotLineItemsResponse.fromJson(data);
    } else {
      throw Exception(
        "Failed to load KOT line items: ${response.body}",
      );
    }
  }
}

class UpdatekotRepository {
  Future<UpdatekotResponse> updatekot({
    required String token,
    required int kotId,
    required UpdatekotRequest request,
  }) async {
    final url = Uri.parse(
      "${AppConstants.baseApiPath}/orders/$kotId",
    );

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return UpdatekotResponse.fromJson(
        jsonDecode(response.body),
      );
    } else {
      debugPrint("❌ UPDATE URL: $url");
      debugPrint(
        "❌ UPDATE REQUEST: ${jsonEncode(request.toJson())}",
      );
      debugPrint(
        "❌ UPDATE RESPONSE: ${response.statusCode} ${response.body}",
      );

      throw Exception(
        "Update Order Failed: ${response.statusCode} ${response.body}",
      );
    }
  }
}