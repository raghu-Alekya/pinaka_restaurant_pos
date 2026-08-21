// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
// import '../../constants/color_constants.dart';
// import 'order_menu/bloc/category_bloc/category_bloc.dart';
// import 'order_menu/bloc/category_bloc/category_event.dart';
// import 'order_menu/bloc/category_bloc/category_state.dart';
// import 'order_menu/entities/product_entity.dart';
// import 'order_menu/widgets/category_tabs.dart';
// import 'order_menu/widgets/product_card.dart';
//
// const Color kPageBg = Color(0xFFF5F5F5);
// const Color kUnavailableBg = Color(0xFFE9E9E9);
//
// class MenuManagementScreen extends StatefulWidget {
//   final int restaurantId;
//
//   const MenuManagementScreen({
//     Key? key,
//     required this.restaurantId,
//   }) : super(key: key);
//
//   @override
//   State<MenuManagementScreen> createState() => _MenuManagementScreenState();
// }
//
// class _MenuManagementScreenState extends State<MenuManagementScreen> {
//   // Product ids that are currently OUT OF STOCK / unavailable.
//   final Set<int> _unavailableIds = {};
//   bool _seededAvailability = false;
//
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//
//   String _captainRole = '';
//
//   @override
//   void initState() {
//     super.initState();
//     final bloc = context.read<CategoryBloc>();
//     // Load ONLY once – never again while this screen is alive
//     if (bloc.state is CategoryInitial) {
//       bloc.add(LoadCategories());
//     }
//     _loadCaptainRole();
//   }
//
//   Future<void> _loadCaptainRole() async {
//     try {
//       final captainStorage = context.read<CaptainLocalStorage>();
//       final captainData = await captainStorage.getCaptainData();
//       setState(() {
//         _captainRole = captainData?.data?.role?.toLowerCase() ?? '';
//       });
//     } catch (_) {
//       setState(() => _captainRole = '');
//     }
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   bool _matchesSearch(String name) {
//     if (_searchQuery.trim().isEmpty) return true;
//     return name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
//   }
//
//   // Reads real availability from ProductEntity (in_stock / isAvailable)
//   bool _isProductAvailable(ProductEntity product) {
//     try {
//       final dynamic p = product;
//
//       // Prefer explicit bool field
//       final dynamic avail = p.isAvailable;
//       if (avail is bool) return avail;
//
//       // Fallback to API string "in_stock": "Yes" / "No"
//       final dynamic stock = p.inStock ?? p.in_stock;
//       if (stock is String) {
//         return stock.toLowerCase() == 'yes' || stock.toLowerCase() == 'true';
//       }
//       if (stock is bool) return stock;
//     } catch (_) {}
//     return true; // default available
//   }
//
//   void _seedAvailabilityOnce(CategoryLoaded state) {
//     if (_seededAvailability) return;
//     _seededAvailability = true;
//
//     // Collect EVERY product once
//     final all = <ProductEntity>[
//       ...state.directProducts,
//       for (final list in state.subcategoryProducts.values) ...list,
//     ];
//
//     for (final p in all) {
//       if (!_isProductAvailable(p)) {
//         _unavailableIds.add(p.id);
//       }
//     }
//   }
//
//   // ── PIN verification ──────────────────────────────────────────────────
//   Future<bool> _verifyPin(String pin) async {
//     // Just require 6 digits — treat any pin as correct (same as before)
//     return pin.length == 6;
//   }
//
//   Future<void> _openUpdatePinDialog() async {
//     final verified = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => _UpdatePinDialog(onVerify: _verifyPin),
//     );
//     if (verified != true) return;
//     if (!mounted) return;
//
//     final result = await Navigator.of(context).push<Set<int>>(
//       MaterialPageRoute(
//         builder: (_) => EditMenuScreen(
//           restaurantId: widget.restaurantId,
//           initialUnavailableIds: Set<int>.from(_unavailableIds),
//         ),
//       ),
//     );
//
//     if (result != null && mounted) {
//       setState(() {
//         _unavailableIds
//           ..clear()
//           ..addAll(result);
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Menu updated successfully')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isCaptain = _captainRole == 'captain';
//     final bool isEditEnabled = !isCaptain; // only non-captain can edit
//
//     return Scaffold(
//       backgroundColor: kPageBg,
//       appBar: AppBar(
//         toolbarHeight: 44,
//         backgroundColor: ColorConstants.backgroundColor,
//         foregroundColor: ColorConstants.textColor,
//         elevation: 0.5,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, size: 16),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Menu Management',
//           style: TextStyle(
//             fontSize: 16,
//             color: ColorConstants.textColor,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: _buildEditIconButton(
//               enabled: isEditEnabled,
//               onTap: isEditEnabled ? _openUpdatePinDialog : null,
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
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
//           Expanded(
//             child: BlocBuilder<CategoryBloc, CategoryState>(
//               builder: (context, state) {
//                 if (state is CategoryLoading) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (state is CategoryLoaded) {
//                   _seedAvailabilityOnce(state);
//                   return ListView(
//                     padding: const EdgeInsets.only(top: 8),
//                     children: [_buildCategoryContent(state)],
//                   );
//                 } else if (state is CategoryError) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(state.message),
//                         const SizedBox(height: 8),
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
//         ],
//       ),
//     );
//   }
//
//   // ── Edit icon ─────────────────────────────────────────────────────────
//   Widget _buildEditIconButton({required bool enabled, VoidCallback? onTap}) {
//     const Color enabledColor = Color(0xFF3B5BA9);
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 34,
//         height: 34,
//         decoration: BoxDecoration(
//           color: ColorConstants.backgroundColor,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: enabled ? enabledColor.withOpacity(0.6) : Colors.grey.shade300,
//           ),
//         ),
//         child: Icon(
//           Icons.edit_outlined,
//           size: 18,
//           color: enabled ? enabledColor : Colors.grey.shade400,
//         ),
//       ),
//     );
//   }
//
//   // ── Search bar ───────────────────────────────────────────────────────
//   Widget _buildSearchBar() {
//     return Container(
//       color: ColorConstants.backgroundColor,
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//       child: Container(
//         height: 40,
//         decoration: BoxDecoration(
//           color: kPageBg,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Row(
//           children: [
//             const SizedBox(width: 12),
//             Icon(Icons.search, color: ColorConstants.hintColor, size: 20),
//             const SizedBox(width: 8),
//             Expanded(
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: (v) => setState(() => _searchQuery = v),
//                 decoration: InputDecoration(
//                   hintText: 'Search...',
//                   hintStyle: TextStyle(color: ColorConstants.hintColor, fontSize: 14),
//                   border: InputBorder.none,
//                   isDense: true,
//                 ),
//               ),
//             ),
//             if (_searchQuery.isNotEmpty)
//               GestureDetector(
//                 onTap: () => setState(() {
//                   _searchController.clear();
//                   _searchQuery = '';
//                 }),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   child: Icon(Icons.close, size: 16, color: ColorConstants.hintColor),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ── "Categories" header + veg / non-veg legend ───────────────────────
//   Widget _buildCategoriesLabelRow() {
//     return Container(
//       color: ColorConstants.backgroundColor,
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             'Categories',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//               color: ColorConstants.textColor,
//             ),
//           ),
//           Row(
//             children: [
//               _legendChip(ColorConstants.successColor, 'Veg'),
//               const SizedBox(width: 10),
//               _legendChip(ColorConstants.errorColor, 'Non Veg'),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _legendChip(Color color, String label) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: color.withOpacity(0.5)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.circle, size: 8, color: color),
//           const SizedBox(width: 4),
//           Text(label, style: TextStyle(fontSize: 11, color: color)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCategoryContent(CategoryLoaded state) {
//     final selected = state.categories
//         .where((c) => c.id == state.selectedCategoryId)
//         .toList();
//     final title = selected.isNotEmpty ? selected.first.name : '';
//
//     // ── Case 1: category has NO subcategories → show all products flat ──
//     if (state.subcategories.isEmpty) {
//       final products = [
//         ...state.directProducts,
//         for (final list in state.subcategoryProducts.values) ...list,
//         for (final miniList in state.miniSubcategoriesMap.values)
//           for (final mini in miniList) ...mini.products,
//       ];
//
//       final unique = <int, ProductEntity>{};
//       for (final p in products) unique[p.id] = p;
//       final filtered = unique.values.where((p) => _matchesSearch(p.name)).toList();
//
//       if (filtered.isEmpty) {
//         return const Padding(
//           padding: EdgeInsets.only(top: 80),
//           child: Center(child: Text('No items found', style: TextStyle(color: Colors.grey))),
//         );
//       }
//
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionHeader(title),
//           _buildProductGrid(filtered),
//           const SizedBox(height: 24),
//         ],
//       );
//     }
//
//     // ── Case 2: category HAS subcategories → group by subcategory / mini ──
//     final List<Widget> sections = [];
//
//     for (final sub in state.subcategories) {
//       // products that belong directly to this subcategory
//       final direct = state.subcategoryProducts[sub.id] ?? [];
//
//       // mini-subcategories of this subcategory
//       final minis = state.miniSubcategoriesMap[sub.id] ?? [];
//
//       // ---------- no mini → just show subcategory + its products ----------
//       if (minis.isEmpty) {
//         final filtered = direct.where((p) => _matchesSearch(p.name)).toList();
//         if (filtered.isEmpty && _searchQuery.isNotEmpty) continue;
//
//         sections.add(_buildSectionHeader(sub.name));
//         if (filtered.isNotEmpty) {
//           sections.add(_buildProductGrid(filtered));
//         } else {
//           sections.add(const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Text('No items', style: TextStyle(color: Colors.grey, fontSize: 13)),
//           ));
//         }
//         sections.add(const SizedBox(height: 12));
//         continue;
//       }
//
//       // ---------- has mini-subcategories ----------
//       sections.add(_buildSectionHeader(sub.name)); // parent subcategory title
//
//       for (final mini in minis) {
//         final filtered = mini.products.where((p) => _matchesSearch(p.name)).toList();
//         if (filtered.isEmpty && _searchQuery.isNotEmpty) continue;
//
//         // mini title (slightly smaller)
//         sections.add(Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
//           child: Text(
//             mini.name,
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//               color: ColorConstants.textColor.withOpacity(0.85),
//             ),
//           ),
//         ));
//
//         if (filtered.isNotEmpty) {
//           sections.add(_buildProductGrid(filtered));
//         } else {
//           sections.add(const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//             child: Text('No items', style: TextStyle(color: Colors.grey, fontSize: 13)),
//           ));
//         }
//         sections.add(const SizedBox(height: 8));
//       }
//       sections.add(const SizedBox(height: 8));
//     }
//
//     if (sections.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.only(top: 80),
//         child: Center(child: Text('No items found', style: TextStyle(color: Colors.grey))),
//       );
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: sections,
//     );
//   }
//
//   Widget _buildSectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: ColorConstants.textColor,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProductGrid(List<ProductEntity> products) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: products.length,
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 10,
//           crossAxisSpacing: 10,
//           mainAxisExtent: 48,
//         ),
//         itemBuilder: (context, index) => _buildReadOnlyItemCell(products[index]),
//       ),
//     );
//   }
//
//   // Read-only cell
//   Widget _buildReadOnlyItemCell(ProductEntity product) {
//     final isAvailable = !_unavailableIds.contains(product.id);
//     final nonVeg = isNonVegProduct(product);
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         color: isAvailable ? ColorConstants.backgroundColor : kUnavailableBg,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: isAvailable ? Colors.grey.shade300 : Colors.grey.shade400,
//         ),
//       ),
//       child: Opacity(
//         opacity: isAvailable ? 1.0 : 0.55,
//         child: Row(
//           children: [
//             vegNonVegIndicator(nonVeg),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 product.name,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                   color: isAvailable
//                       ? ColorConstants.textColor
//                       : Colors.grey.shade600,
//                   decoration: isAvailable
//                       ? null
//                       : TextDecoration.lineThrough,
//                 ),
//               ),
//             ),
//             if (!isAvailable)
//               const Padding(
//                 padding: EdgeInsets.only(left: 4),
//                 child: Icon(Icons.block, size: 14, color: Colors.grey),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────
// // Shared helpers
// // ─────────────────────────────────────────────────────────────────────────
//
// bool isNonVegProduct(ProductEntity product) {
//   try {
//     final dynamic p = product;
//     final dynamic isVeg = p.isVeg ?? p.is_veg;
//     if (isVeg is bool) return !isVeg;
//   } catch (_) {}
//   return false;
// }
//
// Widget vegNonVegIndicator(bool nonVeg) {
//   final color = nonVeg ? ColorConstants.errorColor : ColorConstants.successColor;
//   return Container(
//     width: 16,
//     height: 16,
//     alignment: Alignment.center,
//     decoration: BoxDecoration(
//       color: color.withOpacity(0.12),
//       borderRadius: BorderRadius.circular(4),
//       border: Border.all(color: color.withOpacity(0.5), width: 1),
//     ),
//     child: Container(
//       width: 6,
//       height: 6,
//       decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//     ),
//   );
// }
//
// Widget squareCheckbox(bool checked, {Color? activeColor}) {
//   final color = activeColor ?? ColorConstants.primaryColor;
//   return Container(
//     width: 18,
//     height: 18,
//     alignment: Alignment.center,
//     decoration: BoxDecoration(
//       color: checked ? color : ColorConstants.backgroundColor,
//       borderRadius: BorderRadius.circular(4),
//       border: Border.all(
//         color: checked ? color : Colors.grey.shade400,
//         width: 1.4,
//       ),
//     ),
//     child: checked ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
//   );
// }
//
// // ─────────────────────────────────────────────────────────────────────────
// // PIN confirmation dialog
// // ─────────────────────────────────────────────────────────────────────────
// class _UpdatePinDialog extends StatefulWidget {
//   final Future<bool> Function(String pin) onVerify;
//
//   const _UpdatePinDialog({required this.onVerify});
//
//   @override
//   State<_UpdatePinDialog> createState() => _UpdatePinDialogState();
// }
//
// class _UpdatePinDialogState extends State<_UpdatePinDialog> {
//   static const int _pinLength = 6;
//
//   String _pin = '';
//   bool _isVerifying = false;
//   String? _error;
//
//   void _addDigit(String d) {
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
//     setState(() {
//       _isVerifying = true;
//       _error = null;
//     });
//
//     // ── PRINT PIN ──────────────────────────────────────────────
//     print('PIN entered: $_pin');
//
//     final ok = await widget.onVerify(_pin);
//     if (!mounted) return;
//
//     if (ok) {
//       print('PIN verified successfully: $_pin');
//       Navigator.of(context).pop(true);
//     } else {
//       setState(() {
//         _isVerifying = false;
//         _error = 'Incorrect pin. Try again.';
//         _pin = '';
//       });
//       print('PIN verification failed: $_pin');
//     }
//   }
//
//   Widget _pinBox(int index) {
//     final filled = index < _pin.length;
//     return Expanded(
//       child: Container(
//         height: 44,
//         alignment: Alignment.center,
//         margin: const EdgeInsets.symmetric(horizontal: 3),
//         decoration: BoxDecoration(
//           color: kPageBg,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: filled ? ColorConstants.primaryColor : Colors.grey.shade300,
//           ),
//         ),
//         child: filled
//             ? Container(
//           width: 10,
//           height: 10,
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
//   Widget _key({String? label, Widget? child, VoidCallback? onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.all(6),
//         width: 64,
//         height: 48,
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: kPageBg,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: child ??
//             Text(
//               label ?? '',
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//             ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: ColorConstants.backgroundColor,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 const Expanded(
//                   child: Text(
//                     'Update Menu Items',
//                     style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: _isVerifying ? null : () => Navigator.of(context).pop(false),
//                   child: Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Color(0xFFFFEAEA),
//                     ),
//                     child: const Icon(Icons.close, size: 18, color: Colors.red),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             const Text(
//               'Select items to keep them available. Unselected items will be unavailable',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 12, color: Colors.black54),
//             ),
//             const SizedBox(height: 18),
//             const Align(
//               alignment: Alignment.center,
//               child: Text(
//                 'Enter Pin',
//                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(_pinLength, _pinBox),
//             ),
//             if (_error != null) ...[
//               const SizedBox(height: 8),
//               Text(
//                 _error!,
//                 style: TextStyle(color: ColorConstants.errorColor, fontSize: 12),
//               ),
//             ],
//             const SizedBox(height: 16),
//             Wrap(
//               alignment: WrapAlignment.center,
//               children: [
//                 for (final n in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
//                   _key(label: n, onTap: () => _addDigit(n)),
//                 _key(label: 'C', onTap: _clear),
//                 _key(label: '0', onTap: () => _addDigit('0')),
//                 _key(
//                   child: const Icon(Icons.backspace_outlined, size: 18),
//                   onTap: _backspace,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 18),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isVerifying ? null : _submit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: ColorConstants.primaryColor,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: _isVerifying
//                     ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
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
//
// // ─────────────────────────────────────────────────────────────────────────
// // Edit Menu screen
// // ─────────────────────────────────────────────────────────────────────────
// class EditMenuScreen extends StatefulWidget {
//   final int restaurantId;
//   final Set<int> initialUnavailableIds;
//
//   const EditMenuScreen({
//     Key? key,
//     required this.restaurantId,
//     required this.initialUnavailableIds,
//   }) : super(key: key);
//
//   @override
//   State<EditMenuScreen> createState() => _EditMenuScreenState();
// }
//
// class _EditMenuScreenState extends State<EditMenuScreen> {
//   late final Set<int> _unavailableIds;
//
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _unavailableIds = Set<int>.from(widget.initialUnavailableIds);
//     final bloc = context.read<CategoryBloc>();
//     // Already loaded from parent – do NOT reload
//     if (bloc.state is CategoryInitial) {
//       bloc.add(LoadCategories());
//     }
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   bool _matchesSearch(String name) {
//     if (_searchQuery.trim().isEmpty) return true;
//     return name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
//   }
//
//   void _toggleProduct(int productId) {
//     // Find the product to get original in_stock
//     String originalStock = 'Yes'; // default
//     try {
//       final state = context.read<CategoryBloc>().state;
//       if (state is CategoryLoaded) {
//         final all = <ProductEntity>[
//           ...state.directProducts,
//           for (final list in state.subcategoryProducts.values) ...list,
//           for (final miniList in state.miniSubcategoriesMap.values)
//             for (final mini in miniList) ...mini.products,
//         ];
//         final product = all.cast<ProductEntity?>().firstWhere(
//               (p) => p?.id == productId,
//           orElse: () => null,
//         );
//         if (product != null) {
//           originalStock = product.inStock ? 'Yes' : 'No';
//         }
//       }
//     } catch (_) {}
//
//     setState(() {
//       if (_unavailableIds.contains(productId)) {
//         // was unavailable → now available
//         _unavailableIds.remove(productId);
//         print(
//           'Item id: $productId | '
//               'Original in_stock: $originalStock ',
//         );
//       } else {
//         _unavailableIds.add(productId);
//         print(
//           'Item id: $productId | '
//               'Original in_stock: $originalStock  ',
//         );
//       }
//     });
//   }
//   void _toggleSection(List<ProductEntity> products, bool selectAll) {
//     setState(() {
//       for (final p in products) {
//         if (selectAll) {
//           _unavailableIds.remove(p.id);
//           print(
//             'Item id: ${p.id} | Name: ${p.name} | '
//                 'Original in_stock: ${p.inStock ? "Yes" : "No"}  ',
//           );
//         } else {
//           _unavailableIds.add(p.id);
//           print(
//             'Item id: ${p.id} | Name: ${p.name} | '
//                 'Original in_stock: ${p.inStock ? "Yes" : "No"}  ',
//           );
//         }
//       }
//     });
//   }
//
//   Future<void> _onContinuePressed() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const _UpdateMenuConfirmDialog(),
//     );
//     if (confirmed != true) return;
//     if (!mounted) return;
//
//     print('========== MENU UPDATE SUMMARY ==========');
//     print('Items that will be set to "in_stock":"No" → IDs: $_unavailableIds');
//     print('Count: ${_unavailableIds.length}');
//     print('=========================================');
//
//     Navigator.of(context).pop<Set<int>>(Set<int>.from(_unavailableIds));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kPageBg,
//       appBar: AppBar(
//         toolbarHeight: 44,
//         backgroundColor: ColorConstants.backgroundColor,
//         foregroundColor: ColorConstants.textColor,
//         elevation: 0.5,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, size: 16),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Edit Menu',
//           style: TextStyle(
//             fontSize: 16,
//             color: ColorConstants.textColor,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildSearchBar(),
//             _buildCategoriesLabelRow(),
//             BlocBuilder<CategoryBloc, CategoryState>(
//               builder: (context, state) {
//                 if (state is CategoryLoaded) {
//                   return CategoryTabs(
//                     categories: state.categories,
//                     selectedId: state.selectedCategoryId,
//                     onTabSelected: (id) {
//                       context.read<CategoryBloc>().add(SelectCategory(categoryId: id));
//                     },
//                   );
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//             Expanded(
//               child: BlocBuilder<CategoryBloc, CategoryState>(
//                 builder: (context, state) {
//                   if (state is CategoryLoading) {
//                     return const Center(child: CircularProgressIndicator());
//                   } else if (state is CategoryLoaded) {
//                     return ListView(
//                       padding: const EdgeInsets.only(top: 8, bottom: 8),
//                       children: [_buildCategoryContent(state)],
//                     );
//                   } else if (state is CategoryError) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(state.message),
//                           const SizedBox(height: 8),
//                           ElevatedButton(
//                             onPressed: () =>
//                                 context.read<CategoryBloc>().add(LoadCategories()),
//                             child: const Text('Retry'),
//                           ),
//                         ],
//                       ),
//                     );
//                   }
//                   return const SizedBox.shrink();
//                 },
//               ),
//             ),
//             _buildContinueBar(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Container(
//       color: ColorConstants.backgroundColor,
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//       child: Container(
//         height: 40,
//         decoration: BoxDecoration(
//           color: kPageBg,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Row(
//           children: [
//             const SizedBox(width: 12),
//             Icon(Icons.search, color: ColorConstants.hintColor, size: 20),
//             const SizedBox(width: 8),
//             Expanded(
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: (v) => setState(() => _searchQuery = v),
//                 decoration: InputDecoration(
//                   hintText: 'Search...',
//                   hintStyle: TextStyle(color: ColorConstants.hintColor, fontSize: 14),
//                   border: InputBorder.none,
//                   isDense: true,
//                 ),
//               ),
//             ),
//             if (_searchQuery.isNotEmpty)
//               GestureDetector(
//                 onTap: () => setState(() {
//                   _searchController.clear();
//                   _searchQuery = '';
//                 }),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   child: Icon(Icons.close, size: 16, color: ColorConstants.hintColor),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCategoriesLabelRow() {
//     return Container(
//       color: ColorConstants.backgroundColor,
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             'Categories',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//               color: ColorConstants.textColor,
//             ),
//           ),
//           Row(
//             children: [
//               _legendChip(ColorConstants.successColor, 'Veg'),
//               const SizedBox(width: 10),
//               _legendChip(ColorConstants.errorColor, 'Non Veg'),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _legendChip(Color color, String label) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: color.withOpacity(0.5)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.circle, size: 8, color: color),
//           const SizedBox(width: 4),
//           Text(label, style: TextStyle(fontSize: 11, color: color)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCategoryContent(CategoryLoaded state) {
//     final selected = state.categories
//         .where((c) => c.id == state.selectedCategoryId)
//         .toList();
//     final title = selected.isNotEmpty ? selected.first.name : '';
//
//     // ── Case 1: no subcategories → flat list ──
//     if (state.subcategories.isEmpty) {
//       final products = [
//         ...state.directProducts,
//         for (final list in state.subcategoryProducts.values) ...list,
//         for (final miniList in state.miniSubcategoriesMap.values)
//           for (final mini in miniList) ...mini.products,
//       ];
//
//       final unique = <int, ProductEntity>{};
//       for (final p in products) unique[p.id] = p;
//       final filtered = unique.values.where((p) => _matchesSearch(p.name)).toList();
//
//       if (filtered.isEmpty) {
//         return const Padding(
//           padding: EdgeInsets.only(top: 80),
//           child: Center(child: Text('No items found', style: TextStyle(color: Colors.grey))),
//         );
//       }
//
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionHeader(title, filtered),
//           _buildProductGrid(filtered),
//           const SizedBox(height: 16),
//         ],
//       );
//     }
//
//     // ── Case 2: has subcategories → group by sub / mini ──
//     final List<Widget> sections = [];
//
//     for (final sub in state.subcategories) {
//       final direct = state.subcategoryProducts[sub.id] ?? [];
//       final minis = state.miniSubcategoriesMap[sub.id] ?? [];
//
//       // ---------- no mini ----------
//       if (minis.isEmpty) {
//         final filtered = direct.where((p) => _matchesSearch(p.name)).toList();
//         if (filtered.isEmpty && _searchQuery.isNotEmpty) continue;
//
//         sections.add(_buildSectionHeader(sub.name, filtered));
//         if (filtered.isNotEmpty) {
//           sections.add(_buildProductGrid(filtered));
//         } else {
//           sections.add(const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Text('No items', style: TextStyle(color: Colors.grey, fontSize: 13)),
//           ));
//         }
//         sections.add(const SizedBox(height: 12));
//         continue;
//       }
//
//       // ---------- has mini-subcategories ----------
//       // Collect all products under this subcategory for the “Select All”
//       final allUnderSub = <ProductEntity>[
//         for (final mini in minis) ...mini.products,
//       ];
//       final filteredAll = allUnderSub.where((p) => _matchesSearch(p.name)).toList();
//
//       sections.add(_buildSectionHeader(sub.name, filteredAll));
//
//       for (final mini in minis) {
//         final filtered = mini.products.where((p) => _matchesSearch(p.name)).toList();
//         if (filtered.isEmpty && _searchQuery.isNotEmpty) continue;
//
//         sections.add(Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
//           child: Text(
//             mini.name,
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//               color: ColorConstants.textColor.withOpacity(0.85),
//             ),
//           ),
//         ));
//
//         if (filtered.isNotEmpty) {
//           sections.add(_buildProductGrid(filtered));
//         } else {
//           sections.add(const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//             child: Text('No items', style: TextStyle(color: Colors.grey, fontSize: 13)),
//           ));
//         }
//         sections.add(const SizedBox(height: 8));
//       }
//       sections.add(const SizedBox(height: 8));
//     }
//
//     if (sections.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.only(top: 80),
//         child: Center(child: Text('No items found', style: TextStyle(color: Colors.grey))),
//       );
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: sections,
//     );
//   }
//
//   Widget _buildSectionHeader(String title, List<ProductEntity> sectionProducts) {
//     final total = sectionProducts.length;
//     final selectedCount =
//         sectionProducts.where((p) => !_unavailableIds.contains(p.id)).length;
//     final allSelected = selectedCount == total;
//
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.baseline,
//             textBaseline: TextBaseline.alphabetic,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: ColorConstants.textColor,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 '$selectedCount/$total Selected',
//                 style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
//               ),
//             ],
//           ),
//           GestureDetector(
//             onTap: () => _toggleSection(sectionProducts, !allSelected),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'Select All',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey.shade700,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 squareCheckbox(allSelected, activeColor: ColorConstants.successColor),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildProductGrid(List<ProductEntity> filtered) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: filtered.length,
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 10,
//           crossAxisSpacing: 10,
//           mainAxisExtent: 48,
//         ),
//         itemBuilder: (context, index) => _buildEditableItemCell(filtered[index]),
//       ),
//     );
//   }
//
//   Widget _buildEditableItemCell(ProductEntity product) {
//     final isAvailable = !_unavailableIds.contains(product.id);
//     final nonVeg = isNonVegProduct(product);
//
//     return GestureDetector(
//       onTap: () => _toggleProduct(product.id),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         decoration: BoxDecoration(
//           color: isAvailable ? ColorConstants.backgroundColor : kUnavailableBg,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Row(
//           children: [
//             vegNonVegIndicator(nonVeg),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 product.name,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                   color: isAvailable ? ColorConstants.textColor : Colors.grey.shade500,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 6),
//             squareCheckbox(isAvailable, activeColor: ColorConstants.successColor),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildContinueBar() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
//       decoration: BoxDecoration(
//         color: ColorConstants.backgroundColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           onPressed: _onContinuePressed,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: ColorConstants.primaryColor,
//             foregroundColor: Colors.white,
//             elevation: 0,
//             padding: const EdgeInsets.symmetric(vertical: 14),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//           child: const Text(
//             'Continue',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────
// // "Update Menu?" confirmation dialog
// // ─────────────────────────────────────────────────────────────────────────
// class _UpdateMenuConfirmDialog extends StatefulWidget {
//   const _UpdateMenuConfirmDialog();
//
//   @override
//   State<_UpdateMenuConfirmDialog> createState() => _UpdateMenuConfirmDialogState();
// }
//
// class _UpdateMenuConfirmDialogState extends State<_UpdateMenuConfirmDialog> {
//   bool _isConfirming = false;
//
//   Future<void> _confirm() async {
//     setState(() => _isConfirming = true);
//     await Future.delayed(const Duration(milliseconds: 300));
//     if (!mounted) return;
//     Navigator.of(context).pop(true);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: ColorConstants.backgroundColor,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 48,
//               height: 48,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 color: ColorConstants.primaryColor.withOpacity(0.12),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.warning_amber_rounded,
//                 color: ColorConstants.primaryColor,
//                 size: 26,
//               ),
//             ),
//             const SizedBox(height: 14),
//             const Text(
//               'Update Menu?',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Are you sure you want to update the menu? Unselected items will be out of stock.',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 12, color: Colors.black54),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: _isConfirming ? null : () => Navigator.of(context).pop(false),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: ColorConstants.textColor,
//                       side: BorderSide(color: Colors.grey.shade300),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     child: const Text(
//                       'Cancel',
//                       style: TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _isConfirming ? null : _confirm,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: ColorConstants.primaryColor,
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     child: _isConfirming
//                         ? const SizedBox(
//                       width: 18,
//                       height: 18,
//                       child:CupertinoActivityIndicator(radius: 14),
//                     )
//                         : const Text(
//                       'Confirm',
//                       style: TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



//////===========

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../constants/color_constants.dart';
import 'order_menu/bloc/category_bloc/category_bloc.dart';
import 'order_menu/bloc/category_bloc/category_event.dart';
import 'order_menu/bloc/category_bloc/category_state.dart';
import 'order_menu/entities/product_entity.dart';
import 'order_menu/widgets/category_tabs.dart';
import 'order_menu/widgets/product_card.dart';

const Color kPageBg = Color(0xFFF5F5F5);
const Color kUnavailableBg = Color(0xFFE9E9E9);

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
  bool _seededAvailability = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _captainRole = '';

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CategoryBloc>();
    if (bloc.state is CategoryInitial) {
      bloc.add(LoadCategories());
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

  void _seedAvailabilityOnce(CategoryLoaded state) {
    if (_seededAvailability) return;
    _seededAvailability = true;

    final all = <ProductEntity>[
      ...state.directProducts,
      for (final list in state.subcategoryProducts.values) ...list,
      for (final miniList in state.miniSubcategoriesMap.values)
        for (final mini in miniList) ...mini.products,
    ];

    for (final p in all) {
      if (!p.inStock) {
        _unavailableIds.add(p.id);
      }
    }

    print('Unavailable (in_stock=No) IDs: $_unavailableIds');
  }

  Future<void> _openUpdatePinDialog() async {
    final pinResult = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _UpdatePinDialog(),
    );
    if (pinResult == null) return;
    if (!mounted) return;

    final result = await Navigator.of(context).push<Set<int>>(
      MaterialPageRoute(
        builder: (_) => EditMenuScreen(
          restaurantId: widget.restaurantId,
          initialUnavailableIds: Set<int>.from(_unavailableIds),
          pin: pinResult,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _unavailableIds
          ..clear()
          ..addAll(result);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu updated successfully')),
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
        toolbarHeight: 44,
        backgroundColor: ColorConstants.backgroundColor,
        foregroundColor: ColorConstants.textColor,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Menu Management',
          style: TextStyle(
            fontSize: 16,
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
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is CategoryLoaded) {
                  _seedAvailabilityOnce(state);
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
        ],
      ),
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
                onChanged: (v) => setState(() => _searchQuery = v),
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
                onTap: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
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
          mainAxisExtent: 48,
        ),
        itemBuilder: (context, index) => _buildReadOnlyItemCell(products[index]),
      ),
    );
  }

  // Widget _buildReadOnlyItemCell(ProductEntity product) {
  //   // Grey out when product.inStock == false OR marked unavailable after edit
  //   final isAvailable = product.inStock && !_unavailableIds.contains(product.id);
  //   final outOfStock = !isAvailable;
  //   final nonVeg = isNonVegProduct(product);
  //
  //   final Color cardBg = outOfStock ? const Color(0xFFE7E7E7) : ColorConstants.backgroundColor;
  //   final Color titleColor = outOfStock ? Colors.grey.shade500 : ColorConstants.textColor;
  //   final Color borderColor = outOfStock ? Colors.grey.shade400 : Colors.grey.shade300;
  //
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10),
  //     decoration: BoxDecoration(
  //       color: cardBg,
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: borderColor),
  //     ),
  //     child: Opacity(
  //       opacity: outOfStock ? 0.7 : 1.0,
  //       child: Row(
  //         children: [
  //           vegNonVegIndicator(nonVeg),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Text(
  //               product.name,
  //               maxLines: 1,
  //               overflow: TextOverflow.ellipsis,
  //               style: TextStyle(
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.w500,
  //                 color: titleColor,
  //                 decoration: outOfStock ? TextDecoration.lineThrough : null,
  //               ),
  //             ),
  //           ),
  //           if (outOfStock)
  //             const Padding(
  //               padding: EdgeInsets.only(left: 4),
  //               child: Icon(Icons.block, size: 14, color: Colors.grey),
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildReadOnlyItemCell(ProductEntity product) {
    // Source of truth = _unavailableIds (seeded from API + updated after edit)
    // Do NOT use product.inStock here — it stays stale until CategoryBloc reloads
    final outOfStock = _unavailableIds.contains(product.id);
    final nonVeg = isNonVegProduct(product);

    final Color cardBg =
    outOfStock ? const Color(0xFFE7E7E7) : ColorConstants.backgroundColor;
    final Color titleColor =
    outOfStock ? Colors.grey.shade500 : ColorConstants.textColor;
    final Color borderColor =
    outOfStock ? Colors.grey.shade400 : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

// ─── PIN dialog ──────────────────────────────────────────────────

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

  void _addDigit(String d) {
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

  Widget _pinBox(int index) {
    final filled = index < _pin.length;
    return Expanded(
      child: Container(
        height: 44,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: kPageBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled ? ColorConstants.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: filled
            ? Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black87,
          ),
        )
            : null,
      ),
    );
  }

  Widget _key({String? label, Widget? child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: _isVerifying ? null : onTap,
      child: Container(
        margin: const EdgeInsets.all(6),
        width: 64,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kPageBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child ??
            Text(
              label ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorConstants.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Update Menu Items',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: _isVerifying ? null : () => Navigator.of(context).pop(null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFEAEA),
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select items to keep them available. Unselected items will be unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Enter Pin',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, _pinBox),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: ColorConstants.errorColor, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final n in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                  _key(label: n, onTap: () => _addDigit(n)),
                _key(label: 'C', onTap: _clear),
                _key(label: '0', onTap: () => _addDigit('0')),
                _key(
                  child: const Icon(Icons.backspace_outlined, size: 18),
                  onTap: _backspace,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
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

// ─── Edit Menu Screen ────────────────────────────────────────────

class EditMenuScreen extends StatefulWidget {
  final int restaurantId;
  final Set<int> initialUnavailableIds;
  final String pin;

  const EditMenuScreen({
    Key? key,
    required this.restaurantId,
    required this.initialUnavailableIds,
    required this.pin,
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

  @override
  void initState() {
    super.initState();
    _unavailableIds = Set<int>.from(widget.initialUnavailableIds);
    final bloc = context.read<CategoryBloc>();
    if (bloc.state is CategoryInitial) {
      bloc.add(LoadCategories());
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
      final state = context.read<CategoryBloc>().state;
      if (state is CategoryLoaded) {
        final all = <ProductEntity>[
          ...state.directProducts,
          for (final list in state.subcategoryProducts.values) ...list,
          for (final miniList in state.miniSubcategoriesMap.values)
            for (final mini in miniList) ...mini.products,
        ];
        final product = all.cast<ProductEntity?>().firstWhere(
              (p) => p?.id == productId,
          orElse: () => null,
        );
        if (product != null) {
          originalStock = product.inStock ? 'Yes' : 'No';
        }
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

    final url = Uri.parse(
      'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/products/status',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu updated successfully')),
          );
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

    final List<Map<String, dynamic>> productsPayload = [];

    for (final p in unique.values) {
      // Always derive old_status from the product entity RIGHT NOW
      final oldStatus = p.inStock ? 'instock' : 'outofstock';

      final currentAvailable = !_unavailableIds.contains(p.id);
      final newStatus = currentAvailable ? 'instock' : 'outofstock';

      // Only send if status actually changes
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

    final success = await _updateMenuOnServer(productsPayload);
    if (!mounted) return;

    if (success) {
      // Reload menu so product.inStock matches server next time
      context.read<CategoryBloc>().add(LoadCategories());
      Navigator.of(context).pop<Set<int>>(Set<int>.from(_unavailableIds));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: ColorConstants.backgroundColor,
        foregroundColor: ColorConstants.textColor,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Menu',
          style: TextStyle(
            fontSize: 16,
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
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is CategoryLoaded) {
                    if (_originalStatusMap.isEmpty) {
                      final all = <ProductEntity>[
                        ...state.directProducts,
                        for (final list in state.subcategoryProducts.values) ...list,
                        for (final miniList in state.miniSubcategoriesMap.values)
                          for (final mini in miniList) ...mini.products,
                      ];
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
                onChanged: (v) => setState(() => _searchQuery = v),
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
                onTap: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                maxLines: 1,
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
          onPressed: _onContinuePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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