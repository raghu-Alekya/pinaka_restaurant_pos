import 'package:equatable/equatable.dart';

abstract class MiniSubCategoryEvent extends Equatable {
  const MiniSubCategoryEvent();

  @override
  List<Object?> get props => [];
}

// Load mini subcategories for a given parent id (could be category or folder id)
class LoadMiniSubCategories extends MiniSubCategoryEvent {
  final String parentId;

  const LoadMiniSubCategories(this.parentId);

  @override
  List<Object?> get props => [parentId];
}

// Select a mini subcategory (folder or item)
class SelectMiniSubCategory extends MiniSubCategoryEvent {
  final String miniSubCategoryId;

  const SelectMiniSubCategory(this.miniSubCategoryId);

  @override
  List<Object?> get props => [miniSubCategoryId];
}
