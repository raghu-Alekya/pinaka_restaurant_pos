import 'package:flutter/material.dart';

class TableStatusColors {
  static const Map<String, Color> tableColors = {
    "available": Color(0xFFBEE8BF),
    "dine in": Color(0xFFF7DDDB),
    "occupied": Color(0xFFEACA00), // Lemon Yellow
    "running": Color(0xFFEACA00),
    "reserve": Color(0xFFE0E0E0),
    "ready to pay": Color(0xFF4C81F1),
    "ready_to_pay": Color(0xFF4C81F1),
  };

  static const Map<String, Color> chairColors = {
    "available": Color(0xFF4CAF50),
    "dine in": Color(0xFFF44336),
    "occupied": Color(0xFFEACA00), // Darker Lemon Yellow
    "running": Color(0xFFEACA00),
    "reserve": Colors.grey,
    "ready to pay": Color(0xFF1E40AF),
    "ready_to_pay": Color(0xFF1E40AF),
  };

  static Color getTableColor(String status) {
    final key = status.trim().toLowerCase();
    if (key == 'ready to pay' || key == 'ready_to_pay' || key == 'readytopay') {
      return const Color(0xFF4C81F1);
    }
    return tableColors[key] ?? const Color(0xFFE0E0E0);
  }

  static Color getChairColor(String status) {
    final key = status.trim().toLowerCase();
    if (key == 'ready to pay' || key == 'ready_to_pay' || key == 'readytopay') {
      return const Color(0xFF1E40AF);
    }
    return chairColors[key] ?? Colors.black;
  }
}