import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/order/transfer_table_model.dart';
import '../../repositories/kot_repository.dart';
import '../Bloc Event/transfer_kot_event.dart';
import '../Bloc State/transfer_kot_state.dart';
// import 'transfer_kot_event.dart';
// import 'transfer_kot_state.dart';
// import '../repositories/kot_repository.dart';
// import '../models/kot_transfer_model.dart';

class TransferKotBloc extends Bloc<TransKotEvent, TransferKotState> {
  final KotTransferRepository repository;

  TransferKotBloc({required this.repository})
      : super(TransferKotInitial()) {
    on<TransferKotEvent>(_onTransferKot);
  }

  Future<void> _onTransferKot(
      TransferKotEvent event,
      Emitter<TransferKotState> emit,
      ) async {
    emit(KotTransferLoading());

    try {
      final KotTransferResponse response =
      await repository.transferKot(
        orderId: event.orderId,
        kotId: event.kotId,
        fromTableId: event.fromTableId,
        toTableId: event.toTableId,
        restaurantId: event.restaurantId,
        zoneId: event.zoneId,
        token: event.token,
      );

      if (response.success) {
        emit(
          KotTransferSuccess(
            message: response.message,
            newParentId: response.newParentId,
            toTableId: response.toTableId,
          ),
        );
      } else {
        emit(
          KotTransferFailure(
            response.message.isNotEmpty
                ? response.message
                : "KOT transfer failed",
          ),
        );
      }
    } catch (e) {
      emit(
        KotTransferFailure(
          e.toString().replaceAll('Exception:', '').trim(),
        ),
      );
    }
  }
}
