import 'items_model.dart';
import 'minisubcategory_model.dart';

class SubCategory {
  final String id;
  final String name;
  final String categoryId;
  final String imagePath;
  final bool isFolder; // true if it contains folders instead of items
  final bool? isVeg; // null if it's a folder
  final List<Item>? items; // if not folder
  final List<MiniSubCategory>? folders; // if folder

  SubCategory({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.imagePath,
    required this.isFolder,
    this.isVeg,
    this.items,
    this.folders,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imagePath: json['imagePath'] ?? '',
      categoryId: json['categoryId'] ?? '',
      isFolder: json['isFolder'] ?? false,
      isVeg: json['isVeg'],
      items: json['isFolder'] == true
          ? null
          : (json['items'] as List?)
          ?.map((e) => Item.fromJson(e))
          .toList(),
      folders: json['isFolder'] == true
          ? (json['folders'] as List?)
          ?.map((e) => MiniSubCategory.fromJson(e))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'imagePath': imagePath,
      'isFolder': isFolder,
      'isVeg': isVeg,
      'items': items?.map((e) => e.toJson()).toList(),
      'folders': folders?.map((e) => e.toJson()).toList(),
    };
  }
}
