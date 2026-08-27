// import 'package:flutter/material.dart';
// import '../../../../constants/color_constants.dart';
// import '../entities/product_entity.dart';
//
// bool isNonVegProduct(ProductEntity product) {
//   return product.isVeg == false;
// }
//
// const String kVariantIndicatorAsset = 'assets/images/variants_image.png';
//
// class ProductCard extends StatefulWidget {
//   final ProductEntity product;
//   final int quantity;
//   final VoidCallback onAdd;
//   final VoidCallback onRemove;
//   final String currencySymbol;
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
//     required this.currencySymbol,
//     this.onVariantTap,
//   }) : super(key: key);
//
//   @override
//   State<ProductCard> createState() => _ProductCardState();
// }
//
// class _ProductCardState extends State<ProductCard> {
//   DateTime? _lastCardTapTime;
//   bool _cardTapLocked = false;
//
//   static const Duration _tapCooldown = Duration(milliseconds: 500);
//
//   void _handleCardTap() {
//     final now = DateTime.now();
//     if (_cardTapLocked) return;
//     if (_lastCardTapTime != null &&
//         now.difference(_lastCardTapTime!) < _tapCooldown) {
//       return;
//     }
//     _lastCardTapTime = now;
//     _cardTapLocked = true;
//
//     if (widget.onVariantTap != null) {
//       widget.onVariantTap!();
//     } else {
//       widget.onAdd();
//     }
//
//     Future.delayed(_tapCooldown, () {
//       if (mounted) _cardTapLocked = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final product = widget.product;
//     final quantity = widget.quantity;
//     final onAdd = widget.onAdd;
//     final onRemove = widget.onRemove;
//     final currencySymbol = widget.currencySymbol;
//     final onVariantTap = widget.onVariantTap;
//
//     final media = MediaQuery.of(context);
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
//     double s(double value) => value * scale;
//
//     final nonVeg = isNonVegProduct(product);
//     final isVariant = onVariantTap != null;
//     final outOfStock = !product.inStock;
//
//     final Color vegDotColor = outOfStock
//         ? Colors.grey.shade400
//         : (nonVeg ? Colors.red : const Color(0xFF2E7D32));
//     final Color cardBackgroundColor =
//     outOfStock ? const Color(0xFFEDEDED) : Colors.white;
//     final Color titleColor =
//     outOfStock ? Colors.grey.shade400 : Colors.black87;
//
//     return RepaintBoundary(
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: outOfStock ? null : _handleCardTap,
//         child: Container(
//           width: double.infinity,
//           // 👈 taller, roomier card — no left color strip, matches the Figma card
//           padding: EdgeInsets.all(s(16)),
//           decoration: BoxDecoration(
//             color: cardBackgroundColor,
//             borderRadius: BorderRadius.circular(s(14)),
//             border: Border.all(
//               color: Colors.grey.shade200,
//               width: s(1),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.04),
//                 blurRadius: s(6),
//                 offset: Offset(0, s(2)),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ── Veg/Non-veg icon + title ──
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     width: s(18),
//                     height: s(15),
//                     margin: EdgeInsets.only(top: s(3)),
//                     padding: EdgeInsets.all(s(2.5)),
//                     decoration: BoxDecoration(
//                       border: Border.all(
//                         color: vegDotColor,
//                         width: s(1.4),
//                       ),
//                       borderRadius: BorderRadius.circular(s(4)),
//                     ),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: vegDotColor,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: s(8)),
//                   Expanded(
//                     child: Text(
//                       product.name,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w700,
//                         fontSize: s(16), // 👈 bumped up to match the design
//                         height: 1.2,
//                         color: titleColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: s(14)),
//
//               // ── Price + action ──
//               if (outOfStock)
//                 _OutOfStockBlock(
//                   currencySymbol: currencySymbol,
//                   price: product.price,
//                   s: s,
//                 )
//               else
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Flexible(
//                       child: Text(
//                         '$currencySymbol${product.price ?? '0.00'}',
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: ColorConstants.primaryColor,
//                           fontWeight: FontWeight.bold,
//                           fontSize: s(17), // 👈 bumped up to match the design
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: s(8)),
//                     if (isVariant)
//                       quantity == 0
//                           ? _VariantIndicatorIcon(size: s(18))
//                           : Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: s(10),
//                           vertical: s(4),
//                         ),
//                         decoration: BoxDecoration(
//                           color: ColorConstants.primaryColor,
//                           borderRadius: BorderRadius.circular(s(8)),
//                         ),
//                         child: Text(
//                           '$quantity',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: s(13),
//                           ),
//                         ),
//                       )
//                     else if (quantity == 0)
//                       GestureDetector(
//                         behavior: HitTestBehavior.opaque,
//                         onTap: outOfStock ? null : onAdd,
//                         child: Icon(
//                           Icons.add_circle,
//                           color: ColorConstants.primaryColor,
//                           size: s(30), // 👈 bumped up to match the design
//                         ),
//                       )
//                     else
//                       _CompactStepper(
//                         quantity: quantity,
//                         onAdd: onAdd,
//                         onRemove: onRemove,
//                         scale: scale,
//                       ),
//                   ],
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _VariantIndicatorIcon extends StatelessWidget {
//   final double size;
//   const _VariantIndicatorIcon({required this.size});
//
//   @override
//   Widget build(BuildContext context) {
//     return Image.asset(
//       kVariantIndicatorAsset,
//       width: size,
//       height: size,
//       fit: BoxFit.contain,
//       color: Colors.red,
//       colorBlendMode: BlendMode.srcIn,
//       errorBuilder: (context, error, stackTrace) {
//         return Icon(
//           Icons.dynamic_feed_outlined,
//           color: Colors.red,
//           size: size,
//         );
//       },
//     );
//   }
// }
//
// class _OutOfStockBlock extends StatelessWidget {
//   final String currencySymbol;
//   final String? price;
//   final double Function(double) s;
//
//   const _OutOfStockBlock({
//     required this.currencySymbol,
//     required this.price,
//     required this.s,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Out of stock',
//           style: TextStyle(
//             color: Colors.red,
//             fontWeight: FontWeight.bold,
//             fontSize: s(15), // 👈 bumped up to match the design
//           ),
//         ),
//         SizedBox(height: s(3)),
//         Text(
//           '$currencySymbol${price ?? '0.00'}',
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: TextStyle(
//             color: Colors.grey.shade400,
//             fontWeight: FontWeight.bold,
//             fontSize: s(17), // 👈 bumped up to match the design
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// /// Responsive compact stepper — same logic, slightly bigger to match the new card size.
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
//       height: s(30), // was 24
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(s(8)),
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
//               width: s(28), // was 22
//               height: s(30),
//               child: Center(
//                 child: Icon(
//                   Icons.remove,
//                   size: s(16), // was 14
//                   color: ColorConstants.primaryColor,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(
//             width: s(22), // was 18
//             child: Text(
//               '$quantity',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: s(14), // was 12
//                 fontWeight: FontWeight.bold,
//                 color: ColorConstants.primaryColor,
//               ),
//             ),
//           ),
//           GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: onAdd,
//             child: SizedBox(
//               width: s(28), // was 22
//               height: s(30),
//               child: Center(
//                 child: Icon(
//                   Icons.add,
//                   size: s(16), // was 14
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
  final String currencySymbol;

  /// Non-null only for variant products (is_variant == "Yes").
  final VoidCallback? onVariantTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.currencySymbol,
    this.onVariantTap,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
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

    double s(double value) => value * scale;

    final nonVeg = isNonVegProduct(product);
    final isVariant = onVariantTap != null;
    final outOfStock = !product.inStock;

    final Color vegDotColor = outOfStock
        ? Colors.grey.shade400
        : (nonVeg ? Colors.red : const Color(0xFF2E7D32));
    final Color cardBackgroundColor =
    outOfStock ? const Color(0xFFEDEDED) : Colors.white;
    final Color titleColor =
    outOfStock ? Colors.grey.shade400 : Colors.black87;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: outOfStock ? null : _handleCardTap,
        child: Container(
          width: double.infinity,
          // ↓ reduced padding so more room for content
          padding: EdgeInsets.fromLTRB(s(12), s(12), s(12), s(10)),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(s(14)),
            border: Border.all(
              color: Colors.grey.shade200,
              width: s(1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: s(6),
                offset: Offset(0, s(2)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // title top, price bottom
            children: [
              // ── Title – FIXED height for exactly 2 lines ──
              // This guarantees the 2nd line is never cut
              // and all cards have the price at the same vertical level
              SizedBox(
                height: s(36), // ≈ fontSize 15 * height 1.2 * 2 lines
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: s(16),
                      height: s(14),
                      margin: EdgeInsets.only(top: s(2)),
                      padding: EdgeInsets.all(s(2)),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: vegDotColor,
                          width: s(1.3),
                        ),
                        borderRadius: BorderRadius.circular(s(3.5)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: vegDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: s(7)),
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: s(15),          // slightly smaller = safer
                          height: 1.2,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              if (outOfStock)
              // Compact single-line style so it matches the height of the normal row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Out of stock',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: s(12),
                            ),
                          ),
                          Text(
                            '$currencySymbol${product.price ?? '0.00'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: s(15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // empty space on the right so price stays left-aligned like other cards
                    SizedBox(width: s(28)), // same approximate width as the add icon
                  ],
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
                          fontSize: s(16),
                        ),
                      ),
                    ),
                    SizedBox(width: s(6)),
                    if (isVariant)
                      quantity == 0
                          ? _VariantIndicatorIcon(size: s(13))
                          : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: s(9),
                          vertical: s(3),
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor,
                          borderRadius: BorderRadius.circular(s(7)),
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
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onAdd,
                        child: Icon(
                          Icons.add_circle,
                          color: ColorConstants.primaryColor,
                          size: s(28),
                        ),
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

              // ── Price + action (always pinned to bottom) ──
              // if (outOfStock)
              //   _OutOfStockBlock(
              //     currencySymbol: currencySymbol,
              //     price: product.price,
              //     s: s,
              //   )
              // else
              //   Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     crossAxisAlignment: CrossAxisAlignment.center,
              //     children: [
              //       Flexible(
              //         child: Text(
              //           '$currencySymbol${product.price ?? '0.00'}',
              //           maxLines: 1,
              //           overflow: TextOverflow.ellipsis,
              //           style: TextStyle(
              //             color: ColorConstants.primaryColor,
              //             fontWeight: FontWeight.bold,
              //             fontSize: s(16),
              //           ),
              //         ),
              //       ),
              //       SizedBox(width: s(6)),
              //       if (isVariant)
              //         quantity == 0
              //             ? _VariantIndicatorIcon(size: s(13))
              //             : Container(
              //           padding: EdgeInsets.symmetric(
              //             horizontal: s(9),
              //             vertical: s(3),
              //           ),
              //           decoration: BoxDecoration(
              //             color: ColorConstants.primaryColor,
              //             borderRadius: BorderRadius.circular(s(7)),
              //           ),
              //           child: Text(
              //             '$quantity',
              //             style: TextStyle(
              //               color: Colors.white,
              //               fontWeight: FontWeight.bold,
              //               fontSize: s(12),
              //             ),
              //           ),
              //         )
              //       else if (quantity == 0)
              //         GestureDetector(
              //           behavior: HitTestBehavior.opaque,
              //           onTap: outOfStock ? null : onAdd,
              //           child: Icon(
              //             Icons.add_circle,
              //             color: ColorConstants.primaryColor,
              //             size: s(28),               // slightly smaller
              //           ),
              //         )
              //       else
              //         _CompactStepper(
              //           quantity: quantity,
              //           onAdd: onAdd,
              //           onRemove: onRemove,
              //           scale: scale,
              //         ),
              //     ],
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      color: Colors.red,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.dynamic_feed_outlined,
          color: Colors.red,
          size: size,
        );
      },
    );
  }
}

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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Out of stock',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: s(15),
          ),
        ),
        SizedBox(height: s(3)),
        Text(
          '$currencySymbol${price ?? '0.00'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
            fontSize: s(17),
          ),
        ),
      ],
    );
  }
}

/// Responsive compact stepper — same logic, slightly bigger to match the new card size.
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
      height: s(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(8)),
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
              width: s(28),
              height: s(30),
              child: Center(
                child: Icon(
                  Icons.remove,
                  size: s(16),
                  color: ColorConstants.primaryColor,
                ),
              ),
            ),
          ),
          SizedBox(
            width: s(22),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: s(14),
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryColor,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAdd,
            child: SizedBox(
              width: s(28),
              height: s(30),
              child: Center(
                child: Icon(
                  Icons.add,
                  size: s(16),
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