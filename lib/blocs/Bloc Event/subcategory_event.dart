import 'package:equatable/equatable.dart';

abstract class SubCategoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Load subcategories of a category
class LoadSubCategories extends SubCategoryEvent {
  final String token;
  final String categoryId;

  LoadSubCategories({required this.token, required this.categoryId});

  @override
  List<Object?> get props => [token, categoryId];
}

// Select a subcategory (e.g., to load items or deeper folders)
class SelectSubCategory extends SubCategoryEvent {
  final String subCategoryId;

  SelectSubCategory(this.subCategoryId);

  @override
  List<Object?> get props => [subCategoryId];
}
