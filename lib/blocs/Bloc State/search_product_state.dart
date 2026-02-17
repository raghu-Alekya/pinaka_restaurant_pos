// import '../models/product_model.dart';

import '../../models/search/search_model.dart';

abstract class SearchProductState {}

class SearchProductInitial extends SearchProductState {}

class SearchProductLoading extends SearchProductState {}

class SearchProductLoaded extends SearchProductState {
  final List<Search_ProductModel> products;

  SearchProductLoaded(this.products);
}

class SearchProductEmpty extends SearchProductState {}

class SearchProductError extends SearchProductState {
  final String message;

  SearchProductError(this.message);
}
