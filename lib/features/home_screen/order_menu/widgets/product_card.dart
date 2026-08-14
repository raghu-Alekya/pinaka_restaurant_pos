// import 'package:flutter/material.dart';
// import '../../../../constants/color_constants.dart';
// import '../entities/product_entity.dart';
//
// bool isNonVegProduct(ProductEntity product) {
//   const nonVegKeywords = [
//     'chicken', 'mutton', 'egg', 'kheema', 'fish', 'prawn', 'beef', 'pork', 'meat',
//   ];
//   final name = product.name.toLowerCase();
//   return nonVegKeywords.any((k) => name.contains(k));
// }
//
// class ProductCard extends StatelessWidget {
//   final ProductEntity product;
//   final int quantity;
//   final VoidCallback onAdd;
//   final VoidCallback onRemove;
//
//   /// Non-null only for variant products (is_variant == "Yes").
//   /// Tapping the card opens the Add Ons bottom sheet instead of adding
//   /// directly.
//   final VoidCallback? onVariantTap;
//
//   const ProductCard({
//     Key? key,
//     required this.product,
//     required this.quantity,
//     required this.onAdd,
//     required this.onRemove,
//     this.onVariantTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final nonVeg = isNonVegProduct(product);
//     final isVariant = onVariantTap != null;
//     final outOfStock = !product.inStock;
//
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       // Tap ANYWHERE on the card: variant products open the sheet,
//       // simple products add one unit directly. The minus/plus buttons
//       // below are separate hit targets, so they still work on their own.
//       onTap: outOfStock
//           ? null
//           : () {
//         if (isVariant) {
//           onVariantTap!();
//         } else {
//           onAdd();
//         }
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: Colors.grey.shade200),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 14,
//                   height: 14,
//                   margin: const EdgeInsets.only(top: 2),
//                   padding: const EdgeInsets.all(2),
//                   decoration: BoxDecoration(
//                     border: Border.all(
//                       color: nonVeg ? Colors.red : Colors.green,
//                       width: 1.2,
//                     ),
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: nonVeg ? Colors.red : Colors.green,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Text(
//                     product.name,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   '\$${product.price ?? '0.00'}',
//                   style: const TextStyle(
//                     color: ColorConstants.primaryColor,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 15,
//                   ),
//                 ),
//                 if (outOfStock)
//                   const Chip(
//                     label: Text('Out of Stock', style: TextStyle(color: Colors.white, fontSize: 9)),
//                     backgroundColor: Colors.red,
//                     visualDensity: VisualDensity.compact,
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                   )
//                 else if (isVariant)
//                   quantity == 0
//                       ? const Icon(Icons.add_circle, color: ColorConstants.primaryColor, size: 24)
//                       : Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                     decoration: BoxDecoration(
//                       color: ColorConstants.primaryColor,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       '$quantity',
//                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
//                     ),
//                   )
//                 else if (quantity == 0)
//                     const Icon(Icons.add_circle, color: ColorConstants.primaryColor, size: 24)
//                   else
//                     _CompactStepper(quantity: quantity, onAdd: onAdd, onRemove: onRemove),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// Small, light stepper — outlined pill instead of a solid filled block.
// class _CompactStepper extends StatelessWidget {
//   final int quantity;
//   final VoidCallback onAdd;
//   final VoidCallback onRemove;
//
//   const _CompactStepper({
//     required this.quantity,
//     required this.onAdd,
//     required this.onRemove,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 24,
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
//             child: Container(
//               width: 22,
//               alignment: Alignment.center,
//               child: const Icon(Icons.remove, size: 14, color: ColorConstants.primaryColor),
//             ),
//           ),
//           SizedBox(
//             width: 18,
//             child: Text(
//               '$quantity',
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorConstants.primaryColor),
//             ),
//           ),
//           GestureDetector(
//             onTap: onAdd,
//             child: Container(
//               width: 22,
//               alignment: Alignment.center,
//               child: const Icon(Icons.add, size: 14, color: ColorConstants.primaryColor),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

/////


import 'package:flutter/material.dart';
import '../../../../constants/color_constants.dart';
import '../entities/product_entity.dart';

bool isNonVegProduct(ProductEntity product) {
  // Uses the real flag from your API instead of guessing from the name.
  // Rename `product.isVeg` below to whatever field your ProductEntity
  // actually has (e.g. product.veg, product.foodType, product.isVegetarian).
  return product.isVeg == false;
}

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// Non-null only for variant products (is_variant == "Yes").
  final VoidCallback? onVariantTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.onVariantTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    // Reference design size
    const referenceWidth = 375.0;
    const referenceHeight = 812.0;

    // Responsive scale
    final widthScale = screenWidth / referenceWidth;
    final heightScale = screenHeight / referenceHeight;

    // Use width primarily for horizontal/card dimensions.
    // Use a balanced scale for things that should not become too large.
    final scale = widthScale < heightScale ? widthScale : heightScale;

    double w(double value) => value * widthScale;
    double h(double value) => value * heightScale;
    double s(double value) => value * scale;

    final nonVeg = isNonVegProduct(product);
    final isVariant = onVariantTap != null;
    final outOfStock = !product.inStock;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: outOfStock
          ? null
          : () {
        if (isVariant) {
          onVariantTap!();
        } else {
          onAdd();
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(s(10)),
          border: Border.all(
            color: Colors.grey.shade200,
            width: s(1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: s(4),
              offset: Offset(0, s(2)),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full-height responsive veg/non-veg indicator
              Container(
                width: w(4),
                decoration: BoxDecoration(
                  color: nonVeg ? Colors.red : Colors.green,
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(s(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Responsive veg/non-veg icon
                          Container(
                            width: s(14),
                            height: s(14),
                            margin: EdgeInsets.only(
                              top: s(2),
                            ),
                            padding: EdgeInsets.all(s(2)),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: nonVeg
                                    ? Colors.red
                                    : Colors.green,
                                width: s(1.2),
                              ),
                              borderRadius: BorderRadius.circular(s(3)),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: nonVeg
                                    ? Colors.red
                                    : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                          SizedBox(width: s(6)),

                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: s(14),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: s(8)),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price
                          Flexible(
                            child: Text(
                              '\$${product.price ?? '0.00'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ColorConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: s(15),
                              ),
                            ),
                          ),

                          SizedBox(width: s(8)),

                          if (outOfStock)
                            Chip(
                              label: Text(
                                'Out of Stock',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: s(9),
                                ),
                              ),
                              backgroundColor: Colors.red,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.symmetric(
                                horizontal: s(4),
                                vertical: s(2),
                              ),
                            )
                          else if (isVariant)
                            quantity == 0
                                ? Icon(
                              Icons.add_circle,
                              color:
                              ColorConstants.primaryColor,
                              size: s(24),
                            )
                                : Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: s(8),
                                vertical: s(3),
                              ),
                              decoration: BoxDecoration(
                                color:
                                ColorConstants.primaryColor,
                                borderRadius:
                                BorderRadius.circular(s(6)),
                              ),
                              child: Text(
                                '$quantity',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: s(12),
                                ),
                              ),
                            )
                          else if (quantity == 0)
                              Icon(
                                Icons.add_circle,
                                color: ColorConstants.primaryColor,
                                size: s(24),
                              )
                            else
                              _CompactStepper(
                                quantity: quantity,
                                onAdd: onAdd,
                                onRemove: onRemove,
                                scale: scale,
                              ),
                        ],
                      ),
                    ],
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

/// Responsive compact stepper.
class _CompactStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final double scale;

  const _CompactStepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.scale,
  });

  double s(double value) => value * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: s(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(6)),
        border: Border.all(
          color: ColorConstants.primaryColor,
          width: s(1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: SizedBox(
              width: s(22),
              height: s(24),
              child: Center(
                child: Icon(
                  Icons.remove,
                  size: s(14),
                  color: ColorConstants.primaryColor,
                ),
              ),
            ),
          ),

          SizedBox(
            width: s(18),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: s(12),
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryColor,
              ),
            ),
          ),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAdd,
            child: SizedBox(
              width: s(22),
              height: s(24),
              child: Center(
                child: Icon(
                  Icons.add,
                  size: s(14),
                  color: ColorConstants.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _VariantStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _VariantStepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ColorConstants.primaryColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const SizedBox(
              width: 22,
              child: Icon(Icons.remove, size: 14, color: ColorConstants.primaryColor),
            ),
          ),
          SizedBox(
            width: 18,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const SizedBox(
              width: 22,
              child: Icon(Icons.add, size: 14, color: ColorConstants.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}