import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/discount_repository.dart';
import '../Bloc Event/discount_event.dart';
import '../Bloc State/discount_stata.dart';
class DiscountReasonBloc
    extends Bloc<DiscountReasonEvent, DiscountReasonState> {

  final DiscountReasonRepository repository;

  DiscountReasonBloc(this.repository)
      : super(DiscountReasonInitial()) {

    on<LoadDiscountReasons>((event, emit) async {
      print('🚨 LoadDiscountReasons EVENT RECEIVED');

      emit(DiscountReasonLoading());

      try {
        final response =
        await repository.fetchDiscountReasons();

        emit(DiscountReasonLoaded(response.reasons));
      } catch (e) {
        emit(DiscountReasonError(e.toString()));
      }
    });
  }
}
class DiscountBloc extends Bloc<DiscountEvent, DiscountState> {
  final AddDiscountRepository repository;

  DiscountBloc(this.repository) : super(DiscountInitial()) {
    on<ApplyDiscountEvent>(_onApplyDiscount);
  }

  Future<void> _onApplyDiscount(
      ApplyDiscountEvent event,
      Emitter<DiscountState> emit,
      ) async {
    emit(DiscountLoading());

    try {
      final response = await repository.addDiscount(
        // token: event.token,
        request: event.request,
      );
      final isNcApplied = event.request.isNc == "yes";

      emit(DiscountSuccess(response,isNcApplied: isNcApplied,));
    } catch (e) {
      emit(DiscountFailure(e.toString()));
    }
  }
}
class RemoveDiscountBloc
    extends Bloc<RemoveDiscountEvent, RemoveDiscountState> {
  final RemoveDiscountRepository repository;

  RemoveDiscountBloc(this.repository) : super(RemoveDiscountInitial()) {
    on<RemoveDiscountRequested>((event, emit) async {
      try {
        emit(RemoveDiscountLoading());

        final result = await repository.removeDiscount(
          // token: event.token,
          orderId: event.orderId,
          isNc: event.isNc,
        );

        emit(RemoveDiscountSuccess(result));
      } catch (e) {
        emit(RemoveDiscountFailure(e.toString()));
      }
    });
  }
}
