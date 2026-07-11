import 'package:flutter/material.dart';

import '../../repositories/TIP_repository.dart';
import '../../utils/SessionManager.dart';

class TipPopup extends StatefulWidget {
  final int orderId;
  final String token;
  final Function(double) onTipApplied;

  const TipPopup({
    super.key,
    required this.orderId,
    required this.token,
    required this.onTipApplied,
  });

  @override
  State<TipPopup> createState() => _TipPopupState();
}



class _TipPopupState extends State<TipPopup> {
  final TextEditingController _tipController = TextEditingController();
  int? selectedTip;
  bool _isLoading = false;
  final TipRepository _tipRepository = TipRepository();
  String _currencySymbol = "₹";
  final List<int> tipOptions = [10, 20, 50, 100];
  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final symbol = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currencySymbol = symbol;
      });
    }
  }
  void _onNumberPressed(String value) {
    setState(() {
      String currentText = _tipController.text.replaceAll(',', '');

      // Remove .00 before appending a new digit
      if (currentText.contains('.')) {
        currentText = currentText.split('.').first;
      }

      currentText += value;

      final amount = double.tryParse(currentText) ?? 0.0;
      _tipController.text = amount.toStringAsFixed(2);

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
      String currentText = _tipController.text;

      if (currentText.contains('.')) {
        currentText = currentText.split('.').first;
      }

      if (currentText.isNotEmpty) {
        currentText = currentText.substring(0, currentText.length - 1);

        if (currentText.isEmpty) {
          _tipController.clear();
        } else {
          _tipController.text =
              (double.tryParse(currentText) ?? 0).toStringAsFixed(2);
        }
      }

      selectedTip = null;
    });
  }

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }
  Future<void> _applyTip() async {
    if (_tipController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter tip amount'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1)),
      );
      return;
    }

    final amount = double.tryParse(_tipController.text) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid tip amount'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _tipRepository.addTip(
        token: widget.token,
        orderId: widget.orderId,
        amount: amount,
      );

      if (!mounted) return;

      if (success) {
        widget.onTipApplied(amount);

        Navigator.pop(context, amount);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip added successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add tip'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          // value.toString(),
          "$_currencySymbol${value.toDouble().toStringAsFixed(2)}",
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

              // const Text(
              //   "Add tip for",
              //   style: TextStyle(color: Colors.grey, fontSize: 14),
              // ),
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
                              prefixText: "$_currencySymbol ",
                              hintText: "Please enter amount",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),                          const SizedBox(height: 25),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _applyTip,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              "Save & Continue",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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