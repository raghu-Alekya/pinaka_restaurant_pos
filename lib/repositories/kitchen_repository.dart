import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../utils/logger.dart';

class KitchenRepository {
  final String token;

  KitchenRepository({required this.token});

  /// Fetch all order types
  Future<List<String>> fetchOrderTypes() async {
    final url = Uri.parse(AppConstants.getAllOrderTypesEndpoint);
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );
      AppLogger.debug("Order types response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["order_types"] != null) {
          return List<String>.from(data["order_types"]);
        }
      } else {
        AppLogger.warning("Failed to fetch order types: ${response.body}");
      }
    } catch (e) {
      AppLogger.error("Error fetching order types: $e");
    }
    return [];
  }

  /// Fetch all users
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final url = Uri.parse(AppConstants.getAllUsersEndpoint);
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        AppLogger.warning("Failed to fetch users: ${response.body}");
      }
    } catch (e) {
      AppLogger.error("Error fetching users: $e");
    }
    return [];
  }

  /// Fetch orders with filters
  Future<List<Map<String, dynamic>>> fetchOrders({
    required String selectedOrderType,
    required String restaurantId,
    String? selectedArea,
    List<Map<String, dynamic>> zones = const [],
    Map<String, dynamic>? selectedUser,
  }) async {
    if (selectedOrderType.isEmpty || restaurantId.isEmpty) {
      AppLogger.warning("Cannot fetch orders: Missing order type or restaurantId");
      return [];
    }

    final params = {
      "order_type": selectedOrderType,
      "restaurant_id": restaurantId,
    };

    if (_normalizeOrderType(selectedOrderType) != "takeaways") {
      if (selectedArea != null) {
        final zone = zones.firstWhere(
              (z) => z['zone_name'] == selectedArea,
          orElse: () => {},
        );
        final zoneId = zone['id'] ?? zone['zone_id'];
        if (zoneId != null) {
          params["zone_id"] = zoneId.toString();
        }
      }
    }

    if (selectedUser != null) {
      final userId = selectedUser['ID'] ?? selectedUser['id'];
      if (userId != null) {
        params["user_id"] = userId.toString();
      }
    }

    final url = Uri.parse(AppConstants.getAllOrdersEndpoint).replace(queryParameters: params);
    AppLogger.debug("Fetching orders -> $url");

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      AppLogger.debug("Fetch orders response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        AppLogger.warning("Failed to fetch orders: ${response.body}");
      }
    } catch (e) {
      AppLogger.error("Error fetching orders: $e");
    }
    return [];
  }

  /// Fetch parent KOT orders
  Future<List<Map<String, dynamic>>> fetchParentKotOrders({
    required String restaurantId,
    required String parentOrderId,
    required String orderType,
    String? zoneId,
    Map<String, dynamic>? selectedUser,
  }) async {
    final params = {
      "parent_order_id": parentOrderId,
      "restaurant_id": restaurantId,
      "order_type": orderType,
      if (zoneId != null) "zone_id": zoneId,
      if (selectedUser != null)
        "user_id": (selectedUser['ID'] ?? selectedUser['id']).toString(),
    };

    final url = Uri.parse(AppConstants.getParentKotOrdersEndpoint)
        .replace(queryParameters: params);

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      AppLogger.debug("KOT API raw response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final kotOrders = data['parent_order']?['kot_orders'] ?? [];
        return List<Map<String, dynamic>>.from(kotOrders);
      } else {
        AppLogger.warning(
          "Failed to fetch KOTs: ${response.statusCode} -> ${response.body}",
        );
      }
    } catch (e) {
      AppLogger.error("Error fetching KOTs: $e");
    }

    return [];
  }

  String _normalizeOrderType(String type) {
    return type.toLowerCase().replaceAll(" ", "");
  }
}