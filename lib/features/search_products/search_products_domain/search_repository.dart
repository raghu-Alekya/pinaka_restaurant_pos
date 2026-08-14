import 'package:restaurant_captain_app/features/search_products/search_products_domain/search_entity.dart';


abstract class SearchRepository {
  Future<List<SearchResultItem>> searchProducts(String query);
}