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
import '../../repositories/discount_repository.dart';
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
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;


      final state = context.read<PaymentBloc>().state;

      if (state is PaymentSummaryLoaded) {
        final discount = state.merchantDiscount;
        final netPayable = state.summary.netTotal;

        discountController.text =
        discount != 0 ? discount.abs().toStringAsFixed(2) : "";

        setState(() {
          _isDiscountApplied = discount != 0;
          merchantDiscount = discount;
          // ✅ AUTO DISPLAY suggested amount (netPayable)
          amount = netPayable.toStringAsFixed(0);
        });
        debugPrint("✅ Auto amount updated = $amount");
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


  Future<void> _submitPayment() async {
    debugPrint("🟡 SUBMIT PAYMENT CALLED");

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
    // ✅ PAY BUTTON
    if (key == "Pay") {
      if (amount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter amount")),
        );
        return;
      }
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

    final double netPayable = context.select(
          (PaymentBloc bloc) =>
      bloc.state is PaymentSummaryLoaded
          ? (bloc.state as PaymentSummaryLoaded).summary.netTotal
          : 0.0,
    );




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

              debugPrint("🟢 BlocListener triggered");
              debugPrint("🟢 Backend merchantDiscount = $discount");
              debugPrint("🟢 Backend isNoCharge (NC) = ${state.isNoCharge}");

              discountController.text =
              discount != 0 ? discount.abs().toStringAsFixed(2) : "";

              final newIsDiscountApplied = discount != 0;

              debugPrint("🟣 Before setState:");
              debugPrint("   _isDiscountApplied (old) = $_isDiscountApplied");
              debugPrint("   _isNcDiscount (old) = $_isNcDiscount");

              setState(() {
                _isDiscountApplied = newIsDiscountApplied;
                merchantDiscount = discount;

                _isNcDiscount = state.isNoCharge;

              });

              debugPrint("🟣 After setState:");
              debugPrint("   _isDiscountApplied (new) = $_isDiscountApplied");
              debugPrint("   _isNcDiscount (new) = $_isNcDiscount");
            }
          },
        ),



        /// ✅ PAYMENT LISTENER
        BlocListener<CreatePaymentBloc, CreatePaymentState>(
          listener: (context, state) async {
            if (state is CreatePaymentLoading) {
              // Optional loader
            }

            if (state is CreatePaymentSuccess) {
              await showDialog(
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

              /// 🔥 Reset order completely
              context.read<OrderBloc>().add(ClearOrder());
            }

            if (state is CreatePaymentFailure) {
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

              // Now clear everything only after backend confirmed removal
              setState(() {
                _isDiscountApplied = false;
                _isNcDiscount = false;   // ✅ reset NC here
                _discountAmount = 0;
                merchantDiscount = 0.0;
                discountController.clear();
              });

              // // sync bloc and parent after state is cleaned
              // context.read<PaymentBloc>().add(UpdateMerchantDiscount(0.0));
              // widget.onMerchantDiscountChanged(0.0);

              // finally refresh summary from server
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
                                        height:
                                        MediaQuery
                                            .of(context)
                                            .size
                                            .height *
                                            0.07,
                                        width:
                                        MediaQuery
                                            .of(context)
                                            .size
                                            .width *
                                            0.38,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFFFDFD),
                                          borderRadius: BorderRadius.circular(
                                              5),
                                          border: Border.all(
                                            color: Color(
                                              0xFFF2EEEE,
                                            ).withOpacity(0.5),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              amount.isNotEmpty ? amount : '',
                                              style: TextStyle(
                                                color: Color(0xFF4C5F7D),
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
                                                  onTap: () => _onPresetAmountTap(value.toStringAsFixed(0)),
                                                  child: Container(
                                                    height: MediaQuery.of(context).size.height * 0.05,
                                                    width: MediaQuery.of(context).size.width * 0.10,
                                                    decoration: BoxDecoration(
                                                      color: amount == value.toStringAsFixed(0)
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
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 25),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildPayment(
                                context,
                                amount,
                                "Transaction Overview :",
                                netPayable: netPayable,

                              ),

                              const SizedBox(height: 25),
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
                              const SizedBox(height: 15),

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

                                  onCouponApplied: (coupon) {
                                  setState(() {
                                    _isCouponApplied = true;
                                    _appliedCoupon = coupon;
                                    couponController.text = coupon;
                                  });
                                },

                                onTipApplied: (amount) {
                                  setState(() {
                                    _isTipApplied = true;
                                    _tipAmount = amount;
                                    tipController.text =
                                        amount.toStringAsFixed(2);
                                  });
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
                                    // ✅ always take NC flag from backend-loaded state
                                    isNcFlag = paymentState.isNoCharge ? "yes" : "no";
                                  }

                                  debugPrint("🧨 Deleting discount with isNc = $isNcFlag");

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

                                onCouponDelete: () {
                                  setState(() {
                                    _isCouponApplied = false;
                                    _appliedCoupon = '';
                                    couponController.clear();
                                  });
                                },
                                onTipDelete: () {
                                  setState(() {
                                    _isTipApplied = false;
                                    _tipAmount = 0;
                                    tipController.clear();
                                  });
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
  // final double grossTotal = context.select(
  //       (PaymentBloc bloc) =>
  //   bloc.state is PaymentSummaryLoaded
  //       ? (bloc.state as PaymentSummaryLoaded).summary.grossTotal
  //       : 0.0,
  // );

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
          height: 1.10,
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

  const NumberPad({
    super.key,
    required this.onKeyPressed,
    required this.selectedPaymentMode,
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
                    onTap: () => onKeyPressed("Pay"),
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
                      child: Text(
                        "PAY",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                          selectedPaymentMode.isNotEmpty
                              ? Colors.white
                              : Color(0xFF4C5F7D),
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

      required ValueChanged<String> onCouponApplied,
      required ValueChanged<double> onTipApplied,
      required ValueChanged<double> onSplitApplied,

      required VoidCallback onDiscountDelete,
      required VoidCallback onCouponDelete,
      required VoidCallback onTipDelete,
      required VoidCallback onSplitDelete,


      String appliedCoupon = "", required String token, required String restaurantId,
    })

{

  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Container(
    height: screenHeight * 0.40,
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
        const SizedBox(height: 6),
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







        const SizedBox(height: 14),

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
                      onCouponApplied: (coupon) {
                        onCouponApplied(coupon);
                        Navigator.pop(context);
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

        const SizedBox(height: 14),

        /// 🔻 TIP
        const Text('Tip :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
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
                    builder: (_) => const TipPopup(),
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
            const SizedBox(width: 6),
            if (isTipApplied)
              _deleteButton(onTipDelete),
          ],
        ),

        const SizedBox(height: 14),

        /// 🔻 SPLIT PAY
        const Text('Split pay :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isSplitApplied
                    ? null
                    : () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => SplitPaymentPopup(netPayable: netPayable),
                  );

                  if (result != null) {
                    print(result['payable']);
                  }

                },

                child: AbsorbPointer(
                  child: _inputField(
                    hint: 'Enter split amount',
                    keyboardType: TextInputType.number,
                    enabled: !isSplitApplied,
                    controller:  splitPayController,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (isSplitApplied)
              _deleteButton(onSplitDelete),
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
      enabled:  true,
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
  final List<Map<String, String>> options = [
    {"label": "Cash", "image": "assets/cash.png"},
    {"label": "Card", "image": "assets/card.png"},
    {"label": "UPI", "image": "assets/icon/upi.png"},
    //{"label": "EBT", "image": "assets/images/EDA.png"},
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
            return GestureDetector(
              onTap: () => onSelect(option['label']!),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                height: 35,
                width: 120,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFFCDFDC) : Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(0),
                  border:
                  isSelected
                      ? Border.all(color: Color(0xFFFE6464))
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x10000000),
                      offset: Offset(0, 1),
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
                    ),
                    SizedBox(width: 0),
                    Text(
                      option['label']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                        isSelected
                            ? Color(0xFFFE6464)
                            : Color(0xFF4147D5),
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