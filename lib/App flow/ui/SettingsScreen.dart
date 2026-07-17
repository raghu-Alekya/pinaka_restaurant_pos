// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:dotted_border/dotted_border.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../repositories/settings_repository.dart';
// import '../../utils/logger.dart';
//
// class SettingsScreen extends StatefulWidget {
//   final String token;
//   final String pin;
//   final String userId;
//   final String displayName;
//   final String role;
//
//   const SettingsScreen({
//     super.key,
//     required this.token,
//     required this.pin,
//     required this.userId,
//     required this.displayName,
//     required this.role,
//   });
//
//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }
//
// class _SettingsScreenState extends State<SettingsScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _contactController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _deviceIdController = TextEditingController();
//   final TextEditingController _companyController = TextEditingController();
//   final TextEditingController _gstinController = TextEditingController();
//   final TextEditingController _headerController = TextEditingController();
//   final TextEditingController _footerController = TextEditingController();
//
//   Uint8List? _photoBytes;
//   Uint8List? _logoBytes;
//   String? _photoBase64;
//   String? _logoBase64;
//   String? _selectedDefaultMethod;
//   Map<String, bool> _paymentSelections = {
//     "Cash": true,
//     "Card": true,
//     "UPI": true,
//     "Wallets": true,
//   };
//   Map<String, bool> _otherSelections = {
//     "Coupons": true,
//     "Tips": true,
//     "Payouts": true,
//   };
//   Map<String, bool> _orderTypeSelections = {
//     "Dine-in": true,
//     "Takeaway": true,
//   };
//   final ImagePicker _picker = ImagePicker();
//   String _selectedLabel = "General";
//   bool _isLoading = true;
//   final _settingsRepo = SettingsRepository();
//
//   @override
//   void initState() {
//     super.initState();
//     print("SettingsScreen initialized with:");
//     print("User ID: ${widget.userId}");
//     print("Display Name: ${widget.displayName}");
//     print("Role: ${widget.role}");
//     _fetchGeneralSettings();
//   }
//   Future<void> _fetchGeneralSettings() async {
//     AppLogger.info("🔹 Fetching General Settings for User ID: ${widget.userId}");
//
//     setState(() => _isLoading = true);
//
//     final result = await _settingsRepo.fetchGeneralSettings(
//       token: widget.token,
//       userId: widget.userId,
//     );
//
//     if (result["success"] == true) {
//       final userData = result["data"];
//
//       setState(() {
//         _fullNameController.text = userData["full_name"] ?? '';
//         _emailController.text = userData["email"] ?? '';
//         _contactController.text = userData["phone_number"] ?? '';
//         _deviceIdController.text = userData["user_device_id"] ?? '';
//         _companyController.text = userData["company_name"] ?? '';
//         _gstinController.text = userData["gstin"] ?? '';
//
//         if (userData["profile_url"] != null &&
//             userData["profile_url"].toString().isNotEmpty) {
//           _loadImageFromUrl(userData["profile_url"], isProfile: true);
//         }
//
//         if (userData["receipt_logo"] != null &&
//             userData["receipt_logo"].toString().isNotEmpty) {
//           _loadImageFromUrl(userData["receipt_logo"], isProfile: false);
//         }
//
//         _isLoading = false;
//       });
//     } else {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   /// 🔹 Load image from URL into memory
//   Future<void> _loadImageFromUrl(String url, {required bool isProfile}) async {
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final bytes = response.bodyBytes;
//         setState(() {
//           if (isProfile) {
//             _photoBytes = bytes;
//             _photoBase64 = base64Encode(bytes);
//           } else {
//             _logoBytes = bytes;
//             _logoBase64 = base64Encode(bytes);
//           }
//         });
//       }
//     } catch (e) {
//       print("Failed to load image: $e");
//     }
//   }
//
//   Future<void> _pickImage(bool isProfile) async {
//     try {
//       final XFile? picked = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//       );
//       if (picked == null) return;
//       final bytes = await picked.readAsBytes();
//       final base64Str = base64Encode(bytes);
//       setState(() {
//         if (isProfile) {
//           _photoBytes = bytes;
//           _photoBase64 = base64Str;
//         } else {
//           _logoBytes = bytes;
//           _logoBase64 = base64Str;
//         }
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Image selection failed')));
//     }
//   }
//
//   Future<void> _saveSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('header', _headerController.text);
//     await prefs.setString('footer', _footerController.text);
//     if (_logoBase64 != null) await prefs.setString('logoBase64', _logoBase64!);
//     await prefs.setString(
//       'selectedDefaultMethod',
//       _selectedDefaultMethod ?? '',
//     );
//     await prefs.setString('paymentSelections', jsonEncode(_paymentSelections));
//     await prefs.setString('otherSelections', jsonEncode(_otherSelections));
//     await prefs.setString('orderTypeSelections', jsonEncode(_orderTypeSelections));
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Settings saved successfully')),
//     );
//   }
//
//   Widget _photoBox(Uint8List? bytes) {
//     return DottedBorder(
//       color: Colors.black,
//       strokeWidth: 1.5,
//       dashPattern: const [6, 5],
//       borderType: BorderType.RRect,
//       radius: const Radius.circular(12),
//       child: Container(
//         width: 90,
//         height: 90,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           color: Colors.white,
//         ),
//         child: bytes == null
//             ? const Center(
//           child: Icon(
//             Icons.image_outlined,
//             size: 28,
//             color: Colors.black54,
//           ),
//         )
//             : ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Image.memory(bytes, fit: BoxFit.cover),
//         ),
//       ),
//     );
//   }
//
//   Widget _logoBox(Uint8List? bytes) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         GestureDetector(
//           onTap: () => _pickImage(false),
//           child: DottedBorder(
//             color: Colors.black,
//             strokeWidth: 1.5,
//             dashPattern: const [6, 5],
//             borderType: BorderType.RRect,
//             radius: const Radius.circular(12),
//             child: Container(
//               width: 90,
//               height: 90,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(12),
//                 color: Colors.white,
//               ),
//               child:
//               bytes == null
//                   ? const Center(
//                 child: Icon(
//                   Icons.add_photo_alternate_outlined,
//                   size: 28,
//                   color: Colors.black,
//                 ),
//               )
//                   : ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.memory(bytes, fit: BoxFit.cover),
//               ),
//             ),
//           ),
//         ),
//         if (bytes != null) ...[
//           const SizedBox(width: 12),
//           Column(
//             children: [
//               // Edit button
//               InkWell(
//                 onTap: () => _pickImage(false),
//                 borderRadius: BorderRadius.circular(6),
//                 child: Container(
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: const Icon(
//                     Icons.edit,
//                     color: Colors.black54,
//                     size: 20,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               // Delete button
//               InkWell(
//                 onTap: () {
//                   setState(() {
//                     _logoBytes = null;
//                     _logoBase64 = null;
//                   });
//                 },
//                 borderRadius: BorderRadius.circular(6),
//                 child: Container(
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: const Icon(
//                     Icons.delete,
//                     color: Colors.redAccent,
//                     size: 20,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ],
//     );
//   }
//
//   Widget _buildTabs() {
//     final List<String> labels = ["General", "Payment", "Advanced"];
//
//     return Row(
//       children:
//       labels.map((label) {
//         final bool selected = label == _selectedLabel;
//         return Padding(
//           padding: const EdgeInsets.only(right: 12),
//           child: GestureDetector(
//             onTap: () {
//               setState(() {
//                 _selectedLabel = label;
//               });
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 14,
//                 vertical: 7,
//               ),
//               decoration: BoxDecoration(
//                 gradient:
//                 selected
//                     ? const LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Color(0xFF002E63), Color(0xFF005DC9)],
//                 )
//                     : null,
//                 color: selected ? null : Colors.transparent,
//                 borderRadius: BorderRadius.circular(6),
//                 boxShadow:
//                 selected
//                     ? [
//                   const BoxShadow(
//                     color: Color(0x3F000000),
//                     blurRadius: 4,
//                     offset: Offset(1, 1),
//                   ),
//                 ]
//                     : [],
//               ),
//               child: Text(
//                 label,
//                 style: TextStyle(
//                   color: selected ? Colors.white : Colors.black,
//                   fontSize: 14,
//                   fontFamily: 'Manrope',
//                   fontWeight:
//                   selected ? FontWeight.w700 : FontWeight.normal,
//                 ),
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   Widget _buildField(
//       String label,
//       TextEditingController controller, {
//         String? hint,
//         bool readOnly = false,
//       }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//             fontSize: 15,
//           ),
//         ),
//         const SizedBox(height: 5),
//         TextFormField(
//           controller: controller,
//           readOnly: readOnly,
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: const Color(0xFFEDF2F6),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(6),
//               borderSide: const BorderSide(color: Color(0xFFE0E4EC)),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(6),
//               borderSide: const BorderSide(color: Color(0xFFE0E4EC)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(6),
//               borderSide: const BorderSide(
//                 color: Color(0xFFE0E4EC),
//                 width: 1.5,
//               ),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 14,
//               vertical: 12,
//             ),
//             hintText: hint,
//           ),
//           style: TextStyle(
//             color: readOnly ? Colors.grey[700] : Colors.black,
//           ),
//         ),
//       ],
//     );
//   }
//
//   // =================== MAIN BUILD ===================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6FC),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(22.0),
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               return SingleChildScrollView(
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                   child: IntrinsicHeight(
//                     child: Container(
//                       padding: const EdgeInsets.all(27),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // ===== Header =====
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 8,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFF4F6FB),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Row(
//                               children: [
//                                 // back button
//                                 Container(
//                                   height: 40,
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     border: Border.all(
//                                       color: Colors.grey.shade300,
//                                     ),
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   child: InkWell(
//                                     onTap: () => Navigator.pop(context),
//                                     borderRadius: BorderRadius.circular(10),
//                                     child: const Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Icon(Icons.arrow_back, size: 18),
//                                         SizedBox(width: 5),
//                                         Text(
//                                           'Back',
//                                           style: TextStyle(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 _buildTabs(),
//                                 const Spacer(),
//                                 ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.redAccent,
//                                     foregroundColor: Colors.white,
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 30,
//                                       vertical: 10,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                   onPressed: _saveSettings,
//                                   child: const Text("Save Changes"),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 22),
//
//                           // ===== Tab Content =====
//                           if (_selectedLabel == "General")
//                             _buildGeneralSection(),
//                           if (_selectedLabel == "Payment")
//                             _buildPaymentSection(),
//                           if (_selectedLabel == "Advanced")
//                             _buildAdvancedSection(),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildGeneralSection() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // LEFT COLUMN
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Personal Information",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//               ),
//               const SizedBox(height: 6),
//               const Text(
//                 "Change your personal information",
//                 style: TextStyle(color: Colors.grey, fontSize: 13),
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 children: [
//                   _photoBox(_photoBytes),
//                   const SizedBox(width: 20),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "User",
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           widget.role.isNotEmpty ? widget.role : "Role",
//                           style: const TextStyle(
//                             fontSize: 16,
//                             color: const Color(0xFF002E63),
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 25),
//               _buildField("Full Name", _fullNameController, readOnly: true),
//               const SizedBox(height: 18),
//               _buildField("Contact No.", _contactController, readOnly: true),
//               const SizedBox(height: 18),
//               _buildField("Email Address", _emailController, readOnly: true),
//               const SizedBox(height: 18),
//               _buildField("Device ID :", _deviceIdController, readOnly: true),
//               const SizedBox(height: 18),
//               FutureBuilder<PackageInfo>(
//                 future: PackageInfo.fromPlatform(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Text(
//                       "Loading version...",
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black54,
//                         fontSize: 15,
//                       ),
//                     );
//                   } else if (snapshot.hasError) {
//                     return const Text(
//                       "Version info not available",
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black54,
//                         fontSize: 15,
//                       ),
//                     );
//                   } else if (snapshot.hasData) {
//                     final packageInfo = snapshot.data!;
//                     final version = '${packageInfo.version}+${packageInfo.buildNumber}';
//                     return Text(
//                       "App Version $version",
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                         fontSize: 15,
//                       ),
//                     );
//                   } else {
//                     return const SizedBox();
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 50),
//
//         // RIGHT COLUMN
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Receipt Settings",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//               ),
//               const SizedBox(height: 6),
//               const Text(
//                 "Customise your own receipt",
//                 style: TextStyle(color: Colors.grey, fontSize: 14),
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 children: [
//                   _logoBox(_logoBytes),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: _buildField("Company Name", _companyController,readOnly: true),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               _buildField("GSTIN", _gstinController,readOnly: true),
//               const SizedBox(height: 20),
//               _buildField("Header", _headerController),
//               const SizedBox(height: 20),
//               _buildField("Footer", _footerController),
//               const SizedBox(height: 20),
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: const [
//                         Text(
//                           "Printer Settings",
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           "Connected Printer",
//                           style: TextStyle(color: Colors.black54),
//                         ),
//                       ],
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {},
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF007BFF),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 30,
//                         vertical: 8,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text(
//                       "+ Add",
//                       style: TextStyle(color: Colors.white, fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPaymentSection() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Payment Settings",
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 24),
//
//           const Text(
//             "Default Payment Method",
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 6),
//
//           DropdownButtonFormField<String>(
//             value: _selectedDefaultMethod != null &&
//                 _paymentSelections.containsKey(_selectedDefaultMethod)
//                 ? _selectedDefaultMethod
//                 : null,
//             items: _paymentSelections.keys
//                 .map((method) => DropdownMenuItem(
//               value: method,
//               child: Text(method),
//             ))
//                 .toList(),
//             onChanged: (val) {
//               setState(() {
//                 _selectedDefaultMethod = val;
//               });
//             },
//             decoration: InputDecoration(
//               hintText: "Select Payment Method",
//               filled: true,
//               fillColor: const Color(0xFFF4F6FB),
//               contentPadding:
//               const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 26),
//           const Text(
//             "Payment Methods",
//             style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 10),
//
//           Wrap(
//             spacing: 20,
//             runSpacing: 8,
//             children: [
//               for (var method in _paymentSelections.keys)
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Checkbox(
//                       value: _paymentSelections[method],
//                       onChanged:
//                           (val) =>
//                           setState(() => _paymentSelections[method] = val!),
//                       activeColor: Colors.black,
//                     ),
//                     Text(method, style: const TextStyle(fontSize: 14)),
//                   ],
//                 ),
//             ],
//           ),
//
//           const SizedBox(height: 30),
//           const Text(
//             "Other Options",
//             style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 10),
//
//           Wrap(
//             spacing: 20,
//             runSpacing: 8,
//             children: [
//               for (var opt in _otherSelections.keys)
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Checkbox(
//                       value: _otherSelections[opt],
//                       onChanged:
//                           (val) => setState(() => _otherSelections[opt] = val!),
//                       activeColor: Colors.black,
//                     ),
//                     Text(opt, style: const TextStyle(fontSize: 14)),
//                   ],
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAdvancedSection() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Advanced Settings",
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             "Order Type",
//             style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 10),
//           Wrap(
//             spacing: 20,
//             runSpacing: 8,
//             children: [
//               for (var opt in _orderTypeSelections.keys)
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Checkbox(
//                       value: _orderTypeSelections[opt],
//                       onChanged: (val) {
//                         setState(() => _orderTypeSelections[opt] = val!);
//                       },
//                       activeColor: Colors.black,
//                     ),
//                     Text(opt, style: const TextStyle(fontSize: 14)),
//                   ],
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/General_Settings_Model.dart';
import '../../printer/printer_setup_screen.dart';
import '../../printer/printer_db_helper.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/SessionManager.dart';

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
    // "Payouts": true,
  };
  Map<String, bool> _orderTypeSelections = {
    "Dine-in": true,
    "Takeaway": true,
  };
  final ImagePicker _picker = ImagePicker();
  String _selectedLabel = "General";
  String? _connectedPrinterName;
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
    _loadConnectedPrinter();
    _loadGeneralSettings();
  }
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

      final request = SaveGeneralSettingsRequest(
        headerText: _headerController.text.trim(),
        footerText: _footerController.text.trim(),
        printSettings: _connectedPrinterName ?? "",
        receiptLogoUrl: "", // Replace with uploaded logo URL if available
      );

      final response = await _settingsRepository.saveGeneralSettings(
        token: token,
        request: request,
      );

      // Save locally if required
      await _saveSettings();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      // Refresh data from server
      await _loadGeneralSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
  Future<void> _loadConnectedPrinter() async {
    try {
      final printerData = await PrinterDBHelper().getPrinterFromDB();
      if (printerData.isNotEmpty) {
        setState(() {
          _connectedPrinterName = printerData.first['deviceName'] ?? printerData.first['device_name'];
        });
      } else {
        setState(() {
          _connectedPrinterName = null;
        });
      }
    } catch (e) {
      debugPrint("Error loading connected printer: $e");
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

      // Upload image to WordPress
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
      const SnackBar(content: Text('Settings saved successfully'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,),
    );
  }

  Widget _photoBox(Uint8List? bytes) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _pickImage(true), // ✅ Profile image
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
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.black54,
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
                    border: Border.all(color: Colors.grey.shade300),
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

  Widget _logoBox(Uint8List? bytes, String? imageUrl,) {
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
              // Edit button
              InkWell(
                onTap: () => _pickImage(false),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Delete button
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
                    border: Border.all(color: Colors.grey.shade300),
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
    final List<String> labels = ["General","Payment", "Advanced"];

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
                  fontWeight:
                  selected ? FontWeight.w700 : FontWeight.normal,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly
                ? const Color(0xFFF5F5F5) // Grey background for non-editable fields
                : const Color(0xFFEDF2F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE0E4EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE0E4EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFFE0E4EC),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            hintText: hint,
          ),
        ),
      ],
    );
  }

  // =================== MAIN BUILD ===================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== Header =====
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6FB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                // back button
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
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

                          // ===== Tab Content =====
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COLUMN
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Personal Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                "Change your personal information",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _photoBox(_photoBytes),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      "Upload\nPlease Upload a Clear Photo\nAccepted formats: JPG, PNG · Max size: 5MB",
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _buildField("Full Name", _fullNameController,readOnly: true,),
              const SizedBox(height: 18),
              _buildField("Contact No.", _contactController,readOnly: true,),
              const SizedBox(height: 18),
              _buildField("Email Address", _emailController,readOnly: true,),
              const SizedBox(height: 18),
              _buildField("Device ID :", _deviceIdController,readOnly: true,),
              const SizedBox(height: 18),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      "Loading version...",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Text(
                      "Version info not available",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final packageInfo = snapshot.data!;
                    final version = '${packageInfo.version}+${packageInfo.buildNumber}';
                    return Text(
                      "App Version $version",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
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

        // RIGHT COLUMN
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Receipt Settings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                "Customise your own receipt",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _logoBox(
                    _logoBytes,
                    _receiptLogoUrl,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildField("Company Name", _companyController,readOnly: true,),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildField("GSTIN", _gstinController,readOnly: true,),
              const SizedBox(height: 20),
              _buildField("Header", _headerController),
              const SizedBox(height: 20),
              _buildField("Footer", _footerController),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Printer Settings",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              "Connected Printer: ",
                              style: TextStyle(color: Colors.black54),
                            ),
                            Text(
                              _connectedPrinterName ?? "None",
                              style: TextStyle(
                                color: _connectedPrinterName != null
                                    ? Colors.green
                                    : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrinterSetup(),
                        ),
                      );
                      _loadConnectedPrinter();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "+ Add",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Payment Settings",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),

          const Text(
            "Default Payment Method",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),

          DropdownButtonFormField<String>(
            value: _selectedDefaultMethod != null &&
                _paymentSelections.containsKey(_selectedDefaultMethod)
                ? _selectedDefaultMethod
                : null,
            items: _paymentSelections.keys
                .map((method) => DropdownMenuItem(
              value: method,
              child: Text(method),
            ))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedDefaultMethod = val;
              });
            },
            decoration: InputDecoration(
              hintText: "Select Payment Method",
              filled: true,
              fillColor: const Color(0xFFF4F6FB),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

          const SizedBox(height: 26),
          const Text(
            "Payment Methods",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                      onChanged:
                          (val) =>
                          setState(() => _paymentSelections[method] = val!),
                      activeColor: Colors.black,
                    ),
                    Text(method, style: const TextStyle(fontSize: 14)),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 30),
          const Text(
            "Other Options",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                      onChanged:
                          (val) => setState(() => _otherSelections[opt] = val!),
                      activeColor: Colors.black,
                    ),
                    Text(opt, style: const TextStyle(fontSize: 14)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Advanced Settings",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          const Text(
            "Order Type",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                      activeColor: Colors.black,
                    ),
                    Text(opt, style: const TextStyle(fontSize: 14)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}