import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DiscountPopup extends StatefulWidget {
  const DiscountPopup({super.key});

  @override
  State<DiscountPopup> createState() => _DiscountPopupState();
}

class _DiscountPopupState extends State<DiscountPopup> {
  int? _selectedRadio = 1;
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();

  void _handleRadioValueChange(int? value) {
    setState(() {
      _selectedRadio = value;
    });
  }

  void _handleKeyPress(String value) {
    setState(() {
      TextEditingController targetController =
      _selectedRadio == 1 ? _controller1 : _controller2;

      if (value == "Clear") {
        targetController.clear();
      } else if (value == "⌫") {
        if (targetController.text.isNotEmpty) {
          targetController.text = targetController.text.substring(
            0,
            targetController.text.length - 1,
          );
        }
      } else {
        targetController.text += value;
      }
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      //insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.65,
        child: Padding(
          padding: EdgeInsets.all(0),
          child: Column(
            children: [
              // Header with title and close
              Container(
                width: double.infinity,
                height: 30,
                padding: EdgeInsets.symmetric(horizontal: 0),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Discount",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Add discounts using a percentage or amount, with an optional reason and real-time total preview.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF4C5F7D)),
              ),
              SizedBox(height: 10),

              // Body
              Expanded(
                child: Row(
                  children: [
                    // Left side
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Food",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF373535),
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Radio<int>(
                                  value: 1,
                                  groupValue: _selectedRadio,
                                  onChanged: _handleRadioValueChange,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Percent",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                    _selectedRadio == 1
                                        ? Color(0xFF3649FC)
                                        : Color(0xFFBCBDBD),
                                  ),
                                ),
                                SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  height: 37,
                                  child: TextFormField(
                                    controller: _controller1,
                                    decoration: InputDecoration(
                                      labelText: '%',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                                Radio<int>(
                                  value: 2,
                                  groupValue: _selectedRadio,
                                  onChanged: _handleRadioValueChange,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Amount",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                    _selectedRadio == 2
                                        ? Color(0xFF3649FC)
                                        : Color(0xFFBCBDBD),
                                  ),
                                ),
                                SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  height: 37,
                                  child: TextFormField(
                                    controller: _controller2,
                                    decoration: InputDecoration(
                                      labelText: 'Rs',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Text(
                              "Add discount reason",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4C5F7D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: 380,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 15,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            Row(
                              children: [
                                _buildTag("Regular Customer"),
                                SizedBox(width: 10),
                                _buildTag("New Customer"),
                                SizedBox(width: 10),
                                _buildTag("Coupon Discount"),
                              ],
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: 380,
                              height: 38,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Color(0xFFFE6464),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  shadowColor: Colors.grey.withOpacity(0.5),
                                  elevation: 3,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  "Save & Continue",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right side - NumberPad
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: NumberPad(onKeyPressed: _handleKeyPress),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildTag(String text) {
    return Container(
      width: 90,
      height: 30,
      decoration: BoxDecoration(
        color: Color(0xFF4C81F1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 10)),
      ),
    );
  }
}

// Reuse your NumberPad
class NumberPad extends StatelessWidget {
  final Function(String) onKeyPressed;

  NumberPad({super.key, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(["1", "2", "3"]),
        _buildRow(["4", "5", "6"]),
        _buildRow(["7", "8", "9"]),
        _buildFinalRow(),
      ],
    );
  }

  Widget _buildRow(List<String> labels) {
    return Row(children: labels.map((label) => _buildButton(label)).toList());
  }

  Widget _buildButton(
      String label, {
        int flex = 1,
        Color? backgroundColor,
        Color? textColor,
        BoxBorder? border,
      }) {
    final bool isNumber = RegExp(r'^\d+$').hasMatch(label);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => onKeyPressed(label),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isNumber ? 24 : 18,
                fontWeight: isNumber ? FontWeight.w600 : FontWeight.bold,
                color:
                textColor ??
                    (isNumber ? Color(0xFF4C5F7D) : Color(0xFFE64646)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton(
          "Clear",
          // Optional styling overrides if needed
          // backgroundColor: Colors.red[50],
          // textColor: Colors.red,
        ),
        _buildButton("0"),
        _buildButton(
          "⌫",
          // textColor: Colors.red,
        ),
      ],
    );
  }
}
