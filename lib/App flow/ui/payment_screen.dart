import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/payment_event.dart';
import '../../blocs/Bloc Event/tax_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc Logic/tax_bloc.dart';
import '../../blocs/Bloc State/payment_state.dart';
// import '../../blocs/payment/payment_bloc.dart';
// import '../../blocs/payment/payment_event.dart';
// import '../../blocs/payment/payment_state.dart';
import '../../local database/database_helper.dart';
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

  const PaymentScreen({
    super.key,
    required this.loadedTables,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
    this.zoneId,
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
  // double merchantDiscount = 0.0;


  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadSessionData();

    /// ✅ Load payment summary ONCE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderBloc = context.read<OrderBloc>();

      context.read<PaymentBloc>().add(
        LoadPaymentSummary(
          restaurantId: widget.restaurantId,
          orderId: orderBloc.state.orderId,
          zoneId: orderBloc.state.zoneId, // can be null
          orderType: "Dine In",
          token: widget.token, // ✅ must pass token
        ),
      );
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
      }
    } catch (e) {
      debugPrint("❌ Error loading permissions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        // 🔄 Loading
        if (state is PaymentLoading || state is PaymentInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Error
        if (state is PaymentFailure) {
          return Scaffold(
            body: Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        // debugPrint("🟦 Passing merchantDiscount to Sidebar = $merchantDiscount");


        // ✅ Data Loaded
        if (state is PaymentSummaryLoaded) {
          final paymentSummary = state.summary;
          final orderId = context.read<OrderBloc>().state.orderId; //
          final merchantDiscount = state.merchantDiscount; // ✅ important
          final hasCouponApplied = paymentSummary.coupons > 0;
          final hasDiscountApplied = merchantDiscount.abs() > 0;
          debugPrint("🔥 _couponAmount = $_couponAmount");
          debugPrint(
              "🔥 paymentSummary.coupons = ${paymentSummary.coupons}");
          debugPrint(
              "🚨 Passing coupon to sidebar = $_couponAmount");

          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: TopBar(
                userPermissions: _userPermissions,
                selectedUser: _selectedUser,
                token: widget.token,
                pin: widget.pin,
              ),
            ),
            body: Row(
              children: [

                /// LEFT SIDEBAR
                Expanded(
                  flex: 25,
                  child: BlocProvider(
                    create: (context) => TaxBloc(TaxRepository())..add(LoadTaxesEvent()),





                    child: Sidebarwidgets(
                      userPermissions: _userPermissions,
                      selectedUser: _selectedUser,
                      merchantDiscount: merchantDiscount,
                      tipAmount: _tipAmount,
                      paymentSummary: paymentSummary,
                      hasCouponApplied: hasCouponApplied,
                      hasDiscountApplied: hasDiscountApplied,
                      appliedCouponAmount: paymentSummary.coupons,
                      token: widget.token,
                    ),

                  ),
                ),


                /// NUMBER PAD
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

                    onMerchantDiscountChanged: (double value) {
                      context.read<PaymentBloc>().add(
                        UpdateMerchantDiscount(value),
                      );
                    },

                    onTipChanged: (double value) {
                      setState(() {
                        _tipAmount = value;
                      });
                    },
                    onCouponAmountChanged: (double amount) {
                      debugPrint("🎟 Coupon Amount Callback = $amount");

                      setState(() {
                        // Only use callback if > 0
                        if (amount > 0) {
                          _couponAmount = amount;
                        }
                      });
                    },
                  ),


                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}
