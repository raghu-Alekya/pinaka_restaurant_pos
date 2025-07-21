import '../../models/UserPermissions.dart';

abstract class CheckInState {}

class CheckInInitial extends CheckInState {}

class CheckInLoading extends CheckInState {}

class CheckInSuccess extends CheckInState {
  final UserPermissions permissions;
  CheckInSuccess({required this.permissions});
}

class CheckInFailure extends CheckInState {
  final String message;

  CheckInFailure(this.message);
}
