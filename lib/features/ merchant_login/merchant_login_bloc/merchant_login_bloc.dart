import 'package:bloc/bloc.dart';

import '../merchant_login_domain/merchant_login_usecase.dart';
import 'merchant_login_event.dart';
import 'merchant_login_state.dart';


class MerchantLoginBloc extends Bloc<MerchantLoginEvent, MerchantLoginState> {
  final MerchantLoginUseCase loginUseCase;

  MerchantLoginBloc({required this.loginUseCase})
      : super(MerchantLoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  Future<void> _onLoginButtonPressed(
      LoginButtonPressed event,
      Emitter<MerchantLoginState> emit,
      ) async {
    emit(MerchantLoginLoading());

    try {
      final entity = await loginUseCase(
        username: event.username,
        password: event.password,
        storeId: event.storeId,
        deviceId: event.deviceId,
        shift: event.shift,
      );

      if (entity.success) {
        emit(MerchantLoginSuccess(entity: entity));
      } else {
        emit(MerchantLoginFailure(
            error: entity.message ?? 'Login failed'));
      }
    } catch (e) {
      // Clean the error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      emit(MerchantLoginFailure(error: errorMsg));
    }
  }
}