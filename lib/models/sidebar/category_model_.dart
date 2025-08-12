import '../category/subcategory_model.dart';

class Category {
  final String id;
  final String name;
  final String imagePath;
  final List<SubCategory> subCategories;

  Category({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.subCategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      imagePath: json['imagePath'] ?? '',
      subCategories: (json['subCategories'] as List<dynamic>)
          .map((item) => SubCategory.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'subCategories': subCategories.map((s) => s.toJson()).toList(),
  };
}
