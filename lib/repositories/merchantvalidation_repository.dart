import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/merchantlogin_model.dart';
import '../services/api_exception.dart';

class MerchantLoginRepository {
  static const String _url =
      'https://test.alekyatechsolutions.com/wp-json/custom/v1/validate-merchant';

  Future<MerchantLoginResponse> login({
    required String username,
    required String password,
    required String storeId,
    required String deviceId,
    String shift = '',
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_url),
      );

      request.fields['username'] = username;
      request.fields['password'] = password;
      request.fields['store_id'] = storeId;
      request.fields['device_id'] = deviceId;
      request.fields['shifit'] = shift;

      final streamedResponse =
      await ApiExceptionHandler.multipart(request);

      final response =
      await http.Response.fromStream(streamedResponse);

      print("Merchant Login Status: ${response.statusCode}");
      print("Merchant Login Response: ${response.body}");

      if (response.statusCode == 200) {
        return MerchantLoginResponse.fromJson(
          jsonDecode(response.body),
        );
      }

      throw Exception(
        ApiExceptionHandler.parseError(
          response,
          defaultMessage: "Merchant login failed. Please try again.",
        ),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Something went wrong. Please try again later.",
      );
    }
  }
}