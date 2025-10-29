import 'package:flutter/material.dart';

class TipPopup extends StatefulWidget {
  const TipPopup({super.key});

  @override
  State<TipPopup> createState() => _TipPopupState();
}

class _TipPopupState extends State<TipPopup> {
  final TextEditingController _tipController = TextEditingController();
  int? selectedTip;

  final List<int> tipOptions = [10, 20, 50, 100];

  void _onNumberPressed(String value) {
    setState(() {
      _tipController.text += value;
      selectedTip = null;
    });
  }

  void _onClear() {
    setState(() {
      _tipController.clear();
      selectedTip = null;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_tipController.text.isNotEmpty) {
        _tipController.text =
            _tipController.text.substring(0, _tipController.text.length - 1);
      }
    });
  }

  Widget _buildTipButton(int value) {
    final bool isSelected = selectedTip == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTip = value;
          _tipController.text = value.toString();
        });
      },
      child: Container(
        width: 80,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Color(0xFF4C81F1),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(2, 2),
              blurRadius: 3,
            )
          ],
        ),
        child: Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String label,
      {Color? color, VoidCallback? onPressed, Color? borderColor}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFFF3F5FF),
        foregroundColor: Colors.black,
        minimumSize: const Size(70, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor ?? Colors.transparent, width: 1),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        // side: const BorderSide(color: Colors.blueAccent, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 850,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ---------- Header ----------
              Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Title
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Tip",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Close Button on the Right
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF94438), // red background
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),

              const Text(
                "Add tip for",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 50),

              // ---------- Body ----------
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------- Left: Tip Selection ----------
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 15,
                            runSpacing: 15,
                            children: tipOptions
                                .map((e) => _buildTipButton(e))
                                .toList(),
                          ),
                          const SizedBox(height: 25),
                          const Text(
                            "Add Custom Tip :",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _tipController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: "Please enter amount",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 25),
                          ElevatedButton(
                            onPressed: () {
                              if (_tipController.text.isNotEmpty) {
                                Navigator.pop(context, true); // return true
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              "Save & Continue",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),

                        ],
                      ),
                    ),

                    const SizedBox(width: 40),
                    const SizedBox(height: 25),

                    // ---------- Right: Number Pad ----------
                    Expanded(
                      flex: 1,
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        // 👇 Adjust this ratio to control button height
                        childAspectRatio: 3, // smaller value = taller buttons
                        children: [
                          for (var i = 1; i <= 9; i++)
                            _buildKeypadButton(
                              i.toString(),
                              onPressed: () => _onNumberPressed(i.toString()),
                            ),
                          _buildKeypadButton(
                            "Clear",
                            color: Colors.white,
                            onPressed: _onClear,
                            borderColor: const Color(0xFFFF4D20), // Added border color
                          ),

                          _buildKeypadButton(
                            "0",
                            onPressed: () => _onNumberPressed("0"),
                          ),
                          _buildKeypadButton(
                            "⌫",
                            onPressed: _onBackspace,
                          ),
                        ],
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
}
