import 'package:flutter/material.dart';
import '../App flow/widgets/area_movement_notifier.dart';

class PermissionHandler {
  static void handleNoPermission(
      BuildContext context, {
        required Widget fallbackScreen,
        String customMessage = "No permission to access this feature",
      }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => fallbackScreen),
        );
        AreaMovementNotifier.showPopup(
          context: context,
          fromArea: '',
          toArea: '',
          tableName: 'Permission',
          customMessage: customMessage,
        );
      }
    });
  }
}
