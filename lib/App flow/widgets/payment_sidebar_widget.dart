import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/models/payment/payment_summary_model.dart';

import '../../blocs/Bloc Event/tax_event.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc Logic/tax_bloc.dart';
import '../../blocs/Bloc State/payment_state.dart';
import '../../blocs/Bloc State/tax_state.dart';
import '../../models/tax_model.dart';

class Sidebarwidgets extends StatefulWidget {
  final PaymentSummary paymentSummary;
  final double merchantDiscount;


  const Sidebarwidgets({
    super.key,
    required this.paymentSummary,
    required userPermissions,
    Map<String, dynamic>? selectedUser,
    required this.merchantDiscount,
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
  double? foodRate;
  double? beverageRate;


  double foodCgst = 0;
  double foodSgst = 0;
  double beverageCgst = 0;
  double beverageSgst = 0;
  double totalTax = 0;
  double liquorCgst = 0;
  double liquorSgst = 0;
  double netPayable = 0.0;

  // final merchantDiscount = 0.0;
  double calculatedNetPayable = 0.0;


  // until backend provides it




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
  void _calculateNetPayableOnce() {
    final grossTotal = widget.paymentSummary.grossTotal;
    final couponDiscount = widget.paymentSummary.coupons;
    final merchantDiscount = widget.merchantDiscount.abs();

    final subTotal = grossTotal - couponDiscount;
    final netTotal = subTotal + totalTax; // ✅ uses class totalTax

    setState(() {
      calculatedNetPayable = netTotal - merchantDiscount;
    });
  }


  @override
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightAnimation = Tween<double>(begin: 60, end: 260).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _calculateNetPayableOnce();

    // ✅ LOAD TAX IMMEDIATELY (before expand)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaxBloc>() .add(LoadTaxesEvent());
    });
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
  Widget rightAlignedDottedLine({double width = 120}) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: width, // 👈 controls line length
        child: const DottedLine(
          dashLength: 4,
          dashGapLength: 4,
          lineThickness: 1,
          dashColor: Color(0x66666626),
        ),
      ),
    );
  }



  Widget _row(
      String label,
      double value, {
        bool isBold = false,
        Color? color,
        double fontSize = 14,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// LEFT COLUMN
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// 🔙 Back Button (row 1)
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset("assets/icon/-01.png", width: 18),
                                const SizedBox(width: 8),
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

                        const SizedBox(height: 12),

                        /// 🧾 Order ID (row 2)
                        Text(
                          "Order ID #${widget.paymentSummary.orderId}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),

                    /// RIGHT COLUMN
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        /// 🖨️ Print Button (row 1)
                        Container(
                          width: 90,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.green, // ✅ background
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            "Print",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white, // ✅ text color
                            ),
                          ),
                        ),


                        const SizedBox(height: 12),

                        /// 📅 Date & Time (row 2)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset("assets/icon/calender.png", width: 16),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF656161)),
                            ),
                            const SizedBox(width: 8),
                            Image.asset("assets/icon/clock.png", width: 16),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF656161)),
                            ),
                          ],
                        ),
                      ],
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

            return BlocBuilder<TaxBloc, TaxState>(
              builder: (context, state) {
                if (state is TaxLoaded) {
                  final grossTotal = widget.paymentSummary.grossTotal;
                  final couponDiscount = widget.paymentSummary.coupons;
                  final merchantDiscount = widget.merchantDiscount.abs();
                  final subTotal = grossTotal - couponDiscount;

                  double foodCgst = 0, foodSgst = 0, beverageCgst = 0, beverageSgst = 0;

                  for (final item in widget.paymentSummary.lineItems) {
                    final itemClass = normalizeTaxClass(item.taxClass);

                    final tax = state.taxes.firstWhere(
                          (t) => normalizeTaxClass(t.taxClass) == itemClass,
                      orElse: () => TaxModel(
                        id: 0,
                        rate: "0",
                        name: "",
                        taxClass: "",
                        compound: false,
                        shipping: false,
                      ),
                    );

                    final rate = double.tryParse(tax.rate) ?? 0;
                    if (rate == 0) continue;

                    final halfTax = (item.total * rate / 100) / 2;

                    if (itemClass == 'food') {
                      foodCgst += halfTax;
                      foodSgst += halfTax;
                    } else if (itemClass == 'beverages') {
                      beverageCgst += halfTax;
                      beverageSgst += halfTax;
                    }
                  }

                  final newTotalTax = foodCgst + foodSgst + beverageCgst + beverageSgst;
                  final netTotal = subTotal + newTotalTax;
                  final tempPayable = netTotal - merchantDiscount;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    if (calculatedNetPayable != tempPayable) {
                      setState(() {
                        totalTax = newTotalTax;
                        calculatedNetPayable = tempPayable;
                      });
                    }
                  });
                }

                return const SizedBox.shrink();
              },
            );
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
                final grossTotal = widget.paymentSummary.grossTotal;
                final couponDiscount = widget.paymentSummary.coupons;
                // final merchantDiscount = widget.paymentSummary.discount ?? 0.0;
                // final merchantDiscount = widget.merchantDiscount;
                // double netPayable = widget.paymentSummary.netTotal;
                // final double merchantDiscount = context.select((PaymentBloc bloc) {
                //   return bloc.state is PaymentSummaryLoaded
                //       ? (bloc.state as PaymentSummaryLoaded).merchantDiscount
                //       : 0.0;
                // });
                final double merchantDiscount = widget.merchantDiscount;


                final double backendNetPayable =
                    widget.paymentSummary.netTotal -  widget.merchantDiscount.abs();


// backend not available yet

                final subTotal = grossTotal - couponDiscount;
                // final netPayable = subTotal + totalTax - merchantDiscount;
                // final netTotal = subTotal + totalTax;




                if (state is TaxLoaded) {
                  debugPrint('✅ TaxLoaded → Calculating taxes');

                  double foodCgst = 0;
                  double foodSgst = 0;
                  double beverageCgst = 0;
                  double beverageSgst = 0;
                  // double totalTax = 0;

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
                      if (itemClass == 'liquor-rate') {
                        debugPrint('🍺 LIQUOR ITEM → CGST = 0, SGST = 0');

                        liquorCgst += 0;
                        liquorSgst += 0;
                      } else {
                        debugPrint('⚠️ RATE IS ZERO → skipping item');
                      }
                      continue;
                    }


                    final itemTax = item.total * rate / 100;
                    final halfTax = itemTax / 2;

                    // totalTax += itemTax;

                    debugPrint('🔍 COMPARE → itemClass="$itemClass" | taxClass="$taxClass"');

                    /// 🍽 FOOD
                    if (itemClass == 'food' && taxClass == 'food' && rate > 0) {
                      foodRate ??= rate; // 👈 capture rate ONCE
                      foodCgst += halfTax;
                      foodSgst += halfTax;
                    }


                    /// 🥤 BEVERAGES
                    else if (itemClass == 'beverages' && taxClass == 'beverages' && rate > 0) {
                      beverageRate ??= rate; // 👈 capture rate ONCE
                      beverageCgst += halfTax;
                      beverageSgst += halfTax;
                    }


                    else {
                      debugPrint('❌ TAX CLASS DID NOT MATCH ANY CATEGORY');
                    }
                  }
                  final newTotalTax = foodCgst + foodSgst + beverageCgst + beverageSgst;
                  final netTotal = subTotal + newTotalTax;
                  final tempPayable = netTotal - merchantDiscount.abs();

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      totalTax = newTotalTax;
                      calculatedNetPayable = tempPayable;
                    });
                  });



                  // ✅ FINAL SUMMARY PRINT
                  debugPrint('================ FINAL TAX SUMMARY ================');
                  debugPrint('🍽 Food CGST      : $foodCgst');
                  debugPrint('🍽 Food SGST      : $foodSgst');
                  debugPrint('🥤 Beverage CGST  : $beverageCgst');
                  debugPrint('🥤 Beverage SGST  : $beverageSgst');
                  debugPrint('🍺 Liquor CGST    : $liquorCgst');
                  debugPrint('🍺 Liquor SGST    : $liquorSgst');
                  debugPrint('💰 TOTAL TAX      : $totalTax');
                  debugPrint('===================================================');
                  debugPrint("💙 Showing Merchant Discount in UI = ${widget.merchantDiscount}");

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _row("Gross Total", grossTotal ,isBold: true, fontSize: 15),

                      _row(
                        "Coupon / Discounts",
                        -couponDiscount,
                        color: Colors.green,
                      ),

                      const DottedLine(),

                      _row("Sub Total", subTotal, isBold: true, fontSize: 15),


                      if ((foodCgst > 0 || foodSgst > 0) && foodRate != null) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Tax @${foodRate!.toStringAsFixed(0)}% Food",
                            style: const TextStyle(
                              fontSize: 14,
                              // fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            children: [
                              _row(
                                "CGST ${(foodRate! / 2).toStringAsFixed(1)}%",
                                foodCgst,
                              ),
                              _row(
                                "SGST ${(foodRate! / 2).toStringAsFixed(1)}%",
                                foodSgst,
                              ),
                            ],
                          ),
                        ),
                      ],


                      if ((beverageCgst > 0 || beverageSgst > 0) && beverageRate != null) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Tax @${beverageRate!.toStringAsFixed(0)}% Beverages",
                            style: const TextStyle(
                              fontSize: 14,
                              // fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            children: [
                              _row(
                                "CGST ${(beverageRate! / 2).toStringAsFixed(1)}%",
                                beverageCgst,
                              ),
                              _row(
                                "SGST ${(beverageRate! / 2).toStringAsFixed(1)}%",
                                beverageSgst,
                              ),
                            ],
                          ),
                        ),
                      ],

// ✅ ALWAYS show liquor (even zero)
                      _row(
                        "Tax Alcohol @Nil (Price inclusive of Excise Duty)",
                        0.00,
                      ),

                      rightAlignedDottedLine(width: 140),



                      _row("Total Tax", totalTax, isBold: true),
                      const DottedLine(),

                      _row(
                        "Net Total",
                        netTotal,
                        isBold: true, fontSize: 15

                      ),

                      _row("Merchant Discount", merchantDiscount.abs(), color: Colors.blue),


                      // const DottedLine(),


                      const DottedLine(
                        dashLength: 4,
                        dashGapLength: 4,
                        lineThickness: 1,
                        dashColor: Color(0x66666626),
                      ),

                      _row(
                        "Net Payable",
                        tempPayable,
                        isBold: true,
                        fontSize: 18,
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
                "Net Payable : ${ calculatedNetPayable.toStringAsFixed(2)}",
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