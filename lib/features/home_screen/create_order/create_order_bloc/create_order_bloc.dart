import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../create_order_domain/create_order_usecase.dart';
import 'create_order_event.dart';
import 'create_order_state.dart';

class CreateOrderBloc extends Bloc<CreateOrderEvent, CreateOrderState> {
  final CreateOrderUseCase useCase;

  CreateOrderBloc({required this.useCase}) : super(CreateOrderInitial()) {
    on<CreateOrder>(_onCreateOrder);
  }

  Future<void> _onCreateOrder(
      CreateOrder event,
      Emitter<CreateOrderState> emit,
      ) async {
    emit(CreateOrderLoading());
    try {
      final response = await useCase(event.request);
      emit(CreateOrderSuccess(response: response));
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      emit(CreateOrderError(message: errorMsg));
    }
  }
}