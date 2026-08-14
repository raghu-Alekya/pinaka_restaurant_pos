import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../utils/api_exception_handler.dart';
import 'captain_login_model.dart';

abstract class CaptainLoginRemoteDataSource {
  Future<CaptainLoginResponse> login({
    required String pin,
    required String baseUrl,
  });
}

class CaptainLoginRemoteDataSourceImpl
    implements CaptainLoginRemoteDataSource {
  @override
  Future<CaptainLoginResponse> login({
    required String pin,
    required String baseUrl,
  }) async {
    try {
      print('========== CAPTAIN LOGIN START ==========');
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/token';
      print('URL: $url');
      print('Method: POST');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      request.fields['emp_login_pin'] = pin;

      print('--- Request Fields ---');
      print('emp_login_pin: $pin');

      print('Sending request...');

      final streamedResponse =
      await ApiExceptionHandler.multipart(request);

      final response =
      await http.Response.fromStream(streamedResponse);

      print('--- Response ---');
      print('Status Code: ${response.statusCode}');
      print('Reason Phrase: ${response.reasonPhrase}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Captain login successful.');

        try {
          final jsonResponse = jsonDecode(response.body);
          print('--- Parsed JSON Response ---');
          print(jsonResponse);

          final result =
          CaptainLoginResponse.fromJson(jsonResponse);

          print('CaptainLoginResponse parsed successfully.');
          print('========== CAPTAIN LOGIN END ==========');

          return result;
        } catch (e, stackTrace) {
          print('ERROR while parsing success response');
          print('Parse Error: $e');
          print('Stack Trace: $stackTrace');
          rethrow;
        }
      }

      print('========== CAPTAIN LOGIN FAILED ==========');
      print('HTTP Error Status: ${response.statusCode}');
      print('HTTP Error Body: ${response.body}');

      final errorMessage = ApiExceptionHandler.parseError(
        response,
        defaultMessage: "Captain login failed. Please try again.",
      );

      print('Parsed Error Message: $errorMessage');

      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      print('========== CAPTAIN LOGIN EXCEPTION ==========');
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