import 'package:flutter/material.dart';

class AreaMovementNotifier {
  static OverlayEntry? _areaPopupEntry;

  static void showPopup({
    required BuildContext context,
    required String fromArea,
    required String toArea,
    required String tableName,
    Duration duration = const Duration(seconds: 3),
  }) {
    _areaPopupEntry?.remove();

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
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              'Table "$tableName" moved from "$fromArea" to "$toArea"',
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