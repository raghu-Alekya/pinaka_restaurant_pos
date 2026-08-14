import 'package:equatable/equatable.dart';
import '../search_products_domain/search_entity.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<SearchResultItem> results;

  const SearchLoaded({required this.results});

  @override
  List<Object> get props => [results];
}

class SearchError extends SearchState {
  final String message;

  const SearchError({required this.message});

  @override
  List<Object> get props => [message];
}