import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/payment_summary_repository.dart';
import '../Bloc Event/payment_event.dart';
import '../Bloc State/payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository repository;

  PaymentBloc(this.repository) : super(PaymentInitial()) {
    on<LoadPaymentSummary>((event, emit) async {
      emit(PaymentLoading());

      try {
        final summary = await repository.fetchOrderPaymentDetails(
          restaurantId: event.restaurantId,
          orderId: event.orderId,
          zoneId: event.zoneId,
          orderType: event.orderType,
        );
        debugPrint("🔥 API returned merchant_discount = ${summary.discount}");
        debugPrint("🔥 API returned isNoCharge (NC) = ${summary.isNoCharge}");

        emit(
          PaymentSummaryLoaded(
            summary: summary,
            merchantDiscount: summary.discount,
            isNoCharge: summary.isNoCharge,// ✅ from API
          ),
        );
        debugPrint("🟥 PaymentBloc emitted merchantDiscount(from API) = ${summary.discount}");
        debugPrint("🟥 PaymentBloc emitted isNoCharge (NC) = ${summary.isNoCharge}");
      } catch (e) {
        final message = e.toString().replaceFirst("Exception: ", "");

        debugPrint("Payment Error: $message");

        emit(PaymentFailure(message));
      }
    });


    on<SelectPaymentMethod>((event, emit) {
      if (state is PaymentSummaryLoaded) {
        final current = state as PaymentSummaryLoaded;

        emit(
          PaymentSummaryLoaded(
            summary: current.summary,
            selectedMethod: event.method,
            merchantDiscount: current.merchantDiscount,
            isNoCharge: current.isNoCharge,// ✅ keep it
          ),
        );
      }
    });

    on<ConfirmPayment>((event, emit) async {
      emit(PaymentLoading());
      try {
        await Future.delayed(const Duration(seconds: 1));
        emit(PaymentSuccess("RCPT-${DateTime.now().millisecondsSinceEpoch}"));
      } catch (_) {
        emit(PaymentFailure("Payment failed"));
      }
    });

    on<ResetPayment>((event, emit) {
      emit(PaymentInitial());
    });

    on<UpdateMerchantDiscount>((event, emit) {
      if (state is PaymentSummaryLoaded) {
        final current = state as PaymentSummaryLoaded;

        emit(
          PaymentSummaryLoaded(
            summary: current.summary,
            selectedMethod: current.selectedMethod,
            merchantDiscount: event.value,
            isNoCharge: event.isNoCharge,
          ),
        );

        debugPrint(
          "🟩 PaymentBloc emitted merchantDiscount = ${event.value}",
        );
        debugPrint(
          "🟩 PaymentBloc emitted isNoCharge = ${event.isNoCharge}",
        );
      }
    });

  }
}
