import 'package:restaurant_captain_app/features/home_screen/Zones/zones_data_layer/zone_remote_data_source.dart';

import '../../../ captain_pin_login/captain_login_data_layer/captain_local_storage.dart';
import '../../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../zones_domain/zone_entity.dart';
import '../zones_domain/zone_repository.dart';

class ZoneRepositoryImpl implements ZoneRepository {
  final ZoneRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantStorage;
  final CaptainLocalStorage captainStorage;

  ZoneRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantStorage,
    required this.captainStorage,
  });

  @override
  Future<List<ZoneEntity>> getZones() async {
    // Retrieve stored base URL
    final baseUrl = await merchantStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found. Please login as merchant first.');
    }

    // Retrieve stored token from captain login
    final captainData = await captainStorage.getCaptainData();
    if (captainData?.data?.token == null) {
      throw Exception('Captain token not found. Please login as captain first.');
    }
    final token = captainData!.data!.token!;

    final response = await remoteDataSource.getZones(
      baseUrl: baseUrl,
      token: token,
    );

    return response.toEntityList();
  }
}