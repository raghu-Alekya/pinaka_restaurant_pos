import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // ✅ needed for Provider.of
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restaurant_captain_app/features/printer/printer_db_helper.dart';
import 'package:restaurant_captain_app/features/printer/printer_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/thermal_printer.dart';

// ✅ Import CaptainLocalStorage
import '../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';

// Printer selection model (unchanged)
class PrinterSelection {
  final String name;
  final String address;
  final String port;
  final String type;
  final String? vendorId;
  final String? productId;
  final bool isBle;
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
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // User details
  String _displayName = '';
  String _role = '';
  String _userId = '';
  String _token = '';

  // Settings state
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  // Profile image
  Uint8List? _photoBytes;
  String? _photoBase64;

  // Printer management
  List<PrinterSelection> _connectedPrinters = [];
  bool _isLoadingPrinters = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadSavedSettings();
    _loadConnectedPrinters();
  }

  // ==================== LOAD USER DETAILS (from CaptainLocalStorage) ====================
  Future<void> _loadUserDetails() async {
    try {
      // ✅ Use Provider to get the concrete CaptainLocalStorage instance
      final captainStorage = Provider.of<CaptainLocalStorage>(context, listen: false);
      final captainData = await captainStorage.getCaptainData();

      if (captainData != null && captainData.data != null) {
        final data = captainData.data!;
        setState(() {
          _displayName = data.displayName ?? '';
          _role = data.role ?? '';
          _userId = data.id?.toString() ?? '';
          _token = data.token ?? '';
        });

        // ─── Print to console ──────────────────────────────────────────
        print('══════════════ CAPTAIN DETAILS ══════════════');
        print('Display Name: ${data.displayName}');
        print('Role: ${data.role}');
        print('ID: ${data.id}');
        print('Token: ${data.token}');
        print('Restaurant Name: ${data.restaurantName}');
        print('Currency Symbol: ${data.currencySymbol}');
        print('══════════════════════════════════════════════');
      } else {
        // Fallback: SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _displayName = prefs.getString('display_name') ?? '';
          _role = prefs.getString('user_role') ?? '';
          _userId = prefs.getString('user_id') ?? '';
          _token = prefs.getString('auth_token') ?? '';
        });
        print('⚠️ No captain data found, using SharedPreferences fallback.');
      }
    } catch (e) {
      debugPrint('Error loading captain details: $e');
      // Final fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _displayName = prefs.getString('display_name') ?? '';
          _role = prefs.getString('user_role') ?? '';
          _userId = prefs.getString('user_id') ?? '';
          _token = prefs.getString('auth_token') ?? '';
        });
      } catch (_) {}
    }
  }

  // ==================== LOAD / SAVE SETTINGS ====================
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
      _selectedTheme = prefs.getString('selected_theme') ?? 'Light';
      _photoBase64 = prefs.getString('photoBase64');
      _photoBytes = _photoBase64 != null ? base64Decode(_photoBase64!) : null;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('selected_language', _selectedLanguage);
    await prefs.setString('selected_theme', _selectedTheme);
    if (_photoBase64 != null) {
      await prefs.setString('photoBase64', _photoBase64!);
    }
  }

  // ==================== PRINTER DB METHODS ====================
  Future<void> _loadConnectedPrinters() async {
    if (_isLoadingPrinters) return;
    setState(() => _isLoadingPrinters = true);

    try {
      final printerDb = PrinterDBHelper();
      final dbPrinters = await printerDb.getAllPrintersFromDB();
      List<PrinterSelection> tempPrinters = [];

      if (dbPrinters.isNotEmpty) {
        for (var printer in dbPrinters) {
          final deviceName =
              printer['deviceName'] ?? printer['device_name'] ?? 'Unknown';
          final address = printer['printer_address'] ?? '';
          final port = printer['port'] ?? '9100';
          final isSelected = (printer['is_selected'] ?? 1) == 1;
          final type = printer['printer_type'] ?? 'network';
          final vendorId = printer['vendor_id']?.toString();
          final productId = printer['product_id']?.toString();

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

      // Load network printers from shared preferences (backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      final savedPrinters = prefs.getString('network_printers');
      if (savedPrinters != null && savedPrinters.isNotEmpty) {
        try {
          final List<dynamic> printerList = jsonDecode(savedPrinters);
          for (var printer in printerList) {
            final ip = printer['ip'] ?? '';
            final port = printer['port'] ?? '9100';
            final name = printer['name'] ?? 'Network Printer';
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

      // Assign proper names based on index
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
            type: printer.type,
            vendorId: printer.vendorId,
            productId: printer.productId,
          );
        }
      }

      setState(() {
        _connectedPrinters = tempPrinters;
        _isLoadingPrinters = false;
      });
    } catch (e) {
      debugPrint("Error loading connected printers: $e");
      setState(() => _isLoadingPrinters = false);
    }
  }

  String _getPrinterName(int index, String defaultName) {
    if (index == 0) return "KOT Printer";
    if (index == 1) return "Cash Printer";
    return "Printer ${index + 1}";
  }

  // ==================== DIALOGS ====================
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                setState(() => _selectedLanguage = 'English');
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              onTap: () {
                setState(() => _selectedLanguage = 'Spanish');
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('French'),
              onTap: () {
                setState(() => _selectedLanguage = 'French');
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              onTap: () {
                setState(() => _selectedTheme = 'Light');
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              onTap: () {
                setState(() => _selectedTheme = 'Dark');
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('System Default'),
              onTap: () {
                setState(() => _selectedTheme = 'System');
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── ✨ polished custom dialog for Help & Support ──────────
  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCDD2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFFC62828),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Contact us for any assistance or inquiries.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF737373),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.email_outlined, color: Color(0xFF1A1A1A), size: 18),
                    SizedBox(width: 12),
                    Text(
                      'support@restaurantapp.com',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ✨ polished custom dialog for About App ──────────────
  void _showAboutAppDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFB2EBF2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF00838F),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'About App',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        Text(
                          '${snapshot.data!.appName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version ${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF737373),
                          ),
                        ),
                      ],
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    // Colors matching the screenshot
    const Color backgroundColor = Color(0xFFF7F7F7);
    const Color cardColor = Colors.white;
    const Color primaryTextColor = Color(0xFF1A1A1A);
    const Color secondaryTextColor = Color(0xFF8A8A8A);
    const Color switchActiveColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: primaryTextColor,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: primaryTextColor,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== PROFILE ====================
            _buildSectionHeader('PROFILE'),
            const SizedBox(height: 8),
            _buildProfileCard(),
            const SizedBox(height: 24),

            // ==================== GENERAL SETTINGS ====================
            _buildSectionHeader('GENERAL SETTINGS'),
            const SizedBox(height: 8),
            _buildSettingsCard(
              children: [
                _buildSettingTile(
                  icon: Icons.language,
                  iconBgColor: const Color(0xFFFFE0B2),
                  iconColor: const Color(0xFFE65100),
                  title: 'Language',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedLanguage,
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: secondaryTextColor),
                    ],
                  ),
                  onTap: _showLanguageDialog,
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.nightlight_round,
                  iconBgColor: const Color(0xFFE1BEE7),
                  iconColor: const Color(0xFF7B1FA2),
                  title: 'Themes',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedTheme,
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: secondaryTextColor),
                    ],
                  ),
                  onTap: _showThemeDialog,
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.volume_up_rounded,
                  iconBgColor: const Color(0xFFC8E6C9),
                  iconColor: const Color(0xFF2E7D32),
                  title: 'Sound',
                  trailing: Switch(
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() => _soundEnabled = value);
                      _saveSettings();
                    },
                    activeColor: switchActiveColor,
                    activeTrackColor: switchActiveColor.withOpacity(0.4),
                  ),
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.vibration,
                  iconBgColor: const Color(0xFFFFECB3),
                  iconColor: const Color(0xFFF9A825),
                  title: 'Vibration',
                  trailing: Switch(
                    value: _vibrationEnabled,
                    onChanged: (value) {
                      setState(() => _vibrationEnabled = value);
                      _saveSettings();
                    },
                    activeColor: switchActiveColor,
                    activeTrackColor: switchActiveColor.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ==================== PRINTER ====================
            _buildSectionHeader('PRINTER'),
            const SizedBox(height: 8),
            _buildSettingsCard(
              children: [
                _buildSettingTile(
                  icon: Icons.print_rounded,
                  iconBgColor: const Color(0xFFBBDEFB),
                  iconColor: const Color(0xFF1565C0),
                  title: 'Printer Connection',
                  subtitle: _connectedPrinters.isEmpty
                      ? 'No Printer Connected'
                      : '${_connectedPrinters.length} Printer${_connectedPrinters.length > 1 ? 's' : ''} Connected',
                  subtitleColor: _connectedPrinters.isEmpty
                      ? secondaryTextColor
                      : const Color(0xFF2E7D32),
                  trailing: const Icon(Icons.chevron_right, color: secondaryTextColor),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrinterSetup()),
                    );
                    await _loadConnectedPrinters();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ==================== NOTIFICATIONS ====================
            _buildSectionHeader('NOTIFICATIONS'),
            const SizedBox(height: 8),
            _buildSettingsCard(
              children: [
                _buildSettingTile(
                  icon: Icons.notifications_rounded,
                  iconBgColor: const Color(0xFFB3E5FC),
                  iconColor: const Color(0xFF0277BD),
                  title: 'Notifications',
                  trailing: const Icon(Icons.chevron_right, color: secondaryTextColor),
                  onTap: () {
                    setState(() => _notificationsEnabled = !_notificationsEnabled);
                    _saveSettings();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ==================== HELP & SUPPORT ====================
            _buildSectionHeader('HELP & SUPPORT'),
            const SizedBox(height: 8),
            _buildSettingsCard(
              children: [
                _buildSettingTile(
                  icon: Icons.help_outline_rounded,
                  iconBgColor: const Color(0xFFFFCDD2),
                  iconColor: const Color(0xFFC62828),
                  title: 'Help & Support',
                  trailing: const Icon(Icons.chevron_right, color: secondaryTextColor),
                  onTap: _showHelpSupportDialog,
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.info_outline_rounded,
                  iconBgColor: const Color(0xFFB2EBF2),
                  iconColor: const Color(0xFF00838F),
                  title: 'About App',
                  trailing: const Icon(Icons.chevron_right, color: secondaryTextColor),
                  onTap: _showAboutAppDialog,
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==================== UI HELPERS ====================
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9E9E9E),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage:
            _photoBytes != null ? MemoryImage(_photoBytes!) : null,
            backgroundColor: Colors.grey.shade300,
            child: _photoBytes == null
                ? Text(
              _displayName.isNotEmpty
                  ? _displayName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName.isNotEmpty ? _displayName : 'User',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _role.isNotEmpty ? _role : 'Captain',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: subtitleColor ?? const Color(0xFF8A8A8A),
        ),
      )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
  }
}