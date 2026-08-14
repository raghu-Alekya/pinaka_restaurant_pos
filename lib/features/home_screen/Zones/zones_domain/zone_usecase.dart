

import 'package:restaurant_captain_app/features/home_screen/Zones/zones_domain/zone_entity.dart';
import 'package:restaurant_captain_app/features/home_screen/Zones/zones_domain/zone_repository.dart';

class ZoneUseCase {
  final ZoneRepository repository;

  ZoneUseCase({required this.repository});

  Future<List<ZoneEntity>> call() async {
    return await repository.getZones();
  }
}