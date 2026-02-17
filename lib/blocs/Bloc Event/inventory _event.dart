import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class FetchProducts extends ProductEvent {
  final String? search;
  final String? sku;
  final String? filter;
  final int? categoryId;

  const FetchProducts({this.search, this.sku, this.filter, this.categoryId});

  @override
  List<Object?> get props => [search, sku, filter, categoryId];
}