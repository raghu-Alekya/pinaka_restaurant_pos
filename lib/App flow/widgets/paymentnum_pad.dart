import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/paymentsucess.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/tip_widget.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Event/order_event.dart';
import '../../blocs/Bloc Event/create_payment_event.dart';
import '../../blocs/Bloc Event/discount_event.dart';
import '../../blocs/Bloc Event/payment_event.dart';
import '../../blocs/Bloc Logic/create_payment_bloc.dart';
import '../../blocs/Bloc Logic/discount_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc State/create_payment_state.dart';
import '../../blocs/Bloc State/discount_stata.dart';
import '../../blocs/Bloc State/payment_state.dart';
import '../../models/payment/create_payment_model.dart';
import '../../models/payment/payment_summary_model.dart';
import '../../repositories/TIP_repository.dart';
import '../../repositories/coupon_repository.dart';
import '../../repositories/create_payment_repository.dart';
import '../../repositories/discount_repository.dart';
import '../../repositories/service_charge_repository.dart';
import '../../utils/SessionManager.dart';
import 'coupon_widget.dart';
import 'discount_screen.dart';

class paymentsummary extends StatefulWidget {
  final List<Map<String, dynamic>> loadedTables;
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final int? zoneId;
  final int orderId;
  final ValueChanged<double> onMerchantDiscountChanged;
  final ValueChanged<double> onTipChanged;
  final Function(double)? onCouponAmountChanged;
  final double? grandTotal;

  const paymentsummary({
    Key? key,
    required this.loadedTables,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    this.zoneId,
    required PaymentSummary,
    required this.orderId,
    required this.onMerchantDiscountChanged,
    required this.onTipChanged,
    this.onCouponAmountChanged,
    this.grandTotal,
  }) : super(key: key);

  @override
  State<paymentsummary> createState() => _paymentsummaryState();
}

class _paymentsummaryState extends State<paymentsummary> {
  String selectedOption = '';
  String amount = '';
  PaymentSummary? _paymentSummary;
  String _cashierName = "";

  double? calculatedChange;
  String selectedPaymentMode = "Cash";
  bool isCashSelected = true;

  // Inline validation message
  String? tenderAmountError;

  bool _isDiscountApplied = false;
  bool _isCouponApplied = false;
  bool _isTipApplied = false;
  String _appliedCoupon = "";
  bool _isSplitApplied = false;
  double _discountAmount = 0.0;
  double _couponAmount = 0.0;
  double _tipAmount = 0.0;
  double _splitAmount = 0.0;
  double merchantDiscount = 0.0;
  double _lastNetPayable = 0.0;
  bool _isNcDiscount = false;

  double serviceChargeAmount = 0.0;
  int? selectedServiceCharge;
  final serviceChargeRepository = ServiceChargeRepository();
  bool isServiceChargeApplied = false;
  final TipRepository _tipRepository = TipRepository();
  final CreatePaymentRepository _paymentRepository = CreatePaymentRepository();
  final CouponRepository _couponRepository = CouponRepository();

  final TextEditingController discountController = TextEditingController();
  final TextEditingController couponController = TextEditingController();
  final TextEditingController tipController = TextEditingController();
  final TextEditingController splitPayController = TextEditingController();

  bool get isDeleteEnabled =>
      _isTipApplied || _isDiscountApplied || _isCouponApplied;

  // ── FIX: single place that decides "is this tender amount payable".
  // Used by the Pay key (it previously only checked amount.isEmpty, so a
  // "0"/"0.00" tender slipped through and reached _submitPayment).
  bool get _isValidTenderAmount {
    final double? parsed = double.tryParse(amount);
    return parsed != null && parsed > 0;
  }

  @override
  void initState() {
    super.initState();
    // Initialize UI immediately - no loading state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<PaymentBloc>().state;
      if (state is PaymentSummaryLoaded) {
        _syncFromState(state);
      } else {
        // Load summary in background without showing loading
        _reloadSummary();
      }
    });
  }

  void _syncFromState(PaymentSummaryLoaded state) {
    final summary = state.summary;
    final discount = state.merchantDiscount;

    discountController.text =
    discount != 0 ? discount.abs().toStringAsFixed(2) : "";

    if (summary.couponDetails.isNotEmpty) {
      _appliedCoupon = summary.couponDetails.first.code;
      _couponAmount = summary.couponDetails.first.value;
      couponController.text = _appliedCoupon;
      _isCouponApplied = true;
    }

    if (summary.tipAmount > 0) {
      _tipAmount = summary.tipAmount;
      tipController.text = summary.tipAmount.toStringAsFixed(2);
      _isTipApplied = true;
    }

    setState(() {
      _isDiscountApplied = discount != 0;
      merchantDiscount = discount;
      _isNcDiscount = state.isNoCharge;
      _paymentSummary = summary;

      final serviceCharge = summary.serviceChargePercentage ?? 0;
      if (serviceCharge > 0) {
        selectedServiceCharge = serviceCharge.toInt();
        isServiceChargeApplied = true;
      } else {
        selectedServiceCharge = null;
        isServiceChargeApplied = false;
      }

      // ── FIX: this field was declared but never assigned, so the Svc
      // Charges tile had no amount to show. Now it tracks the summary's
      // computed service-charge value and updates whenever % changes.
      serviceChargeAmount = summary.serviceChargeValue;
    });
  }

  @override
  void dispose() {
    discountController.dispose();
    couponController.dispose();
    tipController.dispose();
    splitPayController.dispose();
    super.dispose();
  }

  void _updateAmountField() {
    // Just update the UI - no full rebuild
    setState(() {});
  }

  double getGrandTotal(PaymentState state) {
    if (widget.grandTotal != null) {
      return widget.grandTotal!.abs().roundToDouble();
    }

    final PaymentSummary? summary =
    state is PaymentSummaryLoaded ? state.summary : _paymentSummary;
    if (summary == null) return 0.0;

    final merchantDiscountAbs = merchantDiscount.abs();
    final serviceCharge = summary.serviceChargeValue;

    double basePayable = summary.netTotal;
    if (summary.coupons <= 0) {
      basePayable -= _couponAmount;
    }

    double calculatedPayable =
        basePayable - merchantDiscountAbs + _tipAmount + serviceCharge;
    return calculatedPayable.abs().roundToDouble();
  }

  Future<void> applyServiceCharge(int percentage) async {
    final response = await serviceChargeRepository.applyServiceCharge(
      token: widget.token,
      orderId: widget.orderId,
      percentage: percentage,
    );
    if (response != null && response.success) {
      setState(() {
        selectedServiceCharge = response.serviceChargePercentage;
        isServiceChargeApplied = true;
      });
      _reloadSummary();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Service charge applied successfully"),
            duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> deleteServiceCharge() async {
    final response = await serviceChargeRepository.deleteServiceCharge(
      token: widget.token,
      orderId: widget.orderId,
    );
    if (response != null && response.success) {
      setState(() {
        selectedServiceCharge = null;
        isServiceChargeApplied = false;
        serviceChargeAmount = 0.0; // FIX: clear the displayed amount too
      });
      _reloadSummary();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Service charge removed successfully"),
            duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _submitPayment() async {
    debugPrint("🟡 SUBMIT PAYMENT CALLED");

    // Validate: must enter amount
    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter payment amount"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate: amount must be greater than 0
    final double enteredAmount = double.tryParse(amount) ?? 0.0;
    if (enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid amount greater than 0"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate: must select payment mode
    if (selectedPaymentMode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a payment method (Cash / Card / UPI)"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final orderBloc = context.read<OrderBloc>();
    final orderId = orderBloc.state.orderId;
    final int? userId = await SessionManager.getUserId();
    final int? shiftId = await SessionManager.getShiftId();

    debugPrint(
        "➡️ orderId: $orderId | userId: $userId | shiftId: $shiftId | amount: $amount | mode: $selectedPaymentMode");

    if (orderId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Order not created")));
      return;
    }
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }
    if (shiftId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Shift not started")));
      return;
    }

    debugPrint("✅ ALL VALID — Creating payment...");

    context.read<CreatePaymentBloc>().add(
      CreatePaymentRequested(
        token: widget.token,
        request: CreatePaymentRequest(
          orderId: orderId,
          title: "POS Payment",
          amount: double.parse(amount),
          paymentMethod: selectedPaymentMode,
          shiftId: shiftId,
          userId: userId,
          restaurantId: widget.restaurantId,
          notes: {"source": "POS", "device": "ANDROID"},
        ),
      ),
    );
  }

  Future<void> handleKeyPress(String key) async {
    final netPayable = _getCurrentNetPayable();


    final bool isSummaryReady = _paymentSummary != null ||
        context.read<PaymentBloc>().state is PaymentSummaryLoaded;
    if (isSummaryReady && netPayable <= 0 && key != "Pay") return;

    if (key == "Pay") {
      // ── FIX: was only checking amount.isEmpty — a tender amount of "0"
      // or "0.00" passed through and went straight to _submitPayment.
      // Now uses the same _isValidTenderAmount check as everything else.
      if (!_isValidTenderAmount) {
        final String msg = amount.isEmpty
            ? "Please enter the amount"
            : "Amount must be greater than 0";
        setState(() => tenderAmountError = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      await _submitPayment();
      return;
    }

    if (key == "C") {
      setState(() {
        amount = '';
        tenderAmountError = null;
      });
      return;
    }
    if (key == "⌫") {
      if (amount.isNotEmpty) {
        setState(() {
          amount = amount.substring(0, amount.length - 1);
          tenderAmountError = null;
        });
      }
      return;
    }
    if (!RegExp(r'^[0-9.]+$').hasMatch(key)) return;
    if (key == "." && amount.contains(".")) return;

    setState(() {
      amount += key;
      tenderAmountError = null;
    });
  }

  double _getCurrentNetPayable() {
    final state = context.read<PaymentBloc>().state;
    return getGrandTotal(state);
  }

  Future<void> _onPaymentModeTap(String mode) async {
    if (amount.isEmpty) {
      setState(() {
        selectedPaymentMode = mode;
        isCashSelected = mode == "Cash";
        tenderAmountError = "Please enter the amount";
      });
      return;
    }

    // Check if amount is 0
    final double enteredAmount = double.tryParse(amount) ?? 0.0;
    if (enteredAmount <= 0) {
      setState(() {
        selectedPaymentMode = mode;
        isCashSelected = mode == "Cash";
        tenderAmountError = "Please enter a valid amount";
      });
      return;
    }

    setState(() {
      selectedPaymentMode = mode;
      isCashSelected = mode == "Cash";
      tenderAmountError = null;
    });
    await _submitPayment();
  }

  void _onPresetAmountTap(String value) {
    // Don't allow 0 amount
    if (double.tryParse(value) == 0) return;
    setState(() {
      amount = value;
      tenderAmountError = null;
    });
  }

  List<double> buildPresetAmounts(double total) {
    if (total <= 0) return [];
    final List<double> result = [];
    final Set<double> seen = {};

    void add(double value) {
      if (seen.add(value)) result.add(value);
    }

    add(total);
    int step = 50;
    double current = total;

    while (result.length < 4) {
      final next = (current / step).ceil() * step;
      if (next > total) add(next.toDouble());
      current = next + 1;
      if (result.length == 2) step = 100;
      if (result.length == 3) step = 200;
    }

    result.sort();
    return result;
  }

  void _reloadSummary() {
    context.read<PaymentBloc>().add(
      LoadPaymentSummary(
        token: widget.token,
        orderId: widget.orderId,
        restaurantId: widget.restaurantId,
        orderType: "Dine In",
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    debugPrint("🔥 paymentsummary build called");

    return MultiBlocListener(
      listeners: [
        // PaymentBloc: only sync local fields
        BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }
            if (state is PaymentSummaryLoaded) {
              _paymentSummary = state.summary;
              _syncFromState(state);
            }
          },
        ),

        // CreatePaymentBloc: result handling
        BlocListener<CreatePaymentBloc, CreatePaymentState>(
          listener: (context, state) async {
            if (state is CreatePaymentSuccess) {
              final paymentBlocState = context.read<PaymentBloc>().state;
              if (paymentBlocState is! PaymentSummaryLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Payment summary not available")),
                );
                return;
              }

              final summary = paymentBlocState.summary;
              final action = await showDialog<String>(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.black.withOpacity(0.4),
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.zero,
                  child: Center(
                    child: Paymentsucess(
                      amount: state.response.paidAmount.toString(),
                      paymentMode: selectedPaymentMode,
                      changeAmount:
                      state.response.change.toStringAsFixed(2),
                      paymentId: state.response.paymentId,
                      orderId: state.response.orderId,
                      loadedTables: widget.loadedTables,
                      pin: widget.pin,
                      token: widget.token,
                      restaurantId: widget.restaurantId,
                      zoneId: widget.zoneId,
                      restaurantName: '',
                      paymentSummary: summary,
                      cashierName: _cashierName,
                    ),
                  ),
                ),
              );
              if (!mounted) return;

              if (action == "void") {
                try {
                  final message = await _paymentRepository.voidPayment(
                    token: widget.token,
                    paymentId: state.response.paymentId,
                    orderId: state.response.orderId,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(message),
                        duration: const Duration(seconds: 1)),
                  );
                  setState(() {
                    amount = '';
                    tenderAmountError = null;
                  });
                  // _reloadSummary();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        duration: const Duration(seconds: 1)),
                  );
                }
              } else {
                context.read<OrderBloc>().add(ClearOrder());
              }
            }

            if (state is CreatePaymentFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.error),
                    duration: const Duration(seconds: 1)),
              );
            }
          },
        ),

        // RemoveDiscountBloc
        BlocListener<RemoveDiscountBloc, RemoveDiscountState>(
          listener: (context, state) {
            if (state is RemoveDiscountSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.response.message),
                    duration: const Duration(seconds: 1)),
              );
              setState(() {
                _isDiscountApplied = false;
                _isNcDiscount = false;
                _discountAmount = 0;
                merchantDiscount = 0.0;
                discountController.clear();
              });
              context.read<PaymentBloc>().add(UpdateMerchantDiscount(0.0));
              widget.onMerchantDiscountChanged(0.0);
              _updateAmountField();
              // _reloadSummary();
            }
            if (state is RemoveDiscountFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.error),
                    duration: const Duration(seconds: 1)),
              );
            }
          },
        ),
      ],

      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F6),
        // UI is always visible - no loading state
        body:
        BlocBuilder<PaymentBloc, PaymentState>(
          buildWhen: (prev, curr) {
            // Only rebuild when we have data and values changed
            if (curr is! PaymentSummaryLoaded) return false;
            if (prev is PaymentSummaryLoaded) {
              return curr.summary.netTotal != prev.summary.netTotal ||
                  curr.summary.serviceChargeValue !=
                      prev.summary.serviceChargeValue ||
                  curr.merchantDiscount != prev.merchantDiscount;
            }
            return true;
          },
          builder: (context, payState) {
            final double netPayableVal = getGrandTotal(payState);

            final bool isSummaryReady =
                payState is PaymentSummaryLoaded || _paymentSummary != null;
            final bool payDisabled = isSummaryReady && netPayableVal <= 0;

            final double tenderAmt =
            amount.isNotEmpty ? double.tryParse(amount) ?? 0.0 : 0.0;
            final double balAmt = tenderAmt < netPayableVal
                ? (netPayableVal - tenderAmt)
                : 0.0;

            final List<double> presets = buildPresetAmounts(netPayableVal);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT — Numpad
                Expanded(
                  child: _buildNumpadColumn(
                    context,
                    netPayableVal: netPayableVal,
                    payDisabled: payDisabled,
                    presets: presets,
                  ),
                ),

                const SizedBox(width: 10),

                // RIGHT — Amounts + Action tiles
                _buildRightColumn(
                  context,
                  netPayableVal: netPayableVal,
                  balAmt: balAmt,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumpadColumn(
      BuildContext context, {
        required double netPayableVal,
        required bool payDisabled,
        required List<double> presets,
      }) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Tender Amount:",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3D5A9A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: tenderAmountError != null
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFFB3C7FF),
                              width: tenderAmountError != null ? 1.4 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: tenderAmountError != null
                                ? const Color(0xFFFFF3F3)
                                : Colors.white,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              (amount.isEmpty || payDisabled) ? "0.00" : amount,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: payDisabled
                                    ? Colors.grey
                                    : const Color(0xFF212121),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tenderAmountError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Color(0xFFE53935),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tenderAmountError!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _numRow(["7", "8", "9"], payDisabled),
                        _numRow(["4", "5", "6"], payDisabled),
                        _numRow(["1", "2", "3"], payDisabled),
                        _numRow(["00", "0", "⌫"], payDisabled),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        ...presets.take(3).map(
                              (v) => _presetBtn(v, payDisabled),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: GestureDetector(
                              onTap: () => handleKeyPress("C"),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEB),
                                  borderRadius: BorderRadius.circular(10),
                                  // ── ONLY CHANGE: blue-tinted shadow bottom+right ──
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xCCF0A0A0),
                                      blurRadius: 0,
                                      spreadRadius: 0,
                                      offset: Offset(3, 3),
                                    ),
                                    BoxShadow(
                                      color: Color(0x55DC6464),
                                      blurRadius: 8,
                                      offset: Offset(4, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text("C",
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE53935))),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _payModeBtn(
                    "Cash",
                    const Color.fromRGBO(156, 205, 123, 1),
                    "assets/cash.png",
                  ),
                  const SizedBox(width: 10),
                  _payModeBtn(
                    "Card",
                    const Color.fromRGBO(164, 132, 200, 1),
                    "assets/card.png",
                  ),
                  const SizedBox(width: 10),
                  _payModeBtn(
                    "UPI",
                    const Color.fromRGBO(204, 185, 133, 1),
                    "assets/icon/upi.png",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numRow(List<String> keys, bool disabled) {
    return Expanded(
      child: Row(
        children: keys.map((k) {
          final bool isBackspace = k == "⌫";
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: GestureDetector(
                onTap: disabled ? null : () => handleKeyPress(k),
                child: Container(
                  decoration: BoxDecoration(
                    color: disabled
                        ? Colors.grey.shade100
                        : isBackspace
                        ? const Color(0xFFF0F0F0)
                        : const Color(0xFFF2F5FF),
                    borderRadius: BorderRadius.circular(10),
                    // ── ONLY CHANGE: blue-tinted shadow bottom+right ──
                    boxShadow: disabled
                        ? []
                        : [
                      BoxShadow(
                        color: isBackspace
                            ? const Color(0xCCB4C8DC)
                            : const Color(0xCCB4C8F0),
                        blurRadius: 0,
                        spreadRadius: 0,
                        offset: const Offset(3, 3),
                      ),
                      BoxShadow(
                        color: isBackspace
                            ? const Color(0x5596B4D0)
                            : const Color(0x5596B4E6),
                        blurRadius: 8,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: isBackspace
                      ? Icon(Icons.backspace_outlined,
                      color: disabled
                          ? Colors.grey
                          : const Color(0xFF4C5F7D),
                      size: 22)
                      : Text(k,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: disabled
                            ? Colors.grey
                            : const Color(0xFF4C5F7D),
                      )),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _presetBtn(double value, bool disabled) {
    if (value <= 0) return const SizedBox.shrink();

    final bool isSelected = amount == value.toStringAsFixed(2);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: GestureDetector(
          onTap: disabled ? null : () => _onPresetAmountTap(value.toStringAsFixed(2)),
          child: Container(
            decoration: BoxDecoration(
              color: disabled
                  ? Colors.grey.shade200
                  : isSelected
                  ? const Color(0xFFDFF5E1)
                  : const Color(0xFFE6F9E0),
              borderRadius: BorderRadius.circular(10),
              // ── ONLY CHANGE: green-tinted shadow bottom+right ──
              boxShadow: disabled
                  ? []
                  : const [
                BoxShadow(
                  color: Color(0xCC96D2A0),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: Offset(3, 3),
                ),
                BoxShadow(
                  color: Color(0x5564B478),
                  blurRadius: 8,
                  offset: Offset(4, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              "₹${value.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: disabled ? Colors.grey : const Color(0xFF318616)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }



  Widget _payModeBtn(String mode, Color color, String asset) {
    final bool isSelected = selectedPaymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPaymentModeTap(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.transparent),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mode,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(width: 10),

              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    asset,
                    width: 18,
                    height: 18,
                    color: color, // icon color inside white circle
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RIGHT COLUMN
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildRightColumn(
      BuildContext context, {
        required double netPayableVal,
        required double balAmt,
      }) {
    final double screenW = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenW * 0.19,
      child: Column(
        children: [
          const SizedBox(height: 12),

          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                // children: [
                //   _netAmountCard(netPayableVal),
                //   const SizedBox(height: 10),
                //   _balanceAmountCard(balAmt),
                // ],
                children: [
                  const SizedBox(height: 12),

                  // Each card is now its own white elevated card (matches image)
                  _netAmountCard(netPayableVal),
                  const SizedBox(height: 10),
                  _balanceAmountCard(balAmt),

                  const SizedBox(height: 14),

                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildActionButtons(context, netPayableVal),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: _buildActionButtons(context, netPayableVal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _netAmountCard(double value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Net Amount",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B7B8D),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 7),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5D6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    // Custom Image for Net Amount
                    SizedBox(
                      width: 52,
                      height: 50,
                      child: Image.asset(
                        "assets/net_amount.png",   // ← Your custom icon
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceAmountCard(double value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Balance Amount",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B7B8D),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 7),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EAF7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    // Custom Image instead of _coinsWidget()
                    SizedBox(
                      width: 54,
                      height: 50,
                      child: Image.asset(
                        "assets/balance_amount.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }  // Shared builder: plain label above a soft gradient pill (value + icon).
  Widget _gradientAmountCard({
    required String label,
    required String value,
    required List<Color> gradientColors,
    Widget? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 30),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (icon != null)
                Positioned(
                  right: -2,
                  bottom: -4,
                  child: icon,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _moneyBagWidget() {
    return SizedBox(
      width: 56,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 8,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [Color(0xFFC5D98C), Color(0xFF8DAD50)],
                  center: Alignment(-0.3, -0.3),
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF6B8A30).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: const Center(
                child: Text(
                  "₹",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 18,
            child: Container(
              width: 20,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF7A9A42),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 16,
            child: Container(
              width: 24,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF5A7A2A),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 20,
            child: Column(
              children: [
                Container(
                    width: 12,
                    height: 2,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(1))),
                const SizedBox(height: 3),
                Container(
                    width: 8,
                    height: 2,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(1))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coinsWidget() {
    return SizedBox(
      width: 60,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [Color(0xFFD8A8D0), Color(0xFFB070A8)],
                  center: Alignment(-0.3, -0.3),
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF9850A0), width: 1.5),
              ),
            ),
          ),
          Positioned(
            left: 2,
            bottom: 2,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [Color(0xFFC890C0), Color(0xFF9860A0)],
                  center: Alignment(-0.3, -0.3),
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7840A0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF9B59B6).withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: const Center(
                child: Text(
                  "₹",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.auto_awesome,
                size: 18, color: Color(0xFF9B59B6)),
          ),
          const Positioned(
            top: 16,
            right: 8,
            child: Icon(Icons.lens, size: 5, color: Color(0xFFBB80C8)),
          ),
          const Positioned(
            top: 8,
            left: 20,
            child:
            Icon(Icons.lens, size: 4, color: Color(0xFFBB80C8)),
          ),
        ],
      ),
    );
  }

  // Action buttons section
  Widget _buildActionButtons(BuildContext context, double netPayable) {
    return Column(
      children: [
        // Discounts
        _actionTile(
          label: "Discounts",
          borderColor: const Color(0xFF1E88E5),
          iconBg: const Color(0xFF2563EB),
          // icon: Icons.discount_rounded,
          iconWidget: Image.asset(  // ← Now correctly passed
            "assets/discount_rounded.png",
            width: 14,
            height:12,
            color: Colors.white,
          ),
          isApplied: _isDiscountApplied,
          appliedText: discountController.text.isNotEmpty
              ? "₹${discountController.text}"
              : null,
          onTap: _isDiscountApplied
              ? null
              : () async {
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              barrierDismissible: false,
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                      create: (_) => DiscountReasonBloc(
                          DiscountReasonRepository())),
                  BlocProvider.value(
                      value: context.read<DiscountBloc>()),
                ],
                child: DiscountPopup(
                  netPayable: netPayable,
                  orderId: widget.orderId,
                ),
              ),
            );
            if (result != null) {
              final double applied =
              (result["amount"] as double).abs();
              discountController.text = applied.toStringAsFixed(2);
              setState(() => _isDiscountApplied = true);
              // _reloadSummary();
            }
          },
          onDelete: _isDiscountApplied
              ? () {
            final paymentState = context.read<PaymentBloc>().state;
            String isNcFlag = "no";
            if (paymentState is PaymentSummaryLoaded) {
              isNcFlag = paymentState.isNoCharge ? "yes" : "no";
            }
            context.read<RemoveDiscountBloc>().add(
              RemoveDiscountRequested(
                orderId: widget.orderId,
                isNc: isNcFlag,
                token: widget.token,
              ),
            );
          }
              : null,
        ),

        const SizedBox(height: 8),

        // Coupons
        _actionTile(
          label: "Coupons",
          borderColor: const Color(0xFFE65100),
          iconBg: const Color(0xFFE65100),
          // icon: Icons.local_offer_rounded,
          iconWidget: Image.asset(  // ← Now correctly passed
            "assets/Coupon_icon.png",
            width: 22,
            height: 22,
            color: Colors.white,
          ),
          isApplied: _isCouponApplied,
          appliedText: _appliedCoupon.isNotEmpty ? _appliedCoupon : null,
          onTap: _isCouponApplied
              ? null
              : () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Couponscreen(
                orderId: widget.orderId,
                token: widget.token,
                onCouponApplied: (coupon, amt) {
                  setState(() {
                    _isCouponApplied = true;
                    _appliedCoupon = coupon;
                    _couponAmount = amt;
                    couponController.text = coupon;
                  });
                  widget.onCouponAmountChanged?.call(amt);
                  // _reloadSummary();
                },
              ),
            );
          },
          onDelete: _isCouponApplied
              ? () async {
            final success = await _couponRepository.removeCoupon(
              token: widget.token,
              orderId: widget.orderId,
            );
            if (success) {
              setState(() {
                _isCouponApplied = false;
                _appliedCoupon = '';
                _couponAmount = 0.0;
                couponController.clear();
              });
              widget.onCouponAmountChanged?.call(0.0);
              // _reloadSummary();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Coupon removed successfully"),
                    duration: Duration(seconds: 1)),
              );
            }
          }
              : null,
        ),

        const SizedBox(height: 8),

        // Tips
        _actionTile(
          label: "Tips",
          borderColor: const Color(0xFF2E7D32),
          iconBg: const Color(0xFF2E7D32),
          // icon: Icons.volunteer_activism_rounded,
          iconWidget: Image.asset(  // ← Now correctly passed
            "assets/Tips_icon.png",
            width: 22,
            height: 22,
            color: Colors.white,
          ),
          isApplied: _isTipApplied,
          appliedText:
          _isTipApplied ? "₹${_tipAmount.toStringAsFixed(2)}" : null,
          onTap: _isTipApplied
              ? null
              : () async {
            final double? result = await showDialog<double>(
              context: context,
              barrierDismissible: false,
              builder: (_) => TipPopup(
                orderId: widget.orderId,
                token: widget.token,
                onTipApplied: (amt) {
                  setState(() {
                    _isTipApplied = true;
                    _tipAmount = amt;
                    tipController.text = amt.toStringAsFixed(2);
                  });
                  widget.onTipChanged(amt);
                  // _reloadSummary();
                },
              ),
            );
            if (result != null && result > 0) {
              setState(() {
                _isTipApplied = true;
                _tipAmount = result;
                tipController.text = result.toStringAsFixed(2);
              });
              widget.onTipChanged(result);
              // _reloadSummary();
            }
          },
          onDelete: _isTipApplied
              ? () async {
            final success = await _tipRepository.removeTip(
              token: widget.token,
              orderId: widget.orderId,
            );
            if (success) {
              setState(() {
                _isTipApplied = false;
                _tipAmount = 0;
                tipController.clear();
              });
              widget.onTipChanged(0);
              _updateAmountField();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Tip removed successfully'),
                    duration: Duration(seconds: 1)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Failed to remove tip'),
                    duration: Duration(seconds: 1)),
              );
            }
          }
              : null,
        ),

        const SizedBox(height: 8),

        // Svc Charges
        _svcChargeTile(context),
      ],
    );
  }

  Widget _actionTile({
    required String label,
    required Color borderColor,
    required Color iconBg,
    IconData? icon,
    Widget? iconWidget,
    required bool isApplied,
    String? appliedText,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    // ── Only change: gradient per tile color ──
    LinearGradient _tileGradient(Color base) {
      if (base == const Color(0xFF1E88E5)) {
        return const LinearGradient(
          colors: [Color(0xFF5B9EF0), Color(0xFF3A7BDB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      } else if (base == const Color(0xFFE65100)) {
        return const LinearGradient(
          colors: [Color(0xFF5CC96A), Color(0xFF2EA83C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      } else if (base == const Color(0xFF2E7D32)) {
        return const LinearGradient(
          colors: [Color(0xFFFFCC55), Color(0xFFF5950A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      }
      return LinearGradient(colors: [base, base]);
    }

    final Color labelColor = isApplied ? Colors.white : borderColor;
    final Color subColor = isApplied
        ? Colors.white.withOpacity(0.9)
        : borderColor.withOpacity(0.8);
    final Color activeBorder = isApplied
        ? iconBg
        : borderColor.withOpacity(0.4);

    return GestureDetector(
      onTap: isApplied ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // ── Only change: gradient when applied, white when not ──
          gradient: isApplied ? _tileGradient(iconBg) : null,
          color: isApplied ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: activeBorder,
              width: isApplied ? 0 : 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  if (appliedText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      appliedText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isApplied && onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  // ── Only change: trash icon instead of close ──
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 15, color: Colors.red),
                ),
              )
            else
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                // ── Only change: iconWidget wrapped in CircleAvatar ──
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.transparent,
                  child: iconWidget ??
                      (icon != null
                          ? Icon(icon, color: Colors.white, size: 18)
                          : const Icon(Icons.help_outline,
                          color: Colors.white, size: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _svcChargeTile(BuildContext context) {
    final bool applied =
        isServiceChargeApplied && selectedServiceCharge != null;
    final Color base = const Color(0xFFC62828);
    final Color labelColor =
    applied ? Colors.white : const Color(0xFFC62828);
    final Color subColor = Colors.white.withOpacity(0.9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // ── Only change: red gradient when applied ──
        gradient: applied
            ? const LinearGradient(
          colors: [Color(0xFFFF7A7A), Color(0xFFE84040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: applied ? null : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: applied ? Colors.transparent : base.withOpacity(0.4),
          width: applied ? 0 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Svc Charges",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: labelColor)),
                if (applied) ...[
                  const SizedBox(height: 2),
                  Text(
                    "${selectedServiceCharge}%",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: subColor),
                  ),
                ],
                if (!applied)
                  SizedBox(
                    height: 26,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedServiceCharge,
                        isDense: true,
                        hint: const Text("Select %",
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF777777))),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF212121)),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text("1%")),
                          DropdownMenuItem(value: 2, child: Text("2%")),
                          DropdownMenuItem(value: 3, child: Text("3%")),
                          DropdownMenuItem(value: 4, child: Text("4%")),
                          DropdownMenuItem(value: 5, child: Text("5%")),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          applyServiceCharge(v);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (applied)
            GestureDetector(
              onTap: deleteServiceCharge,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                // ── Only change: trash icon ──
                child: const Icon(Icons.delete_outline_rounded,
                    size: 15, color: Colors.red),
              ),
            )
          else
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: Color(0xFFC62828), shape: BoxShape.circle),
              // ── Only change: icon wrapped in CircleAvatar ──
              child: const CircleAvatar(
                radius: 17,
                backgroundColor: Colors.transparent,
                child: Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(
      String label,
      String value, {
        bool bold = false,
        Color? labelColor,
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: bold ? 13 : 12,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: labelColor ?? const Color(0xFF444444),
                )),
          ),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 13 : 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? const Color(0xFF212121),
              )),
        ],
      ),
    );
  }
}

// ─── NumberPad ─────────────────────────────────────────────────────────
class NumberPad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final String selectedPaymentMode;
  final bool isPaying;

  const NumberPad({
    super.key,
    required this.onKeyPressed,
    required this.selectedPaymentMode,
    required this.isPaying,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildRow(["1", "2", "3"]),
              _buildRow(["4", "5", "6"]),
              _buildRow(["7", "8", "9"]),
              _buildRow(["00", ".", "0"]),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildSideButton("⌫"),
              _buildSideButton("C"),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => onKeyPressed("Pay"),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedPaymentMode.isNotEmpty
                            ? const Color(0xFFFE6464)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "PAY",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: selectedPaymentMode.isNotEmpty
                              ? Colors.white
                              : const Color(0xFF4C5F7D),
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
    );
  }

  Widget _buildRow(List<String> labels) {
    return Expanded(
      child: Row(
          children: labels.map((label) => _buildButton(label)).toList()),
    );
  }

  Widget _buildButton(String label,
      {int flex = 1,
        Color? backgroundColor,
        Color? textColor,
        BoxBorder? border,
        bool isPayButton = false}) {
    final bool isNumber = RegExp(r'^(\d+|00|\.)\$').hasMatch(label);
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => onKeyPressed(label),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: border,
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ],
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    fontSize: isNumber ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? const Color(0xFF4C5F7D))),
          ),
        ),
      ),
    );
  }

  Widget _buildSideButton(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => onKeyPressed(label),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ],
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C5F7D))),
          ),
        ),
      ),
    );
  }
}

// ─── Standalone helper widgets ─────────────────────────────────────────
Widget _inputField({
  required String hint,
  required TextEditingController controller,
  bool enabled = true,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(6)),
    child: TextFormField(
      controller: controller,
      readOnly: true,
      keyboardType: keyboardType,
      decoration:
      InputDecoration(hintText: hint, border: InputBorder.none),
    ),
  );
}

Widget _deleteButton(VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.delete, size: 18, color: Colors.red),
    ),
  );
}