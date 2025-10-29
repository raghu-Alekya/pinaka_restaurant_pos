import 'package:flutter/material.dart';

class Couponscreen extends StatefulWidget {
  final Function(String) onCouponApplied;

  const Couponscreen({super.key, required this.onCouponApplied});

  @override
  State<Couponscreen> createState() => _CouponscreenState();
}

class _CouponscreenState extends State<Couponscreen> {
  final TextEditingController _couponController = TextEditingController();

  final List<String> availableCoupons = [
    "WELCOME10",
    "FOODIE20",
    "HAPPYHOUR15",
    "FESTIVE50",
  ];

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
                      onPressed: () {
                        // apply coupon
                        widget.onCouponApplied(_couponController.text);
                        Navigator.of(context).pop(true); // return true
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4C5F7D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        "Apply coupon",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Available coupons horizontal list
              SizedBox(
                height: 30,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableCoupons.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        _couponController.text = availableCoupons[index];
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        padding:
                        EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Color(0xFF4C81F1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            availableCoupons[index],
                            style:
                            TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
