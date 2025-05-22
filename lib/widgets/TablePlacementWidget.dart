import 'package\:flutter/material.dart';

class TablePlacementWidget extends StatefulWidget {
  final List<Map<String, dynamic>> placedTables;
  final double scale;
  final bool showPopup;
  final Function(Map<String, dynamic>, Offset) addTable;
  final Function(int, Offset) updateTablePosition;
  final Widget Function() buildAddContentPrompt;
  final Widget Function(int, Map<String, dynamic>) buildPlacedTable;
  final String? selectedArea;
  const TablePlacementWidget({
    Key? key,
    required this.placedTables,
    required this.scale,
    required this.showPopup,
    required this.addTable,
    required this.updateTablePosition,
    required this.buildAddContentPrompt,
    required this.buildPlacedTable,
    required this.selectedArea,
  }) : super(key: key);

  @override
  _TablePlacementWidgetState createState() => _TablePlacementWidgetState();
}

class _TablePlacementWidgetState extends State<TablePlacementWidget> {
  final ScrollController verticalScrollController = ScrollController();
  final ScrollController horizontalScrollController = ScrollController();
  final GlobalKey _canvasKey = GlobalKey();

  String? _selectedArea;

  List<String> get areaNames =>
      widget.placedTables
          .map((e) => e['areaName'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .toSet()
          .cast<String>()
          .toList();

  void _selectArea(String area) {
    setState(() {
      _selectedArea = area;
    });
  }

  @override
  void initState() {
    super.initState();
    if (areaNames.isNotEmpty) {
      _selectedArea = areaNames.first;
    }
  }

  @override
  void didUpdateWidget(covariant TablePlacementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedArea != oldWidget.selectedArea &&
        widget.selectedArea != _selectedArea) {
      setState(() {
        _selectedArea = widget.selectedArea;
      });
    }

    if (widget.placedTables.length != oldWidget.placedTables.length) {
      final lastTableArea =
      widget.placedTables.isNotEmpty
          ? widget.placedTables.last['areaName'] as String?
          : null;

      if (lastTableArea != null && lastTableArea != _selectedArea) {
        setState(() {
          _selectedArea = lastTableArea;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final visibleTables =
        _selectedArea == null
            ? widget.placedTables
            : widget.placedTables
                .where((e) => e['areaName'] == _selectedArea)
                .toList();

    return Column(
      children: [
        if (areaNames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: areaNames.map((area) {
                  final bool isSelected = _selectedArea == area;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0,vertical: 4.0),
                    child: TextButton(
                      onPressed: () => _selectArea(area),
                      style: TextButton.styleFrom(
                        backgroundColor: isSelected ? const Color(0xFFFD6464) : Colors.transparent,
                        foregroundColor: isSelected ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Pill-shaped
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.5,
                        ),
                      ),
                      child: Text(area),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        Expanded(
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thickness: WidgetStateProperty.all(12.0),
              radius: const Radius.circular(8),
              thumbVisibility: MaterialStateProperty.all(true),
              minThumbLength: 500,
              thumbColor: WidgetStateProperty.all(const Color(0xFFB6B6B6)),
              trackColor: WidgetStateProperty.all(Colors.grey.shade800),
            ),
            child: DragTarget<Map<String, dynamic>>(
              onAcceptWithDetails: (details) {
                final data = details.data;
                final dropOffset = details.offset;
                final RenderBox canvasBox =
                    _canvasKey.currentContext!.findRenderObject() as RenderBox;
                final localPosition = canvasBox.globalToLocal(dropOffset);

                final newArea = data['areaName'] as String? ?? '';

                setState(() {
                  // Immediately select the new table's area to filter correctly
                  _selectedArea = newArea.isNotEmpty ? newArea : _selectedArea;
                });

                widget.addTable(data, localPosition / widget.scale);
              },
              builder: (context, candidateData, rejectedData) {
                return ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(scrollbars: false),
                  child: Scrollbar(
                    controller: horizontalScrollController,
                    child: Scrollbar(
                      controller: verticalScrollController,
                      notificationPredicate: (_) => true,
                      child: SingleChildScrollView(
                        controller: horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: verticalScrollController,
                          scrollDirection: Axis.vertical,
                          child: Container(
                            key: _canvasKey,
                            width: 90000,
                            height: 60000,
                            alignment: Alignment.topLeft,
                            child: Transform.scale(
                              scale: widget.scale,
                              alignment: Alignment.topLeft,
                              child: Stack(
                                children: [
                                  if (visibleTables.isEmpty &&
                                      !widget.showPopup)
                                    widget.buildAddContentPrompt(),
                                  ...visibleTables.asMap().entries.map(
                                    (entry) => widget.buildPlacedTable(
                                      widget.placedTables.indexOf(entry.value),
                                      entry.value,
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: DragTarget<int>(
                                      onAcceptWithDetails: (details) {
                                        final index = details.data;
                                        final dropOffset = details.offset;
                                        final RenderBox canvasBox =
                                            _canvasKey.currentContext!
                                                    .findRenderObject()
                                                as RenderBox;
                                        final localPos = canvasBox
                                            .globalToLocal(dropOffset);
                                        widget.updateTablePosition(
                                          index,
                                          localPos / widget.scale,
                                        );
                                      },
                                      builder: (context, _, __) => Container(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
