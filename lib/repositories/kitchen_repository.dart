import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../utils/logger.dart';

class KitchenRepository {
  final String token;

  static List<String>? _cachedOrderTypes;
  static List<Map<String, dynamic>>? _cachedOrders;

  List<String>? get cachedOrderTypes => _cachedOrderTypes;
  List<Map<String, dynamic>>? get cachedOrders => _cachedOrders;

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
          final types = List<String>.from(data["order_types"]);
          _cachedOrderTypes = types;
          return types;
        }
      } else {
        AppLogger.warning("Failed to fetch order types: ${response.body}");
      }
    } catch (e) {
      AppLogger.error("Error fetching order types: $e");
    }
    return _cachedOrderTypes ?? [];
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
  /// Fetch orders with filters
  Future<List<Map<String, dynamic>>> fetchOrders({
    required String selectedOrderType,
    required String restaurantId,
    String? selectedArea,
    List<Map<String, dynamic>> zones = const [],
    Map<String, dynamic>? selectedUser,
  }) async {
    if (selectedOrderType.isEmpty || restaurantId.isEmpty) {
      AppLogger.warning(
        "Cannot fetch orders: Missing order type or restaurantId",
      );
      return _cachedOrders ?? [];
    }

    final normalizedOrderType =
    _normalizeOrderType(selectedOrderType);

    final isNonZoneOrderType =
        normalizedOrderType == "takeaways" ||
            normalizedOrderType == "takeaway" ||
            normalizedOrderType == "onlineorders" ||
            normalizedOrderType == "onlineorder" ||
            normalizedOrderType == "online" ||
            normalizedOrderType == "delivery";

    final params = <String, String>{
      "order_type": selectedOrderType,
      "restaurant_id": restaurantId,
    };

    // ------------------------------------------------------------
    // ADD ZONE ONLY FOR ZONE-BASED ORDER TYPES
    // ------------------------------------------------------------
    if (!isNonZoneOrderType &&
        selectedArea != null &&
        selectedArea != "All") {
      final zone = zones.firstWhere(
            (z) => z['zone_name'] == selectedArea,
        orElse: () => <String, dynamic>{},
      );

      final zoneId = zone['id'] ?? zone['zone_id'];

      if (zoneId != null) {
        params["zone_id"] = zoneId.toString();
      }
    }

    // ------------------------------------------------------------
    // USER FILTER
    // ------------------------------------------------------------
    if (selectedUser != null) {
      final userId =
          selectedUser['ID'] ?? selectedUser['id'];

      if (userId != null) {
        params["user_id"] = userId.toString();
      }
    }

    final url = Uri.parse(
      AppConstants.getAllOrdersEndpoint,
    ).replace(
      queryParameters: params,
    );

    AppLogger.debug(
      "🔥 FETCH ORDERS"
          "\n   Selected Type: '$selectedOrderType'"
          "\n   Normalized Type: '$normalizedOrderType'"
          "\n   Is Non-Zone: $isNonZoneOrderType"
          "\n   Selected Area: '$selectedArea'"
          "\n   Params: $params"
          "\n   URL: $url",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      AppLogger.debug(
        "🔥 FETCH ORDERS RESPONSE"
            "\n   Status: ${response.statusCode}"
            "\n   Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
        jsonDecode(response.body);

        final orders =
        List<Map<String, dynamic>>.from(data);

        // Make sure the selected type is preserved
        // when the API response doesn't provide it.
        for (final order in orders) {
          final existingType =
          (order['order_type'] ?? '')
              .toString()
              .trim();

          if (existingType.isEmpty) {
            order['order_type'] =
                selectedOrderType;
          }
        }

        _cachedOrders = orders;

        AppLogger.debug(
          "🔥 FETCH ORDERS SUCCESS"
              "\n   Type: '$selectedOrderType'"
              "\n   Count: ${orders.length}",
        );

        return orders;
      } else {
        AppLogger.warning(
          "Failed to fetch orders: ${response.body}",
        );
      }
    } catch (e) {
      AppLogger.error(
        "Error fetching orders: $e",
      );
    }

    return _cachedOrders ?? [];
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
