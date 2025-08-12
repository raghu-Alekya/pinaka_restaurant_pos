import 'package:equatable/equatable.dart';
import '../models/category/minisubcategory_model.dart';
// import '../models/minisubcategory_model.dart';

abstract class MiniSubCategoryState extends Equatable {
  const MiniSubCategoryState();

  @override
  List<Object?> get props => [];
}

class MiniSubCategoryInitial extends MiniSubCategoryState {}

class MiniSubCategoryLoading extends MiniSubCategoryState {}

class MiniSubCategoryLoaded extends MiniSubCategoryState {
  final List<MiniSubCategory> miniSubCategories;
  final MiniSubCategory? selectedMiniSubCategory;

  const MiniSubCategoryLoaded(this.miniSubCategories, {this.selectedMiniSubCategory});

  @override
  List<Object?> get props => [miniSubCategories, selectedMiniSubCategory ?? ''];
}

class MiniSubCategoryError extends MiniSubCategoryState {
  final String message;

  const MiniSubCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
