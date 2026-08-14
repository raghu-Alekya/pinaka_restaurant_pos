import '../entities/category_entity.dart';
import '../entities/product_entity.dart';


class CategoryResponse {
  final String status;
  final List<CategoryModel> categories;

  CategoryResponse({
    required this.status,
    required this.categories,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      status: json['status'] ?? '',
      categories: (json['category'] as List?)
          ?.map((e) => CategoryModel.fromJson(e))
          .toList() ??
          [],
    );
  }

  List<CategoryEntity> toEntityList() =>
      categories.map((e) => e.toEntity()).toList();
}

class CategoryModel {
  final int id;
  final String name;
  final String? imagePath;
  final List<SubcategoryModel> subcategories;

  CategoryModel({
    required this.id,
    required this.name,
    this.imagePath,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      imagePath: json['imagepath'],
      subcategories: (json['subcategory'] as List?)
          ?.map((e) => SubcategoryModel.fromJson(e))
          .toList() ??
          [],
    );
  }

  CategoryEntity toEntity() => CategoryEntity(
    id: id,
    name: name,
    imagePath: imagePath,
    subcategories: subcategories.map((e) => e.toEntity()).toList(),
  );
}

class SubcategoryModel {
  final int id;
  final String name;
  final String? imagePath;
  final List<MiniSubcategoryModel> miniSubcategories; // Now a list
  final List<ProductModel> directProducts; // products directly under this subcategory

  SubcategoryModel({
    required this.id,
    required this.name,
    this.imagePath,
    this.miniSubcategories = const [],
    this.directProducts = const [],
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    List<MiniSubcategoryModel> miniList = [];
    List<ProductModel> directProducts = [];

    final miniData = json['mini_subcategory'];
    if (miniData is Map<String, dynamic>) {
      // It's a map with numeric keys and possibly a "products" key
      for (var entry in miniData.entries) {
        if (entry.key == 'products') {
          // This is the direct products list
          directProducts = (entry.value as List?)
              ?.map((p) => ProductModel.fromJson(p))
              .toList() ??
              [];
        } else {
          // It's a mini-subcategory (numeric key)
          final miniJson = entry.value;
          if (miniJson is Map<String, dynamic>) {
            miniList.add(MiniSubcategoryModel.fromJson(miniJson));
          }
        }
      }
    }
    // If miniData is a List (empty or otherwise), we ignore it as there are no mini-subcategories.

    return SubcategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      imagePath: json['imagepath'],
      miniSubcategories: miniList,
      directProducts: directProducts,
    );
  }

  SubcategoryEntity toEntity() => SubcategoryEntity(
    id: id,
    name: name,
    imagePath: imagePath,
    miniSubcategories: miniSubcategories.map((e) => e.toEntity()).toList(),
    directProducts: directProducts.map((e) => e.toEntity()).toList(),
  );
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
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
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

class ProductModel {
  final int id;
  final String name;
  final String? price;
  final String? image;
  final bool? isVeg;
  final bool inStock;
  final String? isVariant;
  final String? isCombo;

  ProductModel({
    required this.id,
    required this.name,
    this.price,
    this.image,
    this.isVeg,
    this.inStock = true,
    this.isVariant,
    this.isCombo,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price']?.toString(),
      image: json['image'],
      isVeg: json['is_veg'],
      inStock: json['in_stock'] == 'Yes',
      isVariant: json['is_variant'],
      isCombo: json['is_combo'],
    );
  }

  ProductEntity toEntity() => ProductEntity(
    id: id,
    name: name,
    price: price,
    image: image,
    isVeg: isVeg,
    inStock: inStock,
    isVariant: isVariant,
    isCombo: isCombo,
  );
}