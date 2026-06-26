import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/models/payment/payment_summary_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';

import '../../blocs/Bloc Event/tax_event.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc Logic/tax_bloc.dart';
import '../../blocs/Bloc State/payment_state.dart';
import '../../blocs/Bloc State/tax_state.dart';
import '../../models/tax_model.dart';
import '../../printer/printer_db_helper.dart';
import '../../printer/printer_settings.dart';
import '../../repositories/ordertype_payment.dart';

class Sidebarwidgets extends StatefulWidget {
  final PaymentSummary paymentSummary;
  final double merchantDiscount;
  final bool hasCouponApplied;
  final bool hasDiscountApplied;
  final double tipAmount;
  final double appliedCouponAmount;
  final String token;
  final ValueChanged<double>? onNetPayableChanged;

  const Sidebarwidgets({
    super.key,
    required this.paymentSummary,
    required userPermissions,
    Map<String, dynamic>? selectedUser,
    required this.merchantDiscount,
    required this.tipAmount,
    required this.appliedCouponAmount, // 👈 ADD THIS
    this.hasCouponApplied = false,
    this.hasDiscountApplied = false,
    required this.token,
    this.onNetPayableChanged,
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
  // order type
  List<String> orderTypes = [];
  String? selectedOrderType;

  // service charges
  double serviceChargeAmount = 0.0;
  String? selectedServiceCharge;

  // until backend provides it

  @override
  void didUpdateWidget(covariant Sidebarwidgets oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tipAmount != widget.tipAmount ||
        oldWidget.appliedCouponAmount != widget.appliedCouponAmount ||
        oldWidget.merchantDiscount != widget.merchantDiscount) {
      debugPrint(
        "Coupon Changed: ${oldWidget.appliedCouponAmount} -> ${widget.appliedCouponAmount}",
      );

      final taxState = context.read<TaxBloc>().state;

      if (taxState is TaxLoaded) {
        _calculateTaxAndPayable(taxState);
      } else {
        _calculateInitialPayable();
        setState(() {});
      }
    }
    {
      final taxState = context.read<TaxBloc>().state;

      if (taxState is TaxLoaded) {
        _calculateTaxAndPayable(taxState);
      }

      debugPrint(
        "💰 Tip changed: ${oldWidget.tipAmount} -> ${widget.tipAmount}",
      );
    }
  }

  void _calculateInitialPayable() {
    final grossTotal = widget.paymentSummary.grossTotal;
    final couponDiscount =
        widget.paymentSummary.coupons > 0
            ? widget.paymentSummary.coupons
            : widget.appliedCouponAmount;

    final merchantDiscount = widget.merchantDiscount.abs();

    calculatedNetPayable =
        grossTotal -
        couponDiscount -
        merchantDiscount +
        widget.paymentSummary.serviceChargeValue +
        widget.tipAmount;

    debugPrint(
      "Service Charge value : ${widget.paymentSummary.serviceChargeValue}",
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onNetPayableChanged?.call(calculatedNetPayable);
      }
    });
  }

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
            ??
        '';
  }

  // void _calculateNetPayableOnce() {
  //   final grossTotal = widget.paymentSummary.grossTotal;
  //   final couponDiscount = widget.paymentSummary.coupons;
  //   final merchantDiscount = widget.merchantDiscount.abs();
  //
  //   final subTotal = grossTotal - couponDiscount;
  //   final netTotal = subTotal + totalTax; // ✅ uses class totalTax
  //
  //   setState(() {
  //     calculatedNetPayable = netTotal - merchantDiscount;
  //   });
  // }
  void _calculateTaxAndPayable(TaxLoaded state) {
    double foodCgstTemp = 0;
    double foodSgstTemp = 0;
    double beverageCgstTemp = 0;
    double beverageSgstTemp = 0;

    for (final item in widget.paymentSummary.lineItems) {
      final itemClass = normalizeTaxClass(item.taxClass);

      final tax = state.taxes.firstWhere(
        (t) => normalizeTaxClass(t.taxClass) == itemClass,
        orElse:
            () => TaxModel(
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

      final itemTax = item.calculatedTax(
        modifiersTaxable: widget.paymentSummary.modifiersTaxable,
      );

      final halfTax = itemTax / 2;

      if (itemClass == 'food') {
        foodRate ??= rate;
        foodCgstTemp += halfTax;
        foodSgstTemp += halfTax;
      } else if (itemClass == 'beverages') {
        beverageRate ??= rate;
        beverageCgstTemp += halfTax;
        beverageSgstTemp += halfTax;
      }
    }

    final grossTotal = widget.paymentSummary.grossTotal;
    final couponDiscount =
        widget.paymentSummary.coupons > 0
            ? widget.paymentSummary.coupons
            : widget.appliedCouponAmount;
    final merchantDiscount = widget.merchantDiscount.abs();
    final tipAmount = widget.tipAmount;
    final serviceCharge = widget.paymentSummary.serviceChargeValue;

    final subTotal = grossTotal - couponDiscount;
    final totalTaxTemp =
        foodCgstTemp + foodSgstTemp + beverageCgstTemp + beverageSgstTemp;

    final netPayableTemp =
        subTotal + totalTaxTemp - merchantDiscount + tipAmount + serviceCharge;
    debugPrint("""
Gross Total      : $grossTotal
Coupon Discount  : $couponDiscount
Total Tax        : $totalTaxTemp
Merchant Discount: $merchantDiscount
Tip Amount       : $tipAmount
Net Payable      : $netPayableTemp
""");

    setState(() {
      foodCgst = foodCgstTemp;
      foodSgst = foodSgstTemp;
      beverageCgst = beverageCgstTemp;
      beverageSgst = beverageSgstTemp;
      totalTax = totalTaxTemp;
      calculatedNetPayable = netPayableTemp;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onNetPayableChanged?.call(calculatedNetPayable);
      }
    });
  }

  Future<void> printBill({
    required String orderId,
    required String tableName,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required double grossTotal,
    required double couponDiscount,
    required double merchantDiscount,
    required double tipAmount,
    required double taxAmount,
    required double netPayable,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      debugPrint("store_name => ${prefs.getString('store_name')}");
      debugPrint("store_address => ${prefs.getString('store_address')}");
      debugPrint("store_phone => ${prefs.getString('store_phone')}");
      debugPrint("store_gst => ${prefs.getString('store_gst')}");

      final restaurantName =
          prefs.getString('store_name') ?? 'Restaurant';

      final address =
          prefs.getString('store_address') ?? '';

      final phone =
          prefs.getString('store_phone') ?? '';

      final gstNumber =
          prefs.getString('store_gst') ?? '';

      List<int> bytes = [];

      final profile =
      await CapabilityProfile.load(name: 'XP-N160I');

      final generator = Generator(
        PaperSize.mm80,
        profile,
      );

      // =========================
      // Restaurant Header
      // =========================

      // =========================
// HEADER
// =========================

      bytes += generator.text(
        "**** CUST-INVOICE ****",
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      );

      bytes += generator.text(
        restaurantName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );

      if (address.isNotEmpty) {
        bytes += generator.text(
          address,
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
      }

      if (gstNumber.isNotEmpty) {
        bytes += generator.text(
          "GSTIN: $gstNumber",
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
      }

      if (phone.isNotEmpty) {
        bytes += generator.text(
          "Ph: $phone",
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        );
      }

      bytes += generator.hr();

      // customer detail

      // bytes += generator.text(
      //   "Name : ${customerName ?? '-'}",
      // );

      bytes += generator.row([
        PosColumn(
          width: 6,
          text: "Date : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
        ),
        PosColumn(
          width: 6,
          text: "Dine In : $tableName",
          styles: const PosStyles(
            align: PosAlign.right,
          ),
        ),
      ]);

      bytes += generator.row([
        PosColumn(
          width: 6,
          text: "Cashier : $cashierName",
        ),
        PosColumn(
          width: 6,
          text: "Order Id : $orderId",
          styles: const PosStyles(
            align: PosAlign.right,
          ),
        ),
      ]);

      bytes += generator.hr();

      // =========================
      // Item Header
      // =========================

      bytes += generator.row([
        PosColumn(
          width: 6,
          text: "Item Name",
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          width: 2,
          text: "Qty",
          styles: const PosStyles(
            bold: true,
            align: PosAlign.center,
          ),
        ),
        PosColumn(
          width: 2,
          text: "Price",
          styles: const PosStyles(
            bold: true,
            align: PosAlign.right,
          ),
        ),
        PosColumn(
          width: 2,
          text: "Amount",
          styles: const PosStyles(
            bold: true,
            align: PosAlign.right,
          ),
        ),
      ]);

      bytes += generator.hr();
      // =========================
      // Items
      // =========================

      for (final item in items) {
        bytes += generator.row([
          PosColumn(width: 6, text: item['name'].toString()),
          PosColumn(
            width: 2,
            text: item['qty'].toString(),
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            width: 2,
            text: double.parse(item['price'].toString()).toStringAsFixed(2),
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            width: 2,
            text: double.parse(item['amount'].toString()).toStringAsFixed(2),
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        // Print modifiers
        if (item['modifiers'] != null &&
            (item['modifiers'] as List).isNotEmpty) {

          for (final modifier in (item['modifiers'] as List)) {
            bytes += generator.text(
              "   + $modifier",
              styles: const PosStyles(
                align: PosAlign.left,
              ),
            );
          }
        }
      }

      bytes += generator.hr();

      // =========================
      // Summary
      // =========================

      bytes += generator.row([
        PosColumn(width: 8, text: "Gross Total"),
        PosColumn(
          width: 4,
          text: grossTotal.toStringAsFixed(2),
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

// Coupon
      if (couponDiscount > 0) {
        bytes += generator.row([
          PosColumn(width: 8, text: "Coupon"),
          PosColumn(
            width: 4,
            text: "-${couponDiscount.toStringAsFixed(2)}",
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

// Merchant Discount
      if (merchantDiscount != 0) {
        bytes += generator.row([
          PosColumn(
            width: 8,
            text: "Merchant Discount",
          ),
          PosColumn(
            width: 4,
            text: merchantDiscount.toStringAsFixed(2),
            styles: const PosStyles(
              align: PosAlign.right,
            ),
          ),
        ]);
      }

// Tax
      if (taxAmount > 0) {
        final cgst = taxAmount / 2;
        final sgst = taxAmount / 2;

        bytes += generator.row([
          PosColumn(width: 8, text: "CGST @ 2.5%"),
          PosColumn(
            width: 4,
            text: cgst.toStringAsFixed(2),
            styles: const PosStyles(
              align: PosAlign.right,
            ),
          ),
        ]);

        bytes += generator.row([
          PosColumn(width: 8, text: "SGST @ 2.5%"),
          PosColumn(
            width: 4,
            text: sgst.toStringAsFixed(2),
            styles: const PosStyles(
              align: PosAlign.right,
            ),
          ),
        ]);
      }

// Service Charge
      if (widget.paymentSummary.serviceChargeValue > 0) {
        bytes += generator.row([
          PosColumn(width: 8, text: "Service Charge"),
          PosColumn(
            width: 4,
            text: widget.paymentSummary.serviceChargeValue.toStringAsFixed(2),
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

// Tip
      if (tipAmount > 0) {
        bytes += generator.row([
          PosColumn(width: 8, text: "Tip"),
          PosColumn(
            width: 4,
            text: tipAmount.toStringAsFixed(2),
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      bytes += generator.hr();

      final grandTotal = netPayable.roundToDouble();
      final roundOff = grandTotal - netPayable;

      bytes += generator.row([
        PosColumn(
          width: 8,
          text: "Round Off",
        ),
        PosColumn(
          width: 4,
          text: roundOff.toStringAsFixed(2),
          styles: const PosStyles(
            align: PosAlign.right,
          ),
        ),
      ]);

      bytes += generator.hr();

      bytes += generator.row([
        PosColumn(
          width: 8,
          text: "Grand Total",
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
          ),
        ),
        PosColumn(
          width: 4,
          text: grandTotal.toStringAsFixed(2),
          styles: const PosStyles(
            bold: true,
            align: PosAlign.right,
            height: PosTextSize.size2,
          ),
        ),
      ]);
      bytes += generator.hr();

      bytes += generator.text(
        "Thank You Visit Again..!!",
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      );

      bytes += generator.text(
        "Service charge is optional",
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
      bytes += generator.feed(2);
      bytes += generator.cut();

      final printerSettings = PrinterSettings();

      await printerSettings.loadPrinter();

      if (printerSettings.selectedPrinter == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No printer selected"),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      await printerSettings.printTicket(
        bytes,
        generator,
      );
    } catch (e) {
      debugPrint("Print Bill Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadOrderTypes();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightAnimation = Tween<double>(
      begin: 60,
      end: 260,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    selectedServiceCharge =
        widget.paymentSummary.serviceChargePercentage.toString();

    serviceChargeAmount = widget.paymentSummary.serviceChargeValue;

    debugPrint(
      "Service Charge %: ${widget.paymentSummary.serviceChargePercentage}",
    );

    debugPrint(
      "Service Charge Value: ${widget.paymentSummary.serviceChargeValue}",
    );

    _calculateInitialPayable();

    // ✅ LOAD TAX IMMEDIATELY (before expand)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaxBloc>().add(LoadTaxesEvent());
    });
  }

  Future<void> loadOrderTypes() async {
    try {
      debugPrint("══════════════════════════════");
      debugPrint("🚀 loadOrderTypes Started");
      debugPrint("🚀 Token: ${widget.token}");

      final repo = OrderTypesInPaymentScreenRepository();

      final result = await repo.getOrderTypes(token: widget.token);

      debugPrint("🟡 API Result: $result");

      if (result != null && mounted) {
        setState(() {
          orderTypes = result.orderTypes;
          selectedOrderType = null;
        });
        debugPrint("✅ Order Types Count: ${orderTypes.length}");
        debugPrint("✅ Order Types: $orderTypes");
        debugPrint("✅ Selected Type: $selectedOrderType");
      } else {
        debugPrint("❌ Result is NULL");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Order Types Error: $e");
      debugPrint("$stackTrace");
    }
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
        bool showNegative = false,
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
            "${showNegative || value < 0 ? '-₹' : '₹'}${value.abs().toStringAsFixed(2)}",
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
    return BlocListener<TaxBloc, TaxState>(
      listener: (context, state) {
        if (state is TaxLoaded) {
          _calculateTaxAndPayable(state); // ✅ CALCULATE IMMEDIATELY
        }
      },

      child: Scaffold(
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
                              if (widget.hasCouponApplied) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Remove coupon first"),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                return;
                              }
                              if (widget.hasDiscountApplied) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Remove discount first"),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                return;
                              }
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              /// Print Button Only
                              InkWell(
                                onTap: () async {
                                  debugPrint("PRINT BUTTON TAPPED");

                                  final printers =
                                  await PrinterDBHelper().getPrinterFromDB();

                                  debugPrint("Saved Printers => $printers");

                                  final printItems = widget.paymentSummary.lineItems.map((item) {
                                    return {
                                      "name": item.name,
                                      "qty": item.qty,
                                      "price": item.price,
                                      "amount": item.total.toStringAsFixed(2),
                                      "modifiers": item.modifiers,
                                    };
                                  }).toList();

                                  await printBill(
                                    orderId: widget.paymentSummary.orderId.toString(),
                                    tableName: widget.paymentSummary.tableName,
                                    cashierName: "Admin",
                                    items: printItems,
                                    // modifiers: item.modifiers,
                                    grossTotal: widget.paymentSummary.grossTotal,
                                    couponDiscount: widget.paymentSummary.coupons,
                                    merchantDiscount: widget.paymentSummary.discount,
                                    tipAmount: widget.paymentSummary.tipAmount,
                                    taxAmount: widget.paymentSummary.tax,
                                    netPayable: widget.paymentSummary.netTotal,
                                  );
                                },
                                child: Container(
                                  width: 90,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Text(
                                    "Print",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              /// Order Type Dropdown (No InkWell)
                              Container(
                                width: 165,
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FBFF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE6E6E6),
                                    width: 1,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedOrderType,
                                    isExpanded: true,
                                    hint: const Text("Dine In"),
                                    items:
                                        orderTypes.map((type) {
                                          return DropdownMenuItem<String>(
                                            value: type,
                                            child: Text(type),
                                          );
                                        }).toList(),
                                    onChanged: (value) async {
                                      if (value == null) return;

                                      setState(() {
                                        selectedOrderType = value;
                                      });

                                      final result =
                                          await OrderTypesInPaymentScreenRepository()
                                              .updateOrderType(
                                                token: widget.token,
                                                orderId:
                                                    widget
                                                        .paymentSummary
                                                        .orderId,
                                                orderType: value,
                                              );

                                      if (result?.success == true) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(result!.message),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          /// 📅 Date & Time (row 2)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "assets/icon/calender.png",
                                width: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF656161),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Image.asset("assets/icon/clock.png", width: 16),
                              const SizedBox(width: 4),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF656161),
                                ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
                                  SizedBox(
                                    width: 40, // column width
                                    child: Text(
                                      'Units',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 58),
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
                                itemCount:
                                    widget.paymentSummary.lineItems.length,
                                itemBuilder: (context, index) {
                                  final item =
                                      widget.paymentSummary.lineItems[index];

                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (item.modifiers.isNotEmpty)
                                                    Text(
                                                      "${item.modifiers.join(", ")}  (+₹${item.modifierAmount.toStringAsFixed(0)})",
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),

                                            // Qty × Rate
                                            SizedBox(
                                              width: 80,
                                              child: Text(
                                                '${item.qty} × ${((item.qty > 0 ? ((item.total - item.modifierAmount) / item.qty) : 0)).toStringAsFixed(0)}',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),

                                            // Total
                                            SizedBox(
                                              width: 80,
                                              child: Text(
                                                item.total.toStringAsFixed(2),
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
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

                  const SizedBox(
                    height: 60,
                  ), // space for bottom toggle container
                ],
              ),
            ),

            // ---------- Fixed Bottom Toggle Container ----------
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.315,
                margin: const EdgeInsets.only(bottom: 8),
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

                          // return BlocBuilder<TaxBloc, TaxState>(
                          //   builder: (context, state) {
                          //     if (state is TaxLoaded) {
                          //       final grossTotal = widget.paymentSummary.grossTotal;
                          //       final couponDiscount = widget.paymentSummary.coupons;
                          //       final merchantDiscount = widget.merchantDiscount.abs();
                          //       final subTotal = grossTotal - couponDiscount;
                          //
                          //       double foodCgst = 0, foodSgst = 0, beverageCgst = 0, beverageSgst = 0;
                          //
                          //       for (final item in widget.paymentSummary.lineItems) {
                          //         final itemClass = normalizeTaxClass(item.taxClass);
                          //
                          //         final tax = state.taxes.firstWhere(
                          //               (t) => normalizeTaxClass(t.taxClass) == itemClass,
                          //           orElse: () => TaxModel(
                          //             id: 0,
                          //             rate: "0",
                          //             name: "",
                          //             taxClass: "",
                          //             compound: false,
                          //             shipping: false,
                          //           ),
                          //         );
                          //
                          //         final rate = double.tryParse(tax.rate) ?? 0;
                          //         if (rate == 0) continue;
                          //
                          //         final halfTax = (item.total * rate / 100) / 2;
                          //
                          //         if (itemClass == 'food') {
                          //           foodCgst += halfTax;
                          //           foodSgst += halfTax;
                          //         } else if (itemClass == 'beverages') {
                          //           beverageCgst += halfTax;
                          //           beverageSgst += halfTax;
                          //         }
                          //       }
                          //
                          //       final newTotalTax = foodCgst + foodSgst + beverageCgst + beverageSgst;
                          //       final netTotal = subTotal + newTotalTax;
                          //       final tempPayable = netTotal - merchantDiscount;
                          //
                          //       // WidgetsBinding.instance.addPostFrameCallback((_) {
                          //       //   if (!mounted) return;
                          //       //   if (calculatedNetPayable != tempPayable) {
                          //       //     setState(() {
                          //       //       totalTax = newTotalTax;
                          //       //       calculatedNetPayable = tempPayable;
                          //       //     });
                          //       //   }
                          //       // });
                          //     }
                          //
                          //     return const SizedBox.shrink();
                          //   },
                          // );
                          return const SizedBox.shrink();
                        }

                        debugPrint('🔼 Tax panel expanded');
                        debugPrint("💰 Sidebar Tip = ${widget.tipAmount}");

                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: BlocBuilder<TaxBloc, TaxState>(
                            builder: (context, state) {
                              debugPrint(
                                '📦 BlocBuilder state = ${state.runtimeType}',
                              );

                              if (state is TaxLoading) {
                                debugPrint('⏳ TaxLoading...');
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final grossTotal =
                                  widget.paymentSummary.grossTotal;
                              final couponDiscount =
                                  widget.paymentSummary.coupons;
                              // final merchantDiscount = widget.paymentSummary.discount ?? 0.0;
                              // final merchantDiscount = widget.merchantDiscount;
                              // double netPayable = widget.paymentSummary.netTotal;
                              // final double merchantDiscount = context.select((PaymentBloc bloc) {
                              //   return bloc.state is PaymentSummaryLoaded
                              //       ? (bloc.state as PaymentSummaryLoaded).merchantDiscount
                              //       : 0.0;
                              // });
                              final double merchantDiscount =
                                  widget.merchantDiscount;

                              final double backendNetPayable =
                                  widget.paymentSummary.netTotal -
                                  widget.merchantDiscount.abs();

                              // backend not available yet

                              final subTotal = grossTotal - couponDiscount;
                              // final netPayable = subTotal + totalTax - merchantDiscount;
                              // final netTotal = subTotal + totalTax;
                              final bool modifiersTaxable =
                                  widget.paymentSummary.modifiersTaxable;

                              if (state is TaxLoaded) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) return;
                                  // _calculateTaxAndPayable(state);
                                });
                                final double appliedCouponAmount;

                                final grossTotal =
                                    widget.paymentSummary.grossTotal;
                                final couponDiscount =
                                    widget.paymentSummary.coupons > 0
                                        ? widget.paymentSummary.coupons
                                        : widget.appliedCouponAmount;
                                final merchantDiscount =
                                    widget.merchantDiscount.abs();
                                final subTotal = grossTotal - couponDiscount;
                                final netTotal = subTotal + totalTax;
                                debugPrint(
                                  "Coupon Amount From Summary = ${widget.paymentSummary.coupons}",
                                );

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _row(
                                      "Gross Total",
                                      grossTotal,
                                      isBold: true,
                                    ),
                                    _row(
                                      "Coupon",
                                      couponDiscount,
                                      color: Colors.green,
                                      showNegative: couponDiscount >= 0, // Shows -₹ for 0.00 and positive values
                                    ),

                                    const DottedLine(),
                                    _row("Sub Total", subTotal, isBold: true),

                                    if (foodRate != null &&
                                        (foodCgst > 0 || foodSgst > 0)) ...[
                                      const SizedBox(height: 6),

                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Tax @${foodRate!.toStringAsFixed(0)}% Food",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
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

                                    if (beverageRate != null &&
                                        (beverageCgst > 0 ||
                                            beverageSgst > 0)) ...[
                                      const SizedBox(height: 6),

                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Tax @${beverageRate!.toStringAsFixed(0)}% Beverages",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
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
                                    _row(
                                      "Tax Alcohol @Nil (Amt. inclusive of Excise Duty)",
                                      0.00,
                                    ),

                                    halfDottedLine(width: 100),
                                    _row("Total Tax", totalTax, isBold: true),
                                    const DottedLine(),
                                    _row("Net Total", netTotal, isBold: true),
                                    _row(
                                      "Merchant Discount",
                                      merchantDiscount,
                                      color: Colors.blue,
                                      showNegative: merchantDiscount >= 0,
                                    ),
                                    _row(
                                      "Service Charges (Optional)",
                                      widget.paymentSummary.serviceChargeValue,
                                      color: Colors.black,
                                    ),

                                    if (widget.tipAmount > 0)
                                      _row(
                                        "Tip Amount",
                                        widget.tipAmount,
                                        color: Colors.green,
                                      ),

                                    const DottedLine(),

                                    _row(
                                      "Net Payable",
                                      calculatedNetPayable.abs(),
                                      isBold: true,
                                      fontSize: 18,
                                    ),
                                    _row(
                                      "Round Off",
                                      calculatedNetPayable.round() -
                                          calculatedNetPayable,
                                      isBold: true,
                                      fontSize: 14,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
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
                            /// NET PAYABLE (ROUNDED)
                            Text(
                              "Grand Total : ${calculatedNetPayable.abs().roundToDouble().toStringAsFixed(2)}",
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
      ),
    );
  }
}

Widget halfDottedLine({double width = 140}) {
  return Align(
    alignment: Alignment.centerRight,
    child: SizedBox(
      width: width,
      child: const DottedLine(
        dashLength: 4,
        dashGapLength: 4,
        lineThickness: 1,
        dashColor: Color(0x66666626),
      ),
    ),
  );
}
