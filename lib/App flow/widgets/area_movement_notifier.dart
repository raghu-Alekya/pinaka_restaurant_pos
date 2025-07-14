import 'package:flutter/material.dart';

class AreaMovementNotifier {
  static OverlayEntry? _areaPopupEntry;

  static void showPopup({
    required BuildContext context,
    required String fromArea,
    required String toArea,
    required String tableName,
    double? oldRotation,
    double? newRotation,
    Offset? oldPos,
    Offset? newPos,
    Duration duration = const Duration(seconds: 3),
  }) {
    _areaPopupEntry?.remove();

    String message;
    final isArea = tableName.toLowerCase().contains('area');
    final isRename = isArea && fromArea.isNotEmpty && toArea.isNotEmpty && fromArea != toArea;
    final isRotated = oldRotation != null &&
        newRotation != null &&
        oldRotation != newRotation;

    if (isRename) {
      message = 'Area renamed to "$toArea"';
    } else if (fromArea.isEmpty && toArea.isNotEmpty) {
      message = isArea
          ? 'Area "$toArea" created successfully'
          : 'Table "$tableName" added to "$toArea"';
    } else if (toArea.isEmpty && fromArea.isNotEmpty) {
      message = isArea
          ? 'Area "$fromArea" deleted'
          : 'Table "$tableName" deleted from "$fromArea"';
    } else if (isArea && fromArea != toArea) {
      message = 'Area moved from "$fromArea" to "$toArea"';
    } else if (!isArea && fromArea != toArea) {
      message = 'Table "$tableName" moved from "$fromArea" to "$toArea"';
    } else if (!isArea && isRotated) {
      message = 'Table "$tableName" rotated to ${newRotation?.toInt()}°';
    } else {
      message = 'Updated "$tableName"';
    }

    _areaPopupEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4C5F7D),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_areaPopupEntry!);

    Future.delayed(duration, () {
      _areaPopupEntry?.remove();
      _areaPopupEntry = null;
    });
  }
}