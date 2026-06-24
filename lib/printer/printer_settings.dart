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

  Future<void> setSelectedPrinterFromDB() async {
    var printerDB = await _printerDBHelper.getPrinterFromDB();
    if (printerDB.isEmpty) return;

    BluetoothPrinter printer = BluetoothPrinter();
    printer.deviceName = printerDB.first[AppDBConst.printerDeviceName];
    printer.productId = printerDB.first[AppDBConst.printerProductId];
    printer.vendorId = printerDB.first[AppDBConst.printerVendorId];
    printer.address = printerDB.first[AppDBConst.printerProductId] ?? "";
    printer.typePrinter = EnumToString.fromString(
      PrinterType.values,
      printerDB.first[AppDBConst.printerType],
    ) ??
        PrinterType.usb;
    printer.isBle = false;
    _currentStatus =
    (printer.typePrinter == PrinterType.bluetooth && printer.address != "")
        ? BTStatus.connected
        : BTStatus.none;
    selectedPrinter = printer;
  }

  Future<void> selectDevice(BluetoothPrinter device) async {
    if (selectedPrinter != null) {
      if ((device.address != selectedPrinter!.address) ||
          (device.typePrinter == PrinterType.usb &&
              selectedPrinter!.vendorId != device.vendorId)) {
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
    return true;
  }

  Future<void> printTicket(
      List<int> bytes,
      Generator generator,
      ) async {
    await loadPrinter();

    if (selectedPrinter == null) {
      debugPrint("No printer selected");
      return;
    }

    final printer = selectedPrinter!;

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
          model: TcpPrinterInput(
            ipAddress: printer.address ?? "",
          ),
        );
        break;
    }

    printerManager.send(
      type: printer.typePrinter,
      bytes: bytes,
    );

    debugPrint(
      "Receipt sent to printer: ${printer.deviceName}",
    );
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
