import 'package:equatable/equatable.dart';
import '../models/category/subcategory_model.dart';
// import '../models/subcategory_model.dart';

abstract class SubCategoryState extends Equatable {
  const SubCategoryState();

  @override
  List<Object?> get props => [];
}

// Initial state before anything happens
class SubCategoryInitial extends SubCategoryState {}

// Loading state while fetching data
class SubCategoryLoading extends SubCategoryState {}

// Loaded state with list and optional selected subcategory
class SubCategoryLoaded extends SubCategoryState {
  final List<SubCategory> subCategories;
  final SubCategory? selectedSubCategory;

  const SubCategoryLoaded(this.subCategories, {this.selectedSubCategory});

  @override
  List<Object?> get props => [subCategories, selectedSubCategory ?? ''];
}

// Error state with error message
class SubCategoryError extends SubCategoryState {
  final String message;

  const SubCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
