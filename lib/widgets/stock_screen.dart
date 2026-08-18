import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../kitchen_display_screen.dart';
import '../models/Stock_model.dart';
// import '../repositories/product_repository.dart';
import '../services/STOCK PRODUCT _REPOSITIORY.dart';
import '../top_bar.dart';
import 'completed_orders.dart';
import 'login_screen.dart';

class StockScreen extends StatefulWidget {
  final String token;
  final int restaurantId;

  const StockScreen({
    super.key,
    required this.token,
    required this.restaurantId,
  });

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController _searchController =
  TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey =
  GlobalKey<ScaffoldState>();

  // ==========================================================
  // CATEGORY
  // ==========================================================

  String _selectedCategory = '';
  // String _selectedCategory = '';

  String? _previousCategory;
  StockItem? _previousItem;
  String _previousSearch = '';

  // ==========================================================
  // STOCK DATA
  // ==========================================================

  List<StockCategory> _stockCategories = [];

  bool _isLoading = false;
  String? _errorMessage;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    loadProducts();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void _saveCurrentState() {
    _previousCategory = _selectedCategory;
    _previousItem = _selectedItems as StockItem?;
    _previousSearch = _searchController.text;
  }
  void _resetSelection() {
    setState(() {
      for (final category in _stockCategories) {
        for (final item in category.items) {
          // Restore the original/current backend state
          item.selected = item.isEnabled;
        }
      }

      // Also clear the search
      _searchController.clear();
    });
  }

  // ==========================================================
  // LOAD PRODUCTS API
  // ==========================================================


  Future<void> loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs =
      await SharedPreferences.getInstance();

      final baseUrl =
          prefs.getString('store_base_url') ?? '';

      debugPrint(
        '======================================',
      );
      debugPrint('STOCK PRODUCT API');
      debugPrint('BASE URL: $baseUrl');
      debugPrint(
        '======================================',
      );

      if (baseUrl.isEmpty) {
        throw Exception(
          'Store base URL not found',
        );
      }

      final repository = ProductRepository(
        baseUrl: baseUrl,
        token: widget.token,
      );


      // ==========================================
      // API CALL
      // ==========================================

      final response =
      await repository.fetchProducts();

      debugPrint(
        'PRODUCT COUNT FROM API: ${response.length}',
      );

      // ==========================================
      // CONVERT API RESPONSE TO MODEL
      // ==========================================

      final products = response
          .map(
            (json) => StockProduct.fromJson(json),
      )
          .toList();

      // ==========================================
      // DEBUG
      // ==========================================

      for (final product in products) {
        debugPrint(
          '--------------------------------------',
        );

        debugPrint(
          'PRODUCT ID      : ${product.id}',
        );

        debugPrint(
          'PRODUCT NAME    : ${product.name}',
        );

        debugPrint(
          'CATEGORY        : ${product.categoryName}',
        );

        debugPrint(
          'STOCK QUANTITY  : ${product.stockQuantity}',
        );

        debugPrint(
          'STOCK STATUS    : ${product.stockStatus}',
        );

        debugPrint(
          'ENABLED         : ${product.isEnabled}',
        );
      }

      debugPrint(
        '======================================',
      );

      // ==========================================
      // CREATE CATEGORY + PRODUCT GROUPS
      // ==========================================

      _createCategories(products);

    } catch (e, stackTrace) {
      debugPrint(
        '======================================',
      );

      debugPrint(
        'STOCK API ERROR: $e',
      );

      debugPrint(
        'STACK TRACE: $stackTrace',
      );

      debugPrint(
        '======================================',
      );

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<String?> showStockPinDialog() async {
    final controller = TextEditingController();

    final pin = await showDialog<String>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Enter PIN',
          ),

          content: TextField(
            controller: controller,

            obscureText: true,

            keyboardType:
            TextInputType.number,

            decoration:
            const InputDecoration(
              hintText: 'Enter PIN',
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                final pin =
                controller.text.trim();

                if (pin.isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  pin,
                );
              },

              child: const Text(
                'Confirm',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return pin;
  }
  Future<void> updateProductStockStatus({
    required StockItem item,
    required String pin,
  }) async {
    try {
      final prefs =
      await SharedPreferences.getInstance();

      final baseUrl =
          prefs.getString('store_base_url') ?? '';

      if (baseUrl.isEmpty) {
        throw Exception('Store base URL not found');
      }

      final repository = ProductRepository(
        baseUrl: baseUrl,
        token: widget.token,
      );

      // ==========================================
      // DETERMINE NEW STATUS
      // ==========================================

      final newStatus = item.isEnabled
          ? 'outofstock'
          : 'instock';

      debugPrint('======================================');
      debugPrint('UPDATING PRODUCT STOCK');
      debugPrint('PRODUCT ID: ${item.id}');
      debugPrint('PRODUCT NAME: ${item.name}');
      debugPrint('NEW STATUS: $newStatus');
      debugPrint('======================================');

      // ==========================================
      // CALL UPDATE API
      // ==========================================

      final success =
      await repository.updateProductStatus(
        productId: item.id,
        status: newStatus,
        pin: pin,
      );

      if (!success) {
        throw Exception(
          'Failed to update product status',
        );
      }

      // ❌ REMOVE loadProducts() from here
      // ❌ REMOVE SnackBar from here

    } catch (e) {
      debugPrint('UPDATE STOCK ERROR: $e');

      rethrow;
    }
  }
  // ==========================================================
  // CREATE CATEGORIES
  // ==========================================================

  void _createCategories(
      List<StockProduct> products,
      ) {
    final Map<String, List<StockItem>> grouped =
    {};

    for (final product in products) {
      final categoryName = product.categoryName?.trim();

      // Hide Uncategorized / Others / empty categories
      if (categoryName == null ||
          categoryName.isEmpty ||
          categoryName.toLowerCase() == 'uncategorized' ||
          categoryName.toLowerCase() == 'others') {
        continue;
      }

      final item = StockItem(
        id: product.id,
        name: product.name,
        stockQuantity: product.stockQuantity,
        stockStatus: product.stockStatus,
        isEnabled: product.isEnabled,
        isVeg: product.isVeg,
        selected: product.isEnabled,
      );

      grouped.putIfAbsent(
        categoryName,
            () => [],
      );

      grouped[categoryName]!.add(item);
    }

    final categories =
    grouped.entries.map(
          (entry) {
        return StockCategory(
          name: entry.key,
          items: entry.value,
        );
      },
    ).toList();

    if (!mounted) return;

    setState(() {
      _stockCategories = categories;

      if (_stockCategories.isNotEmpty) {
        final exists =
        _stockCategories.any(
              (category) =>
          category.name ==
              _selectedCategory,
        );

        if (!exists) {
          _selectedCategory =
              _stockCategories.first.name;
        }
      }
    });

    debugPrint(
      'CATEGORY COUNT: '
          '${_stockCategories.length}',
    );
  }

  // ==========================================================
  // CURRENT CATEGORY
  // ==========================================================

  StockCategory? get _currentCategory {
    if (_stockCategories.isEmpty) {
      return null;
    }

    return _stockCategories.firstWhere(
          (category) =>
      category.name ==
          _selectedCategory,
      orElse: () =>
      _stockCategories.first,
    );
  }

  // ==========================================================
  // FILTERED ITEMS
  // ==========================================================

  List<StockItem> get _filteredItems {
    final category = _currentCategory;

    if (category == null) {
      return [];
    }

    final search = _searchController.text
        .trim()
        .toLowerCase();

    if (search.isEmpty) {
      return category.items;
    }

    return category.items.where((item) {
      return item.name
          .toLowerCase()
          .contains(search);
    }).toList();
  }

  // ==========================================================
  // TOTAL ITEMS
  // ==========================================================

  int get _totalItems {
    return _stockCategories.fold<int>(
      0,
          (total, category) =>
      total + category.items.length,
    );
  }

  // ==========================================================
  // SELECTED ITEMS
  // ==========================================================

  int get _selectedItems {
    return _stockCategories.fold<int>(
      0,
          (total, category) =>
      total +
          category.items
              .where(
                (item) => item.selected,
          )
              .length,
    );
  }

  // ==========================================================
  // UNSELECTED ITEMS
  // ==========================================================

  int get _unselectedItems {
    return _totalItems - _selectedItems;
  }

  // ==========================================================
  // CURRENT CATEGORY SELECTED
  // ==========================================================

  int get _currentSelectedCount {
    final category = _currentCategory;

    if (category == null) {
      return 0;
    }

    return category.items
        .where(
          (item) => item.selected,
    )
        .length;
  }

  // ==========================================================
  // CURRENT CATEGORY SELECT ALL
  // ==========================================================

  bool get _isCurrentCategoryAllSelected {
    final category = _currentCategory;

    if (category == null) {
      return false;
    }

    final enabledItems = category.items
        .where(
          (item) => item.isEnabled,
    )
        .toList();

    if (enabledItems.isEmpty) {
      return false;
    }

    return enabledItems.every(
          (item) => item.selected,
    );
  }

  // ==========================================================
  // SELECT ALL
  // ==========================================================

  void _toggleSelectAllCurrentCategory(
      bool value,
      ) {
    final category = _currentCategory;

    if (category == null) {
      return;
    }

    setState(() {
      for (final item in category.items) {
        if (item.isEnabled) {
          item.selected = value;
        } else {
          // Always keep disabled items unselected.
          item.selected = false;
        }
      }
    });
  }

  // ==========================================================
  // RESET
  // ==========================================================

  // void _resetSelection() {
  //   setState(() {
  //     for (final category
  //     in _stockCategories) {
  //       for (final item in category.items) {
  //         if (item.isEnabled) {
  //           item.selected = false;
  //         } else {
  //           item.selected = false;
  //         }
  //       }
  //     }
  //   });
  // }

  // ==========================================================
  // SAVE & UPDATE
  // ==========================================================

  Future<void> _saveAndUpdate() async {
    final changedItems = <StockItem>[];

    // ==========================================
    // FIND CHANGED ITEMS
    // ==========================================

    for (final category in _stockCategories) {
      for (final item in category.items) {
        if (item.selected != item.isEnabled) {
          changedItems.add(item);
        }
      }
    }

    debugPrint('======================================');
    debugPrint('STOCK SAVE & UPDATE');
    debugPrint('CHANGED ITEMS: ${changedItems.length}');

    for (final item in changedItems) {
      debugPrint(
        '${item.name} | '
            'Old: ${item.isEnabled} | '
            'New: ${item.selected}',
      );
    }

    debugPrint('======================================');

    // ==========================================
    // NO CHANGES
    // ==========================================

    if (changedItems.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to update'),
        ),
      );

      return;
    }

    // ==========================================
    // PIN ONLY HERE
    // ==========================================

    final pin = await showStockPinDialog();

    if (pin == null || pin.isEmpty) {
      return;
    }

    try {
      // ==========================================
      // UPDATE ALL CHANGED ITEMS
      // ==========================================

      for (final item in changedItems) {
        await updateProductStockStatus(
          item: item,
          pin: pin,
        );
      }

      // ==========================================
      // ONLY ONE RELOAD
      // ==========================================

      await loadProducts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${changedItems.length} items updated successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update stock: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      key: _scaffoldKey,

      backgroundColor:
      const Color(0xffF4F4F4),

      // ======================================================
      // DRAWER
      // ======================================================

      drawer: _buildKdsDrawer(),

      body: SafeArea(
        child: Column(
          children: [
            // =================================================
            // TOP BAR
            // =================================================

            TopBarWidget(
              token: widget.token,
              restaurantId:
              widget.restaurantId,

              selectedView:
              KotView.active,

              onViewChanged:
                  (view) {},

              pendingCount: 0,
              activeCount: 0,
              repeatedCount: 0,

              onLogout: () {},

              onMenuTap: () {
                _scaffoldKey
                    .currentState
                    ?.openDrawer();
              },
            ),

            // =================================================
            // CONTENT
            // =================================================

            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  8,
                ),
                child: _buildStockBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // STOCK BODY
  // ==========================================================

  Widget _buildStockBody() {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(10),

        border: Border.all(
          color:
          const Color(0xffE4E7EC),
        ),
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            // =================================================
            // TITLE
            // =================================================

            Text(
              'STOCK',

              style:
              GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight:
                FontWeight.w800,
                color:
                const Color(
                  0xff172033,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // =================================================
            // MAIN STOCK AREA
            // =================================================

            Expanded(
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  // LEFT CATEGORY
                  SizedBox(
                    width: 105,
                    child:
                    _buildCategorySidebar(),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  // RIGHT PRODUCTS
                  Expanded(
                    child:
                    _buildStockItemsArea(),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // =================================================
            // SUMMARY
            // =================================================

            _buildBottomSummary(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CATEGORY SIDEBAR
  // ==========================================================

  Widget _buildCategorySidebar() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_stockCategories.isEmpty) {
      return const Center(
        child: Text('No Categories'),
      );
    }

    return Container(
      width: 100,
      color: Colors.white,

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Text(
            'CATEGORIES',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xff344054),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              itemCount:
              _stockCategories.length,

              separatorBuilder:
                  (_, __) =>
              const SizedBox(height: 8),

              itemBuilder:
                  (context, index) {
                final category =
                _stockCategories[index];

                final isSelected =
                    category.name ==
                        _selectedCategory;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory =
                          category.name;

                      _searchController.clear();
                    });
                  },

                  borderRadius:
                  BorderRadius.circular(6),

                  child: Container(
                    width: double.infinity,
                    height: 68,

                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(
                        0xff526887,
                      )
                          : const Color(
                        0xffF5F6F8,
                      ),

                      borderRadius:
                      BorderRadius.circular(6),

                      border: Border.all(
                        color: isSelected
                            ? const Color(
                          0xff526887,
                        )
                            : const Color(
                          0xffE4E7EC,
                        ),
                      ),
                    ),

                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,

                      children: [
                        Icon(
                          _categoryIcon(
                            category.name,
                          ),

                          size: 19,

                          color: isSelected
                              ? Colors.white
                              : const Color(
                            0xff526887,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          category.name,

                          textAlign:
                          TextAlign.center,

                          maxLines: 2,

                          overflow:
                          TextOverflow.ellipsis,

                          style:
                          GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w600,

                            color: isSelected
                                ? Colors.white
                                : const Color(
                              0xff344054,
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
        ],
      ),
    );
  }

  // ==========================================================
  // CATEGORY ICON
  // ==========================================================

  IconData _categoryIcon(
      String category,
      ) {
    final value =
    category.toLowerCase().trim();

    if (value.contains('soup')) {
      return Icons.soup_kitchen_outlined;
    }

    if (value.contains('starter')) {
      return Icons.restaurant;
    }

    if (value.contains('main')) {
      return Icons.ramen_dining;
    }

    if (value.contains('bread')) {
      return Icons.bakery_dining;
    }

    if (value.contains('dessert')) {
      return Icons.cake_outlined;
    }

    if (value.contains('beverage') ||
        value.contains('drink')) {
      return Icons.local_drink_outlined;
    }

    return Icons.restaurant_menu;
  }

  // ==========================================================
  // CATEGORY COLOR
  // ==========================================================

  Color _categoryColor(
      String category,
      ) {
    switch (category
        .toLowerCase()) {
      case 'soups':
        return const Color(
          0xff526887,
        );

      case 'starters':
        return const Color(
          0xff2357B8,
        );

      case 'main course':
        return const Color(
          0xffF04438,
        );

      case 'breads':
        return const Color(
          0xff2E9B91,
        );

      case 'desserts':
        return const Color(
          0xffE83E8C,
        );

      default:
        return const Color(
          0xff526887,
        );
    }
  }

  // ==========================================================
  // STOCK ITEMS AREA
  // ==========================================================

  Widget _buildStockItemsArea() {
    // ========================================================
    // LOADING
    // ========================================================

    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    // ========================================================
    // ERROR
    // ========================================================

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 30,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Failed to load products',

              style:
              GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _errorMessage!,
              textAlign:
              TextAlign.center,

              style:
              GoogleFonts.montserrat(
                fontSize: 14,
                color:
                const Color(
                  0xff667085,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            ElevatedButton(
              onPressed:
              loadProducts,

              child:
              const Text(
                'Retry',
              ),
            ),
          ],
        ),
      );
    }

    final items =
        _filteredItems;

    return Column(
      children: [
        // ====================================================
        // SEARCH + RESET
        // ====================================================

        Row(
          children: [
            // SEARCH
            SizedBox(
              width: 400, // 👈 change this value
              height: 36,
              child: TextField(
                controller: _searchController,

                onChanged: (_) {
                  setState(() {});
                },

                decoration: InputDecoration(
                  hintText: 'Search by category or item name',

                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xff98A2B3),
                  ),

                  prefixIcon: const Icon(
                    Icons.search,
                    size: 17,
                    color: Color(0xff98A2B3),
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Color(0xffD0D5DD),
                    ),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Color(0xffD0D5DD),
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Color(0xff526887),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // RESET
            SizedBox(
              width: 118,
              height: 36,
              child: OutlinedButton(
                onPressed: _resetSelection,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xff98A2B3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  'Reset',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff667085),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 8,
        ),

        // ====================================================
        // PRODUCTS
        // ====================================================

        Expanded(
          child: items.isEmpty
              ? Center(
            child: Text(
              'No items found',

              style:
              GoogleFonts.montserrat(
                fontSize: 14,
                color:
                const Color(
                  0xff98A2B3,
                ),
              ),
            ),
          )
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [
                // ======================================
                // CATEGORY HEADER
                // ======================================

                _buildCategoryHeader(),

                const SizedBox(
                  height: 8,
                ),

                // ======================================
                // ITEM GRID
                // ======================================

                LayoutBuilder(
                  builder:
                      (
                      context,
                      constraints,
                      ) {
                    const spacing =
                    9.0;

                    final width =
                        (constraints
                            .maxWidth -
                            spacing * 3) /
                            4;

                    return Wrap(
                      spacing:
                      spacing,

                      runSpacing:
                      9,

                      children:
                      items.map(
                            (item) {
                          return SizedBox(
                            width:
                            width,

                            child:
                            _buildStockItem(
                              item,
                            ),
                          );
                        },
                      ).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CATEGORY HEADER
  // ==========================================================

  Widget _buildCategoryHeader() {
    final category =
        _currentCategory;

    if (category == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        const Icon(
          Icons.category_outlined,
          size: 19,
          color:
          Color(0xff526887),
        ),

        const SizedBox(
          width: 7,
        ),

        Text(
          category.name,

          style:
          GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight:
            FontWeight.w600,
            color:
            const Color(
              0xff172033,
            ),
          ),
        ),

        const SizedBox(
          width: 28,
        ),

        Text(
          '${_currentSelectedCount}/${category.items.length} Selected',

          style:
          GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight:
            FontWeight.w500,
            color:
            const Color(
              0xff174EA6,
            ),
          ),
        ),

        const Spacer(),

        Checkbox(
          value:
          _isCurrentCategoryAllSelected,

          activeColor:
          const Color(
            0xff526887,
          ),

          visualDensity:
          VisualDensity.compact,

          onChanged:
          category.items.any(
                (item) =>
            item.isEnabled,
          )
              ? (value) {
            _toggleSelectAllCurrentCategory(
              value ?? false,
            );
          }
              : null,
        ),

        Text(
          'Select All',

          style:
          GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight:
            FontWeight.w600,
            color:
            const Color(
              0xff172033,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // STOCK ITEM
  // ==========================================================

  Widget _buildStockItem(StockItem item) {
    final selected = item.selected;
    final enabled = item.isEnabled;

    return InkWell(
      // ======================================================
      // ALWAYS CLICKABLE
      // ======================================================

      onTap: () {
        setState(() {
          item.selected = !item.selected;
        });
      },

      borderRadius: BorderRadius.circular(5),

      child: Container(
        height: 56,

        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),

        decoration: BoxDecoration(
          // ==================================================
          // OUT OF STOCK = GREY
          // IN STOCK     = WHITE
          // ==================================================

          color: enabled
              ? Colors.white
              : const Color(0xffE5E5E5),

          borderRadius: BorderRadius.circular(5),

          border: Border.all(
            color: enabled
                ? const Color(0xffCDEBD4)
                : const Color(0xffBDBDBD),
          ),
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ==================================================
            // CHECKBOX
            // ==================================================

            Container(
              width: 15,
              height: 15,

              decoration: BoxDecoration(
                // --------------------------------------------
                // OUT OF STOCK + NOT SELECTED
                // → WHITE EMPTY CHECKBOX
                //
                // SELECTED VEG
                // → GREEN
                //
                // SELECTED NON VEG
                // → RED
                // --------------------------------------------

                color: selected
                    ? (item.isVeg
                    ? const Color(0xff08A64A)
                    : const Color(0xffF04438))
                    : Colors.white,

                borderRadius:
                BorderRadius.circular(2),

                border: Border.all(
                  color: selected
                      ? (item.isVeg
                      ? const Color(0xff08A64A)
                      : const Color(0xffF04438))
                      : const Color(0xff98A2B3),
                ),
              ),

              child: selected
                  ? const Icon(
                Icons.check,
                size: 11,
                color: Colors.white,
              )
                  : null,
            ),

            const SizedBox(width: 8),

            // ==================================================
            // ITEM NAME
            // ==================================================

            Expanded(
              child: Text(
                item.name,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  height: 1.15,
                  fontWeight: FontWeight.w500,

                  color: enabled
                      ? const Color(0xff172033)
                      : const Color(0xff777777),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ==========================================================
  // KDS DRAWER
  // ==========================================================

  Widget _buildKdsDrawer() {
    return Drawer(
      width: 250,
      backgroundColor:
      Colors.white,

      child: SafeArea(
        child: Column(
          children: [
            // =================================================
            // HEADER
            // =================================================

            Container(
              height: 65,

              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
              ),

              decoration:
              const BoxDecoration(
                border: Border(
                  bottom:
                  BorderSide(
                    color:
                    Color(
                      0xffE4E7EC,
                    ),
                  ),
                ),
              ),

              child: Row(
                children: [
                  Expanded(
                    child: Image.asset(
                      'assets/pinaka.png',

                      height: 42,

                      fit: BoxFit.contain,

                      alignment:
                      Alignment.centerLeft,
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    child:
                    const Icon(
                      Icons.chevron_left,
                      size: 26,
                      color:
                      Color(
                        0xff667085,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // MENU
            // =================================================

            Expanded(
              child:
              SingleChildScrollView(
                padding:
                const EdgeInsets.all(
                  10,
                ),

                child: Column(
                  children: [
                    // =========================================
                    // KDS DASHBOARD
                    // =========================================

                    _buildDrawerMenuItem(
                      title:
                      'KDS Dashboard',

                      icon:
                      Icons.grid_view_rounded,

                      onTap: () {
                        Navigator.pop(
                          context,
                        );

                        Navigator.pushReplacement(
                          context,

                          MaterialPageRoute(
                            builder: (_) =>
                                KitchenDashboardScreen(
                                  token:
                                  widget.token,

                                  restaurantId:
                                  widget.restaurantId,
                                ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    // =========================================
                    // SELECT ITEM
                    // =========================================

                    _buildDrawerMenuItem(
                      title:
                      'Select Item / Category',

                      icon:
                      Icons.format_list_bulleted,

                      onTap: () {
                        Navigator.pop(
                          context,
                        );
                      },
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    // =========================================
                    // STOCK
                    // =========================================

                    _buildDrawerMenuItem(
                      title: 'Stock',

                      icon:
                      Icons.inventory_2_outlined,

                      isSelected: true,

                      onTap: () {
                        Navigator.pop(
                          context,
                        );
                      },
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    // =========================================
                    // RECALL
                    // =========================================

                    _buildDrawerMenuItem(
                      title: 'Recall',

                      icon:
                      Icons.refresh,

                      onTap: () {
                        Navigator.pop(
                          context,
                        );

                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) =>
                                CompletedOrdersScreen(
                                  token:
                                  widget.token,

                                  restaurantId:
                                  widget.restaurantId,
                                ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    // =========================================
                    // SETTINGS
                    // =========================================

                    _buildDrawerMenuItem(
                      title: 'Settings',

                      icon:
                      Icons.settings_outlined,

                      onTap: () {
                        Navigator.pop(
                          context,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // =================================================
            // LOGOUT
            // =================================================

            _buildDrawerLogout(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DRAWER MENU ITEM
  // ==========================================================

  Widget _buildDrawerMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
      BorderRadius.circular(
        8,
      ),

      child: Container(
        height: 44,

        width: double.infinity,

        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
        ),

        decoration:
        BoxDecoration(
          color: isSelected
              ? const Color(
            0xffff5b4f,
          )
              : Colors.transparent,

          borderRadius:
          BorderRadius.circular(
            8,
          ),
        ),

        child: Row(
          children: [
            Icon(
              icon,

              size: 20,

              color: isSelected
                  ? Colors.white
                  : const Color(
                0xff667085,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Text(
                title,

                style:
                GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,

                  color: isSelected
                      ? Colors.white
                      : const Color(
                    0xff344054,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Widget _buildDrawerLogout() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        15,
      ),

      child: InkWell(
        onTap: () async {
          final prefs =
          await SharedPreferences
              .getInstance();

          final storeBaseUrl =
              prefs.getString(
                'store_base_url',
              ) ??
                  '';

          final storeName =
              prefs.getString(
                'store_name',
              ) ??
                  '';

          final storeId =
              prefs.getString(
                'store_id',
              ) ??
                  '';

          await prefs.remove(
            'token',
          );

          await prefs.remove(
            'auth_token',
          );

          await prefs.remove(
            'user_id',
          );

          await prefs.remove(
            'employee_name',
          );

          await prefs.remove(
            'display_name',
          );

          await prefs.remove(
            'role',
          );

          await prefs.remove(
            'emp_login_pin',
          );

          await prefs.remove(
            'emp_login_pin_str',
          );

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,

            MaterialPageRoute(
              builder: (context) =>
                  EmployeeLoginScreen(
                    storeBaseUrl:
                    storeBaseUrl,

                    storeName:
                    storeName,

                    storeId:
                    storeId,

                    onLoginSuccess:
                        (config) {
                      Navigator.pushAndRemoveUntil(
                        context,

                        MaterialPageRoute(
                          builder: (context) =>
                              KitchenDashboardScreen(
                                token:
                                config.apiToken,

                                restaurantId:
                                int.tryParse(
                                  config.restaurantId,
                                ) ??
                                    0,
                              ),
                        ),

                            (route) => false,
                      );
                    },
                  ),
            ),

                (route) => false,
          );
        },

        borderRadius:
        BorderRadius.circular(
          8,
        ),

        child: Container(
          height: 44,

          width:
          double.infinity,

          decoration:
          BoxDecoration(
            color:
            const Color(
              0xffffefec,
            ),

            borderRadius:
            BorderRadius.circular(
              8,
            ),

            border: Border.all(
              color:
              const Color(
                0xffffa69b,
              ),

              width: 0.8,
            ),
          ),

          child: const Row(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [
              Icon(
                Icons.logout,

                size: 17,

                color:
                Color(
                  0xffff4f3d,
                ),
              ),

              SizedBox(
                width: 7,
              ),

              Text(
                'Logout',

                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,

                  color:
                  Color(
                    0xffff4f3d,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BOTTOM SUMMARY
  // ==========================================================

  Widget _buildBottomSummary() {
    return Row(
      children: [
        // ====================================================
        // TOTAL
        // ====================================================

        _buildSummaryCard(
          title: 'Total Items',

          value:
          _totalItems.toString(),

          icon:
          Icons.inventory_2_outlined,

          background:
          const Color(
            0xffEEF5FF,
          ),

          iconColor:
          const Color(
            0xff2563EB,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ====================================================
        // SELECTED
        // ====================================================

        _buildSummaryCard(
          title: 'Selected',

          value:
          _selectedItems.toString(),

          icon:
          Icons.check_circle_outline,

          background:
          const Color(
            0xffEDFFF3,
          ),

          iconColor:
          const Color(
            0xff12B76A,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ====================================================
        // UNSELECTED
        // ====================================================

        _buildSummaryCard(
          title: 'Unselected',

          value:
          _unselectedItems.toString(),

          icon:
          Icons.cancel_outlined,

          background:
          const Color(
            0xfffff5ea,
          ),

          iconColor:
          const Color(
            0xffF04438,
          ),
        ),

        const Spacer(),

        // ====================================================
        // SAVE & UPDATE
        // ====================================================

        SizedBox(
          width: 262,
          height: 34,

          child:
          ElevatedButton(
            onPressed:
            _saveAndUpdate,

            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              const Color(
                0xffff5b4f,
              ),

              foregroundColor:
              Colors.white,

              elevation: 0,

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  6,
                ),
              ),
            ),

            child: Text(
              'Save & Update',

              style:
              GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SUMMARY CARD
  // ==========================================================

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color background,
    required Color iconColor,
  }) {
    return Container(
      height: 34,

      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
      ),

      decoration:
      BoxDecoration(
        color: background,

        borderRadius:
        BorderRadius.circular(
          6,
        ),

        border: Border.all(
          color:
          iconColor.withOpacity(
            .18,
          ),
        ),
      ),

      child: Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          Container(
            width: 20,
            height: 20,

            decoration:
            BoxDecoration(
              color: iconColor,

              borderRadius:
              BorderRadius.circular(
                4,
              ),
            ),

            child: Icon(
              icon,

              size: 12,

              color: Colors.white,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            title,

            style:
            GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight:
              FontWeight.w600,
              color:
              const Color(
                0xff344054,
              ),
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            value,

            style:
            GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight:
              FontWeight.w800,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STOCK CATEGORY MODEL
// ============================================================

class StockCategory {
  final String name;
  final List<StockItem> items;

  StockCategory({
    required this.name,
    required this.items,
  });
}

// ============================================================
// STOCK ITEM MODEL
// ============================================================

class StockItem {
  final int id;
  final String name;
  final int? stockQuantity;
  final String stockStatus;

  final bool isEnabled;

  // ADD THIS
  final bool isVeg;

  bool selected;

  StockItem({
    required this.id,
    required this.name,
    this.stockQuantity,
    required this.stockStatus,
    required this.isEnabled,

    // ADD THIS
    required this.isVeg,

    required this.selected,
  });
}