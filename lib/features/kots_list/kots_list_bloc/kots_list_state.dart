// kots_list_state.dart
import 'package:equatable/equatable.dart';
import '../../home_screen/All_tables_list/All_tables_list_data_layer/order_by_table_model.dart';

abstract class KotsListState extends Equatable {
  const KotsListState();
  @override
  List<Object> get props => [];
}

class KotsListInitial extends KotsListState {}

class KotsListLoading extends KotsListState {}

class KotsListLoaded extends KotsListState {
  final List<KotOrder> kots;
  final int parentOrderId;   // 👈 NEW: identifies which order this data is for

  const KotsListLoaded({
    required this.kots,
    required this.parentOrderId,
  });

  @override
  List<Object> get props => [kots, parentOrderId];
}

class KotsListError extends KotsListState {
  final String message;
  const KotsListError({required this.message});
  @override
  List<Object> get props => [message];
}