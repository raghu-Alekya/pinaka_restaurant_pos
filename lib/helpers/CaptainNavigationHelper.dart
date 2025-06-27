import 'package:flutter/material.dart';
import '../CaptainFlow/ui/CaptainDashboardScreen.dart';
import '../CaptainFlow/ui/CaptainTablesScreen.dart';
import '../CaptainFlow/ui/KitchenStatusScreen.dart';
import '../local database/table_dao.dart';

class CaptionNavigationHelper {
  static void handleNavigation(
      BuildContext context,
      int currentIndex,
      int tappedIndex,
      String pin,
      String associatedManagerPin,
      ) async {
    if (tappedIndex == currentIndex) return;

    if (tappedIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            pin: pin,
            associatedManagerPin: associatedManagerPin,
          ),
        ),
      );
    } else if (tappedIndex == 1) {
      final tableDao = TableDao();
      final tables = await tableDao.getTablesByManagerPin(associatedManagerPin);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CaptionTablesScreen(
            loadedTables: tables,
            pin: pin,
            associatedManagerPin: associatedManagerPin,
          ),
        ),
      );
    } else if (tappedIndex == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KitchenStatusScreen(
            pin: pin,
            associatedManagerPin: associatedManagerPin,
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
