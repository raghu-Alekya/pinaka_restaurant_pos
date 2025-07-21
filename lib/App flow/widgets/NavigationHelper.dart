import 'package:flutter/material.dart';
import '../ui/ManagerDashboardScreen.dart';
import '../ui/KitchenStatusScreen.dart';
import '../../local database/table_dao.dart';
import '../ui/tables_screen.dart';

class NavigationHelper {
  static void handleNavigation(
      BuildContext context,
      int currentIndex,
      int tappedIndex,
      String pin,
      String token,
      String restaurantId,
      String restaurantName,
      ) async {
    if (tappedIndex == currentIndex) return;

    if (tappedIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ManagerDashboardScreen(
            pin: pin,
            token: token,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
          ),
        ),
      );
    } else if (tappedIndex == 1) {
      final tableDao = TableDao();
      final tables = await tableDao.getTablesByManagerPin(pin);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TablesScreen(
            loadedTables: tables,
            pin: pin,
            token: token,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
          ),
        ),
      );
    } else if (tappedIndex == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KitchenStatusScreen(
            pin: pin,
            associatedManagerPin: pin, // or another relevant value
            token: token,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Screen not implemented yet')),
      );
    }
  }
}
