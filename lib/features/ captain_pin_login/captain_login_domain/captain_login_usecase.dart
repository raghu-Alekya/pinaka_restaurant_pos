


import 'captain_login_entity.dart';
import 'captain_login_repository.dart';

class CaptainLoginUseCase {
  final CaptainLoginRepository repository;

  CaptainLoginUseCase({required this.repository});

  Future<CaptainLoginEntity> call({required String pin}) async {
    return await repository.login(pin: pin);
  }
}