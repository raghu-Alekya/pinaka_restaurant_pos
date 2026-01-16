import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/tax_repository.dart';
import '../Bloc Event/tax_event.dart';
import '../Bloc State/tax_state.dart';

class TaxBloc extends Bloc<TaxEvent, TaxState> {
  final TaxRepository repository;

  TaxBloc(this.repository) : super(TaxInitial()) {
    on<LoadTaxesEvent>(_onLoadTaxes);
  }

  Future<void> _onLoadTaxes(
      LoadTaxesEvent event,
      Emitter<TaxState> emit,
      ) async {
    emit(TaxLoading());
    try {
      final taxes = await repository.fetchTaxes();
      emit(TaxLoaded(taxes));
    } catch (e) {
      emit(TaxError(e.toString()));
    }
  }
}
