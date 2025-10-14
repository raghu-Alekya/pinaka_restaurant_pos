// import 'package:equatable/equatable.dart';
// import '../models/category/category.dart';
import 'package:equatable/equatable.dart';

import '../../models/sidebar/category_model_.dart';
// import '../models/sidebar/category_model_.dart';

abstract class CategoryState extends Equatable {
  @override
  List<Object> get props => [];


}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  final Category? selectedCategory;

  CategoryLoaded({
    required this.categories,
    this.selectedCategory,
  });

  @override
  List<Object> get props => [categories, selectedCategory ?? ''];
}

class CategoryError extends CategoryState {
  final String message;

  CategoryError(this.message);

  @override
  List<Object> get props => [message];
}
