// models/search_category.dart
class SearchCategory {
  final int id;
  final String name;

  SearchCategory({required this.id, required this.name});

  factory SearchCategory.fromJson(Map<String, dynamic> json) {
    return SearchCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}