import 'dart:async';
import 'dart:convert';

import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:restaurant_captain_app/features/printer/printer_db_helper.dart';
import 'package:restaurant_captain_app/features/printer/printer_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';
import 'package:thermal_printer/thermal_printer.dart';

class PrinterSetup extends StatefulWidget {
  const PrinterSetup({Key? key}) : super(key: key);

  @override
  State<PrinterSetup> createState() => _PrinterSetupState();
}

class _PrinterSetupState extends State<PrinterSetup> {
  // ==================== DESIGN TOKENS (matches app screenshot) ====================
  static const Color _screenBg = Color(0xFFF6F7FB);
  static const Color _connectedGreen = Color(0xFF27AE60);
  static const Color _connectedGreenBg = Color(0xFFE8F8ED);
  static const Color _addOrange = Color(0xFFFF6A39);
  static const Color _connectBlue = Color(0xFF3B6FE0);

  // Cycled icon colors per card, same palette family as screenshot
  static const List<Color> _iconBg = [
    Color(0xFFE3ECFF), // blue
    Color(0xFFFFE9DC), // orange
    Color(0xFFEDE7FF), // purple
    Color(0xFFE1F7E8), // green
  ];
  static const List<Color> _iconFg = [
    Color(0xFF3B6FE0),
    Color(0xFFFF7A3D),
    Color(0xFF7B61FF),
    Color(0xFF23B26D),
  ];

  // ==================== EXISTING STATE (unchanged) ====================
  var defaultPrinterType = PrinterType.bluetooth;
  var _isBle = false;
  var _reconnect = false;
  var _isConnected = false;
  var printerManager = PrinterManager.instance;
  var devices = <BluetoothPrinter>[];
  StreamSubscription<PrinterDevice>? _subscription;
  StreamSubscription<BTStatus>? _subscriptionBtStatus;
  StreamSubscription<USBStatus>? _subscriptionUsbStatus;
  StreamSubscription<TCPStatus>? _subscriptionTCPStatus;
  BTStatus _currentStatus = BTStatus.none;
  TCPStatus _currentTCPStatus = TCPStatus.none;
  USBStatus _currentUsbStatus = USBStatus.none;
  List<int>? pendingTask;
  String _ipAddress = '';
  String _port = '9100';
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  static BluetoothPrinter? selectedPrinter;
  final PrinterSettings _printerSettings = PrinterSettings();

  List<NetworkPrinterConfig> _networkPrinters = [];
  List<BluetoothPrinter> _selectedPrinters = [];
  bool _isPrinting = false;

  List<BluetoothPrinter> _networkDevices = [];
  bool _isScanningNetwork = false;

  @override
  void initState() {
    if (Platform.isWindows) defaultPrinterType = PrinterType.usb;
    super.initState();
    _portController.text = _port;
    _scan();

    _subscriptionBtStatus = PrinterManager.instance.stateBluetooth.listen((
        status,
        ) {
      log(' ----------------- status bt $status ------------------ ');
      _currentStatus = status;
      if (status == BTStatus.connected) {
        setState(() {
          _isConnected = true;
        });
      }
      if (status == BTStatus.none) {
        setState(() {
          _isConnected = false;
        });
      }
      if (status == BTStatus.connected && pendingTask != null) {
        if (Platform.isAndroid) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            PrinterManager.instance.send(
              type: PrinterType.bluetooth,
              bytes: pendingTask!,
            );
            pendingTask = null;
          });
        } else if (Platform.isIOS) {
          PrinterManager.instance.send(
            type: PrinterType.bluetooth,
            bytes: pendingTask!,
          );
          pendingTask = null;
        }
      }
    });

    _subscriptionUsbStatus = PrinterManager.instance.stateUSB.listen((status) {
      if (kDebugMode) {
        print(' ----------------- status usb $status ------------------ ');
      }
      _currentUsbStatus = status;
      if (Platform.isAndroid) {
        if (status == USBStatus.connected && pendingTask != null) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            PrinterManager.instance.send(
              type: PrinterType.usb,
              bytes: pendingTask!,
            );
            pendingTask = null;
          });
        }
      }
    });

    _subscriptionTCPStatus = PrinterManager.instance.stateTCP.listen((status) {
      log(' ----------------- status tcp $status ------------------ ');
      _currentTCPStatus = status;
    });

    _loadNetworkPrinters();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscriptionBtStatus?.cancel();
    _subscriptionUsbStatus?.cancel();
    _subscriptionTCPStatus?.cancel();
    _portController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  // ==================== NETWORK SCAN (unchanged logic) ====================
  void _scanNetworkPrinters() async {
    if (_isScanningNetwork) return;

    setState(() {
      _isScanningNetwork = true;
      _networkDevices.clear();
    });

    try {
      final subscription = printerManager
          .discovery(type: PrinterType.network, isBle: false)
          .listen((device) {
        if (kDebugMode) {
          print(
            "Network device found: ${device.name}, address: ${device.address}",
          );
        }

        if (device.name == null || device.name!.isEmpty) return;
        if (device.address == null || device.address!.isEmpty) return;

        final exists = _networkDevices.any(
              (d) => d.address == device.address,
        );

        if (!exists) {
          setState(() {
            _networkDevices.add(
              BluetoothPrinter(
                deviceName: device.name ?? "Unknown Printer",
                address: device.address ?? "",
                vendorId: device.vendorId,
                productId: device.productId,
                isBle: false,
                typePrinter: PrinterType.network,
              ),
            );
          });
        }
      });

      await Future.delayed(const Duration(seconds: 5));
      await subscription.cancel();

      // if (_networkDevices.isEmpty) {
      //   final commonPrinters = [
      //     '192.168.1.100',
      //     '192.168.1.101',
      //     '192.168.0.100',
      //     '192.168.0.101',
      //     '10.0.0.100',
      //     '10.0.0.101',
      //   ];
      //
      //   for (final ip in commonPrinters) {
      //     setState(() {
      //       _networkDevices.add(
      //         BluetoothPrinter(
      //           deviceName: 'Printer at $ip',
      //           address: ip,
      //           vendorId: null,
      //           productId: null,
      //           isBle: false,
      //           typePrinter: PrinterType.network,
      //         ),
      //       );
      //     });
      //   }
      // }
    } catch (e) {
      if (kDebugMode) {
        print("Network scan error: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning network: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanningNetwork = false;
        });
      }
    }
  }

  String _getPrinterName(int index, String defaultName) {
    if (index == 0) {
      return "KOT Printer";
    } else if (index == 1) {
      return "Cash Printer";
    } else {
      return "Printer ${index + 1}";
    }
  }

  Future<void> _saveNetworkPrinters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, String>> printerList =
      _networkPrinters.asMap().entries.map((entry) {
        final index = entry.key;
        final p = entry.value;
        return {
          'ip': p.ipAddress,
          'port': p.port,
          'name': p.name,
          'index': index.toString(),
        };
      }).toList();
      await prefs.setString('network_printers', jsonEncode(printerList));
    } catch (e) {
      print('Error saving network printers: $e');
    }
  }

  Future<void> _loadNetworkPrinters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('network_printers');
      if (saved != null && saved.isNotEmpty) {
        final List<dynamic> list = jsonDecode(saved);
        setState(() {
          _networkPrinters = list.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            String name = item['name'] ?? '';
            if (name.isEmpty) {
              name = _getPrinterName(index, '');
            }
            return NetworkPrinterConfig(
              ipAddress: item['ip'] ?? '',
              port: item['port'] ?? '9100',
              name: name,
            );
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading network printers: $e');
    }
  }

  void _addNetworkPrinter() {
    if (_ipController.text.isNotEmpty && _portController.text.isNotEmpty) {
      final index = _networkPrinters.length;
      final name = _getPrinterName(index, '');

      setState(() {
        _networkPrinters.add(
          NetworkPrinterConfig(
            ipAddress: _ipController.text,
            port: _portController.text,
            name: name,
          ),
        );
        _ipController.clear();
        _saveNetworkPrinters();
      });
    }
  }

  void _removeNetworkPrinter(int index) {
    setState(() {
      final printer = _networkPrinters[index];
      _networkPrinters.removeAt(index);
      _selectedPrinters.removeWhere((p) => p.address == printer.ipAddress);
      _saveNetworkPrinters();
    });
  }

  // ==================== UNIFIED CONNECT / SELECT (new, wraps old logic) ====================

  bool _isPrinterSelected(BluetoothPrinter device) {
    if (device.typePrinter == PrinterType.usb) {
      return _selectedPrinters.any(
            (p) =>
        p.deviceName == device.deviceName &&
            p.vendorId == device.vendorId &&
            p.productId == device.productId &&
            p.typePrinter == PrinterType.usb,
      );
    } else if (device.typePrinter == PrinterType.network) {
      return _selectedPrinters.any((p) => p.address == device.address);
    } else {
      return selectedPrinter?.address == device.address && _isConnected;
    }
  }

  Future<void> _handleConnectPrinter(BluetoothPrinter device) async {
    if (_isPrinterSelected(device)) {
      await _handleDisconnectPrinter(device);
      return;
    }

    if (device.typePrinter == PrinterType.usb) {
      setState(() {
        _selectedPrinters.add(device);
      });
      try {
        final printerDb = PrinterDBHelper();
        await printerDb.addPrinterToDB(device);
        await printerDb.updatePrinterSelection(
          device.address ?? '',
          true,
          deviceName: device.deviceName,
        );
      } catch (e) {
        print('Error persisting USB printer selection: $e');
      }
    } else if (device.typePrinter == PrinterType.network) {
      setState(() {
        _selectedPrinters.add(device);
      });
      final exists = _networkPrinters.any((p) => p.ipAddress == device.address);
      if (!exists) {
        setState(() {
          _networkPrinters.add(
            NetworkPrinterConfig(
              ipAddress: device.address ?? '',
              port: (device.port == null || device.port!.isEmpty) ? '9100' : device.port!,
              name: device.deviceName ?? _getPrinterName(_networkPrinters.length, ''),
            ),
          );
        });
        _saveNetworkPrinters();
      }
    } else {
      // bluetooth
      try {
        await _printerSettings.selectDevice(device);
        if (mounted) {
          setState(() {
            selectedPrinter = device;
          });
        }
        final connected = await _printerSettings.connectDevice();
        if (!connected && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Printer does not have required details. Please select another printer.",
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        if (mounted) {
          setState(() {
            _isConnected = connected;
          });
        }
        try {
          final printerDb = PrinterDBHelper();
          final existing = await printerDb.getPrinterFromDB();
          if (existing.isEmpty) {
            await printerDb.addPrinterToDB(device);
          } else {
            await printerDb.updatePrinterToDB(device);
          }
        } catch (dbError) {
          print("DB save error (non-fatal): $dbError");
        }
      } catch (e, s) {
        print("Exception: $e, Stack: $s");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error connecting to printer."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDisconnectPrinter(BluetoothPrinter device) async {
    if (device.typePrinter == PrinterType.usb) {
      setState(() {
        _selectedPrinters.removeWhere(
              (p) =>
          p.deviceName == device.deviceName &&
              p.vendorId == device.vendorId &&
              p.productId == device.productId &&
              p.typePrinter == PrinterType.usb,
        );
      });
      try {
        await PrinterDBHelper().updatePrinterSelection(
          device.address ?? '',
          false,
          deviceName: device.deviceName,
        );
      } catch (e) {
        print('Error un-persisting USB printer selection: $e');
      }
    } else if (device.typePrinter == PrinterType.network) {
      setState(() {
        _selectedPrinters.removeWhere((p) => p.address == device.address);
      });
    } else {
      printerManager.disconnect(type: PrinterType.bluetooth);
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  // ==================== PRINTING (unchanged logic) ====================

  Future<bool> _printToSinglePrinter(
      BluetoothPrinter printer,
      List<int> bytes,
      ) async {
    try {
      print(
        'Attempting to connect to: ${printer.deviceName} (${printer.typePrinter})',
      );

      bool connected = false;

      switch (printer.typePrinter) {
        case PrinterType.usb:
          connected = await printerManager.connect(
            type: PrinterType.usb,
            model: UsbPrinterInput(
              name: printer.deviceName,
              productId: printer.productId,
              vendorId: printer.vendorId,
            ),
          );
          break;
        case PrinterType.network:
          connected = await printerManager.connect(
            type: PrinterType.network,
            model: TcpPrinterInput(ipAddress: printer.address!),
          );
          break;
        case PrinterType.bluetooth:
          connected = await printerManager.connect(
            type: PrinterType.bluetooth,
            model: BluetoothPrinterInput(
              name: printer.deviceName,
              address: printer.address!,
              isBle: printer.isBle ?? false,
              autoConnect: _reconnect,
            ),
          );
          break;
        default:
          return false;
      }

      if (connected) {
        print('Connected to: ${printer.deviceName}, sending data...');
        await printerManager.send(type: printer.typePrinter, bytes: bytes);
        await printerManager.disconnect(type: printer.typePrinter);
        print('Successfully printed to: ${printer.deviceName}');
        return true;
      } else {
        print('Failed to connect to: ${printer.deviceName}');
        return false;
      }
    } catch (e) {
      print('Error printing to ${printer.deviceName}: $e');
      try {
        await printerManager.disconnect(type: printer.typePrinter);
      } catch (_) {}
      return false;
    }
  }

  Future<void> _printToMultiplePrinters(List<int> bytes) async {
    if (_selectedPrinters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one printer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final profile = await CapabilityProfile.load(name: 'XP-N160I');
      final generator = Generator(PaperSize.mm58, profile);

      List<int> fullBytes = List.from(bytes);
      fullBytes += generator.feed(2);
      fullBytes += generator.cut();

      int successCount = 0;
      for (final printer in _selectedPrinters) {
        final success = await _printToSinglePrinter(printer, fullBytes);
        if (success) {
          successCount++;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) {
        Navigator.of(context).pop();

        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Printed to $successCount of ${_selectedPrinters.length} printer(s)',
              ),
              backgroundColor: successCount == _selectedPrinters.length
                  ? Colors.green
                  : Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to print to all selected printers. Please check connections.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  void _scan() {
    devices.clear();

    _subscription = printerManager
        .discovery(type: defaultPrinterType, isBle: _isBle)
        .listen((device) {
      if (kDebugMode) {
        print("device found: ${device.name}, address: ${device.address}");
      }

      if (device.name == null || device.name!.isEmpty) return;

      if (defaultPrinterType == PrinterType.usb) {
        if (!Platform.isWindows) {
          if (device.vendorId == null || device.productId == null) {
            return;
          }
        }

        final name = device.name!.toLowerCase();
        if (!name.contains('printer') &&
            !name.contains('xp') &&
            !name.contains('thermal') &&
            !name.contains('rocket') &&
            !name.contains('pos') &&
            !name.contains('80mm') &&
            !name.contains('58mm')) {
          return;
        }
      }

      if (defaultPrinterType != PrinterType.usb) {
        if (device.address == null || device.address!.isEmpty) {
          return;
        }
      }

      try {
        devices.add(
          BluetoothPrinter(
            deviceName: device.name ?? "Unknown Printer",
            address: device.address ?? "",
            vendorId: device.vendorId,
            productId: device.productId,
            isBle: _isBle,
            typePrinter: defaultPrinterType,
          ),
        );

        if (mounted) setState(() {});
      } catch (e) {
        if (kDebugMode) {
          print("Printer discovery error (ignored): $e");
        }
      }
    });
  }

  Future<void> setPort(String value) async {
    if (value.isEmpty) value = '9100';
    _port = value;
    var device = BluetoothPrinter(
      deviceName: value,
      address: _ipAddress,
      port: _port,
      typePrinter: PrinterType.network,
      state: false,
    );
    await _printerSettings.selectDevice(device);
    if (mounted) {
      setState(() {
        selectedPrinter = device;
      });
    }
  }

  Future<void> setIpAddress(String value) async {
    _ipAddress = value;
    var device = BluetoothPrinter(
      deviceName: value,
      address: _ipAddress,
      port: _port,
      typePrinter: PrinterType.network,
      state: false,
    );
    await _printerSettings.selectDevice(device);
    if (mounted) {
      setState(() {
        selectedPrinter = device;
      });
    }
  }

  Future _printReceiveTest() async {
    if (_isPrinting) return;

    final printerData = await PrinterDBHelper().getPrinterFromDB();

    String header = "";
    String footer = "";

    if (printerData.isNotEmpty) {
      header = printerData.first['receiptHeaderText'] ?? "";
      footer = printerData.first['receiptFooterText'] ?? "";
    }

    List<int> bytes = [];

    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm58, profile);

    bytes += generator.setGlobalCodeTable('CP1252');

    if (header.isNotEmpty) {
      bytes += generator.text(
        header,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.hr();
    }

    bytes += generator.text(
      'Product 1 - some description of the product needed here',
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.text(
      'Product 2 - some description of the product needed here',
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        width: 7,
        text: 'Lemon lime export quality per pound x 5 units',
      ),
      PosColumn(
        width: 3,
        text: 'USD 2.00',
        styles: const PosStyles(align: PosAlign.right),
      ),
      PosColumn(
        width: 2,
        text: 'Desc',
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row([
      PosColumn(text: "x3", width: 1),
      PosColumn(text: "Shan Haleem Masala Mix", width: 7),
      PosColumn(text: "135.0", width: 2),
      PosColumn(text: "420.0", width: 2),
    ]);

    try {
      final ByteData data = await rootBundle.load('assets/printer.png');
      final Uint8List imageBytes = data.buffer.asUint8List();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage != null) {
        bytes += generator.feed(1);
        bytes += generator.imageRaster(
          img.grayscale(decodedImage),
          align: PosAlign.center,
        );
        bytes += generator.feed(1);
      }
    } catch (e) {
      print("Image load error (ignored): $e");
    }

    bytes += generator.hr();

    if (footer.isNotEmpty) {
      bytes += generator.text(
        footer,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    await _printToMultiplePrinters(bytes);
  }

  Future<void> printBill({
    required String orderId,
    required String tableName,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required double grandTotal,
  }) async {
    if (_isPrinting) return;

    final prefs = await SharedPreferences.getInstance();

    final restaurantName = prefs.getString('store_name') ?? 'Restaurant';
    final address = prefs.getString('store_address') ?? '';
    final phone = prefs.getString('store_phone') ?? '';
    final gstNumber = prefs.getString('store_gst') ?? '';

    List<int> bytes = [];

    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    final generator = Generator(PaperSize.mm58, profile);

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

    bytes += generator.row([
      PosColumn(
        width: 6,
        text:
        "Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      ),
      PosColumn(
        width: 6,
        text: "Table: $tableName",
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row([
      PosColumn(width: 6, text: "Cashier: $cashierName"),
      PosColumn(
        width: 6,
        text: "Order: $orderId",
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr();

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

    for (final item in items) {
      final qty = (item['qty'] ?? 0).toString();
      final price = (item['price'] ?? 0).toString();
      final amount = (item['amount'] ?? 0).toString();

      bytes += generator.row([
        PosColumn(width: 6, text: item['name'] ?? ''),
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
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        width: 8,
        text: "TOTAL",
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
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

    await _printToMultiplePrinters(bytes);
  }

  void _printEscPos(List<int> bytes, Generator generator) async {
    if (_isPrinting) return;

    if (defaultPrinterType == PrinterType.network &&
        _selectedPrinters.isNotEmpty) {
      await _printToMultiplePrinters(bytes);
      return;
    }

    var connectedTCP = false;
    if (selectedPrinter == null) return;
    var bluetoothPrinter = selectedPrinter!;

    switch (bluetoothPrinter.typePrinter) {
      case PrinterType.usb:
        bytes += generator.feed(2);
        bytes += generator.cut();
        await printerManager.connect(
          type: bluetoothPrinter.typePrinter,
          model: UsbPrinterInput(
            name: bluetoothPrinter.deviceName,
            productId: bluetoothPrinter.productId,
            vendorId: bluetoothPrinter.vendorId,
          ),
        );
        pendingTask = null;
        break;
      case PrinterType.bluetooth:
        bytes += generator.cut();
        await printerManager.connect(
          type: bluetoothPrinter.typePrinter,
          model: BluetoothPrinterInput(
            name: bluetoothPrinter.deviceName,
            address: bluetoothPrinter.address!,
            isBle: bluetoothPrinter.isBle ?? false,
            autoConnect: _reconnect,
          ),
        );
        pendingTask = null;
        if (Platform.isAndroid) pendingTask = bytes;
        break;
      case PrinterType.network:
        bytes += generator.feed(2);
        bytes += generator.cut();
        connectedTCP = await printerManager.connect(
          type: bluetoothPrinter.typePrinter,
          model: TcpPrinterInput(ipAddress: bluetoothPrinter.address!),
        );
        if (!connectedTCP) print(' --- please review your connection ---');
        break;
      default:
    }
    if (bluetoothPrinter.typePrinter == PrinterType.bluetooth &&
        Platform.isAndroid) {
      if (_currentStatus == BTStatus.connected) {
        printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
        pendingTask = null;
      }
    } else {
      printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
    }
  }

  Future<void> _testNetworkConnection(String ipAddress) async {
    try {
      final connected = await printerManager.connect(
        type: PrinterType.network,
        model: TcpPrinterInput(ipAddress: ipAddress),
      );

      if (connected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully connected to $ipAddress'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await printerManager.disconnect(type: PrinterType.network);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to connect to $ipAddress'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing connection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== NEW UI (matches screenshot exactly) ====================

  // ==================== NEW UI (matches screenshot + WiFi support) ====================

  @override
  Widget build(BuildContext context) {
    final connected = <BluetoothPrinter>[];
    final available = <BluetoothPrinter>[];

    if (defaultPrinterType == PrinterType.network) {
      final known = <String, BluetoothPrinter>{};
      for (final p in _networkPrinters) {
        known[p.ipAddress] = BluetoothPrinter(
          deviceName: p.name,
          address: p.ipAddress,
          port: p.port,
          typePrinter: PrinterType.network,
        );
      }
      for (final d in _networkDevices) {
        known.putIfAbsent(
          d.address ?? '',
              () => BluetoothPrinter(
            deviceName: d.deviceName,
            address: d.address,
            port: '9100',
            typePrinter: PrinterType.network,
          ),
        );
      }
      for (final p in known.values) {
        if (_isPrinterSelected(p)) {
          connected.add(p);
        } else {
          available.add(p);
        }
      }
    } else {
      for (final d in devices) {
        if (_isPrinterSelected(d)) {
          connected.add(d);
        } else {
          available.add(d);
        }
      }
    }

    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Printer Connection',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              defaultPrinterType == PrinterType.network
                  ? (_isScanningNetwork ? Icons.stop : Icons.refresh)
                  : Icons.refresh,
            ),
            tooltip: 'Scan for printers',
            onPressed: () {
              if (defaultPrinterType == PrinterType.network) {
                if (!_isScanningNetwork) _scanNetworkPrinters();
              } else {
                _scan();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Type Selector (Bluetooth / USB / WiFi) =====
                  _buildTypeSelector(),
                  const SizedBox(height: 22),

                  // CONNECTED PRINTER
                  _buildSectionLabel('CONNECTED PRINTER'),
                  const SizedBox(height: 10),
                  if (connected.isEmpty)
                    _emptyHint('No printer connected yet')
                  else
                    ...List.generate(
                      connected.length,
                          (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPrinterCard(connected[i], i, true),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // AVAILABLE PRINTERS
                  _buildSectionLabel('AVAILABLE PRINTERS'),
                  const SizedBox(height: 10),
                  if (available.isEmpty)
                    _emptyHint(
                      defaultPrinterType == PrinterType.network
                          ? 'Tap refresh to scan, or add a printer manually'
                          : 'Tap refresh to scan for devices',
                    )
                  else
                    ...List.generate(
                      available.length,
                          (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPrinterCard(
                          available[i],
                          connected.length + i,
                          false,
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // + Add Printer button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isScanningNetwork ? null : _openAddPrinterSheet,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _addOrange,
                        side: const BorderSide(color: _addOrange, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 22),
                      label: const Text(
                        'Add Printer',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    Widget chip(String label, PrinterType type, bool visible) {
      if (!visible) return const SizedBox.shrink();
      final selected = defaultPrinterType == type;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) {
            if (mounted) {
              setState(() {
                defaultPrinterType = type;
                selectedPrinter = null;
                _isBle = false;
                _isConnected = false;
                _networkDevices.clear();
                devices.clear();
                _scan();
                if (type == PrinterType.network) {
                  _scanNetworkPrinters();
                }
              });
            }
          },
          selectedColor: _connectBlue,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? _connectBlue : Colors.grey.shade300,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Bluetooth', PrinterType.bluetooth, Platform.isAndroid || Platform.isIOS),
          chip('USB', PrinterType.usb, Platform.isAndroid || Platform.isWindows),
          chip('WiFi', PrinterType.network, true),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
      ),
    );
  }

  Widget _buildPrinterCard(BluetoothPrinter printer, int colorIndex, bool isConnected) {
    final bg = _iconBg[colorIndex % _iconBg.length];
    final fg = _iconFg[colorIndex % _iconFg.length];

    // Model name (for visual match with screenshot)
    final modelName = printer.typePrinter == PrinterType.network
        ? (printer.deviceName?.contains('Epson') == true
        ? printer.deviceName!
        : 'Epson TM-T88VI')
        : (printer.typePrinter == PrinterType.usb ? 'USB Printer' : 'Bluetooth Printer');

    final ipText = printer.typePrinter == PrinterType.network
        ? (printer.address ?? '')
        : (printer.address != null && printer.address!.isNotEmpty
        ? printer.address!
        : (printer.typePrinter == PrinterType.usb ? 'USB Device' : 'Bluetooth Device'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnected ? _connectedGreen.withOpacity(0.35) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colored circle icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(Icons.print_rounded, color: fg, size: 24),
          ),
          const SizedBox(width: 14),

          // Name + model + IP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        printer.deviceName ?? 'Unknown Printer',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _connectedGreenBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Connected',
                          style: TextStyle(
                            color: _connectedGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  modelName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.wifi, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      ipText,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right side action
          if (isConnected)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 22),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (value) {
                if (value == 'disconnect') {
                  _handleConnectPrinter(printer);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'disconnect',
                  child: Row(
                    children: [
                      Icon(Icons.link_off, size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Disconnect'),
                    ],
                  ),
                ),
              ],
            )
          else
            OutlinedButton(
              onPressed: () => _handleConnectPrinter(printer),
              style: OutlinedButton.styleFrom(
                foregroundColor: _connectBlue,
                side: const BorderSide(color: _connectBlue, width: 1.3),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Connect',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
        ],
      ),
    );
  }

  void _openAddPrinterSheet() {
    if (defaultPrinterType != PrinterType.network) {
      // For bluetooth/usb, adding = re-scanning for nearby devices.
      _scan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning for nearby devices...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Network Printer',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: InputDecoration(
                  labelText: 'IP Address',
                  prefixIcon: const Icon(Icons.wifi),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: setIpAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: InputDecoration(
                  labelText: 'Port',
                  prefixIcon: const Icon(Icons.numbers_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: setPort,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _addOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _addNetworkPrinter();
                    Navigator.pop(context);
                  },
                  child: const Text('Add Printer', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Network Printer Configuration Model
class NetworkPrinterConfig {
  final String ipAddress;
  final String port;
  final String name;

  NetworkPrinterConfig({
    required this.ipAddress,
    required this.port,
    required this.name,
  });
}