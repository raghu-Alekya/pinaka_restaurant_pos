import 'package:equatable/equatable.dart';

import '../../models/order/KOT_model.dart';
// import '../models/kot_model.dart';

abstract class KotState extends Equatable {
  @override
  List<Object?> get props => [];
}

class KotInitial extends KotState {}

class KotLoading extends KotState {}

class KotLoaded extends KotState {
  final List<KotModel> kots;
  KotLoaded(this.kots);

  @override
  List<Object?> get props => [kots];
}

class KotError extends KotState {
  final String message;
  KotError(this.message);

  @override
  List<Object?> get props => [message];
}
