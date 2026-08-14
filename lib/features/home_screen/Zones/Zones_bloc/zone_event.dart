import 'package:equatable/equatable.dart';

abstract class ZoneEvent extends Equatable {
  const ZoneEvent();

  @override
  List<Object> get props => [];
}

class FetchZones extends ZoneEvent {}