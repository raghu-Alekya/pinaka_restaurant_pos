import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../utils/logger.dart';

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
          "${AppConstants.getRevenueByFiltersEndpoint}"
              "?restaurant_id=$restaurantId&range=${selectedPeriod.toLowerCase()}"
              "${selectedZone != null ? "&zone_id=${selectedZone['id']}" : ""}"
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
  Future<Map<String, dynamic>> fetchPaymentModesRevenue({
    required String zoneId,
    required String range,
    String orderType = "Dine In",
  }) async {
    final url = Uri.parse(
      "${AppConstants.getPaymentModesRevenueEndpoint}"
          "?restaurant_id=$restaurantId"
          "&range=$range"
          "&zone_id=$zoneId"
          "&order_type=${Uri.encodeComponent(orderType)}",
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      AppLogger.debug("Payment modes revenue response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        AppLogger.warning(
            "Failed to load payment revenue (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      AppLogger.error("Error fetching payment revenue: $e");
    }

    return {};
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

  Future<Map<String, dynamic>> fetchRevenueChart({
    required String range,
    required int? zoneId,
  }) async {
    final url = Uri.parse(
        "${AppConstants.getChartRevenueEndpoint}?restaurant_id=$restaurantId&range=$range&zone_id=${zoneId ?? 0}"
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      String revenueText = (data['revenue'] ?? '').toString();
      revenueText = revenueText.replaceAllMapped(
        RegExp(r'(\d+(?:\.\d+)?)'),
            (match) => '₹${match.group(1)}',
      );

      return {
        'chartData': List<Map<String, dynamic>>.from(data['revenue_chart'] ?? []),
        'yAxisValues': List<String>.from(data['y_axis_values'] ?? []),
        'revenueSummary': revenueText,
      };
    } else {
      throw Exception('Failed to fetch revenue chart');
    }
  }
}
