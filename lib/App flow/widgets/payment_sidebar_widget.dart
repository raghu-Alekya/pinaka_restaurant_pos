import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/models/payment/payment_summary_model.dart';

import '../../blocs/Bloc Logic/tax_bloc.dart';
import '../../blocs/Bloc State/tax_state.dart';
import '../../models/tax_model.dart';

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
  double foodTax = 0;
  double beverageTax = 0;

  double foodCgst = 0;
  double foodSgst = 0;
  double beverageCgst = 0;
  double beverageSgst = 0;
  double totalTax = 0;


  @override
  void dispose() {
    _controller.dispose(); // ✅ VERY IMPORTANT
    super.dispose();
  }
  String normalizeTaxClass(String? value) {
    return value
        ?.toLowerCase()
        .trim()
        .replaceAll(' ', '')
        .replaceAll('bewerages', 'beverages') // typo fix
        ?? '';
  }



  /// ✅ CORRECT PLACE
  // Map<String, double> _calculateTaxFromApi(List<TaxModel> taxes) {
  //   double totalTax = 0;
  //   double cgst = 0;
  //   double sgst = 0;
  //
  //   for (final item in widget.paymentSummary.lineItems) {
  //
  //     debugPrint('────────────────────────────────────');
  //     debugPrint('🛒 ITEM NAME     : ${item.name}');
  //     debugPrint('🛒 ITEM TOTAL    : ${item.total}');
  //     debugPrint('🛒 ITEM TAXCLASS : ${item.taxClass}');
  //
  //     final tax = state.taxes.firstWhere(
  //           (t) => t.taxClass == item.taxClass,
  //       orElse: () {
  //         debugPrint('❌ NO TAX MATCH FOUND → using 0%');
  //         return TaxModel(
  //           id: 0,
  //           rate: "0",
  //           name: "",
  //           taxClass: "",
  //           compound: false,
  //           shipping: false,
  //         );
  //       },
  //     );
  //
  //     debugPrint('✅ MATCHED TAX CLASS : ${tax.taxClass}');
  //     debugPrint('✅ MATCHED TAX RATE  : ${tax.rate}%');
  //
  //     final rate = double.tryParse(tax.rate) ?? 0;
  //     debugPrint('🔢 PARSED RATE      : $rate');
  //
  //     if (rate == 0) {
  //       debugPrint('⚠️ RATE IS ZERO → skipping item');
  //       continue;
  //     }
  //
  //     final itemTax = item.total * rate / 100;
  //     final halfTax = itemTax / 2;
  //
  //     debugPrint('💰 ITEM TAX TOTAL   : $itemTax');
  //     debugPrint('💰 HALF TAX (CGST)  : $halfTax');
  //     debugPrint('💰 HALF TAX (SGST)  : $halfTax');
  //
  //     totalTax += itemTax;
  //
  //     final itemClass = item.taxClass.toLowerCase().trim();
  //     final taxClass  = tax.taxClass.toLowerCase().trim();
  //
  //     debugPrint('🔍 COMPARE → itemClass="$itemClass" | taxClass="$taxClass"');
  //
  //     /// 🍽 FOOD
  //     if (itemClass == 'food' && taxClass == 'food') {
  //       foodCgst += halfTax;
  //       foodSgst += halfTax;
  //       debugPrint('🍽 FOOD GST APPLIED');
  //     }
  //
  //     /// 🥤 BEVERAGES
  //     else if (
  //     (itemClass == 'beverages' || itemClass == 'bewerages') &&
  //         (taxClass == 'beverages' || taxClass == 'bewerages')
  //     ) {
  //       beverageCgst += halfTax;
  //       beverageSgst += halfTax;
  //       debugPrint('🥤 BEVERAGE GST APPLIED');
  //     }
  //
  //     else {
  //       debugPrint('❌ TAX CLASS DID NOT MATCH ANY CATEGORY');
  //     }
  //   }
  //
  //   debugPrint('================ FINAL TAX SUMMARY ================');
  //   debugPrint('🍽 Food CGST      : $foodCgst');
  //   debugPrint('🍽 Food SGST      : $foodSgst');
  //   debugPrint('🥤 Beverage CGST  : $beverageCgst');
  //   debugPrint('🥤 Beverage SGST  : $beverageSgst');
  //   debugPrint('💰 TOTAL TAX      : $totalTax');
  //   debugPrint('===================================================');
  //
  //
  //
  //
  //   return {
  //     "total": totalTax,
  //     "cgst": cgst,
  //     "sgst": sgst,
  //   };
  // }





  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _heightAnimation = Tween<double>(begin: 60, end: 260).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // _calculateTaxes();
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
      AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (!_isExpanded) {
            debugPrint('🔽 Tax panel collapsed');
            return const SizedBox.shrink();
          }

          debugPrint('🔼 Tax panel expanded');

          return Padding(
            padding: const EdgeInsets.all(12),
            child: BlocBuilder<TaxBloc, TaxState>(
              builder: (context, state) {

                debugPrint('📦 BlocBuilder state = ${state.runtimeType}');

                if (state is TaxLoading) {
                  debugPrint('⏳ TaxLoading...');
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TaxLoaded) {
                  debugPrint('✅ TaxLoaded → Calculating taxes');

                  double foodCgst = 0;
                  double foodSgst = 0;
                  double beverageCgst = 0;
                  double beverageSgst = 0;
                  double totalTax = 0;

                  for (final item in widget.paymentSummary.lineItems) {
                    debugPrint('────────────────────────────────────');
                    debugPrint('🛒 ITEM NAME     : ${item.name}');
                    debugPrint('🛒 ITEM TOTAL    : ${item.total}');
                    debugPrint('🛒 ITEM TAXCLASS : ${item.taxClass}');

                    // ✅ MUST come FIRST
                    final itemClass = normalizeTaxClass(item.taxClass);

                    debugPrint('🧪 NORMALIZED ITEM CLASS : $itemClass');

                    final tax = state.taxes.firstWhere(
                          (t) => normalizeTaxClass(t.taxClass) == itemClass,
                      orElse: () {
                        debugPrint('❌ NO TAX MATCH FOUND → using 0%');
                        return TaxModel(
                          id: 0,
                          rate: "0",
                          name: "",
                          taxClass: "",
                          compound: false,
                          shipping: false,
                        );
                      },
                    );

                    final taxClass = normalizeTaxClass(tax.taxClass);

                    debugPrint('✅ MATCHED TAX CLASS : $taxClass');
                    debugPrint('✅ MATCHED TAX RATE  : ${tax.rate}%');

                    final rate = double.tryParse(tax.rate) ?? 0;
                    if (rate == 0) {
                      debugPrint('⚠️ RATE IS ZERO → skipping item');
                      continue;
                    }

                    final itemTax = item.total * rate / 100;
                    final halfTax = itemTax / 2;

                    totalTax += itemTax;

                    debugPrint('🔍 COMPARE → itemClass="$itemClass" | taxClass="$taxClass"');

                    /// 🍽 FOOD
                    if (itemClass == 'food' && taxClass == 'food') {
                      foodCgst += halfTax;
                      foodSgst += halfTax;
                      debugPrint('🍽 FOOD GST APPLIED');
                    }

                    /// 🥤 BEVERAGES
                    else if (itemClass == 'bewerages' && taxClass == 'bewerages') {
                      beverageCgst += halfTax;
                      beverageSgst += halfTax;
                      debugPrint('🥤 BEVERAGE GST APPLIED');
                    }

                    else {
                      debugPrint('❌ TAX CLASS DID NOT MATCH ANY CATEGORY');
                    }
                  }


                  // ✅ FINAL SUMMARY PRINT
                  debugPrint('================ FINAL TAX SUMMARY ================');
                  debugPrint('🍽 Food CGST      : $foodCgst');
                  debugPrint('🍽 Food SGST      : $foodSgst');
                  debugPrint('🥤 Beverage CGST  : $beverageCgst');
                  debugPrint('🥤 Beverage SGST  : $beverageSgst');
                  debugPrint('💰 TOTAL TAX      : $totalTax');
                  debugPrint('===================================================');

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _row("Sub Total", widget.paymentSummary.grossTotal),

                      if (foodCgst > 0) _row("Food CGST", foodCgst),
                      if (foodSgst > 0) _row("Food SGST", foodSgst),

                      if (beverageCgst > 0) _row("Beverage CGST", beverageCgst),
                      if (beverageSgst > 0) _row("Beverage SGST", beverageSgst),

                      _row("Total Tax", totalTax, isBold: true),

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
                  );
                }

                if (state is TaxError) {
                  debugPrint('❌ TaxError → ${state.message}');
                  return Text(
                    "Tax error: ${state.message}",
                    style: const TextStyle(color: Colors.red),
                  );
                }

                debugPrint('⚠️ Unknown state');
                return const SizedBox.shrink();
              },
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