import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:restaurant_captain_app/features/home_screen/Zones/zones_data_layer/zone_model.dart';

import '../../../../utils/api_exception_handler.dart';


abstract class ZoneRemoteDataSource {
  Future<ZoneResponse> getZones({
    required String baseUrl,
    required String token,
  });
}

class ZoneRemoteDataSourceImpl implements ZoneRemoteDataSource {
  @override
  Future<ZoneResponse> getZones({
    required String baseUrl,
    required String token,
  }) async {
    try {
      print('========== ZONES FETCH START ==========');
      final url = '$baseUrl/wp-json/pinaka-restaurant-pos/v1/zones/get-all-zones';
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
        print('Zones fetched successfully.');
        try {
          final jsonResponse = jsonDecode(response.body);
          print('Parsed JSON: $jsonResponse');
          final result = ZoneResponse.fromJson(jsonResponse);
          print('ZoneResponse parsed. Zones count: ${result.zoneDetails?.length}');
          print('========== ZONES FETCH END ==========');
          return result;
        } catch (e, stackTrace) {
          print('ERROR parsing zones response: $e');
          print('Stack Trace: $stackTrace');
          rethrow;
        }
      } else {
        print('========== ZONES FETCH FAILED ==========');
        print('HTTP Error: ${response.statusCode}');
        final errorMsg = ApiExceptionHandler.parseError(
          response,
          defaultMessage: 'Failed to fetch zones.',
        );
        print('Error message: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e, stackTrace) {
      print('========== ZONES FETCH EXCEPTION ==========');
      print('Exception: $e');
      print('Stack Trace: $stackTrace');
      print('============================================');
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch zones. Please try again.');
    }
  }
}