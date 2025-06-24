import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/zone_repository.dart';
abstract class ZoneState {}

class ZoneInitial extends ZoneState {}

class ZoneLoading extends ZoneState {}

class ZoneSuccess extends ZoneState {
  final String areaName;
  ZoneSuccess(this.areaName);
}

class ZoneFailure extends ZoneState {
  final String message;
  ZoneFailure(this.message);
}
abstract class ZoneEvent {}

class CreateZoneEvent extends ZoneEvent {
  final String token;
  final String pin;
  final String areaName;
  final Set<String> usedAreaNames;

  CreateZoneEvent({
    required this.token,
    required this.pin,
    required this.areaName,
    required this.usedAreaNames,
  });
}

/// ================= Zone Bloc =================
class ZoneBloc extends Bloc<ZoneEvent, ZoneState> {
  final ZoneRepository zoneRepository;

  ZoneBloc(this.zoneRepository) : super(ZoneInitial()) {
    on<CreateZoneEvent>((event, emit) async {
      if (event.areaName.trim().isEmpty) {
        emit(ZoneFailure('Area name cannot be empty.'));
        return;
      }

      final isAlreadyUsed = event.usedAreaNames
          .map((e) => e.toLowerCase())
          .contains(event.areaName.trim().toLowerCase());

      if (isAlreadyUsed) {
        emit(ZoneFailure('This Area/Zone name already exists.'));
        return;
      }

      emit(ZoneLoading());

      try {
        final result = await zoneRepository.createZone(
          token: event.token,
          pin: event.pin,
          areaName: event.areaName.trim(),
        );

        if (result['success'] == true) {
          emit(ZoneSuccess(event.areaName.trim()));
        } else {
          emit(ZoneFailure(result['message'] ?? 'Failed to create area on server.'));
        }
      } catch (e) {
        emit(ZoneFailure('Network error: $e'));
      }
    });

  }

}