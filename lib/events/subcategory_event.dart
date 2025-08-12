import 'package:equatable/equatable.dart';

abstract class SubCategoryEvent extends Equatable {
  const SubCategoryEvent();

  @override
  List<Object?> get props => [];
}

// Load subcategories for a given categoryId
class LoadSubCategories extends SubCategoryEvent {
  final String categoryId;

  const LoadSubCategories(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

// Select a subcategory (by id)
class SelectSubCategory extends SubCategoryEvent {
  final String subCategoryId;

  const SelectSubCategory(this.subCategoryId);

  @override
  List<Object?> get props => [subCategoryId];
}
