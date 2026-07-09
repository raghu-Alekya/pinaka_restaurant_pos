import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../local database/login_dao.dart';
import '../services/api_exception.dart';
import '../utils/SessionManager.dart';
import '../utils/logger.dart';

class AuthRepository {
  final String baseUrl = AppConstants.authTokenEndpoint;
  final loginDao = LoginDao();

  Future<Map<String, dynamic>> login(String pin) async {
    final url = Uri.parse(AppConstants.authTokenEndpoint);

    try {
      AppLogger.info("AUTH URL => $url");

      final request = http.MultipartRequest("POST", url);
      request.fields["emp_login_pin"] = pin.trim();

      final streamedResponse =
      await ApiExceptionHandler.multipart(request);

      final response =
      await http.Response.fromStream(streamedResponse);

      AppLogger.info("LOGIN STATUS => ${response.statusCode}");
      AppLogger.info("LOGIN RESPONSE => ${response.body}");

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          responseData["success"] == true) {
        final data = responseData["data"];

        final token = data["token"];
        final restaurantId =
        data["restaurant_id"].toString();
        final restaurantName =
        data["restaurant_name"].toString();

        final permissions = Map<String, dynamic>.from(
          data["permissions"] ?? {},
        );

        permissions["displayName"] = data["displayName"] ?? "";
        permissions["role"] = data["role"] ?? "";
        permissions["user_id"] = data["id"]?.toString() ?? "";
        permissions["avatar"] = data["avatar"];
        final prefs =
        await SharedPreferences.getInstance();

        await prefs.setString("token", token);
        await prefs.setString(
            "restaurant_id", restaurantId);
        await prefs.setString(
            "restaurant_name", restaurantName);
        final currencySymbol =
            data["currency_symbol"]?.toString() ?? "₹";

        await SessionManager.saveToken(token);
        await SessionManager.saveCurrencySymbol(currencySymbol);


        await loginDao.insertLogin(
          pin,
          token,
          restaurantId,
          restaurantName,
        );

        return {
          "success": true,
          "token": token,
          "restaurant_id": restaurantId,
          "restaurant_name": restaurantName,
          "permissions": permissions,
          "currency_symbol": currencySymbol,
        };
      }

      return {
        "success": false,
        "message": ApiExceptionHandler.parseError(
          response,
          defaultMessage: "Login failed.",
        ),
      };
    } catch (e, stackTrace) {
      AppLogger.error("Login Exception: $e");
      AppLogger.error(stackTrace.toString());

      return {
        "success": false,
        "message":
        e.toString().replaceFirst("Exception: ", ""),
      };
    }
  }

  Future<bool> logout(String token) async {
    final url = Uri.parse(AppConstants.logoutEndpoint);

    try {
      final response = await ApiExceptionHandler.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info("Logout Status: ${response.statusCode}");
      AppLogger.info("Logout Response: ${response.body}");

      if (response.statusCode == 200) {
        await loginDao.clearLogin();

        final prefs = await SharedPreferences.getInstance();

        await prefs.remove('auth_token');
        await prefs.remove('user_permissions');
        await prefs.remove('user_id');
        await prefs.remove('shift_id');

        AppLogger.info("Logout successful. Session cleared safely.");
        return true;
      }

      throw Exception(
        ApiExceptionHandler.parseError(
          response,
          defaultMessage: "Unable to logout. Please try again.",
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error("Logout exception: $e");
      AppLogger.error(stackTrace.toString());

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Something went wrong while logging out. Please try again.",
      );
    }
  }
  Future<Map<String, dynamic>?> getSavedLogin() async {
    return await loginDao.getLogin();
  }
}
