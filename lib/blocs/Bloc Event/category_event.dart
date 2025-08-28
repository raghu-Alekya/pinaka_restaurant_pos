import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  @override
  List<Object> get props => [];
}

// Load all categories
class LoadCategories extends CategoryEvent {
  final String token;
  final String restaurantId;

  LoadCategories({required this.token, required this.restaurantId});

  @override
  List<Object> get props => [token, restaurantId];
}

// Select a category to show subcategories
class SelectCategory extends CategoryEvent {
  final String categoryId;

  SelectCategory(this.categoryId);

  @override
  List<Object> get props => [categoryId];
}
