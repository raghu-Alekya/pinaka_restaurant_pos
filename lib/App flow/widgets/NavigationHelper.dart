import 'package:flutter/material.dart';
import '../ui/KitchenStatusScreen.dart';
import '../../local database/table_dao.dart';
import '../ui/tables_screen.dart';
import '../ui/reservation_list_screen.dart';

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
    } else if (tappedIndex == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KitchenStatusScreen(
            pin: pin,
            associatedManagerPin: pin,
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
          builder: (context) => ReservationListScreen(
            pin: pin,
            token: token,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screen not implemented yet')),
      );
    }
  }
}