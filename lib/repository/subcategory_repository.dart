import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category/subcategory_model.dart';
// import '../models/subcategory_model.dart';

class SubCategoryRepository {
  final String baseUrl;

  SubCategoryRepository({required this.baseUrl});

  Future<List<SubCategory>> fetchSubCategories(String categoryId) async {
    final url = Uri.parse('$baseUrl/api/categories/$categoryId/subcategories');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);

      return jsonList
          .map((jsonItem) => SubCategory.fromJson(jsonItem))
          .toList();
    } else {
      throw Exception('Failed to load subcategories');
    }
  }
}
