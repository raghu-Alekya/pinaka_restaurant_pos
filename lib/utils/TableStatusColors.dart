import 'dart:ui';
import 'package:flutter/material.dart';

class TableStatusColors {
  static const Map<String, Color> tableColors = {
    "available": Color(0xFFBEE8BF),
    "dine in": Color(0xFFF7DDDB),
    "reserve": Color(0xFFE0E0E0),
    "ready to pay": Color(0xFFC9D6F2),
  };

  static const Map<String, Color> chairColors = {
    "available": Color(0xFF4CAF50),
    "dine in": Color(0xFFF44336),
    "reserve": Colors.grey,
    "ready to pay": Color(0xFF4C81F1),
  };

  static Color getTableColor(String status) {
    final key = status.trim().toLowerCase();
    return tableColors[key] ?? Color(0xFFE0E0E0);
  }

  static Color getChairColor(String status) {
    final key = status.trim().toLowerCase();
    return chairColors[key] ?? Colors.black;
  }
}
