import '../../models/UserPermissions.dart';

abstract class CheckInState {}

class CheckInInitial extends CheckInState {}

class CheckInLoading extends CheckInState {}

class CheckInSuccess extends CheckInState {
  final UserPermissions permissions;
  final Map<String, dynamic> fullResponse;
  final int captainId; // ✅ add captainId

  CheckInSuccess({
    required this.permissions,
    required this.fullResponse,
    required this.captainId,
  });
}




class CheckInFailure extends CheckInState {
  final String message;

  CheckInFailure(this.message);
}
