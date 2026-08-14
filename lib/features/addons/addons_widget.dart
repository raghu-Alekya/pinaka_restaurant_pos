import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/color_constants.dart';
import '../home_screen/order_menu/entities/product_entity.dart';
import 'addons_domin/addon_entity.dart';

class _AddOnSelectionSheet extends StatefulWidget {
  final ProductEntity product;
  final double basePrice;
  final List<AddOnEntity> availableAddOns;
  final void Function(int quantity, List<Map<String, dynamic>> selectedAddOns) onAddToCart;

  const _AddOnSelectionSheet({
    required this.product,
    required this.basePrice,
    required this.availableAddOns,
    required this.onAddToCart,
  });

  @override
  State<_AddOnSelectionSheet> createState() => _AddOnSelectionSheetState();
}

class _AddOnSelectionSheetState extends State<_AddOnSelectionSheet> {
  int _quantity = 1;
  final Set<AddOnEntity> _selectedAddOns = {};

  @override
  Widget build(BuildContext context) {
    final addOnsTotal = _selectedAddOns.fold<double>(
      0,
          (sum, a) => sum + a.price,
    );
    final total = (widget.basePrice + addOnsTotal) * _quantity;

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
          Text(
            widget.product.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${widget.basePrice.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${(widget.basePrice + addOnsTotal).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primaryColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  ),
                  Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: ColorConstants.primaryColor),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ],
          ),
          if (widget.availableAddOns.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Add Ons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(),
            ...widget.availableAddOns.map((addOn) {
              final isChecked = _selectedAddOns.contains(addOn);
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: isChecked,
                title: Text(addOn.name),
                secondary: Text('+ \$${addOn.price.toStringAsFixed(2)}'),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedAddOns.add(addOn);
                    } else {
                      _selectedAddOns.remove(addOn);
                    }
                  });
                },
              );
            }),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final selectedList = _selectedAddOns.map((a) {
                  return {
                    'name': a.name,
                    'price': a.price,
                  };
                }).toList();
                widget.onAddToCart(_quantity, selectedList);
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
  }
}




///// ======

//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../constants/color_constants.dart';
//
// import '../home_screen/order_menu/entities/product_entity.dart';
// import '../home_screen/order_menu/widgets/product_card.dart'show isNonVegProduct;
// import '../variations/variations_domain/variation_entity.dart';
// import 'addons_domin/addon_entity.dart';
//
// class AddOnItem {
//   final String name;
//   final double price;
//
//   AddOnItem({required this.name, required this.price});
// }
//
// class AddOnBottomSheet extends StatefulWidget {
//   final ProductEntity product;
//   final Function(ProductEntity? selectedVariant, List<AddOnItem> selectedAddOns, int quantity)
//   onAddToCart;
//
//   const AddOnBottomSheet({
//     Key? key,
//     required this.product,
//     required this.onAddToCart,
//   }) : super(key: key);
//
//   @override
//   State<AddOnBottomSheet> createState() => _AddOnBottomSheetState();
// }
//
// class _AddOnBottomSheetState extends State<AddOnBottomSheet> {
//   bool _isLoading = true;
//   String? _error;
//
//   List<VariationEntity> _variants = [];
//   List<AddOnEntity> _availableAddOns = [];
//
//   VariationEntity? _selectedVariant;
//   final Set<int> _selectedAddOnIds = {};
//   int _quantity = 1;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }
//
//   Future<void> _loadData() async {
//     try {
//       final results = await Future.wait([
//         context.read<FetchVariationsUseCase>()(widget.product.id),
//         context.read<FetchAddOnsUseCase>()(widget.product.id),
//       ]);
//
//       final variants = results[0] as List<VariationEntity>;
//       final addOns = results[1] as List<AddOnEntity>;
//
//       if (!mounted) return;
//       setState(() {
//         _variants = variants;
//         _availableAddOns = addOns;
//         _selectedVariant = variants.isNotEmpty ? variants.first : null;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _error = 'Failed to load options. Please try again.';
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final nonVeg = isNonVegProduct(widget.product);
//
//     final variantPrice = _selectedVariant != null
//         ? double.tryParse(_selectedVariant!.price) ?? 0
//         : double.tryParse(widget.product.price ?? '0') ?? 0;
//     final addOnsTotal = _availableAddOns
//         .where((a) => _selectedAddOnIds.contains(a.id))
//         .fold<double>(0, (sum, a) => sum + a.price);
//     final totalPrice = (variantPrice + addOnsTotal) * _quantity;
//
//     return Padding(
//       padding: EdgeInsets.only(
//         left: 20,
//         right: 20,
//         top: 16,
//         bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//       ),
//       child: Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.85,
//         ),
//         child: _isLoading
//             ? const SizedBox(
//           height: 160,
//           child: Center(child: CupertinoActivityIndicator(radius: 14)),
//         )
//             : _error != null
//             ? SizedBox(
//           height: 160,
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(_error!, style: const TextStyle(color: Colors.black54)),
//                 const SizedBox(height: 8),
//                 TextButton(
//                   onPressed: () {
//                     setState(() => _isLoading = true);
//                     _loadData();
//                   },
//                   child: const Text('Retry'),
//                 ),
//               ],
//             ),
//           ),
//         )
//             : SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // ── Header: veg/non-veg dot + name + close ──
//               Row(
//                 children: [
//                   Container(
//                     width: 10,
//                     height: 10,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: nonVeg ? Colors.red : Colors.green,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       widget.product.name,
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: const BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Color(0xFFFFEAEA),
//                       ),
//                       child: const Icon(Icons.close, size: 18, color: Colors.red),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//
//               // ── Variants — 2-column card grid ──
//               if (_variants.isNotEmpty)
//                 GridView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: _variants.length,
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     mainAxisSpacing: 10,
//                     crossAxisSpacing: 10,
//                     childAspectRatio: 2.2,
//                   ),
//                   itemBuilder: (context, index) {
//                     final variant = _variants[index];
//                     final isSelected =
//                         _selectedVariant?.variationId == variant.variationId;
//
//                     return GestureDetector(
//                       onTap: () => setState(() {
//                         _selectedVariant = variant;
//                         if (!isSelected) _quantity = 1;
//                       }),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                         decoration: BoxDecoration(
//                           color: isSelected
//                               ? ColorConstants.primaryColor.withOpacity(0.06)
//                               : Colors.white,
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(
//                             color: isSelected
//                                 ? ColorConstants.primaryColor
//                                 : Colors.grey.shade300,
//                             width: isSelected ? 1.4 : 1,
//                           ),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               widget.product.name,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(fontSize: 12, color: Colors.black87),
//                             ),
//                             Text(
//                               variant.name,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
//                             ),
//                             const SizedBox(height: 4),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   '\$${variant.price}',
//                                   style: const TextStyle(
//                                     color: ColorConstants.primaryColor,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                                 isSelected
//                                     ? _VariantStepper(
//                                   quantity: _quantity,
//                                   onAdd: () => setState(() => _quantity++),
//                                   onRemove: () => setState(() {
//                                     if (_quantity > 1) _quantity--;
//                                   }),
//                                 )
//                                     : GestureDetector(
//                                   onTap: () => setState(() {
//                                     _selectedVariant = variant;
//                                     _quantity = 1;
//                                   }),
//                                   child: const Icon(
//                                     Icons.add_circle,
//                                     color: ColorConstants.primaryColor,
//                                     size: 22,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//
//               // ── Modifiers ──
//               if (_availableAddOns.isNotEmpty) ...[
//                 const SizedBox(height: 16),
//                 Row(
//                   children: const [
//                     Text('Modifiers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
//                     SizedBox(width: 8),
//                     Expanded(child: Divider()),
//                   ],
//                 ),
//                 ..._availableAddOns.map((addon) {
//                   final isChecked = _selectedAddOnIds.contains(addon.id);
//                   return CheckboxListTile(
//                     contentPadding: EdgeInsets.zero,
//                     controlAffinity: ListTileControlAffinity.leading,
//                     dense: true,
//                     value: isChecked,
//                     title: Text(addon.name, style: const TextStyle(fontSize: 14)),
//                     secondary: Text('+ \$${addon.price.toStringAsFixed(2)}'),
//                     onChanged: (checked) {
//                       setState(() {
//                         if (checked == true) {
//                           _selectedAddOnIds.add(addon.id);
//                         } else {
//                           _selectedAddOnIds.remove(addon.id);
//                         }
//                       });
//                     },
//                   );
//                 }),
//               ],
//
//               const SizedBox(height: 8),
//
//               // ── Add to Cart ──
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     final selectedAddOns = _availableAddOns
//                         .where((a) => _selectedAddOnIds.contains(a.id))
//                         .map((a) => AddOnItem(name: a.name, price: a.price))
//                         .toList();
//
//                     final selectedVariantEntity = _selectedVariant != null
//                         ? ProductEntity(
//                       id: _selectedVariant!.variationId,
//                       name: '${widget.product.name} - ${_selectedVariant!.name}',
//                       price: _selectedVariant!.price,
//                       inStock: _selectedVariant!.inStock == 'Yes',
//                     )
//                         : null;
//
//                     widget.onAddToCart(selectedVariantEntity, selectedAddOns, _quantity);
//                     Navigator.pop(context);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: ColorConstants.primaryColor,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
//                       Text('\$${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _VariantStepper extends StatelessWidget {
//   final int quantity;
//   final VoidCallback onAdd;
//   final VoidCallback onRemove;
//
//   const _VariantStepper({
//     required this.quantity,
//     required this.onAdd,
//     required this.onRemove,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 26,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: ColorConstants.primaryColor, width: 1),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           GestureDetector(
//             onTap: onRemove,
//             child: const SizedBox(
//               width: 22,
//               child: Icon(Icons.remove, size: 14, color: ColorConstants.primaryColor),
//             ),
//           ),
//           SizedBox(
//             width: 18,
//             child: Text(
//               '$quantity',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: ColorConstants.primaryColor,
//               ),
//             ),
//           ),
//           GestureDetector(
//             onTap: onAdd,
//             child: const SizedBox(
//               width: 22,
//               child: Icon(Icons.add, size: 14, color: ColorConstants.primaryColor),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }