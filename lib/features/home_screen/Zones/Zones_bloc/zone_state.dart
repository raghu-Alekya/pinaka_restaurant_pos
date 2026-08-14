import 'package:equatable/equatable.dart';

import '../zones_domain/zone_entity.dart';

abstract class ZoneState extends Equatable {
  const ZoneState();

  @override
  List<Object> get props => [];
}

class ZoneInitial extends ZoneState {}

class ZoneLoading extends ZoneState {}

class ZoneLoaded extends ZoneState {
  final List<ZoneEntity> zones;

  const ZoneLoaded({required this.zones});

  @override
  List<Object> get props => [zones];
}

class ZoneError extends ZoneState {
  final String message;

  const ZoneError({required this.message});

  @override
  List<Object> get props => [message];
}