import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';

class MergeReserveRepository {
  final String token;

  MergeReserveRepository({required this.token});

  Future<Map<String, dynamic>> fetchMergeTables() async {
    final url = Uri.parse(
      AppConstants.getAllMergeTablesWithReservationEndpoint,
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      throw Exception('Failed to fetch merge tables: ${response.body}');
    }
  }
}
