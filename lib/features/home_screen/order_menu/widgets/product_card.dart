// import 'package:flutter/material.dart';
// import '../../../../constants/color_constants.dart';
// import '../entities/product_entity.dart';
//
// bool isNonVegProduct(ProductEntity product) {
//   return product.isVeg == false;
// }
//
// class ProductCard extends StatelessWidget {
//   final ProductEntity product;
//   final int quantity;
//   final VoidCallback onAdd;
//   final VoidCallback onRemove;
//   final String currencySymbol; // 👈 new parameter
//
//   /// Non-null only for variant products (is_variant == "Yes").
//   final VoidCallback? onVariantTap;
//
//   const ProductCard({
//     Key? key,
//     required this.product,
//     required this.quantity,
//     required this.onAdd,
//     required this.onRemove,
//     required this.currencySymbol, // 👈 required
//     this.onVariantTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final media = MediaQuery.of(context);
//
//     final screenWidth = media.size.width;
//     final screenHeight = media.size.height;
//
//     const referenceWidth = 375.0;
//     const referenceHeight = 812.0;
//
//     final widthScale = screenWidth / referenceWidth;
//     final heightScale = screenHeight / referenceHeight;
//     final scale = widthScale < heightScale ? widthScale : heightScale;
//
//     double w(double value) => value * widthScale;
//     double h(double value) => value * heightScale;
//     double s(double value) => value * scale;
//
//     final nonVeg = isNonVegProduct(product);
//     final isVariant = onVariantTap != null;
//     final outOfStock = !product.inStock;
//
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
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
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(s(10)),
//           border: Border.all(
//             color: Colors.grey.shade200,
//             width: s(1),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: s(4),
//               offset: Offset(0, s(2)),
//             ),
//           ],
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: IntrinsicHeight(
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Container(
//                 width: w(4),
//                 decoration: BoxDecoration(
//                   color: nonVeg ? Colors.red : Colors.green,
//                 ),
//               ),
//               Expanded(
//                 child: Padding(
//                   padding: EdgeInsets.all(s(12)),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             width: s(14),
//                             height: s(14),
//                             margin: EdgeInsets.only(top: s(2)),
//                             padding: EdgeInsets.all(s(2)),
//                             decoration: BoxDecoration(
//                               border: Border.all(
//                                 color: nonVeg ? Colors.red : Colors.green,
//                                 width: s(1.2),
//                               ),
//                               borderRadius: BorderRadius.circular(s(3)),
//                             ),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: nonVeg ? Colors.red : Colors.green,
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: s(6)),
//                           Expanded(
//                             child: Text(
//                               product.name,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: s(14),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: s(8)),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Flexible(
//                             child: Text(
//                               '$currencySymbol${product.price ?? '0.00'}',
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: ColorConstants.primaryColor,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: s(15),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: s(8)),
//                           if (outOfStock)
//                             Chip(
//                               label: Text(
//                                 'Out of Stock',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: s(9),
//                                 ),
//                               ),
//                               backgroundColor: Colors.red,
//                               visualDensity: VisualDensity.compact,
//                               materialTapTargetSize:
//                               MaterialTapTargetSize.shrinkWrap,
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: s(4),
//                                 vertical: s(2),
//                               ),
//                             )
//                           else if (isVariant)
//                             quantity == 0
//                                 ? Icon(
//                               Icons.add_circle,
//                               color: ColorConstants.primaryColor,
//                               size: s(24),
//                             )
//                                 : Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: s(8),
//                                 vertical: s(3),
//                               ),
//                               decoration: BoxDecoration(
//                                 color: ColorConstants.primaryColor,
//                                 borderRadius: BorderRadius.circular(s(6)),
//                               ),
//                               child: Text(
//                                 '$quantity',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: s(12),
//                                 ),
//                               ),
//                             )
//                           else if (quantity == 0)
//                               Icon(
//                                 Icons.add_circle,
//                                 color: ColorConstants.primaryColor,
//                                 size: s(24),
//                               )
//                             else
//                               _CompactStepper(
//                                 quantity: quantity,
//                                 onAdd: onAdd,
//                                 onRemove: onRemove,
//                                 scale: scale,
//                               ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//
//     );
//   }
// }
//
// /// Responsive compact stepper.
// class _CompactStepper extends StatelessWidget {
//   final int quantity;
//   final VoidCallback onAdd;
//   final VoidCallback onRemove;
//   final double scale;
//
//   const _CompactStepper({
//     required this.quantity,
//     required this.onAdd,
//     required this.onRemove,
//     required this.scale,
//   });
//
//   double s(double value) => value * scale;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: s(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(s(6)),
//         border: Border.all(
//           color: ColorConstants.primaryColor,
//           width: s(1),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: onRemove,
//             child: SizedBox(
//               width: s(22),
//               height: s(24),
//               child: Center(
//                 child: Icon(
//                   Icons.remove,
//                   size: s(14),
//                   color: ColorConstants.primaryColor,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(
//             width: s(18),
//             child: Text(
//               '$quantity',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: s(12),
//                 fontWeight: FontWeight.bold,
//                 color: ColorConstants.primaryColor,
//               ),
//             ),
//           ),
//           GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: onAdd,
//             child: SizedBox(
//               width: s(22),
//               height: s(24),
//               child: Center(
//                 child: Icon(
//                   Icons.add,
//                   size: s(14),
//                   color: ColorConstants.primaryColor,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// ///==== above impo



import 'package:flutter/material.dart';
import '../../../../constants/color_constants.dart';
import '../entities/product_entity.dart';

bool isNonVegProduct(ProductEntity product) {
  return product.isVeg == false;
}

const String kVariantIndicatorAsset = 'assets/images/variants_image.png';

class ProductCard extends StatefulWidget {
  final ProductEntity product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final String currencySymbol; // 👈 new parameter

  /// Non-null only for variant products (is_variant == "Yes").
  final VoidCallback? onVariantTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.currencySymbol, // 👈 required
    this.onVariantTap,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  // ─── NEW: tap-debounce guards ────────────────────────────────
  // Fixes: tapping the card multiple times quickly used to open
  // several variant/add-on/modifier bottom sheets stacked on top
  // of each other, and could also fire onAdd twice for one tap.
  DateTime? _lastCardTapTime;
  bool _cardTapLocked = false;

  static const Duration _tapCooldown = Duration(milliseconds: 500);

  void _handleCardTap() {
    final now = DateTime.now();
    if (_cardTapLocked) return;
    if (_lastCardTapTime != null &&
        now.difference(_lastCardTapTime!) < _tapCooldown) {
      return;
    }
    _lastCardTapTime = now;
    _cardTapLocked = true;

    // ── original tap logic, unchanged ──
    if (widget.onVariantTap != null) {
      widget.onVariantTap!();
    } else {
      widget.onAdd();
    }

    Future.delayed(_tapCooldown, () {
      if (mounted) _cardTapLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final quantity = widget.quantity;
    final onAdd = widget.onAdd;
    final onRemove = widget.onRemove;
    final currencySymbol = widget.currencySymbol;
    final onVariantTap = widget.onVariantTap;

    final media = MediaQuery.of(context);

    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    const referenceWidth = 375.0;
    const referenceHeight = 812.0;

    final widthScale = screenWidth / referenceWidth;
    final heightScale = screenHeight / referenceHeight;
    final scale = widthScale < heightScale ? widthScale : heightScale;

    double w(double value) => value * widthScale;
    double h(double value) => value * heightScale;
    double s(double value) => value * scale;

    final nonVeg = isNonVegProduct(product);
    final isVariant = onVariantTap != null;
    final outOfStock = !product.inStock;

    // 👈 NEW: colors get muted when the item is out of stock, to
    // match the greyed-out card look in the reference design.
    final Color vegDotColor = outOfStock
        ? Colors.grey.shade400
        : (nonVeg ? Colors.red : Colors.green);
    final Color cardBackgroundColor =
    outOfStock ? const Color(0xFFE7E7E7) : Colors.white;
    final Color titleColor =
    outOfStock ? Colors.grey.shade400 : Colors.black87;

    // Wrapped in RepaintBoundary so each card repaints independently
    // during scrolling instead of the whole list repainting together
    // — helps with the flicker seen while scrolling the product list.
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: outOfStock ? null : _handleCardTap, // 👈 now debounced
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBackgroundColor, // 👈 greys out when out of stock
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
                Container(
                  width: w(4),
                  decoration: BoxDecoration(
                    color: vegDotColor,
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
                            Container(
                              width: s(14),
                              height: s(14),
                              margin: EdgeInsets.only(top: s(2)),
                              padding: EdgeInsets.all(s(2)),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: vegDotColor,
                                  width: s(1.2),
                                ),
                                borderRadius: BorderRadius.circular(s(3)),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: vegDotColor,
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
                                  color: titleColor, // 👈 greyed when out of stock
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: s(8)),
                        if (outOfStock)
                        // ── NEW: out-of-stock layout, matches reference image ──
                          _OutOfStockBlock(
                            currencySymbol: currencySymbol,
                            price: product.price,
                            s: s,
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  '$currencySymbol${product.price ?? '0.00'}',
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
                              if (isVariant)
                                quantity == 0
                                    ? _VariantIndicatorIcon(size: s(30)) // 👈 NEW image
                                    : Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: s(8),
                                    vertical: s(3),
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorConstants.primaryColor,
                                    borderRadius: BorderRadius.circular(s(6)),
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
      ),
    );
  }
}

/// 👈 NEW: the red "linked circles" variant indicator, loaded from
/// assets/images/variants_image.png. Falls back to a plain icon if
/// the asset is missing so the app never crashes because of it.
class _VariantIndicatorIcon extends StatelessWidget {
  final double size;
  const _VariantIndicatorIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kVariantIndicatorAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: Colors.red,              // 👈 tints the image red regardless of its original color
      colorBlendMode: BlendMode.srcIn, // 👈 applies the tint using the image's alpha shape
      errorBuilder: (context, error, stackTrace) {
        // Safe fallback if the asset isn't registered in pubspec.yaml yet.
        return Icon(
          Icons.dynamic_feed_outlined,
          color: Colors.red,
          size: size,
        );
      },
    );
  }
}

/// 👈 NEW: stacked "Out of Stock" + greyed price block, matching the
/// reference screenshot (red bold "Out of stock" above a muted price).
class _OutOfStockBlock extends StatelessWidget {
  final String currencySymbol;
  final String? price;
  final double Function(double) s;

  const _OutOfStockBlock({
    required this.currencySymbol,
    required this.price,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Out of stock',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: s(14),
          ),
        ),
        SizedBox(height: s(2)),
        Text(
          '$currencySymbol${price ?? '0.00'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
            fontSize: s(15),
          ),
        ),
      ],
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

///==== above impo
