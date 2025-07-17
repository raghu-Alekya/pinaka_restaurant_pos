abstract class CheckInEvent {}

class SubmitPinEvent extends CheckInEvent {
  final String pin;
  final String token;

  SubmitPinEvent({required this.pin, required this.token});
}
