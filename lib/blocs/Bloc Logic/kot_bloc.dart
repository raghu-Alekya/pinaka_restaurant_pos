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

    on<UpdateKotStatus>(_onUpdateKotStatus);

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
    if (currentParentOrderId == 0 && event.kot.parentOrderId > 0) {
      currentParentOrderId = event.kot.parentOrderId;
    }
    if (state is KotLoaded) {
      final current = state as KotLoaded;
      final seen = <String>{};
      final updatedList = <KotModel>[];
      for (final k in [...current.kots, event.kot]) {
        final key = k.kotNumber ?? k.kotId?.toString() ?? '';
        if (key.isEmpty || seen.add(key)) {
          updatedList.add(k);
        }
      }
      emit(current.copyWith(kots: updatedList));
    } else {
      emit(KotLoaded([event.kot]));
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
  void _onUpdateKotStatus(
      UpdateKotStatus event,
      Emitter<KotState> emit,
      ) {
    if (state is! KotLoaded) return;

    final current = state as KotLoaded;

    final updatedKots = current.kots.map((kot) {
      if (kot.kotNumber == event.kotNumber) {
        return kot.copyWith(
          status: event.status,
        );
      }
      return kot;
    }).toList();

    emit(current.copyWith(kots: updatedKots));

    print(
      'KOT Status Updated => ${event.kotNumber} : ${event.status}',
    );
  }
}
