import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../App flow/widgets/table_helpers.dart';
import '../../local database/table_dao.dart';
import '../../repositories/table_repository.dart';
import '../../repositories/zone_repository.dart';
import '../../utils/logger.dart';
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
        final createdTableResponse =
        await tableRepository.createTable(token: event.token, requestBody: requestBody);

        final int? tableIdFromServer = createdTableResponse?['table_id'] ?? createdTableResponse?['id'];
        if (tableIdFromServer == null) {
          emit(TableAddErrorState("Table created but missing table_id in response"));
          return;
        }

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
          'table_id': tableIdFromServer,
          'zone_id': zoneId,
          'restaurant_id': restaurantId,
        };

        final id = await tableDao.insertTable(tableData);
        emit(TableAddedState({...tableData, 'id': id, 'position': adjustedPos}));
      } catch (e) {
        emit(TableAddErrorState("Exception: $e"));
      }
    });

    on<LoadTablesEvent>((event, emit) async {
      emit(TableLoadingState());

      try {
        AppLogger.info('Fetching zones from server...');
        final zones = await zoneRepository.getAllZones(event.token);
        final zoneIdToName = {
          for (var zone in zones)
            zone['zone_id'].toString(): zone['zone_name'].toString(),
        };

        AppLogger.info('Fetching tables from API...');
        final tablesRaw = await tableRepository.getAllTables(event.token);
        final List<Map<String, dynamic>> tables = tablesRaw.map((table) {
          final zoneId = table['zone_id'].toString();
          if (!zoneIdToName.containsKey(zoneId)) return null;

          final zoneName = zoneIdToName[zoneId]!;

          return {
            ...table,
            'tableName': table['table_name'],
            'areaName': zoneName,
            'position': Offset(
              double.tryParse(table['pos_x'].toString()) ?? 0.0,
              double.tryParse(table['pos_y'].toString()) ?? 0.0,
            ),
            'rotation': double.tryParse(table['rotation']?.toString() ?? '0') ?? 0.0,
            'capacity': int.tryParse(table['capacity'].toString()) ?? 0,
            'shape': table['shape'],
          };
        }).whereType<Map<String, dynamic>>().toList();

        final usedTableNames = tables.map((t) => t['tableName'].toString().toLowerCase()).toSet();
        final usedAreaNames = tables.map((t) => t['areaName'].toString().toLowerCase()).toSet();

        emit(TableLoadedState(
          tables: tables,
          usedTableNames: usedTableNames,
          usedAreaNames: usedAreaNames,
        ));
      } catch (e) {
        AppLogger.error("Error loading tables: $e");
        emit(TableLoadErrorState(e.toString()));
      }
    });

    on<DeleteTableEvent>((event, emit) async {
      emit(TableDeletingState());

      final table = event.table;
      final tableName = table['tableName'];
      final areaName = table['areaName'];
      final tableId = int.tryParse(table['table_id']?.toString() ?? '');

      try {
        if (tableId != null) {
          final localTable = await tableDao.getTableByServerId(tableId);

          int? zoneId;
          int? restaurantId;

          if (localTable != null) {
            zoneId = int.tryParse(localTable['zone_id']?.toString() ?? '');
            restaurantId = int.tryParse(localTable['restaurant_id']?.toString() ?? '');
          } else {
            final zoneDetails = await zoneRepository.getZoneDetailsFromServerByAreaName(
              areaName,
              event.token,
            );

            if (zoneDetails != null && zoneDetails['success'] == true) {
              zoneId = int.tryParse(zoneDetails['zone_id'].toString());
              restaurantId = int.tryParse(zoneDetails['restaurant_id'].toString());
            }
          }

          if (zoneId != null && restaurantId != null) {
            final success = await tableRepository.deleteTableFromServer(
              tableId: tableId,
              zoneId: zoneId,
              restaurantId: restaurantId,
              token: event.token,
            );

            if (success) {
              await tableDao.deleteTableByServerId(tableId);
              emit(TableDeletedState(tableName));
            } else {
              emit(TableDeleteErrorState('Server deletion failed'));
            }
          } else {
            emit(TableDeleteErrorState('Zone or Restaurant ID not found'));
          }
        } else {
          await tableDao.deleteTableByNameAndArea(tableName, areaName);
          emit(TableDeletedState(tableName));
        }
      } catch (e) {
        AppLogger.error('Exception during delete: $e');
        emit(TableDeleteErrorState('Exception: $e'));
      }
    });
  }
}
