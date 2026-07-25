import 'dart:async';
import 'dart:convert';

import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pinaka_restaurant_pos/printer/printer_db_helper.dart';
import 'package:pinaka_restaurant_pos/printer/printer_settings.dart';
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
  // Printer Type [bluetooth, usb, network]
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

  // Store multiple printers
  List<NetworkPrinterConfig> _networkPrinters = [];
  List<BluetoothPrinter> _selectedPrinters = [];
  bool _isPrinting = false;

  // NEW: Network devices discovered via scanning
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

  // NEW: Scan for network printers on the local network
  void _scanNetworkPrinters() async {
    if (_isScanningNetwork) return;

    setState(() {
      _isScanningNetwork = true;
      _networkDevices.clear();
    });

    try {
      // Use PrinterManager to discover network printers
      // First, try to discover via broadcast
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

        // Check if device is already in the list
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

      // Wait for discovery to complete (5 seconds)
      await Future.delayed(const Duration(seconds: 5));
      await subscription.cancel();

      // If no devices found, add some common network printer IPs as suggestions
      if (_networkDevices.isEmpty) {
        // Add some common network printer addresses as suggestions
        final commonPrinters = [
          '192.168.1.100',
          '192.168.1.101',
          '192.168.0.100',
          '192.168.0.101',
          '10.0.0.100',
          '10.0.0.101',
        ];

        for (final ip in commonPrinters) {
          // Try to ping or check if printer exists (optional)
          // For now, just add as discovered
          setState(() {
            _networkDevices.add(
              BluetoothPrinter(
                deviceName: 'Printer at $ip',
                address: ip,
                vendorId: null,
                productId: null,
                isBle: false,
                typePrinter: PrinterType.network,
              ),
            );
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Network scan error: $e");
      }
      // Show error message
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

  // NEW: Get printer name based on index
  String _getPrinterName(int index, String defaultName) {
    if (index == 0) {
      return "KOT Printer";
    } else if (index == 1) {
      return "Cash Printer";
    } else {
      return "Printer ${index + 1}";
    }
  }

  // Save multiple network printers using JSON
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
          'name': p.name, // Keep the custom name if set
          'index': index.toString(),
        };
      }).toList();
      await prefs.setString('network_printers', jsonEncode(printerList));
    } catch (e) {
      print('Error saving network printers: $e');
    }
  }

  // Load saved network printers using JSON
  Future<void> _loadNetworkPrinters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('network_printers');
      if (saved != null && saved.isNotEmpty) {
        final List<dynamic> list = jsonDecode(saved);
        setState(() {
          _networkPrinters =
              list.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                // Use saved name if exists, otherwise generate based on index
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

  // Add network printer
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

  // NEW: Add discovered network printer to saved list
  void _addDiscoveredNetworkPrinter(BluetoothPrinter printer) {
    // Check if already added
    final exists = _networkPrinters.any((p) => p.ipAddress == printer.address);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer already added to list'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final index = _networkPrinters.length;
    final name = _getPrinterName(
      index,
      printer.deviceName ?? 'Unknown Printer',
    );

    setState(() {
      _networkPrinters.add(
        NetworkPrinterConfig(
          ipAddress: printer.address ?? '',
          port: '9100',
          name: name,
        ),
      );
      _saveNetworkPrinters();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${printer.deviceName} to printer list'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Remove network printer
  void _removeNetworkPrinter(int index) {
    setState(() {
      final printer = _networkPrinters[index];
      _networkPrinters.removeAt(index);
      // Also remove from selected list if present
      _selectedPrinters.removeWhere((p) => p.address == printer.ipAddress);
      _saveNetworkPrinters();
    });
  }

  // Toggle printer selection
  void _togglePrinterSelection(BluetoothPrinter printer) {
    setState(() {
      final index = _selectedPrinters.indexWhere(
            (p) => p.address == printer.address && p.port == printer.port,
      );
      if (index >= 0) {
        _selectedPrinters.removeAt(index);
      } else {
        _selectedPrinters.add(printer);
      }
    });
  }

  // NEW: Print to single printer (supports ALL types: USB, Network, Bluetooth)
  Future<bool> _printToSinglePrinter(
      BluetoothPrinter printer,
      List<int> bytes,
      ) async {
    try {
      print(
        'Attempting to connect to: ${printer.deviceName} (${printer.typePrinter})',
      );

      bool connected = false;

      // Connect based on printer type
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
        // Send data
        await printerManager.send(type: printer.typePrinter, bytes: bytes);
        // Disconnect
        await printerManager.disconnect(type: printer.typePrinter);
        print('Successfully printed to: ${printer.deviceName}');
        return true;
      } else {
        print('Failed to connect to: ${printer.deviceName}');
        return false;
      }
    } catch (e) {
      print('Error printing to ${printer.deviceName}: $e');
      // Try to disconnect if still connected
      try {
        await printerManager.disconnect(type: printer.typePrinter);
      } catch (_) {}
      return false;
    }
  }

  // FIXED: Print to multiple printers with sequential connection (supports ALL types)
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

    // Show loading indicator
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

      // Print to each selected printer SEQUENTIALLY
      int successCount = 0;
      for (final printer in _selectedPrinters) {
        final success = await _printToSinglePrinter(printer, fullBytes);
        if (success) {
          successCount++;
        }
        // Add small delay between printers to avoid conflicts
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Close dialog
      if (mounted) {
        Navigator.of(context).pop();

        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Printed to $successCount of ${_selectedPrinters.length} printer(s)',
              ),
              backgroundColor:
              successCount == _selectedPrinters.length
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

    // Try to load image, but don't fail if it doesn't exist
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a device to connect'),
        actions: [
          if (defaultPrinterType == PrinterType.network)
            IconButton(
              icon: Icon(_isScanningNetwork ? Icons.stop : Icons.refresh),
              onPressed: _isScanningNetwork ? null : _scanNetworkPrinters,
              tooltip: 'Scan for Network Printers',
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            height: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                            selectedPrinter == null || _isConnected
                                ? null
                                : () async {
                              try {
                                _isConnected =
                                await _printerSettings
                                    .connectDevice();
                                if (!_isConnected && mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
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

                                if (selectedPrinter != null &&
                                    mounted) {
                                  try {
                                    final printerDb = PrinterDBHelper();
                                    final existing =
                                    await printerDb
                                        .getPrinterFromDB();
                                    if (existing.isEmpty) {
                                      await printerDb.addPrinterToDB(
                                        selectedPrinter!,
                                      );
                                    } else {
                                      await printerDb.updatePrinterToDB(
                                        selectedPrinter!,
                                      );
                                    }
                                  } catch (dbError) {
                                    print(
                                      "DB save error (non-fatal): $dbError",
                                    );
                                  }
                                }

                                if (mounted) {
                                  setState(() {});
                                }
                              } catch (e, s) {
                                print("Exception: $e, Stack: $s");
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Error connecting to printer.",
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "Connect",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                            selectedPrinter == null || !_isConnected
                                ? null
                                : () {
                              if (selectedPrinter != null) {
                                printerManager.disconnect(
                                  type: selectedPrinter!.typePrinter,
                                );
                              }
                              if (mounted) {
                                setState(() {
                                  _isConnected = false;
                                });
                              }
                            },
                            child: const Text(
                              "Disconnect",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownButtonFormField<PrinterType>(
                    value: defaultPrinterType,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.print, size: 24),
                      labelText: "Type Printer Device",
                      labelStyle: TextStyle(fontSize: 18.0),
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                    items: <DropdownMenuItem<PrinterType>>[
                      if (Platform.isAndroid || Platform.isIOS)
                        const DropdownMenuItem(
                          value: PrinterType.bluetooth,
                          child: Text("Bluetooth"),
                        ),
                      if (Platform.isAndroid || Platform.isWindows)
                        const DropdownMenuItem(
                          value: PrinterType.usb,
                          child: Text("USB"),
                        ),
                      const DropdownMenuItem(
                        value: PrinterType.network,
                        child: Text("WiFi"),
                      ),
                    ],
                    onChanged: (PrinterType? value) {
                      if (value != null && mounted) {
                        setState(() {
                          defaultPrinterType = value;
                          selectedPrinter = null;
                          _isBle = false;
                          _isConnected = false;
                          _networkDevices.clear();
                          _scan();
                        });
                      }
                    },
                  ),

                  // Network printers management section
                  Visibility(
                    visible: defaultPrinterType == PrinterType.network,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Network Printers Management',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // NEW: Show discovered network printers
                        if (_networkDevices.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: Text(
                              'Discovered Printers:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          ..._networkDevices
                              .map(
                                (device) => ListTile(
                              title: Text(
                                device.deviceName ?? 'Unknown Printer',
                              ),
                              subtitle: Text(device.address ?? 'No IP'),
                              leading: const Icon(
                                Icons.wifi,
                                color: Colors.blue,
                              ),
                              trailing: ElevatedButton(
                                onPressed:
                                    () => _addDiscoveredNetworkPrinter(
                                  device,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Add'),
                              ),
                              onTap: () {
                                // Option to test connection
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Testing connection to ${device.address}...',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                // Test connection
                                _testNetworkConnection(
                                  device.address ?? '',
                                );
                              },
                            ),
                          )
                              .toList(),
                          const Divider(),
                        ],

                        // Manual entry section
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _ipController,
                                  keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                  ),
                                  decoration: const InputDecoration(
                                    label: Text("IP Address"),
                                    prefixIcon: Icon(Icons.wifi, size: 24),
                                  ),
                                  onChanged: setIpAddress,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _portController,
                                  keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                  ),
                                  decoration: const InputDecoration(
                                    label: Text("Port"),
                                    prefixIcon: Icon(
                                      Icons.numbers_outlined,
                                      size: 24,
                                    ),
                                  ),
                                  onChanged: setPort,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                                onPressed: _addNetworkPrinter,
                                tooltip: 'Add printer manually',
                              ),
                            ],
                          ),
                        ),

                        // Saved printers list
                        if (_networkPrinters.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: Text(
                              'Saved Printers:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          ..._networkPrinters.asMap().entries.map((entry) {
                            final index = entry.key;
                            final printer = entry.value;
                            final isSelected = _selectedPrinters.any(
                                  (p) =>
                              p.address == printer.ipAddress &&
                                  p.port == printer.port,
                            );

                            // Show printer type badge
                            String badgeText = '';
                            Color badgeColor = Colors.grey;
                            if (index == 0) {
                              badgeText = 'KOT';
                              badgeColor = Colors.blue;
                            } else if (index == 1) {
                              badgeText = 'Cash';
                              badgeColor = Colors.green;
                            }

                            return ListTile(
                              title: Row(
                                children: [
                                  Text(printer.name),
                                  if (badgeText.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                '${printer.ipAddress}:${printer.port}',
                              ),
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  final bluetoothPrinter = BluetoothPrinter(
                                    deviceName: printer.name,
                                    address: printer.ipAddress,
                                    port: printer.port,
                                    typePrinter: PrinterType.network,
                                    state: false,
                                  );
                                  _togglePrinterSelection(bluetoothPrinter);
                                },
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeNetworkPrinter(index),
                              ),
                            );
                          }).toList(),
                        ],

                        if (_selectedPrinters.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Selected: ${_selectedPrinters.length} printer(s)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed:
                            _selectedPrinters.isEmpty || _isPrinting
                                ? null
                                : _printReceiveTest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: Text(
                              _isPrinting
                                  ? 'Printing...'
                                  : 'Print Test to Selected Printers',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Bluetooth/USB devices list
                  if (defaultPrinterType != PrinterType.network)
                    Column(
                      children:
                      devices
                          .map(
                            (device) => ListTile(
                          title: Text(device.deviceName!),
                          subtitle:
                          (defaultPrinterType == PrinterType.usb ||
                              Platform.isWindows)
                              ? null
                              : Visibility(
                            visible:
                            device.address != null &&
                                device.address!.isNotEmpty,
                            child: Text(device.address ?? ''),
                          ),
                          onTap: () async {
                            await _printerSettings.selectDevice(device);
                            if (mounted) {
                              setState(() {
                                selectedPrinter = device;
                              });
                            }
                          },
                          leading:
                          selectedPrinter != null &&
                              ((device.typePrinter ==
                                  PrinterType.usb &&
                                  Platform.isWindows
                                  ? device.deviceName ==
                                  selectedPrinter!
                                      .deviceName
                                  : device.vendorId !=
                                  null &&
                                  selectedPrinter!
                                      .vendorId ==
                                      device
                                          .vendorId) ||
                                  (device.address != null &&
                                      selectedPrinter!
                                          .address ==
                                          device.address))
                              ? const Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                              : null,
                          //Raghu
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Add checkbox for USB printers to select them for multi-printing
                              if (defaultPrinterType == PrinterType.usb)
                                Checkbox(
                                  value: _selectedPrinters.any(
                                        (p) =>
                                    p.deviceName ==
                                        device.deviceName &&
                                        p.vendorId == device.vendorId &&
                                        p.productId ==
                                            device.productId &&
                                        p.typePrinter ==
                                            PrinterType.usb,
                                  ),
                                  onChanged: (bool? value) async {
                                    if (value == true) {
                                      // Add printer to selection (existing behavior, unchanged)
                                      final printerToAdd =
                                      BluetoothPrinter(
                                        deviceName:
                                        device.deviceName,
                                        address: device.address,
                                        vendorId: device.vendorId,
                                        productId: device.productId,
                                        isBle: device.isBle,
                                        typePrinter:
                                        PrinterType.usb,
                                        state: device.state,
                                      );
                                      setState(() {
                                        final exists = _selectedPrinters
                                            .any(
                                              (p) =>
                                          p.deviceName ==
                                              printerToAdd
                                                  .deviceName &&
                                              p.vendorId ==
                                                  printerToAdd
                                                      .vendorId &&
                                              p.productId ==
                                                  printerToAdd
                                                      .productId &&
                                              p.typePrinter ==
                                                  PrinterType.usb,
                                        );
                                        if (!exists) {
                                          _selectedPrinters.add(
                                            printerToAdd,
                                          );
                                        }
                                      });

                                      // NEW: persist to DB too — Windows USB fix.
                                      // Without this, TopBar's real bill print
                                      // (which reads only from the DB) never
                                      // sees USB printers checked here, even
                                      // though the on-screen test print works
                                      // fine off the in-memory list.
                                      try {
                                        final printerDb =
                                        PrinterDBHelper();
                                        await printerDb.addPrinterToDB(
                                          printerToAdd,
                                        );
                                        await printerDb
                                            .updatePrinterSelection(
                                          device.address ?? '',
                                          true,
                                          deviceName:
                                          device.deviceName,
                                        );
                                      } catch (e) {
                                        print(
                                          'Error persisting USB printer selection: $e',
                                        );
                                      }
                                    } else {
                                      // Remove printer from selection (existing behavior, unchanged)
                                      setState(() {
                                        _selectedPrinters.removeWhere(
                                              (p) =>
                                          p.deviceName ==
                                              device.deviceName &&
                                              p.vendorId ==
                                                  device.vendorId &&
                                              p.productId ==
                                                  device.productId &&
                                              p.typePrinter ==
                                                  PrinterType.usb,
                                        );
                                      });

                                      // NEW: mirror the un-selection in the DB.
                                      try {
                                        await PrinterDBHelper()
                                            .updatePrinterSelection(
                                          device.address ?? '',
                                          false,
                                          deviceName:
                                          device.deviceName,
                                        );
                                      } catch (e) {
                                        print(
                                          'Error un-persisting USB printer selection: $e',
                                        );
                                      }
                                    }
                                  },
                                ),
                              OutlinedButton(
                                onPressed:
                                selectedPrinter == null ||
                                    device.deviceName !=
                                        selectedPrinter
                                            ?.deviceName ||
                                    _isPrinting
                                    ? null
                                    : _printReceiveTest,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 2,
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    "Print test ticket",
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  // Show selected printers count for USB/Bluetooth
                  // Show selected printers count for USB/Bluetooth
                  if (defaultPrinterType != PrinterType.network &&
                      _selectedPrinters.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Selected: ${_selectedPrinters.length} printer(s)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  // Show multi-print button for USB/Bluetooth
                  if (defaultPrinterType != PrinterType.network &&
                      _selectedPrinters.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed:
                        _selectedPrinters.isEmpty || _isPrinting
                            ? null
                            : _printReceiveTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          _isPrinting
                              ? 'Printing...'
                              : 'Print Test to Selected Printers',
                        ),
                      ),
                    ),
                  // Visibility(
                  //   visible:
                  //       defaultPrinterType == PrinterType.network &&
                  //       Platform.isWindows,
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(top: 10.0),
                  //     child: OutlinedButton(
                  //       onPressed:
                  //           _isPrinting
                  //               ? null
                  //               : () async {
                  //                 if (_ipController.text.isNotEmpty) {
                  //                   setIpAddress(_ipController.text);
                  //                 }
                  //                 await _printReceiveTest();
                  //               },
                  //       child: const Padding(
                  //         padding: EdgeInsets.symmetric(
                  //           vertical: 4,
                  //           horizontal: 50,
                  //         ),
                  //         child: Text(
                  //           "Print test ticket",
                  //           textAlign: TextAlign.center,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Test network connection to a printer
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
