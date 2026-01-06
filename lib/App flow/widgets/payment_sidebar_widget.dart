import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/models/payment/payment_summary_model.dart';

class Sidebarwidgets extends StatefulWidget {
  final PaymentSummary paymentSummary;

  const Sidebarwidgets({
    super.key,
    required this.paymentSummary,
    required userPermissions,
    Map<String, dynamic>? selectedUser,
  });

  @override
  State<Sidebarwidgets> createState() => _SidebarwidgetsState();
}


class _SidebarwidgetsState extends State<Sidebarwidgets>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void dispose() {
    _controller.dispose(); // ✅ VERY IMPORTANT
    super.dispose();
  }



  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _heightAnimation = Tween<double>(begin: 60, end: 260).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _toggleExpand() {
    if (!mounted) return; // ✅ REQUIRED

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Widget _row(String label, double value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: isBold ? FontWeight.w600 : null),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : null,
            color: color,
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("EEEE, dd MMM yyyy").format(now);
    String formattedTime = DateFormat("hh:mm a").format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F6),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 16, right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- Header Section ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!mounted) return;
                        Navigator.pop(context);
                      },

                      child: Container(
                        width: 90,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEE8FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/icon/-01.png",
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Back",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF585A5C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ---- Date & Time ----
                    Row(
                      children: [
                        Image.asset("assets/icon/calender.png", width: 18, height: 18),
                        const SizedBox(width: 3),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF656161),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset("assets/icon/clock.png", width: 18, height: 18),
                        const SizedBox(width: 3),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF656161),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order ID #${widget.paymentSummary.orderId}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Text(
                      "Payment Summary",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF656161),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ---------- Items Container ----------

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEE8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [

                        // 🔴 HEADER ROW
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5A5A), // Red header
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Expanded(
                                child: Text(
                                  'Item Name',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                'Units',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 98),
                              Text(
                                'Price',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 📜 LIST ITEMS
                        Expanded(
                          child: ListView.builder(
                            itemCount: widget.paymentSummary.lineItems.length,
                            itemBuilder: (context, index) {
                              final item = widget.paymentSummary.lineItems[index];

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${item.qty} × ${(item.qty > 0 ? item.total / item.qty : 0).toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 80),
                                        Text(
                                          item.total.toStringAsFixed(2),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    color: Color(0xFFE6E7E8),
                                    thickness: 1,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60), // space for bottom toggle container
              ],
            ),
          ),


          // ---------- Fixed Bottom Toggle Container ----------
          Align(
          alignment: Alignment.bottomCenter,
          child: Container(
          width: MediaQuery.of(context).size.width * 0.315,
          margin: const EdgeInsets.only( bottom: 8),
          decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
          BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, -2),
          ),
          ],
          ),
          child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [

    /// 🔼 EXPANDABLE PART (Animated)
      /// 🔼 EXPANDABLE PART (Animated)
      /// 🔼 EXPANDABLE PART (Animated)
      AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (!_isExpanded) {
            // ✅ NO SPACE when collapsed
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // const Divider(height: 1),

                _row("Sub Total", widget.paymentSummary.grossTotal),
                _row("Tax", widget.paymentSummary.tax),
                _row(
                  "Discount",
                  -widget.paymentSummary.discount,
                  color: Colors.blue,
                ),

                const DottedLine(
                  dashLength: 4,
                  dashGapLength: 4,
                  lineThickness: 1,
                  dashColor: Color(0x66666626),
                ),

                _row(
                  "Total",
                  widget.paymentSummary.netTotal,
                  isBold: true,
                ),
              ],
            ),
          );
        },
      ),




      /// 🔽 FIXED BOTTOM (Never moves)
      GestureDetector(
        onTap: _toggleExpand,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFDEE8FF), // SAME COLOR AS IMAGE
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              /// TOTAL ITEMS
              Text(
                "Total Items : ${widget.paymentSummary.lineItems.length}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              const Spacer(),

              /// NET PAYABLE
              Text(
                "Net Payable : ${widget.paymentSummary.netTotal.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(width: 6),

              /// TOGGLE ICON (ONLY HERE)
              Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                size: 22,
              ),
            ],
          ),
        ),
      ),

    ],
    ),
    ),
    ),

        ],
      ),
    );
  }
}