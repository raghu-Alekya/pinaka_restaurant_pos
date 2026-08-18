import '../search_products_domain/search_entity.dart';

class SearchResponse {
  final bool success;
  final int count;
  final List<SearchResultItem> data;

  SearchResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      data: (json['data'] as List?)
          ?.map((e) => SearchResultItem(
        id: e['id'] ?? 0,
        name: e['name'] ?? '',
        inStock: e['in_stock'] ?? 'No',
        price: e['price'] ?? '0',
        parentName: e['parent_name'] as String? ?? '', // 👈 new
      ))
          .toList() ??
          [],
    );
  }
}