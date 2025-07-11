import 'package:flutter/material.dart';

class Checkinpopup extends StatefulWidget {
  final VoidCallback? onCheckIn;
  final VoidCallback? onCancel;

  const Checkinpopup({super.key, this.onCheckIn, this.onCancel});

  @override
  State<Checkinpopup> createState() => _CheckinpopupState();
}

class _CheckinpopupState extends State<Checkinpopup> {
  List<String> pinDigits = ['', '', '', ''];
  bool showError = false;

  void _onNumberTap(String number) {
    for (int i = 0; i < pinDigits.length; i++) {
      if (pinDigits[i].isEmpty) {
        setState(() {
          pinDigits[i] = number;
        });
        break;
      }
    }
  }

  void _onClear() {
    setState(() {
      pinDigits = ['', '', '', ''];
      showError = false;
    });
  }

  void _onCheckIn() {
    final pin = pinDigits.join();
    if (pin != '9999' && pin != '1234') {
      setState(() {
        showError = true;
      });
    } else {
      widget.onCheckIn?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Captain Check-In',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Enter your 4- Digit PIN for Check-In',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4C5F7D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              /// PIN and Keypad Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// PIN Entry (Left side)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PIN:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4C5F7D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            4,
                                (index) => Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 64,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: showError
                                      ? Colors.red
                                      : Colors.grey.shade400,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                pinDigits[index].isNotEmpty ? '*' : '',
                                style: const TextStyle(
                                  fontSize: 30,
                                  color: Color(0xFF4C5F7D),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (showError)
                          const Text(
                            'Please enter a valid PIN',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 25),

                        /// Check-In Button aligned under 3rd and 4th boxes
                        Padding(
                          padding: const EdgeInsets.only(left: 64 + 12 + 64 + 12),
                          child: SizedBox(
                            width: 140,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _onCheckIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'Check-In',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// Number Pad (Right side)
                  Column(
                    children: [
                      _buildNumRow(['1', '2', '3']),
                      _buildNumRow(['4', '5', '6']),
                      _buildNumRow(['7', '8', '9']),
                      _buildNumRow(['clear', '0']),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: values.map((val) {
          if (val == 'clear') {
            return _buildClearButton();
          } else {
            return _buildKey(val);
          }
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 84,
        height: 55,
        child: ElevatedButton(
          onPressed: () => _onNumberTap(value),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Color(0xFF4C5F7D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 179,
        height: 55,
        child: ElevatedButton(
          onPressed: _onClear,
          style: ElevatedButton.styleFrom(
            backgroundColor:Colors.red.shade400,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Clear',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
