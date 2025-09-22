import 'minisubcategory_model.dart';

class SubCategory {
  final int id;
  final String name;
  final String? imagePath;
  final List<MiniSubCategory>? subCategories; // <-- add this

  SubCategory({
    required this.id,
    required this.name,
    this.imagePath,
    this.subCategories,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'],
      imagePath: json['imagepath'],
      subCategories: (json['subcategories'] as List<dynamic>?)
          ?.map((e) => MiniSubCategory.fromJson(e))
          .toList(),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagepath': imagePath,
      'subcategories': subCategories?.map((e) => e.toJson()).toList(),
    };
  }
  /// ✅ Check if this subcategory has mini-subcategories (folders)
  bool get hasMiniSubCategories =>
      subCategories != null && subCategories!.isNotEmpty;
}
