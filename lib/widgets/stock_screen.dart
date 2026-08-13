import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../kitchen_display_screen.dart';
import '../top_bar.dart';
import 'completed_orders.dart';
import 'login_screen.dart';

// import 'top_bar.dart';

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
  // SEARCH
  // ==========================================================

  final TextEditingController _searchController =
  TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey =
  GlobalKey<ScaffoldState>();

  // ==========================================================
  // SELECTED CATEGORY
  // ==========================================================

  String _selectedCategory = 'Soups';

  // ==========================================================
  // STOCK DATA
  // ==========================================================

  final List<StockCategory> _stockCategories = [
    StockCategory(
      name: 'Soups',
      items: [
        StockItem(
          name: 'Tomato Creamy Soup',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Veg Clear Soup',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Veg Manchow Soup',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Veg Corn Soup',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Chicken Corn Soup',
          isVeg: false,
          selected: true,
        ),
        StockItem(
          name: 'Chicken Manchow Soup',
          isVeg: false,
          selected: true,
        ),
        StockItem(
          name: 'Chicken Hot & Sour Soup',
          isVeg: false,
          selected: true,
        ),
        StockItem(
          name: 'Chicken Clear Soup',
          isVeg: false,
          selected: false,
        ),
      ],
    ),

    StockCategory(
      name: 'Starters',
      items: [
        StockItem(
          name: 'Panner Tikka',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Mushroom Bites',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Baby Corn Ribs',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Veg Manchuria',
          isVeg: true,
          selected: false,
        ),
        StockItem(
          name: 'Dragon Chicken',
          isVeg: false,
          selected: false,
        ),
        StockItem(
          name: 'Chicken Tikka',
          isVeg: false,
          selected: false,
        ),
        StockItem(
          name: 'Fish Fingers',
          isVeg: false,
          selected: false,
        ),
        StockItem(
          name: 'Prawn Pepper Fry',
          isVeg: false,
          selected: false,
        ),
      ],
    ),

    StockCategory(
      name: 'Main Course',
      items: [
        StockItem(
          name: 'Chicken 65',
          isVeg: false,
          selected: true,
        ),
        StockItem(
          name: 'Chicken Tikka',
          isVeg: false,
          selected: true,
        ),
        StockItem(
          name: 'Paneer Tikka',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Veg Biryani',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Chicken Biryani',
          isVeg: false,
          selected: false,
        ),
        StockItem(
          name: 'Butter Chicken',
          isVeg: false,
          selected: false,
        ),
        StockItem(
          name: 'Paneer Butter Masala',
          isVeg: true,
          selected: false,
        ),
        StockItem(
          name: 'Mutton Curry',
          isVeg: false,
          selected: false,
        ),
      ],
    ),

    StockCategory(
      name: 'Breads',
      items: [
        StockItem(
          name: 'Butter Naan',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Plain Naan',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Garlic Naan',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Tandoori Roti',
          isVeg: true,
          selected: false,
        ),
        StockItem(
          name: 'Butter Roti',
          isVeg: true,
          selected: false,
        ),
      ],
    ),

    StockCategory(
      name: 'Desserts',
      items: [
        StockItem(
          name: 'Gulab Jamun',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Ice Cream',
          isVeg: true,
          selected: true,
        ),
        StockItem(
          name: 'Brownie',
          isVeg: true,
          selected: false,
        ),
        StockItem(
          name: 'Fruit Salad',
          isVeg: true,
          selected: false,
        ),
      ],
    ),
  ];

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // CURRENT CATEGORY
  // ==========================================================

  StockCategory get _currentCategory {
    return _stockCategories.firstWhere(
          (category) =>
      category.name == _selectedCategory,
    );
  }

  // ==========================================================
  // SEARCHED ITEMS
  // ==========================================================

  List<StockItem> get _filteredItems {
    final search =
    _searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return _currentCategory.items;
    }

    return _currentCategory.items.where((item) {
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
              .where((item) => item.selected)
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
    return _currentCategory.items
        .where((item) => item.selected)
        .length;
  }

  // ==========================================================
  // SELECT ALL CURRENT CATEGORY
  // ==========================================================

  bool get _isCurrentCategoryAllSelected {
    final items = _currentCategory.items;

    if (items.isEmpty) {
      return false;
    }

    return items.every(
          (item) => item.selected,
    );
  }

  // ==========================================================
  // SELECT ALL
  // ==========================================================

  void _toggleSelectAllCurrentCategory(
      bool value,
      ) {
    setState(() {
      for (final item in _currentCategory.items) {
        item.selected = value;
      }
    });
  }

  // ==========================================================
  // RESET
  // ==========================================================

  void _resetSelection() {
    setState(() {
      for (final category in _stockCategories) {
        for (final item in category.items) {
          item.selected = false;
        }
      }
    });
  }

  // ==========================================================
  // SAVE & UPDATE
  // ==========================================================

  Future<void> _saveAndUpdate() async {
    final selectedItems = <String>[];

    for (final category in _stockCategories) {
      for (final item in category.items) {
        if (item.selected) {
          selectedItems.add(item.name);
        }
      }
    }

    debugPrint(
      '======================================',
    );

    debugPrint(
      'STOCK SAVE & UPDATE',
    );

    debugPrint(
      'TOTAL ITEMS: $_totalItems',
    );

    debugPrint(
      'SELECTED ITEMS: ${selectedItems.length}',
    );

    debugPrint(
      'UNSELECTED ITEMS: $_unselectedItems',
    );

    debugPrint(
      'SELECTED ITEM NAMES:',
    );

    for (final item in selectedItems) {
      debugPrint(item);
    }

    debugPrint(
      '======================================',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selectedItems.length} items updated successfully',
        ),
        duration: const Duration(
          seconds: 2,
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      backgroundColor: const Color(0xffF4F4F4),

      // ==========================================================
      // KDS DRAWER
      // ==========================================================

      drawer: _buildKdsDrawer(),

      body: SafeArea(
        child: Column(
          children: [

            // ======================================================
            // TOP BAR
            // ======================================================

            TopBarWidget(
              token: widget.token,
              restaurantId: widget.restaurantId,

              selectedView: KotView.active,

              onViewChanged: (view) {
                // Do not Navigator.pop here.
                // TopBar only changes view.
              },

              pendingCount: 0,
              activeCount: 0,
              repeatedCount: 0,

              onLogout: () {},

              // ====================================================
              // HAMBURGER MENU
              // ====================================================

              onMenuTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),

            // ======================================================
            // STOCK CONTENT
            // ======================================================

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
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
          color: const Color(0xffE4E7EC),
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // ==================================================
            // TITLE
            // ==================================================

            Text(
              'STOCK',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight:
                FontWeight.w800,
                color:
                const Color(0xff172033),
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // MAIN STOCK AREA
            // ==================================================

            Expanded(
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  // =================================================
                  // LEFT CATEGORY MENU
                  // =================================================

                  SizedBox(
                    width: 110,
                    child:
                    _buildCategorySidebar(),
                  ),

                  const SizedBox(width: 14),

                  // =================================================
                  // RIGHT CONTENT
                  // =================================================

                  Expanded(
                    child:
                    _buildStockItemsArea(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // BOTTOM SUMMARY
            // ==================================================

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
    return ListView.separated(
      itemCount:
      _stockCategories.length,

      separatorBuilder:
          (context, index) =>
      const SizedBox(height: 8),

      itemBuilder: (context, index) {
        final category =
        _stockCategories[index];

        final selected =
            category.name ==
                _selectedCategory;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory =
                  category.name;

              _searchController.clear();
            });
          },

          child: Container(
            height: 65,

            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xff526887)
                  : Colors.white,

              borderRadius:
              BorderRadius.circular(7),

              border: Border.all(
                color: selected
                    ? const Color(
                  0xff526887,
                )
                    : const Color(
                  0xffDCE3EE,
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
                  size: 20,

                  color: selected
                      ? Colors.white
                      : _categoryColor(
                    category.name,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  category.name,

                  textAlign:
                  TextAlign.center,

                  style:
                  GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w600,
                    color: selected
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
    );
  }

  // ==========================================================
  // CATEGORY ICON
  // ==========================================================

  IconData _categoryIcon(
      String category,
      ) {
    switch (category) {
      case 'Soups':
        return Icons.soup_kitchen_outlined;

      case 'Starters':
        return Icons.restaurant;

      case 'Main Course':
        return Icons.ramen_dining;

      case 'Breads':
        return Icons.bakery_dining;

      case 'Desserts':
        return Icons.cake_outlined;

      default:
        return Icons.restaurant;
    }
  }

  // ==========================================================
  // CATEGORY COLOR
  // ==========================================================

  Color _categoryColor(
      String category,
      ) {
    switch (category) {
      case 'Soups':
        return const Color(0xff526887);

      case 'Starters':
        return const Color(0xff2357B8);

      case 'Main Course':
        return const Color(0xffF04438);

      case 'Breads':
        return const Color(0xff2E9B91);

      case 'Desserts':
        return const Color(0xffE83E8C);

      default:
        return const Color(0xff526887);
    }
  }

  Widget _buildKdsDrawer() {
    return Drawer(
      width: 250,
      backgroundColor: Colors.white,

      child: SafeArea(
        child: Column(
          children: [

            // HEADER
            Container(
              height: 65,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xffE4E7EC),
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
                      alignment: Alignment.centerLeft,
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.chevron_left,
                      size: 26,
                      color: Color(0xff667085),
                    ),
                  ),
                ],
              ),
            ),

            // MENU
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [

                    _buildDrawerMenuItem(
                      title: 'KDS Dashboard',
                      icon: Icons.grid_view_rounded,
                      onTap: () {
                        Navigator.pop(context);

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                KitchenDashboardScreen(
                                  token: widget.token,
                                  restaurantId:
                                  widget.restaurantId,
                                ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 7),

                    _buildDrawerMenuItem(
                      title: 'Select Item / Category',
                      icon: Icons.format_list_bulleted,
                      onTap: () {
                        Navigator.pop(context);

                        // Navigate to Select Item screen
                      },
                    ),

                    const SizedBox(height: 7),

                    _buildDrawerMenuItem(
                      title: 'Stock',
                      icon: Icons.inventory_2_outlined,
                      isSelected: true,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),

                    const SizedBox(height: 7),

                    _buildDrawerMenuItem(
                      title: 'Recall',
                      icon: Icons.refresh,
                      onTap: () {
                        Navigator.pop(context);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CompletedOrdersScreen(
                                  token: widget.token,
                                  restaurantId:
                                  widget.restaurantId,
                                ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 7),

                    _buildDrawerMenuItem(
                      title: 'Settings',
                      icon: Icons.settings_outlined,
                      onTap: () {
                        Navigator.pop(context);

                        // Settings navigation
                      },
                    ),
                  ],
                ),
              ),
            ),

            // LOGOUT
            _buildDrawerLogout(),
          ],
        ),
      ),
    );
  }
  Widget _buildDrawerMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),

      child: Container(
        height: 44,
        width: double.infinity,

        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),

        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xffff5b4f)
              : Colors.transparent,

          borderRadius: BorderRadius.circular(8),
        ),

        child: Row(
          children: [

            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : const Color(0xff667085),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xff344054),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDrawerLogout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        15,
      ),
      child: InkWell(
        onTap: () async {
          // ==================================================
          // GET SHARED PREFERENCES
          // ==================================================

          final prefs =
          await SharedPreferences.getInstance();

          // ==================================================
          // GET STORE DETAILS BEFORE CLEARING SESSION
          // ==================================================

          final storeBaseUrl =
              prefs.getString('store_base_url') ?? '';

          final storeName =
              prefs.getString('store_name') ?? '';

          final storeId =
              prefs.getString('store_id') ?? '';

          // ==================================================
          // CLEAR LOGIN SESSION
          // ==================================================

          await prefs.remove('token');
          await prefs.remove('auth_token');
          await prefs.remove('user_id');
          await prefs.remove('employee_name');
          await prefs.remove('display_name');
          await prefs.remove('role');
          await prefs.remove('emp_login_pin');
          await prefs.remove('emp_login_pin_str');

          if (!mounted) return;

          // ==================================================
          // GO TO LOGIN SCREEN
          // ==================================================

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeLoginScreen(
                storeBaseUrl: storeBaseUrl,
                storeName: storeName,
                storeId: storeId,

                // ==================================================
                // AFTER PIN LOGIN SUCCESS
                // ==================================================

                onLoginSuccess: (config) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          KitchenDashboardScreen(
                            token: config.apiToken,
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

        borderRadius: BorderRadius.circular(8),

        child: Container(
          height: 44,
          width: double.infinity,

          decoration: BoxDecoration(
            color: const Color(0xffffefec),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xffffa69b),
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
                color: Color(0xffff4f3d),
              ),

              SizedBox(width: 7),

              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xffff4f3d),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ==========================================================
  // RIGHT CONTENT
  // ==========================================================

  Widget _buildStockItemsArea() {
    final items = _filteredItems;

    return Column(
      children: [

        // ==================================================
        // SEARCH + RESET
        // ==================================================

        Row(
          children: [

            Expanded(
              child: SizedBox(
                height: 36,

                child: TextField(
                  controller:
                  _searchController,

                  onChanged: (_) {
                    setState(() {});
                  },

                  decoration:
                  InputDecoration(
                    hintText:
                    'Search by category or item name',

                    hintStyle:
                    GoogleFonts.montserrat(
                      fontSize: 9,
                      color:
                      const Color(
                        0xff98A2B3,
                      ),
                    ),

                    prefixIcon:
                    const Icon(
                      Icons.search,
                      size: 17,
                      color:
                      Color(0xff98A2B3),
                    ),

                    filled: true,

                    fillColor:
                    Colors.white,

                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 10,
                    ),

                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius
                          .circular(5),

                      borderSide:
                      const BorderSide(
                        color:
                        Color(
                          0xffD0D5DD,
                        ),
                      ),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius
                          .circular(5),

                      borderSide:
                      const BorderSide(
                        color:
                        Color(
                          0xffD0D5DD,
                        ),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius
                          .circular(5),

                      borderSide:
                      const BorderSide(
                        color:
                        Color(
                          0xff526887,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 118,
              height: 36,

              child: OutlinedButton(
                onPressed:
                _resetSelection,

                style:
                OutlinedButton.styleFrom(
                  side:
                  const BorderSide(
                    color:
                    Color(0xff98A2B3),
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      5,
                    ),
                  ),
                ),

                child: Text(
                  'Reset',
                  style:
                  GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    const Color(
                      0xff667085,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ==================================================
        // ITEMS
        // ==================================================

        Expanded(
          child: items.isEmpty
              ? Center(
            child: Text(
              'No items found',
              style:
              GoogleFonts.montserrat(
                fontSize: 11,
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

                // ==================================================
                // CATEGORY HEADER
                // ==================================================

                _buildCategoryHeader(),

                const SizedBox(
                  height: 8,
                ),

                // ==================================================
                // ITEM GRID
                // ==================================================

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
                            spacing *
                                3) /
                            4;

                    return Wrap(
                      spacing: spacing,
                      runSpacing:
                      9,

                      children:
                      items.map(
                            (item) {
                          return SizedBox(
                            width: width,

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
    return Row(
      children: [

        _buildVegIcon(
          true,
          size: 19,
        ),

        const SizedBox(width: 7),

        Text(
          _currentCategory.name,

          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight:
            FontWeight.w600,
            color:
            const Color(0xff172033),
          ),
        ),

        const SizedBox(width: 28),

        Text(
          '${_currentSelectedCount}/${_currentCategory.items.length} Selected',

          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight:
            FontWeight.w500,
            color:
            const Color(0xff174EA6),
          ),
        ),

        const Spacer(),

        Checkbox(
          value:
          _isCurrentCategoryAllSelected,

          activeColor:
          const Color(0xff526887),

          visualDensity:
          VisualDensity.compact,

          onChanged: (value) {
            _toggleSelectAllCurrentCategory(
              value ?? false,
            );
          },
        ),

        Text(
          'Select All',

          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight:
            FontWeight.w600,
            color:
            const Color(0xff172033),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // STOCK ITEM
  // ==========================================================

  Widget _buildStockItem(
      StockItem item,
      ) {
    final selected =
        item.selected;

    final isVeg =
        item.isVeg;

    return InkWell(
      onTap: () {
        setState(() {
          item.selected =
          !item.selected;
        });
      },

      borderRadius:
      BorderRadius.circular(5),

      child: Container(
        height: 56,

        padding:
        const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),

        decoration: BoxDecoration(
          color: isVeg
              ? const Color(
            0xffF8FFF9,
          )
              : const Color(
            0xfffff8f8,
          ),

          borderRadius:
          BorderRadius.circular(5),

          border: Border.all(
            color: isVeg
                ? const Color(
              0xffCDEBD4,
            )
                : const Color(
              0xffffd4d8,
            ),
          ),
        ),

        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.center,

          children: [

            // ==================================================
            // CHECKBOX
            // ==================================================

            Container(
              width: 15,
              height: 15,

              decoration: BoxDecoration(
                color: selected
                    ? (isVeg
                    ? const Color(
                  0xff08A64A,
                )
                    : const Color(
                  0xffF41446,
                ))
                    : Colors.transparent,

                borderRadius:
                BorderRadius.circular(
                  2,
                ),

                border: Border.all(
                  color: selected
                      ? (isVeg
                      ? const Color(
                    0xff08A64A,
                  )
                      : const Color(
                    0xffF41446,
                  ))
                      : const Color(
                    0xff98A2B3,
                  ),
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

                overflow:
                TextOverflow.ellipsis,

                style:
                GoogleFonts.montserrat(
                  fontSize: 10,
                  height: 1.15,
                  fontWeight:
                  FontWeight.w500,
                  color:
                  const Color(
                    0xff172033,
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
  // VEG / NON VEG ICON
  // ==========================================================

  Widget _buildVegIcon(
      bool isVeg, {
        double size = 14,
      }) {
    final color = isVeg
        ? const Color(0xff12B76A)
        : const Color(0xffF04438);

    return Container(
      width: size,
      height: size,

      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 1,
        ),

        borderRadius:
        BorderRadius.circular(3),
      ),

      child: Center(
        child: Container(
          width: size * .45,
          height: size * .45,

          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
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

        // ==================================================
        // TOTAL
        // ==================================================

        _buildSummaryCard(
          title: 'Total Items',
          value:
          _totalItems.toString(),
          icon:
          Icons.inventory_2_outlined,
          background:
          const Color(0xffEEF5FF),
          iconColor:
          const Color(0xff2563EB),
        ),

        const SizedBox(width: 12),

        // ==================================================
        // SELECTED
        // ==================================================

        _buildSummaryCard(
          title: 'Selected',
          value:
          _selectedItems.toString(),
          icon:
          Icons.check_circle_outline,
          background:
          const Color(0xffEDFFF3),
          iconColor:
          const Color(0xff12B76A),
        ),

        const SizedBox(width: 12),

        // ==================================================
        // UNSELECTED
        // ==================================================

        _buildSummaryCard(
          title: 'Unselected',
          value:
          _unselectedItems.toString(),
          icon:
          Icons.cancel_outlined,
          background:
          const Color(0xfffff5ea),
          iconColor:
          const Color(0xffF04438),
        ),

        const Spacer(),

        // ==================================================
        // SAVE & UPDATE
        // ==================================================

        SizedBox(
          width: 162,
          height: 34,

          child: ElevatedButton(
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
                fontSize: 10,
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

      decoration: BoxDecoration(
        color: background,

        borderRadius:
        BorderRadius.circular(6),

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

            decoration: BoxDecoration(
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

          const SizedBox(width: 6),

          Text(
            title,

            style:
            GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight:
              FontWeight.w600,
              color:
              const Color(
                0xff344054,
              ),
            ),
          ),

          const SizedBox(width: 5),

          Text(
            value,

            style:
            GoogleFonts.montserrat(
              fontSize: 10,
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
  final String name;
  final bool isVeg;
  bool selected;

  StockItem({
    required this.name,
    required this.isVeg,
    required this.selected,
  });
}