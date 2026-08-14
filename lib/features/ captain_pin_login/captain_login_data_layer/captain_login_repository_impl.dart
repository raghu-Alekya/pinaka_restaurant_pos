import '../../ merchant_login/merchant_login_data_layer/merchant_local_storage.dart';
import '../captain_login_domain/captain_login_entity.dart';
import '../captain_login_domain/captain_login_repository.dart';
import 'captain_local_storage.dart';
import 'captain_login_remote_data_source.dart';

class CaptainLoginRepositoryImpl implements CaptainLoginRepository {
  final CaptainLoginRemoteDataSource remoteDataSource;
  final MerchantLocalStorage merchantLocalStorage;
  final CaptainLocalStorage captainLocalStorage;

  CaptainLoginRepositoryImpl({
    required this.remoteDataSource,
    required this.merchantLocalStorage,
    required this.captainLocalStorage,
  });

  @override
  Future<CaptainLoginEntity> login({required String pin}) async {
    // Get stored base URL from merchant login
    final baseUrl = await merchantLocalStorage.getStoreBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Store base URL not found. Please login as merchant first.');
    }

    final response = await remoteDataSource.login(
      pin: pin,
      baseUrl: baseUrl,
    );
    final entity = response.toEntity();
    if (entity.success) {
      await captainLocalStorage.saveCaptainData(entity);
    }
    return entity;
  }
}