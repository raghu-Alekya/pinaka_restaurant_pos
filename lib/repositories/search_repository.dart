// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/product_model.dart';
//
// class SerachProductRepository {
//   final String baseUrl =
//       'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/products';
//
//   Future<List<SearchProduct>> fetchProducts(String token) async {
//     final response = await http.get(
//       Uri.parse(baseUrl),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final List data = json.decode(response.body);
//       return data.map((e) => Product.fromJson(e)).toList();
//     } else {
//       throw Exception('Failed to load products');
//     }
//   }
// }
