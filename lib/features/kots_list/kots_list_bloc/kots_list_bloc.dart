import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../kots_list_domin/kots_list_usecase.dart';
import 'kots_list_event.dart';
import 'kots_list_state.dart';

class KotsListBloc extends Bloc<KotsListEvent, KotsListState> {
  final KotsListUseCase useCase;

  KotsListBloc({required this.useCase}) : super(KotsListInitial()) {
    on<FetchKotsList>(_onFetchKotsList);
  }

  Future<void> _onFetchKotsList(
      FetchKotsList event,
      Emitter<KotsListState> emit,
      ) async {
    emit(KotsListLoading());
    try {
      final kots = await useCase(
        parentOrderId: event.parentOrderId,
        restaurantId: event.restaurantId,
        zoneId: event.zoneId,
      );
      emit(KotsListLoaded(kots: kots));
    } catch (e) {
      emit(KotsListError(message: e.toString()));
    }
  }
}