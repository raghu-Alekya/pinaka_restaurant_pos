import '../category/subcategory_model.dart';

class Category {
  final String id;
  final String name;
  final String imagepath;

  final List<SubCategory> subCategories;

  Category({
    required this.id,
    required this.name,
    required this.imagepath,

    required this.subCategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(), // int -> String
      name: json['name'] ?? '',
      imagepath: json['imagepath'] ?? '',

      subCategories: (json['subcategory'] as List<dynamic>?)
          ?.map((e) => SubCategory.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagepath': imagepath,

    'subcategory': subCategories.map((s) => s.toJson()).toList(),
  };

  @override
  String toString() {
    return 'Category(id: $id, name: $name, subCategories: ${subCategories.length})';
  }
}
