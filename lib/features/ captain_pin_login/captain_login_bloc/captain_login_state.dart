import 'package:equatable/equatable.dart';

import '../captain_login_domain/captain_login_entity.dart';

abstract class CaptainLoginState extends Equatable {
  const CaptainLoginState();

  @override
  List<Object> get props => [];
}

class CaptainLoginInitial extends CaptainLoginState {}

class CaptainLoginLoading extends CaptainLoginState {}

class CaptainLoginSuccess extends CaptainLoginState {
  final CaptainLoginEntity entity;

  const CaptainLoginSuccess({required this.entity});

  @override
  List<Object> get props => [entity];
}

class CaptainLoginFailure extends CaptainLoginState {
  final String error;

  const CaptainLoginFailure({required this.error});

  @override
  List<Object> get props => [error];
}