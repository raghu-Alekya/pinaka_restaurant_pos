import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants/api_constants.dart';
import '../../../utils/api_exception_handler.dart';
import 'merchant_login_model.dart';

abstract class MerchantLoginRemoteDataSource {
  Future<MerchantLoginResponse> login({
    required String username,
    required String password,
    required String storeId,
    required String deviceId,
    String shift = '',
  });
}

class MerchantLoginRemoteDataSourceImpl
    implements MerchantLoginRemoteDataSource {
  @override
  Future<MerchantLoginResponse> login({
    required String username,
    required String password,
    required String storeId,
    required String deviceId,
    String shift = '',
  }) async {
    try {
      print('========== MERCHANT LOGIN START ==========');
      print('URL: ${ApiConstants.merchantLoginUrl}');
      print('Method: POST');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.merchantLoginUrl),
      );

      request.fields['username'] = username;
      request.fields['password'] = password;
      request.fields['store_id'] = storeId;
      request.fields['device_id'] = deviceId;
      request.fields['shifit'] = shift;

      // Print request data
      print('--- Request Fields ---');
      print('username: $username');
      print('password: $password');
      print('store_id: $storeId');
      print('device_id: $deviceId');
      print('shifit: $shift');

      print('Sending request...');

      final streamedResponse =
      await ApiExceptionHandler.multipart(request);

      final response =
      await http.Response.fromStream(streamedResponse);

      // Print response
      print('--- Response ---');
      print('Status Code: ${response.statusCode}');
      print('Reason Phrase: ${response.reasonPhrase}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Merchant login successful.');

        try {
          final jsonResponse = jsonDecode(response.body);

          print('--- Parsed JSON Response ---');
          print(jsonResponse);

          final result =
          MerchantLoginResponse.fromJson(jsonResponse);

          print('MerchantLoginResponse parsed successfully.');
          print('========== MERCHANT LOGIN END ==========');

          return result;
        } catch (e, stackTrace) {
          print('ERROR while parsing success response');
          print('Parse Error: $e');
          print('Stack Trace: $stackTrace');
          rethrow;
        }
      }

      // API returned non-200 status
      print('========== MERCHANT LOGIN FAILED ==========');
      print('HTTP Error Status: ${response.statusCode}');
      print('HTTP Error Body: ${response.body}');

      final errorMessage = ApiExceptionHandler.parseError(
        response,
        defaultMessage: "Merchant login failed. Please try again.",
      );

      print('Parsed Error Message: $errorMessage');

      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      print('========== MERCHANT LOGIN EXCEPTION ==========');
      print('Exception Type: ${e.runtimeType}');
      print('Exception: $e');
      print('Stack Trace: $stackTrace');
      print('==============================================');

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Something went wrong. Please try again later.",
      );
    }
  }
}
