// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:restaurant_captain_app/features/home_screen/order_menu/widgets/category_tabs.dart';
// import 'package:restaurant_captain_app/features/home_screen/order_menu/widgets/product_list_view.dart';
//
// import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
// import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
// import '../../../constants/color_constants.dart';
// import '../cart_screen.dart';
// import '../create_order/create_order_data_layer/create_order_remote_data_source.dart';
// import 'bloc/category_bloc/category_bloc.dart';
// import 'bloc/category_bloc/category_event.dart';
// import 'bloc/category_bloc/category_state.dart';
// import 'entities/category_entity.dart';
// import 'entities/product_entity.dart';
// import 'widgets/product_card.dart' show isNonVegProduct;
//
// class CartItem {
//   final ProductEntity product;
//   final List<Map<String, dynamic>> addOns;
//   int quantity;
//
//   CartItem({required this.product, this.addOns = const [], this.quantity = 1});
//
//   String get key => '${product.id}_${addOns.map((a) => a['name']).join(',')}';
//
//   double get unitPrice =>
//       (double.tryParse(product.price ?? '0') ?? 0) +
//           addOns.fold<double>(0, (sum, a) => sum + (a['price'] as double));
//
//   double get totalPrice => unitPrice * quantity;
// }
//
// class OrderMenuScreen extends StatefulWidget {
//   final int orderId;
//   final String tableName;
//   final String orderType;
//   final int restaurantId;
//   final int zoneId;
//
//   const OrderMenuScreen({
//     Key? key,
//     required this.orderId,
//     required this.tableName,
//     required this.orderType,
//     required this.restaurantId,
//     required this.zoneId,
//   }) : super(key: key);
//
//   @override
//   State<OrderMenuScreen> createState() => _OrderMenuScreenState();
// }
//
// class _OrderMenuScreenState extends State<OrderMenuScreen> {
//   final Map<String, CartItem> _cartItems = {};
//   bool _isCancellingOrder = false;
//
//   final CreateOrderRemoteDataSource _orderDataSource =
//   CreateOrderRemoteDataSourceImpl();
//
//   bool _vegOnly = false;
//   bool _nonVegOnly = false;
//   String? _language;
//
//   // NEW: which subcategory chip is selected ("All" -> null).
//   int? _selectedSubcategoryId;
//   // Tracks the last category we built chips for, so we can reset filters
//   // whenever the user switches top-level category tabs.
//   int? _lastCategoryIdForFilters;
//
//   final TextEditingController _searchController = TextEditingController();
//
//   final List<Map<String, dynamic>> _demoAddOns = const [
//     {'name': 'Extra Ghee', 'price': 1.0},
//     {'name': 'Extra Karam Podi', 'price': 1.0},
//     {'name': 'Extra chutney', 'price': 1.0},
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     context.read<CategoryBloc>().add(LoadCategories());
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//
//   void _addToCart(ProductEntity product) {
//     setState(() {
//       final key = '${product.id}_';
//       final existing = _cartItems[key];
//       if (existing != null) {
//         existing.quantity++;
//       } else {
//         _cartItems[key] = CartItem(product: product);
//       }
//     });
//   }
//
//   void _removeFromCart(ProductEntity product) {
//     setState(() {
//       final key = '${product.id}_';
//       final existing = _cartItems[key];
//       if (existing == null) return;
//       if (existing.quantity <= 1) {
//         _cartItems.remove(key);
//       } else {
//         existing.quantity--;
//       }
//     });
//   }
//
//   void _addVariantToCart(
//       ProductEntity product,
//       int quantity,
//       List<Map<String, dynamic>> selectedAddOns,
//       ) {
//     setState(() {
//       final item = CartItem(product: product, addOns: selectedAddOns, quantity: quantity);
//       final existing = _cartItems[item.key];
//       if (existing != null) {
//         existing.quantity += quantity;
//       } else {
//         _cartItems[item.key] = item;
//       }
//     });
//
//     if (selectedAddOns.isNotEmpty) {
//       debugPrint(
//         '[CART] Added "${product.name}" x$quantity with add-ons: '
//             '${selectedAddOns.map((a) => a['name']).join(', ')}',
//       );
//     } else {
//       debugPrint('[CART] Added "${product.name}" x$quantity (no add-ons)');
//     }
//   }
//
//   // ---------------------------------------------------------------------
//   // NEW: passed down to CartScreen so that +/- taps there update this
//   // screen's cart map (and therefore the bottom cart bar / product qty
//   // badges) immediately, without waiting for the screen to be popped.
//   // ---------------------------------------------------------------------
//   void _incrementCartItem(CartItem item) {
//     setState(() => item.quantity++);
//   }
//
//   void _decrementCartItem(CartItem item) {
//     setState(() {
//       if (item.quantity <= 1) {
//         _cartItems.remove(item.key);
//       } else {
//         item.quantity--;
//       }
//     });
//   }
//
//   // Called by CartScreen once a KOT print succeeds, so the cart badge /
//   // bottom bar totals reset back to zero.
//   void _clearCart() {
//     setState(() => _cartItems.clear());
//   }
//
//   Map<int, int> get _cartQuantitiesByProductId {
//     final map = <int, int>{};
//     for (final item in _cartItems.values) {
//       map[item.product.id] = (map[item.product.id] ?? 0) + item.quantity;
//     }
//     return map;
//   }
//
//   int get _totalItems => _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
//
//   double get _totalPrice => _cartItems.values.fold(0.0, (sum, item) => sum + item.totalPrice);
//   Future<void> _cancelOrder() async {
//     setState(() => _isCancellingOrder = true);
//
//     try {
//       // 1. Get stored credentials
//       final merchantStorage = context.read<MerchantLocalStorage>();
//       final captainStorage = context.read<CaptainLocalStorage>();
//
//       final baseUrl = await merchantStorage.getStoreBaseUrl();
//       if (baseUrl == null || baseUrl.isEmpty) {
//         throw Exception('Store base URL not found. Please login again.');
//       }
//
//       final captainData = await captainStorage.getCaptainData();
//       final token = captainData?.data?.token;
//       if (token == null || token.isEmpty) {
//         throw Exception('Captain token not found. Please login again.');
//       }
//
//       // 2. Call the API with all required parameters
//       final result = await _orderDataSource.cancelOrder(
//         baseUrl: baseUrl,
//         token: token,
//         parentOrderId: widget.orderId,
//         restaurantId: widget.restaurantId,
//         zoneId: widget.zoneId,
//       );
//
//       if (!mounted) return;
//
//       // Success
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Order cancelled successfully')),
//       );
//
//       // Navigate back to table management screen
//       Navigator.of(context).popUntil((route) => route.isFirst);
//
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to cancel order: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _isCancellingOrder = false);
//       }
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         elevation: 0.5,
//         centerTitle: true,
//         leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
//         title: const Text('Create Order', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
//       ),
//       body: Column(
//         children: [
//           _buildOrderInfoRow(),
//           _buildSearchBar(),
//           _buildCategoriesLabelRow(),
//           BlocBuilder<CategoryBloc, CategoryState>(
//             builder: (context, state) {
//               if (state is CategoryLoaded) {
//                 return CategoryTabs(
//                   categories: state.categories,
//                   selectedId: state.selectedCategoryId,
//                   onTabSelected: (id) {
//                     context.read<CategoryBloc>().add(SelectCategory(categoryId: id));
//                   },
//                 );
//               }
//               return const SizedBox.shrink();
//             },
//           ),
//
//           BlocBuilder<CategoryBloc, CategoryState>(
//             builder: (context, state) {
//               if (state is CategoryLoaded) {
//                 final selected = state.categories.where((c) => c.id == state.selectedCategoryId).toList();
//                 final title = selected.isNotEmpty ? selected.first.name : '';
//                 final languages = state.availableLanguages;
//
//                 if (_lastCategoryIdForFilters != state.selectedCategoryId) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     if (!mounted) return;
//                     setState(() {
//                       _lastCategoryIdForFilters = state.selectedCategoryId;
//                       _selectedSubcategoryId = null;
//                       _language = languages.isNotEmpty ? languages.first : null;
//                     });
//                   });
//                 } else if (languages.isNotEmpty &&
//                     (_language == null || !languages.contains(_language))) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     if (mounted) setState(() => _language = languages.first);
//                   });
//                 }
//
//                 return _buildCategoryHeaderBlock(title, state.subcategories, languages);
//               }
//               return const SizedBox.shrink();
//             },
//           ),
//
//           Expanded(
//             child: BlocBuilder<CategoryBloc, CategoryState>(
//               builder: (context, state) {
//                 if (state is CategoryLoading) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (state is CategoryLoaded) {
//                   return ProductListView(
//                     subcategories: state.subcategories,
//                     directProducts: state.directProducts,
//                     subcategoryProducts: state.subcategoryProducts,
//                     miniSubcategoriesMap: state.miniSubcategoriesMap,
//                     cartQuantitiesByProductId: _cartQuantitiesByProductId,
//                     selectedLanguage: _language,
//                     selectedSubcategoryId: _selectedSubcategoryId,
//                     vegOnly: _vegOnly,
//                     nonVegOnly: _nonVegOnly,
//                     onAdd: _addToCart,
//                     onRemove: _removeFromCart,
//                     onVariantTap: _openVariantSheet,
//                   );
//                 } else if (state is CategoryError) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(state.message),
//                         ElevatedButton(
//                           onPressed: () => context.read<CategoryBloc>().add(LoadCategories()),
//                           child: const Text('Retry'),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//           ),
//           _buildCartBar(),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------------
//   // Order id / table / dine-in / cancel — ALL the same chip style, one
//   // scrollable row, no visual difference between them.
//   // ---------------------------------------------------------------------
//   // ---------------------------------------------------------------------
//   // Order id / table / dine-in as ONE single card with thin dividers
//   // between the values, + Cancel Order as its own button.
//   // ---------------------------------------------------------------------
//   Widget _buildOrderInfoRow() {
//     return Container(
//       width: double.infinity,
//       color: Colors.white,
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
//       child: Row(
//         children: [
//           Expanded(child: _orderInfoCard()),
//           const SizedBox(width: 8),
//           _cancelOrderChip(),
//         ],
//       ),
//     );
//   }
//
//   Widget _orderInfoCard() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFEAF3FF),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: const Color(0xFFB9D9FF)),
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             Text(
//               'Order Id #${widget.orderId}',
//               style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
//             ),
//             _infoDivider(),
//             Text(
//               'Table No ${widget.tableName}',
//               style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
//             ),
//             _infoDivider(),
//             Text(
//               widget.orderType,
//               style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _infoDivider() {
//     return Container(
//       height: 14,
//       width: 1,
//       margin: const EdgeInsets.symmetric(horizontal: 10),
//       color: const Color(0xFFB9D9FF),
//     );
//   }
//
//   Widget _cancelOrderChip() {
//     return GestureDetector(
//       onTap: () => _showCancelDialog(context),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.red),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: const [
//             Icon(Icons.delete_outline, size: 14, color: Colors.red),
//             SizedBox(width: 4),
//             Text(
//               'Cancel Order',
//               style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               softWrap: false,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           hintText: 'Search...',
//           prefixIcon: const Icon(Icons.search, color: Colors.grey),
//           filled: true,
//           fillColor: const Color(0xFFF2F2F2),
//           contentPadding: const EdgeInsets.symmetric(vertical: 0),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCategoriesLabelRow() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//           Row(
//             children: [
//               _dietChip(
//                 label: 'Veg',
//                 color: Colors.green,
//                 selected: _vegOnly,
//                 onTap: () => setState(() {
//                   _vegOnly = !_vegOnly;
//                   if (_vegOnly) _nonVegOnly = false;
//                 }),
//               ),
//               const SizedBox(width: 8),
//               _dietChip(
//                 label: 'Non Veg',
//                 color: Colors.red,
//                 selected: _nonVegOnly,
//                 onTap: () => setState(() {
//                   _nonVegOnly = !_nonVegOnly;
//                   if (_nonVegOnly) _vegOnly = false;
//                 }),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _dietChip({
//     required String label,
//     required Color color,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         decoration: BoxDecoration(
//           color: selected ? color.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: color),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.circle, size: 8, color: color),
//             const SizedBox(width: 4),
//             Text(label, style: TextStyle(fontSize: 11, color: color)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------------
//   // NEW: "Breakfast" title + [All | Idly | Dosa | Pongal | More] +
//   // [Indian | English] — matches the target image layout.
//   // ---------------------------------------------------------------------
//   Widget _buildCategoryHeaderBlock(
//       String title,
//       List<SubcategoryEntity> subcategories,
//       List<String> languages,
//       ) {
//     return Container(
//       color: const Color(0xFFF5F5F5),
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//           if (subcategories.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             _buildSubcategoryChipsRow(subcategories),
//           ],
//           if (languages.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             Row(children: languages.map(_languageOption).toList()),
//           ],
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }
//
//   static const int _maxVisibleSubcategoryChips = 3;
//
// // ---------------------------------------------------------------------
//   // Subcategory chips row — ALL chips in one row, horizontally scrollable.
//   // No more "More" button / bottom sheet — user just scrolls sideways.
//   // ---------------------------------------------------------------------
//
//   Widget _buildSubcategoryChipsRow(List<SubcategoryEntity> subcategories) {
//     // Drop any subcategory with no real name so it doesn't render an empty chip.
//     final validSubs = subcategories.where((s) => s.name.trim().isNotEmpty).toList();
//
//     final hasOverflow = validSubs.length > _maxVisibleSubcategoryChips;
//     final visible = hasOverflow
//         ? validSubs.sublist(0, _maxVisibleSubcategoryChips)
//         : validSubs;
//     final overflow = hasOverflow
//         ? validSubs.sublist(_maxVisibleSubcategoryChips)
//         : const <SubcategoryEntity>[];
//
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             _subcategoryChip(
//               label: 'All',
//               selected: _selectedSubcategoryId == null,
//               onTap: () => setState(() => _selectedSubcategoryId = null),
//             ),
//             for (final sub in visible) ...[
//               const SizedBox(width: 8),
//               _subcategoryChip(
//                 label: sub.name,
//                 selected: _selectedSubcategoryId == sub.id,
//                 onTap: () => setState(() => _selectedSubcategoryId = sub.id),
//               ),
//             ],
//             if (overflow.isNotEmpty) ...[
//               const SizedBox(width: 8),
//               _moreChip(overflow),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _subcategoryChip({
//     required String label,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: selected ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(color: selected ? ColorConstants.primaryColor : Colors.grey.shade300),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: selected ? ColorConstants.primaryColor : Colors.black87,
//             fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
//           ),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           softWrap: false,
//         ),
//       ),
//     );
//   }
//
//   Widget _moreChip(List<SubcategoryEntity> overflow) {
//     final isOverflowSelected = _selectedSubcategoryId != null &&
//         overflow.any((s) => s.id == _selectedSubcategoryId);
//
//     return GestureDetector(
//       onTap: () => _showMoreSubcategoriesSheet(overflow),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//         decoration: BoxDecoration(
//           color: isOverflowSelected ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(
//             color: isOverflowSelected ? ColorConstants.primaryColor : Colors.grey.shade300,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'More',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: isOverflowSelected ? ColorConstants.primaryColor : Colors.black87,
//                 fontWeight: isOverflowSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//             Icon(
//               Icons.keyboard_arrow_down,
//               size: 14,
//               color: isOverflowSelected ? ColorConstants.primaryColor : Colors.black54,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showMoreSubcategoriesSheet(List<SubcategoryEntity> overflow) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (sheetContext) {
//         return SafeArea(
//           child: ConstrainedBox(
//             // Keeps the sheet from growing full-screen with few items,
//             // but scrolls if there are many.
//             constraints: BoxConstraints(
//               maxHeight: MediaQuery.of(context).size.height * 0.5,
//             ),
//             child: ListView(
//               shrinkWrap: true,
//               children: overflow
//                   .map((sub) => ListTile(
//                 title: Text(sub.name),
//                 trailing: _selectedSubcategoryId == sub.id
//                     ? const Icon(Icons.check, color: ColorConstants.primaryColor)
//                     : null,
//                 onTap: () {
//                   setState(() => _selectedSubcategoryId = sub.id);
//                   Navigator.pop(sheetContext);
//                 },
//               ))
//                   .toList(),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
//   Widget _languageOption(String label) {
//     final selected = _language == label;
//     return Padding(
//       padding: const EdgeInsets.only(right: 8),
//       child: GestureDetector(
//         onTap: () => setState(() => _language = label),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//           decoration: BoxDecoration(
//             color: selected ? ColorConstants.primaryColor : Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: ColorConstants.primaryColor),
//           ),
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: selected ? Colors.white : ColorConstants.primaryColor,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCartBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 '$_totalItems Items',
//                 style: TextStyle(color: Colors.grey[600], fontSize: 12),
//               ),
//               Text(
//                 '\$${_totalPrice.toStringAsFixed(2)}',
//                 style: const TextStyle(
//                   color: ColorConstants.primaryColor,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                 ),
//               ),
//             ],
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => CartScreen(
//                     cartItems: _cartItems.values.toList(),
//                     orderId: widget.orderId,
//                     tableName: widget.tableName,
//                     orderType: widget.orderType,
//                     restaurantId: widget.restaurantId,
//                     zoneId: widget.zoneId,
//                     onIncrement: _incrementCartItem,
//                     onDecrement: _decrementCartItem,
//                     onClearCart: _clearCart,
//                   ),
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: ColorConstants.primaryColor,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             icon: const Icon(Icons.shopping_cart, size: 18),
//             label: const Text('View Cart'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showCancelDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Cancel Order?'),
//         content: const Text('Are you sure you want to cancel this order?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('No'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context); // close dialog
//               _cancelOrder();         // call the actual cancellation
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Yes, Cancel'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------------
//   // Variant bottom sheet — UNCHANGED
//   // ---------------------------------------------------------------------
//   void _openVariantSheet(ProductEntity product) {
//     final basePrice = double.tryParse(product.price ?? '0') ?? 0;
//     int quantity = 1;
//     final selected = <Map<String, dynamic>>{};
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
//       builder: (sheetContext) {
//         return StatefulBuilder(
//           builder: (context, setSheetState) {
//             final addOnsTotal = selected.fold<double>(0, (sum, a) => sum + (a['price'] as double));
//             final total = (basePrice + addOnsTotal) * quantity;
//
//             return Padding(
//               padding: EdgeInsets.only(
//                 left: 20,
//                 right: 20,
//                 top: 20,
//                 bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '\$${(basePrice + addOnsTotal).toStringAsFixed(2)}',
//                         style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColorConstants.primaryColor),
//                       ),
//                       Row(
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.remove_circle_outline),
//                             onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null,
//                           ),
//                           Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                           IconButton(
//                             icon: const Icon(Icons.add_circle, color: ColorConstants.primaryColor),
//                             onPressed: () => setSheetState(() => quantity++),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   const Text('Add Ons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//                   const Divider(),
//                   ..._demoAddOns.map((addOn) {
//                     final isChecked = selected.any((a) => a['name'] == addOn['name']);
//                     return CheckboxListTile(
//                       contentPadding: EdgeInsets.zero,
//                       controlAffinity: ListTileControlAffinity.leading,
//                       value: isChecked,
//                       title: Text(addOn['name'] as String),
//                       secondary: Text('+ \$${(addOn['price'] as double).toStringAsFixed(2)}'),
//                       onChanged: (checked) {
//                         setSheetState(() {
//                           if (checked == true) {
//                             selected.add(addOn);
//                           } else {
//                             selected.removeWhere((a) => a['name'] == addOn['name']);
//                           }
//                         });
//                       },
//                     );
//                   }),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         _addVariantToCart(product, quantity, selected.toList());
//                         Navigator.pop(sheetContext);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: ColorConstants.primaryColor,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
//                           Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }



import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_captain_app/features/home_screen/order_menu/widgets/category_tabs.dart';
import 'package:restaurant_captain_app/features/home_screen/order_menu/widgets/product_list_view.dart';

import '../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../../../constants/color_constants.dart';
import '../../search_products/search_screen.dart';
import '../cart_screen.dart';
import '../create_order/create_order_data_layer/create_order_remote_data_source.dart';
import 'bloc/category_bloc/category_bloc.dart';
import 'bloc/category_bloc/category_event.dart';
import 'bloc/category_bloc/category_state.dart';
import 'entities/category_entity.dart';
import 'entities/product_entity.dart';
import 'widgets/product_card.dart' show isNonVegProduct;

class CartItem {
  final ProductEntity product;
  final List<Map<String, dynamic>> addOns;
  int quantity;

  CartItem({required this.product, this.addOns = const [], this.quantity = 1});

  String get key => '${product.id}_${addOns.map((a) => a['name']).join(',')}';

  double get unitPrice =>
      (double.tryParse(product.price ?? '0') ?? 0) +
          addOns.fold<double>(0, (sum, a) => sum + (a['price'] as double));

  double get totalPrice => unitPrice * quantity;
}

class OrderMenuScreen extends StatefulWidget {
  final int orderId;
  final String tableName;
  final String orderType;
  final int restaurantId;
  final int zoneId;

  const OrderMenuScreen({
    Key? key,
    required this.orderId,
    required this.tableName,
    required this.orderType,
    required this.restaurantId,
    required this.zoneId,
  }) : super(key: key);

  @override
  State<OrderMenuScreen> createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {
  final Map<String, CartItem> _cartItems = {};
  bool _isCancellingOrder = false;

  final CreateOrderRemoteDataSource _orderDataSource =
  CreateOrderRemoteDataSourceImpl();

  bool _vegOnly = false;
  bool _nonVegOnly = false;
  String? _language;

  int? _selectedSubcategoryId;
  int? _lastCategoryIdForFilters;
  bool _showAllSubcategories = false;

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _demoAddOns = const [
    {'name': 'Extra Ghee', 'price': 1.0},
    {'name': 'Extra Karam Podi', 'price': 1.0},
    {'name': 'Extra chutney', 'price': 1.0},
  ];

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  void _addToCart(ProductEntity product) {
    setState(() {
      final key = '${product.id}_';
      final existing = _cartItems[key];
      if (existing != null) {
        existing.quantity++;
      } else {
        _cartItems[key] = CartItem(product: product);
      }
    });
  }

  void _removeFromCart(ProductEntity product) {
    setState(() {
      final key = '${product.id}_';
      final existing = _cartItems[key];
      if (existing == null) return;
      if (existing.quantity <= 1) {
        _cartItems.remove(key);
      } else {
        existing.quantity--;
      }
    });
  }

  void _addVariantToCart(
      ProductEntity product,
      int quantity,
      List<Map<String, dynamic>> selectedAddOns,
      ) {
    setState(() {
      final item = CartItem(product: product, addOns: selectedAddOns, quantity: quantity);
      final existing = _cartItems[item.key];
      if (existing != null) {
        existing.quantity += quantity;
      } else {
        _cartItems[item.key] = item;
      }
    });

    if (selectedAddOns.isNotEmpty) {
      debugPrint(
        '[CART] Added "${product.name}" x$quantity with add-ons: '
            '${selectedAddOns.map((a) => a['name']).join(', ')}',
      );
    } else {
      debugPrint('[CART] Added "${product.name}" x$quantity (no add-ons)');
    }
  }

  void _incrementCartItem(CartItem item) {
    setState(() => item.quantity++);
  }

  void _decrementCartItem(CartItem item) {
    setState(() {
      if (item.quantity <= 1) {
        _cartItems.remove(item.key);
      } else {
        item.quantity--;
      }
    });
  }

  void _clearCart() {
    setState(() => _cartItems.clear());
  }

  Map<int, int> get _cartQuantitiesByProductId {
    final map = <int, int>{};
    for (final item in _cartItems.values) {
      map[item.product.id] = (map[item.product.id] ?? 0) + item.quantity;
    }
    return map;
  }

  int get _totalItems => _cartItems.values.fold(0, (sum, item) => sum + item.quantity);

  double get _totalPrice => _cartItems.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  Future<void> _cancelOrder() async {
    setState(() => _isCancellingOrder = true);

    try {
      final merchantStorage = context.read<MerchantLocalStorage>();
      final captainStorage = context.read<CaptainLocalStorage>();

      final baseUrl = await merchantStorage.getStoreBaseUrl();
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception('Store base URL not found. Please login again.');
      }

      final captainData = await captainStorage.getCaptainData();
      final token = captainData?.data?.token;
      if (token == null || token.isEmpty) {
        throw Exception('Captain token not found. Please login again.');
      }

      final result = await _orderDataSource.cancelOrder(
        baseUrl: baseUrl,
        token: token,
        parentOrderId: widget.orderId,
        restaurantId: widget.restaurantId,
        zoneId: widget.zoneId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully')),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel order: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancellingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios), // ✅ iOS style back icon
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Order', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _buildOrderInfoRow(),
          _buildSearchBar(),
          _buildCategoriesLabelRow(),
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

          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              if (state is CategoryLoaded) {
                final selected = state.categories.where((c) => c.id == state.selectedCategoryId).toList();
                final title = selected.isNotEmpty ? selected.first.name : '';
                final languages = state.availableLanguages;

                if (_lastCategoryIdForFilters != state.selectedCategoryId) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _lastCategoryIdForFilters = state.selectedCategoryId;
                      _selectedSubcategoryId = null;
                      _language = languages.isNotEmpty ? languages.first : null;
                    });
                  });
                } else if (languages.isNotEmpty &&
                    (_language == null || !languages.contains(_language))) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _language = languages.first);
                  });
                }

                return _buildCategoryHeaderBlock(title, state.subcategories, languages);
              }
              return const SizedBox.shrink();
            },
          ),

          Expanded(
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading) {
                  // ✅ iOS style loading indicator
                  return const Center(
                    child: CupertinoActivityIndicator(radius: 14),
                  );
                } else if (state is CategoryLoaded) {
                  return ProductListView(
                    subcategories: state.subcategories,
                    directProducts: state.directProducts,
                    subcategoryProducts: state.subcategoryProducts,
                    miniSubcategoriesMap: state.miniSubcategoriesMap,
                    cartQuantitiesByProductId: _cartQuantitiesByProductId,
                    selectedLanguage: _language,
                    selectedSubcategoryId: _selectedSubcategoryId,
                    vegOnly: _vegOnly,
                    nonVegOnly: _nonVegOnly,
                    onAdd: _addToCart,
                    onRemove: _removeFromCart,
                    onVariantTap: _openVariantSheet,
                    onVisibleSubcategoryChanged: (subId) {
                      // Only update if the user is not manually selecting via tap
                      // and if the new subcategory is different
                      if (_selectedSubcategoryId != subId) {
                        setState(() {
                          _selectedSubcategoryId = subId;
                        });
                      }
                    },
                  );
                } else if (state is CategoryError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        ElevatedButton(
                          onPressed: () => context.read<CategoryBloc>().add(LoadCategories()),
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
          _buildCartBar(),
        ],
      ),
    );
  }


  Widget _buildOrderInfoRow() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(child: _orderInfoCard()),
          const SizedBox(width: 8),
          _cancelOrderChip(),
        ],
      ),
    );
  }

  Widget _orderInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB9D9FF)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Order Id #${widget.orderId}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
            ),
            _infoDivider(),
            Text(
              'Table No ${widget.tableName}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
            ),
            _infoDivider(),
            Text(
              widget.orderType,
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E6FCE), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoDivider() {
    return Container(
      height: 14,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFB9D9FF),
    );
  }

  Widget _cancelOrderChip() {
    return GestureDetector(
      onTap: () => _showCancelDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.delete_outline, size: 14, color: Colors.red),
            SizedBox(width: 4),
            Text(
              'Cancel Order',
              style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchScreen(
              onAddToCart: _addToCart,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Icon(Icons.search, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                'Search for Category/item',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesLabelRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Row(
            children: [
              _dietChip(
                label: 'Veg',
                color: Colors.green,
                selected: _vegOnly,
                onTap: () => setState(() {
                  _vegOnly = !_vegOnly;
                  if (_vegOnly) _nonVegOnly = false;
                }),
              ),
              const SizedBox(width: 8),
              _dietChip(
                label: 'Non Veg',
                color: Colors.red,
                selected: _nonVegOnly,
                onTap: () => setState(() {
                  _nonVegOnly = !_nonVegOnly;
                  if (_nonVegOnly) _vegOnly = false;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dietChip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeaderBlock(
      String title,
      List<SubcategoryEntity> subcategories,
      List<String> languages,
      ) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (subcategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSubcategoryChipsRow(subcategories),
          ],
          if (languages.isNotEmpty) ...[
            const SizedBox(height: 10),
            // 👇 Make languages horizontally scrollable
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: languages.map(_languageOption).toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static const double _maxVisibleSubcategoryChips = 3.5;

// ---------------------------------------------------------------------
  // Subcategory chips row — ALL chips in one row, horizontally scrollable.
  // No more "More" button / bottom sheet — user just scrolls sideways.
  // ---------------------------------------------------------------------

// ---------------------------------------------------------------------
// Subcategory chips row — with "More" / "Less" toggling
// ---------------------------------------------------------------------
  Widget _buildSubcategoryChipsRow(List<SubcategoryEntity> subcategories) {
    final validSubs = subcategories.where((s) => s.name.trim().isNotEmpty).toList();
    final hasOverflow = validSubs.length > _maxVisibleSubcategoryChips;

    // Decide which chips to show
    final List<SubcategoryEntity> displayedSubs;
    bool showMoreChip = false;
    bool showLessChip = false;

    if (_showAllSubcategories) {
      displayedSubs = validSubs;
      showLessChip = hasOverflow;
    } else {
      displayedSubs = hasOverflow
          ? validSubs.sublist(0, 4)
          : validSubs;
      showMoreChip = hasOverflow;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "All" chip always visible
            _subcategoryChip(
              label: 'All',
              selected: _selectedSubcategoryId == null,
              onTap: () {
                setState(() {
                  _selectedSubcategoryId = null;
                  _showAllSubcategories = false;
                });
              },
            ),
            // Subcategory chips
            for (final sub in displayedSubs) ...[
              const SizedBox(width: 8),
              _subcategoryChip(
                label: sub.name,
                selected: _selectedSubcategoryId == sub.id,
                onTap: () => setState(() => _selectedSubcategoryId = sub.id),
              ),
            ],
            // "More" or "Less" chip
            if (showMoreChip) ...[
              const SizedBox(width: 8),
              _toggleChip(
                label: 'More',
                isActive: false,
                onTap: () {
                  setState(() {
                    _showAllSubcategories = true;
                  });
                },
              ),
            ],
            if (showLessChip) ...[
              const SizedBox(width: 8),
              _toggleChip(
                label: 'Less',
                isActive: true,
                onTap: () {
                  setState(() {
                    _showAllSubcategories = false;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? ColorConstants.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? ColorConstants.primaryColor : Colors.black87,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_up,
                size: 14,
                color: ColorConstants.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _subcategoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? ColorConstants.primaryColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? ColorConstants.primaryColor : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
  }

  Widget _moreChip(List<SubcategoryEntity> overflow) {
    final isOverflowSelected = _selectedSubcategoryId != null &&
        overflow.any((s) => s.id == _selectedSubcategoryId);

    return GestureDetector(
      onTap: () => _showMoreSubcategoriesSheet(overflow),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOverflowSelected ? ColorConstants.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isOverflowSelected ? ColorConstants.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'More',
              style: TextStyle(
                fontSize: 12,
                color: isOverflowSelected ? ColorConstants.primaryColor : Colors.black87,
                fontWeight: isOverflowSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isOverflowSelected ? ColorConstants.primaryColor : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreSubcategoriesSheet(List<SubcategoryEntity> overflow) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView(
              shrinkWrap: true,
              children: overflow
                  .map((sub) => ListTile(
                title: Text(sub.name),
                trailing: _selectedSubcategoryId == sub.id
                    ? const Icon(Icons.check, color: ColorConstants.primaryColor)
                    : null,
                onTap: () {
                  setState(() => _selectedSubcategoryId = sub.id);
                  Navigator.pop(sheetContext);
                },
              ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }


  Widget _languageOption(String label) {
    final selected = _language == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _language = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? ColorConstants.primaryColor : Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            border: Border.all(
              color: selected ? ColorConstants.primaryColor : ColorConstants.primaryColor,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : ColorConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_totalItems Items',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                '\$${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: ColorConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(
                    cartItems: _cartItems.values.toList(),
                    orderId: widget.orderId,
                    tableName: widget.tableName,
                    orderType: widget.orderType,
                    restaurantId: widget.restaurantId,
                    zoneId: widget.zoneId,
                    onIncrement: _incrementCartItem,
                    onDecrement: _decrementCartItem,
                    onClearCart: _clearCart,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: const Text('View Cart'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5), // light pink
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE53935), // red
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Cancel Order?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Message
              const Text(
                'Are you sure you want to cancel this order? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  // Keep Order (outlined)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B00), // orange
                        side: const BorderSide(
                          color: Color(0xFFFF6B00),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Keep Order',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Cancel Order (filled)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelOrder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00), // orange
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel Order',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Variant bottom sheet — UNCHANGED
  // ---------------------------------------------------------------------
  void _openVariantSheet(ProductEntity product) {
    final basePrice = double.tryParse(product.price ?? '0') ?? 0;
    int quantity = 1;
    final selected = <Map<String, dynamic>>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final addOnsTotal = selected.fold<double>(0, (sum, a) => sum + (a['price'] as double));
            final total = (basePrice + addOnsTotal) * quantity;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${(basePrice + addOnsTotal).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColorConstants.primaryColor),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null,
                          ),
                          Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: ColorConstants.primaryColor),
                            onPressed: () => setSheetState(() => quantity++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Add Ons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(),
                  ..._demoAddOns.map((addOn) {
                    final isChecked = selected.any((a) => a['name'] == addOn['name']);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: isChecked,
                      title: Text(addOn['name'] as String),
                      secondary: Text('+ \$${(addOn['price'] as double).toStringAsFixed(2)}'),
                      onChanged: (checked) {
                        setSheetState(() {
                          if (checked == true) {
                            selected.add(addOn);
                          } else {
                            selected.removeWhere((a) => a['name'] == addOn['name']);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _addVariantToCart(product, quantity, selected.toList());
                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}