import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/merchantlogin_model.dart';

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
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(_url),
      );

      request.fields['username'] = username;
      request.fields['password'] = password;
      request.fields['store_id'] = storeId;
      request.fields['device_id'] = deviceId;
      request.fields['shifit'] = shift;

      final streamedResponse = await request.send();

      final response =
      await http.Response.fromStream(streamedResponse);

      print("Merchant Login Status: ${response.statusCode}");
      print("Merchant Login Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return MerchantLoginResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Login failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Merchant Login Error: $e');
    }
  }
}