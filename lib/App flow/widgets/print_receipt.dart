import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrintRecipt extends StatefulWidget {
  PrintRecipt({Key? key}) : super(key: key);

  @override
  State<PrintRecipt> createState() => _PrintReciptState();
}

class _PrintReciptState extends State<PrintRecipt> {
  String _selectedOption = '';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  final List<String> options = ['Printer', 'Email', 'SMS'];

  void _onDonePressed() {
    if (_selectedOption == 'Email') {
      final email = _emailController.text.trim();
      if (email.isNotEmpty && email.contains("@")) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment details sent to $email")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a valid email address")),
        );
      }
    }
    if (_selectedOption == 'SMS') {
      final sms = _smsController.text.trim();
      if (sms.isNotEmpty && (sms.length == 10)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Payment details sent to $sms")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a valid phone number")),
        );
      }
    }
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



