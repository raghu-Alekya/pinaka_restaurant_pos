import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';

import 'printer_settings.dart';

class Printer {

  static Future<void> printBill({
    required String orderId,
    required String tableName,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required double grossTotal,
    required double couponDiscount,
    required double merchantDiscount,
    required double tipAmount,
    required double taxAmount,
    required double serviceCharge,
    required double netPayable,
    required BuildContext context,
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
      // Service Charge
      if (serviceCharge > 0) {
        bytes += generator.row([
          PosColumn(
            width: 8,
            text: "Service Charge",
          ),
          PosColumn(
            width: 4,
            text: serviceCharge.toStringAsFixed(2),
            styles: const PosStyles(
              align: PosAlign.right,
            ),
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
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(
            content: Text("No printer selected"),
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
  }