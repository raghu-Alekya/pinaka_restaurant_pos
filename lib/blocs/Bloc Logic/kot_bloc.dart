import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/kot_repository.dart';
import '../Bloc Event/kot_event.dart';
import '../Bloc State/kot_state.dart';
import '../../models/order/KOT_model.dart';

class KotBloc extends Bloc<KotEvent, KotState> {
  final KotRepository repository;
  int currentParentOrderId = 0; // track current order

  KotBloc(this.repository) : super(KotInitial()) {
    on<FetchKots>(_onFetchKots);
    on<AddKotToList>(_onAddKotToList);
  }

  Future<void> _onFetchKots(FetchKots event, Emitter<KotState> emit) async {
    emit(KotLoading());
    try {
      currentParentOrderId = event.parentOrderId;
      final kots = await repository.fetchKots(
        parentOrderId: event.parentOrderId,
        restaurantId: event.restaurantId,
        zoneId: event.zoneId,
        token: event.token,
      );
      emit(KotLoaded(kots));
    } catch (e) {
      emit(KotError(e.toString()));
    }
  }

  void _onAddKotToList(AddKotToList event, Emitter<KotState> emit) {
    // Only add if it's for the current loaded order
    if (state is KotLoaded && event.kot.parentOrderId == currentParentOrderId) {
      final currentState = state as KotLoaded;
      final updatedList = List<KotModel>.from(currentState.kots)..add(event.kot);
      emit(KotLoaded(updatedList));
    }
  }
}
