abstract class CheckInState {}

class CheckInInitial extends CheckInState {}

class CheckInLoading extends CheckInState {}

class CheckInSuccess extends CheckInState {}

class CheckInFailure extends CheckInState {
  final String message;

  CheckInFailure(this.message);
}
