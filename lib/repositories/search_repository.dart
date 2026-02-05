import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pinaka_restaurant_pos/models/search/search_model.dart';
// import '../models/product_model.dart';

class Search_ProductRepository {
  final String baseUrl =
      "https://merchantrestaurant.alektasolutions.com/wp-json/wc/v3/products";

  final String token =
      "YOUR_BEARER_TOKEN";

  Future<List<Search_ProductModel>> SearchfetchProducts({String? search}) async {
    final uri = Uri.parse(
      "$baseUrl?search=${search ?? ''}",
    );

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Search_ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }
}
