import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
// import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
// import '../../models/inventory/SearchCategory.dart';
import '../../models/inventory/bev_model.dart';
// import '../../models/inventory/bevmodel.dart';
// import '../../repositories/beverage_inventory_repository.dart';
import '../../models/inventory/search_category.dart';
import '../../repositories/inventory_repository/beverage_iventory_repository.dart';
// import '../widgets/beverage_grid.dart';
// import '../widgets/custom_dropdown_inventory.dart';
// import '../widgets/custom_item_inventory.dart';
import 'beverage_grid.dart';
import 'custom_dropdrown.dart';
import 'custom_item.dart';




class CustomBox extends StatefulWidget {
  final String token;
  const CustomBox({super.key, required this.token});
  @override
  State<CustomBox> createState() => _CustomBoxState();
}

class _CustomBoxState extends State<CustomBox> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedSort = 'Most Popular';

  List<SearchCategory> categories = [];
  bool showCustomCard = false;

  List<Products> allBeverages = [];
  List<Products> filteredBeverages = [];
  late final ProductRepository _repository;
  bool isLoading = false;
  bool _popupShown = false;
  bool _isScanning = false;
  final FocusNode _searchFocusNode = FocusNode();
  bool _barcodeLocked = false;
  bool _isFromBarcode = false;
  int _searchSession = 0;

  // sort
  String _getApiFilter(String sort) {
    switch (sort) {
      case 'Lowest Stock First':
        return 'low_stock';
      case 'Highest Stock First':
        return 'high_stock';
      case 'Out of Stock':
        return 'out_of_stock';
      case 'Alphabetical (A-Z)':
        return 'alphabetical';
      case 'Most Popular':
        return 'most_popular';
      default:
        return '';
    }
  }


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.requestFocus();
    // Initialize repository with token
    _repository = ProductRepository(token: widget.token);
  }

  void _showSortPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sort',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _sortOption(
                        title: 'Lowest Stock First',
                        isSelected: _selectedSort == 'Lowest Stock First',
                        onTap: () => setStateDialog(
                              () => _selectedSort = 'Lowest Stock First',

                        ),
                      ),
                      _sortOption(
                        title: 'Highest Stock First',
                        isSelected: _selectedSort == 'Highest Stock First',
                        onTap: () => setStateDialog(
                              () => _selectedSort = 'Highest Stock First',
                        ),
                      ),
                      _sortOption(
                        title: 'Out of Stock',
                        isSelected: _selectedSort == 'Out of Stock',
                        onTap: () => setStateDialog(
                              () => _selectedSort = 'Out of Stock',
                        ),
                      ),
                      _sortOption(
                        title: 'Alphabetical (A-Z)',
                        isSelected: _selectedSort == 'Alphabetical (A-Z)',
                        onTap: () => setStateDialog(
                              () => _selectedSort = 'Alphabetical (A-Z)',
                        ),
                      ),
                      _sortOption(
                        title: 'Most Popular',
                        isSelected: _selectedSort == 'Most Popular',
                        onTap: () => setStateDialog(
                              () => _selectedSort = 'Most Popular',
                        ),
                      ),

                      const SizedBox(height: 24),

                      GestureDetector(
                        onTap: _applySort,
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4C81F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  void _applySort() {
    print('🟨 Apply button clicked');
    final String apiFilter = _getApiFilter(_selectedSort);

    print('🟩 Selected Sort Label: $_selectedSort');
    print('🟩 Mapped API Filter: $apiFilter');

    Navigator.pop(context);
    print('🚀 Calling API with filter: $apiFilter');

    _fetchProducts(
      filter: apiFilter.isEmpty ? null : apiFilter, session: _searchSession,
    );
  }

  Widget _sortOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF4C81F1) : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4C81F1),
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // 🔥 Cancel debounce
    _debounce?.cancel();

    // 🔥 New search session
    _searchSession++;

    // ✅ HANDLE CLEAR SEARCH
    if (query.isEmpty) {
      setState(() {
        filteredBeverages.clear();
        showCustomCard = false;
        _popupShown = false;
        isLoading = false;
      });

      // 🔥 CLOSE ANY OPEN DIALOG (Manage / AddItem / Custom Item)
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
      }
      return;
    }

    final isNumeric = RegExp(r'^\d+$').hasMatch(query);

    setState(() => showCustomCard = true);

    // 🔒 Prevent partial barcode calls
    if (isNumeric && query.length < 8) return;

    final int session = _searchSession;

    if (isNumeric) {
      _fetchProducts(searchOrSku: query, session: session);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchProducts(searchOrSku: query, session: session);
    });
  }


  // ---------------- FETCH PRODUCTS ----------------
  Future<void> _fetchProducts({
    String? searchOrSku,
    String? filter,
    required int session,
  }) async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final bool isSku =
          searchOrSku != null && RegExp(r'^\d+$').hasMatch(searchOrSku);

      final Model response = await _repository.getProducts(
        search: isSku ? null : searchOrSku,
        sku: isSku ? searchOrSku : null,
        filter: filter,
        categoryId: null,
      );

      // 🔒 IGNORE STALE API RESPONSES
      if (!mounted || session != _searchSession) return;

      setState(() {
        filteredBeverages = response.products;
      });

      // 🔒 Prevent popup after clear
      if (filteredBeverages.isEmpty &&
          !_popupShown &&
          searchOrSku != null &&
          _searchController.text.trim().isNotEmpty) {
        _popupShown = true;
        _showCustomItemAlert(searchOrSku);
      }
    } catch (e) {
      debugPrint('❌ Fetch error: $e');
    } finally {
      if (mounted && session == _searchSession) {
        setState(() => isLoading = false);
      }
    }
  }

  // ================= BARCODE LISTENER =================

  void _onBarcodeScanned(String barcode) async {
    if (_barcodeLocked || barcode.isEmpty) return;

    _barcodeLocked = true;

    debugPrint('📸 BARCODE SCANNED: $barcode');

    // 🚫 Stop text change listener
    _searchController.removeListener(_onSearchChanged);

    setState(() {
      _searchController.text = barcode;
      showCustomCard = true;
      _popupShown = false;
    });

    //  Single API call
    await _fetchProducts( searchOrSku: barcode,
      session: _searchSession,);

    //  Re-attach listener
    _searchController.addListener(_onSearchChanged);

    _barcodeLocked = false;
  }

  // ---------------- CUSTOM ITEM POPUP ----------------
  void _showCustomItemAlert(String scannedCode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double dialogWidth = constraints.maxWidth * 0.35;

                  return Container(
                    width: dialogWidth,
                    padding: const EdgeInsets.all(12),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF84337),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 16),
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment(0.5, 0.5),
                                    radius: 1.5,
                                    colors: [
                                      Color(0xFFFBC2C2),
                                      Colors.white,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/customalert.png',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            )

                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Custom Item Alert',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF373535),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'The scanned or searched item "$scannedCode" does not exist.\n'
                              'You can add it as a custom item.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFA19A9A),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _onAddItem();
                          },
                          child: Container(
                            width: dialogWidth * 0.8,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4C81F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Add Custom Item',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    });
  }

  void _onAddItem() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        token: widget.token,
        onItemAdded: (Products product) async {
          Navigator.pop(context);

          if (product.sku != null && product.sku!.isNotEmpty) {
            _searchController.text = product.sku!;
          }
        },
      ),
    );
  }


  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return BarcodeKeyboardListener(
        bufferDuration: const Duration(milliseconds: 200),
        onBarcodeScanned: _onBarcodeScanned,
        child: Container(
          color: const Color(0xFFE7EDFF),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ---------- HEADER BLOCK ----------
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10 , vertical: 0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/inventory.png',
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Inventory',
                      style: TextStyle(
                        color: Color(0xFFFE6464),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.refresh,
                      size: 18,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 6),
                    const Text(
                      'Update history',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    ElevatedButton.icon(
                      onPressed: _onAddItem,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text("Add New Item"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFE6464),
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              /// ---------- WHITE DIVIDER ----------
              SizedBox(
                height: 10,
                child: Stack(
                  children: [
                    // Horizontal divider
                    Positioned(
                      top: 0, // center the 2px divider vertically in 10px height
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        color: Colors.white,
                      ),
                    ),
                    // Left vertical line
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.white,
                      ),
                    ),
                    // Right vertical line
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // const SizedBox(height: 4),

              /// ---------- SEARCH + ACTION ROW ----------
              SizedBox(
                height: 56,
                child: Stack(
                  children: [
                    // The Row with internal padding
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Search Box
                          SizedBox(
                            width: 300,
                            height: 40,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onSubmitted: (value) async {
                                if (value.trim().isEmpty) return;

                                setState(() {
                                  showCustomCard = true;
                                });

                                await _fetchProducts(searchOrSku: value.trim(),  session: _searchSession,);
                              },
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                isDense: true,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    'assets/search.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                                hintText: "Search by Beverage Name/SKU",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Scan QR Button
                          ElevatedButton.icon(
                            onPressed:() {
                              _searchFocusNode.requestFocus();
                            },
                            icon: Image.asset('assets/scanqr.png', width: 18, height: 18),
                            label: const Text("Scan QR"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7086FD),
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // if (showCustomCard) const SizedBox(width: 12),
                          // if (showCustomCard)  CustomDropdownCard(
                          //   token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3NjgyMDMwNjQsIm5iZiI6MTc2ODIwMzA2NCwiZXhwIjoxNzcwNzk1MDY0LCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.vBVcnan6C9hN-ZDGN1vgpN_MkuT4twI-_WqXGOTgAio',
                          //   baseUrl: 'https://merchantrestaurant.alektasolutions.com',
                          //   onSelected: (category) {
                          //     print('Selected Category: ${category.id} - ${category.name}');
                          //   },
                          // ),
                          // if (showCustomCard) const SizedBox(width: 12),
                          //
                          // /// SORT CIRCLE
                          // if (showCustomCard)
                          //   GestureDetector(
                          //     onTap: _showSortPopup,
                          //     child: Container(
                          //       width: 36,
                          //       height: 36,
                          //       decoration: const BoxDecoration(
                          //         color: Colors.white,
                          //         shape: BoxShape.circle,
                          //         boxShadow: [
                          //           BoxShadow(
                          //             color: Colors.black12,
                          //             blurRadius: 4,
                          //             offset: Offset(0, 2),
                          //           )
                          //         ],
                          //       ),
                          //       child: Padding(
                          //         padding: const EdgeInsets.all(8),
                          //         child: Image.asset(
                          //           'assets/sort.png',
                          //           fit: BoxFit.contain,
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                        ],
                      ),
                    ),

                    // Left vertical line at row edge
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.white,
                      ),
                    ),

                    // Right vertical line at row edge
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // const SizedBox(height: 10),
              /// ---------- WHITE DIVIDER ----------
              SizedBox(
                height: 10, // spacing before/after divider
                child: Stack(
                  children: [
                    // Horizontal divider
                    Positioned(
                      top: 4, // center the 2px divider vertically in 10px height
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        color: Colors.white,
                      ),
                    ),
                    // Left vertical line
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.white,
                      ),
                    ),
                    // Right vertical line
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),


              /// ---------- GRID ----------
              Expanded(
                child: Stack(
                  children: [
                    // Grid container
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2), // padding for vertical lines
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filteredBeverages.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/emptyinventory.png',
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 16),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  "Use the search bar or barcode scanner to view product details and manage inventory.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            : BeverageGrid(beverages: filteredBeverages, token: widget.token)

                    ),

                    // Left vertical line
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.white,
                      ),
                    ),

                    // Right vertical line
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              /// ---------- RIGHT WHITE LINE ----------
              Container(
                width: 2,
                color: Colors.white,
              ),
            ],
          ),
        )
    );
  }

}