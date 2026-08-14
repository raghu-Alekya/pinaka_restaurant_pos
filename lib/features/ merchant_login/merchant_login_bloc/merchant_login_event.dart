import 'package:equatable/equatable.dart';

abstract class MerchantLoginEvent extends Equatable {
  const MerchantLoginEvent();

  @override
  List<Object> get props => [];
}

class LoginButtonPressed extends MerchantLoginEvent {
  final String username;
  final String password;
  final String storeId;
  final String deviceId;
  final String shift;

  const LoginButtonPressed({
    required this.username,
    required this.password,
    required this.storeId,
    required this.deviceId,
    this.shift = '',
  });

  @override
  List<Object> get props => [username, password, storeId, deviceId, shift];
}