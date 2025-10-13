import 'package:equatable/equatable.dart';

abstract class ModifierEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchModifiersByProductId extends ModifierEvent {
  final int productId;

  FetchModifiersByProductId(this.productId);

  @override
  List<Object?> get props => [productId];
}
