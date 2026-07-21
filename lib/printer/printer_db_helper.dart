// import 'package:enum_to_string/enum_to_string.dart';
// import 'package:flutter/foundation.dart';
// import 'package:pinaka_restaurant_pos/printer/printer_settings.dart';
// import '../local database/db_init.dart';
//
//
//
// class PrinterDBHelper {
//   static final PrinterDBHelper _instance = PrinterDBHelper._internal();
//
//   factory PrinterDBHelper() => _instance;
//
//   PrinterDBHelper._internal() {}
//
//
//   Future<int> addPrinterToDB(BluetoothPrinter printer) async {
//     final db = await DatabaseInitializer().initDatabase();
//     await db.delete(AppDBConst.printerTable);
//
//     return await db.insert(
//       AppDBConst.printerTable,
//       {
//         AppDBConst.printerDeviceName: printer.deviceName,
//         AppDBConst.printerProductId: printer.productId ?? printer.address,
//         AppDBConst.printerVendorId: printer.vendorId ?? 'bluetooth',
//         AppDBConst.printerType:
//         EnumToString.convertToString(printer.typePrinter),
//       },
//     );
//   }
//
//   Future<int> updatePrinterToDB(BluetoothPrinter printer) async {
//     final db = await DatabaseInitializer().initDatabase();
//     final int device;
//     var printerDB = await getPrinterFromDB();
//
//     if (printerDB.isEmpty) {
//       device = await db.insert(AppDBConst.printerTable, {
//         AppDBConst.printerDeviceName: printer.deviceName,
//         AppDBConst.printerProductId: printer.productId,
//         AppDBConst.printerVendorId: printer.vendorId,
//         AppDBConst.printerType: EnumToString.convertToString(
//             printer.typePrinter),
//         AppDBConst.receiptIconPath: printer.receiptIconPath,
//         AppDBConst.receiptHeaderText: printer.receiptHeaderText,
//         AppDBConst.receiptFooterText: printer.receiptFooterText,
//       });
//     }
//     else {
//       device = await db.update(AppDBConst.printerTable, {
//         AppDBConst.printerDeviceName: printer.deviceName,
//         AppDBConst.printerProductId: printer.productId,
//         AppDBConst.printerVendorId: printer.vendorId,
//         AppDBConst.printerType: EnumToString.convertToString(
//             printer.typePrinter),
//         AppDBConst.receiptIconPath: printer.receiptIconPath,
//         //Build #1.0.122 : Added new column's
//         AppDBConst.receiptHeaderText: printer.receiptHeaderText,
//         AppDBConst.receiptFooterText: printer.receiptFooterText,
//       },
//         where: '${AppDBConst.printerId} = ?',
//         whereArgs: [1],
//       );
//     }
//     if (kDebugMode) {
//       print("#### Printer added in DB with deviceName: ${printer.deviceName}");
//     }
//     return device;
//   }
//
//   Future<List<Map<String, dynamic>>> getPrinterFromDB() async {
//     final db = await DatabaseInitializer().initDatabase();
//     final printerDevice = await db.query(AppDBConst.printerTable);
//
//     if (kDebugMode) {
//       print("#### PrinterDb Retrieved no. of printerDevices = '${printerDevice
//           .length}' from DB");
//     }
//     if (printerDevice.isNotEmpty) {
//       if (kDebugMode) {
//         print("#### PrinterDb Retrieved printerDevice name: '${printerDevice
//             .first[AppDBConst.printerDeviceName]}' from DB");
//       }
//     }
//     return printerDevice;
//   }
// }



import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:pinaka_restaurant_pos/printer/printer_settings.dart';
import '../local database/db_init.dart';

class PrinterDBHelper {
  static final PrinterDBHelper _instance = PrinterDBHelper._internal();

  factory PrinterDBHelper() => _instance;

  PrinterDBHelper._internal() {}

  // ---- NEW: makes sure the printer_address column exists, even on a  ----
  // ---- database that was created before this fix. Safe to call every ----
  // ---- time - if the column already exists this just fails silently  ----
  // ---- and is ignored, nothing about your existing table is touched. ----
  Future<void> _ensureAddressColumn(db) async {
    try {
      await db.execute(
        'ALTER TABLE ${AppDBConst.printerTable} '
            'ADD COLUMN ${AppDBConst.printerAddress} TEXT',
      );
    } catch (_) {
      // Column already exists (or table not created yet) - ignore.
    }
  }

  Future<int> addPrinterToDB(BluetoothPrinter printer) async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);
    await db.delete(AppDBConst.printerTable);

    return await db.insert(
      AppDBConst.printerTable,
      {
        AppDBConst.printerDeviceName: printer.deviceName,
        AppDBConst.printerProductId: printer.productId ?? printer.address,
        AppDBConst.printerVendorId: printer.vendorId ?? 'bluetooth',
        AppDBConst.printerType:
        EnumToString.convertToString(printer.typePrinter),
        // FIX: actually persist the real address/IP in its own column
        // instead of only smuggling it into product_id.
        AppDBConst.printerAddress: printer.address,
      },
    );
  }

  Future<void> deletePrinterFromDB() async {
    final db = await DatabaseInitializer().initDatabase();
    await db.delete(AppDBConst.printerTable);
  }

  Future<int> updatePrinterToDB(BluetoothPrinter printer) async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);
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
        AppDBConst.receiptHeaderText: printer.receiptHeaderText,
        AppDBConst.receiptFooterText: printer.receiptFooterText,
        // FIX: same address persistence fix as addPrinterToDB above.
        AppDBConst.printerAddress: printer.address,
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
        // FIX: same address persistence fix as addPrinterToDB above.
        AppDBConst.printerAddress: printer.address,
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
    await _ensureAddressColumn(db);
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