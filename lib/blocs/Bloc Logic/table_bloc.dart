import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Manager flow/widgets/table_helpers.dart';
import '../../local database/table_dao.dart';
import '../../repositories/table_repository.dart';
import '../../repositories/zone_repository.dart';
import '../Bloc Event/TableEvent.dart';
import '../Bloc State/table_state.dart';

class TableBloc extends Bloc<TableEvent, TableState> {
  final ZoneRepository zoneRepository;
  final TableRepository tableRepository;
  final tableDao = TableDao();

  TableBloc({
    required this.zoneRepository,
    required this.tableRepository,
  }) : super(TableInitial()) {
    on<AddTableEvent>((event, emit) async {
      try {
        emit(TableAddingState());

        final data = event.tableData;
        final position = event.position;

        final tableSize = TableHelpers.getPlacedTableSize(data['capacity'], data['shape']);
        final clampedPos = TableHelpers.clampPositionToCanvas(position, tableSize);
        final adjustedPos = TableHelpers.findNonOverlappingPosition(
          clampedPos,
          tableSize,
          isOverlapping: (Offset pos, Size size) => false,
        );

        final zoneDetails = await zoneRepository.getZoneDetailsFromServerByAreaName(
          data['areaName'],
          event.token,
        );

        if (zoneDetails == null) {
          emit(TableAddErrorState("Zone not found for area ${data['areaName']}"));
          return;
        }

        final int zoneId = int.tryParse(zoneDetails['zone_id'].toString()) ?? 0;
        final int restaurantId = int.tryParse(zoneDetails['restaurant_id'].toString()) ?? 0;
        final double rotation = (data['rotation'] is num)
            ? data['rotation'].toDouble()
            : double.tryParse(data['rotation']?.toString() ?? '0.0') ?? 0.0;

        final requestBody = {
          "table_name": data['tableName'],
          "restaurant_id": restaurantId,
          "table_capacity": data['capacity'],
          "table_shape": data['shape'],
          "zone_id": zoneId,
          "table_pos_x": adjustedPos.dx.round(),
          "table_pos_y": adjustedPos.dy.round(),
          "table_rotation": rotation,
        };

        await tableRepository.createTable(token: event.token, requestBody: requestBody);

        final tableData = {
          'tableName': data['tableName'],
          'capacity': data['capacity'],
          'shape': data['shape'],
          'areaName': data['areaName'],
          'posX': adjustedPos.dx,
          'posY': adjustedPos.dy,
          'guestCount': data['guestCount'] ?? 0,
          'rotation': rotation,
          'pin': event.pin,
        };

        final id = await tableDao.insertTable(tableData);
        emit(TableAddedState({...tableData, 'id': id, 'position': adjustedPos}));
      } catch (e) {
        emit(TableAddErrorState("Exception: $e"));
      }
    });
  }
}
