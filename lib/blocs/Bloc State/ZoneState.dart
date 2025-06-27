abstract class ZoneState {}

class ZoneInitial extends ZoneState {}

class ZoneLoading extends ZoneState {}

class ZoneSuccess extends ZoneState {
  final String areaName;
  ZoneSuccess(this.areaName);
}

class ZoneFailure extends ZoneState {
  final String message;
  ZoneFailure(this.message);
}
class ZoneDeleteSuccess extends ZoneState {
  final String areaName;

  ZoneDeleteSuccess(this.areaName);
}

class ZoneDeleteFailure extends ZoneState {
  final String error;

  ZoneDeleteFailure(this.error);
}




