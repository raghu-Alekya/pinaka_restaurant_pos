import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category/items_model.dart';

class VariantRepository {
  final String baseUrl;
  final String token;

  VariantRepository({required this.baseUrl, required this.token});

  /// Fetch all variants for a given product ID
  Future<List<Variant>> fetchVariantsByProduct(int productId) async {
    try {
      final url = "$baseUrl/wp-json/wc/v3/products/$productId/variations";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NTc1NzQ4MzQsIm5iZiI6MTc1NzU3NDgzNCwiZXhwIjoxNzYwMTY2ODM0LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.iRatzIIFeR9xWjtS3n5-Zgu_0Mb8AwXowlGUpdd5-i0",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((jsonItem) => Variant.fromJson(jsonItem)).toList();
      } else {
        throw Exception(
            "Failed to load variants: ${response.statusCode} ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("Error fetching variants: $e");
    }
  }
}
