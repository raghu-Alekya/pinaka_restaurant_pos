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
      final zonesUrl = Uri.parse(
        "${AppConstants.dashboardRevenueByFiltersEndpoint}"
            "?restaurant_id=$restaurantId&range=${selectedPeriod.toLowerCase()}",
      );

      final zonesResponse = await http.get(
        zonesUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (zonesResponse.statusCode != 200) {
        throw Exception("Error fetching zones: ${zonesResponse.body}");
      }

      final zonesDecoded = json.decode(zonesResponse.body);
      final fetchedZones = List<Map<String, dynamic>>.from(
        (zonesDecoded['data'] ?? zonesDecoded)['restaurant_zones'] ?? [],
      );

      Map<String, dynamic>? updatedZone;
      if (fetchedZones.isNotEmpty) {
        if (selectedZone == null) {
          updatedZone = fetchedZones.first;
        } else {
          updatedZone = fetchedZones.firstWhere(
                (z) => z['id'] == selectedZone['id'],
            orElse: () => fetchedZones.first,
          );
        }
      }
      String urlStr =
          "${AppConstants.dashboardRevenueByFiltersEndpoint}"
          "?restaurant_id=$restaurantId"
          "&range=${selectedPeriod.toLowerCase()}"
          "${updatedZone != null ? "&zone_id=${updatedZone['id']}" : ""}";

      final response = await http.get(
        Uri.parse(urlStr),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final dashboardData = decoded['data'] ?? decoded;

        return {
          "zones": fetchedZones,
          "selectedZone": updatedZone,
          "totalRevenue":
          (dashboardData['total_revenue']?['value'] ?? 0).toString(),
          "totalOrders":
          (dashboardData['total_orders']?['value'] ?? 0).toString(),
          "revenueTrend":
          dashboardData['total_revenue']?['trend']?.toString() ?? "",
          "ordersTrend":
          dashboardData['total_orders']?['trend']?.toString() ?? "",
          "activeOrders": (dashboardData['active_orders'] ?? 0).toString(),
          "runningTables": (dashboardData['running_tables'] ?? 0).toString(),
        };
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
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
}
