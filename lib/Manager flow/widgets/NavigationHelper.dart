// lib/helpers/NavigationHelper.dart

import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/Manager%20flow/ui/ManagerDashboardScreen.dart';
import '../../helpers/DatabaseHelper.dart';
import '../ui/tables_screen.dart';


class NavigationHelper {
  static void handleNavigation(BuildContext context, int currentIndex, int tappedIndex, String pin) async {
    if (tappedIndex == currentIndex) return;

    if (tappedIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ManagerDashboardScreen(pin: pin)),
      );
    } else if (tappedIndex == 1) {
      final dbHelper = DatabaseHelper();
      final tables = await dbHelper.getTablesByManagerPin(pin);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TablesScreen(loadedTables: tables, pin: pin,),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Screen not implemented yet')),
      );
    }
  }
}
