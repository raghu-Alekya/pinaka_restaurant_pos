class SearchResultItem {
  final int id;
  final String name;
  final String inStock;
  final String price;
  final String parentName;
  final String categoryName;

  SearchResultItem({
    required this.id,
    required this.name,
    required this.inStock,
    required this.price,
    required this.parentName,
    required this.categoryName,
  });
}
