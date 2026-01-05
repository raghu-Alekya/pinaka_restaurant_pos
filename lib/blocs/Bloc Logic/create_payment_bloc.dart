import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/create_payment_repository.dart';
import '../Bloc Event/create_payment_event.dart';
import '../Bloc State/create_payment_state.dart';

class CreatePaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final CreatePaymentRepository repository;

  CreatePaymentBloc(this.repository, {required CreatePaymentRepository }) : super(PaymentInitial()) {
    on<CreatePaymentEvent>(_onCreatePayment);
  }

  Future<void> _onCreatePayment(
      CreatePaymentEvent event,
      Emitter<PaymentState> emit,
      ) async {
    emit(PaymentLoading());
    try {
      final response = await repository.createPayment(
        token: event.token,
        request: event.request,
      );
      emit(PaymentSuccess(response));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }
}
