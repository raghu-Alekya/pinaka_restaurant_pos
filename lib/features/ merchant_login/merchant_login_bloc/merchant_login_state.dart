import 'package:equatable/equatable.dart';
import '../merchant_login_domain/merchant_login_entity.dart';

abstract class MerchantLoginState extends Equatable {
  const MerchantLoginState();

  @override
  List<Object> get props => [];
}

class MerchantLoginInitial extends MerchantLoginState {}

class MerchantLoginLoading extends MerchantLoginState {}

class MerchantLoginSuccess extends MerchantLoginState {
  final MerchantLoginEntity entity;

  const MerchantLoginSuccess({required this.entity});

  @override
  List<Object> get props => [entity];
}

class MerchantLoginFailure extends MerchantLoginState {
  final String error;

  const MerchantLoginFailure({required this.error});

  @override
  List<Object> get props => [error];
}