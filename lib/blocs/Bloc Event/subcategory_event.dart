import 'package:equatable/equatable.dart';
import 'package:pinaka_restaurant_pos/models/category/subcategory_model.dart';

abstract class SubCategoryEvent extends Equatable {
  const SubCategoryEvent();

  @override
  List<Object?> get props => [];
}

// Load subcategories of a specific category
class LoadSubCategories extends SubCategoryEvent {
  final String token;
  final String categoryId;

  const LoadSubCategories({
    required this.token,
    required this.categoryId,
  });

  @override
  List<Object?> get props => [token, categoryId];
}

// Select a subcategory (e.g., to load items or deeper folders)
class SelectSubCategory extends SubCategoryEvent {
  final SubCategory subCategory;

  const SelectSubCategory({required this.subCategory});

  @override
  List<Object?> get props => [subCategory];
}

// Reset the selected subcategory
class ResetSubCategory extends SubCategoryEvent {
  const ResetSubCategory();
}

// Optional: Auto-select first subcategory after load
class AutoSelectFirstSubCategory extends SubCategoryEvent {
  final List<SubCategory> subCategories;

  const AutoSelectFirstSubCategory({required this.subCategories});

  @override
  List<Object?> get props => [subCategories];
}
