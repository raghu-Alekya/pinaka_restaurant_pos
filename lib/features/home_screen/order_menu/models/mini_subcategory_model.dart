import '../entities/category_entity.dart';
import 'category_model.dart';

class MiniSubcategoryResponse {
  final String status;
  final int subcategoryId;
  final List<MiniSubcategoryModel> miniSubcategories;

  MiniSubcategoryResponse({
    required this.status,
    required this.subcategoryId,
    required this.miniSubcategories,
  });

  factory MiniSubcategoryResponse.fromJson(Map<String, dynamic> json) {
    return MiniSubcategoryResponse(
      status: json['status'] ?? '',
      subcategoryId: json['subcategory_id'] ?? 0,
      miniSubcategories: (json['mini_subcategories'] as List?)
          ?.map((e) => MiniSubcategoryModel.fromJson(e))
          .toList() ??
          [],
    );
  }

  List<MiniSubcategoryEntity> toEntityList() =>
      miniSubcategories.map((e) => e.toEntity()).toList();
}

class MiniSubcategoryModel {
  final int id;
  final String name;
  final String? imagePath;
  final List<ProductModel> products;

  MiniSubcategoryModel({
    required this.id,
    required this.name,
    this.imagePath,
    this.products = const [],
  });

  factory MiniSubcategoryModel.fromJson(Map<String, dynamic> json) {
    return MiniSubcategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imagePath: json['imagepath'],
      products: (json['products'] as List?)
          ?.map((e) => ProductModel.fromJson(e))
          .toList() ??
          [],
    );
  }

  MiniSubcategoryEntity toEntity() => MiniSubcategoryEntity(
    id: id,
    name: name,
    imagePath: imagePath,
    products: products.map((e) => e.toEntity()).toList(),
  );
}