import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/merchantlogin_response.dart';
import '../utils/AppConstant.dart';
import '../utils/apiexception_handler.dart';
// import '../utils/session_manager.dart';
import '../utils/sessionmanger.dart';

class MerchantLoginRepository {
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
        Uri.parse(AppConstants.merchantLoginEndpoint),
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

      print(
        "Merchant Login URL: "
            "${AppConstants.merchantLoginEndpoint}",
      );

      print(
        "Merchant Login Status: "
            "${response.statusCode}",
      );

      print(
        "Merchant Login Response: "
            "${response.body}",
      );

      if (response.statusCode == 200) {
        final loginResponse =
        MerchantLoginResponse.fromJson(
          jsonDecode(response.body),
        );

        // =====================================================
        // SAVE STORE ID FROM MERCHANT LOGIN
        // =====================================================

        final merchantStoreId =
            loginResponse.storeId?.toString().trim() ?? '';

        if (merchantStoreId.isEmpty) {
          print(
            "❌ Store ID is missing in merchant login response",
          );
        } else {
          await SessionManager.saveStoreId(
            merchantStoreId,
          );

          print(
            "✅ Merchant Store ID saved: "
                "$merchantStoreId",
          );
        }

        return loginResponse;
      }

      throw Exception(
        ApiExceptionHandler.parseError(
          response,
          defaultMessage:
          "Merchant login failed. Please try again.",
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}