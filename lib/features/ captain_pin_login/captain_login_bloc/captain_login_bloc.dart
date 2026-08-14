import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../captain_login_domain/captain_login_usecase.dart';
import 'captain_login_event.dart';
import 'captain_login_state.dart';

class CaptainLoginBloc extends Bloc<CaptainLoginEvent, CaptainLoginState> {
  final CaptainLoginUseCase loginUseCase;

  CaptainLoginBloc({required this.loginUseCase})
      : super(CaptainLoginInitial()) {
    on<CaptainLoginButtonPressed>(_onLoginButtonPressed);
  }

  Future<void> _onLoginButtonPressed(
      CaptainLoginButtonPressed event,
      Emitter<CaptainLoginState> emit,
      ) async {
    emit(CaptainLoginLoading());

    try {
      final entity = await loginUseCase(pin: event.pin);

      if (entity.success) {
        emit(CaptainLoginSuccess(entity: entity));
      } else {
        emit(CaptainLoginFailure(
            error: entity.message ?? 'Login failed'));
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      emit(CaptainLoginFailure(error: errorMsg));
    }
  }
}