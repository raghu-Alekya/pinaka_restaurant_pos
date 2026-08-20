import 'dart:convert';
import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/thermal_printer.dart';

import '../../models/General_Settings_Model.dart';
import '../../printer/printer_settings.dart';
import '../../printer/printer_setup_screen.dart';
import '../../printer/printer_db_helper.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/SessionManager.dart';

// Add this model for printer selection
class PrinterSelection {
  final String name;
  final String address;
  final String port;
  final String type;        // NEW: 'network' | 'usb' | 'bluetooth'
  final String? vendorId;   // NEW
  final String? productId;  // NEW
  final bool isBle;         // NEW
  bool isSelected;

  PrinterSelection({
    required this.name,
    required this.address,
    required this.port,
    this.type = 'network',
    this.vendorId,
    this.productId,
    this.isBle = false,
    this.isSelected = false,
  });
}

class SettingsScreen extends StatefulWidget {
  final String token;
  final String pin;
  final String userId;
  final String displayName;
  final String role;

  const SettingsScreen({
    super.key,
    required this.token,
    required this.pin,
    required this.userId,
    required this.displayName,
    required this.role,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _footerController = TextEditingController();

  Uint8List? _photoBytes;
  Uint8List? _logoBytes;
  String? _photoBase64;
  String? _logoBase64;
  String? _selectedDefaultMethod;
  Map<String, bool> _paymentSelections = {
    "Cash": true,
    "Card": true,
    "UPI": true,
    "Wallets": true,
  };
  Map<String, bool> _otherSelections = {
    "Coupons": true,
    "Tips": true,
  };
  Map<String, bool> _orderTypeSelections = {
    "Dine-in": true,
    "Takeaway": true,
  };
  final ImagePicker _picker = ImagePicker();
  String _selectedLabel = "General";

  // Updated: Support multiple printers
  List<PrinterSelection> _connectedPrinters = [];
  bool _isLoadingPrinters = false;

  final GeneralSettingsRepository _settingsRepository =
  GeneralSettingsRepository();

  String? _receiptLogoUrl;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    print("SettingsScreen initialized with:");
    print("User ID: ${widget.userId}");
    print("Display Name: ${widget.displayName}");
    _loadSavedSettings();
    _loadConnectedPrinters();
    _loadGeneralSettings();
  }

  // ==================== PRINTER NAME HELPER ====================

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

  // NEW: Get printer badge info based on index
  Map<String, dynamic> _getPrinterBadge(int index) {
    if (index == 0) {
      return {
        'text': 'KOT',
        'color': Colors.blue,
        'icon': Icons.receipt_long,
      };
    } else if (index == 1) {
      return {
        'text': 'Cash',
        'color': Colors.green,
        'icon': Icons.attach_money,
      };
    } else {
      return {
        'text': 'P${index + 1}',
        'color': Colors.grey,
        'icon': Icons.print,
      };
    }
  }

  // ==================== PRINTER DB METHODS ====================

  // NEW: Save printers to database
  Future<void> _savePrintersToDB() async {
    try {
      final printerDb = PrinterDBHelper();

      // Clear existing printers from DB
      await printerDb.clearAllPrinters();

      // Add each printer to DB
      for (var printer in _connectedPrinters) {
        final printerType = printer.type == 'usb'
            ? PrinterType.usb
            : printer.type == 'bluetooth'
            ? PrinterType.bluetooth
            : PrinterType.network;

        final bluetoothPrinter = BluetoothPrinter(
          deviceName: printer.name,
          address: printer.address,
          port: printer.port,
          vendorId: printer.vendorId,
          productId: printer.productId,
          isBle: printer.isBle,
          typePrinter: printerType,   // FIXED
          state: false,
        );

        await printerDb.addPrinterToDB(bluetoothPrinter);
      }

      for (var printer in _connectedPrinters) {
        await printerDb.updatePrinterSelection(
          printer.address,
          printer.isSelected,
          deviceName: printer.name,
        );
      }

      if (kDebugMode) {
        print("#### Saved ${_connectedPrinters.length} printers to DB");
      }
    } catch (e) {
      print("Error saving printers to DB: $e");
    }
  }

  // NEW: Load all connected printers
// NEW: Load all connected printers
  Future<void> _loadConnectedPrinters() async {
    if (_isLoadingPrinters) return;

    setState(() {
      _isLoadingPrinters = true;
    });

    try {
      final printerDb = PrinterDBHelper();

      // First try to load from DB (this will include all printers)
      final dbPrinters = await printerDb.getAllPrintersFromDB();
      List<PrinterSelection> tempPrinters = [];

      // Load from database — SINGLE pass, with type/vendorId/productId included
      if (dbPrinters.isNotEmpty) {
        for (var printer in dbPrinters) {
          final deviceName = printer['deviceName'] ?? printer['device_name'] ?? 'Unknown';
          final address = printer['printer_address'] ?? '';
          final port = printer['port'] ?? '9100';
          final isSelected = (printer['is_selected'] ?? 1) == 1;
          final type = printer[AppDBConst.printerType] ?? 'network';
          final vendorId = printer[AppDBConst.printerVendorId]?.toString();
          final productId = printer[AppDBConst.printerProductId]?.toString();

          tempPrinters.add(PrinterSelection(
            name: deviceName,
            address: address,
            port: port,
            isSelected: isSelected,
            type: type,
            vendorId: vendorId,
            productId: productId,
          ));
        }
      }

      // Also load network printers from shared preferences (for backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      final savedPrinters = prefs.getString('network_printers');

      if (savedPrinters != null && savedPrinters.isNotEmpty) {
        try {
          final List<dynamic> printerList = jsonDecode(savedPrinters);
          for (var printer in printerList) {
            final ip = printer['ip'] ?? '';
            final port = printer['port'] ?? '9100';
            final name = printer['name'] ?? 'Network Printer';

            // Check if already exists in tempPrinters
            final exists = tempPrinters.any((p) => p.address == ip);
            if (!exists && ip.isNotEmpty) {
              tempPrinters.add(PrinterSelection(
                name: name,
                address: ip,
                port: port,
                isSelected: true,
              ));
            }
          }
        } catch (e) {
          print('Error parsing network printers: $e');
        }
      }

      // Load selected printers from shared preferences
      final selectedPrinters = prefs.getString('selected_printers');
      if (selectedPrinters != null && selectedPrinters.isNotEmpty) {
        try {
          final List<dynamic> selectedList = jsonDecode(selectedPrinters);
          for (var printer in tempPrinters) {
            printer.isSelected = selectedList.any((p) =>
            p['address'] == printer.address && p['port'] == printer.port
            );
          }
        } catch (e) {
          print('Error loading selected printers: $e');
        }
      }

      // Apply proper names based on index — RENAME ONLY, no re-adding
      for (int i = 0; i < tempPrinters.length; i++) {
        final printer = tempPrinters[i];
        if (printer.name == 'Network Printer' ||
            printer.name == 'Unknown' ||
            printer.name == 'Unknown Printer' ||
            printer.name.startsWith('Printer ')) {
          tempPrinters[i] = PrinterSelection(
            name: _getPrinterName(i, printer.name),
            address: printer.address,
            port: printer.port,
            isSelected: printer.isSelected,
            type: printer.type,           // preserve type on rename
            vendorId: printer.vendorId,   // preserve vendorId on rename
            productId: printer.productId, // preserve productId on rename
          );
        }
      }

      setState(() {
        _connectedPrinters = tempPrinters;
        _isLoadingPrinters = false;
      });

      // If we have printers but they're not in DB, save them
      if (_connectedPrinters.isNotEmpty && dbPrinters.isEmpty) {
        await _savePrintersToDB();
      }
    } catch (e) {
      debugPrint("Error loading connected printers: $e");
      setState(() {
        _isLoadingPrinters = false;
      });
    }
  }
  // NEW: Save selected printers to SharedPreferences
  Future<void> _saveSelectedPrinters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedList = _connectedPrinters
          .where((p) => p.isSelected)
          .map((p) => {
        'name': p.name,
        'address': p.address,
        'port': p.port,
        'type': p.type,           // NEW
        'vendorId': p.vendorId,   // NEW
        'productId': p.productId, // NEW
      })
          .toList();
      await prefs.setString('selected_printers', jsonEncode(selectedList));

      // Also save to DB
      await _savePrintersToDB();
    } catch (e) {
      print('Error saving selected printers: $e');
    }
  }

  // NEW: Toggle printer selection
  void _togglePrinterSelection(int index) {
    setState(() {
      _connectedPrinters[index].isSelected = !_connectedPrinters[index].isSelected;
    });
    _saveSelectedPrinters();
  }

  // NEW: Remove printer from list
  Future<void> _removePrinter(int index) async {
    final printer = _connectedPrinters[index];

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Printer'),
        content: Text('Are you sure you want to remove "${printer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Remove from database
      final printerDb = PrinterDBHelper();
      await printerDb.deletePrinterFromDBByAddress(printer.address);

      // Remove from list
      setState(() {
        _connectedPrinters.removeAt(index);
      });

      // Save updated list
      await _saveSelectedPrinters();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer removed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint("Error removing printer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing printer: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ==================== SETTINGS METHODS ====================

  Future<void> _loadGeneralSettings() async {
    try {
      final token = await SessionManager.getToken();

      final response = await _settingsRepository.fetchGeneralSettings(
        token: token!,
      );

      final data = response["data"];

      setState(() {
        _fullNameController.text = data["full_name"] ?? "";
        _contactController.text = data["phone_number"] ?? "";
        _emailController.text = data["email"] ?? "";
        _deviceIdController.text = data["user_device_id"] ?? "";

        _companyController.text = data["company_name"] ?? "";
        _gstinController.text =
        data["gstin"] == false ? "" : data["gstin"].toString();
        _headerController.text =
        data["header_text"] == false ? "" : data["header_text"].toString();
        _footerController.text =
        data["footer_text"] == false ? "" : data["footer_text"].toString();
      });
      if ((data["profile_url"] ?? "").toString().isNotEmpty) {
        _profileImageUrl = data["profile_url"];
        _loadProfileImage(data["profile_url"]);
        _loadProfileImage(_profileImageUrl!);
      }

      if ((data["receipt_logo"] ?? "").toString().isNotEmpty) {
        _receiptLogoUrl = data["receipt_logo"];
        _loadLogoImage(data["receipt_logo"]);
        _loadLogoImage(_receiptLogoUrl!);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadProfileImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _photoBytes = response.bodyBytes;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadLogoImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _logoBytes = response.bodyBytes;
        });
      }
    } catch (e) {
      debugPrint("Logo image error: $e");
    }
  }

  Future<void> _saveGeneralSettings() async {
    try {
      final token = await SessionManager.getToken();

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token not found"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      // Save printers to DB first
      await _savePrintersToDB();

      // Build print_settings list → prefer IP/address, fallback to name
      final selectedPrinterSettings = _connectedPrinters
          .where((p) => p.isSelected)
          .map((p) {
        // Send IP/address if available, otherwise send the printer name
        if (p.address.trim().isNotEmpty) {
          return p.address.trim();
        }
        return p.name;
      })
          .toList();

      final request = SaveGeneralSettingsRequest(
        headerText: _headerController.text.trim(),
        footerText: _footerController.text.trim(),
        printSettings: selectedPrinterSettings,   // ← List of IPs / names
        receiptLogoUrl: _receiptLogoUrl ?? "",
      );

      final response = await _settingsRepository.saveGeneralSettings(
        token: token,
        request: request,
      );

      await _saveSettings();
      await _saveSelectedPrinters();

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(response.message),
      //     backgroundColor: Colors.green,
      //     duration: const Duration(seconds: 1),
      //   ),
      // );

      await _loadGeneralSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullNameController.text = prefs.getString('fullName') ?? '';
      _contactController.text = prefs.getString('contactNo') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _deviceIdController.text = prefs.getString('deviceId') ?? '';
      _companyController.text = prefs.getString('companyName') ?? '';
      _gstinController.text = prefs.getString('gstin') ?? '';
      _headerController.text = prefs.getString('header') ?? '';
      _footerController.text = prefs.getString('footer') ?? '';
      _photoBase64 = prefs.getString('photoBase64');
      _logoBase64 = prefs.getString('logoBase64');
      _photoBytes = _photoBase64 != null ? base64Decode(_photoBase64!) : null;
      _logoBytes = _logoBase64 != null ? base64Decode(_logoBase64!) : null;
      _selectedDefaultMethod = prefs.getString('selectedDefaultMethod');

      final paymentSelectionsString = prefs.getString('paymentSelections');
      if (paymentSelectionsString != null) {
        _paymentSelections = Map<String, bool>.from(
          jsonDecode(paymentSelectionsString),
        );
      }

      final otherSelectionsString = prefs.getString('otherSelections');
      if (otherSelectionsString != null) {
        _otherSelections = Map<String, bool>.from(
          jsonDecode(otherSelectionsString),
        );
      }
      final orderTypeString = prefs.getString('orderTypeSelections');
      if (orderTypeString != null) {
        _orderTypeSelections = Map<String, bool>.from(
          jsonDecode(orderTypeString),
        );
      }
    });
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);

      setState(() {
        if (isProfile) {
          _photoBytes = bytes;
          _photoBase64 = base64Str;
        } else {
          _logoBytes = bytes;
          _logoBase64 = base64Str;
        }
      });

      final token = await SessionManager.getToken();

      final uploadedUrl = await _settingsRepository.uploadImage(
        token: token!,
        imagePath: picked.path,
      );
      if (isProfile) {
        await _settingsRepository.editProfileImage(
          token: token,
          profileImageUrl: uploadedUrl,
        );
      } else {
        setState(() {
          _logoBytes = bytes;
          _logoBase64 = base64Str;
          _receiptLogoUrl = uploadedUrl;
        });

        await _settingsRepository.editReceiptImage(
          token: token,
          receiptLogoUrl: uploadedUrl,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image updated successfully"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint("Image upload error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', _fullNameController.text);
    await prefs.setString('contactNo', _contactController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('deviceId', _deviceIdController.text);
    await prefs.setString('companyName', _companyController.text);
    await prefs.setString('gstin', _gstinController.text);
    await prefs.setString('header', _headerController.text);
    await prefs.setString('footer', _footerController.text);
    if (_photoBase64 != null)
      await prefs.setString('photoBase64', _photoBase64!);
    if (_logoBase64 != null) await prefs.setString('logoBase64', _logoBase64!);
    await prefs.setString(
      'selectedDefaultMethod',
      _selectedDefaultMethod ?? '',
    );
    await prefs.setString('paymentSelections', jsonEncode(_paymentSelections));
    await prefs.setString('otherSelections', jsonEncode(_otherSelections));
    await prefs.setString('orderTypeSelections', jsonEncode(_orderTypeSelections));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ==================== UI WIDGETS ====================

  Widget _photoBox(Uint8List? bytes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _pickImage(true),
          child: DottedBorder(
            color: Colors.black,
            strokeWidth: 1.5,
            dashPattern: const [6, 5],
            borderType: BorderType.RRect,
            radius: const Radius.circular(12),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child:
              bytes == null
                  ? const Center(
                child: Icon(
                  Icons.add_a_photo_outlined,
                  size: 28,
                  color: Colors.black,
                ),
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        if (bytes != null) ...[
          const SizedBox(width: 12),
          Column(
            children: [
              InkWell(
                onTap: () => _pickImage(true),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  try {
                    final token = await SessionManager.getToken();

                    await _settingsRepository.editProfileImage(
                      token: token!,
                      profileImageUrl: "",
                    );

                    setState(() {
                      _photoBytes = null;
                      _photoBase64 = null;
                      _profileImageUrl = null;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profile image removed successfully"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _logoBox(Uint8List? bytes, String? imageUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _pickImage(false),
          child: DottedBorder(
            color: Colors.black,
            strokeWidth: 1.5,
            dashPattern: const [6, 5],
            borderType: BorderType.RRect,
            radius: const Radius.circular(12),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child:
              bytes == null
                  ? const Center(
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 28,
                  color: Colors.black,
                ),
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        if (bytes != null) ...[
          const SizedBox(width: 12),
          Column(
            children: [
              InkWell(
                onTap: () => _pickImage(false),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  try {
                    final token = await SessionManager.getToken();

                    await _settingsRepository.editReceiptImage(
                      token: token!,
                      receiptLogoUrl: "",
                    );

                    setState(() {
                      _logoBytes = null;
                      _logoBase64 = null;
                      _receiptLogoUrl = null;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Logo removed successfully"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTabs() {
    final List<String> labels = ["General", "Payment", "Advanced"];

    return Row(
      children:
      labels.map((label) {
        final bool selected = label == _selectedLabel;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedLabel = label;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                gradient:
                selected
                    ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF002E63), Color(0xFF005DC9)],
                )
                    : null,
                color: selected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow:
                selected
                    ? [
                  const BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ]
                    : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontFamily: 'Manrope',
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController controller, {
        String? hint,
        bool readOnly = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? (readOnly
                ? const Color(0xFF2B3142)
                : const Color(0xFF353C4E))
                : (readOnly
                ? const Color(0xFFF5F5F5)
                : const Color(0xFFEDF2F6)),

            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white24
                    : const Color(0xFFE0E4EC),
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white24
                    : const Color(0xFFE0E4EC),
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white54
                    : const Color(0xFFE0E4EC),
                width: 1.5,
              ),
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF161A26) : const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Container(
                      padding: const EdgeInsets.all(27),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(10),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.arrow_back, size: 18),
                                        SizedBox(width: 5),
                                        Text(
                                          'Back',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _buildTabs(),
                                const Spacer(),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _saveGeneralSettings,
                                  child: const Text("Save Changes"),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          if (_selectedLabel == "General")
                            _buildGeneralSection(),
                          if (_selectedLabel == "Payment")
                            _buildPaymentSection(),
                          if (_selectedLabel == "Advanced")
                            _buildAdvancedSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Change your personal information",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _photoBox(_photoBytes),
                  const SizedBox(width: 20),
                   Expanded(
                    child: Text(
                      "Upload\nPlease Upload a Clear Photo\nAccepted formats: JPG, PNG · Max size: 5MB",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _buildField("Full Name", _fullNameController, readOnly: true),
              const SizedBox(height: 18),
              _buildField("Contact No.", _contactController, readOnly: true),
              const SizedBox(height: 18),
              _buildField("Email Address", _emailController, readOnly: true),
              const SizedBox(height: 18),
              _buildField("Device ID :", _deviceIdController, readOnly: true),
              const SizedBox(height: 18),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      "Loading version...",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 15,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text(
                      "Version info not available",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 15,
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final packageInfo = snapshot.data!;
                    final version =
                        '${packageInfo.version}+${packageInfo.buildNumber}';
                    return Text(
                      "App Version $version",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 50),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Receipt Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Customise your own receipt",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _logoBox(_logoBytes, _receiptLogoUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildField("Company Name", _companyController, readOnly: true),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildField("GSTIN", _gstinController, readOnly: true),
              const SizedBox(height: 20),
              _buildField("Header", _headerController),
              const SizedBox(height: 20),
              _buildField("Footer", _footerController),
              const SizedBox(height: 20),

              // UPDATED: Printer Settings Section with Multiple Printers
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Printer Settings",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Loading indicator
                  if (_isLoadingPrinters)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // Printer List
                  if (!_isLoadingPrinters && _connectedPrinters.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2B3142)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No printers connected. Please add a printer.',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_isLoadingPrinters && _connectedPrinters.isNotEmpty)
                    Column(
                      children: [
                        ..._connectedPrinters.asMap().entries.map((entry) {
                          final index = entry.key;
                          final printer = entry.value;
                          final badge = _getPrinterBadge(index);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: printer.isSelected
                                  ? (isDark
                                  ? const Color(0xFF1F3A2D)
                                  : Colors.green.shade50)
                                  : (isDark
                                  ? const Color(0xFF2B3142)
                                  : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: printer.isSelected
                                    ? Colors.green
                                    : (isDark ? Colors.white24 : Colors.grey.shade300),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: Checkbox(
                                value: printer.isSelected,
                                onChanged: (value) => _togglePrinterSelection(index),
                                activeColor: Colors.green,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    printer.name,
                                    style: TextStyle(
                                      fontWeight:
                                      printer.isSelected ? FontWeight.w600 : FontWeight.normal,
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Badge for KOT and Cash printers
                                  if (index == 0 || index == 1)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badge['color'],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            badge['icon'],
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            badge['text'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '${printer.address}:${printer.port}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                onPressed: () => _removePrinter(index),
                              ),
                            ),
                          );
                        }).toList(),

                        // Selected printers count with type indicators
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF22324A)
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Selected Printers:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  // Show KOT and Cash indicators if selected
                                  if (_connectedPrinters.isNotEmpty && _connectedPrinters[0].isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        'KOT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (_connectedPrinters.length > 1 && _connectedPrinters[1].isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        'Cash',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_connectedPrinters.where((p) => p.isSelected).length} / ${_connectedPrinters.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),

                  // Add Printer Button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrinterSetup(),
                              ),
                            );
                            await _loadConnectedPrinters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text(
                            "Add Printer",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_connectedPrinters.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            // Select all printers
                            setState(() {
                              for (var printer in _connectedPrinters) {
                                printer.isSelected = true;
                              }
                            });
                            _saveSelectedPrinters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.select_all, color: Colors.white, size: 18),
                          label: const Text(
                            "All",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Settings",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            "Default Payment Method",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black,
            ),
          ),
          const SizedBox(height: 6),

          Theme(
            data: Theme.of(context).copyWith(
              canvasColor:
              isDark ? const Color(0xFF34384F) : Colors.white,
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedDefaultMethod != null &&
                  _paymentSelections.containsKey(_selectedDefaultMethod)
                  ? _selectedDefaultMethod
                  : null,
              dropdownColor:
              isDark ? const Color(0xFF34384F) : Colors.white,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              iconEnabledColor:
              isDark ? Colors.white70 : Colors.black54,
              items: _paymentSelections.keys
                  .map(
                    (method) => DropdownMenuItem(
                  value: method,
                  child: Text(
                    method,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDefaultMethod = val;
                });
              },
              decoration: InputDecoration(
                hintText: "Select Payment Method",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
                filled: true,
                fillColor:
                isDark ? const Color(0xFF202433) : const Color(0xFFF4F6FB),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 26),

          Text(
            "Payment Methods",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              for (var method in _paymentSelections.keys)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _paymentSelections[method],
                      onChanged: (val) =>
                          setState(() => _paymentSelections[method] = val!),
                      activeColor:
                      isDark ? Colors.white : Colors.black,
                      checkColor:
                      isDark ? Colors.black : Colors.white,
                      fillColor:
                      WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return isDark ? Colors.white : Colors.black;
                        }
                        return isDark
                            ? Colors.white54
                            : Colors.grey;
                      }),
                    ),
                    Text(
                      method,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                        isDark ? Colors.white70 : Colors.black,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 30),

          Text(
            "Other Options",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              for (var opt in _otherSelections.keys)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _otherSelections[opt],
                      onChanged: (val) =>
                          setState(() => _otherSelections[opt] = val!),
                      activeColor:
                      isDark ? Colors.white : Colors.black,
                      checkColor:
                      isDark ? Colors.black : Colors.white,
                      fillColor:
                      WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return isDark ? Colors.white : Colors.black;
                        }
                        return isDark
                            ? Colors.white54
                            : Colors.grey;
                      }),
                    ),
                    Text(
                      opt,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                        isDark ? Colors.white70 : Colors.black,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Advanced Settings",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Order Type",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              for (var opt in _orderTypeSelections.keys)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _orderTypeSelections[opt],
                      onChanged: (val) {
                        setState(() => _orderTypeSelections[opt] = val!);
                      },
                      activeColor: Colors.white,
                      checkColor: Colors.black,
                      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return isDark ? Colors.white : Colors.black;
                        }
                        return isDark ? Colors.white54 : Colors.grey;
                      }),
                    ),
                    Text(
                      opt,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}