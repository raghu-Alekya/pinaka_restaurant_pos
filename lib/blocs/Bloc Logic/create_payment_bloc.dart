import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/create_payment_repository.dart';
import '../Bloc Event/create_payment_event.dart';
import '../Bloc State/create_payment_state.dart';

class CreatePaymentBloc
    extends Bloc<CreatePaymentEvent, CreatePaymentState> {

  final CreatePaymentRepository repository;

  CreatePaymentBloc(this.repository)
      : super(CreatePaymentInitial()) {

    on<CreatePaymentRequested>(_onCreatePayment);
  }

  Future<void> _onCreatePayment(
      CreatePaymentRequested event,
      Emitter<CreatePaymentState> emit,
      ) async {
    emit(CreatePaymentLoading());

    try {
      final response = await repository.createPayment(
        token: event.token,
        request: event.request,
      );

      emit(CreatePaymentSuccess(response));
    } catch (e) {
      emit(CreatePaymentFailure(e.toString()));
    }
  }
}
