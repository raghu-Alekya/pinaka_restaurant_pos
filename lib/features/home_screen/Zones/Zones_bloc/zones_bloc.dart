import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../zones_domain/zone_usecase.dart';
import 'zone_event.dart';
import 'zone_state.dart';

class ZoneBloc extends Bloc<ZoneEvent, ZoneState> {
  final ZoneUseCase useCase;

  ZoneBloc({required this.useCase}) : super(ZoneInitial()) {
    on<FetchZones>(_onFetchZones);
  }

  Future<void> _onFetchZones(FetchZones event, Emitter<ZoneState> emit) async {
    emit(ZoneLoading());
    try {
      final zones = await useCase();
      emit(ZoneLoaded(zones: zones));
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      emit(ZoneError(message: errorMsg));
    }
  }
}