import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/login_model.dart';
import '../utils/AppConstant.dart';
// import '../utils/app_constants.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/login_model.dart';
import '../utils/AppConstant.dart';

class EmployeePinLoginRepository {
  Future<LoginModel> loginWithPin({
    required String empLoginPin,
  }) async {
    try {
      final uri = Uri.parse(AppConstants.authTokenEndpoint);

      print("==========================================");
      print("Employee Login API");
      print("URL      : $uri");
      print("Method   : POST");
      print("Request  : {emp_login_pin: $empLoginPin}");

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "emp_login_pin": empLoginPin,
        }),
      );

      print("Status Code : ${response.statusCode}");
      print("Response    : ${response.body}");
      print("==========================================");

      if (response.statusCode == 200) {
        final login = LoginModel.fromJson(
          jsonDecode(response.body),
        );
        if (!login.data.permissions.canViewKDS) {
          throw Exception(
            "You are not authorized to access the Kitchen Display System.",
          );
        }

        print("Login Success");
        print("User ID      : ${login.data.id}");
        print("RestaurantId : ${login.data.restaurantId}");
        print("Restaurant   : ${login.data.restaurantName}");
        print("Token        : ${login.data.token}");

        return login;
      }

      throw Exception(
        "Employee PIN Login Failed (${response.statusCode}) : ${response.body}",
      );
    } catch (e, stackTrace) {
      print("==========================================");
      print("Employee Login Exception");
      print(e);
      print(stackTrace);
      print("==========================================");
      rethrow;
    }
  }
}


class LogoutRepository {
  Future<LogoutResponse> logout({
    required String token,
    required int empLoginPin,
  }) async {
    final url = AppConstants.logoutEndpoint;
    print("==========================================");
    print("Employee Logout API");
    print("URL      : $url");
    print("Headers  : {Content-Type: application/json, Authorization: Bearer $token}");
    print("Body     : {emp_login_pin: $empLoginPin}");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "emp_login_pin": empLoginPin,
      }),
    );

    print("Status Code : ${response.statusCode}");
    print("Response    : ${response.body}");
    print("==========================================");

    if (response.statusCode == 200) {
      return LogoutResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        "Logout Failed (${response.statusCode}) : ${response.body}",
      );
    }
  }
}