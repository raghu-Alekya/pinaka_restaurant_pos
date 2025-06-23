// lib/helpers/NavigationHelper.dart

import 'package:flutter/material.dart';
import '../../helpers/DatabaseHelper.dart';
import '../CaptainFlow/ui/CaptainDashboardScreen.dart';
import '../CaptainFlow/ui/CaptainTablesScreen.dart';
import '../CaptainFlow/ui/KitchenStatusScreen.dart';

class CaptionNavigationHelper {
  static void handleNavigation(
      BuildContext context,
      int currentIndex,
      int tappedIndex,
      String pin,
      String associatedManagerPin, // ✅ Add this
      ) async {
    if (tappedIndex == currentIndex) return;

    if (tappedIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            pin: pin,
            associatedManagerPin: associatedManagerPin, // ✅ Pass correctly
          ),
        ),
      );
    } else if (tappedIndex == 1) {
      final dbHelper = DatabaseHelper();
      final tables = await dbHelper.getTablesByManagerPin(associatedManagerPin);
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
          builder: (context) => KitchenStatusScreen(pin: pin, associatedManagerPin: associatedManagerPin),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Screen not implemented yet')),
      );
    }
  }
}
