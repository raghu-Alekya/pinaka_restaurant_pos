import 'package:flutter/material.dart';
import '../../models/category/subcategory_model.dart';

class SubCategoryTabWidget extends StatefulWidget {
  final List<SubCategory> subCategories;
  final int? selectedIndex;
  final Function(int)? onTap;

  const SubCategoryTabWidget({
    super.key,
    required this.subCategories,
    this.selectedIndex,
    this.onTap,
  });

  @override
  State<SubCategoryTabWidget> createState() => _SubCategoryTabWidgetState();
}

class _SubCategoryTabWidgetState extends State<SubCategoryTabWidget> {
  final ScrollController _scrollController = ScrollController();
  late int _selectedIndex;
  // bool _defaultTriggered = false; // to load default mini-subcategory once
  bool _showLeftArrow = false;
  bool _showRightArrow = false;
  bool _isScrollable = false;
  @override
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex ?? -1;

    _scrollController.addListener(_updateArrows);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrows();
    });
  }
  @override
  void dispose() {
    _scrollController.removeListener(_updateArrows);
    _scrollController.dispose();
    super.dispose();
  }
  void _updateArrows() {
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;

    setState(() {
      _isScrollable = maxExtent > 0;
      _showLeftArrow = _isScrollable && _scrollController.offset > 0;
      _showRightArrow =
          _isScrollable && _scrollController.offset < maxExtent;
    });
  }
  @override
  void didUpdateWidget(covariant SubCategoryTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateArrows();
      }
    });
    if (widget.subCategories != oldWidget.subCategories &&
        widget.subCategories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          _selectedIndex = 0;
        });
      });
    }

    if (widget.selectedIndex != oldWidget.selectedIndex &&
        widget.selectedIndex != null) {
      setState(() {
        _selectedIndex = widget.selectedIndex!;
      });
    }
  }




  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 100).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      (_scrollController.offset + 100).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subCategories.isEmpty) return const SizedBox(height: 50);

    return Container(
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Color(0XFFFFFFFF),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        borderRadius: BorderRadius.circular(12),
        // boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 0, offset: Offset(1, 2))],
        boxShadow: const [
          BoxShadow(color: Colors.white, blurRadius: 3, offset: Offset(0, 0)),
        ],
      ),
      height: 114,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.subCategories.length,
              itemBuilder: (context, index) {
                final category = widget.subCategories[index];
                final isSelected = _selectedIndex >= 0 && index == _selectedIndex;


                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    widget.onTap?.call(index); // triggers mini-subcategory load
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFE5E8)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF364C)
                            : const Color(0xFFC4C7D1),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 10,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // Image
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: category.imagePath != null &&
                              category.imagePath!.isNotEmpty
                              ? Image.network(
                            category.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFD9D9D9),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 28,
                              ),
                            ),
                          )
                              : Container(
                            color: const Color(0xFFD9D9D9),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 28,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            category.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFFFF364C)
                                  : const Color(0xFF4C5F7D),
                              fontSize: 12,
                              fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                              letterSpacing: 0.6,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showLeftArrow)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 32, // circular size
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white, // background color of the circle
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero, // remove default padding
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: _scrollLeft,
                    color: Colors.black,
                    splashRadius: 20,
                  ),
                ),
              ),
            ),
          if (_showRightArrow)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 32, // circular size
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white, // background color of the circle
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero, // remove default padding
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: _scrollRight,
                    color: Colors.black,
                    splashRadius: 20,
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }
}