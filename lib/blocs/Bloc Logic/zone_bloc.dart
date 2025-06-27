import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../Manager flow/widgets/table_helpers.dart';
import '../../local database/area_dao.dart';
import '../../local database/login_dao.dart';
import '../../local database/table_dao.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/logger.dart';
import '../Bloc Event/TableEvent.dart';
import '../Bloc Event/ZoneEvent.dart';
import '../Bloc State/ZoneState.dart';

/// ================= Zone Bloc =================
class ZoneBloc extends Bloc<ZoneEvent, ZoneState> {
  final ZoneRepository zoneRepository;
  final areaDao = AreaDao();
  final tableDao = TableDao();
  final loginDao = LoginDao();

  ZoneBloc({required this.zoneRepository}) : super(ZoneInitial()) {
    /// Handle Create Zone
    on<CreateZoneEvent>((event, emit) async {
      if (event.areaName
          .trim()
          .isEmpty) {
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
          restaurantId: event.restaurantId,
        );

        if (result['success'] == true) {
          emit(ZoneSuccess(event.areaName.trim()));
        } else {
          emit(ZoneFailure(
              result['message'] ?? 'Failed to create area on server.'));
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
      // ✅ Get full zone details
      final zoneDetails = await zoneRepository.getZoneDetailsFromServerByAreaName(event.areaName, event.token);
      final zoneId = zoneDetails?['zone_id'];

      if (zoneId == null) {
        emit(ZoneDeleteFailure('Zone ID not found for ${event.areaName}'));
        return;
      }

      final success = await zoneRepository.deleteZone(token: event.token, zoneId: zoneId);
      if (success) {
        await areaDao.deleteArea(event.areaName);
        await tableDao.deleteTablesByArea(event.areaName);

        emit(ZoneDeleteSuccess(event.areaName));
      } else {
        emit(ZoneDeleteFailure('Failed to delete zone from server'));
      }
    } catch (e) {
      emit(ZoneDeleteFailure('Exception during deletion: $e'));
    }
  }


}
