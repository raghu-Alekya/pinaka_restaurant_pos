import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:restaurant_captain_app/features/printer/printer_settings.dart';
import 'db_init.dart';

class PrinterDBHelper {
  static final PrinterDBHelper _instance = PrinterDBHelper._internal();

  factory PrinterDBHelper() => _instance;

  PrinterDBHelper._internal();

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

  // NEW: Ensure port column exists
  Future<void> _ensurePortColumn(db) async {
    try {
      await db.execute(
        'ALTER TABLE ${AppDBConst.printerTable} '
        'ADD COLUMN port TEXT',
      );
    } catch (_) {
      // Column already exists - ignore.
    }
  }

  // NEW: Ensure is_selected column exists
  Future<void> _ensureIsSelectedColumn(db) async {
    try {
      await db.execute(
        'ALTER TABLE ${AppDBConst.printerTable} '
        'ADD COLUMN is_selected INTEGER DEFAULT 1',
      );
    } catch (_) {
      // Column already exists - ignore.
    }
  }

  // ---- NEW HELPER: builds a WHERE clause + args that works safely for
  // ---- both network/bluetooth printers (unique address) and USB
  // ---- printers (address is usually '' so we key on address+deviceName
  // ---- instead to avoid accidentally matching every USB row at once). ----
  Map<String, dynamic> _matchClause(String address, String? deviceName) {
    if (address.isNotEmpty) {
      return {
        'where': '${AppDBConst.printerAddress} = ?',
        'args': [address],
      };
    } else if (deviceName != null && deviceName.isNotEmpty) {
      return {
        'where':
            '${AppDBConst.printerAddress} = ? AND ${AppDBConst.printerDeviceName} = ?',
        'args': ['', deviceName],
      };
    } else {
      // Fallback (shouldn't normally happen): match empty-address rows only.
      return {
        'where': '${AppDBConst.printerAddress} = ?',
        'args': [''],
      };
    }
  }

  // NEW: Add multiple printers to DB (replaces all existing)
  Future<void> addMultiplePrintersToDB(List<BluetoothPrinter> printers) async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);
    await _ensurePortColumn(db);
    await _ensureIsSelectedColumn(db);

    // Clear existing printers
    await db.delete(AppDBConst.printerTable);

    // Insert all printers
    for (var printer in printers) {
      await db.insert(AppDBConst.printerTable, {
        AppDBConst.printerDeviceName: printer.deviceName,
        AppDBConst.printerProductId:
            printer.productId ?? printer.address ?? 'network',
        AppDBConst.printerVendorId: printer.vendorId ?? 'network',
        AppDBConst.printerType: EnumToString.convertToString(
          printer.typePrinter,
        ),
        AppDBConst.printerAddress: printer.address ?? '',
        'port': printer.port ?? '9100',
        'is_selected': 1, // Default selected
        AppDBConst.receiptIconPath: printer.receiptIconPath,
        AppDBConst.receiptHeaderText: printer.receiptHeaderText,
        AppDBConst.receiptFooterText: printer.receiptFooterText,
      });
    }

    if (kDebugMode) {
      print("#### Added ${printers.length} printers to DB");
    }
  }

  // NEW: Update printer selection status
  // UPDATED: now accepts optional deviceName so USB printers (which have
  // an empty address) get matched precisely instead of matching every
  // USB row with address = ''. Existing callers that don't pass
  // deviceName keep working exactly as before for network/bluetooth
  // printers, since those still match on address alone.
  Future<int> updatePrinterSelection(
    String address,
    bool isSelected, {
    String? deviceName,
  }) async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);
    await _ensureIsSelectedColumn(db);

    final match = _matchClause(address, deviceName);

    final rowsAffected = await db.update(
      AppDBConst.printerTable,
      {'is_selected': isSelected ? 1 : 0},
      where: match['where'],
      whereArgs: match['args'],
    );

    if (kDebugMode) {
      print(
        "#### updatePrinterSelection: address='$address' deviceName='$deviceName' isSelected=$isSelected -> rowsAffected=$rowsAffected",
      );
    }

    return rowsAffected;
  }

  // NEW: Update all printer selections
  // NOTE: kept for backward compatibility as-is (keyed by address map).
  // Prefer calling updatePrinterSelection per-printer with deviceName
  // when a printer might have an empty address (USB).
  Future<void> updateAllPrinterSelections(Map<String, bool> selections) async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);
    await _ensureIsSelectedColumn(db);

    for (var entry in selections.entries) {
      await db.update(
        AppDBConst.printerTable,
        {'is_selected': entry.value ? 1 : 0},
        where: '${AppDBConst.printerAddress} = ?',
        whereArgs: [entry.key],
      );
    }
  }

  // NEW: Get all printers from DB
  Future<List<Map<String, dynamic>>> getAllPrintersFromDB() async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);
    await _ensurePortColumn(db);
    await _ensureIsSelectedColumn(db);

    final printers = await db.query(AppDBConst.printerTable);

    if (kDebugMode) {
      print("#### PrinterDb Retrieved ${printers.length} printers from DB");
      for (var printer in printers) {
        print(
          "#### Printer: ${printer[AppDBConst.printerDeviceName]} - ${printer[AppDBConst.printerAddress]} - Type: ${printer[AppDBConst.printerType]} - Selected: ${printer['is_selected'] ?? 1}",
        );
      }
    }

    return printers;
  }

  // NEW: Get selected printers only
  Future<List<Map<String, dynamic>>> getSelectedPrintersFromDB() async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);
    await _ensurePortColumn(db);
    await _ensureIsSelectedColumn(db);

    final printers = await db.query(
      AppDBConst.printerTable,
      where: 'is_selected = ?',
      whereArgs: [1],
    );

    if (kDebugMode) {
      print("#### Retrieved ${printers.length} selected printers from DB");
      for (var printer in printers) {
        print(
          "#### Selected Printer: ${printer[AppDBConst.printerDeviceName]} - ${printer[AppDBConst.printerAddress]} - Type: ${printer[AppDBConst.printerType]}",
        );
      }
    }

    return printers;
  }

  // NEW: Fix a mis-saved printer record's type and/or name in place.
  // Matches the same way addPrinterToDB does (address, or address+deviceName
  // for USB rows with empty address) so it only touches the intended row.
  Future<void> fixPrinterRecord({
    required String address,
    required String currentDeviceName,
    String? correctedType,
    String? correctedName,
    String? correctedVendorId, // NEW
    String? correctedProductId, // NEW
    bool clearVendorId = false, // NEW: explicitly blank it out
    bool clearProductId = false, // NEW: explicitly blank it out
  }) async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);

    final match = _matchClause(address, currentDeviceName);

    final Map<String, dynamic> updates = {};
    if (correctedType != null) {
      updates[AppDBConst.printerType] = correctedType;
    }
    if (correctedName != null) {
      updates[AppDBConst.printerDeviceName] = correctedName;
    }
    if (correctedVendorId != null) {
      updates[AppDBConst.printerVendorId] = correctedVendorId;
    }
    if (correctedProductId != null) {
      updates[AppDBConst.printerProductId] = correctedProductId;
    }
    if (clearVendorId) updates[AppDBConst.printerVendorId] = '';
    if (clearProductId) updates[AppDBConst.printerProductId] = '';

    if (updates.isEmpty) return;

    final rows = await db.update(
      AppDBConst.printerTable,
      updates,
      where: match['where'],
      whereArgs: match['args'],
    );

    if (kDebugMode) {
      print(
        "#### fixPrinterRecord: address='$address' name='$currentDeviceName' -> $updates (rowsAffected=$rows)",
      );
    }
  }

  // NEW: Delete a specific printer
  // UPDATED: now accepts optional deviceName so USB printers (empty
  // address) get deleted precisely instead of deleting every USB row.
  Future<void> deletePrinterFromDBByAddress(
    String address, {
    String? deviceName,
  }) async {
    final db = await DatabaseInitializer().initDatabase();

    final match = _matchClause(address, deviceName);

    await db.delete(
      AppDBConst.printerTable,
      where: match['where'],
      whereArgs: match['args'],
    );

    if (kDebugMode) {
      print(
        "#### Deleted printer with address: '$address' deviceName: '$deviceName'",
      );
    }
  }

  // NEW: Clear all printers
  Future<void> clearAllPrinters() async {
    final db = await DatabaseInitializer().initDatabase();
    await db.delete(AppDBConst.printerTable);

    if (kDebugMode) {
      print("#### Cleared all printers from DB");
    }
  }

  // Keep existing methods for backward compatibility
  // UPDATED internally: existence check now uses the safe match clause
  // (address, or address+deviceName for USB) instead of address alone,
  // so multiple USB printers with empty address don't collide/overwrite
  // each other. Method signature and external behavior for network
  // printers is unchanged.
  Future<int> addPrinterToDB(BluetoothPrinter printer) async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);
    await _ensurePortColumn(db);
    await _ensureIsSelectedColumn(db);

    final addr = printer.address ?? '';
    final match = _matchClause(addr, printer.deviceName);

    // Check if printer already exists
    final existing = await db.query(
      AppDBConst.printerTable,
      where: match['where'],
      whereArgs: match['args'],
    );

    if (existing.isNotEmpty) {
      // Update existing
      return await db.update(
        AppDBConst.printerTable,
        {
          AppDBConst.printerDeviceName: printer.deviceName,
          AppDBConst.printerProductId:
              printer.productId ?? printer.address ?? 'network',
          AppDBConst.printerVendorId: printer.vendorId ?? 'network',
          AppDBConst.printerType: EnumToString.convertToString(
            printer.typePrinter,
          ),
          AppDBConst.printerAddress: printer.address ?? '',
          'port': printer.port ?? '9100',
          'is_selected': 1,
          AppDBConst.receiptIconPath: printer.receiptIconPath,
          AppDBConst.receiptHeaderText: printer.receiptHeaderText,
          AppDBConst.receiptFooterText: printer.receiptFooterText,
        },
        where: match['where'],
        whereArgs: match['args'],
      );
    } else {
      // Insert new
      return await db.insert(AppDBConst.printerTable, {
        AppDBConst.printerDeviceName: printer.deviceName,
        AppDBConst.printerProductId:
            printer.productId ?? printer.address ?? 'network',
        AppDBConst.printerVendorId: printer.vendorId ?? 'network',
        AppDBConst.printerType: EnumToString.convertToString(
          printer.typePrinter,
        ),
        AppDBConst.printerAddress: printer.address ?? '',
        'port': printer.port ?? '9100',
        'is_selected': 1,
        AppDBConst.receiptIconPath: printer.receiptIconPath,
        AppDBConst.receiptHeaderText: printer.receiptHeaderText,
        AppDBConst.receiptFooterText: printer.receiptFooterText,
      });
    }
  }

  // Keep for backward compatibility - returns first printer
  Future<List<Map<String, dynamic>>> getPrinterFromDB() async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);
    await _ensurePortColumn(db);
    await _ensureIsSelectedColumn(db);

    final printerDevice = await db.query(AppDBConst.printerTable);

    if (kDebugMode) {
      print(
        "#### PrinterDb Retrieved ${printerDevice.length} printer(s) from DB",
      );
    }

    return printerDevice;
  }

  // Keep for backward compatibility
  Future<void> deletePrinterFromDB() async {
    final db = await DatabaseInitializer().initDatabase();
    await db.delete(AppDBConst.printerTable);
  }

  // Keep for backward compatibility
  // UPDATED internally: same safe-match fix as addPrinterToDB, so USB
  // printers with empty address don't collide with each other.
  Future<int> updatePrinterToDB(BluetoothPrinter printer) async {
    final db = await DatabaseInitializer().initDatabase();
    await _ensureAddressColumn(db);
    await _ensurePortColumn(db);
    await _ensureIsSelectedColumn(db);

    final addr = printer.address ?? '';
    final match = _matchClause(addr, printer.deviceName);

    // Check if printer exists
    final existing = await db.query(
      AppDBConst.printerTable,
      where: match['where'],
      whereArgs: match['args'],
    );

    if (existing.isEmpty) {
      // Insert new
      return await db.insert(AppDBConst.printerTable, {
        AppDBConst.printerDeviceName: printer.deviceName,
        AppDBConst.printerProductId:
            printer.productId ?? printer.address ?? 'network',
        AppDBConst.printerVendorId: printer.vendorId ?? 'network',
        AppDBConst.printerType: EnumToString.convertToString(
          printer.typePrinter,
        ),
        AppDBConst.printerAddress: printer.address ?? '',
        'port': printer.port ?? '9100',
        'is_selected': 1,
        AppDBConst.receiptIconPath: printer.receiptIconPath,
        AppDBConst.receiptHeaderText: printer.receiptHeaderText,
        AppDBConst.receiptFooterText: printer.receiptFooterText,
      });
    } else {
      // Update existing
      return await db.update(
        AppDBConst.printerTable,
        {
          AppDBConst.printerDeviceName: printer.deviceName,
          AppDBConst.printerProductId:
              printer.productId ?? printer.address ?? 'network',
          AppDBConst.printerVendorId: printer.vendorId ?? 'network',
          AppDBConst.printerType: EnumToString.convertToString(
            printer.typePrinter,
          ),
          AppDBConst.printerAddress: printer.address ?? '',
          'port': printer.port ?? '9100',
          'is_selected': 1,
          AppDBConst.receiptIconPath: printer.receiptIconPath,
          AppDBConst.receiptHeaderText: printer.receiptHeaderText,
          AppDBConst.receiptFooterText: printer.receiptFooterText,
        },
        where: match['where'],
        whereArgs: match['args'],
      );
    }
  }
}
