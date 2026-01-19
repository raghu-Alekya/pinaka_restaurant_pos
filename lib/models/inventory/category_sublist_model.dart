class CategorySublistResponse {
  final int parentId;
  final String parentName;
  final List<CategoryItem> categories;

  CategorySublistResponse({
    required this.parentId,
    required this.parentName,
    required this.categories,
  });

  factory CategorySublistResponse.fromJson(Map<String, dynamic> json) {
    return CategorySublistResponse(
      parentId: json['parent_id'],
      parentName: json['parent_name'],
      categories: (json['categories'] as List)
          .map((e) => CategoryItem.fromJson(e))
          .toList(),
    );
  }
}

class CategoryItem {
  final int id;
  final String name;
  final List<MiniCategory> children;

  CategoryItem({
    required this.id,
    required this.name,
    required this.children,
  });

  /// ✅ ADD THIS
  bool get hasChildren => children.isNotEmpty;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'],
      name: json['name'],
      children: (json['children'] as List? ?? [])
          .map((e) => MiniCategory.fromJson(e))
          .toList(),
    );
  }
}


class MiniCategory {
  final int id;
  final String name;

  MiniCategory({
    required this.id,
    required this.name,
  });

  factory MiniCategory.fromJson(Map<String, dynamic> json) {
    return MiniCategory(
      id: json['id'],
      name: json['name'],
    );
  }
}