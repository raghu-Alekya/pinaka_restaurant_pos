import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;


import '../models/void_kot.dart';
import '../utils/AppConstant.dart';

class CancelItemRepository {
  Future<void> updateCancelItemStatus({
    required String token,
    required int parentId,
    required int orderId,
    required int restaurantId,
    required String orderType,
    int? zoneId,
    required List<int> itemIds,
  }) async {
    final url = Uri.parse(
      "${AppConstants.baseApiPath}/kot/update-cancel-item-status",
    );

    final Map<String, dynamic> body = {
      "parent_id": parentId,
      "order_id": orderId,
      "restaurant_id": restaurantId,
      "order_type": orderType,
      "items": itemIds,
    };

    if (zoneId != null) {
      body["zone_id"] = zoneId;
    }

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    debugPrint("URL      : $url");
    debugPrint("REQUEST  : ${jsonEncode(body)}");
    debugPrint("STATUS   : ${response.statusCode}");
    debugPrint("RESPONSE : ${response.body}");

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        "Cancel Item API Failed: ${response.statusCode}\n${response.body}",
      );
    }
  }
}