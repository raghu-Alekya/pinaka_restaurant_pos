import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:pinaka_restaurant_pos/printer/printer_settings.dart';
import '../local database/db_init.dart';



class PrinterDBHelper {
  static final PrinterDBHelper _instance = PrinterDBHelper._internal();

  factory PrinterDBHelper() => _instance;

  PrinterDBHelper._internal() {}


  Future<int> addPrinterToDB(BluetoothPrinter printer) async {
    final db = await DatabaseInitializer().initDatabase();
    await db.delete(AppDBConst.printerTable);

    return await db.insert(
      AppDBConst.printerTable,
      {
        AppDBConst.printerDeviceName: printer.deviceName,
        AppDBConst.printerProductId: printer.productId ?? printer.address,
        AppDBConst.printerVendorId: printer.vendorId ?? 'bluetooth',
        AppDBConst.printerType:
        EnumToString.convertToString(printer.typePrinter),
      },
    );
  }

  Future<int> updatePrinterToDB(BluetoothPrinter printer) async {
    final db = await DatabaseInitializer().initDatabase();
    final int device;
    var printerDB = await getPrinterFromDB();

    if (printerDB.isEmpty) {
      device = await db.insert(AppDBConst.printerTable, {
        AppDBConst.printerDeviceName: printer.deviceName,
        AppDBConst.printerProductId: printer.productId,
        AppDBConst.printerVendorId: printer.vendorId,
        AppDBConst.printerType: EnumToString.convertToString(
            printer.typePrinter),
        AppDBConst.receiptIconPath: printer.receiptIconPath,
        //Build #1.0.122 : Added new column's
        AppDBConst.receiptHeaderText: printer.receiptHeaderText,
        AppDBConst.receiptFooterText: printer.receiptFooterText,
      });
    }
    else {
      device = await db.update(AppDBConst.printerTable, {
        AppDBConst.printerDeviceName: printer.deviceName,
        AppDBConst.printerProductId: printer.productId,
        AppDBConst.printerVendorId: printer.vendorId,
        AppDBConst.printerType: EnumToString.convertToString(
            printer.typePrinter),
        AppDBConst.receiptIconPath: printer.receiptIconPath,
        //Build #1.0.122 : Added new column's
        AppDBConst.receiptHeaderText: printer.receiptHeaderText,
        AppDBConst.receiptFooterText: printer.receiptFooterText,
      },
        where: '${AppDBConst.printerId} = ?',
        whereArgs: [1],
      );
    }
    if (kDebugMode) {
      print("#### Printer added in DB with deviceName: ${printer.deviceName}");
    }
    return device;
  }

  Future<List<Map<String, dynamic>>> getPrinterFromDB() async {
    final db = await DatabaseInitializer().initDatabase();
    //Build #1.0.279: Code Updated - Could not re add printer device to POS machine in setting-printer setting
    final printerDevice = await db.query(AppDBConst.printerTable);

    if (kDebugMode) {
      print("#### PrinterDb Retrieved no. of printerDevices = '${printerDevice
          .length}' from DB");
    }
    if (printerDevice.isNotEmpty) {
      if (kDebugMode) {
        print("#### PrinterDb Retrieved printerDevice name: '${printerDevice
            .first[AppDBConst.printerDeviceName]}' from DB");
      }
    }
    return printerDevice;
  }
}
