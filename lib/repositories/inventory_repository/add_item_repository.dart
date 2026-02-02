import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/inventory/manage_stock_model.dart';
// import '../models/inventory/manage_stock.dart';

class AddUpdateItemRepository {
  static const String baseUrl =
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/inventories/add-update-item-details';
  Future<AddUpdateItemResponse> addOrUpdateItem({
    required String token,
    required String itemName,
    required int categoryId,
    required int itemQty,
    required int itemPrice,
    required String itemNote,
    required String itemSku,
    int? imageId, // ✅ image ID only
    int? miniCategoryId,
    String? taxClass,
  }) async {
    final uri = Uri.parse(baseUrl);

    final requestBody = {
      'item_name': itemName,
      'item_sku': itemSku,
      'item_qty': itemQty,
      'item_price': itemPrice,
      'category_id': categoryId,
      'item_note': itemNote,
      if (imageId != null) 'image_id': imageId, // 🔥 ONLY ID
      if (miniCategoryId != null) 'mini_category_id': miniCategoryId,
      if (taxClass != null) ...{
        'tax_status': 'taxable',
        'tax_class': taxClass,
      },
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return AddUpdateItemResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }


  Future<int> uploadImageToMedia({
    required String token,
    required String imagePath,
  }) async {
    print("🖼️ uploadImageToMedia CALLED");
    print("📁 Image path: $imagePath");

    final file = File(imagePath);
    final exists = await file.exists();
    print("📌 File exists: $exists");

    if (!exists) {
      throw Exception("Image file does not exist at path: $imagePath");
    }

    final fileName = imagePath.split('/').last;
    final fileSize = await file.length();

    print("📄 File name: $fileName");
    print("📏 File size: ${fileSize} bytes");

    final uri = Uri.parse(
      'https://merchantrestaurant.alektasolutions.com/wp-json/wp/v2/media',
    );

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Disposition': 'attachment; filename=$fileName',
    });

    print("🧾 Request headers:");
    request.headers.forEach((k, v) => print("   $k: $v"));

    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      imagePath,
      filename: fileName,
    );

    print("📤 Multipart file details:");
    print("   field: ${multipartFile.field}");
    print("   filename: ${multipartFile.filename}");
    print("   contentType: ${multipartFile.contentType}");

    request.files.add(multipartFile);

    print("🚀 Sending image upload request...");

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("📥 Upload response status: ${response.statusCode}");
    print("📥 Upload response body:\n${response.body}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print("✅ Image uploaded successfully. Media ID: ${json['id']}");
      return json['id'];
    } else {
      throw Exception(
        '❌ Image upload failed: ${response.statusCode} ${response.body}',
      );
    }
  }

}