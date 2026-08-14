import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../utils/api_exception_handler.dart';
import 'all_tables_list_model.dart';

abstract class AllTablesRemoteDataSource {
  Future<AllTablesResponse> getAllTables({
    required String baseUrl,
    required String token,
  });
}

class AllTablesRemoteDataSourceImpl implements AllTablesRemoteDataSource {
  @override
  Future<AllTablesResponse> getAllTables({
    required String baseUrl,
    required String token,
  }) async {
    try {
      print('========== ALL TABLES FETCH START ==========');
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/tables/get-all-tables';
      print('URL: $url');
      print('Method: GET');

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      print('Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('--- Response ---');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Tables fetched successfully.');
        try {
          final jsonResponse = jsonDecode(response.body);
          print('Parsed JSON: $jsonResponse');
          final result = AllTablesResponse.fromJson(jsonResponse);
          print('AllTablesResponse parsed. Tables count: ${result.tableDetails?.length}');
          print('========== ALL TABLES FETCH END ==========');
          return result;
        } catch (e, stackTrace) {
          print('ERROR parsing tables response: $e');
          print('Stack Trace: $stackTrace');
          rethrow;
        }
      } else {
        print('========== ALL TABLES FETCH FAILED ==========');
        print('HTTP Error: ${response.statusCode}');
        final errorMsg = ApiExceptionHandler.parseError(
          response,
          defaultMessage: 'Failed to fetch tables.',
        );
        print('Error message: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      print('========== ALL TABLES FETCH EXCEPTION ==========');
      print('Exception: $e');
      print('Stack Trace: $stackTrace');
      print('============================================');
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch tables. Please try again.');
    }
  }
}