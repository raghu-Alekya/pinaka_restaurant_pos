// widgets/ZoomControlsWidget.dart
import 'package:flutter/material.dart';

class ZoomControlsWidget extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onScaleToFit;

  const ZoomControlsWidget({
    Key? key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onScaleToFit,
  }) : super(key: key);

  Widget _zoomButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 15, color: Colors.black87),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _zoomButton(icon: Icons.add, onTap: onZoomIn),
          SizedBox(height: 10),
          _zoomButton(icon: Icons.remove, onTap: onZoomOut),
          SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 30,
                child: _zoomButton(icon: Icons.fit_screen, onTap: onScaleToFit),
              ),
              SizedBox(width: 8),
              Text(
                "Scaled to fit",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4C5F7D),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
