import '../category/category_model.dart';

class category {
  final String name;
  final List<subcategory> categories;

  category({required this.name, required this.categories});

  factory category.fromJson(Map<String, dynamic> json) {
    return category(
      name: json['name'],
      categories: (json['categories'] as List<dynamic>)
          .map((item) => subcategory.fromJson(item, category(name: json['name'], categories: [])))  // Recursive section
          .toList(),
    );
  }


  Map<String, dynamic> toJson() => {
    'name': name,
    'categories': categories.map((c) => c.toJson()).toList(),
  };
}
