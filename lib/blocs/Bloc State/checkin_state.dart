import '../../models/UserPermissions.dart';

abstract class CheckInState {}

class CheckInInitial extends CheckInState {}

class CheckInLoading extends CheckInState {}

class CheckInSuccess extends CheckInState {
  final UserPermissions permissions;
  final Map<String, dynamic> fullResponse;

  CheckInSuccess({
    required this.permissions,
    required this.fullResponse,
  });
}


class CheckInFailure extends CheckInState {
  final String message;

  CheckInFailure(this.message);
}
