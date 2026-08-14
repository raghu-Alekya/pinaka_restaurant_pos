import 'package:equatable/equatable.dart';
import '../bill_summary_domain/bill_summary_entity.dart';

abstract class BillSummaryEvent extends Equatable {
  const BillSummaryEvent();

  @override
  List<Object> get props => [];
}

class LoadBillSummary extends BillSummaryEvent {
  final int orderId;
  final int restaurantId;
  final String orderType;
  final int zoneId;

  const LoadBillSummary({
    required this.orderId,
    required this.restaurantId,
    required this.orderType,
    required this.zoneId,
  });

  @override
  List<Object> get props => [orderId, restaurantId, orderType, zoneId];
}

class GenerateBill extends BillSummaryEvent {
  final BillSummaryEntity billData;

  const GenerateBill({required this.billData});

  @override
  List<Object> get props => [billData];
}