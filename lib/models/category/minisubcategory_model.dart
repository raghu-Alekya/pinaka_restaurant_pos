import '../../widgets/variant_popup.dart';

class MiniSubCategory {
  final String id;
  final String name;
  final String imagePath;
  final bool isVeg;
  final double _price;
  final bool isFolder;
  final List<MiniSubCategory>? items; // Folder contents
  final List<Variant>? variants; // Product variants

  MiniSubCategory({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.isVeg,
    required double price,
    required this.isFolder,
    this.items,
    this.variants,
  }) : _price = price;

  bool get hasVariants => variants != null && variants!.isNotEmpty;

  double? get price {
    if (!hasVariants && items != null && items!.isNotEmpty) {
      return items!.first.price;
    }
    return _price;
  }

  factory MiniSubCategory.fromJson(Map<String, dynamic> json) {
    return MiniSubCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imagePath: json['imagePath'] ?? '',
      isVeg: json['isVeg'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
      isFolder: json['isFolder'] ?? false,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => MiniSubCategory.fromJson(e))
          .toList(),
      variants: (json['variants'] as List<dynamic>?)
          ?.map((v) => Variant.fromJson(v))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'isVeg': isVeg,
      'price': _price,
      'isFolder': isFolder,
      'items': items?.map((e) => e.toJson()).toList(),
      'variants': variants?.map((v) => v.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'MiniSubCategory(id: $id, name: $name, isFolder: $isFolder, price: $price)';
  }
}

class Variant {
  final String id;
  final String name;
  final String imageUrl;
  final double price;

  Variant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
    };
  }

  @override
  String toString() {
    return 'Variant(id: $id, name: $name, price: $price)';
  }
}
