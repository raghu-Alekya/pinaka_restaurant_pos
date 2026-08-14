import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../printer/printer_service.dart';
import '../bill_summary_domain/bill_summary_usecase.dart';
import 'bill_summary_event.dart';
import 'bill_summary_state.dart';

class BillSummaryBloc extends Bloc<BillSummaryEvent, BillSummaryState> {
  final BillSummaryUseCase useCase;

  BillSummaryBloc({required this.useCase}) : super(BillSummaryInitial()) {
    on<LoadBillSummary>(_onLoadBillSummary);
    on<GenerateBill>(_onGenerateBill);
  }

  Future<void> _onLoadBillSummary(
      LoadBillSummary event,
      Emitter<BillSummaryState> emit,
      ) async {
    emit(BillSummaryLoading());
    try {
      final data = await useCase(
        orderId: event.orderId,
        restaurantId: event.restaurantId,
        orderType: event.orderType,
        zoneId: event.zoneId,
      );
      emit(BillSummaryLoaded(data: data));
    } catch (e) {
      emit(BillSummaryError(message: e.toString()));
    }
  }

  Future<void> _onGenerateBill(
      GenerateBill event,
      Emitter<BillSummaryState> emit,
      ) async {
    emit(BillGenerating());
    try {
      // Prepare items for printing
      final items = event.billData.lineItems.map((item) {
        return {
          'name': item.name,
          'qty': item.qty,
          'price': item.price,
          'amount': item.total,
          'modifiers': item.modifiers.map((m) => m.toString()).toList(),
        };
      }).toList();

      // Call printer service
      await Printer.printBill(
        orderId: event.billData.orderId.toString(),
        tableName: event.billData.tableName,
        cashierName: 'Captain', // you can get from SharedPreferences
        items: items,
        grossTotal: event.billData.grossTotal,
        couponDiscount: event.billData.couponTotal,
        merchantDiscount: event.billData.merchantDiscount,
        tipAmount: event.billData.tip,
        taxAmount: event.billData.tax,
        serviceCharge: event.billData.serviceChargeValue,
        netPayable: event.billData.netTotal,
        context: emit is BuildContext ? emit as BuildContext : throw Exception('Context not available'),
      );

      emit(BillGenerated(message: 'Bill printed successfully'));
    } catch (e) {
      emit(BillSummaryError(message: 'Failed to print bill: $e'));
    }
  }
}