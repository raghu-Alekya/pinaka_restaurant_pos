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
    on<SetExistingKots>(_onSetExistingKots);
    on<PrepareNewKot>(_onPrepareNewKot);
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
  void _onLoadKots(LoadKots event, Emitter<KotState> emit) {
    currentParentOrderId = event.parentOrderId;
    emit(KotLoaded(event.kots));
  }
  void _onSetExistingKots(SetExistingKots event, Emitter<KotState> emit) {
    currentParentOrderId = event.kots.isNotEmpty ? event.kots.first.parentOrderId : 0;
    emit(KotLoaded(event.kots));
  }

  // / Handler implementation
  void _onPrepareNewKot(PrepareNewKot event, Emitter<KotState> emit) {
    if (state is KotLoaded) {
      final currentState = state as KotLoaded;

      // Create a new empty KOT
      final newKot = KotModel(
        kotId: 0, // 0 or backend-generated when printing
        parentOrderId: event.parentOrderId,
        items: [],
        status: 'new',
        kotNumber: '',
        time: DateTime.now(), // assign current time
        captainId: 0,
      );

      final updatedList = List<KotModel>.from(currentState.kots)..add(newKot);

      // Update state
      emit(KotLoaded(updatedList));
    }
  }


}

