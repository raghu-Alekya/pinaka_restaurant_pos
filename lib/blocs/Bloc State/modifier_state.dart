import 'package:equatable/equatable.dart';
import '../../models/order/modifier_model.dart';

abstract class ModifierState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ModifierInitial extends ModifierState {}

class ModifierLoading extends ModifierState {}

class ModifierLoaded extends ModifierState {
  final List<Modifier> modifiers;

  ModifierLoaded(this.modifiers);

  @override
  List<Object?> get props => [modifiers];
}

class ModifierError extends ModifierState {
  final String message;

  ModifierError(this.message);

  @override
  List<Object?> get props => [message];
}
