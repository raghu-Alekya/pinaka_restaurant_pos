import 'package:flutter/material.dart';
// import '../../models/inventory/SearchCategory.dart';
import '../../models/inventory/search_category.dart';
// import '../../repositories/inventory_repository/SearchCategory_Repository.dart';
import '../../repositories/search_category_repository.dart';


class CustomDropdownCard extends StatefulWidget {
  final String token;
  final String baseUrl;
  final Function(SearchCategory) onSelected;

  const CustomDropdownCard({
    super.key,
    required this.token,
    required this.baseUrl,
    required this.onSelected,
  });

  @override
  State<CustomDropdownCard> createState() => _CustomDropdownCardState();
}

class _CustomDropdownCardState extends State<CustomDropdownCard>
    with SingleTickerProviderStateMixin {
  List<SearchCategory> categories = [];
  String selectedCategoryName = 'Loading...';
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    print('🔹 Fetching categories from API...');
    try {
      final repo = SearchCategoryRepository(baseUrl: widget.baseUrl);
      print('🔹 URL: ${widget.baseUrl}/wp-json/pinaka-restaurant-pos/v1/inventories/get-search-categories');
      print('🔹 Token: ${widget.token.substring(0, 10)}...'); // print only part of token for safety

      final data = await repo.fetchSearchCategories(token: widget.token);

      print('✅ API call successful. Categories fetched: ${data.length}');
      for (var cat in data) {
        print('    ${cat.id} - ${cat.name}');
      }

      setState(() {
        categories = data;
        if (categories.isNotEmpty) {
          selectedCategoryName = categories.first.name;
        }
      });
    } catch (e, st) {
      print('❌ Error fetching categories: $e');
      print('Stack trace: $st');
      setState(() {
        selectedCategoryName = 'Error loading';
      });
    }
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _controller.forward();
      setState(() => _isOpen = true);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _controller.reverse();
      setState(() => _isOpen = false);
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: categories.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              )
                  : ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: categories.map((category) {
                  return ListTile(
                    title: Text(
                      category.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    onTap: () {
                      setState(() {
                        selectedCategoryName = category.name;
                      });
                      widget.onSelected(category);
                      _toggleDropdown();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedCategoryName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Transform.rotate(
                    angle: _controller.value * 3.1416,
                    child: child,
                  );
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/down_arrow.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}