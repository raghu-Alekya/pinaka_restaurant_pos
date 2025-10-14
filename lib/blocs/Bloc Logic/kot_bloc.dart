import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/kot_repository.dart';
import '../Bloc Event/kot_event.dart';
import '../Bloc State/kot_state.dart';
import '../../models/order/KOT_model.dart';

class KotBloc extends Bloc<KotEvent, KotState> {
  final KotRepository repository;
  int currentParentOrderId = 0;

  KotBloc(this.repository) : super(KotInitial()) {
    // Fetch KOTs from API
    on<FetchKots>(_onFetchKots);

    // Add a KOT to the current list
    on<AddKotToList>(_onAddKotToList);

    // Set existing KOTs (e.g., when loading table)
    on<SetExistingKots>(_onSetExistingKots);

    // Load KOTs directly
    on<LoadKots>(_onLoadKots);

    // Collapse the KOT dropdown
    on<CollapseKOT>((event, emit) {
      if (state is KotLoaded) {
        final current = state as KotLoaded;
        emit(current.copyWith(isExpanded: false));
      }
    });

    // Toggle KOT dropdown manually
    on<ToggleKOTDropdown>((event, emit) {
      if (state is KotLoaded) {
        final current = state as KotLoaded;
        emit(current.copyWith(isExpanded: !current.isExpanded));
      }
    });
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
    if (state is KotLoaded && event.kot.parentOrderId == currentParentOrderId) {
      final current = state as KotLoaded;
      final updatedList = List<KotModel>.from(current.kots)..add(event.kot);

      // Keep current dropdown state
      emit(current.copyWith(kots: updatedList));
    }
  }

  void _onLoadKots(LoadKots event, Emitter<KotState> emit) {
    currentParentOrderId = event.parentOrderId;
    emit(KotLoaded(event.kots));
  }

  void _onSetExistingKots(SetExistingKots event, Emitter<KotState> emit) {
    currentParentOrderId =
    event.kots.isNotEmpty ? event.kots.first.parentOrderId : 0;
    emit(KotLoaded(event.kots));
  }
}
