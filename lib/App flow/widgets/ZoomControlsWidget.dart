// widgets/ZoomControlsWidget.dart
import 'package:flutter/material.dart';

/// A widget displaying zoom control buttons positioned at the bottom left of the screen.
///
/// Includes buttons for zooming in, zooming out, and scaling content to fit the screen.
/// Each button triggers a respective callback when tapped.
class ZoomControlsWidget extends StatelessWidget {
  /// Callback triggered when the Zoom In button is tapped.
  final VoidCallback onZoomIn;

  /// Callback triggered when the Zoom Out button is tapped.
  final VoidCallback onZoomOut;

  /// Callback triggered when the Scale to Fit button is tapped.
  final VoidCallback onScaleToFit;

  /// Creates a ZoomControlsWidget.
  ///
  /// All callbacks are required and must not be null.
  const ZoomControlsWidget({
    Key? key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onScaleToFit,
  }) : super(key: key);

  /// Builds a single zoom control button with a given [icon] and [onTap] callback.
  ///
  /// The button is a small square with white background, rounded corners, and a subtle shadow.
  Widget _zoomButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 70,
      left: 30,

      /// Arranges the zoom buttons vertically with spacing.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _zoomButton(  context: context,icon: Icons.add, onTap: onZoomIn),
          SizedBox(height: 10),
          _zoomButton(  context: context,icon: Icons.remove, onTap: onZoomOut),
          SizedBox(height: 10),

          /// Scale to fit button with label next to it.
          Row(
            children: [
              SizedBox(
                width: 30,
                child: _zoomButton(
                  icon: Icons.fit_screen,
                  onTap: onScaleToFit,  context: context,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Scaled to fit",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
