import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/inventory/bev_model.dart';
// import '../../models/inventory/bevmodel.dart';
// import '../../repositories/beverage_inventory_repository.dart';
import '../../repositories/inventory_repository/beverage_iventory_repository.dart';
// import '../widgets/beverage_grid.dart';
// import '../widgets/custom_dropdown_inventory.dart';
// import '../widgets/custom_item_inventory.dart';
import 'beverage_grid.dart';
import 'custom_dropdrown.dart';
import 'custom_item.dart';




class CustomBox extends StatefulWidget {
  const CustomBox({super.key});

  @override
  State<CustomBox> createState() => _CustomBoxState();
}

class _CustomBoxState extends State<CustomBox> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool showCustomCard = false;

  List<Products> allBeverages = [];
  List<Products> filteredBeverages = [];
  final ProductRepository _repository = ProductRepository();
  bool isLoading = false;
  bool _popupShown = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  void _onSearchChanged() {
    final query = _searchController.text.trim();

    setState(() {
      showCustomCard = query.isNotEmpty;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.isEmpty) {
        setState(() {
          filteredBeverages.clear();
        });
        return;
      }

      await _fetchProducts(searchOrSku: query);
    });
  }
  // ---------------- FETCH PRODUCTS ----------------
  Future<void> _fetchProducts({required String searchOrSku}) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final bool isSku = RegExp(r'^\d+$').hasMatch(searchOrSku);

      final Model response = await _repository.getProducts(
        search: isSku ? null : searchOrSku,
        sku: isSku ? searchOrSku : null,
        filter: 'Most Popular',
        categoryId: 177,
      );

      if (!mounted) return;

      setState(() {
        filteredBeverages = response.products ?? [];
      });

      // ✅ SHOW CUSTOM ITEM POPUP AFTER API RESPONSE
      if (filteredBeverages.isEmpty && !_popupShown) {
        _popupShown = true;
        _showCustomItemAlert(searchOrSku);
      }
    } catch (e) {
      debugPrint('❌ Fetch error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  Future<void> scanBarcode() async {
    try {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: SizedBox(
            width: 300,
            height: 400,
            child: MobileScanner(
              onDetect: (capture) async {
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;

                final String? code = barcodes.first.displayValue;
                if (code != null && code.isNotEmpty) {
                  _searchController.text = code;
                  // await _fetchProducts(searchOrSku: code);
                  Navigator.pop(context);

                  if (filteredBeverages.isEmpty) {
                    _showCustomItemAlert(code);
                  }
                }
              },
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan barcode: $e')),
      );
    }
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
                                      Colors.white
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
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
                          'The scanned item "$scannedCode" does not exist.\n'
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
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7EDFF),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.arrow_back, color: Colors.black87),
                    SizedBox(width: 8),
                    Text("Inventory",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset('assets/search.png', width: 20, height: 20),
                    ),
                    prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                    hintText: "Search by Beverage Name/SKU",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: scanBarcode,
                icon: Image.asset('assets/scanqr.png', width: 18, height: 18),
                label: const Text("Scan QR"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7086FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _onAddItem,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text("Add Item"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE6464),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 36, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (showCustomCard) const SizedBox(width: 12),
              if (showCustomCard) const CustomDropdownCard(),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBeverages.isEmpty
                ? const Center(child: Text(" "))
                : BeverageGrid(beverages: filteredBeverages),
          ),
        ],
      ),
    );
  }
}