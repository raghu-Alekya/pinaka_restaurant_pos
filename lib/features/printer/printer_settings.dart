//
// import 'dart:async';
// import 'dart:io';
// import 'package:enum_to_string/enum_to_string.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:restaurant_captain_app/features/printer/printer_db_helper.dart';
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
//   // ---- NEW: expose current status so UI can show "connected / disconnected" ----
//   BTStatus get currentStatus => _currentStatus;
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
//
//     // FIXED: use the real address column, fall back to the old
//     // (buggy) productId-based value only for backward compatibility.
//     printer.address =
//         printerDB.first[AppDBConst.printerAddress] ??
//         printerDB.first[AppDBConst.printerProductId] ??
//         "";
//
//     printer.typePrinter =
//         EnumToString.fromString(
//           PrinterType.values,
//           printerDB.first[AppDBConst.printerType],
//         ) ??
//         PrinterType.usb;
//     printer.isBle = false;
//     _currentStatus =
//         (((printer.typePrinter == PrinterType.bluetooth ||
//                         printer.typePrinter == PrinterType.network) &&
//                     printer.address != "") ||
//                 (printer.typePrinter == PrinterType.usb && Platform.isWindows))
//             ? BTStatus.connected
//             : BTStatus.none;
//     selectedPrinter = printer;
//   }
//
//   Future<void> selectDevice(BluetoothPrinter device) async {
//     if (selectedPrinter != null) {
//       if ((device.address != selectedPrinter!.address) ||
//           (device.typePrinter == PrinterType.usb &&
//               (Platform.isWindows
//                   ? selectedPrinter!.deviceName != device.deviceName
//                   : selectedPrinter!.vendorId != device.vendorId))) {
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
//         if (Platform.isWindows) {
//           // On Windows, spooler-based USB printers do not require or maintain a persistent hardware connection.
//           // They print directly to the printer queue by name, so we can treat connection as always successful.
//           _currentStatus = BTStatus.connected;
//           return true;
//         }
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
//     _currentStatus = BTStatus.connected;
//     return true;
//   }
//
//   Future<void> printTicket(List<int> bytes, Generator generator) async {
//     await loadPrinter();
//
//     if (selectedPrinter == null) {
//       debugPrint("No printer selected");
//       return;
//     }
//
//     final printer = selectedPrinter!;
//
//     // ---- FIX: original code connected + sent with no error handling at  ----
//     // ---- all, so any dropped connection (printer asleep, out of range,  ----
//     // ---- wifi hiccup) just failed silently with no retry. We now try    ----
//     // ---- once, and if it fails, disconnect + reconnect + retry once     ----
//     // ---- more before giving up. The connect/send calls themselves are   ----
//     // ---- untouched — same models, same parameters as before.            ----
//     Future<void> doConnectAndSend() async {
//       switch (printer.typePrinter) {
//         case PrinterType.usb:
//           await printerManager.connect(
//             type: printer.typePrinter,
//             model: UsbPrinterInput(
//               name: printer.deviceName,
//               productId: printer.productId,
//               vendorId: printer.vendorId,
//             ),
//           );
//           break;
//
//         case PrinterType.bluetooth:
//           await printerManager.connect(
//             type: printer.typePrinter,
//             model: BluetoothPrinterInput(
//               name: printer.deviceName,
//               address: printer.address ?? "",
//               isBle: printer.isBle ?? false,
//               autoConnect: false,
//             ),
//           );
//           break;
//
//         case PrinterType.network:
//           await printerManager.connect(
//             type: printer.typePrinter,
//             model: TcpPrinterInput(ipAddress: printer.address ?? ""),
//           );
//           break;
//       }
//
//       printerManager.send(type: printer.typePrinter, bytes: bytes);
//     }
//
//     try {
//       await doConnectAndSend();
//       _currentStatus = BTStatus.connected;
//       debugPrint("Receipt sent to printer: ${printer.deviceName}");
//     } catch (e) {
//       debugPrint("Print failed, connection may have dropped: $e. Retrying...");
//       _currentStatus = BTStatus.none;
//       try {
//         // Force a clean disconnect before retrying, in case the printer
//         // is holding a stale/half-open connection.
//         await printerManager.disconnect(type: printer.typePrinter);
//       } catch (_) {
//         // ignore disconnect errors, we're about to reconnect anyway
//       }
//
//       try {
//         await doConnectAndSend();
//         _currentStatus = BTStatus.connected;
//         debugPrint("Receipt sent to printer on retry: ${printer.deviceName}");
//       } catch (e2) {
//         _currentStatus = BTStatus.none;
//         debugPrint("Retry failed. Printer still unreachable: $e2");
//       }
//     }
//   }
//
//   // ---- NEW: connect a printer over WiFi/LAN by IP address. Reuses the  ----
//   // ---- existing selectDevice / connectDevice / saveSelectedPrinterToDB ----
//   // ---- functions above exactly as they are — no old logic changed.     ----
//   Future<bool> connectToWifiPrinter(
//     String ipAddress, {
//     String? deviceName,
//   }) async {
//     final ip = ipAddress.trim();
//
//     if (ip.isEmpty) {
//       debugPrint("WiFi printer IP address cannot be empty");
//       return false;
//     }
//
//     final ipRegex = RegExp(
//       r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
//       r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
//     );
//     if (!ipRegex.hasMatch(ip)) {
//       debugPrint("Invalid WiFi printer IP address: $ip");
//       return false;
//     }
//
//     final wifiPrinter = BluetoothPrinter(
//       deviceName: deviceName ?? "WiFi Printer ($ip)",
//       address: ip,
//       typePrinter: PrinterType.network,
//       isBle: false,
//     );
//
//     await selectDevice(wifiPrinter);
//
//     bool connected = false;
//     try {
//       connected = await connectDevice();
//     } catch (e) {
//       debugPrint("Failed to connect to WiFi printer at $ip: $e");
//       connected = false;
//     }
//
//     if (connected) {
//       await saveSelectedPrinterToDB();
//       _currentStatus = BTStatus.connected;
//     } else {
//       _currentStatus = BTStatus.none;
//     }
//
//     return connected;
//   }
//
//   // ---- NEW: quick check + reconnect helper you can call from the UI ----
//   // ---- (e.g. on a "Check connection" button or before opening the    ----
//   // ---- register) without touching any of the original methods.      ----
//   Future<bool> ensureConnected() async {
//     if (selectedPrinter == null) {
//       await loadPrinter();
//     }
//     if (selectedPrinter == null) return false;
//
//     try {
//       final ok = await connectDevice();
//       _currentStatus = ok ? BTStatus.connected : BTStatus.none;
//       return ok;
//     } catch (e) {
//       debugPrint("ensureConnected failed: $e");
//       _currentStatus = BTStatus.none;
//       return false;
//     }
//   }
// }
//
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
//   // NEW: dedicated address column (used for Bluetooth address AND WiFi/LAN IP).
//   // Added instead of reusing product_id, which was the source of the
//   // reconnect bug.
//   static const String printerAddress = 'printer_address';
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
import 'dart:convert';
import 'dart:io';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_captain_app/features/printer/printer_db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // ==================== FIXED: load ALL selected printers ====================
  Future<List<BluetoothPrinter>> getSelectedPrinters() async {
    final printers = <BluetoothPrinter>[];

    // 1. From DB (proper selected ones)
    final dbPrinters = await _printerDBHelper.getAllPrintersFromDB();
    for (final row in dbPrinters) {
      final isSelected = (row['is_selected'] ?? 1) == 1;
      if (!isSelected) continue;

      final printer = BluetoothPrinter(
        deviceName: row[AppDBConst.printerDeviceName],
        address: row[AppDBConst.printerAddress] ??
            row[AppDBConst.printerProductId] ??
            '',
        vendorId: row[AppDBConst.printerVendorId]?.toString(),
        productId: row[AppDBConst.printerProductId]?.toString(),
        typePrinter: EnumToString.fromString(
          PrinterType.values,
          row[AppDBConst.printerType],
        ) ??
            PrinterType.usb,
        isBle: false,
      );
      printers.add(printer);
    }

    // 2. Fallback – network printers stored in SharedPreferences
    if (printers.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('network_printers');
      if (saved != null && saved.isNotEmpty) {
        try {
          final list = jsonDecode(saved) as List;
          for (final item in list) {
            final ip = item['ip'] ?? '';
            if (ip.isEmpty) continue;
            printers.add(BluetoothPrinter(
              deviceName: item['name'] ?? 'Network Printer',
              address: ip,
              port: item['port'] ?? '9100',
              typePrinter: PrinterType.network,
            ));
          }
        } catch (_) {}
      }
    }

    // Keep the old single-printer field in sync
    selectedPrinter = printers.isNotEmpty ? printers.first : null;
    return printers;
  }

  Future<void> setSelectedPrinterFromDB() async {
    final printers = await getSelectedPrinters();
    selectedPrinter = printers.isNotEmpty ? printers.first : null;

    if (selectedPrinter != null) {
      _currentStatus = (((selectedPrinter!.typePrinter == PrinterType.bluetooth ||
          selectedPrinter!.typePrinter == PrinterType.network) &&
          selectedPrinter!.address != "") ||
          (selectedPrinter!.typePrinter == PrinterType.usb && Platform.isWindows))
          ? BTStatus.connected
          : BTStatus.none;
    } else {
      _currentStatus = BTStatus.none;
    }
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

  // ==================== FIXED printTicket (prints to ALL selected printers) ====================
  Future<void> printTicket(List<int> bytes, Generator generator) async {
    final printers = await getSelectedPrinters();

    if (printers.isEmpty) {
      debugPrint("No printer selected");
      return;
    }

    for (final printer in printers) {
      try {
        await _printToOnePrinter(printer, bytes);
        _currentStatus = BTStatus.connected;
        debugPrint("Receipt sent to printer: ${printer.deviceName}");
      } catch (e) {
        debugPrint("Print failed for ${printer.deviceName}: $e. Retrying...");
        _currentStatus = BTStatus.none;
        try {
          await printerManager.disconnect(type: printer.typePrinter);
        } catch (_) {}

        try {
          await Future.delayed(const Duration(milliseconds: 400));
          await _printToOnePrinter(printer, bytes);
          _currentStatus = BTStatus.connected;
          debugPrint("Receipt sent to printer on retry: ${printer.deviceName}");
        } catch (e2) {
          _currentStatus = BTStatus.none;
          debugPrint("Retry failed. Printer still unreachable: $e2");
        }
      }
    }
  }

  Future<void> _printToOnePrinter(BluetoothPrinter printer, List<int> bytes) async {
    switch (printer.typePrinter) {
      case PrinterType.usb:
        await printerManager.connect(
          type: PrinterType.usb,
          model: UsbPrinterInput(
            name: printer.deviceName,
            productId: printer.productId,
            vendorId: printer.vendorId,
          ),
        );
        break;
      case PrinterType.bluetooth:
        await printerManager.connect(
          type: PrinterType.bluetooth,
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
          type: PrinterType.network,
          model: TcpPrinterInput(ipAddress: printer.address ?? ""),
        );
        break;
    }

    printerManager.send(type: printer.typePrinter, bytes: bytes);
  }

  // ---- NEW: connect a printer over WiFi/LAN by IP address ----
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

// Keep the old constants & model exactly as they were
class AppDBConst {
  static const String printerTable = 'printer';
  static const String printerId = 'id';
  static const String printerDeviceName = 'device_name';
  static const String printerProductId = 'product_id';
  static const String printerVendorId = 'vendor_id';
  static const String printerType = 'printer_type';
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