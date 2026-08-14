import 'package:equatable/equatable.dart';

abstract class CaptainLoginEvent extends Equatable {
  const CaptainLoginEvent();

  @override
  List<Object> get props => [];
}

class CaptainLoginButtonPressed extends CaptainLoginEvent {
  final String pin;

  const CaptainLoginButtonPressed({required this.pin});

  @override
  List<Object> get props => [pin];
}