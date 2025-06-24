// lib/blocs/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';

abstract class AuthEvent {}
class LoginEvent extends AuthEvent {
  final String pin;
  LoginEvent(this.pin);
}

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final String pin;
  final String token;
  AuthSuccess({required this.pin, required this.token});
}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    on<LoginEvent>((event, emit) async {
      if (event.pin.length != 6 || int.tryParse(event.pin) == null) {
        emit(AuthFailure('PIN must be exactly 6 digits.'));
        return;
      }

      emit(AuthLoading());

      try {
        final result = await authRepository.login(event.pin);
        if (result['success']) {
          emit(AuthSuccess(pin: event.pin, token: result['token']));
        } else {
          emit(AuthFailure(result['message']));
        }
      } catch (e) {
        emit(AuthFailure('Network error: $e'));
      }
    });
  }
}
