import 'package:equatable/equatable.dart';
import '../../models/category/subcategory_model.dart';
// import '../models/category/subcategory_model.dart';
// import '../models/sidebar/subcategory_model.dart';

abstract class SubCategoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Initial state
class SubCategoryInitial extends SubCategoryState {}

// Loading state
class SubCategoryLoading extends SubCategoryState {}

// Loaded successfully
class SubCategoryLoaded extends SubCategoryState {
  final List<SubCategory> subcategories;
  final int? selectedSubCategory; // ID only

  SubCategoryLoaded({
    required this.subcategories,
    this.selectedSubCategory,
  });

  @override
  List<Object?> get props => [subcategories, selectedSubCategory];
}


// Error state
class SubCategoryError extends SubCategoryState {
  final String message;

  SubCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
