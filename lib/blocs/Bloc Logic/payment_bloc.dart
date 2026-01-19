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

        emit(
          PaymentSummaryLoaded(
            summary: summary,
            merchantDiscount: summary.discount, // ✅ from API
          ),
        );
      } catch (e) {
        emit(PaymentFailure(e.toString()));
      }
    });


    on<SelectPaymentMethod>((event, emit) {
      if (state is PaymentSummaryLoaded) {
        final current = state as PaymentSummaryLoaded;

        emit(
          PaymentSummaryLoaded(
            summary: current.summary,
            selectedMethod: event.method,
            merchantDiscount: current.merchantDiscount, // ✅ keep it
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
            merchantDiscount: event.value, // ✅ update it
          ),
        );
      }
    });
  }
}
