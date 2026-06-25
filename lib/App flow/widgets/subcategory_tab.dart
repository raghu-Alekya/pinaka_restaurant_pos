
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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex ?? -1; // no default selection
    // Do NOT call widget.onTap here, wait for user tap
  }



  @override
  void didUpdateWidget(covariant SubCategoryTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Color(0XFFDEE8FF),
        border: Border.all(color: Color(0xFFFFFFFF), width: 1),
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
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    padding: const EdgeInsets.all(6),
                    width: 75,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFCDFDC) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected
                          ? const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        category.imagePath != null && category.imagePath!.isNotEmpty
                            ? Image.network(
                          category.imagePath!,
                          height: 55,
                          width: 45,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 30),
                        )
                            : const Icon(Icons.image, size: 28),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            category.name,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.deepOrange : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
