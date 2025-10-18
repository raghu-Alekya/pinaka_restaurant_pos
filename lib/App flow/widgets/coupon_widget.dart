import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Couponscreen extends StatefulWidget {
  const Couponscreen({super.key});

  @override
  State<Couponscreen> createState() => _CouponscreenState();
}

class _CouponscreenState extends State<Couponscreen> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.65,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // add some padding
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start, // align children to start
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 32), // placeholder for spacing
                  Text(
                    "Discount",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.close, color: Colors.white, size: 25),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Description
              Text(
                "Add discounts using a percentage or amount, with an optional reason and real-time total preview",
                style: TextStyle(fontSize: 16, color: Color(0xFF4C5F7D)),
              ),
              SizedBox(height: 20),

              // Coupon code section
              Text(
                "Coupon Code :",
                style: TextStyle(
                  color: Color(0xFF747474),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  // Container wrapping TextFormField
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: "Enter text",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Apply Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Apply"),
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
