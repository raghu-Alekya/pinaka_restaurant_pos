import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/payment_event.dart';
import '../../blocs/Bloc Event/tax_event.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/payment_bloc.dart';
import '../../blocs/Bloc Logic/tax_bloc.dart';
import '../../blocs/Bloc State/payment_state.dart';
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
  double? _grandTotal;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadSessionData();

    // Background load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderBloc = context.read<OrderBloc>();
      final orderId = orderBloc.state.orderId;

      if (orderId != null) {
        context.read<PaymentBloc>().add(
          LoadPaymentSummary(
            restaurantId: widget.restaurantId,
            orderId: orderId,
            zoneId: orderBloc.state.zoneId,
            orderType: "Dine In",
            token: widget.token,
          ),
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
        final paymentSummary = state is PaymentSummaryLoaded ? state.summary : null;
        final merchantDiscount = state is PaymentSummaryLoaded ? state.merchantDiscount : 0.0;
        final orderId = context.read<OrderBloc>().state.orderId ?? 0;

        final hasCouponApplied = paymentSummary?.coupons != null && paymentSummary!.coupons > 0;
        final hasDiscountApplied = merchantDiscount.abs() > 0;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: TopBar(
              userPermissions: _userPermissions,
              // selectedUser: _selectedUser,
              token: widget.token,
              isPaymentScreen: true,
              restaurantName: widget.restaurantName,
              // isPaymentScreen: true,                    // ← Important
              pin: widget.pin,
              restaurantId:widget.restaurantId,
            ),
          ),
          body: Row(
            children: [
              // LEFT SIDEBAR
              Expanded(
                flex: 25,
                child: BlocProvider(
                  create: (context) => TaxBloc(TaxRepository())..add(LoadTaxesEvent()),
                  child: Sidebarwidgets(
                    userPermissions: _userPermissions,
                    selectedUser: _selectedUser,
                    merchantDiscount: merchantDiscount,
                    tipAmount: _tipAmount,
                    paymentSummary: paymentSummary,           // ← No ! here
                    hasCouponApplied: hasCouponApplied,
                    hasDiscountApplied: hasDiscountApplied,
                    appliedCouponAmount: paymentSummary?.coupons ?? 0.0,
                    token: widget.token,
                    onNetPayableChanged: (double value) {
                      setState(() => _grandTotal = value);
                    },
                  ),
                ),
              ),

              // RIGHT - PAYMENT NUMPAD
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
                  onMerchantDiscountChanged: (double value) {
                    context.read<PaymentBloc>().add(UpdateMerchantDiscount(value));
                  },
                  onTipChanged: (double value) {
                    setState(() => _tipAmount = value);
                  },
                  onCouponAmountChanged: (double amount) {
                    setState(() {
                      if (amount > 0) _couponAmount = amount;
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