import '../../models/tax_model.dart';
// import '../models/tax_model.dart';

abstract class TaxState {}

class TaxInitial extends TaxState {}

class TaxLoading extends TaxState {}

class TaxLoaded extends TaxState {
  final List<TaxModel> taxes;

  TaxLoaded(this.taxes);
}

class TaxError extends TaxState {
  final String message;

  TaxError(this.message);
}
