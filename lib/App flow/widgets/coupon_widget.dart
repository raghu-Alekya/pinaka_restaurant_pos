import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order/coupon_model.dart';
import '../../repositories/coupon_repository.dart';
import '../../utils/SessionManager.dart';
import '../../utils/theme_provider.dart';

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
  bool _canApplyCoupon = false;

  List<CouponModel> availableCoupons = [];
  bool isLoading = true;
  bool _isApplying = false;
  String _currency = "₹";
  @override
  void initState() {
    super.initState();
    _loadCurrency(); // <-- Add this
    _couponController.addListener(_couponTextChanged);
    // _loadCoupons();
  }

  void _couponTextChanged() {
    final hasText = _couponController.text.trim().isNotEmpty;

    if (_canApplyCoupon != hasText) {
      setState(() {
        _canApplyCoupon = hasText;
      });
    }
  }

  @override
  void dispose() {
    _couponController.removeListener(_couponTextChanged);
    _couponController.dispose();
    super.dispose();
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
      orElse:
          () => CouponModel(
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
        widget.onCouponApplied(code, result.couponAmount);

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message.replaceAll('&quot;', '"')),
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
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDark;

    final size = MediaQuery.of(context).size;

    final dialogWidth = size.width * 0.55;
    final dialogHeight = size.height * 0.40;

    final iconBox = dialogWidth * 0.10;
    final closeButton = dialogWidth * 0.042;
    final buttonWidth = dialogWidth * 0.24;
    final buttonHeight = dialogHeight * 0.18;
    final textFieldHeight = dialogHeight * 0.18;
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFDFDFDF),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            children: [
              /// Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFAB4C),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Image.asset(
                          "assets/Coupon Icon.png",
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Apply Coupon",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF373535),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Apply coupon codes at checkout to instantly redeem discounts and see updated totals in real time.",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color:
                                isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF4C5F7D),
                          ),
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: closeButton,
                      height: closeButton,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF84337),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              /// Coupon Label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Coupon Code :",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// Textfield + Apply Button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: textFieldHeight,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF374151) : Colors.white,
                        border: Border.all(
                          color:
                              isDark
                                  ? const Color(0xFF4B5563)
                                  : const Color(0xFFC1C1C1),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _couponController,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            prefixIcon: const Icon(
                              Icons.local_offer_outlined,
                              color: Colors.grey,
                            ),
                            hintText: "Enter code (e.g. WELCOME50)",
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_isApplying || !_canApplyCoupon)
                              ? null
                              : _applyCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canApplyCoupon
                                ? const Color(0xFF4CAF50)
                                : Colors.grey.shade400,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      icon:
                          _isApplying
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                      label: Text(
                        _isApplying ? "Applying..." : "Apply",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
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
}
