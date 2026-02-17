import 'package:equatable/equatable.dart';
import '../../models/category/subcategory_model.dart';

abstract class SubCategoryState extends Equatable {
  const SubCategoryState();

  @override
  List<Object?> get props => [];
}

// Initial state
class SubCategoryInitial extends SubCategoryState {
  const SubCategoryInitial();
}

// Loading state
class SubCategoryLoading extends SubCategoryState {
  const SubCategoryLoading();
}

// Loaded successfully
class SubCategoryLoaded extends SubCategoryState {
  final List<SubCategory> subcategories;
  final int? selectedSubCategory; // Store selected subcategory ID

  const SubCategoryLoaded({
    required this.subcategories,
    this.selectedSubCategory,
  });

  @override
  List<Object?> get props => [subcategories, selectedSubCategory];
}

// Error state
class SubCategoryError extends SubCategoryState {
  final String message;

  const SubCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
