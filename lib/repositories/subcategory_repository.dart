import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category/subcategory_model.dart';

class SubCategoryRepository {
  final String baseUrl;

  SubCategoryRepository({required this.baseUrl});

  Future<List<SubCategory>> fetchSubCategories({
    required String categoryId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/wp-json/pinaka-restaurant-pos/v1/categories/get-main-courses'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('API Response: ${response.body}'); // ✅ print raw API response

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['status'] == "success" && body['category'] != null) {
          // Find the matching category by id
          final category = (body['category'] as List).firstWhere(
                (cat) => cat['id'].toString() == categoryId.toString(),
            orElse: () => null,
          );


          if (category != null && category['subcategory'] != null) {
            final List<dynamic> subCategoryJson = category['subcategory'];
            final subCategories = subCategoryJson
                .map((json) => SubCategory.fromJson(json))
                .toList();

            print('Parsed SubCategories:');
            for (var sub in subCategories) {
              print('id: ${sub.id}, name: ${sub.name}, image: ${sub
                  .imagePath}, ');
            }

            return subCategories;
          }
        }
        return [];
      } else {
        throw Exception('Failed to load subcategories');
      }
    } catch (e) {
      print('Error fetching subcategories: $e'); // ✅ print error
      throw Exception('Error fetching subcategories: $e');
    }
  }
}