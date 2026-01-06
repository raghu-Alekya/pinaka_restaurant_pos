import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../ui/tables_screen.dart';

class PrintRecipt extends StatefulWidget {
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final List<Map<String, dynamic>> loadedTables;
  final int? zoneId;

  const PrintRecipt({
    Key? key,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    required this.loadedTables,
    this.zoneId,
  }) : super(key: key);

  @override
  State<PrintRecipt> createState() => _PrintReciptState();
}


class _PrintReciptState extends State<PrintRecipt> {
  String _selectedOption = '';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  final List<String> options = ['Printer', 'Email', 'SMS'];

  void _onDonePressed() async {
    // 1️⃣ Validation
    if (_selectedOption == 'Email') {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains("@")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid email address")),
        );
        return;
      }
    }

    if (_selectedOption == 'SMS') {
      final sms = _smsController.text.trim();
      if (sms.isEmpty || sms.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid phone number")),
        );
        return;
      }
    }

    // ✅ STEP 1: CLOSE THE SUCCESS DIALOG
    Navigator.of(context).pop();

    // ✅ STEP 2: CLEAR ORDER STATE (CRITICAL)
    context.read<OrderBloc>().add(ClearOrder());

    // ⏳ Small delay ensures Bloc processes event before navigation
    await Future.delayed(const Duration(milliseconds: 100));

    // ✅ STEP 3: NAVIGATE TO TABLE SCREEN (FRESH STATE)
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => TablesScreen(
          loadedTables: widget.loadedTables,
          pin: widget.pin,
          token: widget.token,
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
          zoneId: widget.zoneId,
        ),
      ),
          (route) => false,
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      height: MediaQuery.of(context).size.height * 0.60,
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/icon/printer.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Please choose how you'd like to",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4C5F7D),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "share it.",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4C5F7D),
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children:
              options.map((option) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOption = option;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                      _selectedOption == option
                          ? Colors.red.shade50
                          : Colors.white,
                      border: Border.all(
                        color:
                        _selectedOption == option
                            ? Colors.redAccent
                            : Color(0xFFE7E2E2),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: option,
                          groupValue: _selectedOption,
                          onChanged: (value) {
                            setState(() {
                              _selectedOption = value!;
                            });
                          },
                          activeColor: Colors.redAccent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFAFACAC),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child:
                _selectedOption == 'Email'
                    ? _buildTextField(
                  hintText: 'Enter Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                )
                    : _selectedOption == 'SMS'
                    ? _buildTextField(
                  hintText: 'Enter phone number',
                  controller: _smsController,
                  keyboardType: TextInputType.number,
                )
                    : SizedBox.shrink(),
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDialogButton(
                  label: 'No Receipt',
                  color: Color(0xFFECEEF2),
                  textColor: Color(0xFF4C5F7D),
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(width: 20),
                _buildDialogButton(
                  label: 'Done',
                  color: Color(0xFF1BA672),
                  textColor: Colors.white,
                  onTap: _onDonePressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    List<TextInputFormatter> inputFormatters = [];

    if (keyboardType == TextInputType.number) {
      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ];
    } else if (keyboardType == TextInputType.emailAddress) {
      inputFormatters = [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._]')),
        LengthLimitingTextInputFormatter(32),
      ];
    }
    return Container(
      width: MediaQuery.of(context).size.width * 0.48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Color(0xFFE7E2E2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE7E2E2),
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}


