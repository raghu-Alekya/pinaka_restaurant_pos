import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/order/void_kot_items.dart';
import '../../repositories/void_item_repository.dart';
import '../Bloc Event/void_item_evnts.dart';
import '../Bloc State/void_item_state.dart';

class KotLineItemsBloc extends Bloc<KotLineItemsEvent, KotLineItemsState> {
  final VoidItemRepository repository;

  KotLineItemsBloc({required this.repository}) : super(KotLineItemsInitial()) {
    on<FetchKotLineItems>(_onFetchKotLineItems);
  }

  Future<void> _onFetchKotLineItems(
      FetchKotLineItems event,
      Emitter<KotLineItemsState> emit,
      ) async {
    try {
      emit(KotLineItemsLoading());

      final response = await repository.getKotLineItems(
        kotId: event.kotId,
        restaurantId: event.restaurantId,
        zoneId: event.zoneId,
        token: event.token,
      );

      emit(KotLineItemsLoaded(response));
    } catch (e) {
      emit(KotLineItemsError(e.toString()));
    }
  }
}
class UpdatekotBloc extends Bloc<UpdatekotEvent, UpdatekotState> {
  final UpdatekotRepository repository;

  UpdatekotBloc({required this.repository}) : super(UpdatekotInitial()) {
    on<UpdatekotPressed>(_onUpdatekotPressed);
  }

  Future<void> _onUpdatekotPressed(
      UpdatekotPressed event,
      Emitter<UpdatekotState> emit,
      ) async {
    try {
      emit(UpdatekotLoading());

      final res = await repository. updatekot(
        token: event.token,
        kotId: event.kotId,
        request: event.request,
      );

      emit(UpdatekotSuccess(res));
    } catch (e) {
      emit(UpdatekotFailure(e.toString()));
    }
  }
}