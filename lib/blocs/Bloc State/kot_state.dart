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
  final bool isExpanded; // ✅ new property to track dropdown state

  KotLoaded(
      this.kots, {
        this.isExpanded = false, // default collapsed
      });

  KotLoaded copyWith({
    List<KotModel>? kots,
    bool? isExpanded,
  }) {
    return KotLoaded(
      kots ?? this.kots,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  List<Object?> get props => [kots, isExpanded];
}


class KotError extends KotState {
  final String message;
  KotError(this.message);

  @override
  List<Object?> get props => [message];
}
