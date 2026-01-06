import 'package:flutter/material.dart';

class SplitPaymentPopup extends StatefulWidget {
  const SplitPaymentPopup({super.key});

  @override
  State<SplitPaymentPopup> createState() => _SplitPaymentPopupState();
}

class _SplitPaymentPopupState extends State<SplitPaymentPopup> {
  final TextEditingController payableController = TextEditingController();
  final TextEditingController splitController = TextEditingController();
  final TextEditingController perCustomerController = TextEditingController();

  String activeField = 'split';

  @override
  void dispose() {
    payableController.dispose();
    splitController.dispose();
    perCustomerController.dispose();
    super.dispose();
  }

  void _onKeyTap(String value) {
    setState(() {
      final controller = _getActiveController();
      controller.text += value;

      if (activeField == 'split' || activeField == 'payable') {
        _recalculate();
      }
    });
  }

  void _clear() {
    setState(() {
      _getActiveController().clear();
      perCustomerController.clear();
    });
  }

  TextEditingController _getActiveController() {
    switch (activeField) {
      case 'payable':
        return payableController;
      case 'split':
      default:
        return splitController;
    }
  }

  void _recalculate() {
    final payable = double.tryParse(payableController.text) ?? 0;
    final split = int.tryParse(splitController.text) ?? 0;

    if (split > 0) {
      perCustomerController.text =
          (payable / split).toStringAsFixed(2);
    } else {
      perCustomerController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 390,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// 🔹 Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Column(
                  children: const [
                    Text(
                      'Split payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F6BFF),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Split the bill among multiple customers',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9AA4B2)),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFFF4D4D),
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔹 Payable
            _label('Payable Amt :'),
            const SizedBox(height: 6),
            _dynamicInputBox(
              controller: payableController,
              onTap: () => activeField = 'payable',
            ),

            const SizedBox(height: 12),

            /// 🔹 Split Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('No. Split ways :'),
                      const SizedBox(height: 6),
                      _dynamicInputBox(
                        controller: splitController,
                        onTap: () => activeField = 'split',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Per cust. :'),
                      const SizedBox(height: 6),
                      _dynamicInputBox(
                        controller: perCustomerController,
                        enabled: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔹 Number Pad
            GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (context, index) {
                if (index == 9) {
                  return _actionButton(
                    'Clear',
                    Colors.red,
                    outlined: true,
                    onTap: _clear,
                  );
                }
                if (index == 11) {
                  return _actionButton(
                    'Add',
                    const Color(0xFF3B4A66),
                    onTap: () {
                      Navigator.pop(context, {
                        'payable': payableController.text,
                        'splits': splitController.text,
                        'perCustomer': perCustomerController.text,
                      });
                    },
                  );

                }

                final text = index == 10 ? '0' : '${index + 1}';
                return _numberButton(text);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 UI Helpers

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  );

  Widget _dynamicInputBox({
    required TextEditingController controller,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF4F7FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDCE3EE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDCE3EE)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  Widget _numberButton(String text) {
    return GestureDetector(
      onTap: () => _onKeyTap(text),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE3EE)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _actionButton(
      String text,
      Color color, {
        required VoidCallback onTap,
        bool outlined = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: outlined ? color : Colors.white,
          ),
        ),
      ),
    );
  }
}
