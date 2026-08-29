//order_screen

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/payment_screen.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';
import 'package:thermal_printer/thermal_printer.dart';

import '../../blocs/Bloc Event/kot_event.dart';
import '../../blocs/Bloc Event/kot_event.dart' as kot_evt;
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/auth_bloc.dart';
import '../../blocs/Bloc Logic/checkin_bloc.dart';
import '../../blocs/Bloc Logic/discount_bloc.dart';
import '../../blocs/Bloc Logic/kot_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc Logic/void_item_bloc.dart';
import '../../blocs/Bloc State/checkin_state.dart';
import '../../blocs/Bloc State/kot_state.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../constants/constants.dart';
import '../../local database/login_dao.dart';
import '../../local database/table_dao.dart';
import '../../models/order/order_items.dart';
import '../../models/order/KOT_model.dart';
import '../../models/order/guest_details.dart';
import '../../printer/printer_db_helper.dart';
import '../../printer/printer_settings.dart';
import '../../repositories/checkin_repository.dart';
import '../../repositories/discount_repository.dart';
import '../../repositories/kot_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/payment_summary_repository.dart';
import '../../repositories/void_item_repository.dart';
import '../../services/kds_seivices.dart';
import '../../utils/SessionManager.dart';
import '../../utils/logger.dart';
import '../widgets/confirmation_pop_up.dart';
import '../widgets/orderlist_widget.dart';
import '../widgets/view_all_kots.dart';
import 'guest_details_popup.dart';

class OrderPanel extends StatefulWidget {
  final Function(int) onGuestSaved;
  final Map<String, double> addonPrices;
  final String token;
  final String restaurantId;
  final Guestcount guestcount;
  final bool isTakeAway;
  final int orderId;
  final int tableId;
  final String tableName;
  final int zoneId;
  final String zoneName;
  final List<Map<String, dynamic>> placedTables;
  final String pin;
  final String restaurantName;
  final List<OrderItems>? existingOrderItems;
  final List<KotModel>? existingKots;
  final String userId;
  final List<Map<String, dynamic>> loadedTables;

  const OrderPanel({
    super.key,
    required this.onGuestSaved,
    required this.addonPrices,
    required this.token,
    required this.restaurantId,
    required this.guestcount,
    required this.orderId,
    required this.tableId,
    required this.tableName,
    required this.zoneId,
    required this.zoneName,
    required this.placedTables,
    required this.pin,
    required this.restaurantName,
    this.existingOrderItems,
    this.existingKots,
    required this.userId,
    required this.loadedTables,
    this.isTakeAway = false,
  });

  @override
  State<OrderPanel> createState() => _OrderPanelState();
}

class _OrderPanelState extends State<OrderPanel> {
  StreamSubscription? _mqttSubscription;
  bool _isRepeatingOrder = false;
  bool _showKotList = false; // Track KOT dropdown expansion state
  String _currency = "₹";
  @override
  void initState() {
    super.initState();
    _initMqttStatusListener();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }

  Future<void> _initMqttStatusListener() async {
    await KdsMqttPublisher.listenForKdsStatusUpdates(
      restaurantId: widget.restaurantId,
    );

    _mqttSubscription = KdsMqttPublisher.statusUpdates.listen((data) {
      print('MQTT Status Received => $data');

      context.read<OrderBloc>().add(
        UpdateKotStatusInOrder(
          kotNumber: data['kot_number'].toString(),
          status: data['status'].toString(),
          remainingItems:
              data['remaining_items'] != null
                  ? List<Map<String, dynamic>>.from(data['remaining_items'])
                  : null,
        ),
      );
    });
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();
    super.dispose();
  }

  List<String> _wrapText(String text, int maxLength) {
    if (text.isEmpty) return [''];
    List<String> lines = [];
    List<String> words = text.split(' ');
    String currentLine = '';

    for (String word in words) {
      if (word.isEmpty) continue;

      if (word.length > maxLength) {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = '';
        }
        int start = 0;
        while (start < word.length) {
          int end = start + maxLength;
          if (end > word.length) {
            end = word.length;
          }
          lines.add(word.substring(start, end));
          start = end;
        }
        continue;
      }

      if (currentLine.isEmpty) {
        currentLine = word;
      } else if (currentLine.length + 1 + word.length <= maxLength) {
        currentLine += ' ' + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines.isEmpty ? [''] : lines;
  }

  Future<void> printKot({
    required String kotNo,
    required String orderId,
    required String tableName,
    required String captainName,
    required List<Map<String, dynamic>> items,
    required KotModel kot,
  }) async {
    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm80, profile);

    List<int> bytes = [];
    bytes += [27, 32, 0]; // Reset character spacing to 0 right at the start
    final displayKotNo = kotNo.replaceAll('KOT#', '');

    bytes += generator.text(
      "KOT - $displayKotNo",
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size3,
        width: PosTextSize.size2,
      ),
    );

    final orderType = widget.isTakeAway ? "Take Away" : "Dine In";
    final dineInTitle =
        widget.isTakeAway
            ? "Take Away"
            : (tableName.isNotEmpty ? "$orderType: $tableName" : orderType);

    bytes += generator.text(
      dineInTitle,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size3,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.hr();
    // table row

    final now = DateTime.now();
    final dateText = "Date: ${DateFormat('dd/MM/yyyy').format(now)}";
    final timeText = "Time: ${DateFormat('hh:mm a').format(now)}";

    bytes += generator.row([
      PosColumn(width: 6, text: dateText, styles: const PosStyles(bold: true)),
      PosColumn(
        width: 6,
        text: timeText,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    // add a row of space between date row and Order id row
    bytes += [27, 74, 16];

    // order /captain row

    final orderIdText = "Order Id: $orderId";
    final captainText = "Captain: $captainName";

    if ((orderIdText.length + captainText.length) < 45) {
      bytes += generator.row([
        PosColumn(
          width: 5,
          text: orderIdText,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          width: 7,
          text: captainText,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    } else {
      bytes += generator.text(
        orderIdText,
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      bytes += generator.text(
        captainText,
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
    }

    bytes += generator.hr();
    //  header

    // Set character spacing to 3 dots for items and headers
    bytes += [27, 32, 3];

    bytes += generator.row([
      PosColumn(width: 2, text: "S.No", styles: const PosStyles(bold: true)),
      PosColumn(
        width: 8,
        text: "Item Name",
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        width: 2,
        text: "Qty",
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    bytes += [
      27,
      32,
      0,
    ]; // Temporarily reset character spacing to 0 for divider
    bytes += generator.hr();
    bytes += [27, 32, 3]; // Set character spacing back to 3 for items

    // items
    int index = 1;

    for (final item in items) {
      final nameLines = _wrapText(item['name'].toString(), 22);

      bytes += generator.row([
        PosColumn(
          width: 2,
          text: index.toString(),
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
        PosColumn(
          width: 8,
          text: nameLines.first,
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
        PosColumn(
          width: 2,
          text: "x ${item['qty']}",
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
      ]);

      // Print remaining lines of item name aligned underneath
      for (int i = 1; i < nameLines.length; i++) {
        bytes += generator.row([
          PosColumn(
            width: 2,
            text: "",
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
          PosColumn(
            width: 8,
            text: nameLines[i],
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
          PosColumn(
            width: 2,
            text: "",
            styles: const PosStyles(
              align: PosAlign.right,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
        ]);
      }

      // Modifiers
      if (item['modifiers'] != null && (item['modifiers'] as List).isNotEmpty) {
        bytes += generator.row([
          PosColumn(width: 2, text: ""),
          PosColumn(
            width: 10,
            text: " + ${(item['modifiers'] as List).join(', ')}",
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
        ]);
      }

      // Addons
      if (item['addons'] != null && (item['addons'] as Map).isNotEmpty) {
        final addons = item['addons'] as Map<String, dynamic>;

        addons.forEach((name, details) {
          bytes += generator.row([
            PosColumn(width: 2, text: ""),
            PosColumn(
              width: 10,
              text: "   * $name x${details['quantity']}",
              styles: const PosStyles(
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size1,
              ),
            ),
          ]);
        });
      }

      // Item Note / Remarks
      final note = (item['note'] ?? item['remarks'] ?? '').toString();
      if (note.isNotEmpty) {
        bytes += generator.row([
          PosColumn(width: 2, text: ""),
          PosColumn(
            width: 10,
            text: " Note: $note",
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size1,
            ),
          ),
        ]);
      }

      // Thin spacing between item rows (10 dots = 1.25mm)
      bytes += [27, 74, 16];

      index++;
    }
    //  footer

    // Restore standard character spacing (0 dots) for footer and hr dividers
    bytes += [27, 32, 0];

    bytes += generator.hr();

    bytes += generator.text(
      "Note :",
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.feed(3);
    bytes += generator.cut();

    // First, try to get selected printers from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final selectedPrintersJson = prefs.getString('selected_printers');

    // Also get from database as fallback
    final printerDb = PrinterDBHelper();
    final dbPrinters = await printerDb.getSelectedPrintersFromDB();

    // Collect all printer addresses to print to
    List<Map<String, dynamic>> printersToPrint = [];

    // Add from SharedPreferences
    if (selectedPrintersJson != null && selectedPrintersJson.isNotEmpty) {
      try {
        final List<dynamic> selectedList = jsonDecode(selectedPrintersJson);
        for (var printer in selectedList) {
          final address = printer['address'] ?? '';
          final name = printer['name'] ?? 'Printer';
          if (address.isNotEmpty) {
            printersToPrint.add({
              'address': address,
              'name': name,
              'port': printer['port'] ?? '9100',
            });
          }
        }
      } catch (e) {
        debugPrint("Error parsing selected printers: $e");
      }
    }

    // Add from Database (if not already added)
    for (var printer in dbPrinters) {
      final address = printer['printer_address'] ?? '';
      if (address.isNotEmpty) {
        final exists = printersToPrint.any((p) => p['address'] == address);
        if (!exists) {
          printersToPrint.add({
            'address': address,
            'name':
                printer['deviceName'] ?? printer['device_name'] ?? 'Printer',
            'port': printer['port'] ?? '9100',
          });
        }
      }
    }

    // ============================================
    // 🆕 NEW: Find KOT Printer (first printer with "KOT" in name)
    // ============================================

    // Try to find KOT Printer
    Map<String, dynamic>? kotPrinter;
    List<Map<String, dynamic>> otherPrinters = [];

    for (var printer in printersToPrint) {
      final name = printer['name']?.toLowerCase() ?? '';
      // Check if this is the KOT Printer (exact match or contains "kot")
      if (name == 'kot printer' || name.contains('kot')) {
        kotPrinter = printer;
      } else {
        otherPrinters.add(printer);
      }
    }

    // If KOT Printer is not found, use the first printer (fallback)
    if (kotPrinter == null && printersToPrint.isNotEmpty) {
      debugPrint("⚠️ KOT Printer not found. Using first printer as fallback.");
      kotPrinter = printersToPrint.first;
    }

    // If no printers found, try the old single printer method
    if (kotPrinter == null) {
      final printerSettings = PrinterSettings();
      await printerSettings.loadPrinter();

      if (printerSettings.selectedPrinter != null) {
        try {
          await printerSettings.printTicket(bytes, generator);
          debugPrint("KOT printed to single printer (legacy mode)");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("KOT printed successfully"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          }
        } catch (e) {
          debugPrint("KOT print error: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("KOT print failed: $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        debugPrint("KOT print: No printer selected");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No printer selected. Please set up a printer in settings.",
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
      return;
    }

    // ============================================
    // 🆕 PRINT KOT ONLY TO KOT PRINTER
    // ============================================

    final address = kotPrinter['address'] ?? '';
    final name = kotPrinter['name'] ?? 'KOT Printer';
    final port = kotPrinter['port'] ?? '9100';

    if (address.isEmpty) {
      debugPrint("❌ KOT Printer address is empty");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("KOT Printer address is invalid"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      debugPrint("🖨️ Printing KOT to: $name ($address:$port)");

      // Connect to printer
      final connected = await PrinterManager.instance.connect(
        type: PrinterType.network,
        model: TcpPrinterInput(ipAddress: address),
      );

      if (connected) {
        // Send data
        await PrinterManager.instance.send(
          type: PrinterType.network,
          bytes: bytes,
        );
        // Disconnect
        await PrinterManager.instance.disconnect(type: PrinterType.network);

        debugPrint("✅ KOT successfully printed to: $name ($address)");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("KOT printed successfully to KOT Printer"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint("❌ Failed to connect to KOT Printer: $name ($address)");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to connect to KOT Printer"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Error printing KOT to $name: $e");
      // Try to disconnect if still connected
      try {
        await PrinterManager.instance.disconnect(type: PrinterType.network);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error printing KOT: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder(int currentOrderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final orderRepo = OrderRepository(baseUrl: AppConstants.baseDomain);

      final orderState = context.read<OrderBloc>().state;
      final isTakeAway = widget.isTakeAway;

      Map<String, dynamic>? responseJson;

      // =====================
      // TAKEAWAY FLOW
      // =====================
      if (isTakeAway) {
        await orderRepo.cancelTakeAwayOrder(
          parentOrderId: currentOrderId,
          restaurantId: int.parse(orderState.restaurantId),
          token: widget.token,
        );

        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        context.read<OrderBloc>().add(
          CancelOrder(parentOrderId: currentOrderId, token: widget.token),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Takeaway order cancelled successfully"),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // =====================
      // DINE-IN FLOW
      // =====================
      responseJson = await orderRepo.cancelOrder(
        parentOrderId: currentOrderId,
        token: widget.token,
        restaurantId: widget.restaurantId,
        zoneId: widget.zoneId,
      );

      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (responseJson['status'] == 'cancelled') {
        context.read<OrderBloc>().add(
          CancelOrder(parentOrderId: currentOrderId, token: widget.token),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text(
              "Order ${responseJson['order_id']} cancelled successfully",
            ),
            backgroundColor: Colors.red,
          ),
        );

        final tableDao = TableDao();
        final tables = await tableDao.getTablesByManagerPin(widget.pin);

        if (!context.mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => TablesScreen(
                  loadedTables: tables,
                  pin: widget.pin,
                  token: widget.token,
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 1),
            content: Text("Failed to cancel order"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  // Widget build(BuildContext context) {
  //   // 1️⃣ Trigger KOT loading for existing order
  //   final orderBloc = context.read<OrderBloc>();
  //   final kotBloc = context.read<KotBloc>();
  //
  //   // ✅ Initialize OrderBloc with existing order items if not already loaded
  //   if (widget.orderId != 0 && orderBloc.state.orderId != widget.orderId) {
  //     orderBloc.add(
  //       LoadExistingOrder(
  //         orderId: widget.orderId,
  //         tableId: widget.tableId,
  //         zoneId: widget.zoneId,
  //         tableName: widget.tableName,
  //         zoneName: widget.zoneName,
  //         kotList: widget.existingKots ?? [],
  //         restaurantId: widget.restaurantId,
  //         guestDetails: widget.guestcount,
  //       ),
  //     );
  //   }
  //
  //   // ✅ Initialize KotBloc with existing KOTs if not already loaded
  //   if (widget.orderId != 0 &&
  //       widget.existingKots != null &&
  //       (kotBloc.state is! KotLoaded ||
  //           (kotBloc.state as KotLoaded).kots.isEmpty)) {
  //     context.read<KotBloc>().add(SetExistingKots(kots: widget.existingKots!));
  //   }
  //
  //   return BlocListener<KotBloc, KotState>(
  //     listener: (context, kotState) {
  //       if (kotState is KotLoaded) {
  //         debugPrint("KotLoaded: ${kotState.kots.length}");
  //         context.read<OrderBloc>().add(RefreshKotList(kotState.kots));
  //       }
  //     },
  //     child: BlocBuilder<OrderBloc, OrderState>(
  //       builder: (context, state) {
  //         // take away order flow
  //         final bool hasOrder = state.orderId > 0;
  //         // disable buttons
  //         final bool hasCartItems = state.orderItems.isNotEmpty;
  //
  //         final activeKots =
  //         state.kotList.where((kot) {
  //           final status = (kot.status ?? '').toLowerCase();
  //
  //           return status != 'served' &&
  //               status != 'voided' &&
  //               status != 'transferred';
  //         }).toList();
  //
  //         final bool hasActiveKot = activeKots.isNotEmpty;
  //         debugPrint("========== KOTS ==========");
  //         for (final kot in state.kotList) {
  //           debugPrint("KOT: ${kot.kotNumber} | Status: ${kot.status}");
  //         }
  //
  //         debugPrint("Total KOTs: ${state.kotList.length}");
  //         debugPrint("Active KOTs: ${activeKots.length}");
  //
  //         /// Repeat Order -> only if active KOT exists
  //         final bool canRepeatOrder = hasActiveKot;
  //
  //         /// KOT Print -> only if cart contains items
  //         final bool canPrintKot = hasCartItems;
  //
  //         /// Pay -> only if active KOT exists
  //         final bool canPay = hasActiveKot;
  //
  //         return Container(
  //           width: 700,
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(16),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               /// Header row with badges & actions
  //               Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 16,
  //                   vertical: 12,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(14),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black.withOpacity(.05),
  //                       blurRadius: 8,
  //                       offset: const Offset(0, 2),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Row(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     /// LEFT SIDE
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           /// Order ID
  //                           Row(
  //                             children: [
  //                               Image.asset(
  //                                 "assets/order.png",
  //                                 width: 18,
  //                                 height: 18,
  //                               ),
  //                               const SizedBox(width: 6),
  //                               Text(
  //                                 widget.isTakeAway
  //                                     ? (state.orderId > 0
  //                                     ? "Order Id #${state.orderId}"
  //                                     : "Order Id ----")
  //                                     : "Order Id #${state.orderId}",
  //                                 style: const TextStyle(
  //                                   fontSize: 20,
  //                                   fontWeight: FontWeight.w600,
  //                                   color: Color(0xff404040),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                           // Text(
  //                           //   state.orderId > 0
  //                           //       ? "Order Id #${state.orderId}"
  //                           //       : "Order Id ----",
  //                           //   style: const TextStyle(
  //                           //     fontSize: 20,
  //                           //     fontWeight: FontWeight.w600,
  //                           //     color: Color(0xff404040),
  //                           //   ),
  //                           // ),
  //                           const SizedBox(height: 8),
  //
  //                           /// Table + Guests
  //                           widget.isTakeAway
  //                               ? Row(
  //                             children: [
  //                               const Icon(
  //                                 Icons.shopping_bag_outlined,
  //                                 color: Color(0xff002053),
  //                                 size: 22,
  //                               ),
  //                               const SizedBox(width: 8),
  //                               const Text(
  //                                 "Take Away",
  //                                 style: TextStyle(
  //                                   color: Color(0xFF002053),
  //                                   fontSize: 16,
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                               ),
  //                             ],
  //                           )
  //                               : Row(
  //                             children: [
  //                               Image.asset(
  //                                 "assets/dine.png",
  //                                 width: 25,
  //                                 height: 25,
  //                               ),
  //                               const SizedBox(width: 6),
  //                               Text(
  //                                 "${state.zoneName}-${state.tableName}",
  //                                 style: const TextStyle(
  //                                   color: Color(0xff002053),
  //                                   fontSize: 13,
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                               ),
  //                               const SizedBox(width: 10),
  //                               const Icon(
  //                                 Icons.people,
  //                                 size: 18,
  //                                 color: Colors.black54,
  //                               ),
  //                               const SizedBox(width: 4),
  //                               Text(
  //                                 "${state.guestDetails.guestCount}",
  //                                 style: const TextStyle(
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //
  //                     /// RIGHT SIDE
  //                     Column(
  //                       crossAxisAlignment: CrossAxisAlignment.end,
  //                       children: [
  //                         Row(
  //                           children: [
  //                             const Icon(
  //                               Icons.calendar_today_outlined,
  //                               size: 18,
  //                               color: Colors.black54,
  //                             ),
  //                             const SizedBox(width: 6),
  //                             Text(
  //                               "${DateFormat('MMM dd, yyyy').format(DateTime.now())} | ${DateFormat('h:mm a').format(DateTime.now())}",
  //                               style: const TextStyle(
  //                                 fontSize: 14,
  //                                 fontWeight: FontWeight.w500,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                         const SizedBox(height: 12),
  //                         InkWell(
  //                           onTap: () async {
  //                             final currentOrderId =
  //                                 context.read<OrderBloc>().state.orderId;
  //
  //                             if (currentOrderId == 0) {
  //                               ScaffoldMessenger.of(context).showSnackBar(
  //                                 const SnackBar(
  //                                   duration: Duration(seconds: 1),
  //                                   content: Text("No active order to cancel"),
  //                                 ),
  //                               );
  //                               return;
  //                             }
  //
  //                             AppLogger.info(
  //                               "Cancel order clicked → Order ID: $currentOrderId",
  //                             );
  //
  //                             showDialog(
  //                               context: context,
  //                               barrierDismissible: false,
  //                               builder:
  //                                   (_) => const Center(
  //                                 child: CircularProgressIndicator(),
  //                               ),
  //                             );
  //
  //                             try {
  //                               final orderRepo = OrderRepository(
  //                                 baseUrl:
  //                                 'https://merchantrestaurant.alektasolutions.com',
  //                               );
  //
  //                               final orderState =
  //                                   context.read<OrderBloc>().state;
  //
  //                               final isTakeAway = widget.isTakeAway;
  //
  //                               Map<String, dynamic>? responseJson;
  //
  //                               // =====================
  //                               // TAKEAWAY FLOW
  //                               // =====================
  //                               if (isTakeAway) {
  //                                 AppLogger.info("TAKEAWAY CANCEL START");
  //
  //                                 await orderRepo.cancelTakeAwayOrder(
  //                                   parentOrderId: currentOrderId,
  //                                   restaurantId: int.parse(orderState.restaurantId),
  //                                   token: widget.token,
  //                                 );
  //
  //                                 AppLogger.info("TAKEAWAY CANCEL SUCCESS");
  //
  //                                 if (context.mounted && Navigator.canPop(context)) {
  //                                   Navigator.pop(context);
  //                                 }
  //
  //                                 context.read<OrderBloc>().add(
  //                                   CancelOrder(
  //                                     parentOrderId: currentOrderId,
  //                                     token: widget.token,
  //                                   ),
  //                                 );
  //                                 debugPrint(
  //                                   "Using bloc => ${context.read<OrderBloc>().hashCode}",
  //                                 );
  //
  //
  //                                 ScaffoldMessenger.of(context).showSnackBar(
  //                                   const SnackBar(
  //                                     content: Text("Takeaway order cancelled successfully"),
  //                                   ),
  //                                 );
  //
  //                                 return;
  //                               }
  //                               // =====================
  //                               // DINE-IN FLOW
  //                               // =====================
  //                               responseJson = await orderRepo.cancelOrder(
  //                                 parentOrderId: currentOrderId,
  //                                 token: widget.token,
  //                                 restaurantId: widget.restaurantId,
  //                                 zoneId: widget.zoneId,
  //                               );
  //
  //                               if (context.mounted &&
  //                                   Navigator.canPop(context)) {
  //                                 Navigator.pop(context);
  //                               }
  //
  //                               if (responseJson['status'] == 'cancelled') {
  //                                 context.read<OrderBloc>().add(
  //                                   CancelOrder(
  //                                     parentOrderId: currentOrderId,
  //                                     token: widget.token,
  //                                   ),
  //                                 );
  //
  //                                 ScaffoldMessenger.of(context).showSnackBar(
  //                                   SnackBar(
  //                                     duration: const Duration(seconds: 1),
  //                                     content: Text(
  //                                       "Order ${responseJson['order_id']} cancelled successfully",
  //                                     ),
  //                                   ),
  //                                 );
  //
  //                                 final tableDao = TableDao();
  //                                 final tables = await tableDao
  //                                     .getTablesByManagerPin(widget.pin);
  //
  //                                 if (!context.mounted) return;
  //
  //                                 Navigator.pushReplacement(
  //                                   context,
  //                                   MaterialPageRoute(
  //                                     builder:
  //                                         (_) => TablesScreen(
  //                                       loadedTables: tables,
  //                                       pin: widget.pin,
  //                                       token: widget.token,
  //                                       restaurantId: widget.restaurantId,
  //                                       restaurantName:
  //                                       widget.restaurantName,
  //                                     ),
  //                                   ),
  //                                 );
  //                               } else {
  //                                 ScaffoldMessenger.of(context).showSnackBar(
  //                                   const SnackBar(
  //                                     duration: Duration(seconds: 1),
  //                                     content: Text("Failed to cancel order"),
  //                                   ),
  //                                 );
  //                               }
  //                             } catch (e) {
  //                               if (context.mounted &&
  //                                   Navigator.canPop(context)) {
  //                                 Navigator.pop(context);
  //                               }
  //
  //                               AppLogger.error("Cancel order API error: $e");
  //
  //                               ScaffoldMessenger.of(context).showSnackBar(
  //                                 SnackBar(
  //                                   duration: const Duration(seconds: 1),
  //                                   content: Text(
  //                                     e.toString().replaceFirst(
  //                                       "Exception: ",
  //                                       "",
  //                                     ),
  //                                   ),
  //                                   backgroundColor: Colors.red,
  //                                 ),
  //                               );
  //                             }
  //                           },
  //                           borderRadius: BorderRadius.circular(8),
  //                           child: Container(
  //                             height: 36,
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 12,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: const Color(0xFFF6F6F6),
  //                               borderRadius: BorderRadius.circular(6),
  //                               border: Border.all(
  //                                 width: 1,
  //                                 color:
  //                                 hasOrder
  //                                     ? const Color(0xFFFE2222)
  //                                     : const Color(0x7FC0C0C0),
  //                               ),
  //                               boxShadow: [
  //                                 BoxShadow(
  //                                   color: Colors.black.withOpacity(0.08),
  //                                   blurRadius: 6,
  //                                   offset: const Offset(0, 2),
  //                                 ),
  //                               ],
  //                             ),
  //                             child: Row(
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 Image.asset(
  //                                   "assets/icon/delete.png",
  //                                   width: 18,
  //                                   height: 18,
  //                                   color:
  //                                   hasOrder
  //                                       ? const Color(0xFFFE2222)
  //                                       : Colors.grey.shade700,
  //                                 ),
  //                                 const SizedBox(width: 6),
  //                                 Text(
  //                                   "Cancel",
  //                                   style: TextStyle(
  //                                     color:
  //                                     hasOrder
  //                                         ? const Color(0xFFFE2222)
  //                                         : Colors.grey.shade700,
  //                                     fontSize: 13,
  //                                     fontWeight: FontWeight.w600,
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               const SizedBox(height: 2),
  //
  //               /// Main Content Area
  //               Flexible(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.stretch,
  //                   children: [
  //                     /// KOT Dropdown - Always shows the header bar
  //                     if (!widget.isTakeAway && state.kotList.isNotEmpty)
  //                       MultiBlocProvider(
  //                         providers: [
  //                           BlocProvider<KotLineItemsBloc>(
  //                             create:
  //                                 (_) => KotLineItemsBloc(
  //                               repository: VoidItemRepository(),
  //                             ),
  //                           ),
  //                           BlocProvider<UpdatekotBloc>(
  //                             create:
  //                                 (_) => UpdatekotBloc(
  //                               repository: UpdatekotRepository(),
  //                             ),
  //                           ),
  //                           BlocProvider.value(value: context.read<KotBloc>()),
  //                         ],
  //                         child: ViewAllKOTDropdown(
  //                           kots: state.kotList,
  //                           parentOrderId: state.orderId,
  //                           restaurantId: int.parse(widget.restaurantId),
  //                           zoneId: state.zoneId,
  //                           token: widget.token,
  //                           tableNo: state.tableName,
  //                           // onToggle: (isExpanded) {
  //                           //   // Update state when dropdown expands/collapses
  //                           //   setState(() {
  //                           //     _showKotList = isExpanded;
  //                           //   });
  //                           // },
  //                         ),
  //                       ),
  //
  //                     /// Spacing only for Dine-In
  //                     if (!widget.isTakeAway &&
  //                         state.kotList.isNotEmpty &&
  //                         !_showKotList)
  //                       const SizedBox(height: 8),
  //
  //                     /// Conditional Rendering:
  //                     /// - If KOT view is expanded => show ONLY the KOT list.
  //                     /// - Otherwise => show order header + order list + total.
  //                     /// These two branches are mutually exclusive: only one
  //                     /// is ever built into the widget tree at a time.
  //                     if (_showKotList)
  //                     /// ---------------- KOT-ONLY VIEW ----------------
  //                       Expanded(
  //                         child: Container(
  //                           color: const Color(0xFFF1F1F3),
  //                           padding: const EdgeInsets.all(16),
  //                           child: ListView.builder(
  //                             itemCount: state.kotList.length,
  //                             itemBuilder: (context, index) {
  //                               final kot = state.kotList[index];
  //                               return Card();
  //                             },
  //                           ),
  //                         ),
  //                       )
  //                     else
  //                     /// ---------------- ORDER VIEW ----------------
  //                       Flexible(
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.stretch,
  //                           children: [
  //                             /// Header
  //                             Container(
  //                               height: 30,
  //                               decoration: BoxDecoration(
  //                                 color: const Color(0xFF989292),
  //                                 borderRadius: const BorderRadius.only(
  //                                   topLeft: Radius.circular(6),
  //                                   topRight: Radius.circular(6),
  //                                 ),
  //                               ),
  //                               padding: const EdgeInsets.symmetric(
  //                                 horizontal: 12,
  //                               ),
  //                               child: Row(
  //                                 children: [
  //                                   const SizedBox(width: 7),
  //                                   SizedBox(width: 40, child: headerText('#')),
  //                                   const SizedBox(width: 6),
  //                                   Expanded(child: headerText('Item Name')),
  //                                   const SizedBox(width: 40),
  //                                   headerText('Modifiers'),
  //                                   SizedBox(
  //                                     width: 70,
  //                                     child: headerText(
  //                                       'Price',
  //                                       align: TextAlign.right,
  //                                     ),
  //                                   ),
  //                                   const SizedBox(width: 30),
  //                                   SizedBox(
  //                                     width: 80,
  //                                     child: headerText(
  //                                       'Qty',
  //                                       align: TextAlign.center,
  //                                     ),
  //                                   ),
  //                                   const SizedBox(width: 5),
  //                                   SizedBox(
  //                                     width: 70,
  //                                     child: headerText(
  //                                       'Amount',
  //                                       align: TextAlign.right,
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                             const SizedBox(height: 2),
  //
  //                             /// Order List
  //                             Expanded(
  //                               child: Container(
  //                                 color: const Color(0xFFF1F1F3),
  //                                 child:
  //                                 state.orderItems.isEmpty
  //                                     ? const Center(
  //                                   child: Column(
  //                                     mainAxisSize: MainAxisSize.min,
  //                                     children: [
  //                                       Text(
  //                                         "No item Selected",
  //                                         style: TextStyle(
  //                                           fontSize: 16,
  //                                           fontWeight: FontWeight.w600,
  //                                           color: Color(0xFFB8B8B8),
  //                                         ),
  //                                       ),
  //                                       SizedBox(height: 8),
  //                                       Text(
  //                                         "Please select item from Menu",
  //                                         style: TextStyle(
  //                                           fontSize: 16,
  //                                           fontWeight: FontWeight.w600,
  //                                           color: Color(0xFFB8B8B8),
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 )
  //                                     : OrderPanelList(
  //                                   orderItems: state.orderItems,
  //                                   addonPrices: widget.addonPrices,
  //                                   onIncreaseQuantity: (index) {
  //                                     final item =
  //                                     state.orderItems[index];
  //                                     context.read<OrderBloc>().add(
  //                                       UpdateOrderItemQuantity(
  //                                         index,
  //                                         item.quantity + 1,
  //                                       ),
  //                                     );
  //                                   },
  //                                   onDecreaseQuantity: (index) {
  //                                     final item =
  //                                     state.orderItems[index];
  //                                     if (item.quantity > 1) {
  //                                       context.read<OrderBloc>().add(
  //                                         UpdateOrderItemQuantity(
  //                                           index,
  //                                           item.quantity - 1,
  //                                         ),
  //                                       );
  //                                     }
  //                                   },
  //                                   onModifiersChanged: (
  //                                       index,
  //                                       modifiers,
  //                                       addOns,
  //                                       note,
  //                                       ) {
  //                                     final fullAddOns =
  //                                     <
  //                                         String,
  //                                         Map<String, dynamic>
  //                                     >{};
  //                                     addOns.forEach((name, qty) {
  //                                       fullAddOns[name] = {
  //                                         'quantity': qty,
  //                                         'price':
  //                                         widget
  //                                             .addonPrices[name] ??
  //                                             0,
  //                                       };
  //                                     });
  //
  //                                     context.read<OrderBloc>().add(
  //                                       UpdateOrderItemDetails(
  //                                         index: index,
  //                                         modifiers: modifiers,
  //                                         addOns: fullAddOns,
  //                                         note: note,
  //                                       ),
  //                                     );
  //                                   },
  //                                   onRemoveItem: (index) {
  //                                     context.read<OrderBloc>().add(
  //                                       RemoveOrderItem(index),
  //                                     );
  //                                   },
  //                                   token: widget.token,
  //                                 ),
  //                               ),
  //                             ),
  //
  //                             /// TOTAL
  //                             Container(
  //                               padding: const EdgeInsets.symmetric(
  //                                 horizontal: 12,
  //                                 vertical: 6,
  //                               ),
  //                               decoration: BoxDecoration(
  //                                 color: const Color(0xFF152148),
  //                                 borderRadius: const BorderRadius.only(
  //                                   bottomLeft: Radius.circular(6),
  //                                   bottomRight: Radius.circular(6),
  //                                 ),
  //                               ),
  //                               child: Row(
  //                                 mainAxisAlignment:
  //                                 MainAxisAlignment.spaceBetween,
  //                                 children: [
  //                                   Text(
  //                                     'Total Items: ${state.orderItems.length}',
  //                                     style: const TextStyle(
  //                                       fontSize: 14,
  //                                       fontWeight: FontWeight.w600,
  //                                       color: const Color(0xFFFAFAFA),
  //                                     ),
  //                                   ),
  //                                   Text(
  //                                     state.orderItems
  //                                         .fold(
  //                                       0.0,
  //                                           (sum, item) =>
  //                                       sum + item.totalWithAddons,
  //                                     )
  //                                         .toStringAsFixed(2),
  //                                     style: const TextStyle(
  //                                       fontSize: 12,
  //                                       fontWeight: FontWeight.w600,
  //                                       color: const Color(0xFFFAFAFA),
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //
  //               const SizedBox(height: 6),
  //
  //               /// Bottom action buttons
  //               Container(
  //                 padding: const EdgeInsets.all(2),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 child:
  //                 widget.isTakeAway
  //                     ? _takeAwayCheckoutButton(hasOrder)
  //                     : Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                   children: [
  //                     Builder(
  //                       builder: (scaffoldContext) {
  //                         return BlocListener<OrderBloc, OrderState>(
  //                           listenWhen:
  //                               (prev, curr) =>
  //                           prev.error != curr.error,
  //                           listener: (context, state) {
  //                             if (state.error != null &&
  //                                 state.error!.isNotEmpty) {
  //                               ScaffoldMessenger.of(scaffoldContext)
  //                                 ..hideCurrentSnackBar()
  //                                 ..showSnackBar(
  //                                   SnackBar(
  //                                     content: Text(state.error!),
  //                                     duration: Duration(seconds: 1),
  //                                   ),
  //                                 );
  //                             }
  //                           },
  //                           child: orderButton(
  //                             'Repeat order',
  //                             canRepeatOrder
  //                                 ? const Color(0xFF2563EB)
  //                                 : Colors.grey,
  //                             isLoading: _isRepeatingOrder,
  //                             onPressed:
  //                             canRepeatOrder
  //                                 ? () {
  //                               setState(() {
  //                                 _isRepeatingOrder = true;
  //                               });
  //
  //                               final bloc =
  //                               context.read<OrderBloc>();
  //
  //                               if (bloc.state.orderId == 0) {
  //                                 ScaffoldMessenger.of(
  //                                   scaffoldContext,
  //                                 ).showSnackBar(
  //                                   const SnackBar(
  //                                     duration: Duration(
  //                                       seconds: 1,
  //                                     ),
  //                                     content: Text(
  //                                       "Order not found",
  //                                     ),
  //                                   ),
  //                                 );
  //                                 setState(() {
  //                                   _isRepeatingOrder = false;
  //                                 });
  //                                 return;
  //                               }
  //
  //                               bloc.add(
  //                                 RepeatKotOrder(
  //                                   orderId: bloc.state.orderId,
  //                                   restaurantId: int.parse(
  //                                     bloc.state.restaurantId,
  //                                   ),
  //                                   zoneId: bloc.state.zoneId,
  //                                   token: widget.token,
  //                                 ),
  //                               );
  //
  //                               Future.delayed(
  //                                 const Duration(seconds: 2),
  //                                     () {
  //                                   if (mounted) {
  //                                     setState(() {
  //                                       _isRepeatingOrder =
  //                                       false;
  //                                     });
  //                                   }
  //                                 },
  //                               );
  //                             }
  //                                 : null,
  //                           ),
  //                         );
  //                       },
  //                     ),
  //
  //                     orderButton(
  //                       'KOT Print',
  //                       canPrintKot
  //                           ? const Color(0xFFF97316)
  //                           : Colors.grey,
  //                       onPressed:
  //                       canPrintKot
  //                           ? () async {
  //                         final orderBloc =
  //                         context.read<OrderBloc>();
  //                         final kotBloc =
  //                         context.read<KotBloc>();
  //                         final orderRepo = OrderRepository(
  //                           baseUrl:
  //                           'https://merchantrestaurant.alektasolutions.com',
  //                         );
  //
  //                         if (state.orderItems.isEmpty) {
  //                           ScaffoldMessenger.of(
  //                             context,
  //                           ).showSnackBar(
  //                             const SnackBar(
  //                               duration: Duration(seconds: 1),
  //                               content: Text(
  //                                 'No items to create KOT!',
  //                               ),
  //                             ),
  //                           );
  //                           return;
  //                         }
  //
  //                         showDialog(
  //                           context: context,
  //                           barrierDismissible: false,
  //                           builder:
  //                               (_) => const Center(
  //                             child:
  //                             CircularProgressIndicator(),
  //                           ),
  //                         );
  //
  //                         try {
  //                           final captainId = int.tryParse(
  //                             this.widget.userId,
  //                           );
  //                           if (captainId == null ||
  //                               widget.token.isEmpty) {
  //                             throw Exception(
  //                               'Invalid user session. Please check in again.',
  //                             );
  //                           }
  //
  //                           final KotModel? kot =
  //                           await orderRepo.createKOT(
  //                             parentOrderId: state.orderId,
  //                             kotId: "",
  //                             items: state.orderItems,
  //                             token: widget.token,
  //                             restaurantId:
  //                             orderBloc
  //                                 .state
  //                                 .restaurantId
  //                                 .toString(),
  //                             zoneId:
  //                             orderBloc.state.zoneId,
  //                             captainId: captainId,
  //                           );
  //
  //                           Navigator.of(context).pop();
  //
  //                           final permissions =
  //                           await SessionManager.loadPermissions();
  //                           final captainName =
  //                               permissions?.displayName ?? '';
  //                           if (kot != null) {
  //                             await printKot(
  //                               kotNo: kot.kotNumber ?? '',
  //                               orderId:
  //                               kot.parentOrderId
  //                                   .toString(),
  //                               tableName:
  //                               orderBloc.state.tableName,
  //                               captainName: captainName,
  //                               items:
  //                               state.orderItems
  //                                   .map(
  //                                     (e) => {
  //                                   "name": e.name,
  //                                   "qty": e.quantity,
  //                                   "modifiers":
  //                                   e.modifiers
  //                                       .toList(),
  //                                   "addons": e.addOns,
  //                                 },
  //                               )
  //                                   .toList(),
  //                               kot: kot,
  //                             );
  //                             await KdsMqttPublisher.notifyKotCreated(
  //                               restaurantId:
  //                               orderBloc.state.restaurantId
  //                                   .toString(),
  //                               parentOrderId: state.orderId,
  //                               zoneId: orderBloc.state.zoneId,
  //                               zoneName:
  //                               orderBloc.state.zoneName,
  //                               orderType: 'Dine-In',
  //                               kot: kot,
  //                               tableName:
  //                               orderBloc.state.tableName,
  //                             );
  //                             orderBloc.add(AddKOT(kot));
  //                             kotBloc.add(AddKotToList(kot));
  //                             orderBloc.add(ClearOrder());
  //
  //                             ScaffoldMessenger.of(
  //                               context,
  //                             ).showSnackBar(
  //                               SnackBar(
  //                                 content: SizedBox(
  //                                   width: 400,
  //                                   child: Row(
  //                                     mainAxisAlignment:
  //                                     MainAxisAlignment
  //                                         .center,
  //                                     children: [
  //                                       const Icon(
  //                                         Icons.check_circle,
  //                                         color: Colors.white,
  //                                         size: 20,
  //                                       ),
  //                                       const SizedBox(
  //                                         width: 8,
  //                                       ),
  //                                       Text(
  //                                         'KOT Created: ${kot.kotNumber}',
  //                                         style:
  //                                         const TextStyle(
  //                                           fontSize: 16,
  //                                           fontWeight:
  //                                           FontWeight
  //                                               .w500,
  //                                           color:
  //                                           Colors
  //                                               .white,
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ),
  //                                 duration: const Duration(
  //                                   seconds: 4,
  //                                 ),
  //                                 behavior:
  //                                 SnackBarBehavior.floating,
  //                                 margin: EdgeInsets.only(
  //                                   left: 400,
  //                                   right: 400,
  //                                   bottom:
  //                                   MediaQuery.of(
  //                                     context,
  //                                   ).size.height *
  //                                       0.90,
  //                                 ),
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius:
  //                                   BorderRadius.circular(
  //                                     12,
  //                                   ),
  //                                 ),
  //                                 backgroundColor: Colors.green,
  //                                 elevation: 6,
  //                               ),
  //                             );
  //                           }
  //                         } catch (e) {
  //                           if (Navigator.of(
  //                             context,
  //                             rootNavigator: true,
  //                           ).canPop()) {
  //                             Navigator.of(
  //                               context,
  //                               rootNavigator: true,
  //                             ).pop();
  //                           }
  //                           final message = e
  //                               .toString()
  //                               .replaceFirst(
  //                             "Exception: ",
  //                             "",
  //                           );
  //                           ScaffoldMessenger.of(
  //                             context,
  //                           ).showSnackBar(
  //                             SnackBar(
  //                               content: Text(message),
  //                               backgroundColor: Colors.red,
  //                               behavior:
  //                               SnackBarBehavior.floating,
  //                               duration: const Duration(
  //                                 seconds: 1,
  //                               ),
  //                             ),
  //                           );
  //                           AppLogger.error(message);
  //                         }
  //                       }
  //                           : null,
  //                     ),
  //
  //                     orderButton(
  //                       'Checkout',
  //                       canPay ? const Color(0xFF16A34A) : Colors.grey,
  //                       onPressed:
  //                       canPay
  //                           ? () {
  //                         AppLogger.info("Pay clicked - Dine In");
  //                         debugPrint("💳 Navigating to PaymentScreen from Dine-In - isTakeAway: false");
  //                         AppLogger.info("Pay clicked");
  //                         Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                             builder:
  //                                 (_) => MultiBlocProvider(
  //                               providers: [
  //                                 BlocProvider.value(
  //                                   value:
  //                                   context
  //                                       .read<
  //                                       OrderBloc
  //                                   >(),
  //                                 ),
  //                                 BlocProvider.value(
  //                                   value:
  //                                   context
  //                                       .read<
  //                                       PaymentBloc
  //                                   >(),
  //                                 ),
  //                                 BlocProvider.value(
  //                                   value:
  //                                   context
  //                                       .read<
  //                                       RemoveDiscountBloc
  //                                   >(),
  //                                 ),
  //                               ],
  //                               child: PaymentScreen(
  //                                 loadedTables:
  //                                 widget.loadedTables,
  //                                 pin: widget.pin,
  //                                 token: widget.token,
  //                                 restaurantId:
  //                                 widget.restaurantId,
  //                                 restaurantName:
  //                                 widget.restaurantName,
  //                                 zoneId: widget.zoneId,
  //                                 isTakeAway: false,  // ✅ Explicitly false for Dine-In
  //                               ),
  //                             ),
  //                           ),
  //                         );
  //                       }
  //                           : null,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    // 1️⃣ Trigger KOT loading for existing order
    final orderBloc = context.read<OrderBloc>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kotBloc = context.read<KotBloc>();

    // ✅ Initialize OrderBloc with existing order items if not already loaded
    if (widget.orderId != 0 && orderBloc.state.orderId != widget.orderId) {
      orderBloc.add(
        LoadExistingOrder(
          orderId: widget.orderId,
          tableId: widget.tableId,
          zoneId: widget.zoneId,
          tableName: widget.tableName,
          zoneName: widget.zoneName,
          kotList: widget.existingKots ?? [],
          restaurantId: widget.restaurantId,
          guestDetails: widget.guestcount,
        ),
      );
    }

    // ✅ Initialize KotBloc with existing KOTs if not already loaded
    if (widget.orderId != 0 &&
        widget.existingKots != null &&
        (kotBloc.state is! KotLoaded ||
            (kotBloc.state as KotLoaded).kots.isEmpty)) {
      context.read<KotBloc>().add(SetExistingKots(kots: widget.existingKots!));
    }

    return BlocListener<KotBloc, KotState>(
      listener: (context, kotState) {
        if (kotState is KotLoaded) {
          final seen = <String>{};
          final dedupedKots = <KotModel>[
            for (final k in kotState.kots)
              if (seen.add(k.kotNumber ?? k.kotId.toString())) k,
          ];
          debugPrint("KotLoaded: ${kotState.kots.length} (deduped: ${dedupedKots.length})");
          context.read<OrderBloc>().add(RefreshKotList(dedupedKots));
        }
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          // take away order flow
          final bool hasOrder = state.orderId > 0;
          // disable buttons
          final bool hasCartItems = state.orderItems.isNotEmpty;

          // ✅ FIXED: Check for ANY KOT that is not voided or transferred
          final bool hasAnyValidKot = state.kotList.any((kot) {
            final status = (kot.status ?? '').toLowerCase();
            return status != 'voided' && status != 'transferred';
          });

          debugPrint("========== KOTS ==========");
          for (final kot in state.kotList) {
            debugPrint("KOT: ${kot.kotNumber} | Status: ${kot.status}");
          }

          debugPrint("Total KOTs: ${state.kotList.length}");
          debugPrint("OrderId: ${state.orderId}");
          debugPrint("OrderItems: ${state.orderItems.length}");
          debugPrint("HasOrder: $hasOrder");
          debugPrint("ShowKotList: $_showKotList");
          debugPrint(
            "Valid KOTs (not voided/transferred): ${state.kotList.where((k) => k.status?.toLowerCase() != 'voided' && k.status?.toLowerCase() != 'transferred').length}",
          );

          /// Repeat Order -> enabled if there's any valid KOT (not voided or transferred)
          final bool canRepeatOrder = hasAnyValidKot;

          /// KOT Print -> only if cart contains items
          final bool canPrintKot = hasCartItems;

          /// cancel button enable in take away order
          final bool disableCancel = !widget.isTakeAway && hasAnyValidKot;

          /// Pay -> enabled if there's any valid KOT (not voided or transferred)
          final bool canPay = hasAnyValidKot && !hasCartItems;
          final bool hasOrderItems = state.orderItems.isNotEmpty;
          return Container(
            margin: const EdgeInsets.only(top: 6),
            width: 700,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B22) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF2B2E37) : const Color(0xFFE0E0E0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header row with badges & actions
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 12,
                  ),
                  // decoration: BoxDecoration(
                  //   color: isDark
                  //       ? const Color(0xFF2A2F45)
                  //       : Colors.white,
                  //   borderRadius: BorderRadius.circular(14),
                  //   // boxShadow: [
                  //   //   BoxShadow(
                  //   //     color: Colors.black.withOpacity(.05),
                  //   //     blurRadius: 8,
                  //   //     offset: const Offset(0, 2),
                  //   //   ),
                  //   // ],
                  // ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// LEFT SIDE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Order ID
                            Row(
                              children: [
                                Image.asset(
                                  "assets/order.png",
                                  width: 18,
                                  height: 18,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Order Id ",
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF152148),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            widget.isTakeAway
                                                ? (state.orderId > 0
                                                    ? "${state.orderId}"
                                                    : "----")
                                                : "${state.orderId}",
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF152148),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            /// Table + Guests
                            widget.isTakeAway
                                ? Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_outlined,
                                      color: Color(0xff414141),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Take Away",
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Color(0xff002053),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                                : Row(
                                  children: [
                                    Image.asset(
                                      "assets/dine.png",
                                      width: 25,
                                      height: 25,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${state.zoneName}-${state.tableName}",
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? Colors.white
                                                : const Color(0xff002053),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      Icons.people,
                                      size: 18,
                                      color:
                                          isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${state.guestDetails.guestCount}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                          ],
                        ),
                      ),

                      /// RIGHT SIDE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat(
                                  'dd MMMM, yyyy',
                                ).format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? Colors.white
                                          : const Color(0xFF121212),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            // 1. Disable tap function completely if a valid KOT has been generated
                            onTap:
                                disableCancel
                                    ? null
                                    : () {
                                      final currentOrderId =
                                          context
                                              .read<OrderBloc>()
                                              .state
                                              .orderId;

                                      if (currentOrderId == 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            duration: Duration(seconds: 1),
                                            content: Text(
                                              "No active order to cancel",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (dialogContext) {
                                          bool isLoading = false;

                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return ConfirmationPopup(
                                                title: "Are you sure?",
                                                message:
                                                    widget.isTakeAway
                                                        ? "Do you want to really cancel this order?\nThis action cannot be undone."
                                                        : "Do you want to really delete the ",
                                                highlightedText:
                                                    widget.isTakeAway
                                                        ? null
                                                        : state.tableName,
                                                trailingMessage:
                                                    widget.isTakeAway
                                                        ? null
                                                        : "?\nThis will remove it from ${state.zoneName}.",
                                                imagePath:
                                                    "assets/warning_icon.png",
                                                confirmButtonText:
                                                    "Yes, Cancel!",
                                                cancelButtonText: "No, Keep It",
                                                primaryColor: const Color(
                                                  0xFFD83434,
                                                ),
                                                gradientColor: const Color(
                                                  0xFFFCE9E9,
                                                ),
                                                isLoading: isLoading,
                                                onCancel: () {
                                                  Navigator.pop(dialogContext);
                                                },
                                                onConfirm: () async {
                                                  setState(() {
                                                    isLoading = true;
                                                  });

                                                  Navigator.pop(dialogContext);
                                                  await _cancelOrder(
                                                    currentOrderId,
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                            borderRadius: BorderRadius.circular(8),
                            child: Opacity(
                              // 2. Wrap layout structure with opacity filter to give dynamic visual feedback
                              // opacity: hasAnyValidKot ? 0.45 : 1.0,
                              opacity: disableCancel ? 0.45 : 1.0,
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? const Color(0xFF34384F)
                                          : const Color(0xFFF6F6F6),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    width: 1,
                                    // 3. Fallback color maps if active state block triggers lock limits
                                    color:
                                        // (hasOrder && !hasAnyValidKot)
                                        (hasOrder && !disableCancel)
                                            ? const Color(0xFFFE2222)
                                            : const Color(0x7FC0C0C0),
                                  ),
                                  boxShadow:
                                      disableCancel
                                          ? []
                                          : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      "assets/icon/delete.png",
                                      width: 18,
                                      height: 18,
                                      color:
                                          // (hasOrder && !hasAnyValidKot)
                                          (hasOrder && !disableCancel)
                                              ? const Color(0xFFFE2222)
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.grey.shade700),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color:
                                            // (hasOrder && !hasAnyValidKot)
                                            (hasOrder && !disableCancel)
                                                ? const Color(0xFFFE2222)
                                                : (isDark
                                                    ? Colors.white
                                                    : Colors.grey.shade700),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // const SizedBox(height: 2),

                /// Main Content Area
                // Flexible(
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.stretch,
                //     children: [
                //       /// KOT Dropdown - Always shows the header bar
                //       if (!widget.isTakeAway && state.kotList.isNotEmpty)
                //         MultiBlocProvider(
                //           providers: [
                //             BlocProvider<KotLineItemsBloc>(
                //               create:
                //                   (_) => KotLineItemsBloc(
                //                 repository: VoidItemRepository(),
                //               ),
                //             ),
                //             BlocProvider<UpdatekotBloc>(
                //               create:
                //                   (_) => UpdatekotBloc(
                //                 repository: UpdatekotRepository(),
                //               ),
                //             ),
                //             BlocProvider.value(value: context.read<KotBloc>()),
                //           ],
                //           child: ViewAllKOTDropdown(
                //             kots: state.kotList,
                //             parentOrderId: state.orderId,
                //             restaurantId: int.parse(widget.restaurantId),
                //             zoneId: state.zoneId,
                //             token: widget.token,
                //             tableNo: state.tableName,
                //             // onToggle: (isExpanded) {
                //             //   // Update state when dropdown expands/collapses
                //             //   setState(() {
                //             //     _showKotList = isExpanded;
                //             //   });
                //             // },
                //           ),
                //         ),
                //
                //       /// Spacing only for Dine-In
                //       if (!widget.isTakeAway &&
                //           state.kotList.isNotEmpty &&
                //           !_showKotList)
                //         const SizedBox(height: 8),
                //
                //       /// Conditional Rendering:
                //       /// - If KOT view is expanded => show ONLY the KOT list.
                //       /// - Otherwise => show order header + order list + total.
                //       /// These two branches are mutually exclusive: only one
                //       /// is ever built into the widget tree at a time.
                //       if (_showKotList)
                //       /// ---------------- KOT-ONLY VIEW ----------------
                //         Expanded(
                //           child: Container(
                //             color: const Color(0xFFF1F1F3),
                //             padding: const EdgeInsets.all(16),
                //             child: ListView.builder(
                //               itemCount: state.kotList.length,
                //               itemBuilder: (context, index) {
                //                 final kot = state.kotList[index];
                //                 return Card();
                //               },
                //             ),
                //           ),
                //         )
                //       else
                //       /// ---------------- ORDER VIEW ----------------
                //         Flexible(
                //           child: Column(
                //             crossAxisAlignment: CrossAxisAlignment.stretch,
                //             children: [
                //               /// Header
                //               Container(
                //                 height: 30,
                //                 decoration: BoxDecoration(
                //                   color: const Color(0xFF989292),
                //                   borderRadius: const BorderRadius.only(
                //                     topLeft: Radius.circular(6),
                //                     topRight: Radius.circular(6),
                //                   ),
                //                 ),
                //                 padding: const EdgeInsets.symmetric(
                //                   horizontal: 12,
                //                 ),
                //                 child: Row(
                //                   children: [
                //                     const SizedBox(width: 7),
                //                     SizedBox(width: 40, child: headerText('#')),
                //                     const SizedBox(width: 6),
                //                     Expanded(child: headerText('Item Name')),
                //                     const SizedBox(width: 40),
                //                     headerText('Modifiers'),
                //                     SizedBox(
                //                       width: 70,
                //                       child: headerText(
                //                         'Price',
                //                         align: TextAlign.right,
                //                       ),
                //                     ),
                //                     const SizedBox(width: 30),
                //                     SizedBox(
                //                       width: 80,
                //                       child: headerText(
                //                         'Qty',
                //                         align: TextAlign.center,
                //                       ),
                //                     ),
                //                     const SizedBox(width: 5),
                //                     SizedBox(
                //                       width: 70,
                //                       child: headerText(
                //                         'Amount',
                //                         align: TextAlign.right,
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //               const SizedBox(height: 2),
                //
                //               /// Order List
                //               Expanded(
                //                 child: Container(
                //                   color: const Color(0xFFF1F1F3),
                //                   child:
                //                   state.orderItems.isEmpty
                //                       ? const Center(
                //                     child: Column(
                //                       mainAxisSize: MainAxisSize.min,
                //                       children: [
                //                         Text(
                //                           "No item Selected",
                //                           style: TextStyle(
                //                             fontSize: 16,
                //                             fontWeight: FontWeight.w600,
                //                             color: Color(0xFFB8B8B8),
                //                           ),
                //                         ),
                //                         SizedBox(height: 8),
                //                         Text(
                //                           "Please select item from Menu",
                //                           style: TextStyle(
                //                             fontSize: 16,
                //                             fontWeight: FontWeight.w600,
                //                             color: Color(0xFFB8B8B8),
                //                           ),
                //                         ),
                //                       ],
                //                     ),
                //                   )
                //                       : OrderPanelList(
                //                     orderItems: state.orderItems,
                //                     addonPrices: widget.addonPrices,
                //                     onIncreaseQuantity: (index) {
                //                       final item =
                //                       state.orderItems[index];
                //                       context.read<OrderBloc>().add(
                //                         UpdateOrderItemQuantity(
                //                           index,
                //                           item.quantity + 1,
                //                         ),
                //                       );
                //                     },
                //                     onDecreaseQuantity: (index) {
                //                       final item =
                //                       state.orderItems[index];
                //                       if (item.quantity > 1) {
                //                         context.read<OrderBloc>().add(
                //                           UpdateOrderItemQuantity(
                //                             index,
                //                             item.quantity - 1,
                //                           ),
                //                         );
                //                       }
                //                     },
                //                     onModifiersChanged: (
                //                         index,
                //                         modifiers,
                //                         addOns,
                //                         note,
                //                         ) {
                //                       final fullAddOns =
                //                       <
                //                           String,
                //                           Map<String, dynamic>
                //                       >{};
                //                       addOns.forEach((name, qty) {
                //                         fullAddOns[name] = {
                //                           'quantity': qty,
                //                           'price':
                //                           widget
                //                               .addonPrices[name] ??
                //                               0,
                //                         };
                //                       });
                //
                //                       context.read<OrderBloc>().add(
                //                         UpdateOrderItemDetails(
                //                           index: index,
                //                           modifiers: modifiers,
                //                           addOns: fullAddOns,
                //                           note: note,
                //                         ),
                //                       );
                //                     },
                //                     onRemoveItem: (index) {
                //                       context.read<OrderBloc>().add(
                //                         RemoveOrderItem(index),
                //                       );
                //                     },
                //                     token: widget.token,
                //                   ),
                //                 ),
                //               ),
                //
                //               /// TOTAL
                //               Container(
                //                 padding: const EdgeInsets.symmetric(
                //                   horizontal: 12,
                //                   vertical: 6,
                //                 ),
                //                 decoration: BoxDecoration(
                //                   color: const Color(0xFFE9EAFC),
                //                   borderRadius: const BorderRadius.only(
                //                     bottomLeft: Radius.circular(6),
                //                     bottomRight: Radius.circular(6),
                //                   ),
                //                 ),
                //                 child: Row(
                //                   mainAxisAlignment:
                //                   MainAxisAlignment.spaceBetween,
                //                   children: [
                //                     Text(
                //                       'Total Items: ${state.orderItems.length}',
                //                       style: const TextStyle(
                //                         fontSize: 14,
                //                         fontWeight: FontWeight.w600,
                //                         color: const Color(0xFF1A3C71),
                //                       ),
                //                     ),
                //                     Text(
                //                       state.orderItems
                //                           .fold(
                //                         0.0,
                //                             (sum, item) =>
                //                         sum + item.totalWithAddons,
                //                       )
                //                           .toStringAsFixed(2),
                //                       style: const TextStyle(
                //                         fontSize: 14,
                //                         fontWeight: FontWeight.w700,
                //                         color: const Color(0xFF1A3C71),
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //     ],
                //   ),
                // ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /// KOT Dropdown - Always shows the header bar
                      if (!widget.isTakeAway && state.kotList.isNotEmpty)
                        MultiBlocProvider(
                          providers: [
                            BlocProvider<KotLineItemsBloc>(
                              create:
                                  (_) => KotLineItemsBloc(
                                    repository: VoidItemRepository(),
                                  ),
                            ),
                            BlocProvider<UpdatekotBloc>(
                              create:
                                  (_) => UpdatekotBloc(
                                    repository: UpdatekotRepository(),
                                  ),
                            ),
                            BlocProvider.value(value: context.read<KotBloc>()),
                          ],
                          child: ViewAllKOTDropdown(
                            kots: state.kotList,
                            pin: widget.pin,
                            parentOrderId:
                                state.orderId > 0
                                    ? state.orderId
                                    : widget.orderId,
                            restaurantId: int.parse(widget.restaurantId),
                            zoneId: state.zoneId,
                            token: widget.token,
                            tableNo: state.tableName,
                            onToggle: (isExpanded) {
                              if (_showKotList != isExpanded && mounted) {
                                setState(() {
                                  _showKotList = isExpanded;
                                });
                              }
                            },
                          ),
                        ),

                      /// Spacing only for Dine-In
                      if (!widget.isTakeAway &&
                          state.kotList.isNotEmpty &&
                          !_showKotList)
                        const SizedBox(height: 8),

                      /// ---------------- ORDER VIEW ----------------
                      /// ✅ When the KOT dropdown is expanded (_showKotList == true)
                      /// the order header + item list + total below are hidden
                      /// entirely (no separate KOT-only list is rendered here —
                      /// the dropdown itself shows the KOT details).
                      // if (!_showKotList)
                      if (!_showKotList || state.kotList.isEmpty)
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              /// Header
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? const Color(0xFF34384F)
                                          : const Color(0xFF989292),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 7),
                                    SizedBox(width: 40, child: headerText('#')),
                                    const SizedBox(width: 6),
                                    Expanded(child: headerText('Item Name')),
                                    const SizedBox(width: 50),
                                    headerText('Modifiers'),
                                    SizedBox(
                                      width: 40,
                                      child: headerText(
                                        'Price',
                                        align: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    SizedBox(
                                      width: 90,
                                      child: headerText(
                                        'Qty',
                                        align: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    SizedBox(
                                      width: 80,
                                      child: headerText(
                                        'Amount',
                                        align: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),

                              /// Order List
                              Expanded(
                                child: Container(
                                  color:
                                      isDark
                                          ? const Color(0xFF202433)
                                          : const Color(0xFFF1F1F3),
                                  child:
                                      state.orderItems.isEmpty
                                          ? Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "No item Selected",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        isDark
                                                            ? Colors.white70
                                                            : const Color(
                                                              0xFFB8B8B8,
                                                            ),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  "Please select item from Menu",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFB8B8B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          : OrderPanelList(
                                            currency: _currency,
                                            // currency: _currencySymbol, // <-- Add this
                                            orderItems: state.orderItems,
                                            addonPrices: widget.addonPrices,
                                            onIncreaseQuantity: (index) {
                                              final item =
                                                  state.orderItems[index];
                                              context.read<OrderBloc>().add(
                                                UpdateOrderItemQuantity(
                                                  index,
                                                  item.quantity + 1,
                                                ),
                                              );
                                            },
                                            onDecreaseQuantity: (index) {
                                              final item =
                                                  state.orderItems[index];
                                              if (item.quantity > 1) {
                                                context.read<OrderBloc>().add(
                                                  UpdateOrderItemQuantity(
                                                    index,
                                                    item.quantity - 1,
                                                  ),
                                                );
                                              }
                                            },
                                            onModifiersChanged: (
                                              index,
                                              modifiers,
                                              addOns,
                                              note,
                                            ) {
                                              final fullAddOns =
                                                  <
                                                    String,
                                                    Map<String, dynamic>
                                                  >{};
                                              addOns.forEach((name, qty) {
                                                fullAddOns[name] = {
                                                  'quantity': qty,
                                                  'price':
                                                      widget
                                                          .addonPrices[name] ??
                                                      0,
                                                };
                                              });

                                              context.read<OrderBloc>().add(
                                                UpdateOrderItemDetails(
                                                  index: index,
                                                  modifiers: modifiers,
                                                  addOns: fullAddOns,
                                                  note: note,
                                                ),
                                              );
                                            },
                                            onRemoveItem: (index) {
                                              context.read<OrderBloc>().add(
                                                RemoveOrderItem(index),
                                              );
                                            },
                                            token: widget.token,
                                          ),
                                ),
                              ),

                              /// TOTAL
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A3C71),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(6),
                                    bottomRight: Radius.circular(6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Items: ${state.orderItems.length}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      state.orderItems
                                          .fold(
                                            0.0,
                                            (sum, item) =>
                                                sum + item.totalWithAddons,
                                          )
                                          .toStringAsFixed(2),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                /// Bottom action buttons
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1B22) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      widget.isTakeAway
                          ? _takeAwayCheckoutButton(hasOrder)
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Builder(
                                builder: (scaffoldContext) {
                                  return BlocListener<OrderBloc, OrderState>(
                                    listenWhen:
                                        (prev, curr) =>
                                            prev.error != curr.error,
                                    listener: (context, state) {
                                      if (state.error != null &&
                                          state.error!.isNotEmpty) {
                                        ScaffoldMessenger.of(scaffoldContext)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(state.error!),
                                              duration: Duration(seconds: 1),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                      }
                                    },
                                    child: orderButton(
                                      'Repeat order',
                                      canRepeatOrder
                                          ? const Color(0xFF2563EB)
                                          : Colors.grey,
                                      isLoading: _isRepeatingOrder,
                                      onPressed:
                                          canRepeatOrder
                                              ? () {
                                                setState(() {
                                                  _isRepeatingOrder = true;
                                                });

                                                final bloc =
                                                    context.read<OrderBloc>();

                                                if (bloc.state.orderId == 0) {
                                                  ScaffoldMessenger.of(
                                                    scaffoldContext,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      duration: Duration(
                                                        seconds: 1,
                                                      ),
                                                      content: Text(
                                                        "Order not found",
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  setState(() {
                                                    _isRepeatingOrder = false;
                                                  });
                                                  return;
                                                }

                                                bloc.add(
                                                  RepeatKotOrder(
                                                    orderId: bloc.state.orderId,
                                                    restaurantId: int.parse(
                                                      bloc.state.restaurantId,
                                                    ),
                                                    zoneId: bloc.state.zoneId,
                                                    token: widget.token,
                                                  ),
                                                );

                                                Future.delayed(
                                                  const Duration(seconds: 2),
                                                  () {
                                                    if (mounted) {
                                                      setState(() {
                                                        _isRepeatingOrder =
                                                            false;
                                                      });
                                                    }
                                                  },
                                                );
                                              }
                                              : null,
                                    ),
                                  );
                                },
                              ),

                              orderButton(
                                'KOT Print',
                                canPrintKot
                                    ? const Color(0xFFF97316)
                                    : Colors.grey,
                                onPressed:
                                canPrintKot
                                    ? () async {
                                  final orderBloc =
                                  context.read<OrderBloc>();
                                  final kotBloc =
                                  context.read<KotBloc>();
                                  final orderRepo = OrderRepository(
                                    baseUrl: AppConstants.baseDomain,
                                  );
                                  if (state.orderItems.isEmpty) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        duration: Duration(seconds: 1),
                                        content: Text(
                                          'No items to create KOT!',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (_) => const Center(
                                      child:
                                      CircularProgressIndicator(),
                                    ),
                                  );

                                  try {
                                    final captainId = int.tryParse(
                                      this.widget.userId,
                                    );
                                    if (captainId == null ||
                                        widget.token.isEmpty) {
                                      throw Exception(
                                        'Invalid user session. Please check in again.',
                                      );
                                    }

                                    final KotModel? kot =
                                    await orderRepo.createKOT(
                                      parentOrderId: state.orderId,
                                      kotId: "",
                                      items: state.orderItems,
                                      token: widget.token,
                                      restaurantId:
                                      orderBloc
                                          .state
                                          .restaurantId
                                          .toString(),
                                      zoneId:
                                      orderBloc.state.zoneId,
                                      captainId: captainId,
                                    );

                                    Navigator.of(context).pop();

                                    final permissions =
                                    await SessionManager.loadPermissions();
                                    final captainName =
                                        permissions?.displayName ?? '';
                                    if (kot != null) {
                                      debugPrint(
                                        '========== KOT CREATED ==========',
                                      );

                                      debugPrint(
                                        'KOT Number: ${kot.kotNumber}',
                                      );

                                      debugPrint(
                                        'Original KOT Status: ${kot.status}',
                                      );

                                      debugPrint(
                                        'Is Takeaway: ${widget.isTakeAway}',
                                      );

                                      // ==========================================================
                                      // CAPTURE CONTEXT & STATE BEFORE CLEARING CART
                                      // ==========================================================

                                      final String tableName =
                                          widget.isTakeAway
                                              ? ''
                                              : orderBloc.state.tableName;
                                      final String restaurantId =
                                          orderBloc.state.restaurantId.toString();
                                      final int zoneId =
                                          orderBloc.state.zoneId;
                                      final String zoneName =
                                          orderBloc.state.zoneName;
                                      final List<Map<String, dynamic>> itemsToPrint =
                                          state.orderItems.map((e) {
                                        return {
                                          "name": e.name,
                                          "qty": e.quantity,
                                          "modifiers": e.modifiers.toList(),
                                          "addons": e.addOns,
                                          "note": e.note,
                                        };
                                      }).toList();

                                      final mqttKot = kot.copyWith(
                                        status: kot.status.toLowerCase() == 'created'
                                            ? 'pending'
                                            : kot.status,
                                      );

                                      // ==========================================================
                                      // POS LOCAL KOT STATUS & CLEAR ORDER IMMEDIATELY
                                      // ==========================================================

                                      final updatedKot = kot.copyWith(
                                        status:
                                        kot.status.toLowerCase() == 'created'
                                            ? 'Yet To Prepare'
                                            : kot.status,
                                      );

                                      orderBloc.add(
                                        AddKOT(updatedKot),
                                      );

                                      orderBloc.add(
                                        ClearOrder(),
                                      );

                                      // ==========================================================
                                      // SUCCESS MESSAGE (SHOW IMMEDIATELY)
                                      // ==========================================================

                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: SizedBox(
                                              width: 400,
                                              child: Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'KOT Created: ${kot.kotNumber}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            duration: const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                            margin: EdgeInsets.only(
                                              left: 400,
                                              right: 400,
                                              bottom:
                                              MediaQuery.of(context).size.height *
                                                  0.90,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                            backgroundColor: Colors.green,
                                            elevation: 6,
                                          ),
                                        );
                                      }

                                      // ==========================================================
                                      // PRINT KOT & SEND TO KDS ASYNCHRONOUSLY
                                      // ==========================================================

                                      () async {
                                        await printKot(
                                          kotNo: kot.kotNumber ?? '',
                                          orderId: kot.parentOrderId.toString(),
                                          tableName: tableName,
                                          captainName: captainName,
                                          items: itemsToPrint,
                                          kot: kot,
                                        );

                                        try {
                                          debugPrint(
                                              '========== SENDING KOT TO KDS =========='
                                          );

                                          await KdsMqttPublisher.notifyKotCreated(
                                            restaurantId: restaurantId,
                                            parentOrderId: state.orderId,
                                            zoneId: zoneId,
                                            zoneName: zoneName,
                                            orderType: widget.isTakeAway
                                                ? 'takeaway'
                                                : 'dine_in',
                                            kot: mqttKot,
                                            tableName: tableName,
                                          );
                                          unawaited(
                                            KdsMqttPublisher.notifyKotPrinted(
                                              restaurantId: restaurantId,
                                              orderId: state.orderId > 0 ? state.orderId : widget.orderId,
                                              orderType: widget.isTakeAway ? "Take Away" : "Dine In",
                                              zoneId: zoneId,
                                              zoneName: zoneName,
                                              tableName: tableName,
                                              tableId: widget.tableId.toString(),
                                              kotNumber: kot.kotNumber,
                                              kotId: kot.kotId,
                                            ),
                                          );
                                        } catch (e, stack) {
                                          debugPrint(
                                            ' Failed to send KOT to KDS: $e',
                                          );

                                          debugPrint(
                                            'Stack: $stack',
                                          );
                                        }
                                      }();
                                    }
                                  } catch (e) {
                                    if (Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).canPop()) {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                    }
                                    final message = e
                                        .toString()
                                        .replaceFirst(
                                      "Exception: ",
                                      "",
                                    );
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                        backgroundColor: Colors.red,
                                        behavior:
                                        SnackBarBehavior.floating,
                                        duration: const Duration(
                                          seconds: 1,
                                        ),
                                      ),
                                    );
                                    AppLogger.error(message);
                                  }
                                }
                                    : null,
                              ),

                              orderButton(
                                'Checkout',
                                canPay ? const Color(0xFF16A34A) : Colors.grey,
                                onPressed:
                                    canPay
                                        ? () {
                                          AppLogger.info(
                                            "Pay clicked - Dine In",
                                          );
                                          debugPrint(
                                            "💳 Navigating to PaymentScreen from Dine-In - isTakeAway: false",
                                          );
                                          AppLogger.info("Pay clicked");
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => MultiBlocProvider(
                                                    providers: [
                                                      BlocProvider.value(
                                                        value:
                                                            context
                                                                .read<
                                                                  OrderBloc
                                                                >(),
                                                      ),
                                                      BlocProvider.value(
                                                        value:
                                                            context
                                                                .read<
                                                                  PaymentBloc
                                                                >(),
                                                      ),
                                                      BlocProvider.value(
                                                        value:
                                                            context
                                                                .read<
                                                                  RemoveDiscountBloc
                                                                >(),
                                                      ),
                                                    ],
                                                    child: PaymentScreen(
                                                      loadedTables:
                                                          widget.loadedTables,
                                                      pin: widget.pin,
                                                      token: widget.token,
                                                      restaurantId:
                                                          widget.restaurantId,
                                                      restaurantName:
                                                          widget.restaurantName,
                                                      zoneId: widget.zoneId,
                                                      isTakeAway:
                                                          false, // ✅ Explicitly false for Dine-In
                                                    ),
                                                  ),
                                            ),
                                          );
                                        }
                                        : null,
                              ),
                            ],
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget modifierBadge({required bool hasModifier}) {
    final Color color =
        hasModifier ? const Color(0xFFFFB820) : const Color(0xFFB8B8B8);

    return Container(
      width: 61,
      height: 24,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: color),
          borderRadius: BorderRadius.circular(10),
        ),
        shadows: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        'Modifier',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
    );
  }

  Widget headerBadgeRow(OrderState state) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFECEEFB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                state.zoneName.isNotEmpty ? state.zoneName : 'Loading...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                'Order ID: ${state.orderId}',
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/icon/table.png', width: 18, height: 18),
                  const SizedBox(width: 4),
                  Text(
                    state.tableName.isNotEmpty ? state.tableName : 'Loading...',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget actionButton(
    String text,
    String iconPath,
    Color color, {
    required VoidCallback onPressed,
  }) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      backgroundColor: const Color(0xFFF6F6F6),
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    onPressed: onPressed,
    icon: Image.asset(iconPath, width: 16, height: 16, color: color),
    label: Text(text, style: const TextStyle(fontSize: 12)),
  );

  Widget elevatedActionButton(
    String text,
    String iconPath, {
    required VoidCallback onPressed,
  }) => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF152148),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    onPressed: onPressed,
    icon: Image.asset(iconPath, width: 8, height: 8, color: Colors.white),
    label: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.white),
    ),
  );

  Widget iconText(String assetPath, String label) => Row(
    children: [
      Image.asset(assetPath, width: 18, height: 18),
      const SizedBox(width: 2),
      Text(label, style: const TextStyle(fontSize: 14)),
    ],
  );

  Widget avatarName(String imagePath, String name) => Row(
    children: [
      CircleAvatar(
        radius: 12,
        backgroundColor: Colors.transparent,
        foregroundImage: AssetImage(imagePath),
      ),
      const SizedBox(width: 4),
      Text(name),
    ],
  );

  Widget headerText(String text, {TextAlign align = TextAlign.left}) => Text(
    text,
    textAlign: align,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );
  Widget _takeAwayCheckoutButton(bool canPay) {
    final orderBloc = context.watch<OrderBloc>();
    final state = orderBloc.state;

    // Checkout is enabled only if canPay is true AND cart has items
    final canCheckout = canPay && state.orderItems.isNotEmpty;

    return GestureDetector(
      onTap:
      canCheckout
          ? () async {
        final orderRepo = OrderRepository(
          baseUrl: AppConstants.baseDomain,
        );

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final captainId = int.tryParse(widget.userId);

          if (captainId == null) {
            throw Exception("Invalid user session");
          }

          final existingKotId =
          state.kotList.isNotEmpty
              ? state.kotList.first.kotId
              : null;

          if (existingKotId == null || existingKotId == 0) {
            // ==========================================================
            // FIRST TIME -> CREATE TAKEAWAY KOT
            // ==========================================================

            final kot = await orderRepo.createKOT(
              parentOrderId: state.orderId,
              kotId: "",
              items: state.orderItems,
              token: widget.token,
              restaurantId: state.restaurantId,
              zoneId: state.zoneId,
              captainId: captainId,
            );

            if (kot == null) {
              throw Exception("Failed to generate KOT");
            }

            debugPrint("========== TAKEAWAY KOT CREATED ==========");
            debugPrint("Parent Order ID : ${state.orderId}");
            debugPrint("KOT ID          : ${kot.kotId}");
            debugPrint("KOT Number      : ${kot.kotNumber}");
            debugPrint("KOT Status      : ${kot.status}");
            debugPrint("KOT JSON        : ${kot.toJson()}");
            debugPrint("==========================================");

            // ==========================================================
            // UPDATE LOCAL POS ORDER STATE
            // ==========================================================

            orderBloc.add(AddKOT(kot));
            orderBloc.add(SetTakeAwayKotId(kot.kotId));

            // ==========================================================
            // IMPORTANT:
            // DO NOT SEND MQTT HERE.
            //
            // KDS should NOT display takeaway before payment.
            // MQTT will be sent after payment is completed.
            // ==========================================================
          }
          else {
            // SECOND TIME -> UPDATE SAME KOT
            await orderRepo.updateTakeAwayKot(
              kotId: existingKotId,
              parentOrderId: state.orderId,
              restaurantId: int.parse(state.restaurantId),
              captainId: captainId,
              items: state.orderItems,
              token: widget.token,
            );
          }

          Navigator.pop(context);

          debugPrint(
            "💳 Navigating to PaymentScreen from Take Away - isTakeAway: true",
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<OrderBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<PaymentBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<RemoveDiscountBloc>(),
                  ),
                ],
                child: PaymentScreen(
                  loadedTables: widget.loadedTables,
                  pin: widget.pin,
                  token: widget.token,
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                  zoneId: widget.zoneId,
                  isTakeAway: true,
                ),
              ),
            ),
          );
        } catch (e) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceFirst("Exception: ", ""),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
          : null,
      child: Container(
        width: double.infinity,
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
          canCheckout ? const Color(0xFF086888) : const Color(0xFFDEDEDE),
          borderRadius: BorderRadius.circular(14),
          border:
          canCheckout
              ? null
              : Border.all(color: const Color(0xFFC0C0C0), width: 1),
          boxShadow:
          canCheckout
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          "Check out",
          style: TextStyle(
            color: canCheckout ? Colors.white : const Color(0xFFABABAB),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.33,
          ),
        ),
      ),
    );
  }

  Widget orderButton(
    String text,
    Color color, {
    VoidCallback? onPressed,
    bool isLoading = false,
    Color? textColor,
  }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed == null ? Colors.grey : color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onPressed,
          child:
              isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    text,
                    style: TextStyle(
                      color:
                          textColor ??
                          (onPressed == null
                              ? const Color(0xFF757575) // Disabled text
                              : Colors.white), // Enabled text
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    ),
  );
}
