// import 'dart:async';
// import 'dart:io';
// import 'package:enum_to_string/enum_to_string.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:pinaka_restaurant_pos/printer/printer_db_helper.dart';
// import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
// import 'package:thermal_printer/thermal_printer.dart';
//
// class PrinterSettings {
//   PrinterSettings() {
//     setSelectedPrinterFromDB();
//   }
//
//   var _reconnect = false;
//   BTStatus _currentStatus = BTStatus.none;
//
//   BluetoothPrinter? selectedPrinter;
//   var printerManager = PrinterManager.instance;
//   List<int>? pendingTask;
//   final PrinterDBHelper _printerDBHelper = PrinterDBHelper();
//
//   Future<void> loadPrinter() async {
//     await setSelectedPrinterFromDB();
//   }
//
//   Future<Generator> getTicket() async {
//     final profile = await CapabilityProfile.load(name: 'XP-N160I');
//     return Generator(PaperSize.mm80, profile);
//   }
//
//   Future<void> saveSelectedPrinterToDB() async {
//     if (selectedPrinter != null) {
//       await _printerDBHelper.addPrinterToDB(selectedPrinter!);
//     }
//   }
//
//   Future<void> setSelectedPrinterFromDB() async {
//     var printerDB = await _printerDBHelper.getPrinterFromDB();
//     if (printerDB.isEmpty) return;
//
//     BluetoothPrinter printer = BluetoothPrinter();
//     printer.deviceName = printerDB.first[AppDBConst.printerDeviceName];
//     printer.productId = printerDB.first[AppDBConst.printerProductId];
//     printer.vendorId = printerDB.first[AppDBConst.printerVendorId];
//     printer.address = printerDB.first[AppDBConst.printerProductId] ?? "";
//     printer.typePrinter = EnumToString.fromString(
//       PrinterType.values,
//       printerDB.first[AppDBConst.printerType],
//     ) ??
//         PrinterType.usb;
//     printer.isBle = false;
//     _currentStatus =
//     (printer.typePrinter == PrinterType.bluetooth && printer.address != "")
//         ? BTStatus.connected
//         : BTStatus.none;
//     selectedPrinter = printer;
//   }
//
//   Future<void> selectDevice(BluetoothPrinter device) async {
//     if (selectedPrinter != null) {
//       if ((device.address != selectedPrinter!.address) ||
//           (device.typePrinter == PrinterType.usb &&
//               selectedPrinter!.vendorId != device.vendorId)) {
//         await PrinterManager.instance.disconnect(
//           type: selectedPrinter!.typePrinter,
//         );
//       }
//     }
//
//     selectedPrinter = device;
//   }
//
//   Future<bool> connectDevice() async {
//     if (selectedPrinter == null) return false;
//     switch (selectedPrinter!.typePrinter) {
//       case PrinterType.usb:
//         await printerManager.connect(
//           type: selectedPrinter!.typePrinter,
//           model: UsbPrinterInput(
//             name: selectedPrinter!.deviceName,
//             productId: selectedPrinter!.productId,
//             vendorId: selectedPrinter!.vendorId,
//           ),
//         );
//         break;
//       case PrinterType.bluetooth:
//         await printerManager.connect(
//           type: selectedPrinter!.typePrinter,
//           model: BluetoothPrinterInput(
//             name: selectedPrinter!.deviceName,
//             address: selectedPrinter!.address!,
//             isBle: selectedPrinter!.isBle ?? false,
//             autoConnect: _reconnect,
//           ),
//         );
//         break;
//       case PrinterType.network:
//         await printerManager.connect(
//           type: selectedPrinter!.typePrinter,
//           model: TcpPrinterInput(ipAddress: selectedPrinter!.address!),
//         );
//         break;
//     }
//     return true;
//   }
//
//   Future<void> printTicket(
//       List<int> bytes,
//       Generator generator,
//       ) async {
//     await loadPrinter();
//
//     if (selectedPrinter == null) {
//       debugPrint("No printer selected");
//       return;
//     }
//
//     final printer = selectedPrinter!;
//
//     switch (printer.typePrinter) {
//       case PrinterType.usb:
//         await printerManager.connect(
//           type: printer.typePrinter,
//           model: UsbPrinterInput(
//             name: printer.deviceName,
//             productId: printer.productId,
//             vendorId: printer.vendorId,
//           ),
//         );
//         break;
//
//       case PrinterType.bluetooth:
//         await printerManager.connect(
//           type: printer.typePrinter,
//           model: BluetoothPrinterInput(
//             name: printer.deviceName,
//             address: printer.address ?? "",
//             isBle: printer.isBle ?? false,
//             autoConnect: false,
//           ),
//         );
//         break;
//
//       case PrinterType.network:
//         await printerManager.connect(
//           type: printer.typePrinter,
//           model: TcpPrinterInput(
//             ipAddress: printer.address ?? "",
//           ),
//         );
//         break;
//     }
//
//     printerManager.send(
//       type: printer.typePrinter,
//       bytes: bytes,
//     );
//
//     debugPrint(
//       "Receipt sent to printer: ${printer.deviceName}",
//     );
//   }
// }
// // lib/printer/app_db_const.dart
//
// class AppDBConst {
//   // Table
//   static const String printerTable = 'printer';
//
//   // Columns
//   static const String printerId = 'id';
//   static const String printerDeviceName = 'device_name';
//   static const String printerProductId = 'product_id';
//   static const String printerVendorId = 'vendor_id';
//   static const String printerType = 'printer_type';
//
//   static const String receiptIconPath = 'receipt_icon_path';
//   static const String receiptHeaderText = 'receipt_header_text';
//   static const String receiptFooterText = 'receipt_footer_text';
// }
//
// class BluetoothPrinter {
//   int? id;
//   String? deviceName;
//   String? address;
//   String? port;
//   String? vendorId;
//   String? productId;
//   bool? isBle;
//   String? receiptIconPath;
//   String? receiptHeaderText;
//   String? receiptFooterText;
//   PrinterType typePrinter;
//   bool? state;
//
//   BluetoothPrinter({
//     this.deviceName,
//     this.address,
//     this.port,
//     this.state,
//     this.vendorId,
//     this.productId,
//     this.typePrinter = PrinterType.usb,
//     this.isBle = false,
//     this.receiptIconPath,
//     this.receiptHeaderText,
//     this.receiptFooterText,
//   });
// }

import 'dart:async';
import 'dart:io';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/printer/printer_db_helper.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:thermal_printer/thermal_printer.dart';

class PrinterSettings {
  PrinterSettings() {
    setSelectedPrinterFromDB();
  }

  var _reconnect = false;
  BTStatus _currentStatus = BTStatus.none;

  BluetoothPrinter? selectedPrinter;
  var printerManager = PrinterManager.instance;
  List<int>? pendingTask;
  final PrinterDBHelper _printerDBHelper = PrinterDBHelper();

  // ---- NEW: expose current status so UI can show "connected / disconnected" ----
  BTStatus get currentStatus => _currentStatus;

  Future<void> loadPrinter() async {
    await setSelectedPrinterFromDB();
  }

  Future<Generator> getTicket() async {
    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    return Generator(PaperSize.mm80, profile);
  }

  Future<void> saveSelectedPrinterToDB() async {
    if (selectedPrinter != null) {
      await _printerDBHelper.addPrinterToDB(selectedPrinter!);
    }
  }

  // ---- FIX: address was being read from the wrong DB column (productId), ----
  // ---- which caused the saved printer to lose its real address/IP after ----
  // ---- app restart, so reconnecting later would fail. Now we read the   ----
  // ---- dedicated printerAddress column (with a safe fallback for any    ----
  // ---- old rows saved before this fix, so nothing old breaks).          ----
  Future<void> setSelectedPrinterFromDB() async {
    var printerDB = await _printerDBHelper.getPrinterFromDB();
    if (printerDB.isEmpty) return;

    BluetoothPrinter printer = BluetoothPrinter();
    printer.deviceName = printerDB.first[AppDBConst.printerDeviceName];
    printer.productId = printerDB.first[AppDBConst.printerProductId];
    printer.vendorId = printerDB.first[AppDBConst.printerVendorId];

    // FIXED: use the real address column, fall back to the old
    // (buggy) productId-based value only for backward compatibility.
    printer.address =
        printerDB.first[AppDBConst.printerAddress] ??
        printerDB.first[AppDBConst.printerProductId] ??
        "";

    printer.typePrinter =
        EnumToString.fromString(
          PrinterType.values,
          printerDB.first[AppDBConst.printerType],
        ) ??
        PrinterType.usb;
    printer.isBle = false;
    _currentStatus =
        (((printer.typePrinter == PrinterType.bluetooth ||
                        printer.typePrinter == PrinterType.network) &&
                    printer.address != "") ||
                (printer.typePrinter == PrinterType.usb && Platform.isWindows))
            ? BTStatus.connected
            : BTStatus.none;
    selectedPrinter = printer;
  }

  Future<void> selectDevice(BluetoothPrinter device) async {
    if (selectedPrinter != null) {
      if ((device.address != selectedPrinter!.address) ||
          (device.typePrinter == PrinterType.usb &&
              (Platform.isWindows
                  ? selectedPrinter!.deviceName != device.deviceName
                  : selectedPrinter!.vendorId != device.vendorId))) {
        await PrinterManager.instance.disconnect(
          type: selectedPrinter!.typePrinter,
        );
      }
    }

    selectedPrinter = device;
  }

  Future<bool> connectDevice() async {
    if (selectedPrinter == null) return false;
    switch (selectedPrinter!.typePrinter) {
      case PrinterType.usb:
        if (Platform.isWindows) {
          // On Windows, spooler-based USB printers do not require or maintain a persistent hardware connection.
          // They print directly to the printer queue by name, so we can treat connection as always successful.
          _currentStatus = BTStatus.connected;
          return true;
        }
        await printerManager.connect(
          type: selectedPrinter!.typePrinter,
          model: UsbPrinterInput(
            name: selectedPrinter!.deviceName,
            productId: selectedPrinter!.productId,
            vendorId: selectedPrinter!.vendorId,
          ),
        );
        break;
      case PrinterType.bluetooth:
        await printerManager.connect(
          type: selectedPrinter!.typePrinter,
          model: BluetoothPrinterInput(
            name: selectedPrinter!.deviceName,
            address: selectedPrinter!.address!,
            isBle: selectedPrinter!.isBle ?? false,
            autoConnect: _reconnect,
          ),
        );
        break;
      case PrinterType.network:
        await printerManager.connect(
          type: selectedPrinter!.typePrinter,
          model: TcpPrinterInput(ipAddress: selectedPrinter!.address!),
        );
        break;
    }
    _currentStatus = BTStatus.connected;
    return true;
  }

  Future<void> printTicket(List<int> bytes, Generator generator) async {
    await loadPrinter();

    if (selectedPrinter == null) {
      debugPrint("No printer selected");
      return;
    }

    final printer = selectedPrinter!;

    // ---- FIX: original code connected + sent with no error handling at  ----
    // ---- all, so any dropped connection (printer asleep, out of range,  ----
    // ---- wifi hiccup) just failed silently with no retry. We now try    ----
    // ---- once, and if it fails, disconnect + reconnect + retry once     ----
    // ---- more before giving up. The connect/send calls themselves are   ----
    // ---- untouched — same models, same parameters as before.            ----
    Future<void> doConnectAndSend() async {
      switch (printer.typePrinter) {
        case PrinterType.usb:
          await printerManager.connect(
            type: printer.typePrinter,
            model: UsbPrinterInput(
              name: printer.deviceName,
              productId: printer.productId,
              vendorId: printer.vendorId,
            ),
          );
          break;

        case PrinterType.bluetooth:
          await printerManager.connect(
            type: printer.typePrinter,
            model: BluetoothPrinterInput(
              name: printer.deviceName,
              address: printer.address ?? "",
              isBle: printer.isBle ?? false,
              autoConnect: false,
            ),
          );
          break;

        case PrinterType.network:
          await printerManager.connect(
            type: printer.typePrinter,
            model: TcpPrinterInput(ipAddress: printer.address ?? ""),
          );
          break;
      }

      printerManager.send(type: printer.typePrinter, bytes: bytes);
    }

    try {
      await doConnectAndSend();
      _currentStatus = BTStatus.connected;
      debugPrint("Receipt sent to printer: ${printer.deviceName}");
    } catch (e) {
      debugPrint("Print failed, connection may have dropped: $e. Retrying...");
      _currentStatus = BTStatus.none;
      try {
        // Force a clean disconnect before retrying, in case the printer
        // is holding a stale/half-open connection.
        await printerManager.disconnect(type: printer.typePrinter);
      } catch (_) {
        // ignore disconnect errors, we're about to reconnect anyway
      }

      try {
        await doConnectAndSend();
        _currentStatus = BTStatus.connected;
        debugPrint("Receipt sent to printer on retry: ${printer.deviceName}");
      } catch (e2) {
        _currentStatus = BTStatus.none;
        debugPrint("Retry failed. Printer still unreachable: $e2");
      }
    }
  }

  // ---- NEW: connect a printer over WiFi/LAN by IP address. Reuses the  ----
  // ---- existing selectDevice / connectDevice / saveSelectedPrinterToDB ----
  // ---- functions above exactly as they are — no old logic changed.     ----
  Future<bool> connectToWifiPrinter(
    String ipAddress, {
    String? deviceName,
  }) async {
    final ip = ipAddress.trim();

    if (ip.isEmpty) {
      debugPrint("WiFi printer IP address cannot be empty");
      return false;
    }

    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
      r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    if (!ipRegex.hasMatch(ip)) {
      debugPrint("Invalid WiFi printer IP address: $ip");
      return false;
    }

    final wifiPrinter = BluetoothPrinter(
      deviceName: deviceName ?? "WiFi Printer ($ip)",
      address: ip,
      typePrinter: PrinterType.network,
      isBle: false,
    );

    await selectDevice(wifiPrinter);

    bool connected = false;
    try {
      connected = await connectDevice();
    } catch (e) {
      debugPrint("Failed to connect to WiFi printer at $ip: $e");
      connected = false;
    }

    if (connected) {
      await saveSelectedPrinterToDB();
      _currentStatus = BTStatus.connected;
    } else {
      _currentStatus = BTStatus.none;
    }

    return connected;
  }

  // ---- NEW: quick check + reconnect helper you can call from the UI ----
  // ---- (e.g. on a "Check connection" button or before opening the    ----
  // ---- register) without touching any of the original methods.      ----
  Future<bool> ensureConnected() async {
    if (selectedPrinter == null) {
      await loadPrinter();
    }
    if (selectedPrinter == null) return false;

    try {
      final ok = await connectDevice();
      _currentStatus = ok ? BTStatus.connected : BTStatus.none;
      return ok;
    } catch (e) {
      debugPrint("ensureConnected failed: $e");
      _currentStatus = BTStatus.none;
      return false;
    }
  }
}

// lib/printer/app_db_const.dart

class AppDBConst {
  // Table
  static const String printerTable = 'printer';

  // Columns
  static const String printerId = 'id';
  static const String printerDeviceName = 'device_name';
  static const String printerProductId = 'product_id';
  static const String printerVendorId = 'vendor_id';
  static const String printerType = 'printer_type';

  // NEW: dedicated address column (used for Bluetooth address AND WiFi/LAN IP).
  // Added instead of reusing product_id, which was the source of the
  // reconnect bug.
  static const String printerAddress = 'printer_address';

  static const String receiptIconPath = 'receipt_icon_path';
  static const String receiptHeaderText = 'receipt_header_text';
  static const String receiptFooterText = 'receipt_footer_text';
}

class BluetoothPrinter {
  int? id;
  String? deviceName;
  String? address;
  String? port;
  String? vendorId;
  String? productId;
  bool? isBle;
  String? receiptIconPath;
  String? receiptHeaderText;
  String? receiptFooterText;
  PrinterType typePrinter;
  bool? state;

  BluetoothPrinter({
    this.deviceName,
    this.address,
    this.port,
    this.state,
    this.vendorId,
    this.productId,
    this.typePrinter = PrinterType.usb,
    this.isBle = false,
    this.receiptIconPath,
    this.receiptHeaderText,
    this.receiptFooterText,
  });
}
