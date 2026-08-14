import 'package:restaurant_captain_app/features/search_products/search_products_domain/search_entity.dart';
import 'package:restaurant_captain_app/features/search_products/search_products_domain/search_repository.dart';


class SearchUseCase {
  final SearchRepository repository;

  SearchUseCase({required this.repository});

  Future<List<SearchResultItem>> call(String query) async {
    if (query.trim().isEmpty) return [];
    return await repository.searchProducts(query);
  }
}