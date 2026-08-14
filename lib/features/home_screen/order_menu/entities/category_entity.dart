import 'product_entity.dart';

class CategoryEntity {
  final int id;
  final String name;
  final String? imagePath;
  final List<SubcategoryEntity> subcategories;

  CategoryEntity({
    required this.id,
    required this.name,
    this.imagePath,
    this.subcategories = const [],
  });
}

class SubcategoryEntity {
  final int id;
  final String name;
  final String? imagePath;
  final List<MiniSubcategoryEntity> miniSubcategories;
  final List<ProductEntity> directProducts; // products directly under this subcategory

  SubcategoryEntity({
    required this.id,
    required this.name,
    this.imagePath,
    this.miniSubcategories = const [],
    this.directProducts = const [],
  });
}

class MiniSubcategoryEntity {
  final int id;
  final String name;
  final String? imagePath;
  final List<ProductEntity> products;

  MiniSubcategoryEntity({
    required this.id,
    required this.name,
    this.imagePath,
    this.products = const [],
  });
}