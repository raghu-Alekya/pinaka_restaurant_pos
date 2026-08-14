
import 'merchant_login_entity.dart';

abstract class MerchantLoginRepository {
  Future<MerchantLoginEntity> login({
    required String username,
    required String password,
    required String storeId,
    required String deviceId,
    String shift = '',
  });
}