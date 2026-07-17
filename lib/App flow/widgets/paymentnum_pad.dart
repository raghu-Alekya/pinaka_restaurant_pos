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
import '../../models/payment/discount_model.dart';
import '../../models/payment/payment_summary_model.dart';
import '../../repositories/TIP_repository.dart';
import '../../repositories/coupon_repository.dart';
import '../../repositories/create_payment_repository.dart';
import '../../repositories/discount_repository.dart';
import '../../repositories/service_charge_repository.dart';
import '../../utils/SessionManager.dart';
import '../ui/dashboard screen.dart';
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
  final bool isTakeAway; // ➕ NEW — defaults to false so no existing call breaks
  final ValueChanged<double> onMerchantDiscountChanged;
  final ValueChanged<double> onTipChanged;
  final Function(double)? onCouponAmountChanged;
  final double? grandTotal;
  final ValueChanged<bool>? onPartialPaymentChanged;

  const paymentsummary({
    Key? key,
    required this.loadedTables,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    this.zoneId,
    this.isTakeAway = false, // ➕ NEW
    required PaymentSummary,
    required this.orderId,
    required this.onMerchantDiscountChanged,
    required this.onTipChanged,
    this.onCouponAmountChanged,
    this.grandTotal,
    this.onPartialPaymentChanged,
  }) : super(key: key);

  @override
  State<paymentsummary> createState() => _paymentsummaryState();
}

class _paymentsummaryState extends State<paymentsummary> {
  String selectedOption = '';
  String amount = '';
  PaymentSummary? _paymentSummary;
  String _cashierName = "";
  String _currencySymbol = "₹";

  double? calculatedChange;
  String selectedPaymentMode = "Cash";
  bool isCashSelected = true;
  bool _isPaymentLoading = false;
  String _loadingPaymentMode = "";

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
  String? _lastAppliedDiscountStr;
  String? _lastAppliedDiscountReason;

  bool _balanceRevealed = false;
  double _confirmedTenderForBalance = 0.0;

  // ➕ NEW — tracks how much of the current order has already been
  // collected across one or more partial ("split") payments. This is
  // purely additive: while it stays at 0.0 (the default), every existing
  // calculation below behaves exactly as it did before.
  double _totalPaidAmount = 0.0;

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

  bool get _isValidTenderAmount {
    final double? parsed = double.tryParse(amount);
    return parsed != null && parsed > 0;
  }

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await SessionManager.getCurrencySymbol();

    setState(() {
      _currencySymbol = symbol;
    });
  }

  void _syncFromState(PaymentSummaryLoaded state) {
    print("========== _syncFromState CALLED ==========");
    debugPrint("_syncFromState -> state.isNoCharge = ${state.isNoCharge}");

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
    // else {
    //   _appliedCoupon = "";
    //   _couponAmount = 0.0;
    //   couponController.clear();
    //   _isCouponApplied = false;
    // }
    debugPrint("Coupon Details = ${summary.couponDetails}");
    debugPrint("Tip Amount = ${summary.tipAmount}");

    if (summary.tipAmount > 0) {
      _tipAmount = summary.tipAmount;
      tipController.text = summary.tipAmount.toStringAsFixed(2);
      _isTipApplied = true;
    } else {
      _tipAmount = 0.0;
      tipController.clear();
      _isTipApplied = false;
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

  double _roundMoney(double value) {
    final double fractional = value - value.floorToDouble();
    return fractional >= 0.5
        ? value.floorToDouble() + 1
        : value.floorToDouble();
  }

  double getGrandTotal(PaymentState state) {
    if (widget.grandTotal != null) {
      return _roundMoney(widget.grandTotal!.abs());
    }

    final bool isStateValid = state is PaymentSummaryLoaded && state.summary.orderId == widget.orderId;
    final bool isSummaryValid = _paymentSummary != null && _paymentSummary!.orderId == widget.orderId;
    final PaymentSummary? summary =
        isStateValid ? state.summary : (isSummaryValid ? _paymentSummary : null);
    if (summary == null) return 0.0;

    final merchantDiscountAbs = merchantDiscount.abs();
    final serviceCharge = summary.serviceChargeValue;

    double basePayable = summary.netTotal - summary.serviceChargeValue;
    if (summary.coupons <= 0) {
      basePayable -= _couponAmount;
    }

    double calculatedPayable =
        basePayable - merchantDiscountAbs + _tipAmount + serviceCharge;
    // ── FIX: was `.roundToDouble()`, replaced with the explicit
    // "round .50+ up" helper so the displayed Net Amount always matches
    // what the backend will settle as the order total.
    return _roundMoney(calculatedPayable.abs());
  }

  double getNetTotal() {
    final state = context.read<PaymentBloc>().state;
    final bool isStateValid = state is PaymentSummaryLoaded && state.summary.orderId == widget.orderId;
    final bool isSummaryValid = _paymentSummary != null && _paymentSummary!.orderId == widget.orderId;
    final PaymentSummary? summary =
        isStateValid ? state.summary : (isSummaryValid ? _paymentSummary : null);
    if (summary == null) return 0.0;
    final double couponsVal = summary.coupons > 0 ? summary.coupons : _couponAmount;
    return summary.grossTotal - couponsVal + summary.tax;
  }

  // ➕ NEW — full order total minus whatever has already been collected
  // through earlier partial ("split") payments for this order. When no
  // partial payment has been made (_totalPaidAmount == 0.0, the default)
  // this returns exactly the same value as getGrandTotal(state) — so
  // nothing changes for the normal, non-split-payment flow.
  double _remainingNetPayable(PaymentState state) {
    final double full = getGrandTotal(state);
    final double remaining = full - _totalPaidAmount;
    return remaining < 0 ? 0.0 : remaining;
  }

  // ➕ NEW — safe numeric parsing used only for the partial-payment math.
  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
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
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
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
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _submitPayment() async {
    debugPrint("🟡 SUBMIT PAYMENT CALLED");

    // Validate amount only for normal payments
    if (!_isNcDiscount) {
      if (amount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter payment amount"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      final double enteredAmount = double.tryParse(amount) ?? 0.0;
      if (enteredAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid amount greater than 0"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
    }

    // Validate payment mode
    if (selectedPaymentMode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a payment method (Cash / Card / UPI)"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final orderBloc = context.read<OrderBloc>();
    final orderId = orderBloc.state.orderId;
    final int? userId = await SessionManager.getUserId();
    final int? shiftId = await SessionManager.getShiftId();

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order not created"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User not logged in"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (shiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Shift not started"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<CreatePaymentBloc>().add(
      CreatePaymentRequested(
        token: widget.token,
        request: CreatePaymentRequest(
          orderId: orderId,
          title: "POS Payment",
          amount: _isNcDiscount ? 0.0 : double.parse(amount),
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

    final bool isSummaryReady =
        _paymentSummary != null ||
        context.read<PaymentBloc>().state is PaymentSummaryLoaded;
    if (isSummaryReady && netPayable <= 0 && key != "Pay") return;

    if (key == "Pay") {
      // ── FIX: was only checking amount.isEmpty — a tender amount of "0"
      // or "0.00" passed through and went straight to _submitPayment.
      // Now uses the same _isValidTenderAmount check as everything else.
      if (!_isValidTenderAmount) {
        final String msg =
            amount.isEmpty
                ? "Please enter the amount"
                : "Amount must be greater than 0";
        setState(() => tenderAmountError = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
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
        // ── NEW: clearing the tender amount also hides the Balance Amount
        // again until a payment mode is tapped/confirmed afresh.
        _balanceRevealed = false;
        _confirmedTenderForBalance = 0.0;
      });
      return;
    }
    if (key == "⌫") {
      if (amount.isNotEmpty) {
        setState(() {
          amount = amount.substring(0, amount.length - 1);
          tenderAmountError = null;
          // ── NEW: editing the amount invalidates the previously
          // confirmed balance until it's re-confirmed via payment mode tap.
          _balanceRevealed = false;
          _confirmedTenderForBalance = 0.0;
        });
      }
      return;
    }
    if (!RegExp(r'^[0-9.]+$').hasMatch(key)) return;
    if (key == "." && amount.contains(".")) return;

    setState(() {
      amount += key;
      tenderAmountError = null;
      // ── NEW: any digit typed resets the balance reveal — balance only
      // comes back once a payment mode is tapped again for this amount.
      _balanceRevealed = false;
      _confirmedTenderForBalance = 0.0;
    });
  }

  double _getCurrentNetPayable() {
    final state = context.read<PaymentBloc>().state;
    // ➕ CHANGED: now returns the *remaining* balance (full total minus
    // whatever has already been collected via partial payments) instead
    // of always returning the full order total. When no partial payment
    // has ever been made (_totalPaidAmount == 0.0) this is identical to
    // the original `getGrandTotal(state)` return value, so every existing
    // caller of this method keeps working exactly as before.
    return _remainingNetPayable(state);
  }

  Future<void> _onPaymentModeTap(String mode) async {
    // Skip tender amount validation for NC orders
    if (!_isNcDiscount) {
      if (amount.isEmpty) {
        setState(() {
          selectedPaymentMode = mode;
          isCashSelected = mode == "Cash";
          tenderAmountError = "Please enter the amount";
        });
        return;
      }

      final double enteredAmount = double.tryParse(amount) ?? 0.0;
      // Restrict Card payment to Net Payable / Remaining Payable
      if (mode == "Card") {
        final double remainingPayable = _getCurrentNetPayable();

        if (enteredAmount > remainingPayable) {
          setState(() {
            selectedPaymentMode = mode;
            isCashSelected = false;
            tenderAmountError =
            "Card payment cannot exceed the Net Payable amount.";
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Card payment cannot exceed the Net Payable amount.",
              ),
              backgroundColor: Colors.red,
            ),
          );

          return;
        }
      }
      if (enteredAmount <= 0) {
        setState(() {
          selectedPaymentMode = mode;
          isCashSelected = mode == "Cash";
          tenderAmountError = "Please enter a valid amount";
        });
        return;
      }
    }

    // Show loader
    setState(() {
      selectedPaymentMode = mode;
      isCashSelected = mode == "Cash";
      tenderAmountError = null;

      _isPaymentLoading = true;
      _loadingPaymentMode = mode;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;

      setState(() {
        _balanceRevealed = true;
        _confirmedTenderForBalance =
            _isNcDiscount ? 0.0 : (double.tryParse(amount) ?? 0.0);
      });

      // ➕ NEW — purely informational: lets us log whether this tap is
      // going to be a partial ("split") payment or a full settlement.
      // Does not change any control flow.
      final double remainingBeforeThisTxn = _getCurrentNetPayable();
      final double enteredAmountForLog =
          _isNcDiscount ? 0.0 : (double.tryParse(amount) ?? 0.0);
      final bool isPartialAttempt =
          enteredAmountForLog < remainingBeforeThisTxn - 0.01;
      debugPrint(
        isPartialAttempt
            ? "🟠 PARTIAL PAYMENT — sending ₹${enteredAmountForLog.toStringAsFixed(2)} via create-payment (balance before this txn: ₹${remainingBeforeThisTxn.toStringAsFixed(2)})"
            : "🟢 FULL PAYMENT — sending $_currencySymbol${enteredAmountForLog.toStringAsFixed(2)} via create-payment",
      );

      await _submitPayment();
    } finally {
      if (mounted) {
        setState(() {
          _isPaymentLoading = false;
          _loadingPaymentMode = "";
        });
      }
    }
  }

  void _onPresetAmountTap(String value) {
    // Don't allow 0 amount
    if (double.tryParse(value) == 0) return;
    setState(() {
      amount = value;
      tenderAmountError = null;
      // ── NEW: tapping a preset amount is still just "typing" the amount —
      // balance should not move until a payment mode is confirmed.
      _balanceRevealed = false;
      _confirmedTenderForBalance = 0.0;
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
        zoneId: widget.zoneId,
        orderType: widget.isTakeAway ? "Take Away" : "Dine In",
      ),
    );
  }

  // ➕ NEW — Void / Next Payment popup shown when a tendered amount is less
  // than the remaining balance (a partial / split payment).
  Future<String?> _showPartialPaymentDialog({
    required double paidAmount,
    required double remainingAmount,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (dialogContext) {
        return Center(
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.45,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFFFFE0B2), Color(0xFFFFFFFF)],
                      ),
                      borderRadius: BorderRadius.circular(63),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.info_rounded,
                        size: 55,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Partial Payment Received!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4C5F7D),
                      fontSize: 22,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildPartialInfoRow(
                    dialogContext,
                    "Amount Paid",
                    paidAmount.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 15),
                  _buildPartialBalanceRow(
                    dialogContext,
                    remainingAmount.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPartialActionButton(
                        dialogContext,
                        label: 'Void',
                        color: const Color(0xFFFD6464),
                        onTap: () => Navigator.of(dialogContext).pop("void"),
                      ),
                      const SizedBox(width: 30),
                      _buildPartialActionButton(
                        dialogContext,
                        label: 'Next Payment',
                        color: const Color(0xFF1BA672),
                        onTap: () => Navigator.of(dialogContext).pop("next"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ➕ NEW — styled the same as Paymentsucess._buildInfoRow.
  Widget _buildPartialInfoRow(
    BuildContext context,
    String label,
    String amountText,
  ) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.07,
      width: MediaQuery.of(context).size.width * 0.38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0x10000000), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF4C5F7D),
            ),
          ),
          Text(
            "$_currencySymbol$amountText",
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF4C5F7D),
            ),
          ),
        ],
      ),
    );
  }

  // ➕ NEW — styled the same as Paymentsucess._buildChangeRow, but tinted
  // orange/red since this is money still owed, not change to give back.
  Widget _buildPartialBalanceRow(BuildContext context, String balanceText) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.07,
      width: MediaQuery.of(context).size.width * 0.38,
      decoration: BoxDecoration(
        color: const Color(0x10E53935),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0x10E53935), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10E53935),
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Balance Due:",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: Color(0xFFE53935),
            ),
          ),
          Text(
            "$_currencySymbol$balanceText",
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  // ➕ NEW — same 180x50 pill button style as Paymentsucess._buildActionButton.
  Widget _buildPartialActionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
                  duration: const Duration(seconds: 1),
                ),
              );
              return;
            }
            if (state is PaymentSummaryLoaded) {
              if (state.summary.orderId != widget.orderId) {
                return; // ignore stale summary
              }
              debugPrint(
                "BlocListener -> merchant=${state.merchantDiscount}, isNc=${state.isNoCharge}",
              );
              _paymentSummary = state.summary;
              _syncFromState(state);
            }
          },
        ),

        BlocListener<DiscountBloc, DiscountState>(
          listener: (context, state) {
            if (state is DiscountSuccess) {
              final double applied = state.response.discountAmt;
              setState(() {
                _isDiscountApplied = true;
                discountController.text = applied.toStringAsFixed(2);
              });
              context.read<PaymentBloc>().add(
                UpdateMerchantDiscount(
                  value: applied,
                  isNoCharge: state.isNcApplied,
                ),
              );
              // Trigger reload in parent screen so all totals are updated
              widget.onCouponAmountChanged?.call(_couponAmount);
              _reloadSummary();
            }
          },
        ),

        // In the BlocListener for CreatePaymentBloc, update the success handler:

        // In the BlocListener for CreatePaymentBloc, update the success handler:
        BlocListener<CreatePaymentBloc, CreatePaymentState>(
          listener: (context, state) async {
            if (state is CreatePaymentSuccess) {
              final paymentBlocState = context.read<PaymentBloc>().state;
              if (paymentBlocState is! PaymentSummaryLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Payment summary not available"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // ➕ NEW — figure out whether this payment fully settles the
              // order or is a partial ("split") payment. This block is
              // purely additive: when the tendered amount covers the whole
              // remaining net payable (the normal, existing case — including
              // the fully-discounted ₹0 order case), remainingAfter comes out
              // <= 0.01 and everything below falls straight through to the
              // ORIGINAL, unchanged receipt flow exactly as before.
              final double paidThisTxn = _asDouble(state.response.paidAmount);
              final double fullNet = getGrandTotal(paymentBlocState);
              final double newTotalPaid = _totalPaidAmount + paidThisTxn;
              final double remainingAfter = fullNet - newTotalPaid;

              if (remainingAfter > 0.01) {
                // ── Partial payment: show Void / Next Payment popup
                // instead of the normal receipt dialog.
                final String? partialAction = await _showPartialPaymentDialog(
                  paidAmount: paidThisTxn,
                  remainingAmount: remainingAfter,
                );

                if (!mounted) return;

                if (partialAction == "void") {
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
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  setState(() {
                    amount = '';
                    tenderAmountError = null;
                    _balanceRevealed = false;
                    _confirmedTenderForBalance = 0.0;
                    // ── FIX: only THIS transaction is being voided — it
                    // was never added to _totalPaidAmount (that only
                    // happens in the "Next Payment" branch below), so
                    // _totalPaidAmount must be left exactly as it was.
                  });
                } else {
                  // "Next Payment" — accept the partial amount, and update
                  // every place on screen (Net Payable card, Balance
                  // Amount card, numpad enable state, preset buttons) so it
                  // now reflects the reduced remaining balance.
                  setState(() {
                    _totalPaidAmount = newTotalPaid;
                    amount = '';
                    tenderAmountError = null;
                    _balanceRevealed = false;
                    _confirmedTenderForBalance = 0.0;
                  });
                  widget.onPartialPaymentChanged?.call(true);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Partial payment of $_currencySymbol${paidThisTxn.toStringAsFixed(2)} recorded. Balance $_currencySymbol${remainingAfter.toStringAsFixed(2)} remaining.",
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                return; // don't fall through to the full receipt flow below
              }

              final rawSummary = paymentBlocState.summary;
              final summary = rawSummary.copyWith(
                discount: merchantDiscount.abs(),
                coupons: _couponAmount > 0 ? _couponAmount : rawSummary.coupons,
                netTotal: getGrandTotal(paymentBlocState),
                tipAmount: _tipAmount > 0 ? _tipAmount : rawSummary.tipAmount,
              );

              // Show payment success dialog with receipt
              final action = await showDialog<String>(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.black.withOpacity(0.4),
                builder:
                    (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.zero,
                      child: Center(
                        child: Paymentsucess(
                          amount: state.response.paidAmount.toString(),
                          paymentMode: selectedPaymentMode,
                          changeAmount: state.response.change.toStringAsFixed(
                            2,
                          ),
                          paymentId: state.response.paymentId,
                          orderId: state.response.orderId,
                          loadedTables: widget.loadedTables,
                          pin: widget.pin,
                          token: widget.token,
                          restaurantId: widget.restaurantId,
                          zoneId: widget.zoneId,
                          restaurantName: widget.restaurantName,
                          paymentSummary: summary,
                          cashierName: _cashierName,
                          isTakeAway: widget.isTakeAway,
                        ),
                      ),
                    ),
              );

              if (!mounted) return;

              // Handle void action only - navigation is handled inside Paymentsucess/PrintRecipt
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
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    amount = '';
                    tenderAmountError = null;
                    _balanceRevealed = false;
                    _confirmedTenderForBalance = 0.0;
                    // ── FIX: this only reverses THIS transaction — it does
                    // not touch any earlier partial payments the cashier
                    // already accepted via "Next Payment", so
                    // _totalPaidAmount is intentionally left untouched here.
                  });
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                // ✅ IMPORTANT: Just clean up local state, don't navigate here
                // Navigation is handled inside Paymentsucess -> PrintRecipt
                // setState(() {
                //   _balanceRevealed = false;
                //   _confirmedTenderForBalance = 0.0;
                // });

                // ➕ NEW — the order is now fully paid off (this branch only
                // runs when remainingAfter <= 0.01 above). Marking
                // _totalPaidAmount as the full order total here makes sure
                // Net Payable / Balance Amount correctly show "fully paid"
                // (Balance Amount stays at 0) if this screen is still
                // visible for a moment before navigation happens.
                final double fullNetAtCompletion = getGrandTotal(
                  paymentBlocState,
                );
                setState(() {
                  _totalPaidAmount = fullNetAtCompletion;
                });
                widget.onPartialPaymentChanged?.call(false);

                // DO NOT navigate here - let Paymentsucess handle it
                // The navigation will happen inside PrintRecipt's _onDonePressed
              }
            }

            if (state is CreatePaymentFailure) {
              setState(() {
                _balanceRevealed = false;
                _confirmedTenderForBalance = 0.0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.red,
                ),
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
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {
                _isDiscountApplied = false;
                _isNcDiscount = false;
                _discountAmount = 0;
                merchantDiscount = 0.0;
                discountController.clear();
                _lastAppliedDiscountStr = null;
                _lastAppliedDiscountReason = null;
              });
              // context.read<PaymentBloc>().add(
              //   UpdateMerchantDiscount(
              //     value: applied,
              //     isNoCharge: isNc,
              //   ),
              // );
              widget.onMerchantDiscountChanged(0.0);
              _updateAmountField();
            }
            if (state is RemoveDiscountFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],

      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F6),
        // UI is always visible - no loading state
        body: BlocBuilder<PaymentBloc, PaymentState>(
          buildWhen: (prev, curr) {
            if (curr is! PaymentSummaryLoaded) return false;

            if (prev is PaymentSummaryLoaded) {
              return curr.summary.netTotal != prev.summary.netTotal ||
                  curr.summary.serviceChargeValue !=
                      prev.summary.serviceChargeValue ||
                  curr.merchantDiscount != prev.merchantDiscount ||
                  curr.isNoCharge != prev.isNoCharge;
            }

            return true;
          },
          builder: (context, payState) {
            // ➕ CHANGED (additive): fullNetPayableVal is the full order
            // total exactly as before; netPayableVal now represents the
            // *remaining* balance still owed (full total minus whatever
            // has already been collected through partial payments). Every
            // downstream usage below (payDisabled, presets, numpad,
            // Net Payable card, Balance Amount card) is unchanged code —
            // it just now automatically reflects partial payments because
            // this single value does. When no partial payment has ever
            // been made, _totalPaidAmount is 0 and netPayableVal is
            // identical to the old value, so nothing else changes.
            final double netPayableVal = getGrandTotal(
              payState,
            ); // Always fixed

            final double remainingBalance =
                (netPayableVal - _totalPaidAmount) < 0
                    ? 0.0
                    : (netPayableVal - _totalPaidAmount);

            final bool isSummaryReady =
                payState is PaymentSummaryLoaded || _paymentSummary != null;
            final bool isNoCharge =
                payState is PaymentSummaryLoaded && payState.isNoCharge;

            final bool payDisabled =
                isSummaryReady && netPayableVal <= 0 && !isNoCharge;
            // ── CHANGED: Balance Amount stays at 0 until a payment mode is
            // tapped and confirmed (see _onPaymentModeTap) — it no longer
            // reacts to every keystroke on the tender amount.
            final double tenderAmt =
                _balanceRevealed ? _confirmedTenderForBalance : 0.0;

            final double balAmt =
                tenderAmt < remainingBalance
                    ? (remainingBalance - tenderAmt)
                    : 0.0;

            final List<double> presets = buildPresetAmounts(remainingBalance);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT — Numpad
                Expanded(
                  child: _buildNumpadColumn(
                    context,
                    netPayableVal: remainingBalance,
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
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0xFFD9E6FF),
            offset: Offset(4, 4),
            blurRadius: 8,
          ),
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
                              color:
                                  tenderAmountError != null
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFFB3C7FF),
                              width: tenderAmountError != null ? 1.4 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color:
                                tenderAmountError != null
                                    ? const Color(0xFFFFF3F3)
                                    : Colors.white,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              payDisabled
                                  ? "$_currencySymbol 0.00"
                                  : "$_currencySymbol${(double.tryParse(amount) ?? 0.0).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color:
                                    payDisabled
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
                        for (int i = 0; i < 3; i++)
                          _presetBtn(
                            i < presets.length ? presets[i] : 0.0,
                            payDisabled,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: GestureDetector(
                            onTap:
                            payDisabled ? null : () => handleKeyPress("C"),
                            child: Opacity(
                              opacity: payDisabled ? 0.5 : 1.0,
                              child: Container(
                                height: 110,
                                decoration: ShapeDecoration(
                                  color: payDisabled
                                      ? Colors.grey.shade200
                                      : const Color(0xFFFFDADA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  shadows: payDisabled
                                      ? []
                                      : const [
                                    // Top-left highlight
                                    BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(-4, -4),
                                      blurRadius: 4,
                                    ),

                                    // Bottom-right shadow
                                    BoxShadow(
                                      color: Color(0xFFFFCCCC),
                                      offset: Offset(4, 4),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "C",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                    payDisabled
                                        ? Colors.grey
                                        : const Color(0xFFFF4D20),
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
                    "assets/Cash Icon.png",
                  ),
                  const SizedBox(width: 10),
                  _payModeBtn(
                    "Card",
                    const Color.fromRGBO(164, 132, 200, 1),
                    "assets/Card icon.png",
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
        children:
        keys.map((k) {
          final bool isBackspace = k == "⌫";
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: GestureDetector(
                onTap: disabled ? null : () => handleKeyPress(k),
                child: Container(
                  decoration: ShapeDecoration(
                    color: disabled
                        ? Colors.grey.shade100
                        : const Color(0xFFEDF1F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadows: disabled
                        ? []
                        : const [
                      // Top-left highlight
                      BoxShadow(
                        color: Colors.white,
                        offset: Offset(-4, -4),
                        blurRadius: 6,
                      ),

                      // Bottom-right shadow
                      BoxShadow(
                        color: Color(0xFFD9E6FF),
                        offset: Offset(4, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child:
                  isBackspace
                      ? Icon(
                    Icons.backspace_outlined,
                    color: disabled
                        ? Colors.grey
                        : const Color(0xFF0C3952),
                    size: 22,
                  )
                      : Text(
                    k,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                      disabled
                          ? Colors.grey
                          : const Color(0xFF4C5F7D),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _presetBtn(double value, bool disabled) {
    // if (value <= 0) return const SizedBox.shrink();

    final bool isSelected = amount == value.toStringAsFixed(2);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: GestureDetector(
          onTap:
              disabled
                  ? null
                  : () => _onPresetAmountTap(value.toStringAsFixed(2)),
          child: Container(
            decoration: ShapeDecoration(
              color: disabled
                  ? Colors.grey.shade200
                  : const Color(0xFFE5FFDD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              shadows: disabled
                  ? []
                  : const [
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 6,
                ),
                BoxShadow(
                  color: Color(0xFFCBE8C4),
                  offset: Offset(4, 4),
                  blurRadius: 6,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              "$_currencySymbol${value.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: disabled ? Colors.grey : const Color(0xFF318616),
              ),
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
        onTap: _isPaymentLoading ? null : () => _onPaymentModeTap(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: ShapeDecoration(
            color: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Colors.white
                    : Colors.transparent,
                width: 2,
              ),
            ),
            shadows: [
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                offset: const Offset(-4, -4),
                blurRadius: 6,
              ),
              BoxShadow(
                color: color.withOpacity(0.45),
                offset: const Offset(4, 4),
                blurRadius: 6,
              ),
            ],
          ),
          child:
              _isPaymentLoading && _loadingPaymentMode == mode
                  ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mode,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
                            color: color,
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

    return Container(
      width: screenW * 0.19,
      margin: const EdgeInsets.only(
        bottom: 12, // Adjust as needed
      ),
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
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-4, -4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Color(0xFFD9E6FF),
                    offset: Offset(4, 4),
                    blurRadius: 8,
                  ),
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
                  const SizedBox(height: 15),
                  _balanceAmountCard(balAmt),

                  const SizedBox(height: 20),

                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.white,
                            offset: Offset(-4, -4),
                            blurRadius: 8,
                          ),
                          BoxShadow(
                            color: Color(0xFFD9E6FF),
                            offset: Offset(4, 4),
                            blurRadius: 8,
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
        ],
      ),
    );
  }

  Widget _netAmountCard(double value) {
    final bool isReady = _paymentSummary != null && _paymentSummary!.orderId == widget.orderId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0xFFD9E6FF),
            offset: Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Net Payable",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7628),
              letterSpacing: 0.2,
            ),
          ),
          if (_totalPaidAmount > 0)
            const SizedBox(height: 7),
          if (!isReady)
            Container(
              width: double.infinity,
              height: 74,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5D6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7628)),
                ),
              ),
            )
          else
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF5D6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$_currencySymbol${value.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF262525),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      // Custom Image for Net Amount
                      SizedBox(
                        width: 54,
                        height: 50,
                        child: Image.asset(
                          "assets/net_amount.png", // ← Your custom icon
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
    final bool isReady = _paymentSummary != null && _paymentSummary!.orderId == widget.orderId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0xFFD9E6FF),
            offset: Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Balance Amount",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF913177),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 7),
          if (!isReady)
            Container(
              width: double.infinity,
              height: 74,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF7EAF7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF913177)),
                ),
              ),
            )
          else
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EAF7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$_currencySymbol${value.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF262525),
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
  }

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
              if (icon != null) Positioned(right: -2, bottom: -4, child: icon),
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
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "₹",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 8,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
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
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "₹",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.auto_awesome, size: 18, color: Color(0xFF9B59B6)),
          ),
          const Positioned(
            top: 16,
            right: 8,
            child: Icon(Icons.lens, size: 5, color: Color(0xFFBB80C8)),
          ),
          const Positioned(
            top: 8,
            left: 20,
            child: Icon(Icons.lens, size: 4, color: Color(0xFFBB80C8)),
          ),
        ],
      ),
    );
  }

  // Action buttons section
  Widget _buildActionButtons(BuildContext context, double netPayable) {
    debugPrint("_buildActionButtons -> _isNcDiscount = $_isNcDiscount");
    return Column(
      children: [
        // Discounts
        _actionTile(
          label: "Discounts",
          borderColor: const Color(0xFF6BACC3),
          iconBg: const Color(0xFF6BACC3),
          // icon: Icons.discount_rounded,
          iconWidget: Image.asset(
            // ← Now correctly passed
            "assets/Discount Icon.png",
            width: 34,
            height: 32,
            color: Colors.white,
          ),
          isApplied: _isDiscountApplied,
          appliedText:
              discountController.text.isNotEmpty
                  ? "$_currencySymbol${discountController.text}"
                  : null,
          onTap:
              _isDiscountApplied
                  ? null
                  : () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider(
                                create:
                                    (_) => DiscountReasonBloc(
                                      DiscountReasonRepository(),
                                    ),
                              ),
                              BlocProvider.value(
                                value: context.read<DiscountBloc>(),
                              ),
                            ],
                            child: DiscountPopup(
                              netPayable: netPayable + merchantDiscount.abs(),
                              netTotal: getNetTotal(),
                              orderId: widget.orderId,
                              initialDiscount: merchantDiscount.abs(),
                              isPercent: _lastAppliedDiscountStr != null && _lastAppliedDiscountStr!.contains('%'),
                            ),
                          ),
                    );
                    if (result != null) {
                      debugPrint("Discount Result: $result");

                      final double applied = (result["amount"] as double).abs();
                      final bool isNc = result["isNc"] == true;

                      debugPrint("isNc = $isNc");

                      setState(() {
                        _isDiscountApplied = true;
                        _isNcDiscount = isNc;
                        discountController.text = applied.toStringAsFixed(2);
                        _lastAppliedDiscountStr = result["discountStr"];
                        _lastAppliedDiscountReason = result["reason"];
                      });

                      // ✅ Update PaymentBloc with both discount and NC flag
                      context.read<PaymentBloc>().add(
                        UpdateMerchantDiscount(
                          value: applied,
                          isNoCharge: isNc,
                        ),
                      );

                      debugPrint("_isNcDiscount = $_isNcDiscount");
                    }
                  },
          onDelete:
              _isDiscountApplied
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
        IgnorePointer(
          ignoring: _isNcDiscount,
          child: Opacity(
            opacity: _isNcDiscount ? 0.4 : 1.0,
            child: _actionTile(
              label: "Coupons",
              borderColor: const Color(0xFFF7B05F),
              iconBg: const Color(0xFFF7B05F),
              iconWidget: Image.asset(
                "assets/Coupon Icon.png",
                width: 32,
                height: 32,
                color: Colors.white,
              ),
              isApplied: _isCouponApplied,
              appliedText: _appliedCoupon.isNotEmpty ? _appliedCoupon : null,
              onTap:
                  _isCouponApplied
                      ? null
                      : () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (_) => Couponscreen(
                                orderId: widget.orderId,
                                token: widget.token,
                                onCouponApplied: (coupon, amt) async {
                                  setState(() {
                                    _isCouponApplied = true;
                                    _appliedCoupon = coupon;
                                    _couponAmount = amt;
                                    couponController.text = coupon;
                                  });

                                  widget.onCouponAmountChanged?.call(amt);

                                  await Future.delayed(const Duration(milliseconds: 500));

                                  if (_lastAppliedDiscountStr != null && _lastAppliedDiscountStr!.contains('%')) {
                                    final percentVal = double.tryParse(_lastAppliedDiscountStr!.replaceAll('%', '').trim()) ?? 0.0;
                                    final state = context.read<PaymentBloc>().state;
                                    final bool isStateValid = state is PaymentSummaryLoaded && state.summary.orderId == widget.orderId;
                                    final bool isSummaryValid = _paymentSummary != null && _paymentSummary!.orderId == widget.orderId;
                                    final PaymentSummary? summary =
                                        isStateValid ? state.summary : (isSummaryValid ? _paymentSummary : null);
                                    if (summary != null) {
                                      final netTotalBeforeDiscountAndCoupon = summary.netTotal - summary.serviceChargeValue - summary.tipAmount + summary.discount.abs() + summary.coupons.abs();
                                      final newNetTotal = netTotalBeforeDiscountAndCoupon - amt;
                                      final calculatedDiscount = (newNetTotal * percentVal) / 100;
                                      context.read<DiscountBloc>().add(
                                        ApplyDiscountEvent(
                                          request: AddDiscountRequest(
                                            orderId: widget.orderId,
                                            amount: calculatedDiscount.toStringAsFixed(2),
                                            isNc: _isNcDiscount ? "yes" : "no",
                                            reason: _lastAppliedDiscountReason ?? "",
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    _reloadSummary();
                                  }

                                  // Success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Coupon added successfully",
                                      ),
                                      duration: Duration(seconds: 1),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                        );
                      },
              onDelete:
                  _isCouponApplied
                      ? () async {
                          if (_isDiscountApplied) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please delete the merchant discount first"),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          final success = await _couponRepository.removeCoupon(
                          token: widget.token,
                          orderId: widget.orderId,
                          couponCode: _appliedCoupon,
                        );

                        if (success) {
                          setState(() {
                            _isCouponApplied = false;
                            _appliedCoupon = '';
                            _couponAmount = 0.0;
                            couponController.clear();
                          });

                          widget.onCouponAmountChanged?.call(0.0);

                          await Future.delayed(const Duration(milliseconds: 500));

                          if (_lastAppliedDiscountStr != null && _lastAppliedDiscountStr!.contains('%')) {
                            final percentVal = double.tryParse(_lastAppliedDiscountStr!.replaceAll('%', '').trim()) ?? 0.0;
                            final state = context.read<PaymentBloc>().state;
                            final bool isStateValid = state is PaymentSummaryLoaded && state.summary.orderId == widget.orderId;
                            final bool isSummaryValid = _paymentSummary != null && _paymentSummary!.orderId == widget.orderId;
                            final PaymentSummary? summary =
                                isStateValid ? state.summary : (isSummaryValid ? _paymentSummary : null);
                            if (summary != null) {
                              final netTotalBeforeDiscountAndCoupon = summary.netTotal - summary.serviceChargeValue - summary.tipAmount + summary.discount.abs() + summary.coupons.abs();
                              final newNetTotal = netTotalBeforeDiscountAndCoupon;
                              final calculatedDiscount = (newNetTotal * percentVal) / 100;
                              context.read<DiscountBloc>().add(
                                ApplyDiscountEvent(
                                  request: AddDiscountRequest(
                                    orderId: widget.orderId,
                                    amount: calculatedDiscount.toStringAsFixed(2),
                                    isNc: _isNcDiscount ? "yes" : "no",
                                    reason: _lastAppliedDiscountReason ?? "",
                                  ),
                                ),
                              );
                            }
                          } else {
                            _reloadSummary();
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Coupon removed successfully"),
                              duration: Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Tips
        _actionTile(
          label: "Tips",
          borderColor: const Color(0xFF50AC9A),
          iconBg: const Color(0xFF50AC9A),
          // icon: Icons.volunteer_activism_rounded,
          iconWidget: Image.asset(
            // ← Now correctly passed
            "assets/Tips Icon.png",
            width: 32,
            height: 32,
            color: Colors.white,
          ),
          isApplied: _isTipApplied,
          appliedText:
              _isTipApplied
                  ? "$_currencySymbol${_tipAmount.toStringAsFixed(2)}"
                  : null,
          onTap:
              _isTipApplied
                  ? null
                  : () async {
                    final double? result = await showDialog<double>(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (_) => TipPopup(
                            orderId: widget.orderId,
                            token: widget.token,
                            onTipApplied: (amt) {
                              setState(() {
                                _isTipApplied = true;
                                _tipAmount = amt;
                                tipController.text = amt.toStringAsFixed(2);
                              });
                              widget.onTipChanged(amt);

                              context.read<PaymentBloc>().add(UpdateTip(amt));
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
                      context.read<PaymentBloc>().add(UpdateTip(result));
                    }
                  },
          onDelete:
              _isTipApplied
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

                      context.read<PaymentBloc>().add(UpdateTip(0));
                      _updateAmountField();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tip removed successfully'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to remove tip'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Colors.red,
                        ),
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
    bool enabled = true,
  }) {
    // ── Only change: gradient per tile color ──
    LinearGradient _tileGradient(Color base) {
      if (base == const Color(0xFF1E88E5)) {
        return const LinearGradient(
          colors: [Color(0xFF5B9EF0), Color(0xFF3A7BDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (base == const Color(0xFFE65100)) {
        return const LinearGradient(
          colors: [Color(0xFF5CC96A), Color(0xFF2EA83C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (base == const Color(0xFF2E7D32)) {
        return const LinearGradient(
          colors: [Color(0xFFFFCC55), Color(0xFFF5950A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      return LinearGradient(colors: [base, base]);
    }

    final Color labelColor = isApplied ? Colors.white : borderColor;
    final Color subColor =
        isApplied
            ? Colors.white.withOpacity(0.9)
            : borderColor.withOpacity(0.8);
    final Color activeBorder =
        isApplied ? iconBg : borderColor.withOpacity(0.4);

    return GestureDetector(
      onTap: (!enabled || isApplied) ? null : onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            // ── Only change: gradient when applied, white when not ──
            gradient: isApplied ? _tileGradient(iconBg) : null,
            color: isApplied ? null : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: activeBorder, width: isApplied ? 0 : 1.2),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    // ── Only change: trash icon instead of close ──
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 25,
                      color: Colors.red,
                    ),
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
                    child:
                        iconWidget ??
                        (icon != null
                            ? Icon(icon, color: Colors.white, size: 18)
                            : const Icon(
                              Icons.help_outline,
                              color: Colors.white,
                              size: 18,
                            )),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _svcChargeTile(BuildContext context) {
    final bool applied =
        isServiceChargeApplied && selectedServiceCharge != null;
    final Color base = const Color(0xFFE57F69);
    final Color labelColor = applied ? Colors.white : const Color(0xFFC62828);
    final Color subColor = Colors.white.withOpacity(0.9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // ── Only change: red gradient when applied ──
        gradient:
            applied
                ? const LinearGradient(
                  colors: [Color(0xFFF8AD9D), Color(0xFFE57F69)],
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
                Text(
                  "Svc Charges",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
                if (applied) ...[
                  const SizedBox(height: 2),
                  Text(
                    "${selectedServiceCharge}%",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                    ),
                  ),
                ],
                if (!applied)
                  SizedBox(
                    height: 26,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedServiceCharge,
                        isDense: true,
                        hint: const Text(
                          "Select %",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF777777),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF212121),
                        ),
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
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                // ── Only change: trash icon ──
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 25,
                  color: Colors.red,
                ),
              ),
            )
          else
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFC62828),
                shape: BoxShape.circle,
              ),
              // ── Only change: icon wrapped in CircleAvatar ──
              child: const CircleAvatar(
                radius: 17,
                backgroundColor: Colors.transparent,
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 18,
                ),
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 13 : 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: labelColor ?? const Color(0xFF444444),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? const Color(0xFF212121),
            ),
          ),
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
                        color:
                            selectedPaymentMode.isNotEmpty
                                ? const Color(0xFFFE6464)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "PAY",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              selectedPaymentMode.isNotEmpty
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
      child: Row(children: labels.map((label) => _buildButton(label)).toList()),
    );
  }

  Widget _buildButton(
    String label, {
    int flex = 1,
    Color? backgroundColor,
    Color? textColor,
    BoxBorder? border,
    bool isPayButton = false,
  }) {
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
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isNumber ? 24 : 18,
                fontWeight: FontWeight.bold,
                color: textColor ?? const Color(0xFF4C5F7D),
              ),
            ),
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
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4C5F7D),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
    ),
    child: TextFormField(
      controller: controller,
      readOnly: true,
      keyboardType: keyboardType,
      decoration: InputDecoration(hintText: hint, border: InputBorder.none),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.delete, size: 18, color: Colors.red),
    ),
  );
}
