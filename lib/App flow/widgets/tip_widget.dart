import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/TIP_repository.dart';
import '../../utils/SessionManager.dart';
import '../../utils/theme_provider.dart';

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
  final List<int> tipOptions = [50, 100, 150, 200];
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

  Widget _buildTipButton(int value, bool isDark) {
    final bool isSelected = selectedTip == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTip = value;
          _tipController.text = value.toDouble().toStringAsFixed(2);
        });
      },
      child: Container(
        width: 140,
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2353B7)
              : (isDark
              ? const Color(0xFF374151)
              : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2353B7)
                : (isDark
                ? const Color(0xFF4B5563)
                : const Color(0xFFD1D5DB)),
          ),
        ),
        child: Text(
          "$_currencySymbol${value.toDouble().toStringAsFixed(2)}",
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white : Colors.black),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  Widget _buildKeypadButton(
      String label, {
        Color? color,
        VoidCallback? onPressed,
        Color? borderColor,
      }) {
    final bool isClear = label == "Clear";
    final bool isBack = label == "⌫";
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: isDark
            ? []
            : const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 5,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ??
              (isClear || isBack
                  ? (isDark
                  ? const Color(0xFF34384F)
                  : Colors.white)
                  : (isDark
                  ? const Color(0xFF2B3042)
                  : const Color(0xFFF1F5FF))),
          foregroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: borderColor ??
                  (isClear
                      ? const Color(0xFFFF4D20)
                      : isBack
                      ? (isDark
                      ? Colors.white24
                      : const Color(0xFF4C5F7D))
                      : (isDark
                      ? Colors.white24
                      : Colors.transparent)),
              width: 1,
            ),
          ),
        ),
        child: isBack
            ? Icon(
          Icons.backspace_outlined,
          color: isDark
              ? Colors.white
              : const Color(0xFF4C5F7D),
          size: 25,
        )
            : Text(
          label,
          style: TextStyle(
            fontSize: isClear ? 16 : 18,
            fontWeight: FontWeight.w500,
            color: isClear
                ? const Color(0xFFFE6464)
                : (isDark
                ? Colors.white
                : const Color(0xFF4C5F7D)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDark;
    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1F2937)
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFDFDFDF),
            ),
          ),

          child: Padding(
            padding: const EdgeInsets.all(30),
            child: SizedBox(
              width: 650,
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ---------- Header ----------
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDFFF8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF7CCABB),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            "assets/Tips Icon.png",
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tip",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Add a tip to show your appreciation for exceptional service",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF7C7C7C),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF84337),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,color: Colors.white),
                        ),
                      )
                    ],
                  ),

                  // const Text(
                  //   "Add tip for",
                  //   style: TextStyle(color: Colors.grey, fontSize: 14),
                  // ),
                  const SizedBox(height: 20),

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
                                spacing: 30,
                                runSpacing: 20,
                                children: tipOptions
                                    .map((e) => _buildTipButton(e, isDark))
                                    .toList(),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "Add Custom Tip :",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF374151)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x19000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _tipController,
                                  readOnly: true,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    prefixText: "$_currencySymbol ",
                                    prefixStyle: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    hintText: "Please enter amount",
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF374151)
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF4B5563)
                                            : const Color(0xFF6D7A8F),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2353B7),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _applyTip,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF4CAF50),
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

                        const SizedBox(width: 20),
                        // const SizedBox(height: 25),

                        // ---------- Right: Number Pad ----------
                        Expanded(
                          flex: 1,
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                            crossAxisCount: 3,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 1.5, // smaller value = taller buttons
                            children: [
                              for (var i = 1; i <= 9; i++)
                                _buildKeypadButton(
                                  i.toString(),
                                  onPressed: () => _onNumberPressed(i.toString()),
                                ),
                              _buildKeypadButton(
                                "Clear",
                                color: isDark
                                    ? const Color(0xFF34384F)
                                    : Colors.white,
                                onPressed: _onClear,
                                borderColor: const Color(0xFFFF4D20),
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
        ));
  }
}