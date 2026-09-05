import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../../constants/color_constants.dart';
import '../mqtt_servers/captain_mqtt_publisher.dart';
import 'order_menu/bloc/category_bloc/category_bloc.dart';
import 'order_menu/bloc/category_bloc/category_event.dart';
import 'order_menu/bloc/category_bloc/category_state.dart';
import 'order_menu/entities/product_entity.dart';
import 'order_menu/widgets/category_tabs.dart';
import 'order_menu/widgets/product_card.dart';

// Reuse the SAME search API/bloc that already powers the global Search screen,
// so "search" here queries ALL menu items regardless of the selected category
// instead of only filtering whatever the CategoryBloc happens to have loaded.
import 'package:restaurant_captain_app/features/search_products/search_products_bloc/search_bloc.dart';
import 'package:restaurant_captain_app/features/search_products/search_products_bloc/search_event.dart';
import 'package:restaurant_captain_app/features/search_products/search_products_bloc/search_state.dart';
import 'package:restaurant_captain_app/features/search_products/search_products_domain/search_entity.dart';

const Color kPageBg = Color(0xFFFDFDFD);
const Color kUnavailableBg = Color(0xFFE9E9E9);

// ── Colors used only by the PIN popup, matched to the reference design ──
const Color kPinBoxBg = Color(0xFFF4F4F4);
const Color kPinBoxBorder = Color(0xFFE2E2E2);
const Color kKeypadKeyBg = Color(0xFFF3ECE4);
const Color kCloseCircleBg = Color(0xFFE8432B);

class MenuManagementScreen extends StatefulWidget {
  final int restaurantId;

  const MenuManagementScreen({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  // Product ids that are currently OUT OF STOCK / unavailable.
  final Set<int> _unavailableIds = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _captainRole = '';


  final Map<int, ProductEntity> _productCache = {};

  void _seedFromProduct(ProductEntity p) {
    if (_productCache.containsKey(p.id)) return;
    _productCache[p.id] = p;
    if (!p.inStock) {
      _unavailableIds.add(p.id);
    }
  }

  void _seedProducts(List<ProductEntity> products) {
    for (final p in products) {
      _seedFromProduct(p);
    }
  }

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CategoryBloc>();
    // if (bloc.state is CategoryInitial) {
    //   bloc.add(LoadCategories());
    // }
    if (bloc.state is CategoryInitial) {
      bloc.add(LoadCategories());
    } else if (bloc.state is CategoryLoaded) {
      // 👈 NEW: always reset to the 1st category whenever Menu Management
      // opens, regardless of whatever category was left selected elsewhere.
      final loaded = bloc.state as CategoryLoaded;
      if (loaded.categories.isNotEmpty) {
        bloc.add(SelectCategory(categoryId: loaded.categories.first.id));
      }
    }
    _loadCaptainRole();
  }

  Future<void> _loadCaptainRole() async {
    try {
      final captainStorage = context.read<CaptainLocalStorage>();
      final captainData = await captainStorage.getCaptainData();
      setState(() {
        _captainRole = captainData?.data?.role?.toLowerCase() ?? '';
      });
    } catch (_) {
      setState(() => _captainRole = '');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(String name) {
    if (_searchQuery.trim().isEmpty) return true;
    return name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
  }

  bool _isProductAvailable(ProductEntity product) {
    // ProductEntity.inStock is bool (true = "Yes", false = "No")
    return product.inStock;
  }

  // Future<void> _openUpdatePinDialog() async {
  //   final pinResult = await showDialog<String>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => const _UpdatePinDialog(),
  //   );
  //   if (pinResult == null) return;
  //   if (!mounted) return;
  //
  //   final result = await Navigator.of(context).push<Set<int>>(
  //     MaterialPageRoute(
  //       builder: (_) => EditMenuScreen(
  //         restaurantId: widget.restaurantId,
  //         initialUnavailableIds: Set<int>.from(_unavailableIds),
  //         pin: pinResult,
  //       ),
  //     ),
  //   );
  //
  //   if (result != null && mounted) {
  //     // Instant UI update — status chips/cards use _unavailableIds only.
  //     // No LoadCategories() here (avoids loading spinner / lag).
  //     setState(() {
  //       _unavailableIds
  //         ..clear()
  //         ..addAll(result);
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Menu updated successfully')),
  //     );
  //   }
  // }

  Future<void> _openUpdatePinDialog() async {
    final pinResult = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _UpdatePinDialog(),
    );
    if (pinResult == null) return;
    if (!mounted) return;

    // Capture whichever category is currently selected in Menu Management,
    // so Edit Menu opens on the same category instead of resetting to the 1st.
    int? currentCategoryId;
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded) {
      currentCategoryId = catState.selectedCategoryId;
    }

    final result = await Navigator.of(context).push<Set<int>>(
      MaterialPageRoute(
        builder: (_) => EditMenuScreen(
          restaurantId: widget.restaurantId,
          initialUnavailableIds: Set<int>.from(_unavailableIds),
          pin: pinResult,
          initialCategoryId: currentCategoryId, // 👈 new
        ),
      ),
    );

    if (result != null && mounted) {
      // Instant UI update — status chips/cards use _unavailableIds only.
      // No LoadCategories() here (avoids loading spinner / lag).
      setState(() {
        _unavailableIds
          ..clear()
          ..addAll(result);
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Menu updated successfully')),
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu updated successfully'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCaptain = _captainRole == 'captain';
    final bool isEditEnabled = !isCaptain;

    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        // toolbarHeight: 44,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Menu Management',
          style: TextStyle(
            fontSize: 18,
            color: ColorConstants.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildEditIconButton(
              enabled: isEditEnabled,
              onTap: isEditEnabled ? _openUpdatePinDialog : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoriesLabelRow(),
          // Category tabs only make sense when browsing (not while searching
          // across the whole menu), so hide them once a query is active.
          if (_searchQuery.trim().isEmpty)
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoaded) {
                  return CategoryTabs(
                    categories: state.categories,
                    selectedId: state.selectedCategoryId,
                    onTabSelected: (id) {
                      context.read<CategoryBloc>().add(SelectCategory(categoryId: id));
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          Expanded(
            child: _searchQuery.trim().isNotEmpty
                ? ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [_buildSearchResultsSection()],
            )
                : BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is CategoryLoaded) {
                  _seedProducts(<ProductEntity>[
                    ...state.directProducts,
                    for (final list in state.subcategoryProducts.values) ...list,
                    for (final miniList in state.miniSubcategoriesMap.values)
                      for (final mini in miniList) ...mini.products,
                  ]);
                  return ListView(
                    padding: const EdgeInsets.only(top: 8),
                    children: [_buildCategoryContent(state)],
                  );
                } else if (state is CategoryError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<CategoryBloc>().add(LoadCategories()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Cross-category search results (uses the search API via SearchBloc,
  //    same SearchResultItem / SearchState / SearchEvent as the standalone
  //    Search screen) ──
  Widget _buildSearchResultsSection() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is SearchError) {
          return Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Text(state.message, style: const TextStyle(color: Colors.grey)),
            ),
          );
        } else if (state is SearchLoaded) {
          if (state.results.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: Text('No items found', style: TextStyle(color: Colors.grey))),
            );
          }

          // Convert search results to ProductEntity list for grid display
          final products = state.results.map((item) {
            // Try to get full product from category state if already loaded
            ProductEntity? fullProduct;
            final catState = context.read<CategoryBloc>().state;
            if (catState is CategoryLoaded) {
              final all = <ProductEntity>[
                ...catState.directProducts,
                for (final list in catState.subcategoryProducts.values) ...list,
                for (final miniList in catState.miniSubcategoriesMap.values)
                  for (final mini in miniList) ...mini.products,
              ];
              fullProduct = all.cast<ProductEntity?>().firstWhere(
                    (p) => p?.id == item.id,
                orElse: () => null,
              );
            }
            // Fallback to creating from search data (isVeg default = false)
            final p = fullProduct ?? ProductEntity(
              id: item.id,
              name: item.name,
              price: item.price,
              inStock: item.inStock == 'Yes',
              isVeg: false, // default; will be overridden if fullProduct exists
            );
            // Seed availability from real stock status
            _seedFromProduct(p);
            return p;
          }).toList();

          // Use the same grid layout as the category content
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 48,
              ),
              itemBuilder: (context, index) => _buildReadOnlyItemCell(products[index]),
            ),
          );
        }
        // Idle state
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEditIconButton({required bool enabled, VoidCallback? onTap}) {
    const Color enabledColor = Color(0xFF3B5BA9);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: ColorConstants.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? enabledColor.withOpacity(0.6) : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          Icons.edit_outlined,
          size: 18,
          color: enabled ? enabledColor : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: ColorConstants.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: kPageBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: ColorConstants.hintColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  final trimmed = v.trim();
                  if (trimmed.isEmpty) {
                    context.read<SearchBloc>().add(ClearSearch());
                  } else {
                    // Cross-category API search — not limited to the tab
                    // currently selected in CategoryBloc.
                    context.read<SearchBloc>().add(SearchQueryChanged(query: trimmed));
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: ColorConstants.hintColor, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                  context.read<SearchBloc>().add(ClearSearch());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.close, size: 16, color: ColorConstants.hintColor),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoriesLabelRow() {
    return Container(
      color: ColorConstants.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: ColorConstants.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(CategoryLoaded state) {
    final selected = state.categories
        .where((c) => c.id == state.selectedCategoryId)
        .toList();
    final title = selected.isNotEmpty ? selected.first.name : '';

    if (state.subcategories.isEmpty) {
      final products = [
        ...state.directProducts,
        for (final list in state.subcategoryProducts.values) ...list,
        for (final miniList in state.miniSubcategoriesMap.values)
          for (final mini in miniList) ...mini.products,
      ];

      final unique = <int, ProductEntity>{};
      for (final p in products) unique[p.id] = p;
      // Show ALL items (including in_stock = No) — only filter by search
      final filtered = unique.values.where((p) => _matchesSearch(p.name)).toList();

      if (filtered.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: Text('No items found', style: TextStyle(color: Colors.grey))),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          _buildProductGrid(filtered),
          const SizedBox(height: 24),
        ],
      );
    }

    final List<Widget> sections = [];

    for (final sub in state.subcategories) {
      final direct = state.subcategoryProducts[sub.id] ?? [];
      final minis = state.miniSubcategoriesMap[sub.id] ?? [];

      if (minis.isEmpty) {
        final filtered = direct.where((p) => _matchesSearch(p.name)).toList();
        if (filtered.isEmpty && _searchQuery.isNotEmpty) continue;

        sections.add(_buildSectionHeader(sub.name));
        if (filtered.isNotEmpty) {
          sections.add(_buildProductGrid(filtered));
        } else {
          sections.add(const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No items', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ));
        }
        sections.add(const SizedBox(height: 12));
        continue;
      }

      sections.add(_buildSectionHeader(sub.name));

      for (final mini in minis) {
        final filtered = mini.products.where((p) => _matchesSearch(p.name)).toList();
        if (filtered.isEmpty && _searchQuery.isNotEmpty) continue;

        sections.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text(
            mini.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textColor.withOpacity(0.85),
            ),
          ),
        ));

        if (filtered.isNotEmpty) {
          sections.add(_buildProductGrid(filtered));
        } else {
          sections.add(const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('No items', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ));
        }
        sections.add(const SizedBox(height: 8));
      }
      sections.add(const SizedBox(height: 8));
    }

    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: Text('No items found', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: ColorConstants.textColor,
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductEntity> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 60, // ✅ increased from 48
        ),
        itemBuilder: (context, index) => _buildReadOnlyItemCell(products[index]),
      ),
    );
  }

  Widget _buildReadOnlyItemCell(ProductEntity product) {
    final outOfStock = _unavailableIds.contains(product.id);
    final nonVeg = isNonVegProduct(product);

    final Color cardBg = outOfStock ? const Color(0xFFE7E7E7) : ColorConstants.backgroundColor;
    final Color titleColor = outOfStock ? Colors.grey.shade500 : ColorConstants.textColor;
    final Color borderColor = outOfStock ? Colors.grey.shade400 : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Opacity(
        opacity: outOfStock ? 0.7 : 1.0,
        child: Row(
          children: [
            vegNonVegIndicator(nonVeg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                product.name,
                maxLines: 2,                 // ✅ allow up to 2 lines
                overflow: TextOverflow.ellipsis, // optional fallback if 2 lines still not enough
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                  decoration: outOfStock ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (outOfStock)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.block, size: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ─────────────────────────────────────────────

bool isNonVegProduct(ProductEntity product) {
  try {
    final dynamic p = product;
    final dynamic isVeg = p.isVeg;
    if (isVeg is bool) return !isVeg;
  } catch (_) {}
  return false;
}

Widget vegNonVegIndicator(bool nonVeg) {
  final color = nonVeg ? ColorConstants.errorColor : ColorConstants.successColor;
  return Container(
    width: 16,
    height: 16,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.5), width: 1),
    ),
    child: Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

Widget squareCheckbox(bool checked, {Color? activeColor}) {
  final color = activeColor ?? ColorConstants.primaryColor;
  return Container(
    width: 18,
    height: 18,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: checked ? color : ColorConstants.backgroundColor,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: checked ? color : Colors.grey.shade400,
        width: 1.4,
      ),
    ),
    child: checked ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
  );
}

// ─── Search result row ───────────────────────────────────────────
// Modeled after SearchScreen's _SearchResultRow so cross-category search
// results look and feel the same everywhere in the app. Used by both the
// read-only Menu Management search and the editable Edit Menu search.
class _MenuSearchRow extends StatelessWidget {
  final String name;
  final String categoryLabel;
  final bool outOfStock;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuSearchRow({
    required this.name,
    required this.categoryLabel,
    required this.outOfStock,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: outOfStock ? Colors.grey.shade400 : ColorConstants.textColor,
                      decoration: outOfStock ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (categoryLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: outOfStock ? Colors.grey.shade400 : const Color(0xFFD98831),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

//
// class _UpdatePinDialog extends StatefulWidget {
//   const _UpdatePinDialog();
//
//   @override
//   State<_UpdatePinDialog> createState() => _UpdatePinDialogState();
// }
//
// class _UpdatePinDialogState extends State<_UpdatePinDialog> {
//   static const int _pinLength = 6;
//
//   String _pin = '';
//   String? _error;
//   bool _isVerifying = false;
//
//   // Keypad laid out exactly as in the reference image: 1-9, C, 0, backspace.
//   static const List<List<String>> _keyRows = [
//     ['1', '2', '3'],
//     ['4', '5', '6'],
//     ['7', '8', '9'],
//     ['C', '0', '⌫'],
//   ];
//
//   void _addDigit(String d) {
//     // Tapping a number key fills exactly ONE pin box (the next empty one).
//     if (_isVerifying || _pin.length >= _pinLength) return;
//     setState(() {
//       _pin += d;
//       _error = null;
//     });
//   }
//
//   void _backspace() {
//     if (_isVerifying || _pin.isEmpty) return;
//     setState(() => _pin = _pin.substring(0, _pin.length - 1));
//   }
//
//   void _clear() {
//     if (_isVerifying) return;
//     setState(() {
//       _pin = '';
//       _error = null;
//     });
//   }
//
//   Future<void> _submit() async {
//     if (_pin.length != _pinLength) {
//       setState(() => _error = 'Enter your $_pinLength-digit pin');
//       return;
//     }
//
//     setState(() {
//       _isVerifying = true;
//       _error = null;
//     });
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedPin = prefs.getString('captain_pin') ?? '';
//
//       print('Entered PIN: $_pin');
//       print('Saved PIN:   $savedPin');
//
//       if (savedPin.isEmpty) {
//         setState(() {
//           _isVerifying = false;
//           _error = 'No saved PIN found. Please login again.';
//           _pin = '';
//         });
//         return;
//       }
//
//       if (_pin.trim() == savedPin.trim()) {
//         print('PIN matched. Allowing edit access.');
//         if (!mounted) return;
//         Navigator.of(context).pop(_pin);
//       } else {
//         print('PIN mismatch. Access denied.');
//         setState(() {
//           _isVerifying = false;
//           _error = 'Incorrect pin. Try again.';
//           _pin = '';
//         });
//       }
//     } catch (e) {
//       print('PIN validation error: $e');
//       setState(() {
//         _isVerifying = false;
//         _error = 'Something went wrong. Try again.';
//         _pin = '';
//       });
//     }
//   }
//
//   // Single pin box — one box per digit, never shares a box with the keypad.
//   Widget _pinBox(int index) {
//     final filled = index < _pin.length;
//     return Expanded(
//       child: Container(
//         height: 46,
//         margin: EdgeInsets.only(right: index == _pinLength - 1 ? 0 : 8),
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: kPinBoxBg,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: filled ? ColorConstants.primaryColor : kPinBoxBorder,
//             width: filled ? 1.4 : 1,
//           ),
//         ),
//         child: filled
//             ? Container(
//           width: 8,
//           height: 8,
//           decoration: const BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.black87,
//           ),
//         )
//             : null,
//       ),
//     );
//   }
//
//   // Single keypad key — equal-width grid cell (3 per row) like the reference.
//   Widget _keypadKey(String label) {
//     final bool isBackspace = label == '⌫';
//     final bool isClear = label == 'C';
//
//     return Expanded(
//       child: GestureDetector(
//         onTap: _isVerifying
//             ? null
//             : () {
//           if (isBackspace) {
//             _backspace();
//           } else if (isClear) {
//             _clear();
//           } else {
//             _addDigit(label);
//           }
//         },
//         child: Container(
//           height: 52,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             color: kKeypadKeyBg,
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: isBackspace
//               ? const Icon(Icons.backspace_outlined, size: 18, color: Colors.black87)
//               : Text(
//             label,
//             style: const TextStyle(
//               fontSize: 17,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _keypadRow(List<String> row) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         children: [
//           for (int i = 0; i < row.length; i++) ...[
//             _keypadKey(row[i]),
//             if (i != row.length - 1) const SizedBox(width: 10),
//           ],
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: ColorConstants.backgroundColor,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 40),
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Title row with close button – directly in the row, no Transform.translate
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Expanded(
//                   child: Text(
//                     'Update Menu Items',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: _isVerifying ? null : () => Navigator.of(context).pop(null),
//                   child: Container(
//                     width: 30,
//                     height: 30,
//                     alignment: Alignment.center,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: kCloseCircleBg,
//                     ),
//                     child: const Icon(Icons.close, size: 16, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             const Text(
//               'Select items to keep them available. Unselected items will be unavailable',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Enter Pin',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//             ),
//             const SizedBox(height: 14),
//
//             // Six individual pin boxes — one digit per box only.
//             Row(
//               children: List.generate(_pinLength, _pinBox),
//             ),
//
//             if (_error != null) ...[
//               const SizedBox(height: 8),
//               Text(
//                 _error!,
//                 style: TextStyle(color: ColorConstants.errorColor, fontSize: 12),
//               ),
//             ],
//
//             const SizedBox(height: 22),
//
//             // Numeric keypad — 3 equal-width columns per row, 4 rows total.
//             for (final row in _keyRows) _keypadRow(row),
//
//             const SizedBox(height: 6),
//
//             // Continue button with iOS‑style loading
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isVerifying ? null : _submit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: ColorConstants.primaryColor,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: _isVerifying
//                     ? const CupertinoActivityIndicator(radius: 12, color: Colors.white)
//                     : const Text(
//                   'Continue',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


class _UpdatePinDialog extends StatefulWidget {
  const _UpdatePinDialog();

  @override
  State<_UpdatePinDialog> createState() => _UpdatePinDialogState();
}

class _UpdatePinDialogState extends State<_UpdatePinDialog> {
  static const int _pinLength = 6;

  String _pin = '';
  String? _error;
  bool _isVerifying = false;

  // Keypad laid out exactly as in the reference image: 1-9, C, 0, backspace.
  static const List<List<String>> _keyRows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['C', '0', '⌫'],
  ];

  void _addDigit(String d) {
    // Tapping a number key fills exactly ONE pin box (the next empty one).
    if (_isVerifying || _pin.length >= _pinLength) return;
    setState(() {
      _pin += d;
      _error = null;
    });
  }

  void _backspace() {
    if (_isVerifying || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _clear() {
    if (_isVerifying) return;
    setState(() {
      _pin = '';
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_pin.length != _pinLength) {
      setState(() => _error = 'Enter your $_pinLength-digit pin');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('captain_pin') ?? '';

      print('Entered PIN: $_pin');
      print('Saved PIN:   $savedPin');

      if (savedPin.isEmpty) {
        setState(() {
          _isVerifying = false;
          _error = 'No saved PIN found. Please login again.';
          _pin = '';
        });
        return;
      }

      if (_pin.trim() == savedPin.trim()) {
        print('PIN matched. Allowing edit access.');
        if (!mounted) return;
        Navigator.of(context).pop(_pin);
      } else {
        print('PIN mismatch. Access denied.');
        setState(() {
          _isVerifying = false;
          _error = 'Incorrect pin. Try again.';
          _pin = '';
        });
      }
    } catch (e) {
      print('PIN validation error: $e');
      setState(() {
        _isVerifying = false;
        _error = 'Something went wrong. Try again.';
        _pin = '';
      });
    }
  }

  // Single pin box — one box per digit, never shares a box with the keypad.
  Widget _pinBox(int index) {
    final filled = index < _pin.length;
    return Expanded(
      child: Container(
        height: 40,
        margin: EdgeInsets.only(right: index == _pinLength - 1 ? 0 : 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kPinBoxBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? ColorConstants.primaryColor : kPinBoxBorder,
            width: filled ? 1.4 : 1,
          ),
        ),
        child: filled
            ? Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black87,
          ),
        )
            : null,
      ),
    );
  }

  // Single keypad key — equal-width grid cell (3 per row) like the reference.
  Widget _keypadKey(String label) {
    final bool isBackspace = label == '⌫';
    final bool isClear = label == 'C';

    return Expanded(
      child: GestureDetector(
        onTap: _isVerifying
            ? null
            : () {
          if (isBackspace) {
            _backspace();
          } else if (isClear) {
            _clear();
          } else {
            _addDigit(label);
          }
        },
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kKeypadKeyBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: isBackspace
              ? const Icon(Icons.backspace_outlined, size: 18, color: Colors.black87)
              : Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _keypadRow(List<String> row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (int i = 0; i < row.length; i++) ...[
            _keypadKey(row[i]),
            if (i != row.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorConstants.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row with close button – directly in the row, no Transform.translate
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Update Menu Items',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: _isVerifying ? null : () => Navigator.of(context).pop(null),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kCloseCircleBg,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Select items to keep them available. Unselected items will be unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter Pin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),

            // Six individual pin boxes — one digit per box only.
            Row(
              children: List.generate(_pinLength, _pinBox),
            ),

            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: TextStyle(color: ColorConstants.errorColor, fontSize: 12),
              ),
            ],

            const SizedBox(height: 14),

            // Numeric keypad — 3 equal-width columns per row, 4 rows total.
            for (final row in _keyRows) _keypadRow(row),

            const SizedBox(height: 2),

            // Continue button with iOS‑style loading
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isVerifying
                    ? const CupertinoActivityIndicator(radius: 12, color: Colors.white)
                    : const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditMenuScreen extends StatefulWidget {
  final int restaurantId;
  final Set<int> initialUnavailableIds;
  final String pin;
  final int? initialCategoryId; // 👈 new

  const EditMenuScreen({
    Key? key,
    required this.restaurantId,
    required this.initialUnavailableIds,
    required this.pin,
    this.initialCategoryId, // 👈 new

  }) : super(key: key);

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  late final Set<int> _unavailableIds;
  String? _token;
  final Map<int, String> _originalStatusMap = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isUpdating = false;
  // Every product ever seen — from any category browsed AND every search
  // result — keyed by id. Write-through cache: the FIRST time a product is
  // seen (whether via CategoryBloc or SearchBloc) its real stock status is
  // seeded into _unavailableIds, and then never re-seeded again so a later
  // user toggle is never overwritten. Items are always rendered straight
  // from state — nothing is hidden just because it isn't cached yet; the
  // cache is also what lets Continue send changes for items toggled via
  // search even though they aren't part of the currently selected category.
  final Map<int, ProductEntity> _productCache = {};

  void _seedFromProduct(ProductEntity p) {
    if (_productCache.containsKey(p.id)) return;
    _productCache[p.id] = p;
    if (!p.inStock) {
      _unavailableIds.add(p.id);
    }
  }

  void _seedProducts(List<ProductEntity> products) {
    for (final p in products) {
      _seedFromProduct(p);
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _unavailableIds = Set<int>.from(widget.initialUnavailableIds);
  //   final bloc = context.read<CategoryBloc>();
  //   if (bloc.state is CategoryInitial) {
  //     bloc.add(LoadCategories());
  //   }
  //   _loadToken();
  // }

  @override
  void initState() {
    super.initState();
    _unavailableIds = Set<int>.from(widget.initialUnavailableIds);
    final bloc = context.read<CategoryBloc>();
    // if (bloc.state is CategoryInitial) {
    //   bloc.add(LoadCategories());
    // } else if (widget.initialCategoryId != null) {
    //   // restore whichever category was selected on the previous screen
    //   final state = bloc.state;
    //   if (state is CategoryLoaded && state.selectedCategoryId != widget.initialCategoryId) {
    //     bloc.add(SelectCategory(categoryId: widget.initialCategoryId!));
    //   }
    // }

    if (bloc.state is CategoryInitial) {
      bloc.add(LoadCategories());
    } else if (widget.initialCategoryId != null) {
      // restore whichever category was selected on the previous screen
      final state = bloc.state;
      if (state is CategoryLoaded && state.selectedCategoryId != widget.initialCategoryId) {
        bloc.add(SelectCategory(categoryId: widget.initialCategoryId!));
      }
    } else if (bloc.state is CategoryLoaded) {
      // 👈 NEW: no explicit category was passed in — default to the 1st one
      // instead of leaving whatever category another screen last selected.
      final loaded = bloc.state as CategoryLoaded;
      if (loaded.categories.isNotEmpty) {
        bloc.add(SelectCategory(categoryId: loaded.categories.first.id));
      }
    }
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final captainStorage = context.read<CaptainLocalStorage>();
      final captainData = await captainStorage.getCaptainData();
      setState(() {
        _token = captainData?.data?.token;
      });
    } catch (_) {
      setState(() => _token = null);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(String name) {
    if (_searchQuery.trim().isEmpty) return true;
    return name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
  }

  void _toggleProduct(int productId) {
    String originalStock = 'Yes';
    try {
      ProductEntity? product;
      final state = context.read<CategoryBloc>().state;
      if (state is CategoryLoaded) {
        final all = <ProductEntity>[
          ...state.directProducts,
          for (final list in state.subcategoryProducts.values) ...list,
          for (final miniList in state.miniSubcategoriesMap.values)
            for (final mini in miniList) ...mini.products,
        ];
        product = all.cast<ProductEntity?>().firstWhere(
              (p) => p?.id == productId,
          orElse: () => null,
        );
      }
      // Item may have come from a cross-category search result rather than
      // the currently selected category — check the cache too.
      product ??= _productCache[productId];
      if (product != null) {
        originalStock = product.inStock ? 'Yes' : 'No';
      }
    } catch (_) {}

    setState(() {
      if (_unavailableIds.contains(productId)) {
        _unavailableIds.remove(productId);
        print(
          'Item id: $productId | Original in_stock: $originalStock | Status: SELECTED | "in_stock":"Yes"',
        );
      } else {
        _unavailableIds.add(productId);
        print(
          'Item id: $productId | Original in_stock: $originalStock | Status: UNSELECTED | "in_stock":"No"',
        );
      }
    });
  }

  void _toggleSection(List<ProductEntity> products, bool selectAll) {
    setState(() {
      for (final p in products) {
        if (selectAll) {
          _unavailableIds.remove(p.id);
          print(
            'Item id: ${p.id} | Name: ${p.name} | '
                'Original in_stock: ${p.inStock ? "Yes" : "No"} | '
                'Status: SELECTED | "in_stock":"Yes"',
          );
        } else {
          _unavailableIds.add(p.id);
          print(
            'Item id: ${p.id} | Name: ${p.name} | '
                'Original in_stock: ${p.inStock ? "Yes" : "No"} | '
                'Status: UNSELECTED | "in_stock":"No"',
          );
        }
      }
    });
  }

  String _getOriginalStatus(ProductEntity product) {
    final dynamic stock = product.inStock;
    if (stock is String) {
      return stock.toLowerCase() == 'yes' ? 'instock' : 'outofstock';
    } else if (stock is bool) {
      return stock ? 'instock' : 'outofstock';
    } else {
      return 'instock';
    }
  }

  Future<bool> _updateMenuOnServer(
      List<Map<String, dynamic>> productsPayload) async {
    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token missing')),
      );
      return false;
    }

    // Same base-URL source as KOT / repeat-KOT in CartScreen
    final merchantStorage = context.read<MerchantLocalStorage>();
    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store base URL not found')),
      );
      return false;
    }

    final url = Uri.parse(
      '$baseUrl/wp-json/pinaka-restaurant-pos/v1/products/status',
    );

    final body = {
      'products': productsPayload,
      'pin': widget.pin,
    };

    debugPrint('========== API REQUEST ==========');
    debugPrint('URL: $url');
    debugPrint('METHOD: POST');
    debugPrint('HEADERS:');
    debugPrint('Content-Type: application/json');
    debugPrint('Authorization: Bearer $_token');
    debugPrint('BODY: ${json.encode(body)}');
    debugPrint('=================================');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(body),
      );

      debugPrint('========== API RESPONSE =========');
      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RESPONSE HEADERS: ${response.headers}');
      debugPrint('RESPONSE BODY: ${response.body}');
      debugPrint('=================================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        debugPrint('DECODED RESPONSE: $data');

        final success = data['success'] ?? false;

        if (success) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('Menu updated successfully')),
          // );
          return true;
        } else {
          final message = data['message'] ?? 'Update failed';
          final results = data['results'] as List?;

          if (results != null && results.isNotEmpty) {
            final first = results.first;
            final errorMsg = first['message'] ?? message;

            debugPrint('API ERROR MESSAGE: $errorMsg');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: $errorMsg')),
            );
          } else {
            debugPrint('API ERROR MESSAGE: $message');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: $message')),
            );
          }

          return false;
        }
      } else {
        debugPrint('HTTP ERROR: ${response.statusCode}');
        debugPrint('ERROR RESPONSE: ${response.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
          ),
        );
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('========== API EXCEPTION =========');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('==================================');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return false;
    }
  }

  Future<void> _onContinuePressed() async {
    if (_isUpdating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _UpdateMenuConfirmDialog(),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final state = context.read<CategoryBloc>().state;
    if (state is! CategoryLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data not loaded yet')),
      );
      return;
    }

    final allProducts = <ProductEntity>[
      ...state.directProducts,
      for (final list in state.subcategoryProducts.values) ...list,
      for (final miniList in state.miniSubcategoriesMap.values)
        for (final mini in miniList) ...mini.products,
    ];
    final unique = <int, ProductEntity>{};
    for (final p in allProducts) unique[p.id] = p;
    for (final entry in _productCache.entries) {
      unique.putIfAbsent(entry.key, () => entry.value);
    }

    final List<Map<String, dynamic>> productsPayload = [];
    for (final p in unique.values) {
      final oldStatus = p.inStock ? 'instock' : 'outofstock';
      final currentAvailable = !_unavailableIds.contains(p.id);
      final newStatus = currentAvailable ? 'instock' : 'outofstock';
      if (oldStatus != newStatus) {
        productsPayload.add({
          'product_id': p.id,
          'old_status': oldStatus,
          'new_status': newStatus,
        });
      }
    }

    if (productsPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to update')),
      );
      Navigator.of(context).pop(_unavailableIds);
      return;
    }

    setState(() => _isUpdating = true);

    final success = await _updateMenuOnServer(productsPayload);

    if (!mounted) return;

    setState(() => _isUpdating = false);

    if (success) {
      final Map<int, bool> stockById = {};
      for (final p in unique.values) {
        stockById[p.id] = !_unavailableIds.contains(p.id);
      }

      context.read<CategoryBloc>().add(
        UpdateProductsStock(stockById: stockById),
      );
      unawaited(
        CaptainMqttPublisher.notifyMenuStockUpdated(
          restaurantId: widget.restaurantId.toString(),
          products: productsPayload, // same list you sent to API
        ),
      );
      Navigator.of(context).pop<Set<int>>(Set<int>.from(_unavailableIds));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        // toolbarHeight: 44,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Menu',
          style: TextStyle(
            fontSize: 18,
            color: ColorConstants.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoriesLabelRow(),
            // Hide category tabs while a cross-category search is active.
            if (_searchQuery.trim().isEmpty)
              BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryLoaded) {
                    return CategoryTabs(
                      categories: state.categories,
                      selectedId: state.selectedCategoryId,
                      onTabSelected: (id) {
                        context.read<CategoryBloc>().add(SelectCategory(categoryId: id));
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            Expanded(
              child: _searchQuery.trim().isNotEmpty
                  ? ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                children: [_buildSearchResultsSection()],
              )
                  : BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is CategoryLoaded) {
                    final all = <ProductEntity>[
                      ...state.directProducts,
                      for (final list in state.subcategoryProducts.values) ...list,
                      for (final miniList in state.miniSubcategoriesMap.values)
                        for (final mini in miniList) ...mini.products,
                    ];
                    _seedProducts(all);
                    if (_originalStatusMap.isEmpty) {
                      for (final p in all) {
                        if (!_originalStatusMap.containsKey(p.id)) {
                          _originalStatusMap[p.id] = _getOriginalStatus(p);
                        }
                      }
                    }
                    return ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      children: [_buildCategoryContent(state)],
                    );
                  } else if (state is CategoryError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<CategoryBloc>().add(LoadCategories()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            _buildContinueBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: ColorConstants.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: kPageBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: ColorConstants.hintColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  final trimmed = v.trim();
                  if (trimmed.isEmpty) {
                    context.read<SearchBloc>().add(ClearSearch());
                  } else {
                    // Cross-category API search — not limited to the tab
                    // currently selected in CategoryBloc.
                    context.read<SearchBloc>().add(SearchQueryChanged(query: trimmed));
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: ColorConstants.hintColor, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                  context.read<SearchBloc>().add(ClearSearch());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.close, size: 16, color: ColorConstants.hintColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsSection() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is SearchError) {
          return Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Text(state.message, style: const TextStyle(color: Colors.grey)),
            ),
          );
        } else if (state is SearchLoaded) {
          if (state.results.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: Text('No items found', style: TextStyle(color: Colors.grey))),
            );
          }

          // Convert search results to ProductEntity list for grid display
          final products = state.results.map((item) {
            // Try to get full product from category state if already loaded
            ProductEntity? fullProduct;
            final catState = context.read<CategoryBloc>().state;
            if (catState is CategoryLoaded) {
              final all = <ProductEntity>[
                ...catState.directProducts,
                for (final list in catState.subcategoryProducts.values) ...list,
                for (final miniList in catState.miniSubcategoriesMap.values)
                  for (final mini in miniList) ...mini.products,
              ];
              fullProduct = all.cast<ProductEntity?>().firstWhere(
                    (p) => p?.id == item.id,
                orElse: () => null,
              );
            }
            // Fallback to creating from search data (isVeg default = false)
            final p = fullProduct ?? ProductEntity(
              id: item.id,
              name: item.name,
              price: item.price,
              inStock: item.inStock == 'Yes',
              isVeg: false,
            );
            // Seed availability from real stock status
            _seedFromProduct(p);
            return p;
          }).toList();

          // Use the same editable grid layout as the category content
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 48,
              ),
              itemBuilder: (context, index) => _buildEditableItemCell(products[index]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }


  Widget _buildCategoriesLabelRow() {
    return Container(
      color: ColorConstants.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: ColorConstants.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(CategoryLoaded state) {
    final selected = state.categories
        .where((c) => c.id == state.selectedCategoryId)
        .toList();
    final title = selected.isNotEmpty ? selected.first.name : '';

    if (state.subcategories.isEmpty) {
      final products = [
        ...state.directProducts,
        for (final list in state.subcategoryProducts.values) ...list,
        for (final miniList in state.miniSubcategoriesMap.values)
          for (final mini in miniList) ...mini.products,
      ];

      final unique = <int, ProductEntity>{};
      for (final p in products) unique[p.id] = p;
      final filtered = unique.values.where((p) => _matchesSearch(p.name)).toList();

      if (filtered.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: Text('No items found', style: TextStyle(color: Colors.grey))),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, filtered),
          _buildProductGrid(filtered),
          const SizedBox(height: 16),
        ],
      );
    }

    final List<Widget> sections = [];

    for (final sub in state.subcategories) {
      final direct = state.subcategoryProducts[sub.id] ?? [];
      final minis = state.miniSubcategoriesMap[sub.id] ?? [];

      if (minis.isEmpty) {
        final filtered = direct.where((p) => _matchesSearch(p.name)).toList();
        if (filtered.isEmpty && _searchQuery.isNotEmpty) continue;

        sections.add(_buildSectionHeader(sub.name, filtered));
        if (filtered.isNotEmpty) {
          sections.add(_buildProductGrid(filtered));
        } else {
          sections.add(const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No items', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ));
        }
        sections.add(const SizedBox(height: 12));
        continue;
      }

      final allUnderSub = <ProductEntity>[
        for (final mini in minis) ...mini.products,
      ];
      final filteredAll = allUnderSub.where((p) => _matchesSearch(p.name)).toList();

      sections.add(_buildSectionHeader(sub.name, filteredAll));

      for (final mini in minis) {
        final filtered = mini.products.where((p) => _matchesSearch(p.name)).toList();
        if (filtered.isEmpty && _searchQuery.isNotEmpty) continue;

        sections.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text(
            mini.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textColor.withOpacity(0.85),
            ),
          ),
        ));

        if (filtered.isNotEmpty) {
          sections.add(_buildProductGrid(filtered));
        } else {
          sections.add(const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('No items', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ));
        }
        sections.add(const SizedBox(height: 8));
      }
      sections.add(const SizedBox(height: 8));
    }

    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: Text('No items found', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget _buildSectionHeader(String title, List<ProductEntity> sectionProducts) {
    final total = sectionProducts.length;
    final selectedCount =
        sectionProducts.where((p) => !_unavailableIds.contains(p.id)).length;
    final allSelected = selectedCount == total && total > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$selectedCount/$total Selected',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _toggleSection(sectionProducts, !allSelected),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select All',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                squareCheckbox(allSelected, activeColor: ColorConstants.successColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<ProductEntity> filtered) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 48,
        ),
        itemBuilder: (context, index) => _buildEditableItemCell(filtered[index]),
      ),
    );
  }

  Widget _buildEditableItemCell(ProductEntity product) {
    final isAvailable = !_unavailableIds.contains(product.id);
    final nonVeg = isNonVegProduct(product);

    return GestureDetector(
      onTap: () => _toggleProduct(product.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isAvailable ? ColorConstants.backgroundColor : kUnavailableBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            vegNonVegIndicator(nonVeg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                product.name,
                maxLines: 2,                 // ✅ allow up to 2 lines
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isAvailable ? ColorConstants.textColor : Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            squareCheckbox(isAvailable, activeColor: ColorConstants.successColor),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: ColorConstants.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isUpdating ? null : _onContinuePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isUpdating
              ? const CupertinoActivityIndicator(radius: 14, color: Colors.white)
              : const Text(
            'Continue',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

// ─── Confirmation Dialog ────────────────────────────────────────

class _UpdateMenuConfirmDialog extends StatefulWidget {
  const _UpdateMenuConfirmDialog();

  @override
  State<_UpdateMenuConfirmDialog> createState() => _UpdateMenuConfirmDialogState();
}

class _UpdateMenuConfirmDialogState extends State<_UpdateMenuConfirmDialog> {
  bool _isConfirming = false;

  Future<void> _confirm() async {
    setState(() => _isConfirming = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorConstants.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: ColorConstants.primaryColor,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Update Menu?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to update the menu? Unselected items will be out of stock.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isConfirming ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstants.textColor,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConfirming ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CupertinoActivityIndicator(radius: 14),
                    )
                        : const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}