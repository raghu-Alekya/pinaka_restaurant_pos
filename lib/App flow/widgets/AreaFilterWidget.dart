import 'package:flutter/material.dart';

class AreaFilterWidget extends StatelessWidget {
  final List<String> areaNames;
  final String selectedArea;
  final Function(String) onAreaSelected;

  const AreaFilterWidget({
    Key? key,
    required this.areaNames,
    required this.selectedArea,
    required this.onAreaSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (areaNames.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: areaNames.map((area) {
          final bool isSelected = selectedArea == area;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: TextButton(
              onPressed: () => onAreaSelected(area),
              style: TextButton.styleFrom(
                backgroundColor: isSelected
                    ? const Color(0xFFFD6464)
                    : Colors.transparent,
                foregroundColor: isSelected ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 13.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(area),
            ),
          );
        }).toList(),
      ),
    );
  }
}
