import 'package:flutter/material.dart';

class SplitPaymentPopup extends StatefulWidget {
  const SplitPaymentPopup({super.key});

  @override
  State<SplitPaymentPopup> createState() => _SplitPaymentPopupState();
}

class _SplitPaymentPopupState extends State<SplitPaymentPopup> {
  double totalAmount = 2360.00;
  int splitCount = 1;

  void _onNumberTap(String value) {
    if (value == "C") {
      setState(() => splitCount = 1);
      return;
    }

    if (value == "0" && splitCount == 0) return;

    final newValue = int.tryParse("$splitCount$value");
    if (newValue != null) {
      setState(() => splitCount = newValue);
    }
  }

  double get perPersonAmount =>
      splitCount == 0 ? 0 : (totalAmount / splitCount);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Split payment",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),

              const SizedBox(height: 8),
              const Text(
                "Split the bill among multiple customers",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 16),

              _infoRow("Payable Amt :", "₹${totalAmount.toStringAsFixed(2)}"),
              const SizedBox(height: 8),
              _infoRow("No. Split :", "$splitCount"),
              const SizedBox(height: 8),
              _infoRow(
                "Per cust :",
                "₹${perPersonAmount.toStringAsFixed(2)}",
              ),

              const SizedBox(height: 16),

              _buildKeypad(),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F80ED),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    "Add",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildKeypad() {
    final keys = [
      '1','2','3',
      '4','5','6',
      '7','8','9',
      'C','0','←'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];

        return InkWell(
          onTap: () {
            if (key == '←') {
              setState(() {
                splitCount = splitCount ~/ 10;
              });
            } else if (key == 'C') {
              setState(() => splitCount = 1);
            } else {
              _onNumberTap(key);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade200,
            ),
            alignment: Alignment.center,
            child: Text(
              key,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}
