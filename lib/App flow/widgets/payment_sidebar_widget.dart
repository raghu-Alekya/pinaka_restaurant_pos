// import 'package:dotted_line/dotted_line.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:pinaka_restaurant_pos/models/payment/payment_summary_model.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
// import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
// import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
// import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';
// import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';
//
// import '../../blocs/Bloc Event/tax_event.dart';
// import '../../blocs/Bloc Logic/payment_bloc.dart';
// import '../../blocs/Bloc Logic/tax_bloc.dart';
// import '../../blocs/Bloc State/payment_state.dart';
// import '../../blocs/Bloc State/tax_state.dart';
// import '../../models/tax_model.dart';
// import '../../printer/printer_db_helper.dart';
// import '../../printer/printer_settings.dart';
// import '../../repositories/ordertype_payment.dart';
// import '../../utils/SessionManager.dart';
//
// class Sidebarwidgets extends StatefulWidget {
//   final PaymentSummary? paymentSummary;  // ✅ CHANGED: made nullable
//   final double merchantDiscount;
//   final bool hasCouponApplied;
//   final bool hasDiscountApplied;
//   final double tipAmount;
//   final double appliedCouponAmount;
//   final String token;
//   final ValueChanged<double>? onNetPayableChanged;
//   final ValueChanged<String>? onCustomerPhoneChanged;
//   final VoidCallback? onAddCustomer;
//
//   final dynamic userPermissions;
//
//   const Sidebarwidgets({
//     super.key,
//     this.paymentSummary,
//     required this.userPermissions,
//     Map<String, dynamic>? selectedUser,
//     required this.merchantDiscount,
//     required this.tipAmount,
//     required this.appliedCouponAmount,
//     this.hasCouponApplied = false,
//     this.hasDiscountApplied = false,
//     required this.token,
//     this.onNetPayableChanged,
//     this.onCustomerPhoneChanged,
//     this.onAddCustomer,
//   });
//
//   @override
//   State<Sidebarwidgets> createState() => _SidebarwidgetsState();
// }
//
// class _SidebarwidgetsState extends State<Sidebarwidgets>
//     with SingleTickerProviderStateMixin {
//   bool _isExpanded = false;
//   late AnimationController _controller;
//   late Animation<double> _heightAnimation;
//   double foodTax = 0;
//   double beverageTax = 0;
//   double? foodRate;
//   double? beverageRate;
//
//   double foodCgst = 0;
//   double foodSgst = 0;
//   double beverageCgst = 0;
//   double beverageSgst = 0;
//   double totalTax = 0;
//   double liquorCgst = 0;
//   double liquorSgst = 0;
//   double netPayable = 0.0;
//
//   // final merchantDiscount = 0.0;
//   double calculatedNetPayable = 0.0;
//   // order type
//   List<String> orderTypes = [];
//   String? selectedOrderType;
//   String _currency = "₹";
//   // service charges
//   double serviceChargeAmount = 0.0;
//   String? selectedServiceCharge;
//
//   // 👇 ADDED: placeholders for the "Tender Amount" / "Change" rows shown in
//   // the reference UI. There was no source for these values in the original
//   // code, so they default to 0.0 — wire them to your actual cash-tender
//   // entry flow (e.g. tenderAmount - calculatedNetPayable = changeAmount).
//   double tenderAmount = 0.0;
//   double changeAmount = 0.0;
//   final TextEditingController _customerPhoneController =
//   TextEditingController();
//   // until backend provides it
//   final FocusNode _phoneFocusNode = FocusNode();
//   @override
//   void didUpdateWidget(covariant Sidebarwidgets oldWidget) {
//     super.didUpdateWidget(oldWidget);
//
//     if (oldWidget.tipAmount != widget.tipAmount ||
//         oldWidget.appliedCouponAmount != widget.appliedCouponAmount ||
//         oldWidget.merchantDiscount != widget.merchantDiscount) {
//       debugPrint(
//         "Coupon Changed: ${oldWidget.appliedCouponAmount} -> ${widget.appliedCouponAmount}",
//       );
//
//       final taxState = context.read<TaxBloc>().state;
//
//       if (taxState is TaxLoaded) {
//         _calculateTaxAndPayable(taxState);
//       } else {
//         _calculateInitialPayable();
//         setState(() {});
//       }
//     }
//     {
//       final taxState = context.read<TaxBloc>().state;
//
//       if (taxState is TaxLoaded) {
//         _calculateTaxAndPayable(taxState);
//       }
//
//       debugPrint(
//         "💰 Tip changed: ${oldWidget.tipAmount} -> ${widget.tipAmount}",
//       );
//     }
//   }
//
//   void _calculateInitialPayable() {
//     if (widget.paymentSummary == null) return;  // ✅ ADDED: null check
//
//     final grossTotal = widget.paymentSummary!.grossTotal;
//     final couponDiscount =
//     widget.paymentSummary!.coupons > 0
//         ? widget.paymentSummary!.coupons
//         : widget.appliedCouponAmount;
//
//     final merchantDiscount = widget.merchantDiscount.abs();
//
//     calculatedNetPayable =
//         grossTotal -
//             couponDiscount -
//             merchantDiscount +
//             widget.paymentSummary!.serviceChargeValue +
//             widget.tipAmount;
//
//     debugPrint(
//       "Service Charge value : ${widget.paymentSummary!.serviceChargeValue}",
//     );
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         widget.onNetPayableChanged?.call(calculatedNetPayable);
//       }
//     });
//   }
//   Future<void> _loadCurrency() async {
//     final currency = await SessionManager.getCurrencySymbol();
//
//     if (mounted) {
//       setState(() {
//         _currency = currency ?? "₹";
//       });
//     }
//   }
//   @override
//   void dispose() {
//     _phoneFocusNode.dispose();
//     _customerPhoneController.dispose();
//     _controller.dispose(); // ✅ VERY IMPORTANT
//     super.dispose();
//   }
//
//   String normalizeTaxClass(String? value) {
//     return value
//         ?.toLowerCase()
//         .trim()
//         .replaceAll(' ', '')
//         .replaceAll('bewerages', 'beverages') // typo fix
//         ??
//         '';
//   }
//
//   void _calculateTaxAndPayable(TaxLoaded state) {
//     if (widget.paymentSummary == null) return;  // ✅ ADDED: null check
//
//     double foodCgstTemp = 0;
//     double foodSgstTemp = 0;
//     double beverageCgstTemp = 0;
//     double beverageSgstTemp = 0;
//
//     for (final item in widget.paymentSummary!.lineItems) {
//       final itemClass = normalizeTaxClass(item.taxClass);
//
//       final tax = state.taxes.firstWhere(
//             (t) => normalizeTaxClass(t.taxClass) == itemClass,
//         orElse:
//             () => TaxModel(
//           id: 0,
//           rate: "0",
//           name: "",
//           taxClass: "",
//           compound: false,
//           shipping: false,
//         ),
//       );
//
//       final rate = double.tryParse(tax.rate) ?? 0;
//       if (rate == 0) continue;
//
//       final itemTax = item.calculatedTax(
//         modifiersTaxable: widget.paymentSummary!.modifiersTaxable,
//       );
//
//       final halfTax = itemTax / 2;
//
//       if (itemClass == 'food') {
//         foodRate ??= rate;
//         foodCgstTemp += halfTax;
//         foodSgstTemp += halfTax;
//       } else if (itemClass == 'beverages') {
//         beverageRate ??= rate;
//         beverageCgstTemp += halfTax;
//         beverageSgstTemp += halfTax;
//       }
//     }
//
//     final grossTotal = widget.paymentSummary!.grossTotal;
//     final couponDiscount = widget.appliedCouponAmount;
//     final merchantDiscount = widget.merchantDiscount.abs();
//     final tipAmount = widget.tipAmount;
//     final serviceCharge = widget.paymentSummary!.serviceChargeValue;
//
//     final subTotal = grossTotal - couponDiscount;
//     final totalTaxTemp =
//         foodCgstTemp + foodSgstTemp + beverageCgstTemp + beverageSgstTemp;
//     double netPayableTemp =
//         subTotal + totalTaxTemp - merchantDiscount + tipAmount + serviceCharge;
//
// // If NC is applied, or if calculation goes below zero, show 0
//     final paymentState = context.read<PaymentBloc>().state;
//
//     bool isNc = false;
//
//     if (paymentState is PaymentSummaryLoaded) {
//       isNc = paymentState.isNoCharge;
//     }
//
//     if (isNc) {
//       netPayableTemp = 0;
//     } else {
//       netPayableTemp = netPayableTemp.clamp(0.0, double.infinity);
//     }
//
//     debugPrint("""
// Gross Total      : $grossTotal
// Coupon Discount  : $couponDiscount
// Total Tax        : $totalTaxTemp
// Merchant Discount: $merchantDiscount
// Tip Amount       : $tipAmount
// Net Payable      : $netPayableTemp
// """);
//
//     setState(() {
//       foodCgst = foodCgstTemp;
//       foodSgst = foodSgstTemp;
//       beverageCgst = beverageCgstTemp;
//       beverageSgst = beverageSgstTemp;
//       totalTax = totalTaxTemp;
//       calculatedNetPayable = netPayableTemp;
//     });
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         widget.onNetPayableChanged?.call(calculatedNetPayable);
//       }
//     });
//   }
//
//   Future<void> printBill({
//     required String orderId,
//     required String tableName,
//     required String cashierName,
//     required List<Map<String, dynamic>> items,
//     required double grossTotal,
//     required double couponDiscount,
//     required double merchantDiscount,
//     required double tipAmount,
//     required double taxAmount,
//     required double netPayable,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       debugPrint("store_name => ${prefs.getString('store_name')}");
//       debugPrint("store_address => ${prefs.getString('store_address')}");
//       debugPrint("store_phone => ${prefs.getString('store_phone')}");
//       debugPrint("store_gst => ${prefs.getString('store_gst')}");
//
//       final restaurantName =
//           prefs.getString('store_name') ?? 'Restaurant';
//
//       final address =
//           prefs.getString('store_address') ?? '';
//
//       final phone =
//           prefs.getString('store_phone') ?? '';
//
//       final gstNumber =
//           prefs.getString('store_gst') ?? '';
//
//       List<int> bytes = [];
//
//       final profile =
//       await CapabilityProfile.load(name: 'XP-N160I');
//
//       final generator = Generator(
//         PaperSize.mm80,
//         profile,
//       );
//
//       // =========================
//       // Restaurant Header
//       // =========================
//
//       // =========================
// // HEADER
// // =========================
//
//       bytes += generator.text(
//         "**** CUST-INVOICE ****",
//         styles: const PosStyles(
//           align: PosAlign.center,
//           bold: true,
//         ),
//       );
//
//       bytes += generator.text(
//         restaurantName,
//         styles: const PosStyles(
//           align: PosAlign.center,
//           bold: true,
//           height: PosTextSize.size2,
//           width: PosTextSize.size2,
//         ),
//       );
//
//       if (address.isNotEmpty) {
//         bytes += generator.text(
//           address,
//           styles: const PosStyles(
//             align: PosAlign.center,
//           ),
//         );
//       }
//
//       if (gstNumber.isNotEmpty) {
//         bytes += generator.text(
//           "GSTIN: $gstNumber",
//           styles: const PosStyles(
//             align: PosAlign.center,
//           ),
//         );
//       }
//
//       if (phone.isNotEmpty) {
//         bytes += generator.text(
//           "Ph: $phone",
//           styles: const PosStyles(
//             align: PosAlign.center,
//           ),
//         );
//       }
//
//       bytes += generator.hr();
//
//       // customer detail
//
//       // bytes += generator.text(
//       //   "Name : ${customerName ?? '-'}",
//       // );
//
//       bytes += generator.row([
//         PosColumn(
//           width: 6,
//           text: "Date : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
//         ),
//         PosColumn(
//           width: 6,
//           text: "Dine In : $tableName",
//           styles: const PosStyles(
//             align: PosAlign.right,
//           ),
//         ),
//       ]);
//
//       bytes += generator.row([
//         PosColumn(
//           width: 6,
//           text: "Cashier : $cashierName",
//         ),
//         PosColumn(
//           width: 6,
//           text: "Order Id : $orderId",
//           styles: const PosStyles(
//             align: PosAlign.right,
//           ),
//         ),
//       ]);
//
//       bytes += generator.hr();
//
//       // =========================
//       // Item Header
//       // =========================
//
//       bytes += generator.row([
//         PosColumn(
//           width: 6,
//           text: "Item Name",
//           styles: const PosStyles(bold: true),
//         ),
//         PosColumn(
//           width: 2,
//           text: "Qty",
//           styles: const PosStyles(
//             bold: true,
//             align: PosAlign.center,
//           ),
//         ),
//         PosColumn(
//           width: 2,
//           text: "Price",
//           styles: const PosStyles(
//             bold: true,
//             align: PosAlign.right,
//           ),
//         ),
//         PosColumn(
//           width: 2,
//           text: "Amount",
//           styles: const PosStyles(
//             bold: true,
//             align: PosAlign.right,
//           ),
//         ),
//       ]);
//
//       bytes += generator.hr();
//       // =========================
//       // Items
//       // =========================
//
//       for (final item in items) {
//         bytes += generator.row([
//           PosColumn(width: 6, text: item['name'].toString()),
//           PosColumn(
//             width: 2,
//             text: item['qty'].toString(),
//             styles: const PosStyles(align: PosAlign.center),
//           ),
//           PosColumn(
//             width: 2,
//             text: double.parse(item['price'].toString()).toStringAsFixed(2),
//             styles: const PosStyles(align: PosAlign.right),
//           ),
//           PosColumn(
//             width: 2,
//             text: double.parse(item['amount'].toString()).toStringAsFixed(2),
//             styles: const PosStyles(align: PosAlign.right),
//           ),
//         ]);
//
//         // Print modifiers
//         if (item['modifiers'] != null &&
//             (item['modifiers'] as List).isNotEmpty) {
//
//           for (final modifier in (item['modifiers'] as List)) {
//             bytes += generator.text(
//               "   + $modifier",
//               styles: const PosStyles(
//                 align: PosAlign.left,
//               ),
//             );
//           }
//         }
//       }
//
//       bytes += generator.hr();
//
//       // =========================
//       // Summary
//       // =========================
//
//       bytes += generator.row([
//         PosColumn(width: 8, text: "Gross Total"),
//         PosColumn(
//           width: 4,
//           text: grossTotal.toStringAsFixed(2),
//           styles: const PosStyles(align: PosAlign.right),
//         ),
//       ]);
//
// // Coupon
//       if (couponDiscount > 0) {
//         bytes += generator.row([
//           PosColumn(width: 8, text: "Coupon"),
//           PosColumn(
//             width: 4,
//             text: "-${couponDiscount.toStringAsFixed(2)}",
//             styles: const PosStyles(align: PosAlign.right),
//           ),
//         ]);
//       }
//
// // Merchant Discount
//       if (merchantDiscount != 0) {
//         bytes += generator.row([
//           PosColumn(
//             width: 8,
//             text: "Merchant Discount",
//           ),
//           PosColumn(
//             width: 4,
//             text: merchantDiscount.toStringAsFixed(2),
//             styles: const PosStyles(
//               align: PosAlign.right,
//             ),
//           ),
//         ]);
//       }
//
// // Tax
//       if (taxAmount > 0) {
//         final cgst = taxAmount / 2;
//         final sgst = taxAmount / 2;
//
//         bytes += generator.row([
//           PosColumn(width: 8, text: "CGST @ 2.5%"),
//           PosColumn(
//             width: 4,
//             text: cgst.toStringAsFixed(2),
//             styles: const PosStyles(
//               align: PosAlign.right,
//             ),
//           ),
//         ]);
//
//         bytes += generator.row([
//           PosColumn(width: 8, text: "SGST @ 2.5%"),
//           PosColumn(
//             width: 4,
//             text: sgst.toStringAsFixed(2),
//             styles: const PosStyles(
//               align: PosAlign.right,
//             ),
//           ),
//         ]);
//       }
//
// // Service Charge
//       if (widget.paymentSummary != null && widget.paymentSummary!.serviceChargeValue > 0) {  // ✅ ADDED: null check
//         bytes += generator.row([
//           PosColumn(width: 8, text: "Service Charge"),
//           PosColumn(
//             width: 4,
//             text: widget.paymentSummary!.serviceChargeValue.toStringAsFixed(2),
//             styles: const PosStyles(align: PosAlign.right),
//           ),
//         ]);
//       }
//
// // Tip
//       if (tipAmount > 0) {
//         bytes += generator.row([
//           PosColumn(width: 8, text: "Tip"),
//           PosColumn(
//             width: 4,
//             text: tipAmount.toStringAsFixed(2),
//             styles: const PosStyles(align: PosAlign.right),
//           ),
//         ]);
//       }
//       bytes += generator.hr();
//
//       final grandTotal = netPayable.roundToDouble();
//       final roundOff = grandTotal - netPayable;
//
//       bytes += generator.row([
//         PosColumn(
//           width: 8,
//           text: "Round Off",
//         ),
//         PosColumn(
//           width: 4,
//           text: roundOff.toStringAsFixed(2),
//           styles: const PosStyles(
//             align: PosAlign.right,
//           ),
//         ),
//       ]);
//
//       bytes += generator.hr();
//
//       bytes += generator.row([
//         PosColumn(
//           width: 8,
//           text: "Grand Total",
//           styles: const PosStyles(
//             bold: true,
//             height: PosTextSize.size2,
//           ),
//         ),
//         PosColumn(
//           width: 4,
//           text: grandTotal.toStringAsFixed(2),
//           styles: const PosStyles(
//             bold: true,
//             align: PosAlign.right,
//             height: PosTextSize.size2,
//           ),
//         ),
//       ]);
//       bytes += generator.hr();
//
//       bytes += generator.text(
//         "Thank You Visit Again..!!",
//         styles: const PosStyles(
//           align: PosAlign.center,
//           bold: true,
//         ),
//       );
//
//       bytes += generator.text(
//         "Service charge is optional",
//         styles: const PosStyles(
//           align: PosAlign.center,
//         ),
//       );
//       bytes += generator.feed(2);
//       bytes += generator.cut();
//
//       final printerSettings = PrinterSettings();
//
//       await printerSettings.loadPrinter();
//
//       if (printerSettings.selectedPrinter == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("No printer selected"),
//             duration: Duration(seconds: 1),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//
//       await printerSettings.printTicket(
//         bytes,
//         generator,
//       );
//     } catch (e) {
//       debugPrint("Print Bill Error: $e");
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     loadOrderTypes();
//     _customerPhoneController.addListener(() {
//       if (mounted) {
//         setState(() {});
//       }
//     });
//     _loadCurrency();   // <-- Add this
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//
//     _heightAnimation = Tween<double>(
//       begin: 60,
//       end: 260,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
//
//     if (widget.paymentSummary != null) {  // ✅ ADDED: null check
//       selectedServiceCharge = widget.paymentSummary!.serviceChargePercentage.toString();
//       serviceChargeAmount = widget.paymentSummary!.serviceChargeValue;
//
//       debugPrint(
//         "Service Charge %: ${widget.paymentSummary!.serviceChargePercentage}",
//       );
//
//       debugPrint(
//         "Service Charge Value: ${widget.paymentSummary!.serviceChargeValue}",
//       );
//     }
//
//     _calculateInitialPayable();
//
//     // ✅ LOAD TAX IMMEDIATELY (before expand)
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<TaxBloc>().add(LoadTaxesEvent());
//     });
//   }
//
//   Future<void> loadOrderTypes() async {
//     try {
//       debugPrint("══════════════════════════════");
//       debugPrint("🚀 loadOrderTypes Started");
//       debugPrint("🚀 Token: ${widget.token}");
//
//       final repo = OrderTypesInPaymentScreenRepository();
//
//       final result = await repo.getOrderTypes(token: widget.token);
//
//       debugPrint("🟡 API Result: $result");
//
//       if (result != null && mounted) {
//         setState(() {
//           orderTypes = result.orderTypes;
//           selectedOrderType = null;
//         });
//         debugPrint("✅ Order Types Count: ${orderTypes.length}");
//         debugPrint("✅ Order Types: $orderTypes");
//         debugPrint("✅ Selected Type: $selectedOrderType");
//       } else {
//         debugPrint("❌ Result is NULL");
//       }
//     } catch (e, stackTrace) {
//       debugPrint("❌ Order Types Error: $e");
//       debugPrint("$stackTrace");
//     }
//   }
//
//   void _toggleExpand() {
//     if (!mounted) return; // ✅ REQUIRED
//
//     setState(() {
//       _isExpanded = !_isExpanded;
//       if (_isExpanded) {
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     });
//   }
//
//   Widget rightAlignedDottedLine({double width = 120}) {
//     return Align(
//       alignment: Alignment.centerRight,
//       child: SizedBox(
//         width: width, // 👈 controls line length
//         child: const DottedLine(
//           dashLength: 4,
//           dashGapLength: 4,
//           lineThickness: 1,
//           dashColor: Color(0x66666626),
//         ),
//       ),
//     );
//   }
//
//   // 👇 UPDATED: added optional `labelColor`, `valueColor` and `icon` params so
//   // individual rows can be tinted/iconified to match the reference image
//   // (e.g. grey tax sub-rows, green coupon row with a tag icon) without
//   // touching any of the existing call sites that only pass `color`.
//   Widget _row(
//       String label,
//       double value, {
//         bool isBold = false,
//         Color? color,
//         double fontSize = 14,
//         bool showNegative = false,
//         Color? labelColor,
//         Color? valueColor,
//         IconData? icon,
//       }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               if (icon != null) ...[
//                 Icon(
//                   icon,
//                   size: fontSize + 2,
//                   color: labelColor ?? color ?? const Color(0xFF585A5C),
//                 ),
//                 const SizedBox(width: 6),
//               ],
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: fontSize,
//                   fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
//                   color: labelColor ?? color,
//                 ),
//               ),
//             ],
//           ),
//           Text(
//             "${showNegative || value < 0 ? '-$_currency' : '$_currency'}${value.abs().toStringAsFixed(2)}",
//             style: TextStyle(
//               fontSize: fontSize,
//               fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//               color: valueColor ?? color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     if (widget.paymentSummary == null) {  // ✅ ADDED: null check guard
//       return const Scaffold(
//         backgroundColor: Color(0xFFF5F5F6),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     DateTime now = DateTime.now();
//     // 👇 UPDATED format to match the reference image: "16 December, 2025 | 05:00 PM"
//     String formattedDate = DateFormat("dd MMMM, yyyy").format(now);
//     String formattedTime = DateFormat("hh:mm a").format(now);
//     return BlocListener<TaxBloc, TaxState>(
//         listener: (context, state) {
//           if (state is TaxLoaded) {
//             _calculateTaxAndPayable(state); // ✅ CALCULATE IMMEDIATELY
//           }
//         },
//
//         child: Scaffold(
//             resizeToAvoidBottomInset: false, // <-- ADD THIS
//             backgroundColor: const Color(0xFFF5F5F6),
//             body: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 6,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//
//                 child: Stack(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.only(left: 12, top: 16, right: 12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // ---------- Header Section ----------
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               /// First Row
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       const Text(
//                                         "Order ID: ",
//                                         style: TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w700,
//                                         ),
//                                       ),
//                                       Text(
//                                         "${widget.paymentSummary!.orderId}",
//                                         style: const TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w700,
//                                           color: Color(0xFFE53935),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//
//                                   Row(
//                                     children: [
//                                       Image.asset(
//                                         "assets/icon/calender.png",
//                                         width: 16,
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Text(
//                                         "$formattedDate | $formattedTime",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           color: Color(0xFF4C5F7D),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//
//                               const SizedBox(height: 12),
//
//                               /// Second Row - Full Width Mobile Number
//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 42,
//                                 child: TextField(
//                                   focusNode: _phoneFocusNode,
//                                   controller: _customerPhoneController,
//                                   keyboardType: TextInputType.number,
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.digitsOnly,
//                                     LengthLimitingTextInputFormatter(10),
//                                   ],
//                                   onChanged: (value) {
//                                     widget.onCustomerPhoneChanged?.call(value);
//                                   },
//                                   decoration: InputDecoration(
//                                     hintText: "Enter Mobile Number",
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 14,
//                                       vertical: 10,
//                                     ),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     suffixIcon: Padding(
//                                       padding: const EdgeInsets.all(4),
//                                       child: SizedBox(
//                                         width: 85,
//                                         child:
//                                         ValueListenableBuilder<TextEditingValue>(
//                                           valueListenable: _customerPhoneController,
//                                           builder: (_, value, __) {
//                                             final enabled = value.text.length == 10;
//
//                                             return ElevatedButton.icon(
//                                               onPressed: enabled
//                                                   ? () {
//                                                 // FocusScope.of(context).unfocus();
//                                                 // widget.onAddCustomer?.call();
//                                               }
//                                                   : null,
//                                               icon: const Icon(Icons.add, size: 14),
//                                               label: const Text(
//                                                 "Add",
//                                                 style: TextStyle(fontSize: 12),
//                                               ),
//                                               style: ElevatedButton.styleFrom(
//                                                 backgroundColor: const Color(0xFF1A2B4A),
//                                                 foregroundColor: Colors.white,
//                                                 disabledBackgroundColor: Colors.grey,
//                                                 elevation: 0,
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius: BorderRadius.circular(8), // Border radius
//                                                 ),
//                                               ),
//                                             );
//                                           },
//                                         ),
//                                       ),
//                                     ),
//                                     suffixIconConstraints: const BoxConstraints(
//                                       minWidth: 85,
//                                       minHeight: 34,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//
//                           const SizedBox(height: 8),
//
//                           // ---------- Items Container ----------
//                           Expanded(
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFDEE8FF),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               padding: const EdgeInsets.all(10),
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFF1F1F3),
//                                   borderRadius: BorderRadius.circular(5),
//                                 ),
//                                 child: Column(
//                                   children: [
//                                     // 🔴 HEADER ROW
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 12,
//                                         vertical: 8,
//                                       ),
//                                       decoration: const BoxDecoration(
//                                         color: Color(0xFFFF5A5A), // Red header
//                                         borderRadius: BorderRadius.only(
//                                           topLeft: Radius.circular(5),
//                                           topRight: Radius.circular(5),
//                                         ),
//                                       ),
//                                       // 👇 UPDATED columns: "#", "Item Name", "Units",
//                                       // "Amount" — matches the reference image header.
//                                       child: Row(
//                                         children: const [
//                                           SizedBox(
//                                             width: 30,
//                                             child: Text(
//                                               '#',
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 13,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ),
//                                           Expanded(
//                                             child: Text(
//                                               'Item Name',
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 13,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(
//                                             width: 70, // column width
//                                             child: Text(
//                                               'Units',
//                                               textAlign: TextAlign.right,
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 13,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(width: 10),
//                                           SizedBox(
//                                             width: 70,
//                                             child: Text(
//                                               'Amount',
//                                               textAlign: TextAlign.right,
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 13,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//
//                                     // 📜 LIST ITEMS
//                                     Expanded(
//                                       child: ListView.builder(
//                                         itemCount:
//                                         widget.paymentSummary!.lineItems.length,
//                                         itemBuilder: (context, index) {
//                                           final item =
//                                           widget.paymentSummary!.lineItems[index];
//
//                                           return Column(
//                                             children: [
//                                               Padding(
//                                                 padding: const EdgeInsets.symmetric(
//                                                   horizontal: 12,
//                                                   vertical: 6,
//                                                 ),
//                                                 // 👇 UPDATED row: added leading "#"
//                                                 // column (currently index + 1 — swap
//                                                 // for a real item code/id field if
//                                                 // your model has one), and matched the
//                                                 // column widths used in the header above.
//                                                 child: Row(
//                                                   crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                                   children: [
//                                                     SizedBox(
//                                                       width: 30,
//                                                       child: Text(
//                                                         '${index + 1}',
//                                                         style: const TextStyle(
//                                                           fontSize: 13,
//                                                           fontWeight: FontWeight.w600,
//                                                           color: Color(0xFF111827),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                     Expanded(
//                                                       child: Column(
//                                                         crossAxisAlignment:
//                                                         CrossAxisAlignment.start,
//                                                         children: [
//                                                           Text(
//                                                             item.name,
//                                                             overflow:
//                                                             TextOverflow.ellipsis,
//                                                             style: const TextStyle(
//                                                               fontSize: 13,
//                                                               fontWeight:
//                                                               FontWeight.w600,
//                                                               color: Color(0xFF111827),
//                                                             ),
//                                                           ),
//                                                           if (item.modifiers.isNotEmpty)
//                                                             Text(
//                                                               "${item.modifiers.join(", ")}  (+$_currency${item.modifierAmount.toStringAsFixed(0)})",
//                                                               style: const TextStyle(
//                                                                 fontSize: 10,
//                                                                 color: Colors.blue,
//                                                                 fontWeight:
//                                                                 FontWeight.w600,
//                                                               ),
//                                                               overflow:
//                                                               TextOverflow.ellipsis,
//                                                             ),
//                                                         ],
//                                                       ),
//                                                     ),
//
//                                                     // Qty × Rate
//                                                     SizedBox(
//                                                       width: 70,
//                                                       child: Text(
//                                                         '${item.qty} × ${((item.qty > 0 ? ((item.total - item.modifierAmount) / item.qty) : 0)).toStringAsFixed(0)}',
//                                                         textAlign: TextAlign.right,
//                                                         style: const TextStyle(
//                                                           fontSize: 12,
//                                                           color: Color(0xFF656161),
//                                                         ),
//                                                       ),
//                                                     ),
//
//                                                     const SizedBox(width: 10),
//
//                                                     // Total
//                                                     SizedBox(
//                                                       width: 70,
//                                                       child: Text(
//                                                         "$_currency${item.total.toStringAsFixed(2)}",
//                                                         textAlign: TextAlign.right,
//                                                         style: const TextStyle(
//                                                           fontSize: 13,
//                                                           fontWeight: FontWeight.w600,
//                                                           color: Color(0xFF111827),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                               const Divider(
//                                                 color: Color(0xFFE6E7E8),
//                                                 thickness: 1,
//                                               ),
//                                             ],
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(
//                             height: 60,
//                           ), // space for bottom toggle container
//                         ],
//                       ),
//                     ),
//
//                     // ---------- Fixed Bottom Toggle Container ----------
//                     Align(
//                       alignment: Alignment.bottomCenter,
//                       child: Container(
//                         width: MediaQuery.of(context).size.width * 0.315,
//                         margin: const EdgeInsets.only(bottom: 8,left:3,right:3),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFFFFFFF),
//                           borderRadius: BorderRadius.circular(10),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black12,
//                               blurRadius: 6,
//                               offset: const Offset(0, -2),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             /// 🔼 EXPANDABLE PART (Animated)
//                             AnimatedBuilder(
//                               animation: _controller,
//                               builder: (context, child) {
//                                 if (!_isExpanded) {
//                                   debugPrint('🔽 Tax panel collapsed');
//                                   return const SizedBox.shrink();
//                                 }
//
//                                 debugPrint('🔼 Tax panel expanded');
//                                 debugPrint("💰 Sidebar Tip = ${widget.tipAmount}");
//
//                                 // 👇 ADDED: cap the breakdown to 40% of the screen
//                                 // height. Anything taller scrolls inside this box
//                                 // instead of growing the panel / pushing the layout.
//                                 final double maxExpandedHeight =
//                                     MediaQuery.of(context).size.height * 0.4;
//
//                                 return ConstrainedBox(
//                                   constraints: BoxConstraints(
//                                     maxHeight: maxExpandedHeight,
//                                   ),
//                                   child: SingleChildScrollView(
//                                     padding: const EdgeInsets.all(12),
//                                     child: BlocBuilder<TaxBloc, TaxState>(
//                                       builder: (context, state) {
//                                         debugPrint(
//                                           '📦 BlocBuilder state = ${state.runtimeType}',
//                                         );
//
//                                         if (state is TaxLoading) {
//                                           debugPrint('⏳ TaxLoading...');
//                                           return const Center(
//                                             child: CircularProgressIndicator(),
//                                           );
//                                         }
//                                         final grossTotal =
//                                             widget.paymentSummary!.grossTotal;
//                                         final couponDiscount = widget.appliedCouponAmount;
//                                         final double merchantDiscount =
//                                             widget.merchantDiscount;
//
//                                         final double backendNetPayable =
//                                             widget.paymentSummary!.netTotal -
//                                                 widget.merchantDiscount.abs();
//
//                                         final subTotal = grossTotal - couponDiscount;
//                                         final bool modifiersTaxable =
//                                             widget.paymentSummary!.modifiersTaxable;
//
//                                         if (state is TaxLoaded) {
//                                           WidgetsBinding.instance.addPostFrameCallback((
//                                               _,
//                                               ) {
//                                             if (!mounted) return;
//                                           });
//                                           final double appliedCouponAmount;
//
//                                           final grossTotal =
//                                               widget.paymentSummary!.grossTotal;
//                                           final couponDiscount = widget.appliedCouponAmount;
//                                           final merchantDiscount =
//                                           widget.merchantDiscount.abs();
//                                           final subTotal = grossTotal - couponDiscount;
//                                           final netTotal = subTotal + totalTax;
//                                           debugPrint(
//                                             "Coupon Amount From Summary = ${widget.paymentSummary!.coupons}",
//                                           );
//
//                                           return Column(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               _row(
//                                                 "Gross Total",
//                                                 grossTotal,
//                                                 isBold: true,
//                                               ),
//                                               _row(
//                                                 "Coupon",
//                                                 couponDiscount,
//                                                 color: Colors.green,
//                                                 icon: Icons.sell_outlined,
//                                                 showNegative: couponDiscount >= 0, // Shows -₹ for 0.00 and positive values
//                                               ),
//
//                                               const DottedLine(),
//                                               _row("Sub Total", subTotal, isBold: true),
//
//                                               if (foodRate != null &&
//                                                   (foodCgst > 0 || foodSgst > 0)) ...[
//                                                 const SizedBox(height: 6),
//
//                                                 Align(
//                                                   alignment: Alignment.centerLeft,
//                                                   child: Text(
//                                                     "Tax @${foodRate!.toStringAsFixed(0)}% Food",
//                                                     style: const TextStyle(
//                                                       fontSize: 14,
//                                                       fontWeight: FontWeight.w600,
//                                                     ),
//                                                   ),
//                                                 ),
//
//                                                 Padding(
//                                                   padding: const EdgeInsets.only(
//                                                     left: 12,
//                                                   ),
//                                                   child: Column(
//                                                     children: [
//                                                       _row(
//                                                         "CGST ${(foodRate! / 2).toStringAsFixed(1)}%",
//                                                         foodCgst,
//                                                         color: const Color(0xFF8A8A8A),
//                                                         fontSize: 13,
//                                                       ),
//                                                       _row(
//                                                         "SGST ${(foodRate! / 2).toStringAsFixed(1)}%",
//                                                         foodSgst,
//                                                         color: const Color(0xFF8A8A8A),
//                                                         fontSize: 13,
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ],
//
//                                               if (beverageRate != null &&
//                                                   (beverageCgst > 0 ||
//                                                       beverageSgst > 0)) ...[
//                                                 const SizedBox(height: 6),
//
//                                                 Align(
//                                                   alignment: Alignment.centerLeft,
//                                                   child: Text(
//                                                     "Tax @${beverageRate!.toStringAsFixed(0)}% Beverages",
//                                                     style: const TextStyle(
//                                                       fontSize: 14,
//                                                       fontWeight: FontWeight.w600,
//                                                     ),
//                                                   ),
//                                                 ),
//
//                                                 Padding(
//                                                   padding: const EdgeInsets.only(
//                                                     left: 12,
//                                                   ),
//                                                   child: Column(
//                                                     children: [
//                                                       _row(
//                                                         "CGST ${(beverageRate! / 2).toStringAsFixed(1)}%",
//                                                         beverageCgst,
//                                                         color: const Color(0xFF8A8A8A),
//                                                         fontSize: 13,
//                                                       ),
//                                                       _row(
//                                                         "SGST ${(beverageRate! / 2).toStringAsFixed(1)}%",
//                                                         beverageSgst,
//                                                         color: const Color(0xFF8A8A8A),
//                                                         fontSize: 13,
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ],
//                                               _row(
//                                                 "Tax Alcohol @Nill (Price inclusive of Excise Duty)",
//                                                 0.00,
//                                                 color: const Color(0xFF8A8A8A),
//                                                 fontSize: 12,
//                                               ),
//
//                                               halfDottedLine(width: 100),
//                                               _row("Total Tax", totalTax, isBold: true),
//                                               const DottedLine(),
//                                               _row(
//                                                 "Net Total",
//                                                 netTotal,
//                                                 isBold: true,
//                                                 fontSize: 16,
//                                               ),
//                                               if (merchantDiscount != 0)
//                                                 _row(
//                                                   "Merchant Discount",
//                                                   merchantDiscount,
//                                                   color: Colors.blue,
//                                                   showNegative: merchantDiscount >= 0,
//                                                 ),
//                                               _row(
//                                                 "Service Charges (Optional)",
//                                                 widget.paymentSummary!.serviceChargeValue,
//                                                 color: Colors.black,
//                                                 icon: Icons.payments_outlined,
//                                               ),
//
//                                               if (widget.tipAmount > 0)
//                                                 _row(
//                                                   "Add Tip",
//                                                   widget.tipAmount,
//                                                   color: Colors.black,
//                                                   icon: Icons.back_hand_outlined,
//                                                 ),
//
//                                               const DottedLine(),
//
//                                               _row(
//                                                 "Net Payable",
//                                                 calculatedNetPayable,
//                                                 isBold: true,
//                                                 fontSize: 18,
//                                               ),
//                                               _row(
//                                                 "Round Off",
//                                                 calculatedNetPayable.round() -
//                                                     calculatedNetPayable,
//                                                 isBold: true,
//                                                 fontSize: 14,
//                                               ),
//                                               _row(
//                                                 "Tender Amount",
//                                                 tenderAmount,
//                                                 fontSize: 14,
//                                               ),
//                                               _row(
//                                                 "Change",
//                                                 changeAmount,
//                                                 fontSize: 14,
//                                               ),
//                                             ],
//                                           );
//                                         }
//
//                                         if (state is TaxError) {
//                                           debugPrint('❌ TaxError → ${state.message}');
//                                           return Text(
//                                             "Tax error: ${state.message}",
//                                             style: const TextStyle(color: Colors.red),
//                                           );
//                                         }
//
//                                         debugPrint('⚠️ Unknown state');
//                                         return const SizedBox.shrink();
//                                       },
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//
//                             /// 🔽 FIXED BOTTOM (Never moves)
//                             GestureDetector(
//                               onTap: _toggleExpand,
//
//                               child: Container(
//
//                                 margin: const EdgeInsets.symmetric(horizontal: 1),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 12,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFDEE8FF), // SAME COLOR AS IMAGE
//                                   borderRadius: BorderRadius.only(
//                                     bottomLeft: Radius.circular(8),
//                                     bottomRight: Radius.circular(8),
//                                   ),
//
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     /// TOTAL ITEMS
//                                     Text(
//                                       "Total Items : ${widget.paymentSummary!.lineItems.length}",
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 13,
//                                       ),
//                                     ),
//
//                                     const Spacer(),
//
//                                     /// NET PAYABLE
//                                     /// NET PAYABLE (ROUNDED)
//                                     /// NET PAYABLE (ROUNDED)
//                                     Text(
//                                       "Net Payable : $_currency${calculatedNetPayable.round().toDouble().toStringAsFixed(2)}",
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                     // const SizedBox(width: 6),
//
//                                     const SizedBox(width: 6),
//
//                                     /// TOGGLE ICON (ONLY HERE)
//                                     Icon(
//                                       _isExpanded
//                                           ? Icons.keyboard_arrow_down
//                                           : Icons.keyboard_arrow_up,
//                                       size: 22,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             )));
//   }
// }
//
// Widget halfDottedLine({double width = 140}) {
//   return Align(
//     alignment: Alignment.centerRight,
//     child: SizedBox(
//       width: width,
//       child: const DottedLine(
//         dashLength: 4,
//         dashGapLength: 4,
//         lineThickness: 1,
//         dashColor: Color(0x66666626),
//       ),
//     ),
//   );
// }


////

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc Logic/tax_bloc.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../blocs/Bloc State/payment_state.dart';
import '../../blocs/Bloc State/tax_state.dart';
import '../../models/tax_model.dart';
import '../../printer/printer_db_helper.dart';
import '../../printer/printer_settings.dart';
import '../../repositories/ordertype_payment.dart';
import '../../utils/SessionManager.dart';

class _DisplayLineItem {
  final String name;
  final int qty;
  final double total;
  final List<String> modifiers;
  final double modifierAmount;

  const _DisplayLineItem({
    required this.name,
    required this.qty,
    required this.total,
    required this.modifiers,
    required this.modifierAmount,
  });
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

_DisplayLineItem? _parseKotItem(dynamic rawItem) {
  try {
    if (rawItem is Map) {
      final map = rawItem;
      final name = (map['product_name'] ??
          map['productName'] ??
          map['name'] ??
          'Item')
          .toString();
      final qty = _toInt(map['quantity'] ?? map['qty'] ?? 1);
      final price = _toDouble(map['price'] ?? 0);
      final amount = _toDouble(
        map['amount'] ?? map['total'] ?? (price * qty),
      );
      final modifiersRaw = map['modifiers'];
      final modifiers = modifiersRaw is List
          ? modifiersRaw.map((m) => m.toString()).toList()
          : <String>[];
      return _DisplayLineItem(
        name: name,
        qty: qty,
        total: amount,
        modifiers: modifiers,
        modifierAmount: 0,
      );
    } else {
      final dynamic dyn = rawItem;
      String name = 'Item';
      try {
        name = (dyn.productName ?? dyn.name ?? 'Item').toString();
      } catch (_) {
        try {
          name = (dyn.product_name ?? 'Item').toString();
        } catch (_) {}
      }

      int qty = 1;
      try {
        qty = _toInt(dyn.quantity);
      } catch (_) {
        try {
          qty = _toInt(dyn.qty);
        } catch (_) {}
      }

      double amount = 0;
      try {
        amount = _toDouble(dyn.amount);
      } catch (_) {
        try {
          amount = _toDouble(dyn.total);
        } catch (_) {}
      }
      if (amount == 0) {
        try {
          final price = _toDouble(dyn.price);
          amount = price * qty;
        } catch (_) {}
      }

      List<String> modifiers = [];
      try {
        final mods = dyn.modifiers;
        if (mods is List) modifiers = mods.map((m) => m.toString()).toList();
      } catch (_) {}

      return _DisplayLineItem(
        name: name,
        qty: qty,
        total: amount,
        modifiers: modifiers,
        modifierAmount: 0,
      );
    }
  } catch (_) {
    return null;
  }
}


List<_DisplayLineItem> _buildInstantPreviewItems(OrderState orderState) {
  final List<_DisplayLineItem> fromKots = [];

  try {
    for (final kot in orderState.kotList) {
      String status = '';
      try {
        status = (kot.status ?? '').toString().toLowerCase();
      } catch (_) {}
      if (status == 'voided' || status == 'transferred') continue;

      dynamic rawItems;
      try {
        rawItems = (kot as dynamic).items;
      } catch (_) {
        rawItems = null;
      }
      if (rawItems is! List) continue;

      for (final rawItem in rawItems) {
        final parsed = _parseKotItem(rawItem);
        if (parsed != null) fromKots.add(parsed);
      }
    }
  } catch (_) {}

  if (fromKots.isNotEmpty) return fromKots;

  // Fallback: cart items still sitting in OrderBloc (e.g. before any KOT
  // has been created yet).
  try {
    return orderState.orderItems
        .map(
          (e) => _DisplayLineItem(
        name: e.name,
        qty: e.quantity,
        total: e.totalWithAddons,
        modifiers: e.modifiers.toList(),
        modifierAmount: 0,
      ),
    )
        .toList();
  } catch (_) {
    return [];
  }
}

class Sidebarwidgets extends StatefulWidget {
  final PaymentSummary? paymentSummary;
  final double merchantDiscount;
  final bool hasCouponApplied;
  final bool hasDiscountApplied;
  final double tipAmount;
  final double appliedCouponAmount;
  final String token;
  final ValueChanged<double>? onNetPayableChanged;
  final ValueChanged<String>? onCustomerPhoneChanged;
  final VoidCallback? onAddCustomer;

  final dynamic userPermissions;

  const Sidebarwidgets({
    super.key,
    this.paymentSummary,
    required this.userPermissions,
    Map<String, dynamic>? selectedUser,
    required this.merchantDiscount,
    required this.tipAmount,
    required this.appliedCouponAmount,
    this.hasCouponApplied = false,
    this.hasDiscountApplied = false,
    required this.token,
    this.onNetPayableChanged,
    this.onCustomerPhoneChanged,
    this.onAddCustomer,
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
  String _currency = "₹";
  // service charges
  double serviceChargeAmount = 0.0;
  String? selectedServiceCharge;

  // 👇 ADDED: placeholders for the "Tender Amount" / "Change" rows shown in
  // the reference UI. There was no source for these values in the original
  // code, so they default to 0.0 — wire them to your actual cash-tender
  // entry flow (e.g. tenderAmount - calculatedNetPayable = changeAmount).
  double tenderAmount = 0.0;
  double changeAmount = 0.0;
  final TextEditingController _customerPhoneController =
  TextEditingController();
  // until backend provides it
  final FocusNode _phoneFocusNode = FocusNode();
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
    if (widget.paymentSummary == null) return;  // ✅ ADDED: null check

    final grossTotal = widget.paymentSummary!.grossTotal;
    final couponDiscount =
    widget.paymentSummary!.coupons > 0
        ? widget.paymentSummary!.coupons
        : widget.appliedCouponAmount;

    final merchantDiscount = widget.merchantDiscount.abs();

    calculatedNetPayable =
        grossTotal -
            couponDiscount -
            merchantDiscount +
            widget.paymentSummary!.serviceChargeValue +
            widget.tipAmount;

    debugPrint(
      "Service Charge value : ${widget.paymentSummary!.serviceChargeValue}",
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onNetPayableChanged?.call(calculatedNetPayable);
      }
    });
  }
  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }
  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _customerPhoneController.dispose();
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

  void _calculateTaxAndPayable(TaxLoaded state) {
    if (widget.paymentSummary == null) return;  // ✅ ADDED: null check

    double foodCgstTemp = 0;
    double foodSgstTemp = 0;
    double beverageCgstTemp = 0;
    double beverageSgstTemp = 0;

    for (final item in widget.paymentSummary!.lineItems) {
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
        modifiersTaxable: widget.paymentSummary!.modifiersTaxable,
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

    final grossTotal = widget.paymentSummary!.grossTotal;
    final couponDiscount = widget.appliedCouponAmount;
    final merchantDiscount = widget.merchantDiscount.abs();
    final tipAmount = widget.tipAmount;
    final serviceCharge = widget.paymentSummary!.serviceChargeValue;

    final subTotal = grossTotal - couponDiscount;
    final totalTaxTemp =
        foodCgstTemp + foodSgstTemp + beverageCgstTemp + beverageSgstTemp;
    double netPayableTemp =
        subTotal + totalTaxTemp - merchantDiscount + tipAmount + serviceCharge;

// If NC is applied, or if calculation goes below zero, show 0
    final paymentState = context.read<PaymentBloc>().state;

    bool isNc = false;

    if (paymentState is PaymentSummaryLoaded) {
      isNc = paymentState.isNoCharge;
    }

    if (isNc) {
      netPayableTemp = 0;
    } else {
      netPayableTemp = netPayableTemp.clamp(0.0, double.infinity);
    }

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
      if (widget.paymentSummary != null && widget.paymentSummary!.serviceChargeValue > 0) {  // ✅ ADDED: null check
        bytes += generator.row([
          PosColumn(width: 8, text: "Service Charge"),
          PosColumn(
            width: 4,
            text: widget.paymentSummary!.serviceChargeValue.toStringAsFixed(2),
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
            backgroundColor: Colors.red,
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
    _customerPhoneController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadCurrency();   // <-- Add this
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightAnimation = Tween<double>(
      begin: 60,
      end: 260,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.paymentSummary != null) {  // ✅ ADDED: null check
      selectedServiceCharge = widget.paymentSummary!.serviceChargePercentage.toString();
      serviceChargeAmount = widget.paymentSummary!.serviceChargeValue;

      debugPrint(
        "Service Charge %: ${widget.paymentSummary!.serviceChargePercentage}",
      );

      debugPrint(
        "Service Charge Value: ${widget.paymentSummary!.serviceChargeValue}",
      );
    }

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

  // 👇 UPDATED: added optional `labelColor`, `valueColor` and `icon` params so
  // individual rows can be tinted/iconified to match the reference image
  // (e.g. grey tax sub-rows, green coupon row with a tag icon) without
  // touching any of the existing call sites that only pass `color`.
  Widget _row(
      String label,
      double value, {
        bool isBold = false,
        Color? color,
        double fontSize = 14,
        bool showNegative = false,
        Color? labelColor,
        Color? valueColor,
        IconData? icon,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: fontSize + 2,
                  color: labelColor ?? color ?? const Color(0xFF585A5C),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  color: labelColor ?? color,
                ),
              ),
            ],
          ),
          Text(
            "${showNegative || value < 0 ? '-$_currency' : '$_currency'}${value.abs().toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? color,
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // ✅ FIX: no longer block the whole screen on the paymentSummary network
    // call. Read data already loaded on the Order screen from OrderBloc
    // (instant, local, no fetch) — preferring KOT items (since the cart is
    // usually already cleared into KOTs by the time Checkout is enabled),
    // falling back to raw cart items — and render the item list + a local
    // running total right away. Once PaymentBloc emits the real
    // PaymentSummary, this same build() picks it up and switches over — no
    // other function or logic below this point changes.
    final orderState = context.watch<OrderBloc>().state;
    final bool hasSummary = widget.paymentSummary != null;

    final int displayOrderId =
    hasSummary ? widget.paymentSummary!.orderId : orderState.orderId;

    final List<_DisplayLineItem> displayItems = hasSummary
        ? widget.paymentSummary!.lineItems
        .map(
          (e) => _DisplayLineItem(
        name: e.name,
        qty: e.qty,
        total: e.total,
        modifiers: e.modifiers,
        modifierAmount: e.modifierAmount,
      ),
    )
        .toList()
        : _buildInstantPreviewItems(orderState); // ✅ CHANGED: KOT-aware instant preview

    final double localTotal = displayItems.fold(
      0.0,
          (sum, item) => sum + item.total,
    );
    final double displayNetPayable =
    hasSummary ? calculatedNetPayable : localTotal;

    DateTime now = DateTime.now();
    // 👇 UPDATED format to match the reference image: "16 December, 2025 | 05:00 PM"
    String formattedDate = DateFormat("dd MMMM, yyyy").format(now);
    String formattedTime = DateFormat("hh:mm a").format(now);
    return BlocListener<TaxBloc, TaxState>(
        listener: (context, state) {
          if (state is TaxLoaded) {
            _calculateTaxAndPayable(state); // ✅ CALCULATE IMMEDIATELY
          }
        },

        child: Scaffold(
            resizeToAvoidBottomInset: false, // <-- ADD THIS
            backgroundColor: const Color(0xFFF5F5F6),
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),

                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 16, right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---------- Header Section ----------
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// First Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Order ID: ",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        "$displayOrderId",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFE53935),
                                        ),
                                      ),
                                    ],
                                  ),

                                  Row(
                                    children: [
                                      Image.asset(
                                        "assets/icon/calender.png",
                                        width: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "$formattedDate | $formattedTime",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF4C5F7D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              /// Second Row - Full Width Mobile Number
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: TextField(
                                  focusNode: _phoneFocusNode,
                                  controller: _customerPhoneController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  onChanged: (value) {
                                    widget.onCustomerPhoneChanged?.call(value);
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Enter Mobile Number",
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: SizedBox(
                                        width: 85,
                                        child:
                                        ValueListenableBuilder<TextEditingValue>(
                                          valueListenable: _customerPhoneController,
                                          builder: (_, value, __) {
                                            final enabled = value.text.length == 10;

                                            return ElevatedButton.icon(
                                              onPressed: enabled
                                                  ? () {
                                                // FocusScope.of(context).unfocus();
                                                // widget.onAddCustomer?.call();
                                              }
                                                  : null,
                                              icon: const Icon(Icons.add, size: 14),
                                              label: const Text(
                                                "Add",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1A2B4A),
                                                foregroundColor: Colors.white,
                                                disabledBackgroundColor: Colors.grey,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8), // Border radius
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    suffixIconConstraints: const BoxConstraints(
                                      minWidth: 85,
                                      minHeight: 34,
                                    ),
                                  ),
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
                                  color: const Color(0xFFF1F1F3),
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
                                      // 👇 UPDATED columns: "#", "Item Name", "Units",
                                      // "Amount" — matches the reference image header.
                                      child: Row(
                                        children: const [
                                          SizedBox(
                                            width: 30,
                                            child: Text(
                                              '#',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
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
                                            width: 70, // column width
                                            child: Text(
                                              'Units',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          SizedBox(
                                            width: 70,
                                            child: Text(
                                              'Amount',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 📜 LIST ITEMS
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: displayItems.length,
                                        itemBuilder: (context, index) {
                                          final item = displayItems[index];

                                          return Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                // 👇 UPDATED row: added leading "#"
                                                // column (currently index + 1 — swap
                                                // for a real item code/id field if
                                                // your model has one), and matched the
                                                // column widths used in the header above.
                                                child: Row(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      width: 30,
                                                      child: Text(
                                                        '${index + 1}',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF111827),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            item.name,
                                                            overflow:
                                                            TextOverflow.ellipsis,
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                              FontWeight.w600,
                                                              color: Color(0xFF111827),
                                                            ),
                                                          ),
                                                          if (item.modifiers.isNotEmpty)
                                                            Text(
                                                              "${item.modifiers.join(", ")}  (+$_currency${item.modifierAmount.toStringAsFixed(0)})",
                                                              style: const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors.blue,
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
                                                      width: 70,
                                                      child: Text(
                                                        '${item.qty} × ${((item.qty > 0 ? ((item.total - item.modifierAmount) / item.qty) : 0)).toStringAsFixed(0)}',
                                                        textAlign: TextAlign.right,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(0xFF656161),
                                                        ),
                                                      ),
                                                    ),

                                                    const SizedBox(width: 10),

                                                    // Total
                                                    SizedBox(
                                                      width: 70,
                                                      child: Text(
                                                        "$_currency${item.total.toStringAsFixed(2)}",
                                                        textAlign: TextAlign.right,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF111827),
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
                        margin: const EdgeInsets.only(bottom: 8,left:3,right:3),
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
                                debugPrint("💰 Sidebar Tip = ${widget.tipAmount}");

                                // 👇 ADDED: cap the breakdown to 40% of the screen
                                // height. Anything taller scrolls inside this box
                                // instead of growing the panel / pushing the layout.
                                final double maxExpandedHeight =
                                    MediaQuery.of(context).size.height * 0.4;

                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: maxExpandedHeight,
                                  ),
                                  // ✅ FIX: the tax/service-charge breakdown genuinely
                                  // needs the backend PaymentSummary + TaxBloc, so
                                  // while that hasn't arrived yet we show a small
                                  // inline "calculating" indicator here instead of
                                  // touching the item list/total above, and instead
                                  // of the old full-screen spinner.
                                  child: !hasSummary
                                      ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Calculating totals...",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF8A8A8A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                      : SingleChildScrollView(
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
                                            widget.paymentSummary!.grossTotal;
                                        final couponDiscount = widget.appliedCouponAmount;
                                        final double merchantDiscount =
                                            widget.merchantDiscount;

                                        final double backendNetPayable =
                                            widget.paymentSummary!.netTotal -
                                                widget.merchantDiscount.abs();

                                        final subTotal = grossTotal - couponDiscount;
                                        final bool modifiersTaxable =
                                            widget.paymentSummary!.modifiersTaxable;

                                        if (state is TaxLoaded) {
                                          WidgetsBinding.instance.addPostFrameCallback((
                                              _,
                                              ) {
                                            if (!mounted) return;
                                          });
                                          final double appliedCouponAmount;

                                          final grossTotal =
                                              widget.paymentSummary!.grossTotal;
                                          final couponDiscount = widget.appliedCouponAmount;
                                          final merchantDiscount =
                                          widget.merchantDiscount.abs();
                                          final subTotal = grossTotal - couponDiscount;
                                          final netTotal = subTotal + totalTax;
                                          debugPrint(
                                            "Coupon Amount From Summary = ${widget.paymentSummary!.coupons}",
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
                                                icon: Icons.sell_outlined,
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
                                                        color: const Color(0xFF8A8A8A),
                                                        fontSize: 13,
                                                      ),
                                                      _row(
                                                        "SGST ${(foodRate! / 2).toStringAsFixed(1)}%",
                                                        foodSgst,
                                                        color: const Color(0xFF8A8A8A),
                                                        fontSize: 13,
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
                                                        color: const Color(0xFF8A8A8A),
                                                        fontSize: 13,
                                                      ),
                                                      _row(
                                                        "SGST ${(beverageRate! / 2).toStringAsFixed(1)}%",
                                                        beverageSgst,
                                                        color: const Color(0xFF8A8A8A),
                                                        fontSize: 13,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              _row(
                                                "Tax Alcohol @Nill (Price inclusive of Excise Duty)",
                                                0.00,
                                                color: const Color(0xFF8A8A8A),
                                                fontSize: 12,
                                              ),

                                              halfDottedLine(width: 100),
                                              _row("Total Tax", totalTax, isBold: true),
                                              const DottedLine(),
                                              _row(
                                                "Net Total",
                                                netTotal,
                                                isBold: true,
                                                fontSize: 16,
                                              ),
                                              if (merchantDiscount != 0)
                                                _row(
                                                  "Merchant Discount",
                                                  merchantDiscount,
                                                  color: Colors.blue,
                                                  showNegative: merchantDiscount >= 0,
                                                ),
                                              _row(
                                                "Service Charges (Optional)",
                                                widget.paymentSummary!.serviceChargeValue,
                                                color: Colors.black,
                                                icon: Icons.payments_outlined,
                                              ),

                                              if (widget.tipAmount > 0)
                                                _row(
                                                  "Add Tip",
                                                  widget.tipAmount,
                                                  color: Colors.black,
                                                  icon: Icons.back_hand_outlined,
                                                ),

                                              const DottedLine(),

                                              _row(
                                                "Net Payable",
                                                calculatedNetPayable,
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
                                              _row(
                                                "Tender Amount",
                                                tenderAmount,
                                                fontSize: 14,
                                              ),
                                              _row(
                                                "Change",
                                                changeAmount,
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
                                  ),
                                );
                              },
                            ),

                            /// 🔽 FIXED BOTTOM (Never moves)
                            GestureDetector(
                              onTap: _toggleExpand,

                              child: Container(

                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDEE8FF), // SAME COLOR AS IMAGE
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),

                                ),
                                child: Row(
                                  children: [
                                    /// TOTAL ITEMS
                                    Text(
                                      "Total Items : ${displayItems.length}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),

                                    const Spacer(),

                                    /// NET PAYABLE
                                    /// NET PAYABLE (ROUNDED)
                                    /// NET PAYABLE (ROUNDED)
                                    Text(
                                      "Net Payable : $_currency${displayNetPayable.round().toDouble().toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    // const SizedBox(width: 6),

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
            )));
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