import 'package:flutter/material.dart';

import '../../models/order/coupon_model.dart';
import '../../repositories/coupon_repository.dart';
import '../../utils/SessionManager.dart';

class Couponscreen extends StatefulWidget {
  final Function(String, double) onCouponApplied;
  final int orderId;
  final String token;

  const Couponscreen({
    super.key,
    required this.onCouponApplied,
    required this.orderId,
    required this.token,
  });


  @override
  State<Couponscreen> createState() => _CouponscreenState();
}




class _CouponscreenState extends State<Couponscreen> {
  final TextEditingController _couponController = TextEditingController();
  final CouponRepository _couponRepository = CouponRepository();


  List<CouponModel> availableCoupons = [];
  bool isLoading = true;
  bool _isApplying = false;
  String _currency = "₹";
  @override
  void initState() {
    super.initState();
    _loadCurrency();   // <-- Add this
    // _loadCoupons();
  }
  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }
  // Future<void> _loadCoupons() async {
  //   final repository = CouponRepository();
  //
  //   final coupons = await repository.fetchCoupons();
  //
  //   if (!mounted) return;
  //
  //   setState(() {
  //     availableCoupons = coupons;
  //     isLoading = false;
  //   });
  // }
  Future<void> _applyCoupon() async {
    if (_couponController.text.trim().isEmpty) return;

    setState(() {
      _isApplying = true;
    });

    final code = _couponController.text.trim();

    final selectedCoupon = availableCoupons.firstWhere(
          (c) => c.code.trim().toLowerCase() == code.toLowerCase(),
      orElse: () => CouponModel(
        id: 0,
        code: code,
        description: '',
        discountType: 'fixed_cart',
        amount: 0.0,
      ),
    );

    try {
      final result = await _couponRepository.applyCoupon(
        token: widget.token,
        orderId: widget.orderId,
        couponCode: code,
      );

      if (!mounted) return;

      if (result.success) {
        widget.onCouponApplied(
          code,
          result.couponAmount,
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.replaceAll('&quot;', '"'),

            ),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 900,
        height: 400,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "COUPON",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Add discounts using a percentage or amount with optional reason and real-time total review.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF4C5F7D)),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child:
                          Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Coupon input row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextFormField(
                        controller: _couponController,
                        decoration: const InputDecoration(
                          hintText: "Enter coupon code",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isApplying ? null : _applyCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C5F7D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: _isApplying
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        "Apply Coupon",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Available coupons horizontal list
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableCoupons.length,
                  itemBuilder: (context, index) {
                    final coupon = availableCoupons[index];

                    return InkWell(
                      onTap: () {
                        _couponController.text = coupon.code;
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C81F1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              coupon.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              coupon.discountType == 'percent'
                                  ? '${coupon.amount}% OFF'
                                  : '$_currency${coupon.amount.toInt()} OFF',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}