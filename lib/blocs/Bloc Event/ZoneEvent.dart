abstract class ZoneEvent {}

class CreateZoneEvent extends ZoneEvent {
  final String token;
  final String pin;
  final String areaName;
  final Set<String> usedAreaNames;

  CreateZoneEvent({
    required this.token,
    required this.pin,
    required this.areaName,
    required this.usedAreaNames,
  });
}
class DeleteAreaEvent extends ZoneEvent {
  final String areaName;
  final String token;

  DeleteAreaEvent({required this.areaName, required this.token});
}

