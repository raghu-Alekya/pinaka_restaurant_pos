
import '../merchant_login_domain/merchant_login_entity.dart';

abstract class MerchantLocalStorage {
  Future<void> saveMerchantData(MerchantLoginEntity entity);
  Future<MerchantLoginEntity?> getMerchantData();
  Future<void> clearMerchantData();
  Future<String?> getStoreBaseUrl();
}