import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';

class DashboardRepository {
  final String token;
  final String restaurantId;

  DashboardRepository({
    required this.token,
    required this.restaurantId,
  });

  Future<Map<String, dynamic>> fetchDashboardData({
    required String selectedPeriod,
    Map<String, dynamic>? selectedZone,
  }) async {
    try {
      final url = Uri.parse(
        "https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/merchant-dashboard/get-revenue-by-filters"
            "?restaurant_id=$restaurantId&range=${selectedPeriod.toLowerCase()}"
            "${selectedZone != null ? "&zone_id=${selectedZone['id']}" : ""}",
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception("Error fetching dashboard: ${response.body}");
      }

      final decoded = json.decode(response.body);

      final fetchedZones = List<Map<String, dynamic>>.from(
        decoded['restaurant_zones'] ?? [],
      );

      // Select a zone: either previously selected or default to first
      Map<String, dynamic>? updatedZone;
      if (fetchedZones.isNotEmpty) {
        updatedZone = selectedZone != null
            ? fetchedZones.firstWhere(
              (z) => z['id'] == selectedZone['id'],
          orElse: () => fetchedZones.first,
        )
            : fetchedZones.first;
      }

      return {
        "zones": fetchedZones,
        "selectedZone": updatedZone,
        "totalRevenue": (decoded['total_revenue']?['value'] ?? 0).toString(),
        "totalOrders": (decoded['total_orders']?['value'] ?? 0).toString(),
        "revenueTrend": decoded['total_revenue']?['trend']?.toString() ?? "",
        "ordersTrend": decoded['total_orders']?['trend']?.toString() ?? "",
        "activeOrders": (decoded['active_orders'] ?? 0).toString(),
        "runningTables": (decoded['running_tables'] ?? 0).toString(),
        "periods": List<String>.from(decoded['all_ranges'] ?? []),
      };
    } catch (e) {
      throw Exception("Error fetching dashboard: $e");
    }
  }
  Future<List<Map<String, dynamic>>> fetchCurrentShiftEmployees({
    required String date,
    required String time,
  }) async {
    try {
      final url = Uri.parse(
        "${AppConstants.currentShiftEmployeesEndpoint}?date=$date&time=$time",
      );

      print(" API URL: $url");

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final employees = List<Map<String, dynamic>>.from(decoded['employees'] ?? []);
        print(" Employees List: $employees");
        return employees;
      } else {
        throw Exception("Failed to fetch employees: ${response.statusCode}");
      }
    } catch (e) {
      print(" Error: $e");
      throw Exception("Error fetching employees: $e");
    }
  }
  Future<List<Map<String, dynamic>>> fetchInventoryAlerts() async {
    try {
      final url = Uri.parse(AppConstants.inventoryAlertsEndpoint);

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception("Failed to fetch inventory alerts: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching inventory alerts: $e");
    }
  }
  Future<List<Map<String, dynamic>>> fetchCompletedOrders() async {
    try {
      final url = Uri.parse(AppConstants.completedOrdersEndpoint);

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception("Failed to fetch completed orders: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching completed orders: $e");
    }
  }
  Future<List<Map<String, dynamic>>> fetchEmployeeList({
    required String date,
  }) async {
    try {
      final url = Uri.parse("${AppConstants.employeeAttendanceEndpoint}?date=$date");

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return List<Map<String, dynamic>>.from(decoded["employees"] ?? []);
      } else {
        throw Exception("Failed to fetch employees: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching employees: $e");
    }
  }
  Future<List<Map<String, dynamic>>> fetchTopProducts({String? zoneId}) async {
    try {
      final url = Uri.parse(
        "${AppConstants.topProductsSoldEndpoint}?restaurant_id=$restaurantId&zone_id=${zoneId ?? ''}",
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['top_products_sold'] ?? []);
      } else {
        throw Exception("Failed to load top products: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching top products: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchTopCategories({String? zoneId}) async {
    try {
      final url = Uri.parse(
        "${AppConstants.topCategoriesSoldEndpoint}?restaurant_id=$restaurantId&zone_id=${zoneId ?? ''}",
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['top_categories_sold'] ?? []);
      } else {
        throw Exception("Failed to load top categories: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching top categories: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchRevenueChart({
    required String range,
    required int? zoneId,
  }) async {
    final url = Uri.parse(
        "https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/merchant-dashboard/get-chart-revenue?restaurant_id=$restaurantId&range=$range&zone_id=${zoneId ?? 0}"
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['monthly_revenue_chart'] ?? []);
    } else {
      throw Exception('Failed to fetch revenue chart');
    }
  }

  Future<Map<String, dynamic>> fetchPaymentModesRevenue({
    required int zoneId,
    required String range,
    String orderType = "Dine In",
  }) async {
    try {
      final url = Uri.parse(
        'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/merchant-dashboard/get-payment-modes-revenue'
            '?restaurant_id=$restaurantId&range=$range&zone_id=$zoneId&order_type=${Uri.encodeComponent(orderType)}',
      );

      print("=== Fetching Payment Modes Revenue ===");
      print("Zone ID: $zoneId");
      print("Range: $range");
      print("Order Type: $orderType");
      print("URL: $url");
      print("=====================================");

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch payment revenue: ${response.body}");
      }

      final data = json.decode(response.body);

      // Parse order types and payment modes
      final orderTypes = List<String>.from(data['order_types'] ?? []);
      final paymentModes = List<String>.from(data['payment_modes'] ?? []);

      // Parse revenue data
      final Map<String, double> paymentRevenue = {};
      final rawPaymentRevenue = data['payment_revenue'];

      if (rawPaymentRevenue != null) {
        if (rawPaymentRevenue is List) {
          for (var e in rawPaymentRevenue) {
            if (e is Map<String, dynamic>) {
              final mode = e['mode']?.toString() ?? "Unknown";
              final percentStr = e['percent']?.toString().replaceAll('%', '') ?? "0";
              paymentRevenue[mode] = double.tryParse(percentStr) ?? 0;
            }
          }
        } else if (rawPaymentRevenue is Map) {
          final paymentData = rawPaymentRevenue['payment_types'];
          if (paymentData is List) {
            for (var e in paymentData) {
              if (e is Map<String, dynamic>) {
                final mode = e['mode']?.toString() ?? "Unknown";
                final percentStr = e['percent']?.toString().replaceAll('%', '') ?? "0";
                paymentRevenue[mode] = double.tryParse(percentStr) ?? 0;
              }
            }
          } else if (paymentData is Map) {
            paymentData.forEach((key, value) {
              final percentStr = value?.toString().replaceAll('%', '') ?? "0";
              paymentRevenue[key.toString()] = double.tryParse(percentStr) ?? 0;
            });
          }
        }
      }

      return {
        "order_types": orderTypes,
        "payment_modes": paymentModes,
        "payment_revenue": paymentRevenue,
      };
    } catch (e) {
      print("Error in fetchPaymentModesRevenue: $e");
      throw Exception("Error fetching payment revenue: $e");
    }
  }
}
