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
import '../utils/SessionManager.dart';

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
    bool isCopy = false,
    List<dynamic>? couponDetails,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      debugPrint("store_name => ${prefs.getString('store_name')}");
      debugPrint("store_address => ${prefs.getString('store_address')}");
      debugPrint("store_phone => ${prefs.getString('store_phone')}");
      debugPrint("store_gst => ${prefs.getString('store_gst')}");

      final restaurantName =
          prefs.getString('store_name') ?? 'Pinaka restaurant';

      String address = prefs.getString('store_address') ?? '';
      if (address.isEmpty) address = 'raidurg metro, hitech city';

      String phone = prefs.getString('store_phone') ?? '';
      if (phone.isEmpty) phone = '9892829282';

      String gstNumber =
          prefs.getString('store_gstin') ?? prefs.getString('store_gst') ?? '';
      if (gstNumber.isEmpty) gstNumber = '33AAACI1607G2Z5';

      List<int> bytes = [];

      final profile = await CapabilityProfile.load(name: 'XP-N160I');

      final generator = Generator(PaperSize.mm80, profile);
      bytes += generator.setGlobalFont(PosFontType.fontA);

      // =========================
      // Restaurant Header
      // =========================

      bytes += generator.text(
        isCopy ? "**** COPY OF CUST-INVOICE ****" : "**** CUST-INVOICE ****",
        styles: const PosStyles(align: PosAlign.center, bold: true),
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
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      if (gstNumber.isNotEmpty) {
        bytes += generator.text(
          "GST NO : $gstNumber",
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      if (phone.isNotEmpty) {
        bytes += generator.text(
          "Ph: $phone",
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      bytes += generator.hr(ch: '=');

      final permissions = await SessionManager.loadPermissions();
      final role = permissions?.role ?? 'administrator';

      bytes += generator.row([
        PosColumn(
          width: 7,
          text: "Date: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.now())}",
        ),
        PosColumn(
          width: 5,
          text: "Dine In: $tableName",
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += generator.row([
        PosColumn(width: 6, text: "Role: $role"),
        PosColumn(
          width: 6,
          text: "Bill No.: $orderId",
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.hr(ch: '=');

      // =========================
      // Item Header
      // =========================

      bytes += generator.row([
        PosColumn(width: 6, text: "Item", styles: const PosStyles(bold: true)),
        PosColumn(
          width: 2,
          text: "Qty.",
          styles: const PosStyles(bold: true, align: PosAlign.center),
        ),
        PosColumn(
          width: 2,
          text: "Price",
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
        PosColumn(
          width: 2,
          text: "Amount",
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      bytes += generator.hr(ch: '=');
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
              styles: const PosStyles(align: PosAlign.left),
            );
          }
        }
      }

      bytes += generator.hr(ch: '=');

      // =========================
      // Summary
      // =========================

      int totalQty = 0;
      for (final item in items) {
        totalQty += int.tryParse(item['qty'].toString()) ?? 0;
      }

      bytes += generator.row([
        PosColumn(
          width: 6,
          text: "Total Qty: $totalQty",
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          width: 6,
          text: "Sub Total  ${grossTotal.toStringAsFixed(2)}",
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      // Tax
      if (taxAmount > 0) {
        final cgst = taxAmount / 2;
        final sgst = taxAmount / 2;

        bytes += generator.row([
          PosColumn(width: 8, text: "CGST@2.5%"),
          PosColumn(
            width: 4,
            text: cgst.toStringAsFixed(2),
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        bytes += generator.row([
          PosColumn(width: 8, text: "SGST@2.5%"),
          PosColumn(
            width: 4,
            text: sgst.toStringAsFixed(2),
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      // Coupon
      if (couponDiscount.abs() > 0) {
        String couponLabel = "Coupon";
        if (couponDetails != null && couponDetails.isNotEmpty) {
          final codes = couponDetails.map((c) {
            if (c is Map) {
              return c['code']?.toString() ?? '';
            } else {
              try {
                return (c as dynamic).code?.toString() ?? '';
              } catch (_) {
                return '';
              }
            }
          }).where((code) => code.isNotEmpty).join(", ");
          if (codes.isNotEmpty) {
            couponLabel = "Coupon ($codes)";
          }
        }
        bytes += generator.row([
          PosColumn(width: 8, text: couponLabel),
          PosColumn(
            width: 4,
            text: "-${couponDiscount.abs().toStringAsFixed(2)}",
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      // Merchant Discount
      if (merchantDiscount.abs() > 0) {
        bytes += generator.row([
          PosColumn(width: 8, text: "Merchant Discount"),
          PosColumn(
            width: 4,
            text: "-${merchantDiscount.abs().toStringAsFixed(2)}",
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      // Service Charge
      if (serviceCharge > 0) {
        bytes += generator.row([
          PosColumn(width: 8, text: "Service Charge"),
          PosColumn(
            width: 4,
            text: serviceCharge.toStringAsFixed(2),
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
      bytes += generator.hr(ch: '=');

      final rawTotal =
          grossTotal -
          couponDiscount.abs() -
          merchantDiscount.abs() +
          taxAmount +
          serviceCharge +
          tipAmount;
      final roundedNetPayable = netPayable.roundToDouble();
      final roundOff =
          roundedNetPayable > 0 ? (roundedNetPayable - rawTotal) : 0.0;
      final grandTotal = roundedNetPayable;

      bytes += generator.row([
        PosColumn(width: 6, text: ""),
        PosColumn(
          width: 6,
          text: "Round off  ${roundOff.toStringAsFixed(2)}",
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.hr(ch: '=');

      bytes += generator.row([
        PosColumn(
          width: 6,
          text: "Grand Total",
          styles: const PosStyles(bold: true, height: PosTextSize.size2),
        ),
        PosColumn(
          width: 6,
          text: grandTotal.toStringAsFixed(2),
          styles: const PosStyles(
            bold: true,
            align: PosAlign.right,
            height: PosTextSize.size2,
          ),
        ),
      ]);
      bytes += generator.hr(ch: '=');

      bytes += generator.text(
        "Thank You Visit Again...!",
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      bytes += generator.text(
        "Service charge is optional",
        styles: const PosStyles(align: PosAlign.center),
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

      await printerSettings.printTicket(bytes, generator);
    } catch (e) {
      debugPrint("Print Bill Error: $e");
    }
  }
}
