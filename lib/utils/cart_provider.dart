import 'package:flutter/material.dart';

import '../features/home_screen/order_menu/entities/product_entity.dart';

class CartItem {
  final ProductEntity product;
  final List<Map<String, dynamic>> addOns;
  int quantity;

  CartItem({
    required this.product,
    this.addOns = const [],
    this.quantity = 1,
  });

  String get key => '${product.id}_${addOns.map((a) => a['name']).join(',')}';

  double get unitPrice =>
      (double.tryParse(product.price ?? '0') ?? 0) +
          addOns.fold<double>(0, (sum, a) => sum + (a['price'] as double));

  double get totalPrice => unitPrice * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  Map<int, int> get quantitiesByProductId {
    final map = <int, int>{};
    for (final item in _items.values) {
      map[item.product.id] = (map[item.product.id] ?? 0) + item.quantity;
    }
    return map;
  }

  void addItem(ProductEntity product, int quantity, {List<Map<String, dynamic>> addOns = const []}) {
    final item = CartItem(product: product, addOns: addOns, quantity: quantity);
    final existing = _items[item.key];
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _items[item.key] = item;
    }
    notifyListeners();
  }

  void removeItem(String key) {
    _items.remove(key);
    notifyListeners();
  }

  void incrementItem(String key) {
    final item = _items[key];
    if (item != null) {
      item.quantity++;
      notifyListeners();
    }
  }

  void decrementItem(String key) {
    final item = _items[key];
    if (item != null) {
      if (item.quantity <= 1) {
        _items.remove(key);
      } else {
        item.quantity--;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}