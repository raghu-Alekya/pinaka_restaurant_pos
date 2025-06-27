import 'package:flutter/material.dart';

class TablePlacementWidget extends StatefulWidget {
  final List<Map<String, dynamic>> placedTables;
  final double scale;
  final bool showPopup;
  final Function(Map<String, dynamic>, Offset) addTable;
  final Function(int, Offset) updateTablePosition;
  final Widget Function() buildAddContentPrompt;
  final Widget Function(int, Map<String, dynamic>) buildPlacedTable;
  final String? selectedArea;
  final VoidCallback onTapOutside;
  final bool isLoading;

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
    required this.onTapOutside,
    required this.isLoading,
  }) : super(key: key);

  @override
  _TablePlacementWidgetState createState() => _TablePlacementWidgetState();
}

class _TablePlacementWidgetState extends State<TablePlacementWidget> {
  final ScrollController verticalScrollController = ScrollController();
  final ScrollController horizontalScrollController = ScrollController();
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final visibleTables = widget.selectedArea == null
        ? widget.placedTables
        : widget.placedTables
        .where((e) => e['areaName'] == widget.selectedArea)
        .toList();

    return Column(
      children: [
        Expanded(
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thickness: WidgetStateProperty.all(12.0),
              radius: const Radius.circular(8),
              thumbVisibility: WidgetStateProperty.all(true),
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
                          child: Transform.scale(
                            scale: widget.scale,
                            alignment: Alignment.topLeft,
                            child: Container(
                              key: _canvasKey,
                              width: 90000 / widget.scale,
                              height: 60000 / widget.scale,
                              alignment: Alignment.topLeft,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: widget.onTapOutside,
                                child: Stack(
                                  children: [
                                    if (visibleTables.isEmpty &&
                                        !widget.showPopup &&
                                        !widget.isLoading) // ✅ only show if not loading
                                      widget.buildAddContentPrompt(),
                                    ...visibleTables.asMap().entries.map(
                                          (entry) => widget.buildPlacedTable(
                                        widget.placedTables
                                            .indexOf(entry.value),
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
                                              .findRenderObject() as RenderBox;
                                          final localPos = canvasBox
                                              .globalToLocal(dropOffset);
                                          widget.updateTablePosition(
                                            index,
                                            localPos / widget.scale,
                                          );
                                        },
                                        builder: (context, _, __) =>
                                            Container(),
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
