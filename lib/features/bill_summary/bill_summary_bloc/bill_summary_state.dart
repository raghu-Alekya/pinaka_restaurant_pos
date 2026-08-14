import 'package:equatable/equatable.dart';
import '../bill_summary_domain/bill_summary_entity.dart';

abstract class BillSummaryState extends Equatable {
  const BillSummaryState();

  @override
  List<Object> get props => [];
}

class BillSummaryInitial extends BillSummaryState {}

class BillSummaryLoading extends BillSummaryState {}

class BillSummaryLoaded extends BillSummaryState {
  final BillSummaryEntity data;

  const BillSummaryLoaded({required this.data});

  @override
  List<Object> get props => [data];
}

class BillSummaryError extends BillSummaryState {
  final String message;

  const BillSummaryError({required this.message});

  @override
  List<Object> get props => [message];
}

class BillGenerating extends BillSummaryState {}

class BillGenerated extends BillSummaryState {
  final String message;

  const BillGenerated({required this.message});

  @override
  List<Object> get props => [message];
}