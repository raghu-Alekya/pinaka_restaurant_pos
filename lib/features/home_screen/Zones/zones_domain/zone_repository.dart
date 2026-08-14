import 'package:restaurant_captain_app/features/home_screen/Zones/zones_domain/zone_entity.dart';

abstract class ZoneRepository {
  Future<List<ZoneEntity>> getZones();
}