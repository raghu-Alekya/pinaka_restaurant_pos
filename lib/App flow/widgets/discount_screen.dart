import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../blocs/Bloc Event/discount_event.dart';
import '../../blocs/Bloc Event/payment_event.dart';
import '../../blocs/Bloc Logic/discount_bloc.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc State/discount_stata.dart';
import '../../models/payment/discount_model.dart';
import '../../utils/SessionManager.dart';
import '../../utils/theme_provider.dart';

enum DiscountType { percent, amount }

class DiscountPopup extends StatefulWidget {
  final double netPayable;
  final double netTotal; // ✅ ADDED
  final String? authToken;
  final int orderId;
  final double initialDiscount;
  final bool isPercent;

  const DiscountPopup({
    super.key,
    required this.netPayable,
    required this.netTotal, // ✅ REQUIRED
    this.authToken,
    required this.orderId,
    this.initialDiscount = 0.0,
    this.isPercent = false,
  });

  @override
  State<DiscountPopup> createState() => _DiscountPopupState();
}

class _DiscountPopupState extends State<DiscountPopup> {
  final TextEditingController discountController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  bool get isDark => Provider.of<ThemeProvider>(context, listen: false).isDark;
  DiscountType selectedType = DiscountType.percent;
  bool isNCSelected = false;
  double payableAmount = 0; // original
  double newPayableAmount = 0;
  // final double grossTotal;
  String _currency = "₹";
  @override
  @override
  void initState() {
    super.initState();
    _loadCurrency(); // <-- Add this
    // payableAmount = widget.netPayable;
    // newPayableAmount = widget.netPayable;
    payableAmount = widget.netTotal;
    newPayableAmount = widget.netTotal;
    // ✅ show existing discount when popup opens
    if (widget.initialDiscount > 0) {
      if (widget.isPercent) {
        selectedType = DiscountType.percent;
        final double percentVal =
            (widget.initialDiscount /
                (widget.netTotal > 0 ? widget.netTotal : 1.0)) *
                100;
        discountController.text = percentVal.toStringAsFixed(0);
      } else {
        selectedType = DiscountType.amount;
        discountController.text = widget.initialDiscount.toStringAsFixed(2);
      }
      // update preview also
      final applied = widget.initialDiscount;
      newPayableAmount = (payableAmount - applied).clamp(0, payableAmount);
    }

    discountController.addListener(_calculateNewPayable);
  }

  bool _isLoaded = false;
  Future<void> _loadCurrency() async {
    final currency = await SessionManager.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _currency = currency ?? "₹";
      });
    }
  }

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
    if (isNCSelected) return;

    if (value == 'Clear') {
      discountController.clear();
    } else if (value == '⌫') {
      if (discountController.text.isNotEmpty) {
        final raw = discountController.text.replaceAll('.00', '');

        if (raw.isNotEmpty) {
          final updated = raw.substring(0, raw.length - 1);

          if (updated.isEmpty) {
            discountController.clear();
          } else if (selectedType == DiscountType.amount) {
            discountController.text = '${int.parse(updated).toString()}.00';
          } else {
            discountController.text = updated;
          }
        }
      }
    } else {
      if (selectedType == DiscountType.amount) {
        final raw = discountController.text.replaceAll('.00', '');
        final updated = raw + value;

        discountController.text = '${int.parse(updated).toString()}.00';
      } else {
        discountController.text += value;
      }
    }

    discountController.selection = TextSelection.fromPosition(
      TextPosition(offset: discountController.text.length),
    );

    _calculateNewPayable();
    setState(() {});
  }

  void _calculateNewPayable() {
    if (isNCSelected) {
      setState(() {
        discountController.text = payableAmount.toStringAsFixed(2);
        newPayableAmount = 0;
      });
      return;
    }

    final value =
        double.tryParse(discountController.text.replaceAll('.00', '')) ?? 0;

    setState(() {
      if (selectedType == DiscountType.percent) {
        final discount = (widget.netTotal * value) / 100;
        newPayableAmount = (payableAmount - discount).clamp(0, payableAmount);
      } else {
        newPayableAmount = (payableAmount - value).clamp(0, payableAmount);
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
    final inputValue =
        double.tryParse(discountController.text.replaceAll('.00', '')) ?? 0;
    // Show with 2 decimal places
    //     if (selectedType == DiscountType.amount) {
    //       discountController.text = inputValue.toStringAsFixed(2);
    //     }

    debugPrint('➡️ inputValue = $inputValue');
    debugPrint('➡️ selectedType = $selectedType');
    debugPrint('➡️ isNCSelected = $isNCSelected');
    debugPrint('➡️ payableAmount = $payableAmount');

    // final String discountStr = isNCSelected
    //     ? payableAmount.toStringAsFixed(2)
    //     : selectedType == DiscountType.percent
    //         ? ((widget.netTotal * inputValue) / 100).toStringAsFixed(2)
    //         : inputValue.toStringAsFixed(0);
    final String discountStr =
    isNCSelected
        ? payableAmount.toStringAsFixed(2)
        : selectedType == DiscountType.percent
        ? ((widget.netTotal * inputValue) / 100).toStringAsFixed(2)
        : inputValue.toStringAsFixed(2);
    debugPrint('💰 FINAL discountStr sent to API = $discountStr');
    debugPrint('🧾 orderId = ${widget.orderId}');
    debugPrint('🧾 reason = ${reasonController.text}');

    debugPrint('🚀 Dispatching ApplyDiscountEvent');

    context.read<DiscountBloc>().add(
      ApplyDiscountEvent(
        request: AddDiscountRequest(
          orderId: widget.orderId,
          amount: discountStr,
          isNc: isNCSelected ? "yes" : "no",
          reason: reasonController.text,
        ),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exitNCMode() {
    setState(() {
      isNCSelected = false;

      // Clear discount input
      discountController.clear();

      // Restore payable
      newPayableAmount = payableAmount;
    });
  }

  // @override
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    return BlocListener<DiscountBloc, DiscountState>(
      listener: (context, state) {
        if (state is DiscountSuccess) {
          final inputValue = double.tryParse(discountController.text) ?? 0;
          final appliedDiscount = state.response.discountAmt;

          setState(() {
            newPayableAmount = (payableAmount - appliedDiscount).clamp(
              0,
              payableAmount,
            );
          });

          context.read<PaymentBloc>().add(
            UpdateMerchantDiscount(
              value: appliedDiscount,
              isNoCharge: isNCSelected,
            ),
          );

          Navigator.pop(context, {
            "amount": appliedDiscount,
            "isNc": isNCSelected,
            "reason": reasonController.text,
          });
        }
        if (state is DiscountFailure) {
          _showError(state.error.replaceFirst("Exception: ", ""));
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Container(
          width: 750,
          height: 550,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1F2937)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFDFDFDF),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Header
              _header(context,isDark),

              const SizedBox(height: 18),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LEFT
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        /// Amount Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111827)
                                : const Color(0xFFF9FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFDFDFDF),
                            ),
                          ),
                          child: _amountRow(isDark),
                        ),

                        const SizedBox(height: 10),

                        /// Discount Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111827)
                                : const Color(0xFFF9FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFDFDFDF),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // const Text(
                              //   "Apply Discount",
                              //   style: TextStyle(
                              //     fontWeight: FontWeight.w600,
                              //     fontSize: 15,
                              //   ),
                              // ),
                              //
                              // const SizedBox(height: 15),
                              _discountToggle(),

                              const SizedBox(height: 10),

                              _reasonField(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff4CAF50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _onSaveAndContinue,
                            child: const Text(
                              "Save & Continue",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 18),

                  /// RIGHT
                  Expanded(
                    flex: 4,
                    child: SizedBox(height: 386, child: _keypadSection()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------- HEADER ----------------
  Widget _header(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6FD),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF6BACC3),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              "assets/Discount Icon.png",
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
        ),
        // Container(
        //   width: 68,
        //   height: 68,
        //   decoration: BoxDecoration(
        //     color: const Color(0xFFEAF6FD),
        //     borderRadius: BorderRadius.circular(18),
        //   ),
        //   child: Center(
        //     child: Image.asset(
        //       "assets/Discount Icon.png",
        //       width: 34,
        //       height: 34,
        //       fit: BoxFit.contain,
        //     ),
        //   ),
        // ),
        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Apply Discount",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF3B3B3B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Add discounts using a percentage or amount, with an optional reason and real-time total preview.",
                style: TextStyle(fontSize: 14,    color: isDark
                    ? Colors.grey.shade400
                    : const Color(0xFF5A6A85),),
              ),
            ],
          ),
        ),

        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFFF4B3E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  /// ---------------- LEFT SECTION ----------------
  Widget _leftSection(bool isDark) {
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
          _amountRow(isDark),
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

  Widget _amountRow(bool isDark) {
    return Row(
      children: [
        _amountBox(
          'Net Total',
          '$_currency${payableAmount.toStringAsFixed(2)}',
          isDark,
          readOnly: true,
        ),

        const SizedBox(width: 12),

        _amountBox(
          'New Payable Amount',
          '$_currency${newPayableAmount.toStringAsFixed(2)}',
          isDark,
          readOnly: true,
        ),
      ],
    );
  }

  Widget _amountBox(
      String label,
      String value,
      bool isDark, {
        bool readOnly = false,
      }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white70
                  : const Color(0xFF252525),
            ),
          ),

          const SizedBox(height: 6),

          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFF1F3F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFFDFDFDF),
              ),
              boxShadow: isDark
                  ? []
                  : const [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 10,
                  offset: Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _discountToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //
        //         const SizedBox(
        //           height: 20, // aligns with Value label
        //         ),
        //
        //         const SizedBox(height: 6),
        //
        //         GestureDetector(
        //           onTap: () {
        //             setState(() {
        //               isNCSelected = true;
        //               discountController.text =
        //                   payableAmount.toStringAsFixed(2);
        //               newPayableAmount = 0;
        //             });
        //           },
        //           child: Container(
        //             width: 80,
        //             height: 48,
        //             decoration: BoxDecoration(
        //               color: const Color(0xFFFFFFFF),
        //               borderRadius: BorderRadius.circular(8),
        //               border: Border.all(
        //                 color: isNCSelected
        //                     ? const Color(0xFFFAD51D)
        //                     : Colors.transparent,
        //               ),
        //             ),
        //             child: const Center(
        //               child: Text(
        //                 "NC",
        //                 style: TextStyle(
        //                   fontWeight: FontWeight.bold,
        //                   fontSize: 18,
        //                 ),
        //               ),
        //             ),
        //           ),
        //         ),
        //       ],
        //     ),
        //     const SizedBox(width: 12),
        //
        //     /// Discount Type
        //     Expanded(
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           const Text(
        //             "Discount Type:",
        //             style: TextStyle(
        //               fontWeight: FontWeight.w500,
        //               fontSize: 14,
        //             ),
        //           ),
        //           const SizedBox(height: 6),
        //
        //           Container(
        //             height: 48,
        //             padding: const EdgeInsets.all(2),
        //             decoration: BoxDecoration(
        //               color: Colors.white,
        //               borderRadius: BorderRadius.circular(8),
        //               border: Border.all(color: const Color(0xFFDFDFDF)),
        //             ),
        //             child: Row(
        //               children: [
        //
        //                 /// %
        //                 Expanded(
        //                   child: GestureDetector(
        //                     onTap: () {
        //                       setState(() {
        //                         _exitNCMode();
        //                         selectedType = DiscountType.percent;
        //                       });
        //                     },
        //                     child: AnimatedContainer(
        //                       duration: const Duration(milliseconds: 200),
        //                       alignment: Alignment.center,
        //                       decoration: BoxDecoration(
        //                         color: selectedType == DiscountType.percent
        //                             ? const Color(0xFF2136BE)
        //                             : Colors.transparent,
        //                         borderRadius: BorderRadius.circular(6),
        //                       ),
        //                       child: Text(
        //                         "%",
        //                         style: TextStyle(
        //                           fontSize: 22,
        //                           fontWeight: FontWeight.bold,
        //                           color: selectedType == DiscountType.percent
        //                               ? Colors.white
        //                               : Colors.black,
        //                         ),
        //                       ),
        //                     ),
        //                   ),
        //                 ),
        //
        //                 Expanded(
        //                   child: GestureDetector(
        //                     onTap: () {
        //                       setState(() {
        //                         _exitNCMode();
        //                         selectedType = DiscountType.amount;
        //                       });
        //                     },
        //                     child: AnimatedContainer(
        //                       duration: const Duration(milliseconds: 200),
        //                       alignment: Alignment.center,
        //                       decoration: BoxDecoration(
        //                         color: selectedType == DiscountType.amount
        //                             ? const Color(0xFF2136BE)
        //                             : Colors.transparent,
        //                         borderRadius: BorderRadius.circular(6),
        //                       ),
        //                       child: Text(
        //                         _currency,
        //                         style: TextStyle(
        //                           fontSize: 22,
        //                           fontWeight: FontWeight.bold,
        //                           color: selectedType == DiscountType.amount
        //                               ? Colors.white
        //                               : Colors.black,
        //                         ),
        //                       ),
        //                     ),
        //                   ),
        //                 ),
        //               ],
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //
        //     const SizedBox(width: 12),
        //
        //     /// Value
        //     SizedBox(
        //       width: 120,
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //
        //           const Text(
        //             "Value:",
        //             style: TextStyle(
        //               fontWeight: FontWeight.w500,
        //               fontSize: 14,
        //             ),
        //           ),
        //
        //           const SizedBox(height: 6),
        //
        //           SizedBox(
        //             height: 48,
        //             child: IgnorePointer(
        //               ignoring: isNCSelected,
        //               child: TextField(
        //                 controller: discountController,
        //                 readOnly: true,
        //                 textAlign: TextAlign.center,
        //                 style: const TextStyle(
        //                   fontSize: 18, // Entered text size
        //                   fontWeight: FontWeight.bold,
        //                   color: Color(0xFF111827),
        //                 ),
        //                 decoration: InputDecoration(
        //                   hintText: selectedType == DiscountType.percent
        //                       ? "10%"
        //                       : "$_currency 100.00",
        //                   prefixText: !isNCSelected &&
        //                       selectedType == DiscountType.amount
        //                       ? "$_currency "
        //                       : null,
        //
        //                   suffixText: !isNCSelected &&
        //                       selectedType == DiscountType.percent
        //                       ? "%"
        //                       : null,
        //                   filled: true,
        //                   fillColor: Colors.white,
        //                   contentPadding: const EdgeInsets.symmetric(
        //                     horizontal: 10,
        //                     vertical: 12,
        //                   ),
        //                   border: OutlineInputBorder(
        //                     borderRadius: BorderRadius.circular(8),
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //
        //     const SizedBox(width: 12),
        //
        //     /// NC
        //     Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //
        //         const SizedBox(
        //           height: 20, // aligns with Value label
        //         ),
        //
        //         // const SizedBox(height: 6),
        //
        //         // GestureDetector(
        //         //   onTap: () {
        //         //     setState(() {
        //         //       isNCSelected = true;
        //         //       discountController.text =
        //         //           payableAmount.toStringAsFixed(2);
        //         //       newPayableAmount = 0;
        //         //     });
        //         //   },
        //         //   child: Container(
        //         //     width: 80,
        //         //     height: 48,
        //         //     decoration: BoxDecoration(
        //         //       color: const Color(0xFFFAD51D),
        //         //       borderRadius: BorderRadius.circular(8),
        //         //       border: Border.all(
        //         //         color: isNCSelected
        //         //             ? const Color(0xFFB45309)
        //         //             : Colors.transparent,
        //         //       ),
        //         //     ),
        //         //     child: const Center(
        //         //       child: Text(
        //         //         "NC",
        //         //         style: TextStyle(
        //         //           fontWeight: FontWeight.bold,
        //         //           fontSize: 18,
        //         //         ),
        //         //       ),
        //         //     ),
        //         //   ),
        //         // ),
        //       ],
        //     ),
        //   ],
        // ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT SIDE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discount Type label
                  const Text(
                    "Discount Type:",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),

                  const SizedBox(height: 6),

                  // NC | % | ₹ Container
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F2937)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFDFDFDF),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTypeButton(
                          title: "NC",
                          isDark: isDark,
                          selected: isNCSelected,
                          onTap: () {
                            setState(() {
                              isNCSelected = true;
                              discountController.text = payableAmount.toStringAsFixed(2);
                              newPayableAmount = 0;
                            });
                          },
                        ),

                        _divider(isDark),

                        _buildTypeButton(
                          title: "%",
                          isDark: isDark,
                          selected: !isNCSelected &&
                              selectedType == DiscountType.percent,
                          onTap: () {
                            setState(() {
                              _exitNCMode();
                              selectedType = DiscountType.percent;
                            });
                          },
                        ),

                        _divider(isDark),

                        _buildTypeButton(
                          title: _currency,
                          isDark: isDark,
                          selected: !isNCSelected &&
                              selectedType == DiscountType.amount,
                          onTap: () {
                            setState(() {
                              _exitNCMode();
                              selectedType = DiscountType.amount;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  if (isNCSelected)
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "NC Applied",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            /// RIGHT SIDE (UNCHANGED)
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Value:",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: isNCSelected
                          ? (isDark
                          ? const Color(0xFF2B3042)
                          : const Color(0xFFF5F5F5))
                          : (isDark
                          ? const Color(0xFF2B3042)
                          : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isNCSelected
                            ? (isDark
                            ? Colors.white24
                            : const Color(0xFFCECECE))
                            : (isDark
                            ? Colors.white24
                            : const Color(0xFFDFDFDF)),
                      ),
                    ),
                    child: SizedBox(
                      height: 48,
                      child: IgnorePointer(
                        ignoring: isNCSelected,
                        child: TextField(
                          controller: discountController,
                          readOnly: true,
                          enabled: !isNCSelected,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isNCSelected
                                ? (isDark
                                ? Colors.white54
                                : const Color(0xFFBDBDBD))
                                : (isDark
                                ? Colors.white
                                : const Color(0xFF111827)),
                          ),
                          decoration: InputDecoration(
                            hintText: selectedType == DiscountType.percent
                                ? "10"
                                : "100.00",
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFFBDBDBD),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixText: !isNCSelected &&
                                selectedType == DiscountType.amount
                                ? "$_currency "
                                : null,
                            suffixText: !isNCSelected &&
                                selectedType == DiscountType.percent
                                ? "%"
                                : null,
                            prefixStyle: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            suffixStyle: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            filled: true,
                            fillColor: isNCSelected
                                ? (isDark
                                ? const Color(0xFF2B3042)
                                : const Color(0xFFF5F5F5))
                                : (isDark
                                ? const Color(0xFF2B3042)
                                : Colors.white),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Row(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     /// Discount Type + NC
        //     Expanded(
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           const Text(
        //             "Discount Type:",
        //             style: TextStyle(
        //               fontWeight: FontWeight.w500,
        //               fontSize: 14,
        //             ),
        //           ),
        //           const SizedBox(height: 6),
        //
        //           Row(
        //             children: [
        //               /// NC Button
        //               GestureDetector(
        //                 onTap: () {
        //                   setState(() {
        //                     isNCSelected = true;
        //                     discountController.text =
        //                         payableAmount.toStringAsFixed(2);
        //                     newPayableAmount = 0;
        //                   });
        //                 },
        //                 child: Container(
        //                   width: 80,
        //                   height: 48,
        //                   decoration: BoxDecoration(
        //                     color: isNCSelected
        //                         ? const Color(0xFF2236BE)
        //                         : Colors.white,
        //                     borderRadius: BorderRadius.circular(8),
        //                     border: Border.all(
        //                       color: isNCSelected
        //                           ? const Color(0xFF2236BE)
        //                           : const Color(0xFFEACB00),
        //                       width: 1.5,
        //                     ),
        //                   ),
        //                   child: Center(
        //                     child: Text(
        //                       "NC",
        //                       style: TextStyle(
        //                         fontWeight: FontWeight.bold,
        //                         fontSize: 18,
        //                         color: isNCSelected
        //                             ? Colors.white
        //                             : const Color(0xFFEACB00),
        //                       ),
        //                     ),
        //                   ),
        //                 ),
        //               ),
        //
        //               const SizedBox(width: 8),
        //
        //               /// % / ₹ Toggle
        //               Expanded(
        //                 child: Container(
        //                   height: 48,
        //                   padding: const EdgeInsets.all(2),
        //                   decoration: BoxDecoration(
        //                     color: Colors.white,
        //                     borderRadius: BorderRadius.circular(8),
        //                     border: Border.all(
        //                       color: const Color(0xFFDFDFDF),
        //                     ),
        //                   ),
        //                   child: Row(
        //                     children: [
        //                       // % button
        //                       Expanded(
        //                         child: GestureDetector(
        //                           onTap: () {
        //                             setState(() {
        //                               _exitNCMode();
        //                               selectedType = DiscountType.percent;
        //                             });
        //                           },
        //                           child: AnimatedContainer(
        //                             duration: const Duration(milliseconds: 200),
        //                             alignment: Alignment.center,
        //                             decoration: BoxDecoration(
        //                               color: selectedType ==
        //                                   DiscountType.percent
        //                                   ? const Color(0xFF2136BE)
        //                                   : Colors.transparent,
        //                               borderRadius:
        //                               BorderRadius.circular(6),
        //                             ),
        //                             child: Text(
        //                               "%",
        //                               style: TextStyle(
        //                                 fontSize: 22,
        //                                 fontWeight: FontWeight.bold,
        //                                 color: selectedType ==
        //                                     DiscountType.percent
        //                                     ? Colors.white
        //                                     : Colors.black,
        //                               ),
        //                             ),
        //                           ),
        //                         ),
        //                       ),
        //
        //                       Expanded(
        //                         child: GestureDetector(
        //                           onTap: () {
        //                             setState(() {
        //                               _exitNCMode();
        //                               selectedType = DiscountType.amount;
        //                             });
        //                           },
        //                           child: AnimatedContainer(
        //                             duration: const Duration(milliseconds: 200),
        //                             alignment: Alignment.center,
        //                             decoration: BoxDecoration(
        //                               color: selectedType ==
        //                                   DiscountType.amount
        //                                   ? const Color(0xFF2136BE)
        //                                   : Colors.transparent,
        //                               borderRadius:
        //                               BorderRadius.circular(6),
        //                             ),
        //                             child: Text(
        //                               _currency,
        //                               style: TextStyle(
        //                                 fontSize: 22,
        //                                 fontWeight: FontWeight.bold,
        //                                 color: selectedType ==
        //                                     DiscountType.amount
        //                                     ? Colors.white
        //                                     : Colors.black,
        //                               ),
        //                             ),
        //                           ),
        //                         ),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ],
        //       ),
        //     ),
        //
        //     const SizedBox(width: 16),
        //
        //     /// Value
        //     SizedBox(
        //       width: 120,
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //
        //           const Text(
        //             "Value:",
        //             style: TextStyle(
        //               fontWeight: FontWeight.w500,
        //               fontSize: 14,
        //             ),
        //           ),
        //
        //           const SizedBox(height: 6),
        //
        //           SizedBox(
        //             height: 48,
        //             child: IgnorePointer(
        //               ignoring: isNCSelected,
        //               child: TextField(
        //                 controller: discountController,
        //                 readOnly: true,
        //                 textAlign: TextAlign.center,
        //                 style: const TextStyle(
        //                   fontSize: 18, // Entered text size
        //                   fontWeight: FontWeight.bold,
        //                   color: Color(0xFF111827),
        //                 ),
        //                 decoration: InputDecoration(
        //                   hintText: selectedType == DiscountType.percent
        //                       ? "10%"
        //                       : "$_currency 100.00",
        //                   prefixText: !isNCSelected &&
        //                       selectedType == DiscountType.amount
        //                       ? "$_currency "
        //                       : null,
        //
        //                   suffixText: !isNCSelected &&
        //                       selectedType == DiscountType.percent
        //                       ? "%"
        //                       : null,
        //                   filled: true,
        //                   fillColor: Colors.white,
        //                   contentPadding: const EdgeInsets.symmetric(
        //                     horizontal: 10,
        //                     vertical: 12,
        //                   ),
        //                   border: OutlineInputBorder(
        //                     borderRadius: BorderRadius.circular(8),
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //
        //   ],
        // )
        // const SizedBox(height: 5),

        // Row(
        //   children: [
        //     /// Percentage Toggle
        //     Expanded(
        //       child: Container(
        //         height: 48,
        //         padding: const EdgeInsets.all(2),
        //         decoration: BoxDecoration(
        //           color: Colors.white,
        //           borderRadius: BorderRadius.circular(8),
        //           border: Border.all(
        //             color: const Color(0xFFDFDFDF),
        //           ),
        //         ),
        //         child: Row(
        //           children: [
        //
        //             /// Percentage
        //             Expanded(
        //               child: GestureDetector(
        //                 onTap: () {
        //                   setState(() {
        //                     _exitNCMode();
        //                     selectedType = DiscountType.percent;
        //                   });
        //                 },
        //                 child: AnimatedContainer(
        //                   duration: const Duration(milliseconds: 200),
        //                   decoration: BoxDecoration(
        //                     color: selectedType == DiscountType.percent
        //                         ? const Color(0xFF2136BE)
        //                         : Colors.transparent,
        //                     borderRadius: BorderRadius.circular(6),
        //                   ),
        //                   alignment: Alignment.center,
        //                   child: Text(
        //                     "%",
        //                     style: TextStyle(
        //                       fontSize: 22,
        //                       fontWeight: FontWeight.bold,
        //                       color: selectedType == DiscountType.percent
        //                           ? Colors.white
        //                           : Colors.black,
        //                     ),
        //                   ),
        //                 ),
        //               ),
        //             ),
        //
        //             /// Amount
        //             Expanded(
        //               child: GestureDetector(
        //                 onTap: () {
        //                   setState(() {
        //                     _exitNCMode();
        //                     selectedType = DiscountType.amount;
        //                   });
        //                 },
        //                 child: AnimatedContainer(
        //                   duration: const Duration(milliseconds: 200),
        //                   decoration: BoxDecoration(
        //                     color: selectedType == DiscountType.amount
        //                         ? const Color(0xFF2136BE)
        //                         : Colors.transparent,
        //                     borderRadius: BorderRadius.circular(6),
        //                   ),
        //                   alignment: Alignment.center,
        //                   child: Text(
        //                     _currency,
        //                     style: TextStyle(
        //                       fontSize: 22,
        //                       fontWeight: FontWeight.bold,
        //                       color: selectedType == DiscountType.amount
        //                           ? Colors.white
        //                           : Colors.black,
        //                     ),
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //
        //     const SizedBox(width: 12),
        //
        //     /// Value Field
        //     SizedBox(
        //       width: 120,
        //       height: 48,
        //       child: IgnorePointer(
        //         ignoring: isNCSelected,
        //         child: TextField(
        //           controller: discountController,
        //           readOnly: true,
        //           enabled: !isNCSelected,
        //           textAlign: TextAlign.center,
        //           decoration: InputDecoration(
        //             prefixText: !isNCSelected &&
        //                 selectedType == DiscountType.amount
        //                 ? "$_currency "
        //                 : null,
        //             prefixStyle: const TextStyle(
        //               fontWeight: FontWeight.bold,
        //               fontSize: 16,
        //               color: Colors.black,
        //             ),
        //             hintText: selectedType == DiscountType.percent
        //                 ? "10"
        //                 : "100",
        //             filled: true,
        //             fillColor:
        //             isNCSelected ? const Color(0xFFE5E7EB) : Colors.white,
        //             contentPadding: const EdgeInsets.symmetric(
        //               horizontal: 10,
        //               vertical: 12,
        //             ),
        //             enabledBorder: OutlineInputBorder(
        //               borderRadius: BorderRadius.circular(8),
        //               borderSide:
        //               const BorderSide(color: Color(0xFFD9DDE5)),
        //             ),
        //             focusedBorder: OutlineInputBorder(
        //               borderRadius: BorderRadius.circular(8),
        //               borderSide:
        //               const BorderSide(color: Color(0xFF2E43C6)),
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //
        //     const SizedBox(width: 12),
        //
        //     /// NC Button
        //     GestureDetector(
        //       onTap: () {
        //         setState(() {
        //           isNCSelected = true;
        //           discountController.text =
        //               payableAmount.toStringAsFixed(2);
        //           newPayableAmount = 0;
        //         });
        //       },
        //       child: Container(
        //         width: 80,
        //         height: 48,
        //         decoration: BoxDecoration(
        //           color: const Color(0xFFFAD51D),
        //           borderRadius: BorderRadius.circular(8),
        //           border: Border.all(
        //             color: isNCSelected
        //                 ? const Color(0xFFB45309)
        //                 : Colors.transparent,
        //           ),
        //         ),
        //         child: const Center(
        //           child: Text(
        //             "NC",
        //             style: TextStyle(
        //               fontSize: 18,
        //               fontWeight: FontWeight.bold,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
  Widget _divider(bool isDark) {

    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDark
          ? const Color(0xFF4B5563)
          : const Color(0xFFE5E7EB),
    );
  }
  Widget _buildTypeButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final bool isNC = title == "NC";

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
            color: const Color(0xFF2236BE),
            borderRadius: BorderRadius.circular(8),
          )
              : isNC
              ? BoxDecoration(
            color: selected
                ? const Color(0xFF2236BE)
                : isDark
                ? const Color(0xFF374151)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: isNC
                ? Border.all(
              color: const Color(0xFFEACA00),
            )
                : null,
          )
              : const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: selected
                  ? Colors.white
                  : isNC
                  ? const Color(0xFFEACA00)
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _radioButton(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? const Color(0xFF3B82F6) : const Color(0xFFE6EAF2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 16,
            color: selected ? const Color(0xFF3B82F6) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }

  Widget _reasonField() {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discount / NC Reason :',
          style: TextStyle(fontSize: 12,     color: isDark
              ? Colors.white70
              : const Color(0xFF252525),),
        ),
        const SizedBox(height: 6),

        BlocBuilder<DiscountReasonBloc, DiscountReasonState>(
          builder: (context, state) {
            print('🟡 [ReasonField] Bloc state: ${state.runtimeType}');

            if (state is DiscountReasonLoading) {
              print('⏳ Loading discount reasons...');
              return const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            if (state is DiscountReasonLoaded) {
              print('✅ Discount reasons loaded: ${state.reasons}');

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 10,
                      offset: Offset(0, 1),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value:
                  reasonController.text.isNotEmpty
                      ? reasonController.text
                      : null,
                  items:
                  state.reasons
                      .map(
                        (reason) => DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    reasonController.text = value ?? '';
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF374151)
                        : Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFDFDFDF),
                      ),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFDFDFDF),
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  hint: Text(
                    'Select reason',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white54
                          : Colors.grey,
                    ),
                  ),

                  dropdownColor: isDark
                      ? const Color(0xFF374151)
                      : Colors.white,

                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
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
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    final labels = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'Clear',
      '0',
      '⌫',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: labels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (_, index) {
        final label = labels[index];

        final isClear = label == "Clear";
        final isBack = label == "⌫";

        return IgnorePointer(
          ignoring: isNCSelected,
          child: Opacity(
            opacity: isNCSelected ? 0.5 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _onKeypadTap(label),
              child: Container(
                decoration: BoxDecoration(
                  color: isNCSelected && (isClear || isBack)
                      ? (isDark
                      ? const Color(0xFF2B3042)
                      : const Color(0xFFF5F5F5))
                      : (isClear || isBack)
                      ? (isDark
                      ? const Color(0xFF34384F)
                      : Colors.white)
                      : (isDark
                      ? const Color(0xFF2B3042)
                      : const Color(0xFFF4F7FD)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isNCSelected && (isClear || isBack)
                        ? (isDark
                        ? Colors.white24
                        : const Color(0xFFCECECE))
                        : (isClear || isBack)
                        ? Colors.redAccent
                        : (isDark
                        ? Colors.white24
                        : const Color(0xFFDADFE8)),
                  ),
                  boxShadow: isDark
                      ? []
                      : const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: isBack
                      ? Icon(
                    Icons.backspace_outlined,
                    color: isNCSelected
                        ? (isDark
                        ? Colors.white54
                        : const Color(0xFFBDBDBD))
                        : (isDark
                        ? Colors.white
                        : Colors.redAccent),
                    size: 28,
                  )
                      : Text(
                    label,
                    style: TextStyle(
                      fontSize: isClear ? 16 : 18,
                      fontWeight: FontWeight.w500,
                      color: isNCSelected && (isClear || isBack)
                          ? (isDark
                          ? Colors.white54
                          : const Color(0xFFBDBDBD))
                          : isClear
                          ? Colors.redAccent
                          : (isDark
                          ? Colors.white
                          : const Color(0xFF4C5F80)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
