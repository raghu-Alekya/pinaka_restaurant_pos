import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/paymentsucess.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/splitpaymentpopup.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/tip_widget.dart';
import 'package:pinaka_restaurant_pos/blocs/Bloc%20Event/order_event.dart';
import '../../blocs/Bloc Event/create_payment_event.dart';
import '../../blocs/Bloc Logic/create_payment_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc State/create_payment_state.dart';
import '../../models/payment/create_payment_model.dart';
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

  const paymentsummary({
    Key? key,
    required this.loadedTables,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    this.zoneId,   required PaymentSummary,
  }) : super(key: key);


  @override
  State<paymentsummary> createState() => _paymentsummaryState();
}

class _paymentsummaryState extends State<paymentsummary> {
  String selectedOption = '';
  String amount = '';
  double balanceAmount = AppDatabase.instance.totalamount ?? 0.0;
  double? calculatedChange;
  String selectedPaymentMode = "Cash";
  bool isCashSelected = true;
  // ✅ Declare this variable
  bool _isDiscountApplied = false;
  bool _isCouponApplied = false;
  bool _isTipApplied = false;
  String _appliedCoupon = "";
  bool isSplitApplied = false;


  // / Delete button enabled if any of the above are applied
  bool get isDeleteEnabled =>
      _isTipApplied || _isDiscountApplied || _isCouponApplied;

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
      CreatePaymentEvent(
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
    if (!RegExp(r'^[0-9.]$').hasMatch(key)) {
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
    if (amount.isEmpty) {
      String cleaned = value.replaceAll("\$", "");
      setState(() {
        amount = cleaned;
      });
    }
  }
  List<double> buildPresetAmounts(double total) {
    if (total <= 0) return [];

    final r100 = ((total / 100).ceil()) * 100;
    final r500 = ((total / 500).ceil()) * 500;
    final r1000 = ((total / 1000).ceil()) * 1000;

    return {
      total,
      r100.toDouble(),
      r500.toDouble(),
      r1000.toDouble(),
    }.toList();
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount =
    context.select((OrderBloc bloc) => bloc.state.grossTotal);

    // ✅ DEFINE HERE
    final List<double> presetAmounts = buildPresetAmounts(totalAmount);
    return BlocListener<CreatePaymentBloc, PaymentState>(
        listener: (context, state) async {
          if (state is PaymentLoading) {
            // Optional loader
          }

          if (state is PaymentSuccess) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Paymentsucess(
                amount: state.response.paidAmount.toString(),
                paymentMode: selectedPaymentMode,
                changeAmount: state.response.remainingAmount.toString(),
                loadedTables: widget.loadedTables,
                pin: widget.pin,
                token: widget.token,
                restaurantId: widget.restaurantId,
                zoneId: widget.zoneId,
                restaurantName: '',
              ),
            );
            // 🔥 Reset order completely
            context.read<OrderBloc>().add(ClearOrder());
          }

          if (state is PaymentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
    child:  Scaffold(
      backgroundColor: Color(0xFFF5F5F6),
      body: Row(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  width: MediaQuery.of(context).size.width * 0.65,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    // border: Border.all(
                    //   color: Colors.grey.withOpacity(0.5),
                    //   width: 0.8,
                    // ),
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.60,
                    width: MediaQuery.of(context).size.width * 0.50,
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
                                MediaQuery.of(context).size.height * 0.68,
                                width: MediaQuery.of(context).size.width * 0.40,
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
                                      MediaQuery.of(context).size.height *
                                          0.05,
                                      width:
                                      MediaQuery.of(context).size.width *
                                          0.38,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFDF7F7),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
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
                                      MediaQuery.of(context).size.height *
                                          0.07,
                                      width:
                                      MediaQuery.of(context).size.width *
                                          0.38,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFFDFD),
                                        borderRadius: BorderRadius.circular(5),
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
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: presetAmounts.map((amount) {
                                          return GestureDetector(
                                            onTap: () => _onPresetAmountTap(amount as String),
                                            child: Container(
                                              height: MediaQuery.of(context).size.height * 0.05,
                                              width: MediaQuery.of(context).size.width * 0.05,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE1F9DA),
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(
                                                  color: const Color(0xFFF2EEEE).withOpacity(0.5),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  amount.toStringAsFixed(2),
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
                            ),

                            const SizedBox(height: 20),
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
                            _buildPaymentDiscountItem(
                              context,
                              onDiscountApplied: () {
                                setState(() => _isDiscountApplied = true);
                              },
                              onCouponApplied: (String coupon) {
                                setState(() {
                                  _isCouponApplied = true;
                                  _appliedCoupon = coupon; // store applied coupon
                                });
                              },
                              onTipApplied: () {
                                setState(() => _isTipApplied = true);
                              },
                              isDiscountApplied: _isDiscountApplied,
                              isCouponApplied: _isCouponApplied,
                              isTipApplied: _isTipApplied,
                              appliedCoupon: _appliedCoupon,

                              // ✅ pass proper delete logic and delete enable flag
                              isDeleteEnabled: _isDiscountApplied || _isCouponApplied || _isTipApplied,
                              onDelete: () {
                                setState(() {
                                  _isDiscountApplied = false;
                                  _isCouponApplied = false;
                                  _isTipApplied = false;
                                  _appliedCoupon = "";
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
    ));
  }
}

@override
Widget buildPayment(BuildContext context, String amount, String label) {
  double balanceAmount = AppDatabase.instance.totalamount ?? 0.0;
  double tenderAmount =
  amount.isNotEmpty ? double.tryParse(amount) ?? 0.0 : 0.0;
  double changeAmount = (balanceAmount - tenderAmount).abs();

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
        height: MediaQuery.of(context).size.height * 0.28,
        width: MediaQuery.of(context).size.width * 0.20,
        decoration: BoxDecoration(
          color: Color(0xFFDEE8FF),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
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
            // _buildColumnItem(
            //   "Change.",
            //   changeAmount.toStringAsFixed(2),
            //   context,
            //   amount: changeAmount,
            // ),
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
bool _isDiscountApplied = false;
bool _isCouponApplied = false;
bool _isTipApplied = false;
String _appliedCoupon = "";
bool isSplitApplied = false;



Widget _buildPaymentDiscountItem(
    BuildContext context, {
      required VoidCallback onDiscountApplied,
      required Function(String) onCouponApplied,
      required VoidCallback onTipApplied,
      required bool isDiscountApplied,
      required bool isCouponApplied,
      required bool isTipApplied,
      required bool isDeleteEnabled, // ✅ pass this
      required VoidCallback onDelete,
      String appliedCoupon = "",
    }) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  Color appliedColor = Colors.grey.shade400;

  return Column(
    children: [
      Container(
        height: screenHeight * 0.45,
        width: screenWidth * 0.20,
        decoration: BoxDecoration(
          color: const Color(0xFFDEE8FF),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // DISCOUNT BUTTON
            _buildActionRow(
              context,
              color: isDiscountApplied ? appliedColor : const Color(0xFF3DA540),
              ellipse: "assets/icon/green .png",
              icon: "assets/icon/discount.png",
              label: isDiscountApplied ? "Discount Applied" : "Discount",
              onTap: isDiscountApplied
                  ? null
                  : () async {
                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const DiscountPopup(),
                );
                if (result == true) onDiscountApplied();
              },
            ),

            const SizedBox(height: 15),

            // COUPON BUTTON
            _buildActionRow(
              context,
              color: isCouponApplied ? Colors.grey : const Color(0xFFEB4D4D),
              ellipse: "assets/icon/REDellipse.png",
              icon: "assets/coupon.png",
              label: isCouponApplied
                  ? "Coupon Applied: $appliedCoupon"
                  : "Coupon",
              onTap: isCouponApplied
                  ? null
                  : () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Couponscreen(
                    onCouponApplied: (String coupon) {
                      onCouponApplied(coupon); // ✅ update parent state
                      Navigator.of(context).pop(); // close popup only
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // TIP BUTTON
            _buildActionRow(
              context,
              color: isTipApplied ? Colors.grey : const Color(0xFF4C81F1),
              ellipse: "assets/icon/Ellipse 1934.png",
              icon: "assets/icon/tip.png",
              label: isTipApplied ? "Tip Added" : "Add Tip",
              onTap: isTipApplied
                  ? null
                  : () async {
                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const TipPopup(),
                );
                if (result == true) onTipApplied();
              },
              isDeleteEnabled: isDeleteEnabled, // enable if any applied
              // onDelete: () {
              //   // Reset all applied states
              //   setState(() {
              //     isDiscountApplied = false;
              //     isCouponApplied = false;
              //     isTipApplied = false;
              //   });
              // },
            ),
            // _buildActionRow(
            //   context,
            //   color: isSplitApplied ? Colors.grey : const Color(0xFF4C81F1),
            //   ellipse: "assets/icon/Ellipse 1934.png",
            //   icon: "assets/icon/split.png",
            //   label: isSplitApplied ? "Split Applied" : "Split Payment",
            //   onTap: isSplitApplied
            //       ? null
            //       : () async {
            //     final result = await showDialog<bool>(
            //       context: context,
            //       barrierDismissible: false,
            //       builder: (context) => const SplitPaymentPopup(),
            //     );
            //
            //     if (result == true) {
            //       setState(() {
            //         isSplitApplied = true;
            //       });
            //     }
            //   },
            //   isDeleteEnabled: isSplitApplied,
            // ),
            //


          ],
        ),
      ),
    ],
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
        SizedBox(height: 10),
        Container(
          height: MediaQuery.of(context).size.height * 0.07,
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