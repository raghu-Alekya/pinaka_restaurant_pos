// lib/bloc/checkin_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/UserPermissions.dart';
import '../../repositories/checkin_repository.dart';
import '../../utils/logger.dart';
import '../Bloc Event/checkin_event.dart';
import '../Bloc State/checkin_state.dart';

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  final CheckInRepository _repository;

  CheckInBloc(this._repository) : super(CheckInInitial()) {
    on<SubmitPinEvent>(_onSubmitPin);
  }

  Future<void> _onSubmitPin(
      SubmitPinEvent event, Emitter<CheckInState> emit) async {
    emit(CheckInLoading());

    try {
      final data = await _repository.validatePin(
        pin: event.pin,
        token: event.token,
      );

      AppLogger.debug('KOT PIN Validation Parsed Response: $data');

      if (data['captainId'] != null && data['captainId'] != 0) {
        // ⚡ No need for 'permissions' unless your API still returns them separately
        final permissions = UserPermissions.fromJson(data['permissions'] ?? {});

        emit(CheckInSuccess(
          permissions: permissions,
          fullResponse: data,
          captainId: data['captainId'],
        ));
      } else {
        emit(CheckInFailure('Invalid PIN or missing captainId'));
      }
    } catch (e) {
      AppLogger.debug('Login Exception: $e');
      emit(CheckInFailure('Error: $e'));
    }
  }


}
