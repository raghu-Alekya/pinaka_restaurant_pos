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

      final request = http.MultipartRequest(
        'POST',
        uri,
      )..fields['emp_login_pin'] = empLoginPin;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
    final response = await http.post(
      Uri.parse(AppConstants.logoutEndpoint),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "emp_login_pin": empLoginPin,
      }),
    );

    if (response.statusCode == 200) {
      return LogoutResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        "Logout Failed (${response.statusCode}) : ${response.body}",
      );
    }
  }
}