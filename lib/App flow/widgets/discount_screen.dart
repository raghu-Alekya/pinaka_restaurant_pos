import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/discount_event.dart';
import '../../blocs/Bloc Event/payment_event.dart';
import '../../blocs/Bloc Logic/discount_bloc.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc State/discount_stata.dart';
import '../../models/payment/discount_model.dart';
enum DiscountType { percent, amount }

class DiscountPopup extends StatefulWidget {
  final double netPayable;
  final String ? authToken;
  final int orderId;
  final double initialDiscount;
// ✅ comes from parent

  const DiscountPopup({
    super.key,
    required this.netPayable,
     this.authToken,
    required this.orderId,
    this.initialDiscount = 0.0,


  });

  @override
  State<DiscountPopup> createState() => _DiscountPopupState();
}

class _DiscountPopupState extends State<DiscountPopup> {

  final TextEditingController discountController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  DiscountType selectedType = DiscountType.percent;
  bool isNCSelected = false;
  double payableAmount = 0; // original
  double newPayableAmount = 0;
  // final double grossTotal;

  @override
  @override
  void initState() {
    super.initState();

    payableAmount = widget.netPayable;
    newPayableAmount = widget.netPayable;

    // ✅ show existing discount when popup opens
    if (widget.initialDiscount > 0) {
      discountController.text = widget.initialDiscount.toStringAsFixed(2);

      // update preview also
      final applied = widget.initialDiscount;
      newPayableAmount = (payableAmount - applied).clamp(0, payableAmount);
    }

    discountController.addListener(_calculateNewPayable);
  }

  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isLoaded) {
      _isLoaded = true;
      context.read<DiscountReasonBloc>().add(LoadDiscountReasons());
    }
  }






  @override
  void dispose() {
    discountController.removeListener(_calculateNewPayable);
    discountController.dispose();
    reasonController.dispose();
    super.dispose();
  }


  void _onKeypadTap(String value) {
    if (isNCSelected) return; // 🔒 HARD BLOCK

    setState(() {
      if (value == 'Clear') {
        discountController.clear();
      } else if (value == '⌫') {
        if (discountController.text.isNotEmpty) {
          discountController.text =
              discountController.text.substring(
                  0, discountController.text.length - 1);
        }
      } else {
        discountController.text += value;
      }
    });
  }
  void _calculateNewPayable() {
    if (isNCSelected) {
      setState(() {
        discountController.text = payableAmount.toStringAsFixed(2);
        newPayableAmount = 0;
      });
      return;
    }

    final value = double.tryParse(discountController.text) ?? 0;

    setState(() {
      if (selectedType == DiscountType.percent) {
        final discount = (payableAmount * value) / 100;
        newPayableAmount =
            (payableAmount - discount).clamp(0, payableAmount);
      } else {
        newPayableAmount =
            (payableAmount - value).clamp(0, payableAmount);
      }
    });
  }
  void _onSaveAndContinue() {
    debugPrint('🟢 [_onSaveAndContinue] called');

    // // 🔐 Token check
    // if (widget.authToken == null) {
    //   debugPrint('❌ authToken is NULL');
    //   return;
    // }

    debugPrint('🔐 authToken present');

    // 🔒 Validation
    if (!isNCSelected && discountController.text.isEmpty) {
      debugPrint('❌ Discount value empty');
      _showError('Enter discount value');
      return;
    }

    if (reasonController.text.isEmpty) {
      debugPrint('❌ Reason not selected');
      _showError('Select discount reason');
      return;
    }

    final inputValue = double.tryParse(discountController.text) ?? 0;

    debugPrint('➡️ inputValue = $inputValue');
    debugPrint('➡️ selectedType = $selectedType');
    debugPrint('➡️ isNCSelected = $isNCSelected');
    debugPrint('➡️ payableAmount = $payableAmount');

    // 🔥 CORRECT AMOUNT CALCULATION
    final discountAmount = isNCSelected
        ? payableAmount
        : selectedType == DiscountType.percent
        ? (payableAmount * inputValue) / 100
        : inputValue;

    debugPrint('💰 FINAL discountAmount sent to API = $discountAmount');
    debugPrint('🧾 orderId = ${widget.orderId}');
    debugPrint('🧾 reason = ${reasonController.text}');

    debugPrint('🚀 Dispatching ApplyDiscountEvent');

    context.read<DiscountBloc>().add(
      ApplyDiscountEvent(
        // token: widget.authToken!,
        request: AddDiscountRequest(
          orderId: widget.orderId,
          amount: discountAmount,
          isNc: isNCSelected ? "yes" : "no",
          reason: reasonController.text,
        ),
      ),
    );
  }


  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }




  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscountBloc, DiscountState>(
      listener: (context, state) {
        debugPrint('🟣 [DiscountPopup] BlocListener state = ${state.runtimeType}');

        if (state is DiscountSuccess) {
          final inputValue = double.tryParse(discountController.text) ?? 0;

          final appliedDiscount = isNCSelected
              ? payableAmount
              : selectedType == DiscountType.percent
              ? (payableAmount * inputValue) / 100
              : inputValue;

          // ✅ keep discount value in TextField after apply
          discountController.value = TextEditingValue(
            text: inputValue.toString(),
            selection: TextSelection.collapsed(offset: inputValue.toString().length),
          );

          // ✅ update payable preview
          setState(() {
            newPayableAmount = (payableAmount - appliedDiscount).clamp(0, payableAmount);
          });

          // ✅ save discount in PaymentBloc
          context.read<PaymentBloc>().add(UpdateMerchantDiscount(appliedDiscount));

          Navigator.pop(context, {
            "amount": appliedDiscount,
            "isNc": isNCSelected,
          });
        }




        if (state is DiscountFailure) {
          debugPrint('❌ [DiscountPopup] DiscountFailure = ${state.error}');
          _showError(state.error);
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 860,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1FBF75), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(context),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 870,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 460,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _leftSection(),
                            const SizedBox(height: 25),
                            GestureDetector(
                              onTap: () {
                                debugPrint('🟢 [UI] Save & Continue tapped');
                                _onSaveAndContinue();
                              },
                              child: Container(
                                height: 48,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Save & Continue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      _keypadSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  /// ---------------- HEADER ----------------
  Widget _header(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            children: const [
              Text(
                'Discount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1C),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Add discounts using a percentage or amount, with an optional reason and real-time total preview.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFFF5A5A),
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }

  /// ---------------- LEFT SECTION ----------------
  Widget _leftSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _amountRow(),
          const Divider(height: 32),

          const Text(
            'Apply Discount',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          _discountToggle(),
          const SizedBox(height: 12),

          _reasonField(),
          const SizedBox(height: 12),

          // _customerTags(),
          // const SizedBox(height: 20),

        ],
      ),
    );
  }


  Widget _amountRow() {
    return Row(
      children: [
        _amountBox(
          'Payable Amount',
          payableAmount.toStringAsFixed(0),
          readOnly: true,
        ),
        const SizedBox(width: 12),
        _amountBox(
          'New Payable Amount',
          newPayableAmount.toStringAsFixed(0), // 🔥 LIVE UPDATE
          readOnly: true,
        ),
      ],
    );
  }

  Widget _amountBox(String label, String value, {bool readOnly = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A869A))),
          const SizedBox(height: 6),

          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE6EAF2)),
            ),
            child: Text(
              value, // ✅ dynamically updates
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _discountToggle() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedType = DiscountType.percent;
              isNCSelected = false;
              // discountController.clear();
            });
          },
          child: _radioButton(
            'Percent',
            selectedType == DiscountType.percent && !isNCSelected,
          ),
        ),
        const SizedBox(width: 12),

        GestureDetector(
          onTap: () {
            setState(() {
              selectedType = DiscountType.amount;
              isNCSelected = false;
              discountController.clear();
            });
          },
          child: _radioButton(
            'Amount',
            selectedType == DiscountType.amount && !isNCSelected,
          ),
        ),

        const SizedBox(width: 12),

        /// 🔹 Input Field (Enabled for Percent / Amount / NC)
        SizedBox(
          width: 120,
          child: IgnorePointer( // 🚫 blocks ALL interaction
            ignoring: isNCSelected,
            child: TextField(
              controller: discountController,
              readOnly: true, // keypad only
              enabled: !isNCSelected,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: isNCSelected
                    ? '--'
                    : selectedType == DiscountType.percent
                    ? ' ex:10%'
                    : 'ex:₹100',
                hintStyle: TextStyle(               // ✅ CONTROL COLOR HERE
                  color: isNCSelected
                      ? const Color(0xFF9CA3AF)     // medium grey (disabled)
                      : const Color(0xFF999393),    // darker grey (active)
                  fontWeight: FontWeight.w500,
                ),

                filled: true,
                fillColor: isNCSelected
                    ? const Color(0xFFE5E7EB) // disabled look
                    : Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),


        const SizedBox(width: 12),

        /// 🔹 NC Button
        GestureDetector(
          onTap: () {
            setState(() {
              isNCSelected = true;

              // ✅ Discount becomes full payable amount
              discountController.text = payableAmount.toStringAsFixed(2);

              // ✅ New payable becomes zero
              newPayableAmount = 0;
            });
          },

          child: Container(
            width: 80,
            height: 42,
            decoration: BoxDecoration(
              color: isNCSelected ? const Color(0xFFF59E0B) : const Color(0xFFFAD51D),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isNCSelected ? const Color(0xFFB45309) : Colors.transparent,
              ),
            ),
            child: const Center(
              child: Text(
                'NC',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),

      ],
    );
  }


  Widget _radioButton(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: selected
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE6EAF2)),
      ),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            size: 16,
            color:
            selected ? const Color(0xFF3B82F6) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }

  Widget _reasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discount / NC Reason :',
          style: TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
        ),
        const SizedBox(height: 6),

        BlocBuilder<DiscountReasonBloc, DiscountReasonState>(
          builder: (context, state) {
            print('🟡 [ReasonField] Bloc state: ${state.runtimeType}');

            if (state is DiscountReasonLoading) {
              print('⏳ Loading discount reasons...');
              return const SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (state is DiscountReasonLoaded) {
              print('✅ Discount reasons loaded: ${state.reasons}');

              return DropdownButtonFormField<String>(
                value: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
                items: state.reasons
                    .map(
                      (reason) => DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  print('👉 Selected discount reason: $value');
                  reasonController.text = value ?? '';
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                hint: const Text('Select reason'),
              );
            }

            if (state is DiscountReasonError) {
              print('❌ Error loading discount reasons: ${state.message}');
              return Text(
                state.message,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              );
            }

            print('⚪ ReasonField: Initial/empty state');
            return const SizedBox();
          },
        ),
      ],
    );
  }


  // Widget _customerTags() {
  //   return Row(
  //     children: [
  //       _tag('Regular Customer'),
  //       const SizedBox(width: 8),
  //       _tag('New Customer'),
  //       const SizedBox(width: 8),
  //       _tag('Corporate'),
  //     ],
  //   );
  // }


  Widget _tag(String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          reasonController.text = text; // ✅ reflect in field
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4C81F1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
    );
  }


  /// ---------------- KEYPAD ----------------
  Widget _keypadSection() {
    final labels = [
      '1','2','3',
      '4','5','6',
      '7','8','9',
      'Clear','0','⌫'
    ];

    return SizedBox(
      width: 300,
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: labels.length,
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (_, i) {
          return InkWell(
            onTap: () => _onKeypadTap(labels[i]), // ✅ tap enabled
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE6EAF2)),
              ),
              child: Center(
                child: Text(
                  labels[i],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


}
