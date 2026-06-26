class Product {
  final int id;
  final String name;
  final double price;
  final List<String> images;
  final String image; // first image or fallback
  final bool? isVeg;
  final List<Variant> variants;
  // 🔥 COMBO SUPPORT
  // final List<ComboItem> subItems;
  // ✅ ADD THIS
  final bool isCombo;
  final bool inStock;


  // ✅ New fields
  final List<String> modifiers;
  final List<String> addOns;
  final bool hasOptions;
  final bool isVariantProduct;


  // Constructor
  Product({
    required this.id,
    required this.name,
    required this.price,
    List<String>? images,
     this.isVeg,
    required this.isCombo,
    // ✅ default false (VERY IMPORTANT)
    // this.subItems = const [],
    required this.variants,
    List<String>? modifiers,
    List<String>? addOns,
    bool? hasOptions,
    this.inStock = true,
    String? image,
    this.isVariantProduct = false,
  })  : images = images ?? [],
        image = image ?? (images != null && images.isNotEmpty ? images.first : ''),
        modifiers = modifiers ?? [],
        addOns = addOns ?? [],
        hasOptions = hasOptions ?? ((modifiers?.isNotEmpty ?? false) || (addOns?.isNotEmpty ?? false));

  // ✅ copyWith for immutability
  Product copyWith({
    int? id,
    String? name,
    double? price,
    List<String>? images,
    String? image,
    bool? isVeg,
    bool? isCombo,
    bool? inStock,
    List<Variant>? variants,
    List<String>? modifiers,
    List<String>? addOns,
    bool? hasOptions,
    bool? isVariantProduct,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      images: images ?? this.images,
      image: image ?? (images != null && images.isNotEmpty ? images.first : this.image),
      isVeg: isVeg ?? this.isVeg,
      isCombo: isCombo ?? this.isCombo,
      inStock: inStock ?? this.inStock,

      variants: variants ?? this.variants,
      modifiers: modifiers ?? this.modifiers,
      addOns: addOns ?? this.addOns,
      hasOptions: hasOptions ?? ((modifiers ?? this.modifiers).isNotEmpty ||
          (addOns ?? this.addOns).isNotEmpty),
      isVariantProduct: isVariantProduct ?? this.isVariantProduct, // 👈
    );
  }

  // fromJson
  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse images safely
    final images = (json['images'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        [];
    // 🔹 Parse sub-items (COMBO)
    final List<ComboProduct> parsedSubItems =
        (json['sub-items'] as List<dynamic>?)
            ?.map((e) => ComboProduct.fromJson(e))
            .toList() ??
            [];


    // Parse modifiers and addOns safely
    final modifiers = (json['modifiers'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        [];
    final addOns = (json['addOns'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        [];


    // Unified isVeg parsing
    bool? parsedIsVeg;
    final rawIsVeg =
        json['is_veg'] ?? json['isVeg'] ?? json['veg_type'] ?? json['type'];
    if (rawIsVeg != null) {
      final val = rawIsVeg.toString().toLowerCase().trim();
      if (val == 'true' || val == '1' || val == 'veg') parsedIsVeg = true;
      else if (val == 'false' || val == '0' || val == 'nonveg')
        parsedIsVeg = false;
    }


    // Parse variants safely, fallback if API uses a different field
    List<Variant> parsedVariants = [];
    final variantJsonList = (json['variants'] ?? json['variant_list']) as List<dynamic>?;
    if (variantJsonList != null) {
      try {
        parsedVariants = variantJsonList.map((v) => Variant.fromJson(v)).toList();
      } catch (e) {
        print("⚠️ Error parsing variants for product ${json['name']}: $e");
      }
    }


    // Parse hasOptions safely
    final hasOptionsParsed = (modifiers.isNotEmpty || addOns.isNotEmpty) ||
        (json['hasOptions'] == true);
    final rawIsVariant = json['is_variant']?.toString().toLowerCase();
    final bool parsedIsVariant = rawIsVariant == 'yes' || rawIsVariant == 'true' || rawIsVariant == '1';


    return Product(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      images: images,
      // subItems: parsedSubItems,
      isVeg: parsedIsVeg,
      isCombo: json['is_combo']?.toString().toLowerCase() == 'yes',
      inStock: json['in_stock']?.toString().toLowerCase() == 'yes',
      variants: parsedVariants,
      image: json['image'] ??
          (images.isNotEmpty ? images.first : ''), // fallback image
      modifiers: modifiers,
      addOns: addOns,
      hasOptions: hasOptionsParsed,
        isVariantProduct: parsedIsVariant,
    );
  }



  // toJson
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "price": price,
      "images": images,
      "image": image,
      "isVeg": isVeg,
      "variants": variants.map((v) => v.toJson()).toList(),
      "modifiers": modifiers,
      "addOns": addOns,
      "hasOptions": hasOptions,
    };
  }
}


class Variant {
  final int productId;
  final int variationId;
  final String name;
  final String image;
  final double price;
  final int quantity;

  Variant({
    required this.productId,
    required this.variationId,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
  });

  // ✅ copyWith for immutability
  Variant copyWith({
    int? productId,
    int? variationId,
    String? name,
    String? image,
    double? price,
    int? quantity,
  }) {
    return Variant(
      productId: productId ?? this.productId,
      variationId: variationId ?? this.variationId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      productId: json['product_id'] ?? 0,
      variationId: json['variation_id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'variation_id': variationId,
    'name': name,
    'image': image,
    'price': price,
    'quantity': quantity,
  };
}
class ComboProduct {
  final int id;
  final String name;
  final double price;
  final List<ComboSubItem> subItems;

  ComboProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.subItems,
  });

  factory ComboProduct.fromJson(Map<String, dynamic> json) {
    return ComboProduct(
      id: json['item id'],
      name: json['item name'],
      price: (json['item price'] as num).toDouble(),
      subItems: (json['sub-items'] as List)
          .map((e) => ComboSubItem.fromJson(e))
          .toList(),
    );
  }
}
class ComboSubItem {
  final int id;
  final String name;
  final double price;
  final int quantity;

  ComboSubItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory ComboSubItem.fromJson(Map<String, dynamic> json) {
    return ComboSubItem(
      id: json['id'] ?? 0,               // ✅ FIX
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }
}

