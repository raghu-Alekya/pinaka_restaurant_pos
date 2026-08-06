import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';

class StatusCountModel {
  final int restaurantId;
  final int queue;
  final int kitchenPreparing;
  final int kotReady;
  final int served;
  final int cancelled;
  final int totalDineInCount;
  final int totalTakeAwayCount;
  final String message;

  StatusCountModel({
    required this.restaurantId,
    required this.queue,
    required this.kitchenPreparing,
    required this.kotReady,
    required this.served,
    required this.cancelled,
    required this.totalDineInCount,
    required this.totalTakeAwayCount,
    required this.message,
  });

  factory StatusCountModel.fromJson(Map<String, dynamic> json) {
    return StatusCountModel(
      restaurantId: json['restaurant_id'] ?? 0,
      queue: json['queue'] ?? 0,
      kitchenPreparing: json['kitchen_preparing'] ?? 0,
      kotReady: json['kot_ready'] ?? 0,
      served: json['served'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      totalDineInCount: json['total_dinein_count'] ?? 0,
      totalTakeAwayCount: json['total_takeaway_count'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

class StatusCountRepository {
  final String baseUrl;

  StatusCountRepository({required this.baseUrl});

  Future<StatusCountModel> getStatusWiseCount({
    required String token,
    required String restaurantId,
  }) async {
    final url = Uri.parse(
      "${AppConstants.baseApiPath}/kot/get-status-wise-count?restaurant_id=$restaurantId",
    );

    debugPrint("========== KOT STATUS COUNT API ==========");
    debugPrint("URL: $url");
    debugPrint("Restaurant ID: $restaurantId");
    debugPrint("Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...");
    debugPrint("=========================================");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      debugPrint("Parsed JSON: $json");

      final model = StatusCountModel.fromJson(json);

      debugPrint("Queue: ${model.queue}");
      debugPrint("Kitchen Preparing: ${model.kitchenPreparing}");
      debugPrint("Ready: ${model.kotReady}");
      debugPrint("Served: ${model.served}");
      debugPrint("Cancelled: ${model.cancelled}");
      debugPrint("Dine-In: ${model.totalDineInCount}");
      debugPrint("Takeaways: ${model.totalTakeAwayCount}");

      return model;
    } else {
      debugPrint("API Error: ${response.body}");
      throw Exception(
        'Failed to fetch KOT status count: ${response.body}',
      );
    }
  }
}