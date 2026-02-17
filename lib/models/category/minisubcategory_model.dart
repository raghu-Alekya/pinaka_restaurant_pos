import 'items_model.dart';

class MiniSubCategoryResponse {
  final String status;
  final int subcategoryId;
  final List<MiniSubCategory> miniSubcategories;

  MiniSubCategoryResponse({
    required this.status,
    required this.subcategoryId,
    required this.miniSubcategories,
  });

  factory MiniSubCategoryResponse.fromJson(Map<String, dynamic> json) {
    return MiniSubCategoryResponse(
      status: json['status'] ?? '',
      subcategoryId: json['subcategory_id'] is int
          ? json['subcategory_id']
          : int.tryParse(json['subcategory_id'].toString()) ?? 0,
      miniSubcategories: (json['mini_subcategories'] is List)
          ? (json['mini_subcategories'] as List)
          .map((e) => MiniSubCategory.fromJson(e))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'subcategory_id': subcategoryId,
      'mini_subcategories': miniSubcategories.map((e) => e.toJson()).toList(),
    };
  }
}

class MiniSubCategory {
  final int id;
  final String name;
  final String? slNo;
  final int count;
  final String? imagePath;
  final bool isFolder;
  List<Product> products;

  MiniSubCategory({
    required this.id,
    required this.name,
    this.slNo,
    required this.count,
    this.imagePath,
    required this.isFolder,
    required this.products,
  });

  factory MiniSubCategory.fromJson(Map<String, dynamic> json) {
    List<Product> productList = (json['products'] is List)
        ? (json['products'] as List).map((e) {
      // Use product's actual isVeg
      return Product.fromJson(e);
    }).toList()
        : [];

    return MiniSubCategory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      slNo: json['sl_no'],
      count: json['count'] is int ? json['count'] : int.tryParse(json['count'].toString()) ?? 0,
      imagePath: json['imagepath'],
      isFolder: json['isFolder'].toString().toLowerCase() == 'true',
      products: productList,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sl_no': slNo,
      'count': count,
      'imagepath': imagePath,
      'isFolder': isFolder,
      'products': products.map((e) => e.toJson()).toList(),
    };
  }

  MiniSubCategory copyWith({
    int? id,
    String? name,
    String? slNo,
    int? count,
    String? imagePath,
    bool? isFolder,
    List<Product>? products,
  }) {
    return MiniSubCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      slNo: slNo ?? this.slNo,
      count: count ?? this.count,
      imagePath: imagePath ?? this.imagePath,
      isFolder: isFolder ?? this.isFolder,
      products: products ?? this.products,
    );
  }

  // ✅ New computed property for folder veg status
  // In MiniSubCategory
  bool? get isVegFolder {
    if (!isFolder) return null; // Not a folder → no icon
    if (products.isEmpty) return null; // Empty folder → no icon

    final nonNullIsVeg = products.map((p) => p.isVeg).where((v) => v != null).toList();

    if (nonNullIsVeg.isEmpty) return null; // All null → no icon
    if (nonNullIsVeg.every((v) => v == true)) return true; // All veg
    if (nonNullIsVeg.every((v) => v == false)) return false; // All non-veg

    return null; // Mixed → no icon
  }

}
