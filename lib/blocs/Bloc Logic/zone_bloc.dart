import 'package:flutter_bloc/flutter_bloc.dart';
import '../../helpers/DatabaseHelper.dart';
import '../../repositories/zone_repository.dart';
import '../Bloc Event/ZoneEvent.dart';
import '../Bloc State/ZoneState.dart';

/// ================= Zone Bloc =================
class ZoneBloc extends Bloc<ZoneEvent, ZoneState> {
  final ZoneRepository zoneRepository;

  ZoneBloc({required this.zoneRepository}) : super(ZoneInitial()) {
    /// Handle Create Zone
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

    /// Handle Delete Area
    on<DeleteAreaEvent>(_onDeleteArea);
  }

  Future<void> _onDeleteArea(DeleteAreaEvent event, Emitter<ZoneState> emit) async {
    try {
      final zoneId = await zoneRepository.getZoneIdFromServerByAreaName(event.areaName, event.token);
      if (zoneId == null) {
        emit(ZoneDeleteFailure('Zone ID not found for ${event.areaName}'));
        return;
      }

      final success = await zoneRepository.deleteZone(token: event.token, zoneId: zoneId);
      if (success) {
        // 🔽 Local cleanup
        final dbHelper = DatabaseHelper();
        await dbHelper.deleteArea(event.areaName);
        await dbHelper.deleteTablesByArea(event.areaName);

        emit(ZoneDeleteSuccess(event.areaName));
      } else {
        emit(ZoneDeleteFailure('Failed to delete zone from server'));
      }
    } catch (e) {
      emit(ZoneDeleteFailure('Exception during deletion: $e'));
    }
  }

}
