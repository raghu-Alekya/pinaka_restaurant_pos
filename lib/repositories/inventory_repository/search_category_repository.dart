// // repositories/search_category_repository.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// import '../models/inventory/search_category.dart';
// // import '../../models/inventory/SearchCategory.dart';
//
// class SearchCategoryRepository {
//   final String baseUrl;
//
//   SearchCategoryRepository({required this.baseUrl});
//
//   Future<List<SearchCategory>> fetchSearchCategories({required String token}) async {
//     final url = Uri.parse('$baseUrl/wp-json/pinaka-restaurant-pos/v1/inventories/get-search-categories');
//
//     print('➡️ GET URL: $url');
//     print('➡️ Token: ${token.substring(0, 10)}...');
//
//     final response = await http.get(
//       url,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );
//
//     print('➡️ Status Code: ${response.statusCode}');
//     print('➡️ Response body: ${response.body}');
//
//     if (response.statusCode == 200) {
//       final List<dynamic> jsonData = json.decode(response.body);
//       return jsonData.map((item) => SearchCategory.fromJson(item)).toList();
//     } else {
//       throw Exception('Failed to fetch search categories: ${response.body}');
//     }
//   }
// }