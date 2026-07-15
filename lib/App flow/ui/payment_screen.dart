import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/payment_event.dart';
import '../../blocs/Bloc Event/tax_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc Logic/tax_bloc.dart';
import '../../blocs/Bloc State/payment_state.dart';
import '../../local database/database_helper.dart';
import '../../models/payment/payment_summary_model.dart';
import '../../repositories/tax_repository.dart';
import '../../utils/SessionManager.dart';

import '../widgets/payment_sidebar_widget.dart';
import '../widgets/paymentnum_pad.dart';
import '../widgets/top_bar.dart';

class PaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> loadedTables;
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final int? zoneId;
  final bool isTakeAway;

  const PaymentScreen({
    super.key,
    required this.loadedTables,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    this.zoneId,
    this.isTakeAway = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  dynamic _userPermissions;
  String? token;
  int? userId;
  int? shiftId;
  Map<String, dynamic>? _selectedUser;
  double _tipAmount = 0.0;
  double _couponAmount = 0.0;
  double? _grandTotal;
  bool _hasPartialPayment = false;

  @override
  void initState() {
    super.initState();

    // ✅ DEBUG: Print PaymentScreen initialization
    debugPrint("💳 PaymentScreen init - isTakeAway: ${widget.isTakeAway}");
    debugPrint("💳 PaymentScreen init - restaurantId: ${widget.restaurantId}");
    debugPrint("💳 PaymentScreen init - zoneId: ${widget.zoneId}");

    _loadPermissions();
    _loadSessionData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderBloc = context.read<OrderBloc>();
      final orderId = orderBloc.state.orderId;

      // ✅ DEBUG: Print order details
      debugPrint("💳 PaymentScreen - OrderBloc state:");
      debugPrint("   - orderId: $orderId");
      debugPrint("   - items count: ${orderBloc.state.orderItems.length}");
      debugPrint("   - zoneId: ${orderBloc.state.zoneId}");
      debugPrint("   - isTakeAway: ${widget.isTakeAway}");

      if (orderId != null && orderId > 0) {
        // Reset the payment state to prevent displaying previous checkout values
        context.read<PaymentBloc>().add(ResetPayment());

        final orderType = widget.isTakeAway ? "Take Away" : "Dine In";
        debugPrint(
          "💳 Loading payment summary for Order ID: $orderId (Type: $orderType)",
        );

        context.read<PaymentBloc>().add(
          LoadPaymentSummary(
            restaurantId: widget.restaurantId,
            orderId: orderId,
            zoneId: orderBloc.state.zoneId,
            orderType: orderType,
            token: widget.token,
          ),
        );
      } else {
        debugPrint(
          "⚠️ PaymentScreen - No valid order ID found (orderId: $orderId)",
        );
      }
    });
  }

  Future<void> _loadSessionData() async {
    final db = DatabaseHelper();
    final user = await db.getLoggedInUser();
    final shift = await db.getCurrentShiftId();
    setState(() {
      token = user?['token'];
      userId = user?['id'];
      shiftId = shift;
    });

    debugPrint("💳 Session data loaded - userId: $userId, shiftId: $shiftId");
  }

  Future<void> _loadPermissions() async {
    try {
      final savedPermissions = await SessionManager.loadPermissions();
      if (savedPermissions != null) {
        setState(() {
          _userPermissions = savedPermissions;
          _selectedUser = {
            "id": savedPermissions.userId,
            "name": savedPermissions.displayName,
            "role": savedPermissions.role,
          };
        });
        debugPrint(
          "💳 Permissions loaded - User: ${savedPermissions.displayName}, Role: ${savedPermissions.role}",
        );
      }
    } catch (e) {
      debugPrint("❌ Error loading permissions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ DEBUG: Print build information
    debugPrint("💳 Building PaymentScreen - isTakeAway: ${widget.isTakeAway}");

    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final orderId = context.read<OrderBloc>().state.orderId ?? 0;
        final bool isStateValid =
            state is PaymentSummaryLoaded && state.summary.orderId == orderId;
        final rawSummary = isStateValid ? state.summary : null;
        final merchantDiscount = isStateValid ? state.merchantDiscount : 0.0;
        final PaymentSummary? paymentSummary =
            rawSummary != null
                ? rawSummary.copyWith(
                  discount: merchantDiscount.abs(),
                  coupons:
                      _couponAmount > 0 ? _couponAmount : rawSummary.coupons,
                  netTotal: _grandTotal ?? rawSummary.netTotal,
                  tipAmount: _tipAmount > 0 ? _tipAmount : rawSummary.tipAmount,
                )
                : null;

        final hasCouponApplied =
            _couponAmount > 0 || ((paymentSummary?.coupons ?? 0) > 0);
        final hasDiscountApplied = merchantDiscount.abs() > 0;

        // ✅ DEBUG: Print payment state
        debugPrint("💳 Payment State - orderId: $orderId");
        debugPrint("   - has payment summary: ${paymentSummary != null}");
        debugPrint("   - merchantDiscount: $merchantDiscount");
        debugPrint("   - tipAmount: $_tipAmount");
        debugPrint("   - grandTotal: $_grandTotal");
        debugPrint("   - isTakeAway: ${widget.isTakeAway}");

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: TopBar(
              userPermissions: _userPermissions,
              token: widget.token,
              isPaymentScreen: true,
              restaurantName: widget.restaurantName,
              pin: widget.pin,
              restaurantId: widget.restaurantId,
              paymentSummary: paymentSummary,
              loadedTables: widget.loadedTables,
              zoneId: widget.zoneId,
              cashierName: _selectedUser?['name'] ?? '',
              isTakeAway: widget.isTakeAway,
              onBackPressed: () {
                final paymentState = context.read<PaymentBloc>().state;

                final bool isNoCharge =
                    paymentState is PaymentSummaryLoaded &&
                    paymentState.isNoCharge;

                final bool hasDiscountApplied =
                    paymentState is PaymentSummaryLoaded &&
                    paymentState.merchantDiscount.abs() > 0;

                final double remainingAmount =
                    paymentState is PaymentSummaryLoaded
                        ? paymentState.summary.netTotal
                        : 0.0;

                if (_couponAmount > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please remove the applied coupon before going back.",
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }

                if (hasDiscountApplied) {
                  final String msg =
                      isNoCharge
                          ? "Please remove the applied No Charge discount before going back."
                          : "Please remove the applied discount to go back.";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  return;
                }

                if (_hasPartialPayment) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please complete the remaining payment before leaving this screen.",
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
              },
            ),
          ),
          body: Row(
            children: [
              Expanded(
                flex: 25,
                child: BlocProvider(
                  create:
                      (context) =>
                          TaxBloc(TaxRepository())..add(LoadTaxesEvent()),
                  child: Sidebarwidgets(
                    userPermissions: _userPermissions,
                    selectedUser: _selectedUser,
                    merchantDiscount: merchantDiscount,
                    tipAmount:
                        _tipAmount > 0
                            ? _tipAmount
                            : (paymentSummary?.tipAmount ?? 0),
                    paymentSummary: paymentSummary,
                    hasCouponApplied: hasCouponApplied,
                    hasDiscountApplied: hasDiscountApplied,
                    appliedCouponAmount:
                        _couponAmount > 0
                            ? _couponAmount
                            : (paymentSummary?.coupons ?? 0.0),
                    token: widget.token,
                    onNetPayableChanged: (double value) {
                      debugPrint(
                        "💳 Net payable changed: $value (isTakeAway: ${widget.isTakeAway})",
                      );
                      setState(() => _grandTotal = value);
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 50,
                child: paymentsummary(
                  loadedTables: widget.loadedTables,
                  pin: widget.pin,
                  token: widget.token,
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                  zoneId: widget.zoneId,
                  PaymentSummary: paymentSummary,
                  orderId: orderId,
                  grandTotal: _grandTotal,
                  isTakeAway:
                      widget.isTakeAway, // ✅ Pass isTakeAway to paymentsummary
                  onMerchantDiscountChanged: (double value) {
                    debugPrint(
                      "💳 Merchant discount changed: $value (isTakeAway: ${widget.isTakeAway})",
                    );
                    context.read<PaymentBloc>().add(
                      UpdateMerchantDiscount(value: value, isNoCharge: false),
                    );
                  },
                  onTipChanged: (double value) {
                    debugPrint(
                      "💳 Tip changed: $value (isTakeAway: ${widget.isTakeAway})",
                    );

                    setState(() {
                      _tipAmount = value;
                    });

                    context.read<PaymentBloc>().add(UpdateTip(value));
                  },
                  onCouponAmountChanged: (double amount) {
                    debugPrint(
                      "💳 Coupon amount changed: $amount (isTakeAway: ${widget.isTakeAway})",
                    );
                    setState(() {
                      _couponAmount = amount;
                    });
                  },
                  onPartialPaymentChanged: (value) {
                    setState(() {
                      _hasPartialPayment = value;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
