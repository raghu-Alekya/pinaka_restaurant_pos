import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kitchen_order.dart';

class OrderLocalStorage {
  static const _key = 'kds_saved_orders';

  Future<List<KitchenOrder>> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List;
    return list
        .map((e) => KitchenOrder.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveOrders(List<KitchenOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = orders.map((o) => o.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}