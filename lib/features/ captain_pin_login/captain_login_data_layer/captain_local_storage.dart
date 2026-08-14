import '../captain_login_domain/captain_login_entity.dart';

abstract class CaptainLocalStorage {
  Future<void> saveCaptainData(CaptainLoginEntity entity);
  Future<CaptainLoginEntity?> getCaptainData();
  Future<void> clearCaptainData();
  Future<String?> getToken(); // <-- NEW
  Future<String?> getCurrencySymbol(); // new

}