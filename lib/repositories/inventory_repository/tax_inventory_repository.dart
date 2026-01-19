import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/inventory/tax_inventory_model.dart';
// import '../../models/inventory/tax_model.dart';


class TaxinventoryRepository {
  static const String baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/wc/v3/taxes';

  final String token;

  TaxinventoryRepository(this.token);

  Future<List<TaxInventoryModel>> fetchTaxes() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => TaxInventoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load taxes');
    }
  }
}