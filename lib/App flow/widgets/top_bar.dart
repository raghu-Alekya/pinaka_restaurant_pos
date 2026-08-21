import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/print_receipt.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';
import 'package:thermal_printer/thermal_printer.dart';

import '../../models/UserPermissions.dart';
import '../../printer/printer_db_helper.dart';
import '../../printer/printer_settings.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../utils/SessionManager.dart';
import '../../utils/theme_provider.dart';
import '../ui/CheckinPopup.dart';
import '../ui/DailyAttendanceScreen.dart';
import '../ui/SettingsScreen.dart';
import '../ui/employee_login_page.dart';
import '../ui/home_screen.dart';
import '../ui/tables_screen.dart';
import 'LogoutConfirmationDialog.dart';

// Added for Payment Screen support
import '../../models/payment/payment_summary_model.dart';
import '../../repositories/ordertype_payment.dart';

// Added for Print support
import '../../printer/printer_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/Bloc Event/subcategory_event.dart';
import '../../blocs/Bloc Event/minisubcategory_event.dart';
import '../../blocs/Bloc Event/product_event.dart';
import '../../blocs/Bloc Logic/subcategory_bloc.dart';
import '../../blocs/Bloc Logic/minisubcategory_bloc.dart';
import '../../blocs/Bloc Logic/product_bloc.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../constants/constants.dart';
import '../../repositories/order_repository.dart';
import 'confirmation_pop_up.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String token;
  final String pin;
  final UserPermissions? userPermissions;
  final Function(UserPermissions)? onPermissionsReceived;
  final bool isHomeScreen;
  final bool isOrderPanel;
  final bool showTablesIcon;
  final VoidCallback? onTablesTap;
  final String restaurantId;
  final String restaurantName;

  // ── Payment Screen parameters ──────────────────────────
  final bool isPaymentScreen;
  final PaymentSummary? paymentSummary;
  final VoidCallback? onBackPressed;
  final ValueChanged<String>? onOrderTypeChanged;
  final ValueChanged<String>? onCustomerPhoneChanged;
  final VoidCallback? onAddCustomer;

  // ── Additional parameters for PrintRecipt ──────────────
  final String cashierName;
  final List<Map<String, dynamic>> loadedTables;
  final int? zoneId;
  final bool isTakeAway;
  final bool showSearchBar;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final LayerLink? searchLink;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchTap;
  final Future<bool> Function()? onHomePressed;
  const TopBar({
    Key? key,
    required this.token,
    required this.pin,
    this.userPermissions,
    this.onPermissionsReceived,
    this.isHomeScreen = false,
    this.isOrderPanel = false,
    this.showTablesIcon = false,
    this.onTablesTap,
    required this.restaurantId,
    required this.restaurantName,
    this.isPaymentScreen = false,
    this.paymentSummary,
    this.onBackPressed,
    this.onOrderTypeChanged,
    this.onCustomerPhoneChanged,
    this.onAddCustomer,
    this.cashierName = '',
    this.loadedTables = const [],
    this.zoneId,
    this.isTakeAway = false,
    this.showSearchBar = false,
    this.searchController,
    this.searchFocusNode,
    this.searchLink,
    this.onSearchChanged,
    this.onSearchTap,
    this.onHomePressed,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(75);

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  bool isLightMode = true;
  bool _isAttendanceDialogOpen = false;
  bool _isCheckInDone = false;
  UserPermissions? _permissions;

  // ── Payment Screen state ───────────────────────────────
  List<String> orderTypes = [];
  String? selectedOrderType;
  final TextEditingController _customerPhoneController =
  TextEditingController();

  PaymentSummary? _localPaymentSummary;

  // ── FIX: guard so a fast double-tap on Print doesn't fire two jobs
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _localPaymentSummary = widget.paymentSummary;

    if (widget.isPaymentScreen) {
      _loadOrderTypes();
    }
  }

  @override
  void didUpdateWidget(TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paymentSummary != oldWidget.paymentSummary) {
      setState(() {
        _localPaymentSummary = widget.paymentSummary;
      });
    }
  }

  @override
  void dispose() {
    _customerPhoneController.dispose();
    super.dispose();
  }

  List<String> get _filteredOrderTypes {
    if (widget.isTakeAway) {
      return orderTypes
          .where((t) => t.toLowerCase().contains("takeaway"))
          .toList();
    } else {
      return orderTypes
          .where((t) => t.toLowerCase().contains("dine in"))
          .toList();
    }
  }

  Future<void> _loadOrderTypes() async {
    try {
      final repo = OrderTypesInPaymentScreenRepository();
      final result = await repo.getOrderTypes(token: widget.token);
      if (result != null && mounted) {
        setState(() {
          orderTypes = result.orderTypes;

          final filtered =
          widget.isTakeAway
              ? orderTypes
              .where((t) => t.toLowerCase().contains("takeaway"))
              .toList()
              : orderTypes
              .where((t) => t.toLowerCase().contains("dine in"))
              .toList();

          selectedOrderType =
          widget.paymentSummary?.orderType != null &&
              filtered.contains(widget.paymentSummary?.orderType)
              ? widget.paymentSummary?.orderType
              : (filtered.isNotEmpty ? filtered.first : null);
        });
      }
    } catch (e) {
      debugPrint(" Order Types Error in TopBar: $e");
    }
  }

  Future<void> _cancelTakeAwayAndGoHome() async {
    final currentOrderId = context.read<OrderBloc>().state.orderId;

    if (currentOrderId == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (_) => HomeScreen(
                pin: widget.pin,
                token: widget.token,
                restaurantId: widget.restaurantId,
                restaurantName: widget.restaurantName,
              ),
        ),
        (route) => false,
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
              title: "Exit Current Order?",
              message:
                  "The current order has items in the cart. Do you want to really cancel this order?",
              imagePath: "assets/warning_icon.png",
              confirmButtonText: "Yes, Cancel!",
              cancelButtonText: "No, Keep It",
              primaryColor: const Color(0xFFD83434),
              gradientColor: const Color(0xFFFCE9E9),
              isLoading: isLoading,

              onCancel: () {
                Navigator.of(dialogContext).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      pin: widget.pin,
                      token: widget.token,
                      restaurantId: widget.restaurantId,
                      restaurantName: widget.restaurantName,
                    ),
                  ),
                      (route) => false,
                );
              },
              onConfirm: () async {
                setState(() {
                  isLoading = true;
                });

                try {
                  final orderRepo = OrderRepository(
                    baseUrl: AppConstants.baseDomain,
                  );

                  final orderState = context.read<OrderBloc>().state;

                  await orderRepo.cancelTakeAwayOrder(
                    parentOrderId: currentOrderId,
                    restaurantId: int.parse(orderState.restaurantId),
                    token: widget.token,
                  );

                  if (!context.mounted) return;

                  // close popup
                  Navigator.pop(dialogContext);

                  // update bloc
                  context.read<OrderBloc>().add(
                    CancelOrder(
                      parentOrderId: currentOrderId,
                      token: widget.token,
                    ),
                  );

                  context.read<OrderBloc>().add(ClearOrder());
                  context.read<OrderBloc>().add(ResetOrder());

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Takeaway order cancelled successfully"),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => HomeScreen(
                            pin: widget.pin,
                            token: widget.token,
                            restaurantId: widget.restaurantId,
                            restaurantName: widget.restaurantName,
                          ),
                    ),
                    (route) => false,
                  );
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(dialogContext);

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
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getCashPrinterCandidates() async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> printers = [];

    final printerDb = PrinterDBHelper();
    final dbPrinters = await printerDb.getSelectedPrintersFromDB();

    for (var printer in dbPrinters) {
      final address = printer['printer_address'] ?? '';
      final name = printer['deviceName'] ?? printer['device_name'] ?? 'Printer';
      String type = printer[AppDBConst.printerType] ?? 'network';

      final vendorIdRaw = printer[AppDBConst.printerVendorId]?.toString() ?? '';
      final productIdRaw =
          printer[AppDBConst.printerProductId]?.toString() ?? '';
      final vendorIdIsBad = vendorIdRaw.isEmpty || vendorIdRaw == 'network';
      final productIdIsBad = productIdRaw.isEmpty || productIdRaw == 'network';

      if (type == 'usb' &&
          (vendorIdRaw == 'network' || productIdRaw == 'network')) {
        await printerDb.fixPrinterRecord(
          address: address,
          currentDeviceName: name,
          clearVendorId: vendorIdRaw == 'network',
          clearProductId: productIdRaw == 'network',
        );
      }

      if (type == 'network' && address.isEmpty) {
        type = 'usb';
        await printerDb.fixPrinterRecord(
          address: address,
          currentDeviceName: name,
          correctedType: 'usb',
        );
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

    // Order candidates: cash-named first, then everything else
    // (so a name match is tried first, but nothing is ever discarded —
    // every selected printer becomes a fallback candidate).
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

  // Kept for compatibility with any other caller — returns just the
  // top candidate.
  Future<Map<String, dynamic>?> _getCashPrinter() async {
    final candidates = await _getCashPrinterCandidates();
    return candidates.isEmpty ? null : candidates.first;
  }

  Future<void> _printBill() async {
    PaymentSummary? summaryToPrint =
        _localPaymentSummary ?? widget.paymentSummary;

    if (summaryToPrint == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No payment summary available. Please try again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      debugPrint("========== BILL DATA ==========");
      debugPrint("Order ID: ${summaryToPrint.orderId}");
      debugPrint("Table Name: ${summaryToPrint.tableName}");
      debugPrint(
        "Cashier: ${widget.cashierName.isNotEmpty ? widget.cashierName : widget.userPermissions?.displayName ?? 'Admin'}",
      );
      debugPrint("Gross Total: ${summaryToPrint.grossTotal}");
      debugPrint("Coupon Discount: ${summaryToPrint.coupons}");
      debugPrint("Merchant Discount: ${summaryToPrint.discount}");
      debugPrint("Tip: ${summaryToPrint.tipAmount}");
      debugPrint("Tax: ${summaryToPrint.tax}");
      debugPrint("Service Charge: ${summaryToPrint.serviceChargeValue}");
      debugPrint("Net Payable: ${summaryToPrint.netTotal}");

      debugPrint("Items:");
      for (var item in summaryToPrint.lineItems) {
        debugPrint("----------------------------");
        debugPrint("Name: ${item.name}");
        debugPrint("Qty: ${item.qty}");
        debugPrint("Price: ${item.price}");
        debugPrint("Amount: ${item.total}");
        debugPrint("Modifiers: ${item.modifiers}");
      }
      debugPrint("================================");

      final cashPrinter = await _getCashPrinter();
      debugPrint("🔍 Resolved cash printer -> $cashPrinter");

      if (cashPrinter == null) {
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
        setState(() => _isPrinting = false);
        return;
      }

      final address = cashPrinter['address'] ?? '';
      final name = cashPrinter['name'] ?? 'Cash Printer';
      final port = cashPrinter['port'] ?? '9100';
      final type = cashPrinter['type'] ?? 'network';
      final vendorId = cashPrinter['vendorId'];
      final productId = cashPrinter['productId'];

      // Only network printers truly require a non-empty address.
      // USB relies on vendorId/productId (or just name-based matching if
      // those weren't captured), so it's never blocked here.
      if (type == 'network' && address.isEmpty) {
        debugPrint("❌ Blocked: type=network but address is empty for '$name'");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Printer address is invalid"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        setState(() => _isPrinting = false);
        return;
      }

      List<int> bytes = await _generateBillBytes(summaryToPrint);

      try {
        debugPrint(
          "🖨️ Printing bill to: $name (type=$type, address='$address', port=$port, vendorId=$vendorId, productId=$productId)",
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

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Receipt printed successfully"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          debugPrint(
            "❌ Failed to connect to printer: $name ($type - $address)",
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to connect to printer: $name"),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Error printing bill: ${e.toString().replaceFirst('Exception: ', '')}",
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
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

  // Helper method to generate bill bytes
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
            PosColumn(
              width: 6,
              text: "  + $modifier",
              // styles: const PosStyles(fontSize: PosFontSize.fontSizeB),
            ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.paymentSummary != null &&
        _localPaymentSummary != widget.paymentSummary) {
      _localPaymentSummary = widget.paymentSummary;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
          bottom: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            isDark
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 75,
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        title: SizedBox(
          height: 75,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LEFT SIDE
                if (widget.isPaymentScreen)
                  GestureDetector(
                    onTap: widget.onBackPressed ?? () => Navigator.pop(context),
                    child: Container(
                      width: 84,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Back",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Image.asset(
                    isDark ? 'assets/pinaka_dark.png' : 'assets/pinaka.png',
                    height: 50,
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(width: 75),

                if (widget.showSearchBar)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CompositedTransformTarget(
                        link: widget.searchLink!,
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color:
                            isDark ? const Color(0xFF2A2A2A) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                              isDark
                                  ? Colors.grey.shade700
                                  : const Color(0xFFE5E7EB),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: widget.searchController,
                            focusNode: widget.searchFocusNode,
                            onTap: widget.onSearchTap,
                            onChanged: widget.onSearchChanged,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: "Search item or short code....",
                              hintStyle: TextStyle(
                                color:
                                isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF9CA3AF),
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 10, right: 8),
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: Color(0xFFB6BDC7),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 38,
                                minHeight: 38,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // CENTER - PAYMENT CONTROLS
                if (widget.isPaymentScreen)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // const Text("Customer :", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      // const SizedBox(width: 8),
                      // SizedBox(
                      //   width: 170,
                      //   height: 38,
                      //   child: TextField(
                      //     controller: _customerPhoneController,
                      //     keyboardType: TextInputType.phone,
                      //     style: const TextStyle(fontSize: 13),
                      //     onChanged: widget.onCustomerPhoneChanged,
                      //     decoration: InputDecoration(
                      //       hintText: "Mobile number",
                      //       hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                      //       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      //       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                      //       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F7CFF), width: 1.5)),
                      //       filled: true,
                      //       fillColor: Colors.white,
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(width: 8),
                      // GestureDetector(
                      //   onTap: widget.onAddCustomer,
                      //   child: Container(
                      //     height: 38,
                      //     padding: const EdgeInsets.symmetric(horizontal: 16),
                      //     decoration: BoxDecoration(color: const Color(0xFF1A2B4A), borderRadius: BorderRadius.circular(8)),
                      //     child: const Row(
                      //       mainAxisSize: MainAxisSize.min,
                      //       children: [
                      //         Icon(Icons.add, color: Colors.white, size: 16),
                      //         SizedBox(width: 4),
                      //         Text("Add", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(width: 625),
                      // Order Type Dropdown
                      Container(
                        width: 235,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color:
                              isDark ? Colors.black : const Color(0xFFF9FBFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                            isDark
                                ? Colors.grey.shade700
                                : const Color(0xFFE6E6E6),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedOrderType,
                            isExpanded: true,
                            dropdownColor:
                            isDark ? const Color(0xFF2B2B2B) : Colors.white,
                            iconEnabledColor:
                            isDark ? Colors.white : Colors.black,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                            ),
                            hint: Text(
                              "Dine In",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            items:
                            orderTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color:
                                    isDark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
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
                                orderId: widget.paymentSummary!.orderId,
                                orderType: value,
                              );

                              if (result?.success == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result!.message),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Print Button
                      GestureDetector(
                        onTap: _isPrinting ? null : _printBill,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color:
                            _isPrinting
                                ? const Color(0xFF9AD9AE)
                                : const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                          _isPrinting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.print_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Print",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                const Spacer(),

                // ==================== RIGHT SIDE ====================
                // Show Profile always, but hide other buttons on Payment Screen
                if (widget.isPaymentScreen) ...[
                  _buildProfileSection(),
                ] else ...[
                  if (widget.isHomeScreen) ...[
                    if (widget.userPermissions?.canCreateShiftAttendance ?? false) ...[
                      _buildAttendanceIconButton(context),
                      const SizedBox(width: 10),
                    ],
                    _buildNotificationIconButton(),
                    const SizedBox(width: 10),
                    _buildThemeButton(),
                    const SizedBox(width: 10),
                    _buildSettingsButton(),
                    const SizedBox(width: 10),
                    _buildLogoutButton(),
                    const SizedBox(width: 10),
                    _buildProfileSection(),
                  ] else if (widget.isOrderPanel) ...[
                    _buildHomeButton(),
                    const SizedBox(width: 10),
                    if (!widget.isTakeAway) ...[
                      _buildTablesButton(),
                      const SizedBox(width: 10),
                    ],

                    _buildNotificationIconButton(),
                    const SizedBox(width: 10),
                    _buildThemeButton(),
                    const SizedBox(width: 10),
                    _buildSettingsButton(),
                    const SizedBox(width: 10),
                    _buildProfileSection(),
                  ] else ...[
                    _buildHomeButton(),
                    const SizedBox(width: 10),
                    _buildNotificationIconButton(),
                    const SizedBox(width: 10),
                    _buildThemeButton(),
                    const SizedBox(width: 10),
                    _buildSettingsButton(),
                    const SizedBox(width: 10),
                    _buildLogoutButton(),
                    const SizedBox(width: 10),
                    _buildProfileSection(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ALL HELPER METHODS (UNCHANGED) ====================

  Widget _buildHomeButton() {
    return GestureDetector(
      onTap: () async {
        if (widget.isOrderPanel && widget.isTakeAway) {
          _cancelTakeAwayAndGoHome();
          return;
        }

        bool shouldNavigate = true;

        if (widget.onHomePressed != null) {
          shouldNavigate = await widget.onHomePressed!();
        }

        if (!shouldNavigate) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (_) => HomeScreen(
              token: widget.token,
              pin: widget.pin,
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
            ),
          ),
              (route) => false,
        );
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF7B4597),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x667B4597),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.home_outlined, color: Colors.white, size: 22),
            SizedBox(height: 3),
            Text(
              "Home",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => TablesScreen(
              loadedTables: const [],
              pin: widget.pin,
              token: widget.token,
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
              userPermissions: widget.userPermissions,
            ),
          ),
        );
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF048DCB),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4C048ECC),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.table_restaurant, color: Colors.white, size: 22),
            SizedBox(height: 3),
            Text(
              "Tables",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: () {
        themeProvider.toggleTheme();
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x666366F1),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              themeProvider.isDark ? "Light" : "Dark",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => SettingsScreen(
              token: widget.token,
              pin: widget.pin,
              userId: widget.userPermissions?.userId ?? '',
              displayName: widget.userPermissions?.displayName ?? '',
              role: widget.userPermissions?.role ?? '',
            ),
          ),
        );
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x664CAF50),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/setting.png',
              width: 22,
              height: 22,
              color: Colors.white,
            ),
            const SizedBox(height: 3),
            const Text(
              "Settings",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => LogoutConfirmationDialog(
            onCancel: () => Navigator.pop(context, false),
            onConfirm: () => Navigator.pop(context, true),
          ),
        );

        if (result != true) return;

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? "";

        final authRepository = AuthRepository();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final success = await authRepository.logout(token);

          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (success && context.mounted) {
            // ✅ ADD — purge stale category/subcategory/product state & caches
            // so the next login doesn't show leftover data from this session.
            // Guarded with try/catch since TopBar is reused on screens where
            // these Blocs may not be provided above it in the tree.
            try {
              context.read<SubCategoryBloc>().add(ResetSubCategory());
              context.read<MiniSubCategoryBloc>().add(ResetMiniSubCategory());
              context.read<ProductBloc>().add(ClearProducts());
            } catch (_) {
              // Blocs not available on this screen — safe to ignore.
            }

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder:
                    (_) => const EmployeeLoginPage(
                  storeBaseUrl: '',
                  storeName: '',
                  storeId: '',
                ),
              ),
                  (route) => false,
            );
          }
          // if (success && context.mounted) {
          //   Navigator.pushAndRemoveUntil(
          //     context,
          //     MaterialPageRoute(
          //       builder: (_) => const EmployeeLoginPage(
          //         storeBaseUrl: '',
          //         storeName: '',
          //         storeId: '',
          //       ),
          //     ),
          //         (route) => false,
          //   );
          // }
        } catch (e) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst("Exception: ", "")),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FF9800),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white, size: 22),
            const SizedBox(height: 3),
            const Text(
              "Logout",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Widget _buildLogoutButton() {
  //   return _buildIconButton(
  //     label: "Logout",
  //     color: const Color(0xFFFF9800),
  //     icon: Image.asset('assets/logout.png', width: 24, height: 24, color: const Color(0xFFFF9800)),
  //     onPressed: () async {
  //       final result = await showDialog<bool>(
  //         context: context,
  //         barrierDismissible: false,
  //         builder: (_) => LogoutConfirmationDialog(
  //           onCancel: () => Navigator.pop(context, false),
  //           onConfirm: () => Navigator.pop(context, true),
  //         ),
  //       );
  //
  //       if (result != true) return;
  //
  //       final prefs = await SharedPreferences.getInstance();
  //       final token = prefs.getString('token') ?? "";
  //
  //       final authRepository = AuthRepository();
  //
  //       showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
  //
  //       try {
  //         final success = await authRepository.logout(token);
  //         if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
  //
  //         if (success && context.mounted) {
  //           // ✅ ADD — purge stale category/subcategory/product state & caches
  //           // so the next login doesn't show leftover data from this session.
  //           // Guarded with try/catch since TopBar is reused on screens where
  //           // these Blocs may not be provided above it in the tree.
  //           try {
  //             context.read<SubCategoryBloc>().add(ResetSubCategory());
  //             context.read<MiniSubCategoryBloc>().add(ResetMiniSubCategory());
  //             context.read<ProductBloc>().add(ClearProducts());
  //           } catch (_) {
  //             // Blocs not available on this screen — safe to ignore.
  //           }
  //
  //           Navigator.pushAndRemoveUntil(
  //             context,
  //             MaterialPageRoute(builder: (_) => const EmployeeLoginPage(storeBaseUrl: '', storeName: '', storeId: '')),
  //                 (route) => false,
  //           );
  //         }
  //       } catch (e) {
  //         if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red));
  //       }
  //     },
  //   );
  // }

  Widget _buildAttendanceIconButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isAttendanceDialogOpen) return;

        setState(() {
          _isAttendanceDialogOpen = true;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final repository = EmployeeRepository();
          final response = await repository.getAllEmployees(widget.token);

          final List<Employee> employees =
          response.map((e) {
            return Employee(
              id: e['ID'].toString(),
              name: e['name'].toString(),
            );
          }).toList();

          final currentShift = await repository.getCurrentShift(widget.token);

          if (currentShift != null) {
            final presentIds = List<int>.from(currentShift['shift_emp'] ?? []);
            final absentIds = List<int>.from(
              currentShift['shift_absent_emp'] ?? [],
            );

            for (var emp in employees) {
              final empId = int.tryParse(emp.id);
              if (presentIds.contains(empId)) {
                emp.status = 'Present';
              } else if (absentIds.contains(empId)) {
                emp.status = 'Absent';
              } else {
                emp.status = '';
              }
            }
          }

          if (context.mounted) {
            Navigator.pop(context);

            final shiftData = await EmployeeRepository().getCurrentShift(
              widget.token,
            );

            final permissions = await SessionManager.loadPermissions();

            if (permissions == null ||
                !permissions.canUpdateShiftAttendance) {
              return;
            }

            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AttendancePopup(
                token: widget.token,
                employees: employees,
                isUpdateMode: true,
                currentShiftData: shiftData,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to load employees'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 1),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isAttendanceDialogOpen = false;
            });
          }
        }
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF4F7CFF),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x664F7CFF),
              blurRadius: 4,
              offset: Offset(0, 0), // Horizontal shadow only
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/attendance.png',
              width: 22,
              height: 22,
              color: Colors.white,
            ),
            const SizedBox(height: 3),
            const Text(
              "Attendance",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIconButton({VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFEACA00),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66D8C300),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                Positioned(
                  top: 1,
                  right: -1,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF0303),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              "Alerts",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required Widget icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 65,
        height: 51,
        margin: const EdgeInsets.only(right: 14, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarUrl = widget.userPermissions?.avatar;

    final bool isPayment = widget.isPaymentScreen;

    return Container(
      height: isPayment ? 42 : 55,
      padding: EdgeInsets.symmetric(horizontal: isPayment ? 10 : 14),
      decoration: ShapeDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        shadows: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: isPayment ? 15 : 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
            avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : const AssetImage('assets/loginname.png') as ImageProvider,
          ),
          SizedBox(width: isPayment ? 8 : 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.userPermissions?.displayName ?? "username",
                style: TextStyle(
                  fontSize: isPayment ? 11 : 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: isPayment ? 1 : 2),
              Text(
                widget.userPermissions?.role ?? "role",
                style: TextStyle(
                  fontSize: isPayment ? 9 : 12,
                  color: theme.textTheme.bodySmall?.color,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
