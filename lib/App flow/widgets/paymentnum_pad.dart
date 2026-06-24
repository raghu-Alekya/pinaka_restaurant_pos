import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/paymentsucess.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/splitpaymentpopup.dart';
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
import '../../repositories/TIP_repository.dart';
import '../../repositories/coupon_repository.dart';
import '../../repositories/create_payment_repository.dart';
import '../../repositories/discount_repository.dart';
import '../../repositories/service_charge_repository.dart';
import '../../services/app_database.dart';
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
  }) : super(key: key);


  @override
  State<paymentsummary> createState() => _paymentsummaryState();
}

class _paymentsummaryState extends State<paymentsummary> {
  String selectedOption = '';
  String amount = '';

  // double balanceAmount = AppDatabase.instance.totalamount ?? 0.0;
  double? calculatedChange;
  String selectedPaymentMode = "Cash";
  bool isCashSelected = true;

  // ✅ Declare this variable
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
  bool _isPaying = false;
  double serviceChargeAmount = 0.0;
  int? selectedServiceCharge;
  final serviceChargeRepository = ServiceChargeRepository();
  bool isServiceChargeApplied = false;
  final TipRepository _tipRepository = TipRepository();
  final CreatePaymentRepository _paymentRepository = CreatePaymentRepository();
  final CouponRepository _couponRepository = CouponRepository();


  final TextEditingController discountController =
  TextEditingController();
  final TextEditingController couponController =
  TextEditingController();

  final TextEditingController tipController =
  TextEditingController();

  final TextEditingController splitPayController =
  TextEditingController();


// ✅ FIXED


  // / Delete button enabled if any of the above are applied
  bool get isDeleteEnabled =>
      _isTipApplied || _isDiscountApplied || _isCouponApplied;


  @override
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final state = context.read<PaymentBloc>().state;

      if (state is PaymentSummaryLoaded) {
        final summary = state.summary;

        /// DISCOUNT
        final discount = state.merchantDiscount;

        discountController.text =
        discount != 0 ? discount.abs().toStringAsFixed(2) : "";


        /// COUPON
        if (summary.couponDetails.isNotEmpty) {
          _appliedCoupon = summary.couponDetails.first.code;
          _couponAmount = summary.couponDetails.first.value;

          couponController.text = _appliedCoupon;
          _isCouponApplied = true;
        }

        /// TIP
        if (summary.tipAmount > 0) {
          _tipAmount = summary.tipAmount;

          tipController.text =
              summary.tipAmount.toStringAsFixed(2);

          _isTipApplied = true;
        }

        setState(() {
          _isDiscountApplied = discount != 0;
          merchantDiscount = discount;

          final serviceCharge =
              state.summary.serviceChargePercentage ?? 0;

          if (serviceCharge > 0) {
            selectedServiceCharge = serviceCharge.toInt();
            isServiceChargeApplied = true;
          } else {
            selectedServiceCharge = null;
            isServiceChargeApplied = false;
          }
        });        _updateAmountField();

        _updateAmountField();

        debugPrint("Coupon = ${couponController.text}");
        debugPrint("Tip = ${tipController.text}");
        debugPrint("Discount = ${discountController.text}");
      }
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
    final state = context.read<PaymentBloc>().state;

    if (state is! PaymentSummaryLoaded) return;

    double payable = state.summary.netTotal;

    // Coupon reduces amount
    payable -= _couponAmount;

    // Merchant discount reduces amount
    payable -= merchantDiscount.abs();

    // Tip increases amount
    payable += _tipAmount;

    if (payable < 0) payable = 0;

    setState(() {
      amount = payable.toStringAsFixed(2);
    });

    debugPrint("💰 Updated Payable = $payable");
  }
  double _calculateNetPayable(PaymentSummaryLoaded state) {
    double payable = state.summary.netTotal;

    payable -= merchantDiscount.abs();
    payable += _tipAmount;

    if (payable < 0) payable = 0;

    return payable;
  }
  Future<void> applyServiceCharge(int percentage) async {
    final response =
    await serviceChargeRepository.applyServiceCharge(
      token: widget.token,
      orderId: widget.orderId,
      percentage: percentage,
    );

    if (response != null && response.success) {
      setState(() {
        selectedServiceCharge = response.serviceChargePercentage;
        isServiceChargeApplied = true;
      });

      context.read<PaymentBloc>().add(
        LoadPaymentSummary(
          token: widget.token,
          orderId: widget.orderId,
          restaurantId: widget.restaurantId,
          orderType: "Dine In",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Service charge applied successfully"),
        ),
      );
    }
  }
  Future<void> deleteServiceCharge() async {
    final response =
    await serviceChargeRepository.deleteServiceCharge(
      token: widget.token,
      orderId: widget.orderId,
    );

    if (response != null && response.success) {
      setState(() {
        selectedServiceCharge = null;
        isServiceChargeApplied = false;
      });

      context.read<PaymentBloc>().add(
        LoadPaymentSummary(
          token: widget.token,
          orderId: widget.orderId,
          restaurantId: widget.restaurantId,
          orderType: "Dine In",
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Service charge removed successfully"),
        ),
      );
    }
  }



  Future<void> _submitPayment() async {
    debugPrint("🟡 SUBMIT PAYMENT CALLED");
    // debugPrint("🟡 SUBMIT PAYMENT CALLED");

    // // ✅ BLOCK PAYMENT WHEN NET PAYABLE IS ZERO
    // final paymentState = context.read<PaymentBloc>().state;
    // if (paymentState is PaymentSummaryLoaded &&
    //     paymentState.summary.netTotal <= 0) {
    //   debugPrint("⛔ Net payable is zero — payment not required");
    //
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("No payment required for this order")),
    //   );
    //   return;
    // }


    final orderBloc = context.read<OrderBloc>();

    // ---- DEBUG ALL REQUIRED VALUES ----
    debugPrint("📦 OrderBloc State: ${orderBloc.state}");

    final orderId = orderBloc.state.orderId;
    final int? userId = await SessionManager.getUserId();
    final int? shiftId = await SessionManager.getShiftId();

    debugPrint("➡️ orderId: $orderId");
    debugPrint("➡️ userId: $userId");
    debugPrint("➡️ shiftId: $shiftId");
    debugPrint("➡️ amount: $amount");
    debugPrint("➡️ paymentMode: $selectedPaymentMode");

    // ---------- VALIDATION ----------
    if (orderId == null) {
      debugPrint("❌ ERROR: orderId is NULL");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Order not created")));
      return;
    }

    if (userId == null) {
      debugPrint("❌ ERROR: userId is NULL");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    if (shiftId == null) {
      debugPrint("❌ ERROR: shiftId is NULL");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Shift not started")));
      return;
    }

    if (amount.isEmpty) {
      debugPrint("❌ ERROR: amount is empty");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter payment amount")));
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
          notes: {
            "source": "POS",
            "device": "ANDROID",
          },
        ),
      ),
    );
  }


  Future<void> handleKeyPress(String key) async {
    final netPayable =
    (context.read<PaymentBloc>().state is PaymentSummaryLoaded)
        ? (context.read<PaymentBloc>().state as PaymentSummaryLoaded)
        .summary
        .netTotal
        : 0.0;

    if (netPayable <= 0 && key != "Pay") {
      return; // ⛔ block digits, allow Pay
    }

    // ✅ PAY BUTTON
    // ✅ PAY BUTTON
    if (key == "Pay") {
      if (_isPaying) return; // ⛔ prevent double tap

      if (amount.isEmpty && netPayable > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter amount")),
        );
        return;
      }

      setState(() {
        _isPaying = true; // 🔄 start loading
      });

      await _submitPayment();
      return;
    }


    // ✅ CLEAR
    if (key == "C") {
      setState(() => amount = '');
      return;
    }

    // ✅ BACKSPACE
    if (key == "⌫") {
      if (amount.isNotEmpty) {
        setState(() {
          amount = amount.substring(0, amount.length - 1);
        });
      }
      return;
    }

    // ❌ BLOCK NON-NUMERIC INPUT
    if (!RegExp(r'^[0-9.]+$').hasMatch(key)) {
      return;
    }


    // ✅ PREVENT MULTIPLE DOTS
    if (key == "." && amount.contains(".")) {
      return;
    }

    // ✅ ADD NUMBER
    setState(() {
      amount += key;
    });
  }

  void _onPresetAmountTap(String value) {
    setState(() {
      amount = value;
    });
  }


  List<double> buildPresetAmounts(double total) {
    if (total <= 0) return [];

    final List<double> result = [];
    final Set<double> seen = {};

    void add(double value) {
      if (seen.add(value)) {
        result.add(value);
      }
    }

    // 1) exact total
    add(total);

    // 2) keep adding next rounded multiples until we have 4 values
    int step = 50;
    double current = total;

    while (result.length < 3) {
      final next = (current / step).ceil() * step;
      if (next > total) {
        add(next.toDouble());
      }
      current = next + 1; // move forward to avoid same rounding again

      // after some iterations increase step to get bigger jumps
      if (result.length == 2) step = 100;
      if (result.length == 3) step = 200;
    }

    result.sort();
    return result;
  }


  @override
  Widget build(BuildContext context) {
    debugPrint("🔥 paymentsummary build called");
    final double totalAmount =
    context.select(
          (PaymentBloc bloc) =>
      bloc.state is PaymentSummaryLoaded
          ? (bloc.state as PaymentSummaryLoaded).summary.grossTotal
          : 0.0,
    );
    debugPrint("💰 grossTotal = ${context
        .read<OrderBloc>()
        .state
        .grossTotal}");

    final paymentState = context.watch<PaymentBloc>().state;

    double netPayable = 0.0;

    if (paymentState is PaymentSummaryLoaded) {
      netPayable =
          paymentState.summary.netTotal -
              _couponAmount +
              _tipAmount;
    }
    final bool isPaymentDisabled = netPayable <= 0;




    // ✅ DEFINE HERE
    final List<double> presetAmounts =
    buildPresetAmounts(netPayable);

    return MultiBlocListener(
      listeners: [
        // ✅ ADD THIS LISTENER HERE (PaymentBloc)
        BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentSummaryLoaded) {
              final discount = state.merchantDiscount;

              setState(() {
                /// ===== DISCOUNT =====
                _isDiscountApplied = discount != 0;
                merchantDiscount = _isDiscountApplied ? discount : 0.0;

                discountController.text = _isDiscountApplied
                    ? discount.abs().toStringAsFixed(2)
                    : "";

                _isNcDiscount = state.isNoCharge;
                /// ===== COUPON =====
                if (state.summary.couponDetails.isNotEmpty) {
                  final coupon = state.summary.couponDetails.first;

                  _isCouponApplied = true;
                  _appliedCoupon = coupon.code;
                  _couponAmount = coupon.value;

                  couponController.text = coupon.code;
                }

                /// ===== TIP =====
                if (state.summary.tipAmount > 0) {
                  _isTipApplied = true;
                  _tipAmount = state.summary.tipAmount;

                  tipController.text =
                      state.summary.tipAmount.toStringAsFixed(2);
                }
              });

              final grossTotal = state.summary.grossTotal;

              final couponAmount = state.summary.coupons > 0
                  ? state.summary.coupons
                  : _couponAmount;

              double finalPayable =
                  grossTotal -
                      couponAmount -
                      merchantDiscount.abs() +
                      _tipAmount;

              if (finalPayable < 0) {
                finalPayable = 0;
              }

              setState(() {
                amount = finalPayable.toStringAsFixed(2);
              });
              debugPrint("TextField Amount  : $amount");

              debugPrint("===== REBUILD =====");
              debugPrint("_appliedCoupon = $_appliedCoupon");
              debugPrint("_couponAmount = $_couponAmount");
              debugPrint("_tipAmount = $_tipAmount");
              debugPrint("couponController = ${couponController.text}");
              debugPrint("tipController = ${tipController.text}");
            }
          },
        ),


        /// ✅ PAYMENT LISTENER
        BlocListener<CreatePaymentBloc, CreatePaymentState>(
          listener: (context, state) async {
            if (state is CreatePaymentLoading) {
              setState(() {
                _isPaying = true; // 🔄 keep loading
              });
              // Optional loader
            }

            if (state is CreatePaymentSuccess) {
              setState(() {
                _isPaying = false; // ✅ stop loading
              });
              final action = await showDialog<String>(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.black.withOpacity(0.4),
                builder: (_) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: Center(
                      child: Paymentsucess(
                        amount: state.response.paidAmount.toString(),
                        paymentMode: selectedPaymentMode,
                        changeAmount: state.response.change.toStringAsFixed(2),
                        paymentId: state.response.paymentId,
                        orderId: state.response.orderId,
                        loadedTables: widget.loadedTables,
                        pin: widget.pin,
                        token: widget.token,
                        restaurantId: widget.restaurantId,
                        zoneId: widget.zoneId,
                        restaurantName: '',
                      ),
                    ),
                  );
                },
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
                    SnackBar(content: Text(message)),
                  );

                  context.read<PaymentBloc>().add(
                    LoadPaymentSummary(
                      token: widget.token,
                      orderId: widget.orderId,
                      restaurantId: widget.restaurantId,
                      orderType: "Dine In",
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              } else {
                /// 🔥 Reset order completely
                context.read<OrderBloc>().add(ClearOrder());
              }
            }

            if (state is CreatePaymentFailure) {
              setState(() {
                _isPaying = false; // ❌ stop loading on error
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
        ),

        /// ✅ REMOVE DISCOUNT LISTENER
        BlocListener<RemoveDiscountBloc, RemoveDiscountState>(
          listener: (context, state) {
            if (state is RemoveDiscountSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.response.message)),
              );

              setState(() {
                _isDiscountApplied = false;
                _isNcDiscount = false;
                _discountAmount = 0;
                merchantDiscount = 0.0;
                discountController.clear();
              });

              context.read<PaymentBloc>().add(
                UpdateMerchantDiscount(0.0),
              );

              widget.onMerchantDiscountChanged(0.0);

              _updateAmountField();

              // 🔥 MUST RELOAD SUMMARY
              context.read<PaymentBloc>().add(
                LoadPaymentSummary(
                  token: widget.token,
                  orderId: widget.orderId,
                  restaurantId: widget.restaurantId,
                  orderType: "Dine In",
                ),
              );
            }

            if (state is RemoveDiscountFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Color(0xFFF5F5F6),
        body: Row(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Container(
                    height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.85,
                    width: MediaQuery
                        .of(context)
                        .size
                        .width * 0.65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      // border: Border.all(
                      //   color: Colors.grey.withOpacity(0.5),
                      //   width: 0.8,
                      // ),
                    ),
                    child: Container(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.60,
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * 0.50,
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 5),
                                _buildPaymentModeItem(
                                  "Select Payment Mode",
                                  context,
                                  selectedPaymentMode,
                                      (val) {
                                    setState(() {
                                      selectedPaymentMode = val;
                                      isCashSelected = val == "Cash";
                                    });
                                  },
                                ),
                                SizedBox(height: 5),
                                Container(
                                  alignment: Alignment.center,
                                  height:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.68,
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width * 0.40,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFDEE8FF),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: Color(0xFFFFEBEB).withOpacity(1),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      SizedBox(height: 8),
                                      Container(
                                        height:
                                        MediaQuery
                                            .of(context)
                                            .size
                                            .height *
                                            0.05,
                                        width:
                                        MediaQuery
                                            .of(context)
                                            .size
                                            .width *
                                            0.38,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFDF7F7),
                                          borderRadius: BorderRadius.circular(
                                              5),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                                0.5),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            "$selectedPaymentMode Payment",
                                            style: TextStyle(
                                              color: Color(0xFFFE6464),
                                              fontSize: 15,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        height: MediaQuery.of(context).size.height * 0.07,
                                        width: MediaQuery.of(context).size.width * 0.38,
                                        decoration: BoxDecoration(
                                          color: isPaymentDisabled
                                              ? Colors.grey.shade200   //disabled look
                                              : const Color(0xFFFFFDFD),
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(
                                            color: const Color(0xFFF2EEEE).withOpacity(0.5),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              isPaymentDisabled ? "0.00" : amount,
                                              style: TextStyle(
                                                color: isPaymentDisabled
                                                    ? Colors.grey
                                                    : const Color(0xFF4C5F7D),
                                                fontSize: 15,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w500,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: 5),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: BlocBuilder<PaymentBloc, PaymentState>(
                                          builder: (context, state) {
                                            double netPayable = 0.0;

                                            if (state is PaymentSummaryLoaded) {
                                              netPayable = state.summary.netTotal; // ✅ updated net payable
                                            }

                                            final presetAmounts = buildPresetAmounts(netPayable);

                                            return Wrap(
                                              spacing: 10,
                                              runSpacing: 10,
                                              children: presetAmounts.map((value) {
                                                return GestureDetector(
                                                  onTap: isPaymentDisabled
                                                      ? null
                                                      : () => _onPresetAmountTap(value.toStringAsFixed(0)),

                                                  child: Container(
                                                    height: MediaQuery.of(context).size.height * 0.05,
                                                    width: MediaQuery.of(context).size.width * 0.10,
                                                    decoration: BoxDecoration(
                                                      color: isPaymentDisabled
                                                          ? Colors.grey.shade300
                                                          : amount == value.toStringAsFixed(0)
                                                          ? const Color(0xFFDFF5E1)
                                                          : const Color(0xFFE1F9DA),
                                                      borderRadius: BorderRadius.circular(5),
                                                      border: Border.all(
                                                        color: const Color(0xFFF2EEEE).withOpacity(0.5),
                                                        width: 0.8,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "₹${value.toStringAsFixed(0)}",
                                                        style: const TextStyle(
                                                          color: Color(0xFF318616),
                                                          fontSize: 15,
                                                          fontFamily: 'Inter',
                                                          fontWeight: FontWeight.w500,
                                                          decoration: TextDecoration.none,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            );
                                          },
                                        ),
                                      ),



                                      Expanded(
                                        flex: 1,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: NumberPad(
                                            onKeyPressed: handleKeyPress,
                                            selectedPaymentMode:
                                            selectedPaymentMode,
                                            isPaying: _isPaying,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 15),
                          SizedBox(height: 5),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildPayment(
                                context,
                                amount,
                                "Transaction Overview :",
                                netPayable: netPayable,

                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Action:",
                                style: TextStyle(
                                  color: Color(0xFF212121),
                                  fontSize: 15,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              const SizedBox(height: 5),

                              _buildPaymentDiscountItem(
                                context,
                                netPayable: netPayable,
                                orderId: widget.orderId,
                                token: widget.token,
                                restaurantId: widget.restaurantId,

                                // ✅ controller comes from parent
                                discountController: discountController,
                                couponController: couponController,
                                tipController: tipController,
                                splitPayController: splitPayController,


                                // ===== STATE FLAGS =====
                                isDiscountApplied: _isDiscountApplied,
                                isCouponApplied: _isCouponApplied,
                                isTipApplied: _isTipApplied,
                                isSplitApplied: _isSplitApplied,
                                // 👇 ADD THESE
                                selectedServiceCharge: selectedServiceCharge,
                                isServiceChargeApplied: isServiceChargeApplied,

                                onServiceChargeApplied: (percentage) async {
                                  await applyServiceCharge(percentage);
                                },

                                onServiceChargeDelete: () async {
                                  await deleteServiceCharge();
                                },

                                appliedCoupon: _appliedCoupon,

                                // ===== APPLY CALLBACKS =====

                                onDiscountApplied: (double amount, bool isNc) {
                                  debugPrint("🟠 onDiscountApplied amount=$amount isNc=$isNc");

                                  // Only update the field visually for instant feedback
                                  discountController.text = amount.toStringAsFixed(2);

                                  // DO NOT touch _isDiscountApplied, merchantDiscount or _isNcDiscount here

                                  // Always refresh from backend so real NC + discount come from API
                                  context.read<PaymentBloc>().add(
                                    LoadPaymentSummary(
                                      token: widget.token,
                                      orderId: widget.orderId,
                                      restaurantId: widget.restaurantId,
                                      orderType: "Dine In",
                                    ),
                                  );
                                },

                                onCouponApplied: (coupon, amount) {
                                  setState(() {
                                    _isCouponApplied = true;
                                    _appliedCoupon = coupon;
                                    _couponAmount = amount;

                                    couponController.text = coupon;
                                  });

                                  widget.onCouponAmountChanged?.call(amount);

                                  _updateAmountField();

                                  // 🔥 Refresh Payment Summary
                                  context.read<PaymentBloc>().add(
                                    LoadPaymentSummary(
                                      token: widget.token,
                                      orderId: widget.orderId,
                                      restaurantId: widget.restaurantId,
                                      orderType: "Dine In",
                                    ),
                                  );

                                  debugPrint("Coupon Applied = $coupon");
                                  debugPrint("Coupon Amount = $amount");
                                  debugPrint("_couponAmount = $_couponAmount");
                                },

                                onTipApplied: (amount) {
                                  setState(() {
                                    _isTipApplied = true;
                                    _tipAmount = amount;
                                    tipController.text = amount.toStringAsFixed(2);
                                  });

                                  widget.onTipChanged(amount);

                                  context.read<PaymentBloc>().add(
                                    LoadPaymentSummary(
                                      token: widget.token,
                                      orderId: widget.orderId,
                                      restaurantId: widget.restaurantId,
                                      orderType: "Dine In",
                                    ),
                                  );
                                },

                                onSplitApplied: (amount) {
                                  setState(() {
                                    _isSplitApplied = true;
                                    _splitAmount = amount;
                                    splitPayController.text =
                                        amount.toStringAsFixed(2);
                                  });
                                },

                                // ===== DELETE CALLBACKS =====
                                onDiscountDelete: () {
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
                                },


                                //   // reset local NC flag after sending request
                                //   setState(() {
                                //     _isNcDiscount = false;
                                //   });
                                // },

                                  onCouponDelete: () async {
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

                                      context.read<PaymentBloc>().add(
                                        LoadPaymentSummary(
                                          token: widget.token,
                                          orderId: widget.orderId,
                                          restaurantId: widget.restaurantId,
                                          orderType: "Dine In",
                                        ),
                                      );

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Coupon removed successfully"),
                                        ),
                                      );
                                    }
                                  },
                                onTipDelete: () async {
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
                                      const SnackBar(content: Text('Tip removed successfully')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to remove tip')),
                                    );
                                  }
                                },

                                onSplitDelete: () {
                                  setState(() {
                                    _isSplitApplied = false;
                                    _splitAmount = 0;
                                    splitPayController.clear();
                                  });
                                },
                              ),


                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


@override
Widget buildPayment(
    BuildContext context,
    String amount,
    String label, {
      required double netPayable,
    })
{

  final double tenderAmount =
  amount.isNotEmpty ? double.tryParse(amount) ?? 0.0 : 0.0;

  final double balanceAmount =
  tenderAmount < netPayable ? (netPayable - tenderAmount) : 0.0;

  final bool isPartial = tenderAmount < netPayable;
  final bool isOver = tenderAmount > netPayable;

  final double changeAmount =
  isOver ? (tenderAmount - netPayable) : 0.0;


  /// 🔍 DEBUG
  print('💰 netPayable = $netPayable');
  print('Tender Amount = $tenderAmount');

  if (isPartial) {
    print('Payment Type: PARTIAL PAYMENT');
  } else if (isOver) {
    print('Payment Type: OVER PAYMENT');
  } else {
    print('Payment Type: FULL PAYMENT');
  }

  print('-----------------------------------------------');

  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 5),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF212121),
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          height: 1.00,
          decoration: TextDecoration.none,
        ),
      ),
      SizedBox(height: 15),
      Container(
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height * 0.30,
        width: MediaQuery.of(context).size.width * 0.20,
        decoration: BoxDecoration(
          color: Color(0xFFDEE8FF),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 8),
            _buildColumnItem(
              "Balance Amount.",
              balanceAmount.toStringAsFixed(2),
              context,
              amount: balanceAmount,
            ),
            SizedBox(width: 20),
            _buildColumnItem(
              "Tender Amount.",
              tenderAmount.toStringAsFixed(2),
              context,
              amount: tenderAmount,
            ),
            SizedBox(width: 20),
            _buildColumnItem(
              "Change.",
              changeAmount.toStringAsFixed(2),
              context,
              amount: changeAmount,
            ),
          ],
        ),
      ),
    ],
  );
}

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
        // Left side 3x4 grid
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
        // Right side: Delete, Clear, Pay button stacked vertically
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildSideButton("⌫"),
              _buildSideButton("C"),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: isPaying ? null : () => onKeyPressed("Pay"),

                    child: Container(
                      decoration: BoxDecoration(
                        color:
                        selectedPaymentMode.isNotEmpty
                            ? Color(0xFFFE6464)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: isPaying
                          ? const SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
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
        padding: EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => onKeyPressed(label),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: border,
              boxShadow: [
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
                color:
                textColor ??
                    (isNumber ? Color(0xFF4C5F7D) : Color(0xFF4C5F7D)),
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
        padding: EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => onKeyPressed(label),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
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

// bool isSplitApplied = false;
// final TextEditingController splitPayController = TextEditingController();
// final TextEditingController _discountController = TextEditingController();





Widget _buildPaymentDiscountItem(
    BuildContext context, {
      required double netPayable,
      required int orderId,

      required TextEditingController discountController,
      required TextEditingController couponController,
      required TextEditingController tipController,
      required TextEditingController splitPayController,

      required bool isDiscountApplied,
      required bool isCouponApplied,
      required bool isTipApplied,
      required bool isSplitApplied,

      required void Function(double amount, bool isNc) onDiscountApplied,

      required Function(String, double) onCouponApplied,
      required ValueChanged<double> onTipApplied,
      required ValueChanged<double> onSplitApplied,

      required VoidCallback onDiscountDelete,
      required VoidCallback onCouponDelete,
      required VoidCallback onTipDelete,
      required VoidCallback onSplitDelete,
      required int? selectedServiceCharge,
      required bool isServiceChargeApplied,
      required ValueChanged<int> onServiceChargeApplied,
      required VoidCallback onServiceChargeDelete,


      String appliedCoupon = "", required String token, required String restaurantId,
    })

{

  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Container(
    height: screenHeight * 0.44,
    width: screenWidth * 0.20,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFDEE8FF),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// 🔻 DISCOUNT
        const Text('Discount :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isDiscountApplied
                    ? null
                    : () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) {
                      return MultiBlocProvider(
                        providers: [
                          BlocProvider(
                            create: (_) => DiscountReasonBloc(
                              DiscountReasonRepository(),
                            ),
                          ),
                          BlocProvider.value(
                            value: context.read<DiscountBloc>(), // ✅ reuse same instance
                          ),

                        ],
                        child: DiscountPopup(
                          netPayable: netPayable,
                          orderId: orderId,
                        ),
                      );
                    },
                  );

                  if (result != null) {
                    final double applied =
                    (result["amount"] as double).abs();
                    final bool isNc = result["isNc"] == true;


                    // update only the field UI here
                    discountController.text =
                        applied.toStringAsFixed(2);

                    // tell parent “a discount was applied”
                    onDiscountApplied(applied, isNc);
                  }
                },
                child: AbsorbPointer(
                  child: _inputField(
                    controller: discountController,
                    hint: '0.00',
                    enabled: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (isDiscountApplied)
              _deleteButton(() {
                debugPrint("🔥 Delete icon tapped");
                // just inform parent to delete
                onDiscountDelete();
              }),
          ],
        ),







        const SizedBox(height: 4),


        /// 🔻 COUPON
        const Text('Coupon :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isCouponApplied
                    ? null
                    : () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Couponscreen(
                      orderId: orderId,
                      token: token,
                      onCouponApplied: (coupon, amount) {
                        onCouponApplied(coupon, amount);
                      },
                    ),
                  );
                },
                child: AbsorbPointer(
                  child: _inputField(
                    hint: 'Enter your coupon code',
                    enabled: !isCouponApplied,
                    // initialValue: appliedCoupon,
                    controller: couponController,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (isCouponApplied)
              _deleteButton(onCouponDelete),
          ],
        ),


        const SizedBox(height: 4),

        /// 🔻 TIP
        const Text('Tip :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isTipApplied
                    ? null
                    : () async {
                  final double? result = await showDialog<double>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => TipPopup(
                      orderId: orderId,
                      token: token,
                      onTipApplied: onTipApplied,
                    ),
                  );

                  if (result != null && result > 0) {
                    onTipApplied(result);
                  }
                },
                child: AbsorbPointer(
                  child: _inputField(
                    hint: 'Enter tip amount',
                    keyboardType: TextInputType.number,
                    enabled: !isTipApplied,
                    controller:tipController,
                    // initialValue: '' ,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (isTipApplied)
              _deleteButton(onTipDelete),
          ],
        ),

        const SizedBox(height: 4),

        /// 🔻 SPLIT PAY
        // const Text('Split pay :',
        //     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        // const SizedBox(height: 6),
        // Row(
        //   children: [
        //     Expanded(
        //       child: GestureDetector(
        //         onTap: isSplitApplied
        //             ? null
        //             : () async {
        //           final result = await showDialog<Map<String, dynamic>>(
        //             context: context,
        //             barrierDismissible: false,
        //             builder: (_) => SplitPaymentPopup(netPayable: netPayable),
        //           );
        //
        //           if (result != null) {
        //             print(result['payable']);
        //           }
        //
        //         },
        //
        //         child: AbsorbPointer(
        //           child: _inputField(
        //             hint: 'Enter split amount',
        //             keyboardType: TextInputType.number,
        //             enabled: !isSplitApplied,
        //             controller:  splitPayController,
        //           ),
        //         ),
        //       ),
        //     ),
        //     const SizedBox(width: 4),
        //     if (isSplitApplied)
        //       _deleteButton(onSplitDelete),
        //   ],
        // ),
        /// 🔻 SERVICE CHARGES
        const SizedBox(height: 4),

        const Text(
          'Service Charges :',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        // const SizedBox(height: 6),

        Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedServiceCharge,
                    hint: const Text(
                      "Select Service Charge",
                      style: TextStyle(fontSize: 12),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text("1%"),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text("2%"),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text("3%"),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text("4%"),
                      ),
                      DropdownMenuItem(
                        value: 5,
                        child: Text("5%"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      onServiceChargeApplied(value);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(width: 4),

            if (selectedServiceCharge != null)
              _deleteButton(onServiceChargeDelete),
          ],
        ),
      ],


    ),
  );
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
      // enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,
      ),
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
      child: const Icon( Icons.delete, size: 18, color: Colors.red),
    ),
  );
}



Widget _buildActionRow(
    BuildContext context, {
      required Color color,
      required String ellipse,
      required String icon,
      required String label,
      VoidCallback? onTap, // nullable for disabling main button
      bool isDeleteEnabled = false, // new flag
      VoidCallback? onDelete, // callback for delete action
    }) {
  return Row(
    children: [
      Expanded(
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                // Stack(
                //   alignment: Alignment.center,
                //   children: [
                //     Image.asset(ellipse, width: 44, height: 44),
                //     Image.asset(icon, width: 24, height: 24),
                //   ],
                // ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      InkWell(
        onTap: isDeleteEnabled ? onDelete : null, // disable if false
        child: Container(
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            color: isDeleteEnabled ? Colors.white : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Image.asset(
              "assets/icon/delete.png",
              width: 25,
              height: 25,
              fit: BoxFit.contain,
              color: isDeleteEnabled ? null : Colors.grey, // gray icon if disabled
            ),
          ),
        ),
      ),
    ],
  );
}


Widget _buildPaymentModeItem(
    String label,
    BuildContext context,
    String selectedOption,
    Function(String) onSelect,
    ) {
  final List<Map<String, dynamic>> options = [
    {
      "label": "Cash",
      "image": "assets/cash.png",
      "enabled": true,
    },
    {
      "label": "Card",
      "image": "assets/card.png",
      "enabled": false, // ❌ disabled
    },
    {
      "label": "UPI",
      "image": "assets/icon/upi.png",
      "enabled": false, // ❌ disabled
    },
  ];


  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 5),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF152148),
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          height: 1.10,
          decoration: TextDecoration.none,
        ),
      ),
      SizedBox(height: 10),
      Container(
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height * 0.10,
        width: MediaQuery.of(context).size.width * 0.40,
        decoration: BoxDecoration(
          color: Color(0xFFDEE8FF),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
          options.map((option) {
            final bool isSelected = selectedOption == option['label'];
            final bool isEnabled = option['enabled'] == true;

            return GestureDetector(
              onTap: isEnabled ? () => onSelect(option['label']!) : null,
              child: Opacity(
                opacity: isEnabled ? 1.0 : 0.4, // 👈 disabled look
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  height: 35,
                  width: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFCDFDC)
                        : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(0),
                    border: isSelected
                        ? Border.all(color: const Color(0xFFFE6464))
                        : Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: isEnabled
                            ? const Color(0x10000000)
                            : Colors.transparent,
                        offset: const Offset(0, 1),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        option['image']!,
                        width: 30,
                        height: 30,
                        color: isEnabled ? null : Colors.grey, // 👈 grey icon
                      ),
                      const SizedBox(width: 4),
                      Text(
                        option['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !isEnabled
                              ? Colors.grey
                              : isSelected
                              ? const Color(0xFFFE6464)
                              : const Color(0xFF4147D5),
                          fontSize: 13,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                          letterSpacing: 0.60,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

        ),
      ),
    ],
  );
}

Widget _buildColumnItem(
    String label,
    String insideText,
    BuildContext context, {
      num? amount,
    }) {
  // Determine color based on the value
  Color textColor;
  if (amount != null) {
    if (amount == (AppDatabase.instance.totalamount ?? 0.0)) {
      textColor = Color(0xFFFE6464);
    } else if (amount <= 2230.00) {
      textColor = Color(0xFF373535);
    } else {
      textColor = Color(0xFF318616);
    }
  } else {
    textColor = Color(0xFF373535);
  }
  return Padding(
    padding: const EdgeInsets.only(left: 15), // 👈 shift whole column to right
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 👈 align to start
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF656161),
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: 7),
        Container(
          height: MediaQuery.of(context).size.height * 0.05,
          width: MediaQuery.of(context).size.width * 0.17,
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F6),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 0.8,
            ),
          ),
          alignment: Alignment.centerLeft, // 👈 text starts at left
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ), // small padding inside
          child: Text(
            insideText,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.start,
          ),
        ),

        // example extra widgets
        Column(children: [Container()]),
      ],
    ),
  );
}