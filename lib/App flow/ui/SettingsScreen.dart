// settings_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/UserPermissions.dart';
import '../../utils/SessionManager.dart';
import '../widgets/top_bar.dart';

class SettingsScreen extends StatefulWidget {
  final String token;
  final String pin;

  const SettingsScreen({super.key, required this.token, required this.pin});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserPermissions? _userPermissions;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _language;
  String? _currency;
  String? _timeZone;
  bool _emailNotification = false;
  bool _soundNotification = true;
  String? _photoBase64;
  String? _logoBase64;
  Uint8List? _photoBytes;
  Uint8List? _logoBytes;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadSavedSettings();
  }

  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
      });
    }
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final photoB64 = prefs.getString('photoBase64');
    final logoB64 = prefs.getString('logoBase64');

    setState(() {
      _businessNameController.text = prefs.getString('businessName') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _contactController.text = prefs.getString('contact') ?? '';
      _addressController.text = prefs.getString('address') ?? '';
      _language = prefs.getString('language');
      _currency = prefs.getString('currency');
      _timeZone = prefs.getString('timeZone');
      _emailNotification = prefs.getBool('emailNotification') ?? false;
      _soundNotification = prefs.getBool('soundNotification') ?? true;
      _photoBase64 = photoB64;
      _logoBase64 = logoB64;
      _photoBytes = photoB64 != null ? base64Decode(photoB64) : null;
      _logoBytes = logoB64 != null ? base64Decode(logoB64) : null;
    });
  }

  Future<void> _pickImage(bool isPhoto) async {
    try {
      final XFile? picked =
      await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);

      setState(() {
        if (isPhoto) {
          _photoBase64 = base64Str;
          _photoBytes = bytes;
        } else {
          _logoBase64 = base64Str;
          _logoBytes = bytes;
        }
      });
    } catch (e) {
      debugPrint('Image pick error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Widget _imageFromBytes(Uint8List? bytes, double width, double height,
      {IconData placeholder = Icons.add_a_photo_outlined}) {
    if (bytes == null) {
      return Center(
        child: Icon(placeholder, color: Colors.grey, size: 40),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(bytes, width: width, height: height, fit: BoxFit.cover),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('businessName', _businessNameController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('contact', _contactController.text);
    await prefs.setString('address', _addressController.text);
    if (_language != null) await prefs.setString('language', _language!);
    if (_currency != null) await prefs.setString('currency', _currency!);
    if (_timeZone != null) await prefs.setString('timeZone', _timeZone!);
    await prefs.setBool('emailNotification', _emailNotification);
    await prefs.setBool('soundNotification', _soundNotification);
    if (_photoBase64 != null) await prefs.setString('photoBase64', _photoBase64!);
    if (_logoBase64 != null) await prefs.setString('logoBase64', _logoBase64!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentMaxWidth = screenWidth > 1100 ? 1500.0 : screenWidth - 40.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3FC),
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        userPermissions: _userPermissions,
        onPermissionsReceived: (permissions) {
          setState(() => _userPermissions = permissions);
        },
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: contentMaxWidth,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_back, size: 18),
                            SizedBox(width: 5),
                            Text(
                              'Back',
                              style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Tabs
                    _buildTabs(),

                    const Spacer(),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _saveSettings,
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column (fixed width)
                      SizedBox(
                        width: 240,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Upload photo box
                            GestureDetector(
                              onTap: () => _pickImage(true),
                              child: DottedBorder(
                                color: Colors.grey.shade300,
                                strokeWidth: 1.6,
                                dashPattern: const [6, 5],
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(10),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                  ),
                                  child: _imageFromBytes(_photoBytes, 120, 120),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Upload",
                              style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Please Upload a Clear Photo\nAccepted formats: JPG, PNG · Max size: 5MB",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 22),

                            // Logo Upload
                            GestureDetector(
                              onTap: () => _pickImage(false),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F6F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border:
                                        Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: _imageFromBytes(_logoBytes, 38, 38,
                                          placeholder: Icons.image),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        "Please Upload your logo here",
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 40),

                      // Right column (expands)
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_businessNameController, "Business Name")),
                                const SizedBox(width: 20),
                                Expanded(child: _buildTextField(_contactController, "Contact Info")),
                              ],
                            ),
                            const SizedBox(height: 23),

                            Row(
                              children: [
                                Expanded(child: _buildTextField(_emailController, "Email")),
                                const SizedBox(width: 20),
                                Expanded(child: _buildTextField(_addressController, "Address")),
                              ],
                            ),
                            const SizedBox(height: 23),

                            Row(
                              children: [
                                Expanded(child: _buildDropdown("Language", _language, (v) => setState(() => _language = v))),
                                const SizedBox(width: 20),
                                Expanded(child: _buildDropdown("Currency", _currency, (v) => setState(() => _currency = v))),
                              ],
                            ),
                            const SizedBox(height: 23),

                            Row(
                              children: [
                                Expanded(child: _buildDropdown("Time Zone", _timeZone, (v) => setState(() => _timeZone = v))),
                              ],
                            ),
                            const SizedBox(height: 33),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Notification",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  CheckboxListTile(
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("Email Notification"),
                                    subtitle: const Text(
                                        "You will be notified when a new email arrives."),
                                    value: _emailNotification,
                                    onChanged: (val) =>
                                        setState(() => _emailNotification = val ?? false),
                                  ),
                                  CheckboxListTile(
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("Sound Notification"),
                                    subtitle: const Text(
                                        "You will be notified with sound when someone messages you."),
                                    value: _soundNotification,
                                    onChanged: (val) =>
                                        setState(() => _soundNotification = val ?? false),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 26),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "App Version 1.0.417+1",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final List<String> labels = ["General", "Payment", "Devices", "Advanced"];
    final String selectedLabel = "General";

    return Row(
      children: labels.map((label) {
        final bool selected = label == selectedLabel;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF002E63), Color(0xFF005DC9)],
              )
                  : null,
              color: selected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(1, 1),
                  spreadRadius: 0,
                )
              ]
                  : [],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontSize: 15,
                fontFamily: 'Manrope',
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      validator: (val) {
        if (label == "Business Name" && (val == null || val.trim().isEmpty)) {
          return 'Please enter your full name';
        }
        if (label == "Email" && val != null && val.isNotEmpty) {
          final emailRegex = RegExp(r'^\S+@\S+\.\S+$');
          if (!emailRegex.hasMatch(val)) return 'Please enter a valid email';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown(
      String label, String? value, ValueChanged<String?> onChanged) {
    final options = _getOptionsForLabel(label);
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: options
          .map((o) => DropdownMenuItem<String>(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }

  List<String> _getOptionsForLabel(String label) {
    switch (label) {
      case "Language":
        return ["English", "Spanish", "French", "Hindi"];
      case "Currency":
        return ["USD", "EUR", "INR", "GBP"];
      case "Time Zone":
        return ["UTC", "GMT+5:30", "EST", "PST"];
      default:
        return ["Option 1", "Option 2"];
    }
  }
}
