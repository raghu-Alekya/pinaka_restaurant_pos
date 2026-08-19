import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../models/UserPermissions.dart';
import '../../models/payment/payment_summary_model.dart';
import '../../printer/printer_service.dart';
import '../../printer/printer_db_helper.dart';
import '../../printer/printer_settings.dart';
import '../../services/kds_seivices.dart';
import '../ui/dashboard screen.dart';
import '../ui/tables_screen.dart';

// Add these imports for printer functionality
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';
import 'package:thermal_printer/thermal_printer.dart';

class PrintRecipt extends StatefulWidget {
  final PaymentSummary paymentSummary;
  final String cashierName;
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final List<Map<String, dynamic>> loadedTables;
  final int? zoneId;
  final bool isTakeAway;
  final UserPermissions? userPermissions;
  final bool isFromOrderDetails;
  final bool isCopy;

  const PrintRecipt({
    Key? key,
    required this.paymentSummary,
    required this.cashierName,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    required this.loadedTables,
    this.zoneId,
    this.isTakeAway = false,
    this.userPermissions,
    this.isFromOrderDetails = false,
    this.isCopy = false,
  }) : super(key: key);

  @override
  State<PrintRecipt> createState() => _PrintReciptState();
}

class _PrintReciptState extends State<PrintRecipt> {
  String _selectedOption = 'Printer';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  final List<String> options = ['Printer', 'Email', 'SMS'];

  // Add printing guard
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _selectedOption = 'Printer';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _smsController.dispose();
    super.dispose();
  }



  // ============ BILL GENERATION METHOD (copied from TopBar) ============
  Future<List<int>> _generateBillBytes(PaymentSummary summary) async {
    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm80, profile);

    List<int> bytes = [];

    // Restaurant Header
    final prefs = await SharedPreferences.getInstance();
    final restaurantName = prefs.getString('store_name') ?? 'Restaurant';
    final address = prefs.getString('store_address') ?? '';
    final phone = prefs.getString('store_phone') ?? '';
    final gstNumber = prefs.getString('store_gst') ?? '';

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
        "GSTIN: $gstNumber",
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    if (phone.isNotEmpty) {
      bytes += generator.text(
        "Ph: $phone",
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr();

    // Bill Details
    bytes += generator.row([
      PosColumn(
        width: 6,
        text:
            "Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      ),
      PosColumn(
        width: 6,
        text: "Table: ${summary.tableName}",
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row([
      PosColumn(
        width: 6,
        text:
            "Cashier: ${widget.cashierName.isNotEmpty ? widget.cashierName : widget.userPermissions?.displayName ?? 'Admin'}",
      ),
      PosColumn(
        width: 6,
        text: "Order: ${summary.orderId}",
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr();

    // Column Header
    bytes += generator.row([
      PosColumn(width: 6, text: "Item", styles: const PosStyles(bold: true)),
      PosColumn(
        width: 2,
        text: "Qty",
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
      PosColumn(
        width: 2,
        text: "Price",
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        width: 2,
        text: "Amt",
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr();

    // Items
    for (final item in summary.lineItems) {
      final qty = item.qty.toString();
      final price = item.price.toStringAsFixed(2);
      final amount = item.total.toStringAsFixed(2);

      bytes += generator.row([
        PosColumn(width: 6, text: item.name),
        PosColumn(
          width: 2,
          text: qty,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          width: 2,
          text: price,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          width: 2,
          text: amount,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      // Modifiers
      if (item.modifiers != null && item.modifiers.isNotEmpty) {
        for (var modifier in item.modifiers) {
          bytes += generator.row([
            PosColumn(width: 6, text: "  + $modifier"),
            PosColumn(width: 2, text: ""),
            PosColumn(width: 2, text: ""),
            PosColumn(width: 2, text: ""),
          ]);
        }
      }
    }

    bytes += generator.hr();

    // Totals
    bytes += generator.row([
      PosColumn(
        width: 8,
        text: "Subtotal",
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        width: 4,
        text: summary.grossTotal.toStringAsFixed(2),
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    if (summary.coupons > 0) {
      bytes += generator.row([
        PosColumn(width: 8, text: "Coupon Discount"),
        PosColumn(
          width: 4,
          text: "-${summary.coupons.toStringAsFixed(2)}",
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    if (summary.discount > 0) {
      bytes += generator.row([
        PosColumn(width: 8, text: "Merchant Discount"),
        PosColumn(
          width: 4,
          text: "-${summary.discount.toStringAsFixed(2)}",
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    if (summary.tipAmount > 0) {
      bytes += generator.row([
        PosColumn(width: 8, text: "Tip"),
        PosColumn(
          width: 4,
          text: summary.tipAmount.toStringAsFixed(2),
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    if (summary.tax > 0) {
      bytes += generator.row([
        PosColumn(width: 8, text: "Tax"),
        PosColumn(
          width: 4,
          text: summary.tax.toStringAsFixed(2),
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    if (summary.serviceChargeValue > 0) {
      bytes += generator.row([
        PosColumn(width: 8, text: "Service Charge"),
        PosColumn(
          width: 4,
          text: summary.serviceChargeValue.toStringAsFixed(2),
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    // Net Total
    bytes += generator.row([
      PosColumn(
        width: 8,
        text: "TOTAL",
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        width: 4,
        text: summary.netTotal.toStringAsFixed(2),
        styles: const PosStyles(
          bold: true,
          align: PosAlign.right,
          height: PosTextSize.size2,
        ),
      ),
    ]);

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  // ============ CORE PRINTING LOGIC ============
  // ============ CORE PRINTING LOGIC ============
  Future<void> _printToPrinter() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      debugPrint("========== PRINTING BILL FROM PRINT RECEIPT ==========");
      debugPrint("Order ID: ${widget.paymentSummary.orderId}");
      debugPrint("Table Name: ${widget.paymentSummary.tableName}");
      debugPrint(
        "Cashier: ${widget.cashierName.isNotEmpty ? widget.cashierName : widget.userPermissions?.displayName ?? 'Admin'}",
      );
      debugPrint("Net Payable: ${widget.paymentSummary.netTotal}");

      // Get an ORDERED LIST of printer candidates instead of just one,
      // so a stale/duplicate DB row can't block printing entirely.
      final candidates = await _getCashPrinterCandidates();
      debugPrint("🔍 Printer candidates -> $candidates");

      if (candidates.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No printer selected. Please set up a printer in settings.",
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        setState(() => _isPrinting = false);
        return;
      }

      List<int> bytes = await _generateBillBytes(widget.paymentSummary);

      bool printedOk = false;
      String lastTriedName = '';

      // Try each candidate in order until one actually connects and prints.
      for (final cashPrinter in candidates) {
        final address = cashPrinter['address'] ?? '';
        final name = cashPrinter['name'] ?? 'Cash Printer';
        final port = cashPrinter['port'] ?? '9100';
        final type = cashPrinter['type'] ?? 'network';
        final vendorId = cashPrinter['vendorId'];
        final productId = cashPrinter['productId'];
        lastTriedName = name;

        // Only network printers truly require a non-empty address
        if (type == 'network' && address.isEmpty) {
          debugPrint("⏭️ Skipping '$name': type=network but address is empty");
          continue;
        }

        try {
          debugPrint(
            "🖨️ Trying to print bill to: $name (type=$type, address='$address', port=$port, vendorId=$vendorId, productId=$productId)",
          );

          bool connected = false;
          PrinterType sendType;

          switch (type) {
            case 'usb':
              sendType = PrinterType.usb;
              connected = await PrinterManager.instance.connect(
                type: PrinterType.usb,
                model: UsbPrinterInput(
                  name: name,
                  vendorId: vendorId,
                  productId: productId,
                ),
              );
              break;

            case 'bluetooth':
              sendType = PrinterType.bluetooth;
              connected = await PrinterManager.instance.connect(
                type: PrinterType.bluetooth,
                model: BluetoothPrinterInput(
                  name: name,
                  address: address,
                  isBle: false,
                  autoConnect: false,
                ),
              );
              break;

            case 'network':
            default:
              sendType = PrinterType.network;
              connected = await PrinterManager.instance.connect(
                type: PrinterType.network,
                model: TcpPrinterInput(ipAddress: address),
              );
              break;
          }

          debugPrint("🔌 Connect result for $name ($type): $connected");

          if (connected) {
            final sendResult = await PrinterManager.instance.send(
              type: sendType,
              bytes: bytes,
            );
            debugPrint("📤 Send result: $sendResult");

            await PrinterManager.instance.disconnect(type: sendType);
            debugPrint("🔌 Disconnected from $name");

            debugPrint(
              "✅ Bill successfully printed to: $name ($type - $address)",
            );

            printedOk = true;
            break; // stop at the first successful printer
          } else {
            debugPrint(
              "❌ Failed to connect to printer: $name ($type - $address), trying next candidate if any...",
            );
          }
        } catch (e, stack) {
          debugPrint("❌ Error printing bill to $name: $e");
          debugPrint("Stack trace: $stack");
          try {
            final fallbackType =
                type == 'usb'
                    ? PrinterType.usb
                    : type == 'bluetooth'
                    ? PrinterType.bluetooth
                    : PrinterType.network;
            await PrinterManager.instance.disconnect(type: fallbackType);
          } catch (_) {}
          // fall through to try the next candidate
        }
      }

      if (mounted) {
        if (printedOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Receipt printed successfully"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed to connect to any selected printer (last tried: $lastTriedName)",
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stack) {
      debugPrint("Print Bill Error: $e");
      debugPrint("Stack trace: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to print: ${e.toString().replaceFirst('Exception: ', '')}",
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getCashPrinterCandidates() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> printers = [];

    final printerDb = PrinterDBHelper();
    final dbPrinters = await printerDb.getSelectedPrintersFromDB();

    for (var printer in dbPrinters) {
      final address = printer['printer_address'] ?? '';
      var name = printer['deviceName'] ?? printer['device_name'] ?? 'Printer';
      String type = printer[AppDBConst.printerType] ?? 'network';

      final vendorIdRaw = printer[AppDBConst.printerVendorId]?.toString() ?? '';
      final productIdRaw =
          printer[AppDBConst.printerProductId]?.toString() ?? '';
      final vendorIdIsBad = vendorIdRaw.isEmpty || vendorIdRaw == 'network';
      final productIdIsBad = productIdRaw.isEmpty || productIdRaw == 'network';

      // Self-heal garbage vendorId/productId ("network" literal) left over
      // from older buggy saves — these broke USB connect() on Windows.
      if (type == 'usb' &&
          (vendorIdRaw == 'network' || productIdRaw == 'network')) {
        debugPrint(
          "⚠️ Detected garbage vendorId/productId ('network') for '$name' — clearing in DB",
        );
        await printerDb.fixPrinterRecord(
          address: address,
          currentDeviceName: name,
          clearVendorId: vendorIdRaw == 'network',
          clearProductId: productIdRaw == 'network',
        );
      }

      // Self-heal mis-saved network printers
      if (type == 'network' && address.isEmpty) {
        debugPrint(
          "⚠️ Detected mis-saved printer type for '$name' — correcting network -> usb",
        );
        type = 'usb';
        await printerDb.fixPrinterRecord(
          address: address,
          currentDeviceName: name,
          correctedType: 'usb',
        );
      }

      // 🔧 SELF-HEAL: If USB printer name was corrupted to 'Cash Printer' or 'KOT Printer',
      // restore the actual OS device name from SharedPreferences
      if (type == 'usb' && (name == 'Cash Printer' || name == 'KOT Printer')) {
        final spJson = prefs.getString('selected_printers');
        if (spJson != null && spJson.isNotEmpty) {
          try {
            final List<dynamic> spList = jsonDecode(spJson);
            for (var p in spList) {
              final spName = (p['name'] ?? p['deviceName'] ?? '').toString();
              final spType = (p['type'] ?? 'usb').toString();
              if (spName.isNotEmpty &&
                  spName != 'Cash Printer' &&
                  spName != 'KOT Printer' &&
                  (spType == 'usb' || (p['address'] ?? '').toString().isEmpty)) {
                debugPrint(
                  "🔧 Restored corrupted USB printer device name '$name' -> '$spName'",
                );
                await printerDb.fixPrinterRecord(
                  address: address,
                  currentDeviceName: name,
                  correctedName: spName,
                );
                name = spName;
                break;
              }
            }
          } catch (e) {
            debugPrint("Error restoring printer name: $e");
          }
        }
      }

      printers.add({
        'address': address,
        'name': name,
        'port': printer['port'] ?? '9100',
        'type': type,
        'vendorId': vendorIdIsBad ? null : vendorIdRaw,
        'productId': productIdIsBad ? null : productIdRaw,
      });
    }

    // Fallback: SharedPreferences
    if (printers.isEmpty) {
      final selectedPrintersJson = prefs.getString('selected_printers');
      if (selectedPrintersJson != null && selectedPrintersJson.isNotEmpty) {
        try {
          final List<dynamic> selectedList = jsonDecode(selectedPrintersJson);
          for (var printer in selectedList) {
            final address = printer['address'] ?? '';
            final name = printer['name'] ?? 'Printer';
            String type = printer['type'] ?? 'network';
            if (type == 'network' && address.isEmpty) type = 'usb';

            final vendorIdRaw = printer['vendorId']?.toString() ?? '';
            final productIdRaw = printer['productId']?.toString() ?? '';
            final vendorIdIsBad =
                vendorIdRaw.isEmpty || vendorIdRaw == 'network';
            final productIdIsBad =
                productIdRaw.isEmpty || productIdRaw == 'network';

            printers.add({
              'address': address,
              'name': name,
              'port': printer['port'] ?? '9100',
              'type': type,
              'vendorId': vendorIdIsBad ? null : vendorIdRaw,
              'productId': productIdIsBad ? null : productIdRaw,
            });
          }
        } catch (e) {
          debugPrint("Error parsing selected printers: $e");
        }
      }
    }

    if (printers.isEmpty) return [];

    // Order candidates: cash-named first, then everything else.
    final List<Map<String, dynamic>> cashNamed = [];
    final List<Map<String, dynamic>> others = [];
    for (var p in printers) {
      final n = (p['name'] as String? ?? '').toLowerCase();
      if (n == 'cash printer' || n.contains('cash')) {
        cashNamed.add(p);
      } else {
        others.add(p);
      }
    }

    // Prefer position convention (2nd selected printer) if no name match
    if (cashNamed.isEmpty && others.length > 1) {
      final secondPrinter = others.removeAt(1);
      others.insert(0, secondPrinter);
    }

    return [...cashNamed, ...others];
  }

  Future<void> _onDonePressed({bool isNoReceipt = false}) async {
    if (!isNoReceipt) {
      // Validation
      if (_selectedOption == 'Email') {
        final email = _emailController.text.trim();

        if (email.isEmpty || !email.contains("@")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter a valid email address"),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (_selectedOption == 'SMS') {
        final sms = _smsController.text.trim();

        if (sms.isEmpty || sms.length != 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter a valid phone number"),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Print receipt
      if (_selectedOption == 'Printer') {
        await _printToPrinter();
      }
    }

    // STEP 1: CLOSE PRINT DIALOG
    Navigator.of(context).pop();

    if (widget.isFromOrderDetails) {
      return;
    }

    // ==========================================================
    // STEP 2: SEND TAKEAWAY COMPLETED EVENT TO KDS
    // ==========================================================

    if (widget.isTakeAway) {
      try {
        final parentOrderId =
        int.tryParse(widget.paymentSummary.orderId.toString());

        debugPrint('========== TAKEAWAY COMPLETE ==========');
        debugPrint(
          'Payment Order ID: ${widget.paymentSummary.orderId}',
        );
        debugPrint(
          'Parsed Parent Order ID: $parentOrderId',
        );
        debugPrint(
          'Restaurant ID: ${widget.restaurantId}',
        );

        if (parentOrderId != null) {
          final orderState = context.read<OrderBloc>().state;

          final kotId = orderState.kotList.isNotEmpty
              ? orderState.kotList.first.kotId
              : null;

          final kotNumber = orderState.kotList.isNotEmpty
              ? orderState.kotList.first.kotNumber
              : null;

          await KdsMqttPublisher.notifyTakeawayCompleted(
            restaurantId: widget.restaurantId,
            parentOrderId: parentOrderId,
            kotId: kotId,
            kotNumber: kotNumber,
          );

          debugPrint(
              '========== TAKEAWAY MQTT SENT =========='
          );
        } else {
          debugPrint(
            '❌ Could not parse parentOrderId',
          );
        }
      } catch (e, stack) {
        debugPrint(
          '❌ Takeaway MQTT error: $e',
        );
        debugPrint(
          'Stack: $stack',
        );
      }
    }

    // ==========================================================
    // STEP 3: CLEAR ORDER STATE
    // ==========================================================

    context.read<OrderBloc>().add(ResetOrder());

    // Small delay ensures Bloc processes event
    await Future.delayed(
      const Duration(milliseconds: 100),
    );

    if (!mounted) return;

    // ==========================================================
    // STEP 4: NAVIGATE
    // ==========================================================

    if (widget.isTakeAway) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            pin: widget.pin,
            token: widget.token,
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            userPermissions: widget.userPermissions,
            isTakeAway: true,
          ),
        ),
            (route) => false,
      );
    } else {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TablesScreen(
            loadedTables: widget.loadedTables,
            pin: widget.pin,
            token: widget.token,
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            zoneId: widget.zoneId,
          ),
        ),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      height: MediaQuery.of(context).size.height * 0.60,
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2D3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/icon/printer.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Please choose how you'd like to",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4C5F7D),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "share it.",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4C5F7D),
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children:
                  options.map((option) {
                    final bool isSelected = _selectedOption == option;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedOption = option;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? (isDark
                                      ? const Color(0xFF4A1E1E)
                                      : Colors.red.shade50)
                                  : (isDark
                                      ? const Color(0xFF353847)
                                      : Colors.white),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.redAccent
                                    : (isDark
                                        ? Colors.white24
                                        : const Color(0xFFE7E2E2)),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: option,
                              groupValue: _selectedOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedOption = value!;
                                });
                              },
                              activeColor: Colors.redAccent,
                              fillColor: WidgetStateProperty.resolveWith<Color>(
                                (states) =>
                                    isDark ? Colors.white : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFFAFACAC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _selectedOption == 'Email'
                        ? _buildTextField(
                          hintText: 'Enter Email Address',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        )
                        : _selectedOption == 'SMS'
                        ? _buildTextField(
                          hintText: 'Enter phone number',
                          controller: _smsController,
                          keyboardType: TextInputType.number,
                        )
                        : const SizedBox.shrink(),
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDialogButton(
                  label: 'No Receipt',
                  color:
                      isDark
                          ? const Color(0xFF4A4C5A)
                          : const Color(0xFFECEEF2),
                  textColor: isDark ? Colors.white : const Color(0xFF4C5F7D),
                  onTap: () => _onDonePressed(isNoReceipt: true),
                ),
                const SizedBox(width: 20),
                _buildDialogButton(
                  label: 'Done',
                  color:
                      isDark
                          ? const Color(0xFF22B07D)
                          : const Color(0xFF1BA672),
                  textColor: Colors.white,
                  onTap: () => _onDonePressed(isNoReceipt: false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<TextInputFormatter> inputFormatters = [];

    if (keyboardType == TextInputType.number) {
      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ];
    } else if (keyboardType == TextInputType.emailAddress) {
      inputFormatters = [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._]')),
        LengthLimitingTextInputFormatter(32),
      ];
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF353847) : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFE7E2E2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.35)
                    : const Color(0xFFE7E2E2),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        cursorColor: isDark ? Colors.white : Colors.black,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.45) : Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
