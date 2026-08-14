
import 'captain_login_entity.dart';

abstract class CaptainLoginRepository {
  Future<CaptainLoginEntity> login({required String pin});
}