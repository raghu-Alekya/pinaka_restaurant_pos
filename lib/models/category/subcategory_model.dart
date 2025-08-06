class minisubcategory {
  final String name;
  final String imagePath;
  final double price;
  final bool isVeg;
  final bool isFolder;
  final List<minisubcategory> subItems;

  minisubcategory({
    required this.name,
    required this.imagePath,
    this.price = 0,
    this.isVeg = true,
    this.isFolder = false,
    this.subItems = const [],
  });

  factory minisubcategory.fromJson(Map<String, dynamic> json) {
    return minisubcategory(
      name: json['name'],
      imagePath: json['imagePath'],
      price: (json['price'] ?? 0).toDouble(),
      isVeg: json['isVeg'] ?? true,
      isFolder: json['isFolder'] ?? false,
      subItems: json['subItems'] != null
          ? (json['subItems'] as List)
          .map((e) => minisubcategory.fromJson(e))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'imagePath': imagePath,
    'price': price,
    'isVeg': isVeg,
    'isFolder': isFolder,
    'subItems': subItems.map((e) => e.toJson()).toList(),
  };
}
