
import '../merchant_login_domain/merchant_login_entity.dart';
import '../merchant_login_domain/merchant_login_repository.dart';
import 'merchant_local_storage.dart';
import 'merchant_login_remote_data_source.dart';

class MerchantLoginRepositoryImpl implements MerchantLoginRepository {
  final MerchantLoginRemoteDataSource remoteDataSource;
  final MerchantLocalStorage localStorage;

  MerchantLoginRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorage,
  });

  @override
  Future<MerchantLoginEntity> login({
    required String username,
    required String password,
    required String storeId,
    required String deviceId,
    String shift = '',
  }) async {
    final response = await remoteDataSource.login(
      username: username,
      password: password,
      storeId: storeId,
      deviceId: deviceId,
      shift: shift,
    );
    final entity = response.toEntity();
    // Save data locally on success
    if (entity.success) {
      await localStorage.saveMerchantData(entity);
    }
    return entity;
  }
}