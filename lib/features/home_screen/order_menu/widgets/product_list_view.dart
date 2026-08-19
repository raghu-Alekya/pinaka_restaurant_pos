import 'dart:async';
import 'package:flutter/material.dart';
import '../entities/category_entity.dart';
import '../entities/product_entity.dart';
import 'product_card.dart';

class ProductListView extends StatefulWidget {
  final List<SubcategoryEntity> subcategories;
  final List<ProductEntity> directProducts;
  final Map<int, List<ProductEntity>> subcategoryProducts;
  final Map<int, List<MiniSubcategoryEntity>> miniSubcategoriesMap;
  final Map<int, int> cartQuantitiesByProductId;

  final String? selectedLanguage;
  final int? selectedSubcategoryId;
  final bool vegOnly;
  final bool nonVegOnly;

  final ValueChanged<ProductEntity> onAdd;
  final ValueChanged<ProductEntity> onRemove;
  final ValueChanged<ProductEntity> onVariantTap;

  /// Called when the visible subcategory changes during scrolling.
  /// Only called when selectedSubcategoryId == null (i.e., "All" is active).
  final ValueChanged<int?> onVisibleSubcategoryChanged;

  /// Currency symbol from captain login (e.g., ₹, $)
  final String currencySymbol; // 👈 new

  const ProductListView({
    Key? key,
    required this.subcategories,
    required this.directProducts,
    this.subcategoryProducts = const {},
    this.miniSubcategoriesMap = const {},
    required this.cartQuantitiesByProductId,
    required this.selectedLanguage,
    this.selectedSubcategoryId,
    required this.onAdd,
    required this.onRemove,
    required this.onVariantTap,
    required this.onVisibleSubcategoryChanged,
    required this.currencySymbol, // 👈 required
    this.vegOnly = false,
    this.nonVegOnly = false,
  }) : super(key: key);

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};
  bool _isScrolling = false;
  int? _lastNotifiedId;

  // 👈 NEW: throttles how often we walk the render tree to find the
  // currently visible section. Previously this ran on every single
  // scroll callback (i.e. many times per frame during a fast fling),
  // which is expensive and was contributing to the flicker/jank while
  // scrolling. Now it runs at most every 80ms.
  Timer? _scrollThrottleTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectVisibleSection();
    });
  }

  @override
  void dispose() {
    _scrollThrottleTimer?.cancel(); // 👈 NEW
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProductListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subcategories != widget.subcategories) {
      _sectionKeys.clear();
      for (final sub in widget.subcategories) {
        _sectionKeys[sub.id] = GlobalKey();
      }
    }
  }

  void _onScroll() {
    // 👈 NEW: real throttle. The old `_isScrolling` boolean guard never
    // actually blocked anything (it was set true then immediately reset
    // false within the same synchronous call), so detection ran on every
    // scroll notification. This replaces it with a proper timer-based
    // throttle without touching the detection logic itself.
    _scrollThrottleTimer?.cancel();
    _scrollThrottleTimer = Timer(const Duration(milliseconds: 80), () {
      if (mounted) _detectVisibleSection();
    });
  }

  void _detectVisibleSection() {
    if (widget.selectedSubcategoryId != null) {
      if (_lastNotifiedId != null) {
        _lastNotifiedId = null;
        widget.onVisibleSubcategoryChanged(null);
      }
      return;
    }

    final RenderBox? viewportBox = context.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.attached) return;
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;

    int? visibleId;
    double? minDistance;

    for (final entry in _sectionKeys.entries) {
      final key = entry.value;
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      final top = box.localToGlobal(Offset.zero).dy - viewportTop;
      if (top >= 0) {
        final distance = top;
        if (minDistance == null || distance < minDistance) {
          minDistance = distance;
          visibleId = entry.key;
        }
      }
    }

    if (visibleId == null && _sectionKeys.isNotEmpty) {
      visibleId = _sectionKeys.keys.last;
    }

    if (visibleId != _lastNotifiedId) {
      _lastNotifiedId = visibleId;
      widget.onVisibleSubcategoryChanged(visibleId);
    }
  }

  List<ProductEntity> _filter(List<ProductEntity> products) {
    if (!widget.vegOnly && !widget.nonVegOnly) return products;
    return products.where((p) {
      final nonVeg = isNonVegProduct(p);
      if (widget.vegOnly) return !nonVeg;
      if (widget.nonVegOnly) return nonVeg;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subcategories.isEmpty && widget.directProducts.isEmpty) {
      return const Center(child: Text('No items available.'));
    }

    final bool isFiltered = widget.selectedSubcategoryId != null;
    final List<Widget> children = [];

    // 👇 Show the selected subcategory's name as a title at the top
    if (isFiltered) {
      final selectedSub = widget.subcategories.firstWhere(
            (s) => s.id == widget.selectedSubcategoryId,
        orElse: () => widget.subcategories.first,
      );
      children.add(_buildSectionHeader(selectedSub.name));
    }

    // Direct (category-level) products only show in "All" mode
    if (!isFiltered) {
      final directFiltered = _filter(widget.directProducts);
      if (directFiltered.isNotEmpty) {
        children.add(_buildGrid(directFiltered));
        children.add(const SizedBox(height: 16));
      }
    }

    for (final sub in widget.subcategories) {
      // 👇 EXACT FILTER: skip every subcategory except the selected one
      if (isFiltered && sub.id != widget.selectedSubcategoryId) {
        continue;
      }

      if (!_sectionKeys.containsKey(sub.id)) {
        _sectionKeys[sub.id] = GlobalKey();
      }

      final miniList = widget.miniSubcategoriesMap[sub.id] ?? sub.miniSubcategories;
      Widget sectionContent;

      if (miniList.isNotEmpty) {
        MiniSubcategoryEntity mini = miniList.first;
        if (widget.selectedLanguage != null) {
          for (final m in miniList) {
            if (m.name.toLowerCase() == widget.selectedLanguage!.toLowerCase()) {
              mini = m;
              break;
            }
          }
        }
        final products = _filter(mini.products);
        if (products.isNotEmpty) {
          sectionContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Per-section header still hidden when filtered —
              // the title above already shows the active subcategory.
              if (!isFiltered) _buildSectionHeader(sub.name),
              _buildGrid(products),
            ],
          );
        } else {
          continue;
        }
      } else {
        final products = _filter(
          sub.directProducts.isNotEmpty
              ? sub.directProducts
              : (widget.subcategoryProducts[sub.id] ?? const []),
        );
        if (products.isNotEmpty) {
          sectionContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isFiltered) _buildSectionHeader(sub.name),
              _buildGrid(products),
            ],
          );
        } else {
          continue;
        }
      }

      children.add(
        // 👈 NEW: RepaintBoundary isolates each section's repaint from
        // its neighbors during scroll, instead of the whole ListView
        // repainting together — helps with scroll flicker.
        RepaintBoundary(
          child: Container(
            key: _sectionKeys[sub.id],
            child: sectionContent,
          ),
        ),
      );
      children.add(const SizedBox(height: 2));
    }

    if (children.isEmpty) {
      return const Center(child: Text('No items match this filter.'));
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 1),
      children: children,
    );
  }

  Widget _buildGrid(List<ProductEntity> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,      // was 12
        crossAxisSpacing: 10,    // was 12
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        final isVariant = product.isVariant == 'Yes';
        return ProductCard(
          product: product,
          quantity: widget.cartQuantitiesByProductId[product.id] ?? 0,
          onAdd: () => widget.onAdd(product),
          onRemove: () => widget.onRemove(product),
          onVariantTap: isVariant ? () => widget.onVariantTap(product) : null,
          currencySymbol: widget.currencySymbol, // 👈 pass the symbol
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 1, bottom:4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }
}