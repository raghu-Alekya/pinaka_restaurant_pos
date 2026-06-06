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

  Future<void> _onSubmitPin(SubmitPinEvent event, Emitter<CheckInState> emit) async {
    emit(CheckInLoading());

    try {
      final data = await _repository.validatePin(
        pin: event.pin,
        token: event.token,
      );

      AppLogger.debug('KOT PIN Validation Response: $data');

      if (data['success'] == true && data['data'] != null) {
        final permissionsJson = Map<String, dynamic>.from(
          data['data']['permissions'],
        );

// Add role and avatar from parent data
        permissionsJson['role'] = data['data']['role'];
        permissionsJson['avatar'] = data['data']['avatar'];
        permissionsJson['displayName'] = data['data']['displayName'];
        permissionsJson['user_id'] = data['data']['id'].toString();

        final permissions = UserPermissions.fromJson(
          permissionsJson,
        );
        emit(CheckInSuccess(
          permissions: permissions,
          fullResponse: data,
        ));

      }
      else {
        AppLogger.debug('Login Failed with message: ${data['message'] ?? 'Unknown error'}');
        emit(CheckInFailure(data['message'] ?? 'Invalid PIN'));
      }
    } catch (e) {
      AppLogger.debug('Login Exception: $e');
      emit(CheckInFailure('Error: $e'));
    }
  }
}
