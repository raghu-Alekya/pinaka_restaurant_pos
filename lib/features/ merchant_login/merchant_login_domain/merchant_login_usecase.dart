
import 'merchant_login_entity.dart';
import 'merchant_login_repository.dart';

class MerchantLoginUseCase {
  final MerchantLoginRepository repository;

  MerchantLoginUseCase({required this.repository});

  Future<MerchantLoginEntity> call({
    required String username,
    required String password,
    required String storeId,
    required String deviceId,
    String shift = '',
  }) async {
    return await repository.login(
      username: username,
      password: password,
      storeId: storeId,
      deviceId: deviceId,
      shift: shift,
    );
  }
}